INSERT INTO Course_areas (area_name)
VALUES ('Artificial Intelligence'),
  ('Computer Graphics and Games'),
  ('Computer Security'),
  ('Database Systems'),
  ('Software Engineering');

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

INSERT INTO Administrators (eid)
VALUES (1),
  (2),
  (3),
  (4),
  (5),
  (6),
  (7),
  (8),
  (9),
  (10);

INSERT INTO Offerings (
    course_id,
    offering_id,
    launch_date,
    reg_deadline,
    fees,
    target_num_reg,
    eid
  )
VALUES (1, 1242, '2021-02-07', '2021-04-22', 260, 198, 3),
  (1, 2317, '2021-01-10', '2021-04-10', 320, 101, 1),
  (2, 4248, '2021-02-28', '2021-05-29', 190, 141, 2),
  (3, 4248, '2021-02-27', '2021-06-04', 400, 137, 8),
  (4, 3235, '2021-03-17', '2021-04-11', 170, 24, 5),
  (5, 3242, '2021-03-20', '2021-06-03', 285, 110, 5),
  (5, 3757, '2021-01-31', '2021-06-30', 400, 112, 1),
  (5, 4236, '2021-01-12', '2021-05-26', 170, 61, 5),
  (6, 4218, '2021-01-30', '2021-05-27', 460, 153, 4),
  (8, 4225, '2021-03-12', '2021-06-15', 75, 23, 7),
  (8, 4236, '2021-02-28', '2021-06-23', 440, 127, 4),
  (9, 2317, '2021-02-10', '2021-04-03', 200, 51, 9),
  (9, 5340, '2021-03-15', '2021-06-04', 270, 171, 6),
  (10, 6585, '2021-02-07', '2021-06-23', 125, 73, 9);

INSERT INTO Sessions (
    course_id,
    offering_id,
    session_date,
    start_time,
    rid
  )
VALUES (1, 1242, '2021-08-04', '10:00', 1),
  (1, 2317, '2021-07-01', '10:00', 3),
  (1, 2317, '2021-07-01', '14:00', 3),
  (1, 2317, '2021-08-30', '09:00', 6),
  (1, 2317, '2021-09-15', '14:00', 2),
  (2, 4248, '2021-08-09', '09:00', 8),
  (3, 4248, '2021-07-31', '15:00', 4),
  (3, 4248, '2021-08-09', '10:00', 5),
  (3, 4248, '2021-09-09', '15:00', 1),
  (3, 4248, '2021-09-18', '09:00', 9),
  (3, 4248, '2021-09-23', '16:00', 5),
  (3, 4248, '2021-09-25', '15:00', 9),
  (4, 3235, '2021-07-28', '11:00', 2),
  (4, 3235, '2021-08-01', '14:00', 8),
  (5, 3242, '2021-07-12', '16:00', 10),
  (5, 3242, '2021-08-27', '16:00', 5),
  (5, 3242, '2021-09-26', '14:00', 5),
  (5, 3242, '2021-09-28', '09:00', 4),
  (5, 3757, '2021-07-15', '10:00', 3),
  (5, 3757, '2021-08-07', '09:00', 10),
  (5, 3757, '2021-08-12', '10:00', 8),
  (5, 3757, '2021-09-03', '10:00', 4),
  (5, 3757, '2021-09-29', '11:00', 5),
  (5, 4236, '2021-07-25', '10:00', 2),
  (5, 4236, '2021-07-29', '09:00', 5),
  (6, 4218, '2021-09-30', '16:00', 4),
  (8, 4225, '2021-08-26', '11:00', 5),
  (8, 4225, '2021-09-27', '09:00', 1),
  (8, 4236, '2021-07-05', '11:00', 8),
  (8, 4236, '2021-07-11', '14:00', 5),
  (8, 4236, '2021-09-30', '10:00', 3),
  (9, 2317, '2021-07-13', '10:00', 9),
  (9, 2317, '2021-08-10', '16:00', 3),
  (9, 2317, '2021-08-24', '09:00', 9),
  (9, 2317, '2021-09-05', '14:00', 1),
  (9, 5340, '2021-08-13', '09:00', 10),
  (9, 5340, '2021-08-18', '14:00', 4),
  (10, 6585, '2021-07-05', '14:00', 4),
  (10, 6585, '2021-08-09', '15:00', 5),
  (10, 6585, '2021-08-12', '17:00', 3),
  (10, 6585, '2021-08-27', '15:00', 9),
  (10, 6585, '2021-09-13', '17:00', 1);

