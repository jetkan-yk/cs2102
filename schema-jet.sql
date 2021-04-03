DROP TABLE IF EXISTS Administrators,
Course_areas,
Courses,
Instructors,
Offerings,
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
    area_name   TEXT     NOT NULL,
    title       TEXT     NOT NULL,
    description TEXT,
    duration    SMALLINT NOT NULL
                CONSTRAINT duration_between_1_and_7
                CHECK (duration BETWEEN 1 AND 7),

    PRIMARY KEY (course_id),
    FOREIGN KEY (area_name) REFERENCES Course_areas
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Administrators (
    eid INTEGER,

    PRIMARY KEY (eid)
);

/* TODO: trigger update start_date and end_date */
/* TODO: trigger update seating_capacity, abort Offerings if
    seating_capacity < target_num_reg */
/* TODO: trigger abort Offerings if no Sessions created */
/* eid is the administrator id */
CREATE TABLE Offerings (
    course_id        INTEGER,
    offering_id      INTEGER,
    launch_date      DATE    NOT NULL,
    start_date       DATE,
    end_date         DATE,
    reg_deadline     DATE    NOT NULL
                     CONSTRAINT launch_date_before_reg_deadline
                          CHECK (launch_date < reg_deadline),
    fees             INTEGER NOT NULL
                     CONSTRAINT non_negative_fees
                          CHECK (fees >= 0),
    seating_capacity INTEGER,
    target_num_reg   INTEGER NOT NULL
                     CONSTRAINT non_negative_target_num_reg
                          CHECK (target_num_reg >= 0),
    eid              INTEGER NOT NULL,

    PRIMARY KEY (course_id, offering_id),
    FOREIGN KEY (course_id) REFERENCES Courses
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (eid)       REFERENCES Administrators,

    CONSTRAINT offerings_cand_key
        UNIQUE (course_id, launch_date),
    CONSTRAINT valid_reg_deadline
         CHECK (reg_deadline <= start_date + 10)
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

/* TODO: trigger check room availability */
/* TODO: trigger auto assign eid */
/* TODO: trigger auto assign & check validity of end_time = start_time + duration + lunch break */
/* Sessions can take lunch break, e.g. 4 hour session from 10am to 4pm */
/* date & time in ISO 8601 format */
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
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (eid)                    REFERENCES Instructors,
    FOREIGN KEY (rid)                    REFERENCES Rooms,

    CONSTRAINT sessions_cand_key
        UNIQUE (course_id, offering_id, session_id, session_date, start_time)
);