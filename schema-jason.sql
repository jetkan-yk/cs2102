DROP TABLE IF EXISTS Pay_slips,
Employees,
For,
Instructors,
Part_time_Employees,
Part_time_instructors,
Full_time_Employees,
Full_time_instructors,
Managers,
Administrators,
Manages,
Specializes;


/*Weak entity -> dependent on Employees*/
CREATE TABLE Pay_slips (
    eid             INTEGER,
    num_work_hours  INTEGER,
    num_work_days   INTEGER,
    amount          INTEGER,
    payment_date    DATETIME,
    PRIMARY KEY (eid, payment_date),
    FOREIGN KEY (eid)
);

CREATE TABLE Employees (
    eid             INTEGER,
    ename           char(20),
    phone           INTEGER,
    address         char(50),
    email           char(50),
    join_date       DATETIME,
    depart_date     DATETIME
    PRIMARY KEY (eid)
);

CREATE TABLE For (
    eid             INTEGER,
    payment_date    DATETIME,
    PRIMARY KEY (eid, payment_date),
    FOREIGN KEY (eid) references Employees,
    FOREIGN KEY (payment_date) references Pay_slips
)

/*Instructors ISA Employees - not all instructors have to be employees - employees can be instructors and also other sub classes*/
CREATE TABLE Instructors (
    eid             INTEGER PRIMARY KEY REFERENCES Employees ON DELETE CASCADE,
    PRIMARY KEY (eid)
)

/*ISA Employee*/
CREATE TABLE Part_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees ON DELETE CASCADE,
    hourly_rate     INTEGER
)

CREATE TABLE Part_time_instructors (
    eid             INTEGER PRIMARY KEY REFERENCES Part_time_Employees ON DELETE CASCADE,,
)

/*ISA Employee*/
CREATE TABLE Full_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees ON DELETE CASCADE,
    monthly_salary  INTEGER
)

/*ISA Employee*/
CREATE TABLE Full_time_instructors (
    eid INTEGER PRIMARY KEY REFERENCES Full_time_Employees ON DELETE CASCADE,
)

/*ISA Full_time_Employee*/
CREATE TABLE Managers (
    eid INTEGER PRIMARY KEY REFERENCES Full_time_Employees ON DELETE CASCADE,
)

/*ISA Full_time_Employee*/
CREATE TABLE Administrators (
    eid     INTEGER PRIMARY KEY REFERENCES Full_time_Employees ON DELETE CASCADE,
)

CREATE TABLE Manages (
    eid             INTEGER,  /*instructor id*/
    cname           char(20)
    PRIMARY KEY (cname, eid)
)

CREATE TABLE Specializes (
    eid             INTEGER,  /*instructor id*/
    cname           char(20)
    PRIMARY KEY (cname, eid)
)