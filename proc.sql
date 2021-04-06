CREATE EXTENSION IF NOT EXISTS "intarray";

/* ============== START OF TRIGGERS ============== */

/* -------------- Offerings Triggers -------------- */

/* Checks whether total seating capacity >= target number of registrations */
CREATE OR REPLACE FUNCTION check_seating_capacity_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF NEW.seating_capacity < NEW.target_num_reg
    THEN RAISE NOTICE
             'Offering seating_capacity (%) must be >= target_num_reg (%), skipping',
             NEW.seating_capacity, NEW.target_num_reg;
         DELETE FROM Offerings WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_seating_capacity
AFTER INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION check_seating_capacity_func();

/* Checks whether Offering has at least 1 Sessions */
CREATE OR REPLACE FUNCTION check_has_session_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF NOT EXISTS (SELECT 1 FROM Sessions
                      WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id))
    THEN RAISE NOTICE
             'Offerings (%, %) must have at least 1 Sessions, skipping',
             NEW.course_id, NEW.offering_id;
         DELETE FROM Offerings WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_has_session
AFTER INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION check_has_session_func();

/* -------------- Offerings Triggers -------------- */

/* -------------- Sessions Triggers -------------- */

/* Assigns session_id which starts from 1 for each Offerings */
CREATE TRIGGER set_session_id
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_session_id_func();

CREATE OR REPLACE FUNCTION set_session_id_func()
    RETURNS TRIGGER AS
$$
BEGIN
    SELECT COALESCE(MAX(session_id) + 1, 1)
      INTO NEW.session_id
      FROM Sessions
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

/* Checks whether session_date is at least 10 days (inclusive) after registration deadline */
CREATE TRIGGER check_session_date
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_session_date_func();

CREATE OR REPLACE FUNCTION check_session_date_func()
    RETURNS TRIGGER AS
$$
DECLARE
    deadline DATE;
BEGIN
    SELECT reg_deadline
      INTO deadline
      FROM Offerings
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

      IF deadline + 10 <= NEW.session_date
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'Session date must be at least 10 days (inclusive) after %, skipping',
            deadline;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Assigns end_time and removes Sessions that ends after 6pm */
CREATE TRIGGER set_end_time
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_end_time_func();

CREATE OR REPLACE FUNCTION set_end_time_func()
    RETURNS TRIGGER AS
$$
DECLARE
    duration    INTERVAL;
    lunch_break INTERVAL;
BEGIN
    /* Get Session's duration from Courses */
    SELECT MAKE_INTERVAL(HOURS => Courses.duration)
      INTO duration
      FROM Courses
     WHERE course_id = NEW.course_id;

    /* Add lunch break if applicable */
      IF NEW.start_time < '12:00' AND (NEW.start_time + duration) > '12:00'
    THEN lunch_break := '2 hours';
    ELSE lunch_break := '0 hours';
     END IF;

    NEW.end_time := NEW.start_time + duration + lunch_break;

    /* Sessions must end before 6pm */
      IF NEW.end_time <= '18:00'
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'Sessions (%, %, %, %:00, % hours) must end before 6pm, skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date,
             EXTRACT(HOURS from NEW.start_time), EXTRACT(HOURS from duration);
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Assigns eid for Sessions if not provided
    TODO: Implement assign set_instructor() that returns eid and other side effects */
CREATE TRIGGER set_eid
BEFORE INSERT ON Sessions
FOR EACH ROW WHEN (NEW.eid IS NULL) EXECUTE FUNCTION set_eid_func();

CREATE OR REPLACE FUNCTION set_eid_func()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.eid := 1; -- TODO: NEW.eid := set_instructor(...);
      IF NEW.eid IS NOT NULL
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'No available instructor for Session (%, %, %, %), skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Assigns rid for Sessions
    NOTE: Not in use */
CREATE OR REPLACE FUNCTION set_rid_func()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.rid :=
        (SELECT rid
           FROM find_rooms(
                    NEW.session_date,
                    NEW.start_time,
                    (SELECT duration FROM Courses WHERE course_id = NEW.course_id))
          ORDER BY rid LIMIT 1);

      IF NEW.rid IS NOT NULL
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'No available room for Session (%, %, %, %), skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Checks whether the Session's room is available */
CREATE TRIGGER check_rid
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_rid_func();

