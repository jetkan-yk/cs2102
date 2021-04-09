DROP FUNCTION IF EXISTS add_employee(text,text,text,text,date,text,integer,text[]);
DROP FUNCTION IF EXISTS find_instructors(integer,date,time without time zone);

DROP TRIGGER IF EXISTS add_manage_area ON Manages;
DROP TRIGGER IF EXISTS add_specialize_area ON Specializes;
DROP TRIGGER IF EXISTS add_handle_area ON Handles;
DROP TRIGGER IF EXISTS add_employee_type ON Employees;

DROP TYPE IF EXISTS found_instructors;
-- /* With depart date */
-- INSERT INTO Employees (
--   ename,
--   phone_number,
--   home_address,
--   email_address,
--   join_date,
--   depart_date,
--   category,
--   salary,
--   course_area_set
-- )
-- VALUES ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','2022-04-02','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','2022-03-27','Instructor',2240,'{Computer Security}'),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','2021-01-25','Administrator',1427,'{}'),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','2020-11-27','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}'),
-- ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','2022-04-02','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','2022-03-27','Instructor',2240,'{Computer Security}'),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','2021-01-25','Administrator',1427,'{}'),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','2020-11-27','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');

-- /* Without depart date */
-- INSERT INTO Employees (
--   ename,
--   phone_number,
--   home_address,
--   email_address,
--   join_date,
--   category,
--   salary,
--   course_area_set
-- )
-- VALUES ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240,'{Computer Security}'),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}'),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}'),
-- ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240,'{Computer Security}'),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}'),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');

/* Without depart date */
-- INSERT INTO Employees (
--   ename,
--   phone_number,
--   home_address,
--   email_address,
--   join_date,
--   category,
--   salary
-- )
-- VALUES
-- ('Nathaniel Mckenzie', '1-792-176-8701', 'P.O. Box 436, 6023 Malesuada Rd.', 'erat.volutpat@hendreritidante.com', '2019-08-19', 'Manager', 2327);
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255),
-- ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327),
-- ('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240),
-- ('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427),
-- ('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255);

-- INSERT INTO Full_time_Employees (
--     eid,
--     monthly_salary
-- )
-- VALUES (1, 2327);

-- INSERT INTO Managers (
--     eid,
--     area_name
-- )
-- VALUES (1, 'Artificial Intelligence');

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
                INSERT INTO Instructors (eid, course_areas)
                VALUES (next_eid_, _course_area_set);
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


/* 6. remove_employee
    This routine is used to update an employee’s departed date a non-null value.
    RETURNS: the Employee detail after successful DELETE */
/*Instructor can be assigne to a course session if
1. Instructor should specialize in the course area that course belongs to - done
2. Instructor can teach at most 1 course session in an hour - done
3. There must be an hour of break for Instructor between sessions - done
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
    /* Availability */
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
