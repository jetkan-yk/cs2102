DROP TABLE IF EXISTS Courses,
Course_areas,
Offerings,
Sessions,
Rooms,
Consists,
Conducts;

CREATE TABLE Course_areas (area_name text, PRIMARY KEY (area_name));

/* 
 duration
 - refers to number of hours
 - can only be conducted from 9am to 6pm
 - cannot be conducted during 12pm to 2pm */
CREATE TABLE Courses (
  course_id integer,
  area_name text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  duration smallint CHECK(
    0 < duration
    AND duration <= 7
  ),
  PRIMARY KEY (course_id),
  FOREIGN KEY (area_name) REFERENCES Course_areas ON DELETE CASCADE
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

CREATE TABLE Sessions (
  sid integer,
  date date,
  start_time time,
  end_time time,
  PRIMARY KEY (sid)
);

CREATE TABLE Rooms (
  rid integer,
  location text,
  seating_capacity integer,
  PRIMARY KEY (rid)
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