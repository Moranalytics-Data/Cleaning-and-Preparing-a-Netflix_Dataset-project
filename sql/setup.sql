/*
John G. Moran
"Cleaning and Preparing a Netflix Dataset"
This project is a data exploration and cleaning case study, undertaken to gain experience with the
hygienic and normalizing functions of SQL and PowerQuery. Below are the principal queries involved.
*/

-- SETUP

-- After repeated failed efforts to use MySQL Workbench’s Table Data Import Wizard, it became necessary to create the table "manually" with the query below:

CREATE TABLE netflix (
    show_id VARCHAR(10),
    type VARCHAR(10),
    title VARCHAR(255),
    director VARCHAR(255),
    cast TEXT,
    country VARCHAR(255),
    date_added VARCHAR(50),
    release_year INT,
    rating VARCHAR(10),
    duration VARCHAR(50),
    listed_in TEXT,
    description TEXT
);

-- It was also necessary to use MySQL's command-line client to import the CSV file, using the following query:

LOAD DATA LOCAL INFILE 'C:/Users/johnm/OneDrive/Desktop/data analysis/projects/Netflix from Kaggle/netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, type, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description);

-- A "working copy" of the database was created to preserve the origninal.

CREATE TABLE netflix_work AS
SELECT * FROM netflix;

-- The following queries checked to confirm that the columns had successfully imported in the desired formats:

DESCRIBE netflix_work;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'netflix_work'
AND table_schema = 'netflix';

-- The query below was used to generate a comma-separated list of all of the columns:

SELECT GROUP_CONCAT(column_name ORDER BY ordinal_position)
FROM information_schema.columns
WHERE table_name = 'netflix_work'
AND table_schema = 'netflix';

-- The results from the above query were then used in the following query, to check for duplicate rows:

SELECT show_id,type,title,director,cast,country,date_added,release_year,rating,duration,listed_in,description, COUNT(*) AS occurrences
FROM netflix_work
GROUP BY show_id,type,title,director,cast,country,date_added,release_year,rating,duration,listed_in,description
HAVING COUNT(*) > 1;