/* With depart date */
INSERT INTO Employees (
  ename,
  phone_number,
  home_address,
  email_address,
  join_date,
  depart_date,
  category,
  salary,
  course_area_set
)
VALUES ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','2022-04-02','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','2022-03-27','Instructor',2240,'{Computer Security}'),
('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','2021-01-25','Administrator',1427,'{}'),
('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','2020-11-27','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}'),
('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','2022-04-02','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','2022-03-27','Instructor',2240,'{Computer Security}'),
('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','2021-01-25','Administrator',1427,'{}'),
('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','2020-11-27','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');

/* Without depart date */
INSERT INTO Employees (
  ename,
  phone_number,
  home_address,
  email_address,
  join_date,
  category,
  salary,
  course_area_set
)
VALUES ('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240,'{Computer Security}'),
('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}'),
('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}'),
('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'),
('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240,'{Computer Security}'),
('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}'),
('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');

/* --------------- Employees Routines --------------- */

/* 1. add_employee
    This routine is used to add a new employee.
    RETURNS: the result of the new Employee after successful INSERT */
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
    INSERT INTO Employees
        (ename, phone_number, home_address, email_address, join_date, category, salary,
            course_area_set) VALUES
        (_ename, _phone_number, _home_address, _email_address, _join_date, _category, _salary,
            _course_area_set)
    RETURNING *;
$$
LANGUAGE SQL;


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
        IF _eid IN (SELECT eid FROM Manages) THEN
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