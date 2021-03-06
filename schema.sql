DROP TABLE IF EXISTS Course_areas,
Courses,
Offerings,
Rooms,
Sessions;

CREATE TABLE Course_areas (
    area_name text,
    PRIMARY KEY (area_name)
);

/*
 duration
 - refers to number of hours, (0, 7]
 - can only be conducted from 9am to 6pm
 - cannot be conducted during 12pm to 2pm */
CREATE TABLE Courses (
    course_id   integer,
    area_name   text NOT NULL,
    title       text NOT NULL,
    description text,
    duration    smallint DEFAULT 1 NOT NULL
                CONSTRAINT valid_duration
                CHECK (duration BETWEEN 1 AND 7),
    PRIMARY KEY (course_id),
    FOREIGN KEY (area_name) REFERENCES Course_areas
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Rooms (
    rid              integer,
    location         text,
    seating_capacity integer NOT NULL
                     CONSTRAINT non_negative_seating_capacity
                     CHECK (seating_capacity >= 0),
    PRIMARY KEY (rid)
);

/* TODO: routine update start_date and end_date */
/* TODO: routine update seating_capacity */
/* TODO: trigger check reg_deadline <= start_date + 10 */
/* TODO: trigger check seating_capacity >= target_num_reg */
/* TODO: trigger check Offerings has total participation in Sessions */
CREATE TABLE Offerings (
    offering_id      integer,
    course_id        integer,
    launch_date      date    NOT NULL,
    start_date       date,
    end_date         date,
    reg_deadline     date    NOT NULL,
    fees             integer NOT NULL
                     CONSTRAINT non_negative_fees
                     CHECK (target_num_reg >= 0),
    seating_capacity integer,
    target_num_reg   integer NOT NULL
                     CONSTRAINT non_negative_target_num_reg
                     CHECK (target_num_reg >= 0),
    PRIMARY KEY (offering_id),
    FOREIGN KEY (course_id) REFERENCES Courses
        ON DELETE CASCADE,
    UNIQUE (course_id, launch_date)
);

/* TODO: auto assign session_id for an offering starts from 1 */
/* TODO: CHECK end_time = start_time + duration */
/* Sessions can take lunch break, e.g. 4 hour session from 10am to 4pm */
/* date & time in ISO 8601 format */
CREATE TABLE Sessions (
    offering_id integer,
    session_id  integer,
    date        date NOT NULL,
    start_time  time
                CONSTRAINT valid_start_time
                CHECK(start_time BETWEEN '09:00' AND '11:00'
                   OR start_time BETWEEN '14:00' AND '17:00'),
    end_time    time
                CONSTRAINT valid_end_time
                CHECK(end_time BETWEEN '10:00' AND '12:00'
                   OR end_time BETWEEN '15:00' AND '18:00'),
    PRIMARY KEY (offering_id, session_id),
    FOREIGN KEY (offering_id) REFERENCES Offerings
        ON DELETE CASCADE
);
