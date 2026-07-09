SELECT name, count(*) AS n
FROM students
GROUP BY name
ORDER BY n DESC;