CREATE OR REPLACE FUNCTION check_rid_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF NEW.rid IN (
             SELECT find_rooms(
                 NEW.session_date,
                 NEW.start_time,
                 (SELECT duration FROM Courses WHERE course_id = NEW.course_id)))
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'Room % not available for Session (%, %, %, %), skipping',
             NEW.rid, NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Updates Offering's start_date and end_date */
CREATE TRIGGER update_start_end_dates
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_start_end_dates_func();

CREATE OR REPLACE FUNCTION update_start_end_dates_func()
    RETURNS TRIGGER AS
$$
DECLARE
    cur_start_date DATE;
    cur_end_date   DATE;
BEGIN
    /* Get current Offering's start_date and end_date */
    SELECT start_date, end_date
      INTO cur_start_date, cur_end_date
      FROM Offerings
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

    /* Update start_date if applicable */
      IF cur_start_date IS NULL
         OR cur_start_date > NEW.session_date
    THEN UPDATE Offerings
            SET start_date = NEW.session_date
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    /* Update end_date if applicable */
      IF cur_end_date IS NULL
         OR cur_end_date < NEW.session_date
    THEN UPDATE Offerings
            SET end_date = NEW.session_date
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

/* Updates Offering's seating_capacity */
CREATE TRIGGER update_seating_capacity
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_seating_capacity_func();

CREATE OR REPLACE FUNCTION update_seating_capacity_func()
    RETURNS TRIGGER AS
$$
BEGIN
    /* Sum of all Sessions' room capacity */
    UPDATE Offerings
       SET seating_capacity = seating_capacity +
           (SELECT seating_capacity FROM Rooms WHERE rid = NEW.rid)
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Sessions Triggers -------------- */


/* -------------- Registration Triggers -------------- */

/* insert or update Owns based on Customers and Credit_cards */

/* check that customer registers for only 1 session in one course before deadline */

/* check that customer has only 1 active/partially active package */
/*
CREATE TRIGGER check_package_status
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_package_status();

CREATE OR REPLACE FUNCTION check_package_status()
    RETURNS TRIGGER AS
$$
BEGIN
    SELECT num_remaining_redemptions
    INTO indicator
    FROM Buys

    IF indicator > 0

END;
$$
LANGUAGE PLPGSQL;
*/

/* check for late cancellation and refund */



/* -------------- Registration Triggers -------------- */


/* =============== END OF TRIGGERS =============== */



/* ============== START OF ROUTINES ============== */

/* --------------- Rooms Routines --------------- */

/* 8. find_rooms
    This routine is used to find all the rooms that could be used for a course session.
    RETURNS: a table of room identifiers */
CREATE OR REPLACE FUNCTION find_rooms(
    _date DATE,
    _start_time TIME,
    _duration INTEGER)
    RETURNS TABLE (rid INTEGER) AS
$$
DECLARE
    _dur_time CONSTANT INTERVAL := MAKE_INTERVAL(HOURS => _duration);
    one_hour CONSTANT INTERVAL := '1 hour';
    lunch_break CONSTANT INTERVAL := '2 hours';
    _end_time TIME;
BEGIN
    /* Calculate _end_time */
      IF _start_time < '12:00' AND (_start_time + _dur_time) > '12:00'
    THEN _end_time = _start_time + _dur_time + lunch_break;
    ELSE _end_time = _start_time + _dur_time;
     END IF;

    RETURN QUERY
    SELECT R1.rid
      FROM Rooms R1
     WHERE R1.rid NOT IN (
           SELECT R2.rid
             FROM Sessions NATURAL JOIN Rooms R2
            WHERE session_date = _date
                  AND (_start_time BETWEEN start_time AND (end_time - one_hour)
                      OR _end_time BETWEEN (start_time + one_hour) AND end_time));
END;
$$
LANGUAGE PLPGSQL;

/* 9. get_available_rooms
    This routine is used to retrieve the availability information of rooms for a specific duration.
    NOTE: Using extension intarray
    RETURNS: a table of (rid, room capacity, day, hours[]) */
CREATE OR REPLACE FUNCTION get_available_rooms(
    _start_date DATE,
    _end_date DATE)
    RETURNS TABLE (rid INTEGER, room_capacity INTEGER, day DATE, hour INTEGER ARRAY) AS
