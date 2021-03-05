DROP FUNCTION IF EXISTS f1();

CREATE FUNCTION f1() RETURNS TABLE(course_area text, course_id integer, title text) AS $$
SELECT area_name,
  course_id,
  title
FROM Courses
  NATURAL JOIN Course_areas
  NATURAL JOIN Belongs
ORDER BY area_name,
  course_id;

$$ LANGUAGE SQL;