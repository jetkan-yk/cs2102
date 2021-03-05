DELETE FROM Courses;

DELETE FROM Course_areas;

DELETE FROM Belongs;

INSERT INTO Courses (course_id, title, description, duration)
VALUES (
    2102,
    'Database Systems',
    'The aim of this module is to introduce the fundamental concepts and techniques necessary for the understanding and practice of design and implementation of database systems.',
    2
  ),
  (
    2107,
    'Introduction to Information Security',
    'This module serves as an introductory module on information security. It illustrates the fundamentals of how systems fail due to malicious activities and how they can be protected.',
    2
  ),
  (
    3235,
    'Computer Security',
    'The objective of this module is to provide a broad understanding of computer security with some indepth discussions on selected topics in system and network security.',
    3
  ),
  (
    3242,
    '3D Modelling and Animation',
    'This module aims to provide fundamental concepts in 3D modeling and animation. It also serves as a bridge to advanced media modules.',
    3
  ),
  (
    3244,
    'Machine Learning',
    'This module introduces basic concepts and algorithms in machine learning and neural networks.',
    3
  ),
  (
    4225,
    'Big Data Systems for Data Science',
    'Data science incorporates varying elements and builds on techniques and theories from many fields with the goal of extracting meaning from big data and creating data products.',
    4
  ),
  (
    4236,
    'Cryptography Theory and Practice',
    'This module aims to introduce the foundation, principles and concepts behind cryptology and the design of secure communication systems.',
    4
  ),
  (
    4248,
    'Natural Language Processing',
    'This module deals with computer processing of human languages, emphasizing a corpus-based empirical approach.',
    4
  ),
  (
    5340,
    'Uncertainty Modelling in AI',
    'The module covers modelling methods that are suitable for reasoning with uncertainty.',
    5
  );

INSERT INTO Course_areas (area_name)
VALUES ('Artificial Intelligence'),
  ('Computer Graphics and Games'),
  ('Computer Security'),
  ('Database Systems');

INSERT INTO Belongs (course_id, area_name)
VALUES (2102, 'Database Systems'),
  (2107, 'Computer Security'),
  (3235, 'Computer Security'),
  (3242, 'Computer Graphics and Games'),
  (3244, 'Artificial Intelligence'),
  (4225, 'Database Systems'),
  (4236, 'Computer Security'),
  (4248, 'Artificial Intelligence'),
  (5340, 'Artificial Intelligence');