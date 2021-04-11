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
    4,
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
    4,
    'Artificial Intelligence'
  ),
  (
    'Uncertainty Modelling in AI',
    'The module covers modelling methods that are suitable for reasoning with uncertainty.',
    4,
    'Artificial Intelligence'
  );

INSERT INTO Rooms (rid, location, seating_capacity)
VALUES (1, '1F-01', 1),
  (2, '1F-02', 10),
  (3, '1F-03', 15),
  (4, '1F-04', 25),
  (5, '2F-01', 50),
  (6, '2F-02', 40),
  (7, '2F-03', 25),
  (8, '2F-04', 25),
  (9, '3F-01', 100),
  (10, '3F-02', 100);

/*populating Instructors table*/
SELECT * FROM add_employee('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Full-time Instructor',2240, '{Computer Security}');
SELECT * FROM add_employee('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Part-time Instructor',15,'{Life Sciences, Physics, Bioinformatics}');
SELECT * FROM add_employee('Alex Robertson', '1-632-176-4321', 'P.O. Box 643, 6023 Jurong Rd.', 'borat.tapat@hentidante.com', '2019-08-19', 'Part-time Instructor', 21, '{Computer Security}');
SELECT * FROM add_employee('Alan Turner', '785-754-1532', '3599 Glory Road', 'aglasang_ang@mracc.it', '2019-12-13','Full-time Instructor', 2500, '{Database Systems, Statistics}');
SELECT * FROM add_employee('Bea Miller','1-765-434-6532', '805 Deer Haven Drive', 'feggyptr7@kittiza.com', '2019-08-15', 'Full-time Instructor', 2300, '{Life Siences, Chemistry, Bioinformatics}');
SELECT * FROM add_employee('Chris Trent','1-286-194-9725', '4602 Thompson Street', 'ztonielbevad@colevillecapital.com', '2020-09-23', 'Full-time Instructor', 2400,'{Artificial Intlligence, Computer Graphics and Games}');
SELECT * FROM add_employee('Vin Diesel','1-532-276-4921', '2090 Echo Lane', 'wkamal.mofek@wikuiz.com', '2019-04-08', 'Full-time Instructor', 2500, '{Software Engineering, Computer Security}');
SELECT * FROM add_employee('Sal Morales','1-275-439-1582', '4121 Pinnickinick Street', 'hdjnayem@wingkobabat.buzz', '2020-02-06', 'Part-time Instructor', 17, '{Database Systems, Bioinformatics}');
SELECT * FROM add_employee('Millie Bobby','1-874-104-4325', '152 Berkley Street', 'nabdul.suhaib@packiu.com', '2020-03-01', 'Part-time Instructor', 16, '{Physics, Statistics}');
SELECT * FROM add_employee('Helen Huff','1-775-354-1597', '2388 Scheuvront Drive', 'qabdoun.bob.70@kentel.buzz', '2019-08-24', 'Part-time Instructor', 18,'{Chemistry, Bioinformatics}');

/*populating Administrators table*/
SELECT * FROM add_employee('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}');
SELECT * FROM add_employee('Brandie Jessup', '1-265-909-9769', '959 Hintze Junction', 'bjessup0@freewebs.com', '2020-03-26','Administrator',1500,'{}');
SELECT * FROM add_employee('Charmion Hamner', '1-974-669-4743', '32 Victoria Place', 'chamner1@pbs.org', '2020-09-12', 'Administrator',1600,'{}');
SELECT * FROM add_employee('Glynda Ghilks', '5-912-254-0382', '786 Northridge Road', 'gghilks2@addthis.com', '2019-06-28', 'Administrator',1460,'{}');
SELECT * FROM add_employee('Loralee Measham', '6-516-257-6835', '941 Hazelcrest Pass', 'lmeasham3@odnoklassniki.ru', '2021-03-13', 'Administrator',2000,'{}');
SELECT * FROM add_employee('Urban Poulden', '3-301-911-0539', '98511 Kropf Crossing', 'upoulden4@reuters.com', '2020-10-05', 'Administrator',2100,'{}');
SELECT * FROM add_employee('Trstram Pettinger', '6-253-712-8946', '6 Fremont Circle', 'tpettinger5@sitemeter.com', '2020-07-20', 'Administrator',2110,'{}');
SELECT * FROM add_employee('Kathleen Cowlard', '8-402-717-8604', '2 Charing Cross Place', 'kcowlard6@bizjournals.com', '2019-03-02', 'Administrator',1907,'{}');
SELECT * FROM add_employee('Caren Byway', '2-533-902-5847', '47992 Trailsway Crossing', 'cbyway7@g.co', '2019-02-15', 'Administrator',1900,'{}');
SELECT * FROM add_employee('Cesaro Kerford', '5-914-133-8749', '837 Comanche Terrace', 'ckerford8@hhs.gov', '2020-04-17', 'Administrator',1950,'{}');

