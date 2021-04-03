/* -------------- Offerings Triggers -------------- */
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
    SELECT MAKE_INTERVAL(HOURS => Courses.duration)
      INTO duration
      FROM Courses
     WHERE course_id = NEW.course_id;

      IF NEW.start_time < '12:00'
         AND (NEW.start_time + duration) > '12:00'
    THEN lunch_break := '2 hours';
    ELSE lunch_break := '0 hours';
     END IF;

    NEW.end_time := NEW.start_time + duration + lunch_break;

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


/* Updates Offering start_date and end_date */
CREATE OR REPLACE FUNCTION set_start_end_dates_func()
    RETURNS TRIGGER AS
$$
DECLARE
    cur_start_date DATE;
    cur_end_date   DATE;
BEGIN
    SELECT start_date, end_date
      INTO cur_start_date, cur_end_date
      FROM Offerings
     WHERE course_id = NEW.course_id
           AND offering_id = NEW.offering_id;

      IF cur_start_date IS NULL
         OR cur_start_date > NEW.session_date
    THEN UPDATE Offerings
            SET start_date = NEW.session_date
          WHERE course_id = NEW.course_id
                AND offering_id = NEW.offering_id;
     END IF;

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

CREATE TRIGGER set_start_end_dates
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_start_end_dates_func();

/* -------------- Sessions Triggers -------------- */