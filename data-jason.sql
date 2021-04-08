INSERT INTO Course_areas (area_name)
VALUES ('Artificial Intelligence'),
  ('Computer Graphics and Games'),
  ('Computer Security'),
  ('Database Systems'),
  ('Software Engineering'),
  ('Life Sciences'),
  ('Physics'),
  ('Statistics'),
  ('Chemistry'),
  ('Bioinformatics');


INSERT INTO Courses (
    title,
    description,
    duration,
    area_name
  )
VALUES (
    'Introduction to Database Systems',
    'The aim of this module is to introduce the fundamental concepts and techniques necessary for the understanding and practice of design and implementation of database systems.',
    2,
    'Database Systems'
  ),
  (
    'Introduction to Information Security',
    NULL,
    2,
    'Computer Security'
  ),
  (
    'Advanced Computer Security',
    'The objective of this module is to provide a broad understanding of computer security with some indepth discussions on selected topics in system and network security.',
    3,
    'Computer Security'
  ),
  (
    '3D Modelling and Animation',
    'This module aims to provide fundamental concepts in 3D modeling and animation. It also serves as a bridge to advanced media modules.',
    5,
    'Computer Graphics and Games'
  ),
  (
    'Machine Learning',
    'This module introduces basic concepts and algorithms in machine learning and neural networks.',
    6,
    'Artificial Intelligence'
  ),
  (
    'Software Testing',
    'This module covers the concepts and practice of software testing including unit testing, integration testing, and regression testing.',
    4,
    'Software Engineering'
  ),
  (
    'Big Data Systems for Data Science',
    'Data science incorporates varying elements and builds on techniques and theories from many fields with the goal of extracting meaning from big data and creating data products.',
    5,
    'Database Systems'
  ),
  (
    'Cryptography Theory and Practice',
    'This module aims to introduce the foundation, principles and concepts behind cryptology and the design of secure communication systems.',
    1,
    'Computer Security'
  ),
  (
    'Natural Language Processing',
    'This module deals with computer processing of human languages, emphasizing a corpus-based empirical approach.',
    7,
    'Artificial Intelligence'
  ),
  (
    'Uncertainty Modelling in AI',
    'The module covers modelling methods that are suitable for reasoning with uncertainty.',
    5,
    'Artificial Intelligence'
  );

INSERT INTO Rooms (rid, location, seating_capacity)
VALUES (1, '1F-01', 20),
    (2, '1F-02', 10),
    (3, '1F-03', 15),
    (4, '1F-04', 25),
    (5, '2F-01', 50),
    (6, '2F-02', 40),
    (7, '2F-03', 25),
    (8, '2F-04', 25),
    (9, '3F-01', 100),
    (10, '3F-02', 100);

INSERT INTO Offerings (
    course_id,
    offering_id,
    launch_date,
    reg_deadline,
    fees,
    target_num_reg,
    eid
)
VALUES
    (1, 1242, '2021-02-07', '2021-04-22', 260, 198, 2),
    (2, 4248, '2021-02-27', '2021-06-04', 400, 137, 8),
    (1, 2317, '2021-01-10', '2021-04-10', 320, 101, 2);


INSERT INTO Sessions (
    course_id,
    offering_id,
    session_id,
    session_date,
    start_time,
    eid,
    rid
)
VALUES
    (1, 1242, 1, '2021-08-04', '10:00', 1, 1),
    (1, 2317, 2, '2021-07-01', '10:00', 4, 3),
    (2, 4248, 3, '2021-08-09', '09:00', 4, 8);

/*------------------------ Valid Add ---------------------------*/
SELECT * FROM add_employee('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240, '{Computer Security}');

SELECT * FROM add_employee('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}');

SELECT * FROM add_employee('Nathaniel Mckenzie', '1-792-176-8701', 'P.O. Box 436, 6023 Malesuada Rd.', 'erat.volutpat@hendreritidante.com', '2019-08-19', 'Manager', 2327, '{Artificial Intelligence, Computer Graphics and Games}');

SELECT * FROM add_employee('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');