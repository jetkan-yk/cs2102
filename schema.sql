DROP TABLE IF EXISTS Courses,
Course_areas,
Offerings,
Sessions,
Rooms,
Belongs,
Offers,
Consists,
Conducts;

/* duration refers to number of hours */
CREATE TABLE Courses (
  course_id integer,
  title text,
  description text,
  duration integer,
  PRIMARY KEY (course_id)
);

CREATE TABLE Course_areas (area_name text, PRIMARY KEY (area_name));

CREATE TABLE Offerings (
  launch_date date,
  start_date date,
  end_date date,
  registration_deadline date,
  fees integer,
  seating_capacity integer,
  target_number_registrations integer,
  PRIMARY KEY (launch_date)
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

CREATE TABLE Belongs (
  course_id integer,
  area_name text,
  PRIMARY KEY (course_id, area_name),
  FOREIGN KEY (course_id) REFERENCES Courses,
  FOREIGN KEY (area_name) REFERENCES Course_areas
);

CREATE TABLE Offers (
  course_id integer,
  launch_date date,
  PRIMARY KEY (course_id, launch_date),
  FOREIGN KEY (course_id) REFERENCES Courses,
  FOREIGN KEY (launch_date) REFERENCES Offerings
);

CREATE TABLE Consists (
  course_id integer,
  launch_date date,
  sid integer,
  PRIMARY KEY(course_id, launch_date, sid),
  FOREIGN KEY(course_id) REFERENCES Courses,
  FOREIGN KEY(launch_date) REFERENCES Offerings,
  FOREIGN KEY(sid) REFERENCES Sessions
);

CREATE TABLE Conducts (
  sid integer,
  rid integer,
  /* eid integer, */
  PRIMARY KEY(sid, rid),
  FOREIGN KEY(sid) REFERENCES Sessions,
  FOREIGN KEY(rid) REFERENCES Rooms
);