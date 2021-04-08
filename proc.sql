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
             'Offering seating_capacity (%) must be >= target_num_reg (%)',
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
             'Offerings (%, %) must have at least 1 Sessions',
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
            'Session date must be at least 10 days (inclusive) after %',
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
            'Sessions (%, %, %, %:00, % hours) must end before 6pm',
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
            'No available instructor for Session (%, %, %, %)',
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
            'No available room for Session (%, %, %, %)',
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
            'Room % not available for Session (%, %, %, %)',
             NEW.rid, NEW.course_id, NEW.offering_id, NEW.session_date, NEW.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_rid
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_rid_func();

/* Updates Offering's start_date and end_date
    TODO: change to STATEMENT level, loop through all sessions */
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

/* Updates Offering's seating_capacity
    TODO: change to STATEMENT level, loop through all sessions */
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

/* Checks that a Customer Registers/Redeems only 1 Session of the same Course */
CREATE OR REPLACE FUNCTION check_can_register_course(
    _cust_id INTEGER,
    _course_id INTEGER)
    RETURNS BOOLEAN AS
$$
DECLARE
    old_offering_id_ INTEGER;
    old_session_id_ INTEGER;
BEGIN
-- TODO: Update implementation with get_available_course_offerings() routine
    SELECT offering_id, session_id
      INTO old_offering_id_, old_session_id_
      FROM Registers
     WHERE course_id = _course_id
           AND cc_number = get_cc_number(_cust_id);

      IF old_offering_id_ IS NULL
    THEN RETURN TRUE;
    ELSE RAISE NOTICE
            'Customer has already registered a Session (%, %, %) from this Course',
             _course_id, old_offering_id_, old_session_id_;
         RETURN FALSE;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Checks that Register/Redeem Session is done before registration deadline */
