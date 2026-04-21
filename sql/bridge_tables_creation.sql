/*
John G. Moran
"Cleaning and Preparing a Netflix Dataset"
This project is a data exploration and cleaning case study, undertaken to gain experience with the
hygienic and normalizing functions of SQL and PowerQuery. Below are the principal queries involved.
*/

-- CREATING BRIDGE TABLES

-- Once these various tables, below, were imported, I discovered that many aspects required cleaning.
-- The queries for those cleaning processes appear in the document, cleaning.sql.


-- This query created the "actor_title_bridge" table:

CREATE TABLE actor_title_bridge (
             show_id VARCHAR(10) NULL,
             title VARCHAR(255) NULL,
             actor VARCHAR(100) NULL
);

-- As was the case when importing the main dataset, this query had to be run through MySQL's command-line client:

LOAD DATA LOCAL INFILE 'C:/Users/johnm/OneDrive/Desktop/data analysis/projects/Netflix from Kaggle/actor_title_bridge.csv'
INTO TABLE actor_title_bridge
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id,title,actor);

-- These queries created a "genre_title_bridge" table based on the contents of the main dataset's "listed_in" field:

CREATE TABLE genre_title_bridge (
             show_id VARCHAR(10) NULL,
             title VARCHAR(255) NULL,
             genre VARCHAR(100) NULL
);

LOAD DATA LOCAL INFILE 'C:/Users/johnm/OneDrive/Desktop/data analysis/projects/Netflix from Kaggle/genre_title_bridge.csv'
INTO TABLE genre_title_bridge
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id,title,genre);

-- The following queries created & imported a "director_title_bridge" table:

CREATE TABLE director_title_bridge (
             show_id VARCHAR(10) NULL,
             title VARCHAR(255) NULL,
             director VARCHAR(100) NULL
);

LOAD DATA LOCAL INFILE 'C:/Users/johnm/OneDrive/Desktop/data analysis/projects/Netflix from Kaggle/director_title_bridge.csv'
INTO TABLE director_title_bridge
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id,title,director);

-- These queries created a "country_title_bridge" table:

CREATE TABLE country_title_bridge (
             show_id VARCHAR(10) NULL,
             title VARCHAR(255) NULL,
             country VARCHAR(100) NULL
);

LOAD DATA LOCAL INFILE 'C:/Users/johnm/OneDrive/Desktop/data analysis/projects/Netflix from Kaggle/bridge tables/country_title_bridge.csv'
INTO TABLE country_title_bridge
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id,title,country);