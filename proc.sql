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
    total_seat_cap_ CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Offerings
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
BEGIN
      IF total_seat_cap_ < _target_num_reg
    THEN RAISE NOTICE
             'Offering seating_capacity (%) must be >= target_num_reg (%), skipping',
              total_seat_cap_, _target_num_reg;
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
    deadline_ CONSTANT DATE :=
        (SELECT reg_deadline FROM Offerings
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id));
BEGIN
      IF deadline_ + 10 <= NEW.session_date
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'Session date must be at least 10 days (inclusive) after %, skipping',
             deadline_;
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
    duration_ INTERVAL;
    lunch_break_ INTERVAL;
BEGIN
    /* Get Session's duration from Courses */
    SELECT MAKE_INTERVAL(HOURS => Courses.duration)
      INTO duration_
      FROM Courses
     WHERE course_id = NEW.course_id;

    /* Add lunch break if applicable */
      IF NEW.start_time < '12:00' AND (NEW.start_time + duration_) > '12:00'
    THEN lunch_break_ := '2 hours';
    ELSE lunch_break_ := '0 hours';
     END IF;

    NEW.end_time := NEW.start_time + duration_ + lunch_break_;

    /* Sessions must end before 6pm */
      IF NEW.end_time <= '18:00'
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'Sessions (%, %, %, %:00, % hours) must end before 6pm, skipping',
             NEW.course_id, NEW.offering_id, NEW.session_date,
             EXTRACT(HOURS from NEW.start_time), EXTRACT(HOURS from duration_);
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
    cur_start_date_ DATE;
    cur_end_date_   DATE;
BEGIN
    /* Get current Offering's start_date and end_date */
    SELECT start_date, end_date
      INTO cur_start_date_, cur_end_date_
      FROM Offerings
     WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);

    /* Update start_date if applicable */
      IF cur_start_date_ IS NULL
         OR cur_start_date_ > NEW.session_date
    THEN UPDATE Offerings
            SET start_date = NEW.session_date
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    /* Update end_date if applicable */
      IF cur_end_date_ IS NULL
         OR cur_end_date_ < NEW.session_date
    THEN UPDATE Offerings
            SET end_date = NEW.session_date
          WHERE (course_id, offering_id) = (NEW.course_id, NEW.offering_id);
     END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER update_start_end_dates
AFTER INSERT OR UPDATE OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_start_end_dates_func();

/* Updates Offering's seating_capacity */
CREATE OR REPLACE FUNCTION update_seating_capacity_func()
    RETURNS TRIGGER AS
$$
DECLARE
    room_capacity_ CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Rooms WHERE rid = NEW.rid);
BEGIN
    /* Sum of all Sessions' room capacity */
    UPDATE Offerings
       SET seating_capacity = seating_capacity + room_capacity_
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

/* --------------- Credit Card Routines --------------- */

/* 8. update_credit_card
    This routine is used when a customer requests to change his/her credit card details.
    RETURNS: the result of new credit card details after successful UPDATE */
CREATE OR REPLACE FUNCTION update_credit_card(
    _cust_id INTEGER,
    _cc_number VARCHAR(19),
    _cvv INTEGER,
    _expiry_date DATE)
    RETURNS Owns AS
$$
    INSERT INTO Credit_cards
        (cc_number, cvv, expiry_date) VALUES
        (_cc_number, _cvv, _expiry_date);

    INSERT INTO Owns
        (cc_number, cust_id) VALUES
        (_cc_number, _cust_id)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Credit Card Routines --------------- */

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
    duration_ CONSTANT INTERVAL := MAKE_INTERVAL(HOURS => _duration);
    one_hour_ CONSTANT INTERVAL := '1 hour';
    lunch_break_ CONSTANT INTERVAL := '2 hours';
    end_time_ TIME;