$$
DECLARE
    rid_ INTEGER;
    total_hour_ INTEGER ARRAY;
    lunch_hour_ INTEGER ARRAY;
    busy_hour_ INTEGER ARRAY;
    t1 INTEGER;
    t2 INTEGER;
BEGIN
    /* For each room */
    FOR rid_ IN (SELECT R.rid FROM Rooms R) LOOP
        rid := rid_;
        room_capacity := (SELECT seating_capacity FROM Rooms R WHERE R.rid = rid_);

        /* For each day in [start_date, end_date] */
        FOR day IN (SELECT GENERATE_SERIES(_start_date, _end_date, '1 day')) LOOP
            total_hour_ := ARRAY(SELECT GENERATE_SERIES(9, 17)); -- initialize free hour [9, 17]
            lunch_hour_ := ARRAY(SELECT GENERATE_SERIES(12, 13)); -- lunch breaks
            hour := total_hour_ - lunch_hour_; -- remove lunch breaks

            /* For each (start_time, end_time) pairs in Sessions */
            FOR t1, t2 IN
                (SELECT EXTRACT(HOURS from start_time),
                        EXTRACT(HOURS from end_time) - 1
                   FROM Sessions S
                  WHERE S.session_date = day
                        AND S.rid = rid_) LOOP
                busy_hour_ := ARRAY(SELECT GENERATE_SERIES(t1, t2)); -- busy hours
                hour := hour - busy_hour_; -- remove busy hours
            END LOOP;

            hour := sort(hour);

            RETURN NEXT;
        END LOOP;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Rooms Routines --------------- */

/* --------------- Courses Routines --------------- */

/* 5. add_course
    This routine is used to add a new course.
    RETURNS: the result of the new Course after successful INSERT */
CREATE OR REPLACE FUNCTION add_course(
    _title TEXT,
    _description TEXT,
    _area_name TEXT,
    _duration INTEGER)
    RETURNS Courses AS
$$
    INSERT INTO
    Courses (title, description, area_name, duration) VALUES
            (_title, _description, _area_name, _duration)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Courses Routines --------------- */

/* --------------- Offerings Routines --------------- */

/* 10. add_course_offering
    This routine is used to add a new offering of an existing course.
    RETURNS: the result of the new Offering after successful INSERT */
DROP TYPE IF EXISTS SessionInput CASCADE;
CREATE TYPE SessionInput AS (session_date DATE, start_time TIME, rid INTEGER);

CREATE OR REPLACE FUNCTION add_course_offering(
    _course_id INTEGER,
    _offering_id INTEGER,
    _launch_date DATE,
    _reg_deadline DATE,
    _fees INTEGER,
    _target_num_reg INTEGER,
    _eid INTEGER,
    _session_array SessionInput ARRAY)
    RETURNS Offerings AS
$$
DECLARE
    input SessionInput;
    result Offerings;
BEGIN
    INSERT INTO Offerings
        (course_id, offering_id, launch_date, reg_deadline, fees, target_num_reg, eid) VALUES
        (_course_id, _offering_id, _launch_date, _reg_deadline, _fees, _target_num_reg, _eid);

    FOREACH input IN ARRAY _session_array LOOP
        PERFORM add_session(_course_id, _offering_id,
                    input.session_date, input.start_time, NULL, input.rid);
    END LOOP;

    /* Store the inserted Offering into result */
    SELECT * INTO result FROM Offerings WHERE (course_id, offering_id) = (_course_id, _offering_id);
    RETURN result;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Offerings Routines --------------- */

/* --------------- Sessions Routines --------------- */

/* 24. add_session
    This routine is used to add a new session to a course offering.
    RETURNS: the result of the new Session after successful INSERT */
CREATE OR REPLACE FUNCTION add_session(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_date DATE,
    _start_time TIME,
    _eid INTEGER,
    _rid INTEGER)
    RETURNS Sessions AS
$$
    INSERT INTO Sessions
        (course_id, offering_id, session_date, start_time, eid, rid) VALUES
        (_course_id, _offering_id, _session_date, _start_time, _eid, _rid)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Sessions Routines --------------- */

/* =============== END OF ROUTINES =============== */