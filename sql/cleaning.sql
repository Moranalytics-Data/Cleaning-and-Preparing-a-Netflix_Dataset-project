/*
John G. Moran
"Cleaning and Preparing a Netflix Dataset"
This project is a data exploration and cleaning case study, undertaken to gain experience with the
hygienic and normalizing functions of SQL and PowerQuery. Below are the principal queries involved.
*/

-- CLEANING

-- This query checked for missing and NULL values:

SELECT
  COUNT(*) AS total_rows,
  COUNT(show_id) AS non_null_show_id,
	COUNT(*) - COUNT(show_id) AS missing_show_id,
  COUNT(type) AS non_null_type,
	COUNT(*) - COUNT(type) AS missing_type,
  COUNT(title) AS non_null_title,
	COUNT(*) - COUNT(title) AS missing_title,
  COUNT(director) AS non_null_director,
	COUNT(*) - COUNT(director) AS missing_director,
  COUNT(cast) AS non_null_cast,
	COUNT(*) - COUNT(cast) AS missing_cast,
  COUNT(country) AS non_null_country,
	COUNT(*) - COUNT(country) AS missing_country,
  COUNT(date_added) AS non_null_date_added,
	COUNT(*) - COUNT(date_added) AS missing_date_added,
  COUNT(release_year) AS non_null_release_year,
	COUNT(*) - COUNT(release_year) AS missing_release_year, 
  COUNT(rating) AS non_null_rating,
	COUNT(*) - COUNT(rating) AS missing_rating,
  COUNT(duration) AS non_null_duration,
	COUNT(*) - COUNT(duration) AS missing_duration,
  COUNT(listed_in) AS non_null_listed_in,
	COUNT(*) - COUNT(listed_in) AS missing_listed_in,
  COUNT(description) AS non_null_description,
	COUNT(*) - COUNT(description) AS missing_description 
FROM netflix_work;

-- This query was employed to convert empty strings into NULLs:

UPDATE netflix_work
SET
  show_id = NULLIF(show_id, ''),
  type = NULLIF(type, ''),
  title = NULLIF(title, ''),
  director = NULLIF(director, ''),
  cast = NULLIF(cast, ''),
  country = NULLIF(country, ''),
  date_added = NULLIF(date_added, ''),
  release_year = NULLIF(release_year, ''),
  rating = NULLIF(rating, ''),
  duration = NULLIF(duration, ''),
  listed_in = NULLIF(listed_in, ''),
  description = NULLIF(description, '');
  
-- This query converted the format of "date added" field (which was written like "September 30, 2014") to a SQL-compatible format:

UPDATE netflix_work
SET date_added = STR_TO_DATE(date_added, '%M %d, %Y');

-- The following queries explored the various circumstances in which certain categories included a high level of NULLs:

SELECT *
FROM netflix_work
WHERE director IS NULL
ORDER BY type, listed_in;

SELECT 
	SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS movies_with_no_listed_director,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS TV_shows_with_no_listed_director
FROM netflix_work
WHERE director IS NULL;

SELECT *
FROM netflix_work
WHERE director IS NULL
  AND type = 'Movie';
  
SELECT *
FROM netflix_work
WHERE cast IS NULL
ORDER BY type, listed_in;

SELECT *
FROM netflix_work
WHERE country IS NULL
ORDER BY type, listed_in;

-- The query below was intended to check that the "release_year" column did not have any unwanted characters in it.
-- (It was likely not necessary since this is a query usually meant to find artifacts from currency figures.)

SELECT release_year
FROM netflix_work
WHERE release_year LIKE '%$%'
   OR release_year LIKE '%,%';

-- This is a sample of a query intended to check each of the columns in turn for whitespace:

SELECT title
FROM netflix_work
WHERE title != TRIM(title);

-- This query was necessary to correct a handful of titles whose rating field accidentally contained running times:

UPDATE netflix_work
SET duration = rating,
    rating = NULL
WHERE rating LIKE '%min%';

/*
After I used PowerQuery to create multiple "bridge" tables, I realized that the results
needed various forms of cleaning.
*/

-- It was necessary to detele some lines in the "actor_movie_bridge" table that became garbled due to an errant paragraph return in the original CSV:

SELECT *
FROM actor_movie_bridge
WHERE show_id LIKE '%Flying Fortress%';

DELETE FROM actor_movie_bridge
WHERE show_id LIKE '%Flying Fortress';

-- Because the "genre_title_bridge" table was found to have numerous leading spaces, the following query was applied:

UPDATE genre_title_bridge
SET genre = TRIM(genre);

/*
It became apparent that the bridge tables had numerous hidden characters (presumably a side-effect
of their PowerQuery-based creation). The following query was run to confirm that, for example, 
the "genre_title_bridge" table included repeated such instances:
*/

SELECT DISTINCT genre,
       LENGTH(genre) AS orig_length,
       LENGTH(REPLACE(REPLACE(genre, '\r', ''), '\n', '')) AS cleaned_length
FROM genre_title_bridge
ORDER BY genre;

-- This query was applied to clean the column(s) in question:

UPDATE genre_title_bridge
SET genre = REPLACE(REPLACE(genre, '\r', ''), '\n', '');

/*
Although the assumption was that the carriage returns were created in the PowerQuery conversion 
process, a check was done to ensure that the original "listed_in" column did not, itself, 
contain any instances of \r carriage return and/or \n line feed characters.
*/

SELECT *
FROM netflix_work
WHERE listed_in LIKE CONCAT('%', CHAR(13), '%')
OR listed_in LIKE CONCAT('%', CHAR(10), '%');

-- Despite efforts to eradicate hidden characters in PowerQuery and/or Excel, they continued to appear in the imported bridge tables. 
-- The following query confirmed as much for the "director_title_bridge" table:

SELECT *
FROM director_title_bridge
WHERE director LIKE CONCAT('%', CHAR(13), '%')
OR director LIKE CONCAT('%', CHAR(10), '%');

-- This query confirmed that every row in the "director_title_bridge" table indeed appeared to have an extra character at the end of its "director" field:

SELECT DISTINCT director,
       LENGTH(director) AS orig_length,
       LENGTH(REPLACE(REPLACE(director, '\r', ''), '\n', '')) AS cleaned_length
FROM director_title_bridge
ORDER BY director;

-- This query removed those hidden characters from the new table:

UPDATE director_title_bridge
SET director = REPLACE(REPLACE(director, '\r', ''), '\n', '');

/*
Because I continued to make efforts to remove hidden characters in PowerQuery and/or Excel in advance of 
their import into MySQL, the following queries were run to see if those efforts indeed were successful.
They weren't: The same additional cleaning steps within SQL itself were necessary.
*/

SELECT DISTINCT country,
       LENGTH(country) AS orig_length,
       LENGTH(REPLACE(REPLACE(country, '\r', ''), '\n', '')) AS cleaned_length
FROM country_title_bridge
ORDER BY country;

SELECT DISTINCT country,
       LENGTH(country) AS orig_length,
       LENGTH(REPLACE(country, '\r', '')) AS cleaned_length
FROM country_title_bridge
ORDER BY country;

UPDATE country_title_bridge
SET country = REPLACE(REPLACE(country, '\r', ''), '\n', '');