BEGIN
    /* Calculate end_time_ */
      IF _start_time < '12:00' AND (_start_time + duration_) > '12:00'
    THEN end_time_ = _start_time + duration_ + lunch_break_;
    ELSE end_time_ = _start_time + duration_;
     END IF;

    RETURN QUERY
    SELECT R1.rid
      FROM Rooms R1
     WHERE R1.rid NOT IN (
           SELECT R2.rid
             FROM Sessions NATURAL JOIN Rooms R2
            WHERE session_date = _date
                  AND (_start_time BETWEEN start_time AND (end_time - one_hour_)
                      OR end_time_ BETWEEN (start_time + one_hour_) AND end_time));
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
    t1_ INTEGER;
    t2_ INTEGER;
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
            FOR t1_, t2_ IN
                (SELECT EXTRACT(HOURS from start_time),
                        EXTRACT(HOURS from end_time) - 1
                   FROM Sessions S
                  WHERE S.session_date = day
                        AND S.rid = rid_) LOOP
                busy_hour_ := ARRAY(SELECT GENERATE_SERIES(t1_, t2_)); -- busy hours
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
    INSERT INTO Courses
        (title, description, area_name, duration) VALUES
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
    input_ SessionInput;
    result_ Offerings;
BEGIN
    /* Insert a new entry into Offerings first*/
    INSERT INTO Offerings
        (course_id, offering_id, launch_date, reg_deadline, fees, target_num_reg, eid) VALUES
        (_course_id, _offering_id, _launch_date, _reg_deadline, _fees, _target_num_reg, _eid);

    /* Then process all Sessions */
    FOREACH input_ IN ARRAY _session_array LOOP
        PERFORM add_session(_course_id, _offering_id,
                    input_.session_date, input_.start_time, NULL, input_.rid);
    END LOOP;

    /* Remove Offerings (and all Sessions, CASCADE) if violates any requirements */
    PERFORM check_seating_capacity_func(_course_id, _offering_id, _target_num_reg);
    PERFORM check_has_session_func(_course_id, _offering_id);

    /* Store the inserted Offering into result_ */
    SELECT * INTO result_ FROM Offerings WHERE (course_id, offering_id) = (_course_id, _offering_id);
    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Offerings Routines --------------- */

/* --------------- Buys Routines --------------- */

/* 13. buy_course_package
    This routine is used when a customer requests to purchase a course package.
    RETURNS: the result of the new Buy after successful INSERT */
CREATE OR REPLACE FUNCTION buy_course_package(
    _cust_id INTEGER,
    _package_id INTEGER)
    RETURNS Buys AS
$$
DECLARE
    cc_number_ CONSTANT VARCHAR(19) :=
        (SELECT cc_number FROM Owns WHERE cust_id = _cust_id ORDER BY owns_ts DESC LIMIT 1);
    num_free_reg_ INTEGER;
    sale_start_date_ DATE;
    sale_end_date_ DATE;
    one_day_ CONSTANT INTERVAL := '1 day';
    result_ Buys;
BEGIN
    SELECT num_free_reg, sale_start_date, sale_end_date
      INTO num_free_reg_, sale_start_date_, sale_end_date_
      FROM Packages
     WHERE package_id = _package_id;

     IF NOT (NOW() BETWEEN sale_start_date_ AND (sale_end_date_ + one_day_)) THEN
        RAISE NOTICE
           'Packages must be purchased within sales dates [%, %], skipping',
            sale_start_date_, sale_end_date_;
        RETURN NULL;
    END IF;

    INSERT INTO Buys
        (package_id, cc_number, num_remain_redeem) VALUES
        (_package_id, cc_number_, num_free_reg_)
    RETURNING * INTO result_;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Buys Routines --------------- */

/* --------------- Packages Routines --------------- */

/* 11. add_course_package
    This routine is used to add a new course package for sale.
    RETURNS: the result of the new Package after successful INSERT */
CREATE OR REPLACE FUNCTION add_course_package(
    _name TEXT,
    _num_free_reg INTEGER,
    _price INTEGER,
    _sale_start_date DATE,
    _sale_end_date DATE)
    RETURNS Packages AS
$$
    INSERT INTO Packages
        (name, num_free_reg, price, sale_start_date, sale_end_date) VALUES
        (_name, _num_free_reg, _price, _sale_start_date, _sale_end_date)
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Packages Routines --------------- */

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
    num_reg_ CONSTANT INTEGER := 0;
    /* TODO: Replace with
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)); */
    room_cap_ CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Rooms WHERE rid = _rid);
    result_ Sessions;
