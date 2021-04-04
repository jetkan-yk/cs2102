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
      IF NEW.start_time < '12:00'
         AND (NEW.start_time + duration) > '12:00'
    THEN lunch_break := '2 hours';
    ELSE lunch_break := '0 hours';
     END IF;

    NEW.end_time := NEW.start_time + duration + lunch_break;

    /* Sessions must end before 6pm */
      IF NEW.end_time > '18:00'
    THEN RETURN NULL;
    ELSE RETURN NEW;
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

/* --------------- Courses Routines --------------- */

/* add_course */
CREATE OR REPLACE PROCEDURE add_course() AS
$$
BEGIN
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Courses Routines --------------- */

/* =============== END OF ROUTINES =============== */