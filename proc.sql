/* ============== START OF TRIGGERS ============== */

/* -------------- Sessions Triggers -------------- */

/* Assigns session_id which starts from 1 for each Offerings */
CREATE OR REPLACE FUNCTION set_session_id_func()
    RETURNS TRIGGER AS
$$
BEGIN
    SELECT COALESCE(MAX(session_id) + 1, 1)
      INTO NEW.session_id
      FROM Sessions
     WHERE course_id = NEW.course_id
           AND offering_id = NEW.offering_id;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER set_session_id
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_session_id_func();

/* Checks whether session_date is at least 10 days (inclusive)
   after registration deadline */
CREATE OR REPLACE FUNCTION check_session_date_func()
    RETURNS TRIGGER AS
$$
DECLARE
    deadline DATE;
BEGIN
    SELECT reg_deadline
      INTO deadline
      FROM Offerings
     WHERE course_id = NEW.course_id
           AND offering_id = NEW.offering_id;

      IF deadline + 10 <= NEW.session_date
    THEN RETURN NEW;
    ELSE RAISE NOTICE 'Session date must be at least 10 days (inclusive) after %, skipping',
            deadline;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_session_date
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_session_date_func();

/* Assigns end_time and removes sessions that ends after 6pm */
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
    ELSE RAISE NOTICE 'Session (%, %, %, %:00, % hours) must end before 6pm, skipping',
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
     WHERE course_id = NEW.course_id
           AND offering_id = NEW.offering_id;

    /* Update start_date if applicable */
      IF cur_start_date IS NULL
         OR cur_start_date > NEW.session_date
    THEN UPDATE Offerings
            SET start_date = NEW.session_date
          WHERE course_id = NEW.course_id
                AND offering_id = NEW.offering_id;
     END IF;

    /* Update end_date if applicable */
      IF cur_end_date IS NULL
         OR cur_end_date < NEW.session_date
    THEN UPDATE Offerings
            SET end_date = NEW.session_date
          WHERE course_id = NEW.course_id
                AND offering_id = NEW.offering_id;
     END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER update_start_end_dates
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_start_end_dates_func();

/* Updates Offering's seating_capacity */
CREATE OR REPLACE FUNCTION update_seating_capacity_func()
    RETURNS TRIGGER AS
$$
BEGIN
    /* Sum of all Sessions' room capacity */
    UPDATE Offerings
       SET seating_capacity = seating_capacity +
           (SELECT seating_capacity FROM Rooms WHERE rid = NEW.rid)
     WHERE course_id = NEW.course_id
           AND offering_id = NEW.offering_id;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER update_seating_capacity
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_seating_capacity_func();

/* -------------- Sessions Triggers -------------- */


/* -------------- Registration Triggers -------------- */

/*to check that customer registers for only
1 session in one course before deadline */

/* to check that customer has only 1 active/partially active package */

/* to check for late cancellation and refund */

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
    RETURNS TABLE(rid INTEGER) AS
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
                  AND (start_time BETWEEN _start_time AND (_end_time - one_hour)
                      OR end_time BETWEEN (_start_time + one_hour) AND _end_time));
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
    INSERT INTO Courses(title, description, area_name, duration)
    VALUES (_title, _description, _area_name, _duration)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Courses Routines --------------- */

/* --------------- Sessions Routines --------------- */

/* 24. add_session
    This routine is used to add a new session to a course offering.
    RETURNS: the result of the new Session after successful INSERT
    TODO: Implement assign_instructor() trigger
    TODO: Implement assign_room() trigger */
CREATE OR REPLACE FUNCTION add_session(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_date DATE,
    _start_time TIME,
    _rid INTEGER)
    RETURNS Sessions AS
$$
    INSERT INTO Sessions(course_id, offering_id, session_date, start_time, rid)
    VALUES (_course_id, _offering_id, _session_date, _start_time, _rid)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Sessions Routines --------------- */

/* =============== END OF ROUTINES =============== */