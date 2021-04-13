CREATE EXTENSION IF NOT EXISTS "intarray";

/* ============== START OF TRIGGERS ============== */

/* -------------- Employees Triggers -------------- */
CREATE OR REPLACE FUNCTION update_teaching_hours_func()
    RETURNS TRIGGER AS
$$
DECLARE
    session_duration_ INTEGER;
BEGIN
    SELECT duration INTO session_duration_ FROM Courses C WHERE C.course_id = NEW.course_id;
    RAISE NOTICE 'updating teachcing hours by %', session_duration_;
    IF TG_OP = 'UPDATE' THEN
        IF (NEW.eid IS DISTINCT FROM OLD.eid) THEN
            UPDATE Instructors
            SET num_teach_hours = num_teach_hours + session_duration_
            WHERE eid = NEW.eid;

            UPDATE Instructors
            SET num_teach_hours = num_teach_hours - session_duration_
            WHERE eid = OLD.eid;

            IF NEW.eid IN (SELECT eid FROM Part_time_Employees) THEN
                UPDATE Part_time_Employees
                SET num_work_hours = num_work_hours + session_duration_
                WHERE eid = NEW.eid;
            END IF;

            IF OLD.eid IN (SELECT eid FROM Part_time_Employees) THEN
                UPDATE Part_time_Employees
                SET num_work_hours = num_work_hours - session_duration_
                WHERE eid = OLD.eid;
            END IF;
        END IF;
    ELSIF TG_OP = 'INSERT' THEN

        UPDATE Instructors
        SET num_teach_hours = num_teach_hours + session_duration_
        WHERE eid = NEW.eid;

        IF NEW.eid IN (SELECT eid FROM Part_time_Employees) THEN
            UPDATE Part_time_Employees
            SET num_work_hours = num_work_hours + session_duration_
            WHERE eid = NEW.eid;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER update_teaching_hours
AFTER UPDATE OR INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION update_teaching_hours_func();

/*Trigger to add to Manages or Specializes relation table whenever there is insert to Managers or Instructors tables*/
CREATE OR REPLACE FUNCTION add_employee_course_relation_func()
    RETURNS TRIGGER AS
$$
DECLARE
    area_name_ TEXT;
BEGIN
    IF TG_TABLE_NAME = 'instructors' THEN
        FOREACH area_name_ IN ARRAY NEW.course_areas LOOP
            INSERT INTO Specializes (eid, area_name)
            VALUES (NEW.eid, area_name_);
        END LOOP;
    ELSE
        FOREACH area_name_ IN ARRAY NEW.course_areas LOOP
            INSERT INTO Manages (eid, area_name)
            VALUES (NEW.eid, area_name_);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER add_employee_course_relation
BEFORE INSERT ON Managers
FOR EACH ROW EXECUTE FUNCTION add_employee_course_relation_func();

CREATE TRIGGER add_employee_course_relation
BEFORE INSERT ON Instructors
FOR EACH ROW EXECUTE FUNCTION add_employee_course_relation_func();

/*Trigger to add new course area to Course_area table whenever a new Employee*/
CREATE OR REPLACE FUNCTION add_course_area_func()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.area_name NOT IN (SELECT * FROM Course_areas) THEN
        INSERT INTO Course_areas (area_name)
        VALUES (NEW.area_name);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER add_manage_area
BEFORE INSERT ON Manages
FOR EACH ROW EXECUTE FUNCTION add_course_area_func();

CREATE TRIGGER add_specialize_area
BEFORE INSERT ON Specializes
FOR EACH ROW EXECUTE FUNCTION add_course_area_func();

/*Trigger to add employee to Full_time Employee or Part_time_Employee table whenever they are added to Employee*/
CREATE OR REPLACE FUNCTION add_employee_type_func()
    RETURNS TRIGGER AS
$$
DECLARE
    trimmed_category_ TEXT;
BEGIN
    IF NEW.category = 'Manager' OR NEW.category = 'Administrator' OR NEW.category = 'Full-time Instructor' THEN
        INSERT INTO Full_time_Employees (eid, monthly_salary)
        VALUES (NEW.eid, NEW.salary);
    ELSE
        INSERT INTO Part_time_Employees (eid, num_work_hours, hourly_rate)
        VALUES (NEW.eid, 0, NEW.salary);
    END IF;

    IF NEW.category = 'Full-time Instructor' OR NEW.category = 'Part-time Instructor' THEN
        trimmed_category_ := 'Instructor';
        UPDATE Employees
        SET category = trimmed_category_
        WHERE eid = NEW.eid;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER add_employee_type
AFTER INSERT ON Employees
FOR EACH ROW EXECUTE FUNCTION add_employee_type_func();
/* --------------- Employees Triggers --------------- */

/* -------------- Offerings Triggers -------------- */

