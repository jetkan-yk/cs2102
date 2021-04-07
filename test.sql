/* to populate Course_Areas table */
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
SELECT * FROM add_course('title1','desc1','CS',4); /* should work */
SELECT * FROM add_course('title2','desc2','LS', 8); /* should fail */
SELECT * FROM add_course('title3', 'desc3', 'Computer Security', 4);

SELECT * FROM add_course_offering(2, 5001, '2020-12-01', '2020-12-01', 100, 50, 1,
                                    '{"(2021-01-01, 10:00, 1)",
                                      "(2021-01-01, 11:00, 2)",
                                      "(2021-01-03, 14:00, 3)"}'); /* should work*/
SELECT * FROM add_course_offering(8, 5001, '2020-12-01', '2020-12-01', 100, 50, 1,
                                    '{"(2021-01-01, 10:00, 1)",
                                      "(2021-01-01, 11:00, 2)",
                                      "(2021-01-03, 14:00, 3)"}'); /* should fail*/
/* doesn't detect the sessions*/

/* SELECT * FROM add_course_offering(1, 10410, '2021-04-10', '2021-05-10', 100, 9, 1
                                    '{"(2021-04-09, 10:00, 1)"}');
SELECT * FROM add_course_offering(2, 20510, '2021-05-10', '2021-05-05', 100, 9, 1
                                    '{"(2021-06-09, 10:00, 1)"}');
SELECT * FROM add_course_offering(1, 10411, '2021-04-11', '2021-05-11', 100, 1000, 1
                                    '{"(2021-06-09, 10:00, 1)"}');
SELECT * FROM add_course_offering(1, 10412, '2021-04-12', '2021-05-12', -1, 9, 1
                                    '{"(2021-06-09, 10:00, 1)"}'); 
SELECT * FROM add_course_offering(2, 20411, '2021-04-11', '2021-05-11', 100, -1, 1
                                    '{"(2021-06-09, 10:00, 1)"}');*/
/* SYNTAX ERROR */

/* To test update_room routine */
SELECT * FROM update_room(5, 4236, 2, 4);

/*to check add_session routine*/
SELECT * FROM add_session(1, 10410, '2021-06-30', '09:00', 1, 1); /* should work */
SELECT * FROM add_session(1, 10410, '2021-07-31', '10:00', 1, 2); /* should fail */
SELECT * FROM add_session(1, 1242, '2021-07-01', '11:00', 3, 1); /* should fail */
SELECT * FROM add_session(21, 4225, '2021-07-31', '9:00', 1, 2);

/* to test add_course_package routine */
SELECT * FROM add_course_package('A', 2, '2021-02-01', '2021-03-01', 100); /* should work */
SELECT * FROM add_course_package('B', 2, '2021-03-01', '2021-02-01', 100); /* should fail */
SELECT * FROM add_course_package('C', -1, '2021-02-01', '2021-03-01', 100); /* should fail */
SELECT * FROM add_course_package('D', 2, '2021-02-01', '2021-03-01', -10); /* should fail */

SELECT * FROM add_employee('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}');