/*populating Managers table*/
SELECT * FROM add_employee('Nathaniel Mckenzie', '1-792-176-8701', 'P.O. Box 436, 6023 Malesuada Rd.', 'erat.volutpat@dante.com', '2019-08-19', 'Manager', 2327, '{Artificial Intelligence}');
SELECT * FROM add_employee('Xerxes Surphliss', '8-701-913-0605', '956 Dennis Trail', 'xsurphliss9@cbc.ca', '2019-04-14', 'Manager', 2000, '{Computer Security}');
SELECT * FROM add_employee('Wallie Bengall', '8-996-7363', '5 Burrows Lane', 'wbengall0@patch.com', '2020-04-17', 'Manager', 2100, '{Software Engineering}');
SELECT * FROM add_employee('Evangelia Cromwell', '208-999-7172', '654 Melby Junction', 'ecromwell1@springer.com', '2021-01-14', 'Manager', 2200, '{Physics}');
SELECT * FROM add_employee('Lonnie Meddings', '504-582-8379', '018 Leroy Junction', 'lmeddings2@mozilla.org', '2019-07-11', 'Manager', 2110, '{Chemistry}');
SELECT * FROM add_employee('Elvyn Alejandri', '168-789-6828', '45172 Swallow Drive', 'ealejandri4@bbb.org', '2019-07-28', 'Manager', 2310, '{Computer Graphics and Games}');
SELECT * FROM add_employee('Valentine Fitzharris', '878-530-6931', '56 Jana Drive', 'vfitzharris5@nbcnews.com', '2019-05-24', 'Manager', 2000, '{Database Systems}');
SELECT * FROM add_employee('Freddy Doorbar', '619-455-0759', '94589 Bellgrove Lane', 'fdoorbar6@businessweek.com', '2019-09-02', 'Manager', 2240, '{Statistics}');
SELECT * FROM add_employee('Efren Olivera', '841-169-4580', '1 Goodland Center', 'eolivera7@cpanel.net', '2020-05-29', 'Manager', 2341, '{Life Sciences}');
SELECT * FROM add_employee('Francene Havenhand', '764-742-2909', '205 Stoughton Street', 'fhavenhand8@army.mil', '2019-11-13', 'Manager', 2100, '{Bioinformatics}');


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
  (2, 1242, '2021-02-07', '2021-02-22', 260, 198, 11),
  (2, 2317, '2021-01-10', '2021-03-10', 320, 101, 11),
  (2, 4248, '2021-02-28', '2021-05-29', 190, 141, 12),
  (3, 4248, '2021-02-27', '2021-06-04', 400, 137, 18),
  (4, 3235, '2021-03-17', '2021-04-11', 170, 24, 15),
  (5, 3242, '2021-03-20', '2021-06-03', 285, 110, 15),
  (5, 3757, '2021-01-31', '2021-06-30', 400, 112, 11),
  (5, 4236, '2021-01-12', '2021-05-26', 170, 61, 15),
  (6, 4218, '2021-01-30', '2021-05-27', 460, 153, 14),
  (8, 4225, '2021-03-12', '2021-06-15', 75, 23, 17),
  (8, 4236, '2021-02-28', '2021-06-23', 440, 127, 14),
  (9, 2317, '2021-02-10', '2021-04-23', 200, 51, 19),
  (9, 5340, '2021-03-15', '2021-06-04', 270, 171, 16),
  (10, 6585, '2021-02-07', '2021-06-23', 125, 73, 19);

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
(2, 1242, 1,'2021-08-04', '10:00', 1, 1),
(2, 1242, 2,'2021-04-16', '09:00', 1, 1),
(2, 2317, 1,'2021-04-15', '10:00', 2, 3),
(2, 2317, 2,'2021-05-14', '14:00', 2, 3),
(2, 2317, 3,'2021-08-30', '09:00', 2, 6),
(2, 2317, 4,'2021-08-30', '14:00', 2, 2),
(2, 4248, 1,'2021-08-09', '09:00', 3, 8),
(3, 4248, 2,'2021-07-31', '15:00', 3, 4),
(3, 4248, 3,'2021-09-07', '10:00', 3, 5),
(3, 4248, 4,'2021-09-07', '15:00', 3, 1),
(3, 4248, 5,'2021-09-23', '10:00', 3, 9),
(3, 4248, 6,'2021-09-23', '15:00', 3, 9),
(3, 4248, 7,'2021-09-23', '09:00', 4, 5),
(4, 3235, 1,'2021-07-28', '11:00', 4, 2),
(4, 3235, 2,'2021-08-30', '10:00', 4, 8),
(5, 3242, 3,'2021-07-31', '14:00', 4, 10),
(5, 3242, 4,'2021-08-30', '14:00', 5, 5),
(5, 3242, 5,'2021-09-26', '14:00', 5, 5),
(5, 3242, 6,'2021-09-28', '09:00', 5, 4),
(5, 3757, 1,'2021-07-31', '10:00', 5, 3),
(5, 3757, 2,'2021-08-07', '09:00', 6, 10),
(5, 3757, 3,'2021-08-07', '10:00', 6, 8),
(5, 3757, 4,'2021-09-07', '11:00', 6, 4),
(5, 3757, 5,'2021-09-07', '14:00', 6, 5),
(5, 4236, 1,'2021-07-31', '09:00', 6, 5),
(5, 4236, 2,'2021-07-31', '10:00', 7, 2),
(6, 4218, 1,'2021-09-30', '14:00', 7, 4),
(8, 4225, 1,'2021-08-26', '11:00', 7, 5),
(8, 4225, 2,'2021-09-30', '09:00', 8, 1),
(8, 4236, 1,'2021-07-05', '11:00', 8, 8),
(8, 4236, 2,'2021-07-11', '14:00', 8, 5),
(8, 4236, 3,'2021-09-30', '10:00', 8, 3),
(9, 2317, 1,'2021-07-13', '10:00', 8, 9),
(9, 2317, 2,'2021-08-10', '14:00', 9, 3),
(9, 2317, 3,'2021-08-24', '09:00', 9, 9),
(9, 2317, 4,'2021-09-05', '14:00', 9, 1),
(9, 5340, 1,'2021-08-13', '09:00', 9, 10),
(9, 5340, 2,'2021-08-18', '14:00', 9, 4),
(10, 6585, 1,'2021-07-05', '14:00', 10, 4),
(10, 6585, 2,'2021-08-09', '14:00', 10, 5),
(10, 6585, 3,'2021-08-12', '14:00', 10, 3),
(10, 6585, 4,'2021-08-27', '14:00', 10, 9),
(10, 6585, 5,'2021-09-13', '11:00', 10, 1);

