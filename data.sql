DELETE FROM Course_areas;

DELETE FROM Courses;

DELETE FROM Rooms;

INSERT INTO Course_areas (area_name)
VALUES ('Artificial Intelligence'),
  ('Computer Graphics and Games'),
  ('Computer Security'),
  ('Database Systems'),
  ('Software Engineering');

INSERT INTO Courses (
    course_id,
    title,
    description,
    duration,
    area_name
  )
VALUES (
    2102,
    'Introduction to Database Systems',
    'The aim of this module is to introduce the fundamental concepts and techniques necessary for the understanding and practice of design and implementation of database systems.',
    2,
    'Database Systems'
  ),
  (
    2107,
    'Introduction to Information Security',
    'This module serves as an introductory module on information security. It illustrates the fundamentals of how systems fail due to malicious activities and how they can be protected.',
    2,
    'Computer Security'
  ),
  (
    3235,
    'Advanced Computer Security',
    'The objective of this module is to provide a broad understanding of computer security with some indepth discussions on selected topics in system and network security.',
    3,
    'Computer Security'
  ),
  (
    3242,
    '3D Modelling and Animation',
    'This module aims to provide fundamental concepts in 3D modeling and animation. It also serves as a bridge to advanced media modules.',
    3,
    'Computer Graphics and Games'
  ),
  (
    3244,
    'Machine Learning',
    'This module introduces basic concepts and algorithms in machine learning and neural networks.',
    3,
    'Artificial Intelligence'
  ),
  (
    4218,
    'Software Testing',
    'This module covers the concepts and practice of software testing including unit testing, integration testing, and regression testing.',
    4,
    'Software Engineering'
  ),
  (
    4225,
    'Big Data Systems for Data Science',
    'Data science incorporates varying elements and builds on techniques and theories from many fields with the goal of extracting meaning from big data and creating data products.',
    4,
    'Database Systems'
  ),
  (
    4236,
    'Cryptography Theory and Practice',
    'This module aims to introduce the foundation, principles and concepts behind cryptology and the design of secure communication systems.',
    4,
    'Computer Security'
  ),
  (
    4248,
    'Natural Language Processing',
    'This module deals with computer processing of human languages, emphasizing a corpus-based empirical approach.',
    4,
    'Artificial Intelligence'
  ),
  (
    5340,
    'Uncertainty Modelling in AI',
    'The module covers modelling methods that are suitable for reasoning with uncertainty.',
    5,
    'Artificial Intelligence'
  );

INSERT INTO Rooms (rid, location, seating_capacity)
VALUES(1, '1F-01', 20),
  (2, '1F-02', 10),
  (3, '1F-03', 15),
  (4, '1F-04', 25),
  (5, '2F-01', 50),
  (6, '2F-02', 40),
  (7, '2F-03', 25),
  (8, '2F-04', 25),
  (9, '3F-01', 100),
  (10, '3F-02', 100);