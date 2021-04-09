DROP FUNCTION IF EXISTS add_employee(text,text,text,text,date,text,integer,text[]);
DROP FUNCTION IF EXISTS find_instructors(integer,date,time without time zone);
DROP FUNCTION IF EXISTS get_available_instructors(integer,date,date);

DROP TRIGGER IF EXISTS add_manage_area ON Manages;
DROP TRIGGER IF EXISTS add_specialize_area ON Specializes;
DROP TRIGGER IF EXISTS add_handle_area ON Handles;
DROP TRIGGER IF EXISTS add_employee_type ON Employees;

DROP TYPE IF EXISTS found_instructors;
DROP TYPE IF EXISTS available_instructors;

/* --------------- Employees Triggers --------------- */

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

CREATE TRIGGER add_handle_area
BEFORE INSERT ON Handles
FOR EACH ROW EXECUTE FUNCTION add_course_area_func();


CREATE OR REPLACE FUNCTION add_employee_type_func()
    RETURNS TRIGGER AS
$$
DECLARE
    trimmed_category_ TEXT;
BEGIN
    IF NEW.category = 'Manager' OR NEW.category = 'Administrator' OR NEW.category = 'Full-time Instructor' THEN
        INSERT INTO Full_time_Employees (eid, num_work_days, monthly_salary)
        VALUES (NEW.eid, 0, NEW.salary);
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


/* --------------- Employees Routines --------------- */

/* 1. add_employee
    This routine is used to add a new employee.*/

CREATE OR REPLACE FUNCTION add_employee(
    _ename TEXT,
    _phone_number TEXT,
    _home_address TEXT,
    _email_address TEXT,
    _join_date DATE,
    _category TEXT,
    _salary INTEGER,
    _course_area_set TEXT ARRAY)
    RETURNS VOID AS
$$
DECLARE
    next_eid_ INTEGER;
    area_name_ TEXT;
BEGIN
    SELECT COUNT(*) + 1 FROM Employees INTO next_eid_;
    IF array_length(_course_area_set, 1) >= 1 THEN
        IF _category = 'Administrator' THEN
            RAISE NOTICE
                'Cannot add employee of type Administrator because course area set should not be specified for Administrators, skipping...';
        ELSIF _category = 'Manager' OR _category = 'Full-time Instructor' OR _category = 'Part-time Instructor' THEN
            INSERT INTO Employees
                (ename, phone_number, home_address, email_address, join_date, category, salary)
                VALUES
                (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary);
            IF _category = 'Manager' THEN
                INSERT INTO Managers (eid, course_areas)
                VALUES (next_eid_, _course_area_set);
                FOREACH area_name_ IN ARRAY _course_area_set LOOP
                    INSERT INTO Manages (eid, area_name)
                    VALUES (next_eid_, area_name_);
                END LOOP;
            ELSE
                INSERT INTO Instructors (eid, num_teach_hours, course_areas)
                VALUES (next_eid_, 0, _course_area_set);
                FOREACH area_name_ IN ARRAY _course_area_set LOOP
                    INSERT INTO Specializes (eid, area_name)
                    VALUES (next_eid_, area_name_);
                END LOOP;
            END IF;
        ELSE
            RAISE NOTICE
            'Cannot add employee because employee category is invalid, skipping...';
        END IF;
    ELSE
        IF _category = 'Manager' OR _category = 'Full-time Instructor' OR _category = 'Part-time Instructor' THEN
            RAISE NOTICE
                'Cannot add employee of type % because course area set specified is empty or invalid, skipping...', _category;
        ELSIF _category = 'Administrator' THEN
            INSERT INTO Employees
                (ename, phone_number, home_address, email_address, join_date, category, salary)
                VALUES
                (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary);
            INSERT INTO Administrators (eid)
                VALUES(next_eid_);
        ELSE
            RAISE NOTICE
            'Cannot add employee because employee category is invalid, skipping...';
        END IF;
    END IF;
END;
$$
LANGUAGE PLPGSQL;


/* 2. remove_employee
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
    SELECT category INTO employee_type_
        FROM Employees
        WHERE eid = _eid;
    IF employee_type_ = 'Manager' THEN
        IF _eid IN (SELECT eid FROM Managers WHERE array_length(course_areas, 1) >= 1) THEN
            RAISE NOTICE
                'Cannot remove employee, as employee is a manager managing some area';
        ELSE
            UPDATE Employees
            SET depart_date = _depart_date
            WHERE eid = _eid
            RETURNING * INTO result_;
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
            RETURNING * INTO result_;
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
            RETURNING * INTO result_;
        END IF;
    END IF;

    RETURN result_;
END;
$$
LANGUAGE PLPGSQL;

/*TODO: trigger add hour/day when session/offering is assigned to Employees*/

/* 6. find_instructors
    This routine is used to find all the instructors who could be assigned to teach a course session. */
/*Function designates that Instructor can be assigned to a course session if
1. Instructor should specialize in the course area that course belongs to
2. Instructor can teach at most 1 course session in an hour
3. There must be an hour of break for Instructor between sessions
4. Part-time Instructor's total number of hour taught this month < 30*/

CREATE TYPE found_instructors AS (
    eid INTEGER,
    ename TEXT
);

CREATE OR REPLACE FUNCTION find_instructors(
    _course_id INTEGER,
    _session_date DATE,
    _session_start_hour TIME)
RETURNS SETOF found_instructors AS
$$
DECLARE
    course_area_ TEXT;
    one_hour_ INTERVAL;
    found_instructors_ found_instructors;
BEGIN
    one_hour_ := '01:00';
    SELECT area_name INTO course_area_
    FROM Courses C WHERE C.course_id = _course_id;

    RAISE NOTICE 'Course area is %', course_area_;

    SELECT eid, ename INTO found_instructors_
    FROM Employees
    WHERE eid IN (SELECT eid
                  FROM Specializes
                  WHERE area_name = course_area_)
    AND eid NOT IN (SELECT eid 
                    FROM Sessions
                    WHERE session_date = _session_date 
                        AND (_session_start_hour BETWEEN start_time - one_hour_ AND end_time + one_hour_))
    AND eid NOT IN (SELECT eid
                    FROM Part_time_Employees
                    WHERE num_work_hours >= 30)
    AND eid NOT IN (SELECT eid
                    FROM Employees
                    WHERE depart_date IS NULL OR depart_date > _session_date);
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
    available_hours INTEGER ARRAY) AS
$$
DECLARE
    eid_ INTEGER;
    total_hour_ INTEGER ARRAY;
    lunch_hour_ INTEGER ARRAY;
    busy_hour_ INTEGER ARRAY;
    t1_ INTEGER;
    t2_ INTEGER;
BEGIN
    /*for each instructor*/
    FOR eid_ IN (SELECT I.eid FROM Instructors I) LOOP
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