DROP TABLE IF EXISTS Conducts,
Consists,
Course_areas,
Courses,
Offerings,
Rooms,
Sessions;

CREATE TABLE Course_areas (area_name text, PRIMARY KEY (area_name));

/* 
 duration
 - refers to number of hours, (0, 7]
 - can only be conducted from 9am to 6pm
 - cannot be conducted during 12pm to 2pm */
CREATE TABLE Courses (
  course_id integer,
  area_name text NOT NULL,
  title text UNIQUE NOT NULL,
  description text NOT NULL,
  duration smallint CHECK(
    0 < duration
    AND duration <= 7
  ) NOT NULL,
  PRIMARY KEY (course_id),
  FOREIGN KEY (area_name) REFERENCES Course_areas ON DELETE CASCADE
);

CREATE TABLE Rooms (
  rid integer,
  location text NOT NULL,
  seating_capacity integer CHECK(seating_capacity >= 0) NOT NULL,
  PRIMARY KEY (rid)
);

/* TODO: sid for an offering starts from 1 */
/* TODO: end_time = start_time + duration */
/* TODO: no session between 12pm to 2pm -- can sessions take lunch break? */
/* date & time: ISO 8601 */
CREATE TABLE Sessions (
  sid integer,
  date date NOT NULL,
  start_time time CHECK(
    (
      start_time >= '09:00'
      AND start_time < '18:00'
    )
    AND (
      start_time < '12:00'
      OR start_time >= '14:00'
    )
  ) NOT NULL,
  end_time time CHECK(
    (
      end_time > '09:00'
      AND end_time <= '18:00'
    )
    AND (
      end_time <= '12:00'
      OR end_time > '14:00'
    )
    AND (start_time < end_time)
  ) NOT NULL,
  PRIMARY KEY (sid)
);

CREATE TABLE Offerings (
  course_id integer,
  launch_date date,
  start_date date,
  end_date date,
  registration_deadline date,
  fees integer,
  seating_capacity integer,
  target_number_registrations integer,
  PRIMARY KEY (course_id, launch_date),
  FOREIGN KEY (course_id) REFERENCES Courses ON DELETE CASCADE
);

CREATE TABLE Consists (
  course_id integer,
  launch_date date,
  sid integer,
  PRIMARY KEY(course_id, launch_date, sid),
  FOREIGN KEY(course_id, launch_date) REFERENCES Offerings,
  FOREIGN KEY(sid) REFERENCES Sessions
);

CREATE TABLE Conducts (
  sid integer,
  rid integer,
  /* TODO: eid integer, */
  PRIMARY KEY(sid, rid),
  FOREIGN KEY(sid) REFERENCES Sessions,
  FOREIGN KEY(rid) REFERENCES Rooms
);