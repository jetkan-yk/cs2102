CREATE FUNCTION get_all_course_titles() RETURNS TABLE(title text) AS 'select title from Courses;' LANGUAGE SQL;

