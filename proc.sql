DROP FUNCTION IF EXISTS course_info();

CREATE FUNCTION course_info() RETURNS TABLE(course_area text, course_id integer, title text) AS $$
SELECT area_name,
  course_id,
  title
FROM Courses
ORDER BY area_name,
  course_id;

$$ LANGUAGE SQL;