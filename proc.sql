/* Sessions Triggers */

CREATE TRIGGER set_session_id
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION set_session_id_func();

CREATE OR REPLACE FUNCTION set_session_id_func()
  RETURNS TRIGGER AS
$$
BEGIN
  SELECT COALESCE(max(session_id) + 1, 1) INTO NEW.session_id
    FROM Sessions
   WHERE course_id = NEW.course_id
         AND offering_id = NEW.offering_id;

  RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;