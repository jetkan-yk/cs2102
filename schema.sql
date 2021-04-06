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
Sessions CASCADE;

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

CREATE TABLE Administrators (
    eid INTEGER,

    PRIMARY KEY (eid)
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

CREATE TABLE Instructors (
    eid INTEGER,

    PRIMARY KEY (eid)
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
    cust_id INTEGER,
    name    TEXT    NOT NULL,
    address TEXT    NOT NULL,
    email   TEXT    NOT NULL,
    phone   INTEGER NOT NULL,

    PRIMARY KEY (cust_id)
);

CREATE TABLE Credit_cards (
    cc_number   INTEGER,
    cvv         INTEGER NOT NULL,
    expiry_date DATE    NOT NULL,

    PRIMARY KEY (cc_number)
);

CREATE TABLE Owns (
    cc_number INTEGER,
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
    registers_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cc_number    INTEGER   NOT NULL,
    course_id    INTEGER   NOT NULL,
    offering_id  INTEGER   NOT NULL,
    session_id   INTEGER   NOT NULL,

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
    buys_ts           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    package_id        INTEGER   NOT NULL,
    cc_number         INTEGER   NOT NULL,
    num_remain_redeem INTEGER   NOT NULL,

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
