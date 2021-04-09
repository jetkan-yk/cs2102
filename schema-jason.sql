DROP TABLE IF EXISTS Pay_slips,
Employees,
Instructors,
Part_time_Employees,
Part_time_Instructors,
Full_time_Employees,
Full_time_Instructors,
Managers,
Administrators,
Manages,
Specializes
CASCADE;

/*An Employee has to be either a part_time_Employee or full_time_Employee*/
/*ISA Instructor An Employee COULD (may or may not) be an instructor*/
/*ISA Part-time Employee/Full-time Employees - An Employee HAS to be either a Full-time Employee or Part-time Employee, but not both*/
CREATE TABLE Employees (
    eid             SERIAL,
    ename           TEXT    NOT NULL,
    phone_number    TEXT    NOT NULL,
    home_address    TEXT    NOT NULL,
    email_address   TEXT    NOT NULL,
    join_date       DATE    NOT NULL,
    depart_date     DATE    CONSTRAINT valid_depart_date 
                            CHECK (depart_date > join_date),
    category        TEXT,
    salary          INTEGER,  /*Can be either hourly or monthly*/
    PRIMARY KEY (eid)
);

/*Weak entity -> dependent on Employees*/
-- CREATE TABLE Pay_slips (
--     eid             INTEGER,
--     num_work_hours  INTEGER,
--     num_work_days   INTEGER,
--     amount          INTEGER,
--     payment_date    DATE,
--     PRIMARY KEY (eid, payment_date),
--     FOREIGN KEY (eid) REFERENCES Employees
--         ON DELETE CASCADE
--         ON UPDATE CASCADE
-- );

/*Employee ISA Part-time Employee/Full-time Employees - An Employee HAS to be either a Full-time Employee or Part-time Employee, but not both*/
/*ISA Part-time Instructor - A Part-time Employee HAS to be a Part-time Instructor*/
CREATE TABLE Part_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_work_hours  INTEGER,
    hourly_rate     INTEGER
);
--
-- /*ISA Full-time Instructor/Manager/Administrator - A Full-time Employee HAS to be either a Full-time Instructor, an Administrator or a Manager*/
CREATE TABLE Full_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_work_days   INTEGER,
    monthly_salary  INTEGER
);

/*Employees ISA Instructor - An Employee COULD (may or may not) be an instructor*/
/*ISA Part-time Instructor/Full-time Instructor - An Instructor HAS to be either a Full-time Instructor or Part-time Instructor, but not both*/
CREATE TABLE Instructors (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_teach_hours INTEGER,
    course_areas    TEXT ARRAY
);

/*Full_time_Employee*/
CREATE TABLE Managers (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    course_areas    TEXT ARRAY
);

/*Full_time_Employee*/
CREATE TABLE Administrators (
    eid         INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

/*Each manager manages 0 or more course areas*/
CREATE TABLE Manages (
    eid             INTEGER,  /*manager id*/
    area_name       TEXT,
    PRIMARY KEY (area_name, eid),
    FOREIGN KEY (area_name) REFERENCES Course_areas
);

/*Each instructor specializes in a set of 1 or more course areas*/
CREATE TABLE Specializes (
    eid             INTEGER,  /*instructor id*/
    area_name       TEXT,
    PRIMARY KEY (area_name, eid),
    FOREIGN KEY (area_name) REFERENCES Course_areas
);

/*Administrator handles (0 or more?) course Offerings*/
-- CREATE TABLE Handles (
--     eid         INTEGER,
--     course_id   INTEGER,
--     offering_id INTEGER,
--     PRIMARY KEY (eid, course_id, offering_id),
--     FOREIGN KEY (course_id, offering_id) REFERENCES Offerings
-- );
