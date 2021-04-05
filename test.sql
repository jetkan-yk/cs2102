SELECT * FROM add_course('course1', 'desc1', 'Computer Security', 4);

SELECT * FROM add_session(8, 4225, '2021-07-31', '9:00', 1);

SELECT * FROM find_rooms('2021-07-31', '9:00', 7);

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

SELECT * FROM add_session(1, 1242, '2021-07-31', '09:00', 1); /* should work */
SELECT * FROM add_session(1, 1242, '2021-07-31', '10:00', 1); /* should fail */
SELECT * FROM add_session(1, 1242, '2021-07-01', '11:00', 3); /* should fail */