CREATE OR REPLACE FUNCTION check_is_before_reg_deadline(
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS BOOLEAN AS
$$
DECLARE
    reg_deadline_ CONSTANT DATE :=
        (SELECT reg_deadline FROM Offerings
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
    one_day_ CONSTANT INTERVAL := '1 day';
BEGIN
      IF NOW() < (reg_deadline_ + one_day_)
    THEN RETURN TRUE;
    ELSE RAISE NOTICE
            'Session must be registered before Offering (%, %) registration deadline %',
             _course_id, _offering_id, reg_deadline_ + one_day_;
         RETURN FALSE;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Sessions Triggers -------------- */

/* -------------- Credit Card Triggers -------------- */

/* This function queries the latest cc_number Owns by a Customer */
CREATE OR REPLACE FUNCTION get_cc_number(
    _cust_id INTEGER)
    RETURNS VARCHAR(19) AS
$$
    SELECT cc_number
      FROM Owns
     WHERE cust_id = _cust_id
     ORDER BY owns_ts DESC LIMIT 1;
$$
LANGUAGE SQL;

/* -------------- Credit Card Triggers -------------- */

/* -------------- Registers Triggers -------------- */

/* check that customer has only 1 active/partially active package */

/* check for late cancellation and refund */

/* This function Registers a Customer for a Session using credit card.
    RETURNS: the result of the new Register after successful INSERT */
CREATE OR REPLACE FUNCTION add_registers(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Registers AS
$$
    INSERT INTO Registers
        (cc_number, course_id, offering_id, session_id) VALUES
        (get_cc_number(_cust_id), _course_id, _offering_id, _session_id)
    RETURNING *;
$$
LANGUAGE SQL;

/* -------------- Registers Triggers -------------- */

/* -------------- Redeems Triggers -------------- */

/* Updates the redeemed Package's num_remain_redeem */
CREATE OR REPLACE FUNCTION update_num_remain_redeem_func()
    RETURNS TRIGGER AS
$$
BEGIN
    UPDATE Buys
       SET num_remain_redeem = num_remain_redeem - 1
     WHERE buys_ts = NEW.buys_ts;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER update_num_remain_redeem
AFTER INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION update_num_remain_redeem_func();

/* This function Redeems a Session using Package.
    RETURNS: the result of the new Redeems after successful INSERT */
CREATE OR REPLACE FUNCTION add_redeems(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Redeems AS
$$
DECLARE
    buys_ts_ TIMESTAMP;
    num_remain_redeem_ INTEGER;
    result_ Redeems;
BEGIN
    SELECT buys_ts, num_remain_redeem
      INTO buys_ts_, num_remain_redeem_
      FROM get_active_buys(_cust_id);

      IF buys_ts_ IS NULL
    THEN RAISE NOTICE
            'No redeemable package';
         RETURN NULL;
    ELSE INSERT INTO Redeems
             (buys_ts, course_id, offering_id, session_id) VALUES
             (buys_ts_, _course_id, _offering_id, _session_id)
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Redeems Triggers -------------- */

/* -------------- Buys Triggers -------------- */

/* This function returns the Customer's active package Buys information
    RETURNS: the active Buys entry */
-- TODO: Change to include partially active package
CREATE OR REPLACE FUNCTION get_active_buys(
    _cust_id INTEGER)
    RETURNS Buys AS
$$
    SELECT * FROM Buys
     WHERE cc_number = get_cc_number(_cust_id)
           AND num_remain_redeem > 0;
$$
LANGUAGE SQL;

/* Checks whether the Package is Bought during sales date */
CREATE OR REPLACE FUNCTION check_sales_date_func()
    RETURNS TRIGGER AS
$$
DECLARE
    sale_start_date_ DATE;
    sale_end_date_ DATE;
    one_day_ CONSTANT INTERVAL := '1 day';
BEGIN
    SELECT sale_start_date, sale_end_date
      INTO sale_start_date_, sale_end_date_
      FROM Packages
     WHERE package_id = NEW.package_id;

      IF (NOW() BETWEEN sale_start_date_ AND (sale_end_date_ + one_day_))
    THEN RETURN NEW;
    ELSE RAISE NOTICE
             'Packages must be purchased within sales dates (%, %)',
              sale_start_date_, sale_end_date_;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_sales_date
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_sales_date_func();

/* Sets the num_remain_redeem in Buys */
CREATE OR REPLACE FUNCTION set_num_remain_redeem_func()
    RETURNS TRIGGER AS
$$
BEGIN
    SELECT num_free_reg
      INTO NEW.num_remain_redeem
      FROM Packages
     WHERE package_id = NEW.package_id;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER set_num_remain_redeem
BEFORE INSERT ON Buys
FOR EACH ROW WHEN (NEW.num_remain_redeem IS NULL) EXECUTE FUNCTION set_num_remain_redeem_func();

/* -------------- Buys Triggers -------------- */

/* =============== END OF TRIGGERS =============== */



/* ============== START OF ROUTINES ============== */

/* --------------- Credit Card Routines --------------- */

/* 4. update_credit_card
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
             FROM Sessions S NATURAL JOIN Rooms R2
            WHERE session_date = _date
                  AND (_start_time BETWEEN S.start_time AND (S.end_time - one_hour_)
                      OR end_time_ BETWEEN (S.start_time + one_hour_) AND S.end_time));
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

/* 12. get_available_course_packages
    This routine is used to retrieve the course packages that are available for sale.
    RETURNS: a table of available Packages */
CREATE OR REPLACE FUNCTION get_available_course_packages()
    RETURNS TABLE (package_id INTEGER,
                   name TEXT,
                   num_free_sessions INTEGER,
                   sale_end_date DATE,
                   price INTEGER) AS
$$
    SELECT package_id,
           name,
           num_free_reg AS num_free_sessions,
           sale_end_date,
           price
      FROM Packages
     WHERE NOW() BETWEEN sale_start_date AND (sale_end_date + '1 day'::INTERVAL);
$$
LANGUAGE SQL;

/* --------------- Packages Routines --------------- */

/* --------------- Buys Routines --------------- */

/* 13. buy_course_package
    This routine is used when a customer requests to purchase a course package.
    RETURNS: the result of the new Buy after successful INSERT */
CREATE OR REPLACE FUNCTION buy_course_package(
    _cust_id INTEGER,
    _package_id INTEGER)
    RETURNS Buys AS
$$
-- TODO: add Buys trigger to check Customer eligibility (no active package)
    INSERT INTO Buys
        (package_id, cc_number) VALUES
        (_package_id, get_cc_number(_cust_id))
    RETURNING *;
$$
LANGUAGE SQL;

/* 14. get_my_course_package
    This routine is used when a customer requests to view his/her active/partially active course
    package.
    RETURNS: a JSON result */
-- TODO: Implement redeemed sessions
CREATE OR REPLACE FUNCTION get_my_course_package(
    _cust_id INTEGER)
    RETURNS JSON AS
$$
DECLARE
    active_buys_ RECORD;
    active_packages_ RECORD;
BEGIN
    SELECT package_id,
           DATE(buys_ts) AS purchase_date,
           num_remain_redeem AS num_redeem_allow
      INTO active_buys_
      FROM get_active_buys(_cust_id);

    SELECT name AS package_name,
           price AS package_price,
           num_free_reg AS num_free_sessions
      INTO active_packages_
      FROM Packages
     WHERE package_id = active_buys_.package_id;

    RETURN JSONB_PRETTY(TO_JSONB(active_buys_) || TO_JSONB(active_packages_));
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Buys Routines --------------- */

/* --------------- Sessions Routines --------------- */

/* 17. register_session
    This routine is used when a customer requests to register for a session in a course offering.
    RETURNS: the result of the new Register after successful INSERT */
-- TODO: check get_available_course_session before insert
CREATE OR REPLACE FUNCTION register_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER,
    _payment_method TEXT)
    RETURNS TEXT AS
$$
DECLARE
    can_register_course CONSTANT BOOLEAN :=
        check_can_register_course(_cust_id, _course_id);
    is_before_reg_deadline CONSTANT BOOLEAN :=
        check_is_before_reg_deadline(_course_id, _offering_id);
    result_ TEXT :=
        FORMAT('Operation rejected for Customer %s Session (%s, %s, %s)',
                _cust_id, _course_id, _offering_id, _session_id);
BEGIN
    IF can_register_course AND is_before_reg_deadline THEN
        CASE _payment_method
            WHEN 'payment' THEN
                  IF add_registers(_cust_id, _course_id, _offering_id, _session_id) IS NOT NULL
                THEN result_ = FORMAT('Payment successful for Customer %s Session (%s, %s, %s)',
                                       _cust_id, _course_id, _offering_id, _session_id);
                 END IF;
            WHEN 'redeem' THEN
                  IF add_redeems(_cust_id, _course_id, _offering_id, _session_id) IS NOT NULL
                THEN result_ = FORMAT('Redemption successful for Customer %s Session (%s, %s, %s)',
                                       _cust_id, _course_id, _offering_id, _session_id);
                 END IF;
            ELSE
                RAISE NOTICE
                    'Incorrect payment method "%", use "payment" or "redeem"',
                     _payment_method;
        END CASE;
    END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

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
            'Session has already started (% %)',
             date_, time_;
   ELSIF num_reg_ > room_cap_ THEN
         RAISE NOTICE
            'Session number of registrations (%) > room capacity (%)',
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
    RETURNS: the Session detail after successful DELETE
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
            'Session has already started (% %)',
             date_, time_;
   ELSIF num_reg_ > 0 THEN
         RAISE NOTICE
            'Number of registrations (%) > 0',
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

/* =============== END OF ROUTINES =============== */
