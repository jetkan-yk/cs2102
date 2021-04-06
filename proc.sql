CREATE EXTENSION IF NOT EXISTS "intarray";

/* ============== START OF TRIGGERS ============== */

/* -------------- Offerings Triggers -------------- */

/* Removes Offering if total seating capacity < target number of registrations */
CREATE OR REPLACE FUNCTION check_seating_capacity_func(
    _course_id INTEGER,
    _offering_id INTEGER,
    _target_num_reg INTEGER)
    RETURNS VOID AS
$$
DECLARE
    total_seat_cap CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Offerings
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
BEGIN
      IF total_seat_cap < _target_num_reg
    THEN RAISE NOTICE
             'Offering seating_capacity (%) must be >= target_num_reg (%), skipping',
              total_seat_cap, _target_num_reg;
         DELETE FROM Offerings WHERE (course_id, offering_id) = (_course_id, _offering_id);
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Removes Offering if does not have any Sessions */
CREATE OR REPLACE FUNCTION check_has_session_func(
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS VOID AS
$$
BEGIN
      IF NOT EXISTS (SELECT 1 FROM Sessions
                      WHERE (course_id, offering_id) = (_course_id, _offering_id))
    THEN RAISE NOTICE
             'Offerings (%, %) must have at least 1 Sessions, skipping',
              _course_id, _offering_id;
         DELETE FROM Offerings WHERE (course_id, offering_id) = (_course_id, _offering_id);
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Offerings Triggers -------------- */

/* -------------- Sessions Triggers -------------- */

/* Assigns session_id which starts from 1 for each Offerings */
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

CREATE TRIGGER set_session_id
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_session_id_func();

/* Checks whether session_date is at least 10 days (inclusive) after registration deadline */
CREATE OR REPLACE FUNCTION check_session_date_func()
    RETURNS TRIGGER AS
$$
DECLARE
    deadline CONSTANT DATE :=
        (SELECT reg_deadline FROM Offerings
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id));
BEGIN
      IF deadline + 10 <= NEW.session_date
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'Session date must be at least 10 days (inclusive) after %, skipping',
             deadline;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_session_date
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_session_date_func();

/* Assigns end_time and removes Sessions that ends after 6pm */
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
    ELSE RAISE NOTICE
            'Sessions (%, %, %, %:00, % hours) must end before 6pm, skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date,
             EXTRACT(HOURS from NEW.start_time), EXTRACT(HOURS from duration);
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER set_end_time
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_end_time_func();

/* Assigns eid for Sessions if not provided
    TODO: Implement assign set_instructor() that returns eid and other side effects */
CREATE OR REPLACE FUNCTION set_eid_func()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.eid := 1; -- TODO: NEW.eid := set_instructor(...);
      IF NEW.eid IS NOT NULL
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'No available instructor for Session (%, %, %, %), skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER set_eid
BEFORE INSERT ON Sessions
FOR EACH ROW WHEN (NEW.eid IS NULL) EXECUTE FUNCTION set_eid_func();

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
    ELSE RAISE NOTICE
            'No available room for Session (%, %, %, %), skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Checks whether the Session's room is available */
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
    ELSE RAISE NOTICE
            'Room % not available for Session (%, %, %, %), skipping',
             NEW.rid, NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_rid
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_rid_func();

/* Updates Offering's start_date and end_date */
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

CREATE TRIGGER update_start_end_dates
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_start_end_dates_func();

/* Updates Offering's seating_capacity */
CREATE OR REPLACE FUNCTION update_seating_capacity_func()
    RETURNS TRIGGER AS
$$
DECLARE
    room_capacity CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Rooms WHERE rid = NEW.rid);
BEGIN
    /* Sum of all Sessions' room capacity */
    UPDATE Offerings
       SET seating_capacity = seating_capacity + room_capacity
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER update_seating_capacity
AFTER INSERT OR UPDATE OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_seating_capacity_func();

/* -------------- Sessions Triggers -------------- */


/* -------------- Registration Triggers -------------- */

/* insert or update Owns based on Customers and Credit_cards */

/* check that customer registers for only 1 session in one course before deadline */

/* check that customer has only 1 active/partially active package */
/*
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

CREATE TRIGGER check_package_status
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_package_status();
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
    /* Insert a new entry into Offerings first*/
    INSERT INTO Offerings
        (course_id, offering_id, launch_date, reg_deadline, fees, target_num_reg, eid) VALUES
        (_course_id, _offering_id, _launch_date, _reg_deadline, _fees, _target_num_reg, _eid);

    /* Then process all Sessions */
    FOREACH input IN ARRAY _session_array LOOP
        PERFORM add_session(_course_id, _offering_id,
                    input.session_date, input.start_time, NULL, input.rid);
    END LOOP;

    /* Remove Offerings (and all Sessions, CASCADE) if violates any requirements */
    PERFORM check_seating_capacity_func(_course_id, _offering_id, _target_num_reg);
    PERFORM check_has_session_func(_course_id, _offering_id);

    /* Store the inserted Offering into result */
    SELECT * INTO result FROM Offerings WHERE (course_id, offering_id) = (_course_id, _offering_id);
    RETURN result;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Offerings Routines --------------- */

/* --------------- Sessions Routines --------------- */

/* 22. update_room
    This routine is used to change the room for a course session.
    RETURNS: the result of the new Session after successful INSERT */
CREATE OR REPLACE FUNCTION update_room(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER,
    _rid INTEGER)
    RETURNS Sessions AS
$$
DECLARE
    date_ DATE;
    time_ TIME;
    num_reg CONSTANT INTEGER := 0;
    /* TODO: Replace with
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)); */
    room_cap CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Rooms WHERE rid = _rid);
    result Sessions;
BEGIN
    SELECT session_date, start_time
      INTO date_, time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF (date_ + time_) < now() THEN
         RAISE NOTICE
            'Session has already started (% %), skipping',
             date_, time_;
   ELSIF num_reg > room_cap THEN
         RAISE NOTICE
            'Session number of registrations (%) > room capacity (%), skipping',
             num_reg, room_cap;
    ELSE UPDATE Sessions
            SET rid = _rid
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
         RETURNING * INTO result;
     END IF;

    RETURN result;
END;
$$
LANGUAGE PLPGSQL;

/* 23. remove_session
    This routine is used to remove a course session.
    RETURNS: the session that has been successfully removed
    TODO: Implement update session start_date and end_date */
CREATE OR REPLACE FUNCTION remove_session(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Sessions AS
$$
DECLARE
    date_ DATE;
    time_ TIME;
    num_reg CONSTANT INTEGER := 0;
    /* TODO: Replace with
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)); */
    result Sessions;
BEGIN
    SELECT session_date, start_time
      INTO date_, time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF (date_ + time_) < now() THEN
         RAISE NOTICE
            'Session has already started (% %), skipping',
             date_, time_;
   ELSIF num_reg > 0 THEN
         RAISE NOTICE
            'Number of registrations (%) > 0, skipping',
             num_reg;
    ELSE DELETE FROM Sessions
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
         RETURNING * INTO result;
     END IF;

    RETURN result;
END;
$$
LANGUAGE PLPGSQL;

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