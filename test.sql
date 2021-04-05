SELECT * FROM add_course('course1', 'desc1', 'Computer Security', 4);

SELECT * FROM add_session(8, 4225, '2021-07-31', '9:00');

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