/* Removes Offering if total seating capacity < target number of registrations */
CREATE OR REPLACE FUNCTION remove_if_less_seat(
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
CREATE OR REPLACE FUNCTION remove_if_no_session(
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

/* Counts the number of Registers/Redeems for an Offering */
CREATE OR REPLACE FUNCTION count_signups(
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS INTEGER AS
$$
DECLARE
    num_reg_ CONSTANT INTEGER :=
        (SELECT COUNT(*) FROM Registers
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
    num_red_ CONSTANT INTEGER :=
        (SELECT COUNT(*) FROM Redeems
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
BEGIN
    RETURN num_reg_ + num_red_;
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
    ten_days_ CONSTANT INTERVAL := '10 days';
BEGIN
      IF deadline_ + ten_days_ <= NEW.session_date
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'Session date must be at least 10 days (inclusive) after % registration deadline',
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
             EXTRACT(HOURS FROM NEW.start_time), EXTRACT(HOURS FROM duration_);
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER set_end_time
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_end_time_func();

/* Assigns eid for Sessions if not provided */
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
CREATE OR REPLACE FUNCTION check_rid_available_func()
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

CREATE TRIGGER check_rid_available
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_rid_available_func();

CREATE TRIGGER check_new_rid_available_func
BEFORE UPDATE ON Sessions
FOR EACH ROW WHEN (OLD.rid IS DISTINCT FROM NEW.rid) EXECUTE FUNCTION check_rid_available_func();

/* Checks whether the Session's new room_capacity >= num_signups */
CREATE OR REPLACE FUNCTION check_new_room_cap_func()
    RETURNS TRIGGER AS
$$
DECLARE
    new_room_capacity_ CONSTANT INTEGER :=
        (SELECT seating_capacity FROM Rooms WHERE rid = NEW.rid);
    num_signups_ CONSTANT INTEGER :=
        count_signups(NEW.course_id, NEW.offering_id, NEW.session_id);
BEGIN
      IF new_room_capacity_ >= num_signups_
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'New room capacity (%) < current number of Registers + Redeems (%)',
             new_room_capacity_, num_signups_;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_new_room_cap
BEFORE UPDATE ON Sessions
FOR EACH ROW WHEN (OLD.rid IS DISTINCT FROM NEW.rid) EXECUTE FUNCTION check_new_room_cap_func();

/* Checks whether Session has already started before UPDATE/DELETE */
CREATE OR REPLACE FUNCTION modify_session_check_date_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF NOW() < (OLD.session_date + OLD.start_time)
    THEN RETURN NEW;
    ELSE RAISE NOTICE
            'Cannot UPDATE/DELETE Sessions that has already started (% %)',
             OLD.session_date, OLD.start_time;
         RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER modify_session_check_date
BEFORE UPDATE OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION modify_session_check_date_func();

/* Checks whether Session has at least 1 Register/Redeem before DELETE */
CREATE OR REPLACE FUNCTION delete_session_check_has_signup_func()
    RETURNS TRIGGER AS
$$
DECLARE
    num_registers_ CONSTANT INTEGER :=
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) =
                (OLD.course_id, OLD.offering_id, OLD.session_id));
    num_redeems_ CONSTANT INTEGER :=
        (SELECT count(*) FROM Redeems
          WHERE (course_id, offering_id, session_id) =
                (OLD.course_id, OLD.offering_id, OLD.session_id));
BEGIN
      IF (num_registers_ + num_redeems_) > 0
    THEN RAISE NOTICE
            'Cannot delete Sessions that has at least 1 signup (Registers: %, Redeems: %)',
             num_registers_, num_redeems_;
         RETURN NULL;
    ELSE RETURN OLD;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER delete_session_check_has_signup
BEFORE DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION delete_session_check_has_signup_func();

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

/* Removes the Session's parent Offering if it has no more Session */
CREATE OR REPLACE FUNCTION remove_empty_offerings_func()
    RETURNS TRIGGER AS
$$
BEGIN
    PERFORM remove_if_no_session(OLD.course_id, OLD.offering_id);
    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER remove_empty_offerings
AFTER DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION remove_empty_offerings_func();

/* Checks that a Customer Registers/Redeems only 1 Session of the same Course */
CREATE OR REPLACE FUNCTION check_can_signup_course(
    _cust_id INTEGER,
    _course_id INTEGER)
    RETURNS BOOLEAN AS
$$
DECLARE
    reg_offering_id_ INTEGER;
    reg_session_id_ INTEGER;
    red_offering_id_ INTEGER;
    red_session_id_ INTEGER;
BEGIN
    SELECT offering_id, session_id
      INTO reg_offering_id_, reg_session_id_
      FROM get_registers(_cust_id)
     WHERE course_id = _course_id;

    SELECT offering_id, session_id
      INTO red_offering_id_, red_session_id_
      FROM get_redeems(_cust_id)
     WHERE course_id = _course_id;

      IF reg_offering_id_ IS NOT NULL
    THEN RAISE NOTICE
            'Customer has already registered a Session (%, %, %) from this Course',
             _course_id, reg_offering_id_, reg_session_id_;
         RETURN FALSE;
   ELSIF red_offering_id_ IS NOT NULL
    THEN RAISE NOTICE
            'Customer has already redeemed a Session (%, %, %) from this Course',
             _course_id, red_offering_id_, red_session_id_;
         RETURN FALSE;
    ELSE RETURN TRUE;
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
            'Registration deadline % for Session of Offering (%, %) has elapsed',
             reg_deadline_ + one_day_, _course_id, _offering_id;
         RETURN FALSE;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Checks whether a Session is cancellable, i.e. now  <= session_ts */
CREATE OR REPLACE FUNCTION check_is_session_cancellable(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS BOOLEAN AS
$$
DECLARE
    session_date_ DATE;
    start_time_ TIME;
BEGIN
    SELECT session_date, start_time
      INTO session_date_, start_time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF NOW() < (session_date_ + start_time_)
    THEN RETURN TRUE;
    ELSE RAISE NOTICE
            'Cancellable period % for Session (%, %, %) has elapsed',
             session_date_ + start_time_, _course_id, _offering_id, _session_id;
         RETURN FALSE;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Checks whether a Session is refundable, i.e. now + 7 days <= session_date  */
CREATE OR REPLACE FUNCTION check_is_session_refundable(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS BOOLEAN AS
$$
DECLARE
    session_date_ CONSTANT DATE :=
        (SELECT session_date FROM Sessions
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
    seven_days_ CONSTANT INTERVAL := '7 days';
BEGIN
      IF (NOW() + seven_days_) <= session_date_
    THEN RETURN TRUE;
    ELSE RETURN FALSE;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Counts the number of Registers/Redeems for a Session */
CREATE OR REPLACE FUNCTION count_signups(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS INTEGER AS
$$
DECLARE
    num_reg_ CONSTANT INTEGER :=
        (SELECT COUNT(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
    num_red_ CONSTANT INTEGER :=
        (SELECT COUNT(*) FROM Redeems
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
BEGIN
    RETURN num_reg_ + num_red_;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Sessions Triggers -------------- */

/* -------------- Rooms Triggers -------------- */

/* Counts the number of remaining seats of the Offering */
CREATE OR REPLACE FUNCTION count_remain_seats(
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS INTEGER AS
$$
DECLARE
    offering_capacity_ CONSTANT INTEGER :=
        (SELECT seating_capacity
           FROM Offerings
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
BEGIN
    RETURN offering_capacity_ - count_signups(_course_id, _offering_id);
END;
$$
LANGUAGE PLPGSQL;

/* Counts the number of remaining seats of the Session */
CREATE OR REPLACE FUNCTION count_remain_seats(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS INTEGER AS
$$
DECLARE
    room_capacity_ CONSTANT INTEGER :=
        (SELECT seating_capacity
           FROM Sessions LEFT JOIN Rooms USING (rid)
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
BEGIN
    RETURN room_capacity_ - count_signups(_course_id, _offering_id, _session_id);
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Rooms Triggers -------------- */

/* -------------- Credit Card Triggers -------------- */

/* This function queries the latest cc_number Owns by a Customer */
CREATE OR REPLACE FUNCTION get_latest_cc_number(
    _cust_id INTEGER)
    RETURNS VARCHAR(19) AS
$$
    SELECT cc_number
      FROM Owns
     WHERE cust_id = _cust_id
     ORDER BY owns_ts DESC LIMIT 1;
$$
LANGUAGE SQL;

/* This function queries the latest cc_number Owns by a Customer */
CREATE OR REPLACE FUNCTION get_all_cc_numbers(
    _cust_id INTEGER)
    RETURNS SETOF VARCHAR(19) AS
$$
    SELECT cc_number
      FROM Owns
     WHERE cust_id = _cust_id
     ORDER BY owns_ts DESC;
$$
LANGUAGE SQL;

/* -------------- Credit Card Triggers -------------- */

/* -------------- Registers Triggers -------------- */

/* Checks if Session still has seats */
CREATE OR REPLACE FUNCTION check_has_seats_reg_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF count_remain_seats(NEW.course_id, NEW.offering_id, NEW.session_id) > 0
    THEN RETURN NEW;
    ELSE RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_has_seats_reg
BEFORE INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION check_has_seats_reg_func();

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
        (get_latest_cc_number(_cust_id), _course_id, _offering_id, _session_id)
    RETURNING *;
$$
LANGUAGE SQL;

/* This function returns a list of Registers by the Customer */
CREATE OR REPLACE FUNCTION get_registers(
    _cust_id INTEGER)
    RETURNS SETOF Registers AS
$$
    SELECT R.*
      FROM Registers R LEFT JOIN Owns USING (cc_number)
     WHERE cust_id = _cust_id;
$$
LANGUAGE SQL;

/* This function updates the Session of a Registers entry.
    RETURNS: the result of the new Register after successful UPDATE */
CREATE OR REPLACE FUNCTION update_registers_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _new_session_id INTEGER)
    RETURNS Registers AS
$$
DECLARE
    update_reg_ts_ CONSTANT TIMESTAMP :=
        (SELECT registers_ts FROM get_registers(_cust_id)
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
    result_ Registers;
BEGIN
      IF update_reg_ts_ IS NULL
    THEN RAISE NOTICE
             'Previous registration record for Customer % Course (%, %) not found',
              _cust_id, _course_id, _offering_id;
    ELSE UPDATE Registers
            SET session_id = _new_session_id
          WHERE registers_ts = update_reg_ts_
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* This function deletes the Session of a Registers entry. */
CREATE OR REPLACE FUNCTION delete_registers_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Registers AS
$$
DECLARE
    delete_reg_ts_ CONSTANT TIMESTAMP :=
        (SELECT registers_ts FROM get_registers(_cust_id)
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
    result_ Registers;
BEGIN
      IF check_is_session_cancellable(_course_id, _offering_id, _session_id)
    THEN DELETE FROM Registers
          WHERE registers_ts = delete_reg_ts_
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Registers Triggers -------------- */

/* -------------- Redeems Triggers -------------- */

/* Checks if Session still has seats */
CREATE OR REPLACE FUNCTION check_has_seats_red_func()
    RETURNS TRIGGER AS
$$
BEGIN
      IF count_remain_seats(NEW.course_id, NEW.offering_id, NEW.session_id) > 0
    THEN RETURN NEW;
    ELSE RETURN NULL;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_has_seats_red
BEFORE INSERT OR UPDATE ON Redeems
FOR EACH ROW EXECUTE FUNCTION check_has_seats_red_func();

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
    buys_ts_ CONSTANT TIMESTAMP := (SELECT buys_ts FROM get_redeemable_buys(_cust_id));
    result_ Redeems;
BEGIN
      IF buys_ts_ IS NULL
    THEN RAISE NOTICE 'No redeemable package';
    ELSE INSERT INTO Redeems
             (buys_ts, course_id, offering_id, session_id) VALUES
             (buys_ts_, _course_id, _offering_id, _session_id)
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* This function returns a list of Redeems by the Customer */
CREATE OR REPLACE FUNCTION get_redeems(
    _cust_id INTEGER)
    RETURNS SETOF Redeems AS
$$
    SELECT R.*
      FROM Redeems R
               LEFT JOIN Buys USING (buys_ts)
               LEFT JOIN Owns USING (cc_number)
     WHERE cust_id = _cust_id;
$$
LANGUAGE SQL;

/* This function updates the Session of a Redeems entry.
    RETURNS: the result of the new Redeems after successful UPDATE */
CREATE OR REPLACE FUNCTION update_redeems_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _new_session_id INTEGER)
    RETURNS Redeems AS
$$
DECLARE
    update_red_ts_ CONSTANT TIMESTAMP :=
        (SELECT redeems_ts FROM get_redeems(_cust_id)
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
    result_ Redeems;
BEGIN
      IF update_red_ts_ IS NULL
    THEN RAISE NOTICE
             'Previous redemption record for Customer % Course (%, %) not found',
              _cust_id, _course_id, _offering_id;
    ELSE UPDATE Redeems
            SET session_id = _new_session_id
          WHERE redeems_ts = update_red_ts_
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* This function deletes the Session of a Redeems entry. */
CREATE OR REPLACE FUNCTION delete_redeems_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Redeems AS
$$
DECLARE
    delete_red_ts_ CONSTANT TIMESTAMP :=
        (SELECT redeems_ts FROM get_redeems(_cust_id)
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
    result_ Redeems;
BEGIN
      IF check_is_session_cancellable(_course_id, _offering_id, _session_id)
    THEN DELETE FROM Redeems
          WHERE redeems_ts = delete_red_ts_
         RETURNING * INTO result_;
     END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* -------------- Redeems Triggers -------------- */

/* -------------- Buys Triggers -------------- */

/* Checks whether the Customer has active Package before Buying new Package */
CREATE OR REPLACE FUNCTION check_has_active_package_func()
    RETURNS TRIGGER AS
$$
DECLARE
    cust_id_ INTEGER;
BEGIN
    SELECT cust_id
      INTO cust_id_
      FROM Owns
     WHERE cc_number = NEW.cc_number;

      IF get_active_or_partial_buys(cust_id_) IS NOT NULL
    THEN RAISE NOTICE
             'Customer % still has active/partially active Package %',
              cust_id_, get_active_or_partial_buys(cust_id_);
         RETURN NULL;
    ELSE RETURN NEW;
     END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_has_active_package
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_has_active_package_func();

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

/* This function returns the Customer's Buys that can be used to redeem Session */
CREATE OR REPLACE FUNCTION get_redeemable_buys(
    _cust_id INTEGER)
    RETURNS Buys AS
$$
    SELECT B.*
      FROM Buys B LEFT JOIN Owns USING (cc_number)
     WHERE cust_id = _cust_id
           AND num_remain_redeem > 0;
$$
LANGUAGE SQL;

/* This function returns the Customer's active/partially package Buys information */
CREATE OR REPLACE FUNCTION get_active_or_partial_buys(
    _cust_id INTEGER)
    RETURNS Buys AS
$$
      WITH partially_active_buys_ts AS
               (SELECT buys_ts FROM get_redeems(_cust_id)
                 WHERE check_is_session_refundable(course_id, offering_id, session_id))
    SELECT B.*
      FROM Buys B LEFT JOIN Owns USING (cc_number)
     WHERE cust_id = _cust_id
           AND (num_remain_redeem > 0
                OR buys_ts IN (SELECT buys_ts FROM partially_active_buys_ts));
$$
LANGUAGE SQL;

/* -------------- Buys Triggers -------------- */

/* =============== END OF TRIGGERS =============== */



/* ============== START OF ROUTINES ============== */

/* --------------- Customers Routines --------------- */

/* 3. add_customer
    This routine is used to add a new customer.
    RETURNS: the Customer after successful INSERT */
CREATE OR REPLACE FUNCTION add_customer(
    _name TEXT,
    _address TEXT,
    _phone VARCHAR(15),
    _email TEXT,
    _cc_number VARCHAR(19),
    _cvv INTEGER,
    _expiry_date DATE)
    RETURNS Customers AS
$$
DECLARE 
    result_ Customers;
    next_cid_ INTEGER;
BEGIN

    SELECT COUNT(*) + 1 FROM Customers INTO next_cid_;

    INSERT INTO Credit_cards (cc_number, cvv, expiry_date) 
    VALUES (_cc_number, _cvv, _expiry_date);
    
    INSERT INTO Customers (name, address, email, phone) 
    VALUES (_name, _address, _email, _phone)
    RETURNING * INTO result_;

    INSERT INTO Owns (cc_number, cust_id) 
    VALUES (_cc_number, next_cid_);

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Customers Routines --------------- */

/* --------------- Credit Cards Routines --------------- */

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

/* --------------- Credit Cards Routines --------------- */

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
             FROM Sessions S LEFT JOIN Rooms R2 ON (S.rid = R2.rid)
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
    RETURNS TABLE (rid INTEGER,
                   room_capacity INTEGER,
                   day DATE,
                   hour INTEGER ARRAY) AS
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
                (SELECT EXTRACT(HOURS FROM start_time),
                        EXTRACT(HOURS FROM end_time) - 1
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
    PERFORM remove_if_less_seat(_course_id, _offering_id, _target_num_reg);
    PERFORM remove_if_no_session(_course_id, _offering_id);

    /* Store the inserted Offering into result_ */
    SELECT * INTO result_
      FROM Offerings
     WHERE (course_id, offering_id) = (_course_id, _offering_id);

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* 15. get_available_course_offerings
    This routine is used to retrieve all the available course offerings that could be registered.
    RETURNS: a table of RECORD for each offerings */
CREATE OR REPLACE FUNCTION get_available_course_offerings()
    RETURNS TABLE (course_title TEXT,
                   course_area TEXT,
                   start_date DATE,
                   end_date DATE,
                   reg_deadline DATE,
                   course_fees INTEGER,
                   num_remain_seats INTEGER) AS
$$
    SELECT title AS course_title,
           area_name AS course_area,
           start_date,
           end_date,
           reg_deadline,
           fees AS course_fees,
           count_remain_seats(course_id, offering_id) AS num_remain_seats
      FROM Offerings LEFT JOIN Courses USING (course_id)
     WHERE NOW() < reg_deadline
     ORDER BY reg_deadline, title;
$$
LANGUAGE SQL;

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

/* 14. get_my_course_package
    This routine is used when a customer requests to view his/her active/partially active course
    package.
    RETURNS: a JSON result */
CREATE OR REPLACE FUNCTION get_my_course_package(
    _cust_id INTEGER)
    RETURNS JSON AS
$$
DECLARE
    result1_ RECORD;
    result2_ RECORD;
    redeemed_sessions_ JSON;
BEGIN
    SELECT package_id,
           DATE(buys_ts) AS purchase_date,
           num_remain_redeem AS num_redeem_available
      INTO result1_
      FROM get_active_or_partial_buys(_cust_id);

    SELECT name AS package_name,
           price AS package_price,
           num_free_reg AS total_num_free_sessions
      INTO result2_
      FROM Packages
     WHERE package_id = result1_.package_id;

      WITH redeemed_sessions_cte_ AS (
               SELECT title,
                      session_date,
                      start_time
                 FROM get_redeems(_cust_id)
                          LEFT JOIN Buys USING (buys_ts)
                          LEFT JOIN Sessions USING (course_id, offering_id, session_id)
                          LEFT JOIN Courses USING (course_id)
                WHERE package_id = result1_.package_id
                ORDER BY session_date, start_time)
    SELECT JSONB_AGG(
             JSONB_BUILD_OBJECT(
                 'course_name', title,
                 'session_date', session_date,
                 'start_time', start_time))
      INTO redeemed_sessions_
      FROM redeemed_sessions_cte_;

    RETURN JSONB_PRETTY(
               TO_JSONB(result1_) || TO_JSONB(result2_) ||
               JSONB_BUILD_OBJECT('redeemed_sessions', redeemed_sessions_));
END;
$$
LANGUAGE PLPGSQL;

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
    INSERT INTO Buys
        (package_id, cc_number) VALUES
        (_package_id, get_latest_cc_number(_cust_id))
    RETURNING *;
$$
LANGUAGE SQL;

/* --------------- Buys Routines --------------- */

/* --------------- Registers Routines --------------- */

/* 18. get_my_registrations
    This routine is used when a customer requests to view his/her active course registrations.
    RETURNS: a table of RECORD for each active Registers/Redeems */
CREATE OR REPLACE FUNCTION get_my_registrations(
    _cust_id INTEGER)
    RETURNS TABLE (course_name TEXT,
                   course_fees INTEGER,
                   session_date DATE,
                   start_hour TIME,
                   session_duration INTEGER,
                   instructor_name TEXT) AS
$$
    WITH signed_up_sessions AS (
        SELECT course_id, offering_id, session_id
          FROM get_registers(_cust_id)
        UNION
        SELECT course_id, offering_id, session_id
          FROM get_redeems(_cust_id)
    )
    SELECT title AS course_name,
           fees AS course_fees,
           session_date,
           start_time AS start_hour,
           duration AS session_duration,
           'Bob' AS instructor_name
  -- TODO: name AS instructor_name
      FROM signed_up_sessions
               LEFT JOIN Sessions S USING (course_id, offering_id, session_id)
               LEFT JOIN Offerings USING (course_id, offering_id)
               LEFT JOIN Courses USING (course_id)
      -- TODO: LEFT JOIN Employees E ON (E.eid = S.eid)
     WHERE NOW() < session_date + start_time
     ORDER BY session_date, start_time;
$$
LANGUAGE SQL;

/* 19. update_course_session
    This routine is used when a customer requests to change a registered course session
    to another session.
    RETURNS: a TEXT status */
CREATE OR REPLACE FUNCTION update_course_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _new_session_id INTEGER)
    RETURNS TEXT AS
$$
DECLARE
    is_registered_ CONSTANT BOOLEAN :=
        (_course_id, _offering_id) IN
            (SELECT course_id, offering_id FROM get_registers(_cust_id));
    is_redeemed_ CONSTANT BOOLEAN :=
        (_course_id, _offering_id) IN
            (SELECT course_id, offering_id FROM get_redeems(_cust_id));
BEGIN
    CASE
        WHEN is_registered_ THEN
              IF update_registers_session(
                     _cust_id, _course_id, _offering_id, _new_session_id) IS NOT NULL
            THEN RETURN FORMAT('Registration successful for Customer %s Session (%s, %s, %s)',
                                _cust_id, _course_id, _offering_id, _new_session_id);
             END IF;
        WHEN is_redeemed_ THEN
              IF update_redeems_session(
                     _cust_id, _course_id, _offering_id, _new_session_id) IS NOT NULL
            THEN RETURN FORMAT('Redemption successful for Customer %s Session (%s, %s, %s)',
                                _cust_id, _course_id, _offering_id, _new_session_id);
             END IF;
        ELSE
            RAISE NOTICE
                'Record for Customer % Course (%, %) not found',
                 _cust_id, _course_id, _offering_id;
    END CASE;

    RETURN FORMAT('Operation rejected for Customer %s Session (%s, %s, %s)',
                   _cust_id, _course_id, _offering_id, _new_session_id);
END;
$$
LANGUAGE PLPGSQL;

/* 20. cancel_registration
    This routine is used when a customer requests to cancel a registered/redeemed course session.
    RETURNS: a TEXT status */
CREATE OR REPLACE FUNCTION cancel_registration(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS TEXT AS
$$
DECLARE
    regist_ses_id_ CONSTANT INTEGER :=
        (SELECT session_id FROM get_registers(_cust_id)
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
    redeem_ses_id_ CONSTANT INTEGER :=
        (SELECT session_id FROM get_redeems(_cust_id)
          WHERE (course_id, offering_id) = (_course_id, _offering_id));
BEGIN
    CASE
        WHEN regist_ses_id_ IS NOT NULL THEN
              IF delete_registers_session(
                     _cust_id, _course_id, _offering_id, regist_ses_id_) IS NOT NULL
            THEN RETURN FORMAT('Cancellation successful for Customer %s Session (%s, %s, %s)',
                                _cust_id, _course_id, _offering_id, regist_ses_id_);
             END IF;
        WHEN redeem_ses_id_ IS NOT NULL THEN
              IF delete_redeems_session(
                     _cust_id, _course_id, _offering_id, redeem_ses_id_) IS NOT NULL
            THEN RETURN FORMAT('Cancellation successful for Customer %s Session (%s, %s, %s)',
                                _cust_id, _course_id, _offering_id, redeem_ses_id_);
             END IF;
        ELSE
            RAISE NOTICE
                'Record for Customer % Course (%, %) not found',
                 _cust_id, _course_id, _offering_id;
    END CASE;

    RETURN FORMAT('Operation rejected for Customer %s Offering (%s, %s)',
                   _cust_id, _course_id, _offering_id);
END;
$$
LANGUAGE PLPGSQL;

/* --------------- Registers Routines --------------- */

/* --------------- Sessions Routines --------------- */

/* 16. get_available_course_sessions
    This routine is used to retrieve all the available sessions for a course offering that
    could be registered.
    RETURNS: a table of RECORD for each available Sessions */
CREATE OR REPLACE FUNCTION get_available_course_sessions(
    _course_id INTEGER,
    _offering_id INTEGER)
    RETURNS TABLE (session_date DATE,
                   start_hour TIME,
                   instructor_name TEXT,
                   num_remain_seats INTEGER) AS
$$
    SELECT session_date,
           start_time AS start_hour,
           'Bob' AS instructor_name,
  -- TODO: name AS instructor_name
           count_remain_seats(course_id, offering_id, session_id) AS num_remain_seats
      FROM Sessions S
              LEFT JOIN Offerings USING (course_id, offering_id)
              LEFT JOIN Courses USING (course_id)
     -- TODO: LEFT JOIN Employees E ON (E.eid = S.eid)
     WHERE NOW() < reg_deadline
     ORDER BY session_date, start_time;
$$
LANGUAGE SQL;

/* 17. register_session
    This routine is used when a customer requests to register for a session in a course offering.
    RETURNS: a TEXT status  */
CREATE OR REPLACE FUNCTION register_session(
    _cust_id INTEGER,
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER,
    _payment_method TEXT)
    RETURNS TEXT AS
$$
DECLARE
    can_signup_course CONSTANT BOOLEAN :=
        check_can_signup_course(_cust_id, _course_id);
    is_before_reg_deadline CONSTANT BOOLEAN :=
        check_is_before_reg_deadline(_course_id, _offering_id);
BEGIN
    IF can_signup_course AND is_before_reg_deadline THEN
        CASE _payment_method
            WHEN 'payment' THEN
                  IF add_registers(_cust_id, _course_id, _offering_id, _session_id) IS NOT NULL
                THEN RETURN FORMAT('Payment successful for Customer %s Session (%s, %s, %s)',
                                    _cust_id, _course_id, _offering_id, _session_id);
                 END IF;
            WHEN 'redeem' THEN
                  IF add_redeems(_cust_id, _course_id, _offering_id, _session_id) IS NOT NULL
                THEN RETURN FORMAT('Redemption successful for Customer %s Session (%s, %s, %s)',
                                    _cust_id, _course_id, _offering_id, _session_id);
                 END IF;
            ELSE
                RAISE NOTICE
                    'Incorrect payment method "%", use "payment" or "redeem"',
                     _payment_method;
        END CASE;
    END IF;

    RETURN FORMAT('Operation rejected for Customer %s Session (%s, %s, %s)',
                   _cust_id, _course_id, _offering_id, _session_id);
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
    UPDATE Sessions
       SET rid = _rid
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
    RETURNING *;
$$
LANGUAGE SQL;

/* 23. remove_session
    This routine is used to remove a course session.
    RETURNS: the Session detail after successful DELETE */
CREATE OR REPLACE FUNCTION remove_session(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Sessions AS
$$
    DELETE FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id)
    RETURNING *;
$$
LANGUAGE SQL;

/* 23. remove_session VERSION 2 FOR DEMO PURPOSE ONLY */
CREATE OR REPLACE FUNCTION remove_session_v2(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER)
    RETURNS Sessions AS
$$
DECLARE
    session_date_ DATE;
    start_time_ TIME;
    num_reg_ CONSTANT INTEGER :=
        (SELECT count(*) FROM Registers
          WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id));
    result_ Sessions;
BEGIN
    SELECT session_date, start_time
      INTO session_date_, start_time_
      FROM Sessions
     WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);

      IF (session_date_ + start_time_) < NOW()
    THEN RAISE NOTICE
            'Session has already started (% %)',
             session_date_, start_time_;
   ELSIF num_reg_ > 0
    THEN RAISE NOTICE
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

/* --------------- Employees Routines --------------- */

/* 1. add_employee
    This routine is used to add a new employee.

    Course area is non-empty -> Administrator must have empty course area, while Manager and Instructor must have non-empty course area*/
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
DECLARE
    next_eid_ INTEGER;
    trimmed_category_ TEXT;
    area_name_ TEXT;
    result_ Employees;
BEGIN
    SELECT COUNT(*) + 1 FROM Employees INTO next_eid_;

    IF _category = 'Full-time Instructor' OR _category = 'Part-time Instructor' THEN
        trimmed_category_ := 'Instructor';
    ELSE
        trimmed_category_ := _category;
    END IF;
    
    /*Course area is non-empty*/
    IF array_length(_course_area_set, 1) >= 1 THEN
        /*Invalid if category is Administrator*/
        IF _category = 'Administrator' THEN
            RAISE NOTICE
                'Cannot add employee of type Administrator because course area set should not be specified for Administrators, skipping...';
        /*If category is Manager or Instructor, then add to Manager or Instructor table*/
        ELSIF _category = 'Manager' OR _category = 'Full-time Instructor' OR _category = 'Part-time Instructor' THEN
            INSERT INTO Employees
                (ename, phone_number, home_address, email_address, join_date, category, salary)
                VALUES
                (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary)
                RETURNING * INTO result_;
            IF _category = 'Manager' THEN
                INSERT INTO Managers (eid, course_areas)
                VALUES (next_eid_, _course_area_set);
            ELSE
                INSERT INTO Instructors (eid, num_teach_hours, course_areas)
                VALUES (next_eid_, 0, _course_area_set);
            END IF;
        ELSE
            RAISE NOTICE 'Cannot add employee because employee category is invalid, skipping...';
        END IF;
    ELSE  /*Course area is empty*/
        IF _category = 'Manager' OR _category = 'Full-time Instructor' OR _category = 'Part-time Instructor' THEN
            RAISE NOTICE
                'Cannot add employee of type % because course area set specified is empty or invalid, skipping...', _category;
        ELSIF _category = 'Administrator' THEN
            INSERT INTO Employees
                (ename, phone_number, home_address, email_address, join_date, category, salary)
                VALUES
                (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary)
                RETURNING * INTO result_;
            INSERT INTO Administrators (eid)
                VALUES(next_eid_);
        ELSE
            RAISE NOTICE 'Cannot add employee because employee category is invalid, skipping...';
        END IF;
    END IF;
    -- UPDATE result_ SET category = trimmed_category_;
    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/* 
2. remove_employee
    This routine is used to update an employee’s departed date a non-null value.
    RETURNS: the Employee detail after successful DELETE */
CREATE OR REPLACE FUNCTION remove_employee(
    _eid INTEGER,
    _depart_date DATE)
    RETURNS Employees AS
$$
DECLARE
    employee_type_ TEXT;
    result_ Employees;
BEGIN

    IF _eid NOT IN (SELECT E.eid FROM Employees E) THEN
        RAISE NOTICE
            'Employee not found, skipping...';
        RETURN NULL;
    END IF;

    SELECT E.category INTO employee_type_
        FROM Employees E
        WHERE E.eid = _eid;
    IF employee_type_ = 'Manager' AND _eid IN (SELECT eid FROM Manages) THEN
        RAISE NOTICE
            'Cannot remove employee, as employee is a manager managing some area';
    ELSIF employee_type_ = 'Administrator' AND _eid IN
        (SELECT A.eid FROM Offerings O, Administrators A WHERE O.reg_deadline > _depart_date) THEN
        RAISE NOTICE
            'Cannot remove employee, as employee is an administrator handling a course offering with a registration deadline that is after employee depart date';
    ELSIF employee_type_ = 'Instructor' AND _eid IN 
        (SELECT I.eid FROM Sessions S, Instructors I WHERE S.session_date > _depart_date) THEN
        RAISE NOTICE
            'Cannot remove employee, as employee is an instructor who is teaching some course session that starts after employee depart date';
    ELSE
        UPDATE Employees
        SET depart_date = _depart_date
        WHERE eid = _eid
        RETURNING * INTO result_;
    END IF;
    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/*Removes manages relation and empties course_areas for the specified manager*/
CREATE OR REPLACE FUNCTION stop_managing(eid_ INTEGER)
RETURNS Managers AS
$$
DECLARE
    result_ Managers;
BEGIN
    IF eid_ NOT IN (SELECT eid FROM Managers) THEN
        RAISE NOTICE 'Manager with specified eid % is not found, skipping...', eid_;
    ELSE
        DELETE FROM Manages WHERE eid = eid_;
        UPDATE Managers
        SET course_areas = '{}'
        WHERE eid = eid_
        RETURNING * INTO result_;
    END IF;
    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/*TODO: trigger add work hour/day when session/offering is assigned to Employees*/
/*TODO: trigger add teaching_hour when session is assigned to Instructor*/




/* 6. find_instructors
    This routine is used to find all the instructors who could be assigned to teach a course session. */
/*Function designates that Instructor can be assigned to a course session if
1. Instructor should specialize in the course area that course belongs to
2. Instructor can teach at most 1 course session in an hour
3. There must be an hour of break for Instructor between sessions
4. Part-time Instructor's total number of hour taught this month < 30*/
CREATE OR REPLACE FUNCTION find_instructors(
    _course_id INTEGER,
    _session_date DATE,
    _session_start_hour TIME,
    _session_end_hour TIME)
RETURNS TABLE(
    eid INTEGER,
    ename TEXT
) AS
$$
DECLARE
    course_area_ TEXT;
    one_hour_ INTERVAL;
BEGIN
    one_hour_ := '01:00';

    SELECT area_name INTO course_area_
    FROM Courses C WHERE C.course_id = _course_id;

    RETURN QUERY SELECT E.eid, E.ename
    FROM Employees E
    WHERE E.eid IN (SELECT S1.eid
                  FROM Specializes S1
                  WHERE area_name = course_area_)
    AND E.eid IN (SELECT E2.eid
                    FROM Employees E2
                    WHERE E2.depart_date IS NULL OR E2.depart_date > _session_date)
    AND E.eid NOT IN (SELECT S2.eid 
                    FROM Sessions S2
                    WHERE S2.session_date = _session_date 
                    AND (
                    (_session_start_hour BETWEEN S2.start_time - one_hour_ AND S2.end_time + one_hour_) 
                    OR (_session_end_hour BETWEEN S2.start_time - one_hour_ AND S2.end_time + one_hour_) 
                    OR (_session_start_hour < S2.start_time AND _session_end_hour > S2.end_time)))
    AND E.eid NOT IN (SELECT PTE.eid
                    FROM Part_time_Employees PTE
                    WHERE num_work_hours >= 30)
    AND (_session_start_hour BETWEEN '09:00' AND '11:00' 
        OR  _session_start_hour BETWEEN '14:00' AND '17:00')
    AND _session_end_hour < '18:00';
END;
$$
LANGUAGE PLPGSQL;


/* 7. get_available_instructors
    This routine is used to retrieve the availability information of instructors who could be assigned to teach a specified course. */
CREATE OR REPLACE FUNCTION get_available_instructors(
    _course_id INTEGER,
    _start_date DATE,
    _end_date DATE)
RETURNS TABLE (eid INTEGER,
    ename TEXT,
    total_teaching_hours INTEGER,
    day DATE,
    available_hours INTEGER ARRAY
) AS
$$
DECLARE
    course_area_ TEXT;
    eid_ INTEGER;
    total_hour_ INTEGER ARRAY;
    lunch_hour_ INTEGER ARRAY;
    busy_hour_ INTEGER ARRAY;
    t1_ INTEGER;
    t2_ INTEGER;
BEGIN
    SELECT area_name INTO course_area_
    FROM Courses C WHERE C.course_id = _course_id;
    /*for each instructor*/
    FOR eid_ IN (SELECT S.eid 
                    FROM Specializes S
                    WHERE area_name = course_area_
                        AND S.eid NOT IN (SELECT PTE.eid
                            FROM Part_time_Employees PTE
                            WHERE PTE.num_work_hours >= 30)) LOOP
        RAISE NOTICE 'Instructor %', eid_;
        eid := eid_;
        total_teaching_hours := (SELECT num_teach_hours 
                                FROM Instructors I 
                                WHERE I.eid = eid_);

        ename := (SELECT E.ename FROM Employees E WHERE E.eid = eid_);
        FOR day IN (SELECT GENERATE_SERIES(_start_date, _end_date, '1 day')) LOOP
            total_hour_ := ARRAY(SELECT GENERATE_SERIES(9, 17)); -- initialize free hour [9, 17]
            lunch_hour_ := ARRAY(SELECT GENERATE_SERIES(12, 13)); -- lunch breaks
            available_hours := total_hour_ - lunch_hour_; -- remove lunch breaks
            FOR t1_, t2_ IN
                (SELECT EXTRACT(HOURS FROM start_time) - 1,
                        EXTRACT(HOURS FROM end_time)
                    FROM Sessions S
                    WHERE S.session_date = day
                        AND S.eid = eid_) LOOP
                busy_hour_ := ARRAY(SELECT GENERATE_SERIES(t1_, t2_)); -- busy hours
                available_hours := available_hours - busy_hour_; -- remove busy hours
            END LOOP;
            RETURN NEXT;
        END LOOP;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;


/* 21. update_instructors
    This routine is used when a customer requests to change a registered course session to another session.
    */
CREATE OR REPLACE FUNCTION update_instructors(
    _course_id INTEGER,
    _offering_id INTEGER,
    _session_id INTEGER,
    _new_instructor_id INTEGER)
RETURNS VOID AS
$$
DECLARE
    start_date_ DATE;
    start_time_ TIME;
    end_time_ TIME;
    session_interval_ INTEGER ARRAY;
    available_hours_ INTEGER ARRAY;
    instructor_available_ BOOLEAN;
    num_ INTEGER;
    t1_ INTEGER;
    t2_ INTEGER;
BEGIN
    SELECT session_date, start_time, end_time INTO start_date_, start_time_, end_time_
        FROM Sessions
        WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);
    IF (start_date_ + start_time_) < NOW() THEN
        RAISE NOTICE 
            'Session already started, cannot update instructor, skipping...';
    ELSE
        IF NOT EXISTS (SELECT * FROM get_available_instructors(_course_id, start_date_, start_date_) WHERE eid = _new_instructor_id) THEN
            RAISE NOTICE 
                'TEST New instructor specified is not available for the session, cannot update instructor, skipping...';
        ELSE /*Instructor have available times, check if times match session*/
            instructor_available_ := TRUE;
            t1_ := EXTRACT(HOURS FROM start_time_);
            t2_ := EXTRACT(HOURS FROM end_time_) - 1;
            session_interval_ := ARRAY(SELECT GENERATE_SERIES(t1_, t2_));
            SELECT available_hours INTO available_hours_
            FROM get_available_instructors(_course_id, start_date_, start_date_)
            WHERE eid = _new_instructor_id AND start_date_ = day;
            RAISE NOTICE 'Session_interval: %', session_interval_;

            FOREACH num_ IN ARRAY session_interval_ LOOP
                /*If any hour in session_interval is not in available hours, set instructor_available to false*/
                IF NOT num_ = ANY(available_hours_) THEN
                    RAISE NOTICE '% is not within available hours', num_;
                    instructor_available_ = FALSE;
                END IF;
            END LOOP;
            IF NOT instructor_available_ THEN
                RAISE NOTICE 
                'New instructor specified is not available for the session, cannot update instructor, skipping...';
            ELSE
                UPDATE Sessions
                SET eid = _new_instructor_id
                WHERE (course_id, offering_id, session_id) = (_course_id, _offering_id, _session_id);
            END IF;
        END IF;
    END IF;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION pay_salary_helper()
RETURNS TABLE (
    eid INTEGER,
    ename TEXT,
    e_status TEXT,
    num_work_days INTEGER,
    num_work_hours INTEGER,
    monthly_salary INTEGER,
    hourly_rate INTEGER,
    salary_amount_paid INTEGER
) AS
$$
DECLARE
    first_day_of_month_ DATE;
    last_day_of_month_ DATE;
    num_of_days_in_month_ INTEGER;
    e_join_date_ DATE;
    e_depart_date_ DATE;
    eid_ INTEGER;
BEGIN
    SELECT INTO last_day_of_month_ (DATE_TRUNC('month', NOW()::DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    SELECT INTO first_day_of_month_ (DATE_TRUNC('month', NOW()::DATE))::DATE;

    num_of_days_in_month_ = last_day_of_month_ - first_day_of_month_ + 1;

    /*Loop through employees that have not departed or just departed this month*/
    FOR eid_ IN (SELECT E.eid FROM Employees E WHERE E.eid NOT IN 
            (SELECT E2.eid FROM Employees E2 WHERE E2.depart_date IS NOT NULL AND E2.depart_date < first_day_of_month_))  LOOP
        eid := eid_;
        SELECT E.ename INTO ename FROM Employees E where E.eid = eid_;

        IF eid_ IN (SELECT FTE.eid FROM Full_time_Employees FTE) THEN
            e_status := 'Full-time';
            num_work_hours := NULL;
            hourly_rate := NULL;

            SELECT FTE.monthly_salary INTO monthly_salary
            FROM Full_time_Employees FTE
            WHERE FTE.eid = eid_;

            SELECT E.join_date, E.depart_date INTO e_join_date_, e_depart_date_ FROM Employees E WHERE E.eid = eid_;

            IF (e_join_date_ < first_day_of_month_) AND (e_depart_date_ IS NULL OR e_depart_date_ > last_day_of_month_) THEN
                num_work_days := num_of_days_in_month_;
            ELSIF (e_join_date_ < first_day_of_month_) AND (e_depart_date_ < last_day_of_month_) THEN
                num_work_days := e_depart_date - first_day_of_month_ + 1;
            ELSIF (e_join_date_ > first_day_of_month_) AND (e_depart_date_ IS NULL OR e_depart_date_ > last_day_of_month_) THEN
                num_work_days := last_day_of_month_ - e_join_date_ + 1;
            ELSIF (e_join_date_ > first_day_of_month_) AND (e_depart_date_ < last_day_of_month_) THEN
                num_work_days := e_depart_date - e_join_date_ + 1;
            ELSE
                RAISE NOTICE 'Unhandled case!';
            END IF;

            salary_amount_paid := (num_work_days / num_of_days_in_month_) * monthly_salary;

        ELSE

            e_status := 'Part-time';
            num_work_days := NULL;
            monthly_salary := NULL;

            SELECT PTE.num_work_hours, PTE.hourly_rate INTO num_work_hours, hourly_rate
            FROM Part_time_Employees PTE
            WHERE PTE.eid = eid_;

            salary_amount_paid := num_work_hours * hourly_rate;
        END IF;
        
        INSERT INTO Salary_payment_records (eid, ename, e_status, num_work_days, num_work_hours, monthly_salary, hourly_rate, salary_amount, payment_date)
        VALUES (eid, ename, e_status, num_work_days, num_work_hours, monthly_salary, hourly_rate, salary_amount_paid, NOW()::DATE);

        RETURN NEXT;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

/* 26. pay_salary
    This routine is used at the end of the month to pay salaries to employees.
    */
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS TABLE (
    eid INTEGER,
    ename TEXT,
    e_status TEXT,
    num_work_days INTEGER,
    num_work_hours INTEGER,
    monthly_salary INTEGER,
    hourly_rate INTEGER,
    salary_amount_paid INTEGER
) AS
$$
BEGIN
    RETURN QUERY SELECT * FROM pay_salary_helper() ORDER BY eid;
END;
$$
LANGUAGE PLPGSQL;

/*-------------------------------- End of Employee Routines ------------------------*/

/*-------------------------------- Report Routines ------------------------*/

/* 29. view_summary_report
    This routine is used at the end of the month to pay salaries to employees.
    */
CREATE OR REPLACE FUNCTION view_summary_report(n INTEGER)
RETURNS TABLE (
    month_year TEXT,
    salary_paid INTEGER,
    packages_sold INTEGER,
    total_reg_fees INTEGER,
    refunded_reg_fees INTEGER,
    course_reg_via_package INTEGER
) AS
$$
DECLARE
    interval_ INTERVAL;
    current_date_ DATE;
    date_ DATE;
    f RECORD;
BEGIN
    interval_ := '1 mon';
    SELECT INTO current_date_ NOW()::DATE;
    FOR counter IN 0..n-1 LOOP
        date_ := current_date_ - interval_ * counter;
        RAISE NOTICE 'date: %', date_;
        month_year := TO_CHAR(date_, 'YYYY-MM');

        SELECT SUM(SR.salary_amount) INTO salary_paid
        FROM Salary_payment_records SR
        GROUP BY payment_date
        HAVING (EXTRACT(MONTH FROM payment_date) = EXTRACT(MONTH FROM date_)
            AND EXTRACT(YEAR FROM payment_date) = EXTRACT(YEAR FROM date_));
        IF salary_paid IS NULL THEN
            salary_paid := 0;
        END IF;
        
        SELECT COUNT(*) INTO packages_sold
        FROM Buys B
        WHERE (EXTRACT(MONTH FROM B.buys_ts) = EXTRACT(MONTH FROM date_)
            AND EXTRACT(YEAR FROM B.buys_ts) = EXTRACT(YEAR FROM date_));

        total_reg_fees := 0;
        FOR f IN SELECT * FROM Buys
                            WHERE (EXTRACT(MONTH FROM buys_ts) = EXTRACT(MONTH FROM date_)
                            AND EXTRACT(YEAR FROM buys_ts) = EXTRACT(YEAR FROM date_)) LOOP

            SELECT P.price + total_reg_fees INTO total_reg_fees FROM Packages P WHERE P.package_id = f.package_id;
        END LOOP;

        FOR f IN SELECT * FROM Registers
                            WHERE (EXTRACT(MONTH FROM registers_ts) = EXTRACT(MONTH FROM date_)
                            AND EXTRACT(YEAR FROM registers_ts) = EXTRACT(YEAR FROM date_)) LOOP

            SELECT O.fees + total_reg_fees INTO total_reg_fees 
            FROM Offerings O INNER JOIN Registers R
            ON O.course_id = R.course_id AND O.offering_id = R.offering_id
            WHERE O.course_id = f.course_id AND O.offering_id = f.offering_id;

        END LOOP;

        SELECT SUM(C.refund_amt) INTO refunded_reg_fees
        FROM Cancels C
        WHERE (EXTRACT(MONTH FROM C.cancel_ts) = EXTRACT(MONTH FROM date_)
            AND EXTRACT(YEAR FROM C.cancel_ts) = EXTRACT(YEAR FROM date_));
        IF refunded_reg_fees IS NULL THEN
            refunded_reg_fees := 0;
        END IF;

        SELECT COUNT(*) INTO course_reg_via_package
        FROM Redeems R
        WHERE (EXTRACT(MONTH FROM R.redeems_ts) = EXTRACT(MONTH FROM date_)
            AND EXTRACT(YEAR FROM R.redeems_ts) = EXTRACT(YEAR FROM date_));

        RETURN NEXT;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION get_net_registration_fee(
    course_id_ INTEGER,
    offering_id_ INTEGER
)
RETURNS INTEGER AS
$$
DECLARE
    reg_fees INTEGER;
    f RECORD;
BEGIN
    reg_fees := 0;
    SELECT O.fees + reg_fees INTO reg_fees 
    FROM Offerings O INNER JOIN Registers R 
    ON O.course_id = R.course_id AND O.offering_id = R.offering_id
    WHERE O.course_id = course_id_ AND O.offering_id = offering_id_;
    RETURN reg_fees;
END;
$$
LANGUAGE PLPGSQL;

/* 30. view_manager_report
    This routine is used to view a report on the sales generated by each manager.
    */
CREATE OR REPLACE FUNCTION view_manager_report()
RETURNS TABLE (
    manager_id INTEGER,
    manager_name TEXT,
    managed_course_areas_count INTEGER,
    managed_course_areas TEXT ARRAY,
    managed_offerings_ended INTEGER,
    total_reg_fees INTEGER
) AS
$$
DECLARE
    eid_ INTEGER;
    f RECORD;

BEGIN
    FOR eid_ IN (SELECT M.eid FROM Managers M)  LOOP
        manager_id := eid_;

        SELECT E.ename INTO manager_name FROM Employees E WHERE E.eid = eid_;

        SELECT array_length(course_areas, 1), course_areas INTO managed_course_areas_count, managed_course_areas FROM Managers WHERE eid = eid_;
            
        SELECT COUNT(*) FROM Offerings O INTO managed_offerings_ended
        WHERE EXTRACT(YEAR FROM O.end_date) = EXTRACT(YEAR FROM NOW()::DATE)
        AND O.course_id IN (SELECT C.course_id FROM Courses C WHERE area_name = ANY(managed_course_areas));

        total_reg_fees := 0;

        FOR f IN SELECT * FROM Offerings O
                                    WHERE EXTRACT(YEAR FROM O.end_date) = EXTRACT(YEAR FROM NOW()::DATE)
                                    AND O.course_id IN (SELECT C.course_id FROM Courses C WHERE area_name = ANY(managed_course_areas)) LOOP
            
            total_reg_fees := total_reg_fees + get_net_registration_fee(f.course_id, f.offering_id);
        END LOOP;
        IF total_reg_fees IS NULL THEN
            total_reg_fees := 0;
        END IF;
        RETURN NEXT;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;