/*populating Customers, Credit_cards and Owns tables*/
SELECT * FROM add_customer('Angie Carlson', 'Ap #915-3742 Ipsum Avenue', '168505070535', 'nisi@sapienAenean.edu', '5102460096023660', 504, '2025-04-12');
SELECT * FROM add_customer('Bernard Pate', '530-193 Sapien. Road', '161503114694', 'scelerisque@pedeCumsociis.com', '5224798415993862', 927, '2023-09-11');
SELECT * FROM add_customer('Ariana Spencer', 'Ap #871-1904 Lobortis Avenue', '161109242626', 'vel.turpis.Aliquam@acturpisegestas.edu', '5240081289296120', 334, '2023-06-02');
SELECT * FROM add_customer('Martha Guy', '2841 Ultrices. Road', '165402181753', 'mollis.Phasellus.libero@hymenaeosMaurisut.org', '5274960913947548', 424, '2022-02-23');
SELECT * FROM add_customer('Levi Avery', '4394 Adipiscing Av.', '163611272794', 'est.ac@Donecest.com', '5303568634289291', 279, '2021-11-08');
SELECT * FROM add_customer('Holly Day', 'Ap #214-8751 Nec Ave', '161503286989', 'diam@rutrumurnanec.net', '5372742683829820', 492, '2022-04-25');
SELECT * FROM add_customer('Uma Weeks', 'P.O. Box 793, 1381 Sit Road', '160807202395', 'imperdiet@egetnisi.co.uk', '5459805165907962', 552, '2024-03-05');
SELECT * FROM add_customer('Indira Mckee', '9415 Orci Rd.', '169706125912', 'felis.Nulla.tempor@arcuimperdiet.edu', '5464354259731163', 254, '2022-07-14');
SELECT * FROM add_customer('Hall Savage', '903-4888 Proin Ave', '168304019113', 'in.felis.Nulla@Sed.net', '5527288101232605', 523, '2025-02-21');
SELECT * FROM add_customer('Faith Graves', 'P.O. Box 146, 6550 Gravida St.', '169002058742', 'porta.elit@Crasvulputatevelit.ca', '5309012313326128', 264, '2022-07-07');

