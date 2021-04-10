DROP TRIGGER IF EXISTS add_manage_area ON Manages;
DROP TRIGGER IF EXISTS add_specialize_area ON Specializes;
DROP TRIGGER IF EXISTS add_handle_area ON Handles;
DROP TRIGGER IF EXISTS add_employee_type ON Employees;
DROP TRIGGER IF EXISTS update_teaching_hours ON Sessions;

/* --------------- Employees Triggers --------------- */

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


/*TODO: trigger add work hour/day when session/offering is assigned to Employees*/
/*TODO: trigger add teaching_hour when session is assigned to Instructor*/




/* 6. find_instructors
    This routine is used to find all the instructors who could be assigned to teach a course session. */
/*Function designates that Instructor can be assigned to a course session if
1. Instructor should specialize in the course area that course belongs to
2. Instructor can teach at most 1 course session in an hour
3. There must be an hour of break for Instructor between sessions
4. Part-time Instructor's total number of hour taught this month < 30*/
DROP TYPE IF EXISTS found_instructors CASCADE;
CREATE TYPE found_instructors AS (
    eid INTEGER,
    ename TEXT
);

CREATE OR REPLACE FUNCTION find_instructors(
    _course_id INTEGER,
    _session_date DATE,
    _session_start_hour TIME,
    _session_end_hour TIME)
RETURNS SETOF found_instructors AS
$$
DECLARE
    course_area_ TEXT;
    one_hour_ INTERVAL;
BEGIN
    one_hour_ := '01:00';

    SELECT area_name INTO course_area_
    FROM Courses C WHERE C.course_id = _course_id;

    SELECT eid, ename
    FROM Employees
    WHERE eid IN (SELECT eid
                  FROM Specializes
                  WHERE area_name = course_area_)
    AND eid IN (SELECT eid
                    FROM Employees
                    WHERE depart_date IS NULL OR depart_date > _session_date)
    AND eid NOT IN (SELECT eid 
                    FROM Sessions
                    WHERE session_date = _session_date 
                    AND (
                    (_session_start_hour BETWEEN start_time - one_hour_ AND end_time + one_hour_) 
                    OR (_session_end_hour BETWEEN start_time - one_hour_ AND end_time + one_hour_) 
                    OR (_session_start_hour < start_time AND _session_end_hour > end_time)))
    AND eid NOT IN (SELECT eid
                    FROM Part_time_Employees
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


CREATE OR REPLACE FUNCTION update_teaching_hours_func()
    RETURNS TRIGGER AS
$$
DECLARE
    session_duration_ INTEGER;
BEGIN
    SELECT INTO session_duration_ FROM Courses C WHERE C.course_id = NEW.course_id;

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

    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER update_teaching_hours
AFTER UPDATE ON Sessions
FOR EACH ROW WHEN (NEW.eid IS DISTINCT FROM OLD.eid) EXECUTE FUNCTION update_teaching_hours_func();

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

            salary_amount_paid := num_work_days * hourly_rate;
        END IF;
        
        INSERT INTO Salary_payment_records (eid, ename, e_status, num_work_days, num_work_hours, monthly_salary, hourly_rate, salary_amount, payment_date)
        VALUES (eid, ename, e_status, num_work_days, num_work_hours, monthly_salary, hourly_rate, salary_amount_paid, NOW()::DATE);

        RETURN NEXT;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

DROP TYPE IF EXISTS salary_information CASCADE;
CREATE TYPE salary_information AS (
    eid INTEGER,
    ename TEXT,
    e_status TEXT,
    num_work_days INTEGER,
    num_work_hours INTEGER,
    monthly_salary INTEGER,
    hourly_rate INTEGER,
    salary_amount_paid INTEGER
);

/* 26. pay_salary
    This routine is used at the end of the month to pay salaries to employees.
    */
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS SETOF salary_information AS
$$
BEGIN
    SELECT * FROM pay_salary_helper() ORDER BY eid;
END;
$$
LANGUAGE PLPGSQL;