BEGIN
    SELECT session_date, start_time
      INTO date_, time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF (date_ + time_) < NOW() THEN
         RAISE NOTICE
            'Session has already started (% %), skipping',
             date_, time_;
   ELSIF num_reg_ > room_cap_ THEN
         RAISE NOTICE
            'Session number of registrations (%) > room capacity (%), skipping',
             num_reg_, room_cap_;
    ELSE UPDATE Sessions
            SET rid = _rid
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
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
    num_reg_ CONSTANT INTEGER := 0;
    /* TODO: Replace with
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)); */
    result_ Sessions;
BEGIN
    SELECT session_date, start_time
      INTO date_, time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF (date_ + time_) < NOW() THEN
         RAISE NOTICE
            'Session has already started (% %), skipping',
             date_, time_;
   ELSIF num_reg_ > 0 THEN
         RAISE NOTICE
            'Number of registrations (%) > 0, skipping',
             num_reg_;
    ELSE DELETE FROM Sessions
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
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

/* --------------- Employees Routines --------------- */

/* 1. add_employee
    This routine is used to add a new employee. The inputs to the routine include the following: name, home address, contact number, email address, salary information (i.e., monthly salary for a full-time employee or hourly rate for a part-time employee), date that the employee joined the company, the employee category (manager, administrator, or instructor), and a (possibly empty) set of course areas. 
    
    RETURNS the Employees table after the new employee has been added */
CREATE OR REPLACE FUNCTION add_employee(
    _ename TEXT,
    _phone_number TEXT,
    _home_address TEXT,
    _email_address TEXT,
    _join_date DATE,
    _category TEXT,
    _salary INTEGER,
    _course_area_set TEXT ARRAY)
    RETURNS Employees AS
$$
    INSERT INTO
    Employees (ename, phone_number, home_address, email_address, join_date, category, salary, course_area_set) 
    VALUES (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary, _course_area_set) 
    RETURNING *;
$$
LANGUAGE SQL;


/* 2. remove_employee
    This routine is used to update an employee’s departed date a non-null value. The inputs to the routine is an employee identifier and a departure date.
    
    The update operation is rejected if any one of the following conditions hold: 

    (1) the employee is an administrator who is handling some course offering where its registration deadline is after the employee’s departure date;
    
    (2) the employee is an instructor who is teaching some course session that starts after the employee’s departure date;
    
    (3) the employee is a manager who is managing some area.

    RETURNS the Employees table after the employee departure_date has been updated */
CREATE OR REPLACE FUNCTION remove_employee(
    _eid INTEGER,
    _depart_date DATE)
    RETURNS Employees AS
$$
DECLARE
    employee_type_ TEXT;
    result Employees;
BEGIN
    SELECT category INTO employee_type_
        FROM Employees
        WHERE eid = _eid;
    IF employee_type_ = 'Manager' THEN
        IF _eid IN (SELECT eid FROM Manages) THEN
            RAISE NOTICE
                'Cannot remove employee, as employee is a manager managing some area';
        ELSE
            UPDATE Employees
            SET depart_date = _depart_date
            WHERE eid = _eid
            RETURNING * INTO result;
        END IF;
    ELSIF employee_type_ = 'Administrator' THEN
        IF _eid IN (SELECT a1.eid 
            FROM Offerings o1, Administrators a1
            WHERE o1.reg_deadline > _depart_date) THEN
            RAISE NOTICE
                'Cannot remove employee, as employee is an administrator handling a course offering where its registration deadline is after employee depart date';
        ELSE
            UPDATE Employees
            SET depart_date = _depart_date
            WHERE eid = _eid
            RETURNING * INTO result;
        END IF;
    ELSIF employee_type_ = 'Instructor' THEN
        IF _eid IN (SELECT i1.eid
            FROM Sessions s1, Instructors i1
            WHERE s1.session_date > _depart_date) THEN
            RAISE NOTICE
                'Cannot remove employee, as employee is an instructor who is teaching some course session that starts after employee depart date';
        ELSE
            UPDATE Employees
            SET depart_date = _depart_date
            WHERE eid = _eid
            RETURNING * INTO result;
        END IF;
    END IF;

    RETURN result;
END;
$$
LANGUAGE PLPGSQL;
/* =============== END OF ROUTINES =============== */