/*
Commenting away the empty INSERT queries to
suppress errors when running \i data.sql

INSERT INTO Customers (
  cust_id,
  name,
  address,
  phone,
  email
)
VALUES ("04533","Faith Graves","P.O. Box 146, 6550 Gravida St.","16900205 8742","porta.elit@Crasvulputatevelit.ca"),
("64715","Martha Guy","2841 Ultrices. Road","16540218 1753","mollis.Phasellus.libero@hymenaeosMaurisut.org"),
("95258","Hall Savage","903-4888 Proin Ave","16830401 9113","in.felis.Nulla@Sed.net"),
("84828","Holly Day","Ap #214-8751 Nec Ave","16150328 6989","diam@rutrumurnanec.net"),
("25027","Angie Carlson","Ap #915-3742 Ipsum Avenue","16850507 0535","nisi@sapienAenean.edu"),
("54068","Bernard Pate","530-193 Sapien. Road","16150311 4694","scelerisque@pedeCumsociis.com"),
("90051","Indira Mckee","9415 Orci Rd.","16970612 5912","felis.Nulla.tempor@arcuimperdiet.edu"),
("88106","Uma Weeks","P.O. Box 793, 1381 Sit Road","16080720 2395","imperdiet@egetnisi.co.uk"),
("60405","Ariana Spencer","Ap #871-1904 Lobortis Avenue","16110924 2626","vel.turpis.Aliquam@acturpisegestas.edu"),
("78734","Levi Avery","4394 Adipiscing Av.","16361127 2794","est.ac@Donecest.com");

INSERT INTO Credit_cards (
  cc_number,
  CVV,
  expiry_date
)
VALUES ("5309 0123 1332 6128","264","07/22"),
("510246 0096023660","504","02/25"),
("524 00812 89296 120","334","06/23"),
("552728 810123 2605","523","04/25"),
("5303 5686 3428 9291","279","10/21"),
("545980 516590 7962","552","10/26"),
("5274 9609 1394 7548","424","05/26"),
("522479 841599 3862","927","01/23"),
("537 27426 83829 820","492","01/26"),
("5464354259731163","254","07/22");

INSERT INTO Owns (
  cc_number,
  cust-id,
  from_date
)
VALUES ("5309 0123 1332 6128", "Faith Graves", ),
("510246 0096023660", "Martha Guy", ),
("524 00812 89296 120", "Hall Savage", ),
("552728 810123 2605", "Holly Day", ),
("5303 5686 3428 9291", "Angie Carlson", ),
("545980 516590 7962", "Bernard Pate", ),
("5274 9609 1394 7548", "Indira Mckee", ),
("522479 841599 3862", "Uma Weeks", ),
("537 27426 83829 820", "Ariana Spencer", ),
("5464354259731163", "Levi Avery", );

INSERT INTO Registers (
  reg_date,
  cc_number,
  course_id,
  offering_id,
  session_id
)
VALUES ();

INSERT INTO Cancels (
  cancel_date,
  refund_amt,
  package_credit,
  cust_id
)
VALUES ();

INSERT INTO Buys (
  buy_date,
  num_free_registrations,
  num_remaining_redemptions,
  package_id,
  cc_number
)
VALUES ();

INSERT INTO Course_packages (
  package_id,
  num_free_registrations,
  sale_start_date,
  sale_end_date,
  name,
  price
)
VALUES ();

INSERT INTO Redeems (
  redeem_date,
  package_id,
  cc_number,
  buy_date,
  course_id,
  offering_id,
  session_id
)
VALUES ();

*/