/*poplating Package table*/
SELECT * FROM add_course_package('Beginner 1', 2, 200, '2021-01-01', '2021-02-01');
SELECT * FROM add_course_package('Beginner 2', 2, 200, '2021-02-02', '2022-03-02');
SELECT * FROM add_course_package('Familiar 1', 3, 300, '2021-01-01', '2021-02-01');
SELECT * FROM add_course_package('Familiar 2', 3, 300, '2021-02-02', '2022-03-02');
SELECT * FROM add_course_package('Adept 1', 4, 400, '2021-01-01', '2021-02-01');
SELECT * FROM add_course_package('Adept 2', 4, 400, '2021-02-02', '2022-03-02');
SELECT * FROM add_course_package('Proficient 1', 5, 500, '2021-01-01', '2021-02-01');
SELECT * FROM add_course_package('Proficient 2', 5, 500, '2021-02-02', '2022-03-02');
SELECT * FROM add_course_package('Expert 1', 6, 600, '2021-01-01', '2021-02-01');
SELECT * FROM add_course_package('Expert 2', 6, 600, '2021-04-02', '2021-05-08');

/* test cases*/
SELECT * FROM update_credit_card(4, '123456789', 000, '2022-05-05');
SELECT * FROM update_credit_card(4, '12345678987', 123, '2022-05-06');
SELECT * FROM buy_course_package(4, 10);
SELECT * FROM buy_course_package(4, 10);
SELECT * FROM register_session(4, 5, 3757, 1, 'payment');
SELECT * FROM register_session(4, 1, 2317, 1, 'payment');
SELECT * FROM register_session(4, 5, 3757, 1, 'redeem');
SELECT * FROM register_session(4, 9, 2317, 1, 'redeem');
SELECT * FROM buy_course_package(4, 10);
SELECT * FROM get_available_course_packages();
SELECT * FROM get_my_course_package(4);
SELECT * FROM update_credit_card(4, '123', 123, '2022-05-07');
SELECT * FROM buy_course_package(4, 10);
SELECT * FROM register_session(4, 4, 3235, 1, 'redeem');
SELECT * FROM get_my_course_package(4);
SELECT * FROM register_session(4, 8, 4236, 3, 'redeem');
SELECT * FROM update_course_session(4, 5, 3757, 2);
SELECT * FROM get_available_course_offerings();