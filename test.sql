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

/* to test update_credit_card routine */
SELECT * FROM update_credit_card(1, '123454321', 321, '2025-01-01');

/* to test add_course routine */
SELECT * FROM add_course('title1','desc1','CS',4); /* should work */
SELECT * FROM add_course('title2','desc2','LS', 8); /* should fail */
/*SELECT * FROM add_course('title3', 'desc3', 'Computer Security', 4); */

/* To test find_rooms routine */
SELECT * FROM find_rooms('2021-07-31', '9:00', 7); /*should work*/
SELECT * FROM find_rooms('2021-07-31', '9:00', 8); /* should fail */

/* To test get_available_rooms routine */
SELECT * FROM get_available_rooms('2021-07-31', '2021-07-31');

/* To test add_course_offerings routine */

SELECT * FROM add_course_offering(2, 5001, '2020-12-01', '2020-12-01', 100, 50, 1,
                                    '{"(2021-01-01, 10:00, 1)",
                                      "(2021-01-01, 11:00, 2)",
                                      "(2021-01-03, 14:00, 3)"}'); /* should fail*/
SELECT * FROM add_course_offering(2, 5001, '2020-12-01', '2020-12-01', 100, 50, 1,
                                    '{"(2021-01-01, 10:00, 5)",
                                      "(2021-01-01, 11:00, 2)",
                                      "(2021-01-03, 14:00, 3)"}'); /* should work*/
SELECT * FROM add_course_offering(1, 10410, '2021-04-10', '2021-05-10', 100, 9, 1,
                                    '{"(2021-05-11, 10:00, 1)"}');/* should fail*/



/* to test add_course_package routine */
SELECT * FROM add_course_package('A', 2, 100, '2021-02-01', '2021-03-01'); /* should work */
/* SELECT * FROM add_course_package('B', 2, 100, '2021-03-01', '2021-02-01');
SELECT * FROM add_course_package('C', -1, 100, '2021-02-01', '2021-03-01'); 
SELECT * FROM add_course_package('D', 2, -10, '2021-02-01', '2021-03-01'); */
/* all should fail due to input parameter errors*/

/* to test get_available_course_packages routine */
SELECT * FROM get_available_course_packages();

/* to test buy_course_package routine */
SELECT * FROM buy_course_package(5, 10); /* should work */
/*fails due to cc_num being null*/
SELECT * FROM buy_course_package(1, 1); /* should fail */

/* to test get_my_course_package routine */
SELECT * FROM get_my_course_package(5);

/* to test register_session routine*/
SELECT * FROM register_session(5, 1, 1242, 1, 'redeem');
SELECT * FROM register_session(5, 2, 4248, 1, 'redeem');
SELECT * FROM register_session(5, 3, 4248, 1, 'redeem');
SELECT * FROM register_session(5, 4, 3235, 1, 'redeem');
SELECT * FROM register_session(5, 5, 3242, 1, 'redeem');
SELECT * FROM register_session(5, 6, 4218, 1, 'redeem');
SELECT * FROM register_session(5, 7, 3757, 1, 'redeem'); /*should fail*/
SELECT * FROM register_session(5, 8, 4225, 1, 'redeem'); /*should fail*/
SELECT * FROM register_session(5, 8, 4225, 1, 'payment');
/*redeem and payment proceeds despite no package bought*/


/* To test update_room routine */
SELECT * FROM update_room(5, 4236, 2, 4); /* should fail due to clash*/

INSERT INTO Rooms (rid, location, seating_capacity)
VALUES (11, '4F-01', 1);

INSERT INTO Offerings (
    course_id,
    offering_id,
    launch_date,
    reg_deadline,
    fees,
    target_num_reg,
    eid
  )
VALUES (1, 1234, '2021-01-01', '2021-02-01', 260, 2, 3);
INSERT INTO Sessions (
    course_id,
    offering_id,
    session_date,
    start_time,
    rid
  )
VALUES (1, 1234, '2021-04-09', '11:00', 1);
/*SELECT * FROM update_room(1, 1234, 6, 4); for Session is ongoing*/

SELECT * FROM register_session(5, 1, 1234, 6, 'payment');
SELECT * FROM register_session(1, 1, 1234, 6, 'payment');
SELECT * FROM update_room(1, 1234, 6, 11); /*for no: of reg>room capacity */

/*to check remove_session routine*/
SELECT * FROM remove_session(3, 4248, 1);
/* add extra test case to get:
NOTICE: Session already started and
NOTICE: num reg > 0 */

/*to check add_session routine*/
SELECT * FROM add_session(1, 10410, '2021-06-30', '09:00', 1, 1); /* should work */
SELECT * FROM add_session(1, 10410, '2021-07-31', '10:00', 1, 2); /* should fail */
/*SELECT * FROM add_session(1, 1242, '2021-07-01', '11:00', 3, 1);  should work
SELECT * FROM add_session(21, 4225, '2021-07-31', '9:00', 1, 2); should fail */



/*SELECT * FROM add_employee('Nathaniel Mckenzie','1-792-176-8701','P.O. Box 436, 6023 Malesuada Rd.','erat.volutpat@hendreritidante.com','2019-08-19','Manager',2327,'{Artificial Intelligence, Computer Graphics and Games}'); */

