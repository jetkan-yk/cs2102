/*------------------------ Valid Add ---------------------------*/
-- SELECT * FROM add_employee('Wayne Tyson','1-348-754-1532','638-8711 Rhoncus Street','malesuada@interdumfeugiat.edu','2019-05-22','Instructor',2240, '{Computer Security}');

-- SELECT * FROM add_employee('Wendy Howe','1-338-439-7887','P.O. Box 736, 6389 Laoreet, Av.','tincidunt.congue.turpis@nuncullamcorpereu.net','2019-07-08','Administrator',1427,'{}');

-- SELECT * FROM add_employee('Nathaniel Mckenzie', '1-792-176-8701', 'P.O. Box 436, 6023 Malesuada Rd.', 'erat.volutpat@hendreritidante.com', '2019-08-19', 'Manager', 2327, '{Artificial Intelligence, Computer Graphics and Games}');

-- SELECT * FROM add_employee('Sade Ward','1-620-194-8585','P.O. Box 153, 7641 Nonummy Road','rutrum.justo.Praesent@justo.co.uk','2020-02-03','Instructor',1255,'{Life Sciences, Physics, Bioinformatics}');
-- /*------------------------ Valid Add ---------------------------*/

-- /*------------------------ Invalid Add ---------------------------*/

-- SELECT * FROM add_employee('John Doe','1-338-439-1234','P.O. Box 736, 6123 Clementi, Av.','testturpis@nuncorpereu.net','2019-07-08','Administrator',1627,'{Database Systems}');

-- SELECT * FROM add_employee('Alex Robertson', '1-632-176-4321', 'P.O. Box 643, 6023 Jurong Rd.', 'borat.tapat@hentidante.com', '2019-08-19', 'Manager', 3227, '{}');

-- SELECT * FROM add_employee('David Allis', '1-222-176-4321', 'P.O. Box 768, 35 Jurong East Rd.', 'david.tapat@hentidante.com', '2019-08-19', 'Instructor', 3112, '{}');

/*------------------------ Invalid Add ---------------------------*/


/*------------------------ Valid Remove ---------------------------*/

-- SELECT * FROM remove_employee(1, '2021-08-10');

-- SELECT * FROM remove_employee(4, '2021-11-30');

-- SELECT * FROM remove_employee(2, '2021-12-31');

-- /*------------------------ Valid Remove ---------------------------*/

-- /*------------------------ Invalid Remove ---------------------------*/
SELECT * FROM remove_employee(3, '2020-12-31');

/*depart date after join date*/
select * from remove_employee(4, '2020-01-31');

/*employee is an administrator handling some course offering where deadline is after depart date*/
SELECT * FROM remove_employee(2, '2020-12-31');

/*instructor departure date after session date*/
SELECT * FROM remove_employee(1, '2021-08-05');

/*------------------------ Invalid Remove ---------------------------*/

SELECT * FROM Employees;

SELECT * FROM Course_areas;

SELECT * FROM Manages;
SELECT * FROM Managers;

SELECT * FROM Specializes;
SELECT * FROM Instructors;

SELECT * FROM Administrators;
