SELECT * FROM add_course('course1', 'desc1', 'Computer Security', 4);

SELECT * FROM add_session(6, 4218, '2021-06-12', '10:00', 6);
SELECT * FROM add_session(6, 4218, '2021-06-12', '11:00', 6);
SELECT * FROM add_session(6, 4218, '2021-06-14', '14:00', 6);

SELECT * FROM find_rooms('2021-07-31', '9:00', 4);