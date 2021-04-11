DROP TABLE IF EXISTS
Administrators,
Buys,
Cancels,
Course_areas,
Courses,
Credit_cards,
Customers,
Instructors,
Offerings,
Owns,
Packages,
Redeems,
Registers,
Rooms,
Employees,
Salary_payment_records,
Instructors,
Part_time_Employees,
Part_time_Instructors,
Full_time_Employees,
Full_time_Instructors,
Managers,
Administrators,
Manages,
Specializes,
Sessions CASCADE;

CREATE TABLE Employees (
    eid             SERIAL,
    ename           TEXT            NOT NULL,
    phone_number    VARCHAR (15)    NOT NULL,
    home_address    TEXT            NOT NULL,
    email_address   TEXT            NOT NULL,
    join_date       DATE            NOT NULL,
    depart_date     DATE            CONSTRAINT valid_depart_date 
                                    CHECK (depart_date > join_date),
    category        TEXT,
    salary          INTEGER,  /*Can be either hourly or monthly*/
    PRIMARY KEY (eid)
);

CREATE TABLE Instructors (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_teach_hours INTEGER CONSTRAINT non_negative
                            CHECK (num_teach_hours >= 0),
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

CREATE TABLE Course_areas (
    area_name TEXT,

    PRIMARY KEY (area_name)
);

/*
 duration
 - refers to number of hours, (0, 7]
 - can only be conducted from 9am to 6pm
 - cannot be conducted during 12pm to 2pm */
CREATE TABLE Courses (
    course_id   SERIAL,
    area_name   TEXT    NOT NULL,
    title       TEXT    NOT NULL,
    description TEXT,
    duration    INTEGER NOT NULL
                CONSTRAINT duration_between_1_and_7
                CHECK (duration BETWEEN 1 AND 7),

    PRIMARY KEY (course_id),
    FOREIGN KEY (area_name) REFERENCES Course_areas
);

/* eid is the administrator id */
CREATE TABLE Offerings (
    course_id        INTEGER,
    offering_id      INTEGER,
    launch_date      DATE    NOT NULL,
    start_date       DATE,
    end_date         DATE,
    reg_deadline     DATE    NOT NULL
                     CONSTRAINT launch_date_before_reg_deadline
                          CHECK (launch_date <= reg_deadline),
    fees             INTEGER NOT NULL
                     CONSTRAINT non_negative_fees
                          CHECK (fees >= 0),
    seating_capacity INTEGER DEFAULT 0,
    target_num_reg   INTEGER NOT NULL
                     CONSTRAINT non_negative_target_num_reg
                          CHECK (target_num_reg >= 0),
    eid              INTEGER NOT NULL,

    PRIMARY KEY (course_id, offering_id),
    FOREIGN KEY (course_id) REFERENCES Courses,
    FOREIGN KEY (eid)       REFERENCES Administrators,

    CONSTRAINT offerings_cand_key
        UNIQUE (course_id, launch_date)
);

CREATE TABLE Rooms (
    rid              INTEGER,
    location         TEXT,
    seating_capacity INTEGER NOT NULL
                     CONSTRAINT non_negative_seating_capacity
                          CHECK (seating_capacity >= 0),

    PRIMARY KEY (rid)
);

/* Sessions can take lunch break, e.g. 4 hour session from 11am to 5pm */
/* eid is the instructor id */
CREATE TABLE Sessions (
    course_id    INTEGER,
    offering_id  INTEGER,
    session_id   INTEGER,
    session_date DATE    NOT NULL,
    start_time   TIME    NOT NULL
                 CONSTRAINT valid_start_time
                      CHECK (start_time BETWEEN '09:00' AND '11:00'
                         OR  start_time BETWEEN '14:00' AND '17:00'),
    end_time     TIME,
    eid          INTEGER,
    rid          INTEGER NOT NULL,

    PRIMARY KEY (course_id, offering_id, session_id),
    FOREIGN KEY (course_id, offering_id) REFERENCES Offerings
        ON DELETE CASCADE,
    FOREIGN KEY (eid)                    REFERENCES Instructors,
    FOREIGN KEY (rid)                    REFERENCES Rooms,

    CONSTRAINT sessions_cand_key
        UNIQUE (course_id, offering_id, session_date, start_time)
);

CREATE TABLE Customers (
    cust_id SERIAL,
    name    TEXT        NOT NULL,
    address TEXT        NOT NULL,
    email   TEXT        NOT NULL,
    phone   VARCHAR(15) NOT NULL,

    PRIMARY KEY (cust_id)
);

CREATE TABLE Credit_cards (
    cc_number   VARCHAR(19),
    cvv         INTEGER NOT NULL,
    expiry_date DATE    NOT NULL,

    PRIMARY KEY (cc_number)
);

CREATE TABLE Owns (
    cc_number VARCHAR(19),
    cust_id   INTEGER   NOT NULL,
    owns_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (cc_number),
    FOREIGN KEY (cc_number) REFERENCES Credit_cards,
    FOREIGN KEY (cust_id)   REFERENCES Customers
);

CREATE TABLE Cancels (
    cancel_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cust_id        INTEGER   NOT NULL,
    course_id      INTEGER   NOT NULL,
    offering_id    INTEGER   NOT NULL,
    session_id     INTEGER   NOT NULL,
    refund_amt     INTEGER,
    package_credit BOOLEAN,

    PRIMARY KEY (cancel_ts),
    FOREIGN KEY (cust_id)                            REFERENCES Customers,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);

CREATE TABLE Registers (
    registers_ts TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    cc_number    VARCHAR(19) NOT NULL,
    course_id    INTEGER     NOT NULL,
    offering_id  INTEGER     NOT NULL,
    session_id   INTEGER     NOT NULL,

    PRIMARY KEY (registers_ts),
    FOREIGN KEY (cc_number)                          REFERENCES Owns,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);

CREATE TABLE Packages (
    package_id      SERIAL,
    name            TEXT    NOT NULL,
    num_free_reg    INTEGER NOT NULL,
                    CONSTRAINT non_negative_num_free_reg
                         CHECK (num_free_reg >= 0),
    price           INTEGER NOT NULL
                    CONSTRAINT non_negative_price
                         CHECK (price >= 0),
    sale_start_date DATE    NOT NULL,
    sale_end_date   DATE    NOT NULL
                    CONSTRAINT start_date_before_end_date
                         CHECK (sale_start_date <= sale_end_date),

    PRIMARY KEY (package_id)
);

CREATE TABLE Buys (
    buys_ts           TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    package_id        INTEGER     NOT NULL,
    cc_number         VARCHAR(19) NOT NULL,
    num_remain_redeem INTEGER     NOT NULL,

    PRIMARY KEY (buys_ts),
    FOREIGN KEY (package_id) REFERENCES Packages,
    FOREIGN KEY (cc_number)  REFERENCES Owns
);

CREATE TABLE Redeems (
    redeems_ts  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    buys_ts     TIMESTAMP NOT NULL,
    course_id   INTEGER   NOT NULL,
    offering_id INTEGER   NOT NULL,
    session_id  INTEGER   NOT NULL,

    PRIMARY KEY (redeems_ts),
    FOREIGN KEY (buys_ts)                            REFERENCES Buys,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);

CREATE TABLE Salary_payment_records (
    eid             INTEGER,
    ename           TEXT,
    e_status        TEXT,
    num_work_days   INTEGER,
    num_work_hours  INTEGER,
    monthly_salary  INTEGER,
    hourly_rate     INTEGER,
    salary_amount   INTEGER,
    payment_date    DATE,
    PRIMARY KEY (eid, payment_date),
    FOREIGN KEY (eid) REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

/*Employee ISA Part-time Employee/Full-time Employees - An Employee HAS to be either a Full-time Employee or Part-time Employee, but not both*/
/*ISA Part-time Instructor - A Part-time Employee HAS to be a Part-time Instructor*/
CREATE TABLE Part_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_work_hours  INTEGER CONSTRAINT non_negative
                            CHECK (num_work_hours >= 0),
    hourly_rate     INTEGER
);
--
-- /*ISA Full-time Instructor/Manager/Administrator - A Full-time Employee HAS to be either a Full-time Instructor, an Administrator or a Manager*/
CREATE TABLE Full_time_Employees (
    eid             INTEGER PRIMARY KEY REFERENCES Employees
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    monthly_salary  INTEGER
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