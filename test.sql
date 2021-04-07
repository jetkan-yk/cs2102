/* to populate Course_Areas table) */
INSERT INTO Course_areas (area_name)
VALUES ('CS'),
('AI'),
('LS'),
('MA'),
('ST');

/* To check Offerings start_date and end_date are assigned correctly */
SELECT
	O.course_id,
	O.offering_id,
	session_id,
	session_date,
	start_date,
	end_date
FROM Offerings O LEFT JOIN Sessions S
	   ON O.course_id = S.course_id
		    AND O.offering_id = S.offering_id;

/* To check each Room cannot be used by two Sessions at the same time */
SELECT session_date, start_time, end_time, rid
  FROM Sessions NATURAL JOIN Rooms
 ORDER BY session_date, start_time, end_time;

/* To test find_rooms routine */
SELECT * FROM find_rooms('2021-07-31', '9:00', 7);

/* To test get_available_rooms routine */

/*to check add_course routine*/
SELECT * FROM add_course('CS', 'desc1', 'title1', 4); /* should work */
SELECT * FROM add_course('LS', 'desc2', 'title2', 8); /* should fail */
SELECT * FROM add_course('course1', 'desc1', 'Computer Security', 4);

/*INSERT INTO Offerings (
    course_id,
    offering_id,
    launch_date,
    reg_deadline,
    fees,
    target_num_reg,
    eid
  )
VALUES (1, 10410, '2021-04-10', '2021-05-10', 100, 9, 1), should work
(2, 20510, '2021-05-10', '2021-05-05', 100, 9, 1),  should fail
(1, 10411, '2021-04-11', '2021-05-11', 100, 1000, 1) should fail
(1, 10412, '2021-04-12', '2021-05-12', -1, 9, 1), should fail
(2, 20411, '2021-04-11', '2021-05-11', 100, 0, 1); should fail */

/* To test add_course_offering routine
course offering identifier, course identifier, course fees, launch date,
registration deadline, administrator’s identifier, and information for
each session (session date, session start hour, and room identifier)*/
SELECT * FROM add_course_offering(8, 5001, '2020-12-01', '2020-12-01', 100, 50, 1,
                                    '{"(2021-01-01, 10:00, 1)",
                                      "(2021-01-01, 11:00, 2)",
                                      "(2021-01-03, 14:00, 3)"}');

/* To test update_room routine */
SELECT * FROM update_room(5, 4236, 2, 4);


/*to check add_session routine*/
SELECT * FROM add_session(1, 1242, '2021-07-31', '09:00', 1); /* should work */
SELECT * FROM add_session(1, 1242, '2021-07-31', '10:00', 1); /* should fail */
SELECT * FROM add_session(1, 1242, '2021-07-01', '11:00', 3); /* should fail */
SELECT * FROM add_session(8, 4225, '2021-07-31', '9:00', 1);



/* to test add_course_package routine */
SELECT * FROM add_course_package('A', 2, '2021-02-01', '2021-03-01', 100); /* should work */
SELECT * FROM add_course_package('B', 2, '2021-03-01', '2021-02-01', 100); /* should fail */
SELECT * FROM add_course_package('C', -1, '2021-02-01', '2021-03-01', 100); /* should fail */
SELECT * FROM add_course_package('D', 2, '2021-02-01', '2021-03-01', -10); /* should fail */



/* To test add_employee
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
 */
SELECT * FROM add_employee('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}');

