/*
John G. Moran
"Cleaning and Preparing a Netflix Dataset"
This project is a data exploration and cleaning case study, undertaken to gain experience with the
hygienic and normalizing functions of SQL and PowerQuery. Below are the principal queries involved.
*/

-- BRIDGE TABLE ANALYSES

-- This query determined which actors have worked with which other actors the most:

SELECT
	a.actor AS actor_A,
    b.actor AS actor_B,
    COUNT(*) AS collaborations
FROM actor_title_bridge a
	JOIN actor_title_bridge b
      ON a.show_id = b.show_id
WHERE a.actor > b.actor
GROUP BY 1,2
ORDER BY COUNT(*) DESC;

-- This makes the same determination as above, but limits it to the United States:

SELECT
	a.actor AS actor_A,
    b.actor AS actor_B,
    COUNT(*) AS collaborations
FROM actor_title_bridge a
	JOIN actor_title_bridge b
      ON a.show_id = b.show_id
    LEFT JOIN country_title_bridge c
      ON a.show_id = c.show_id
WHERE a.actor > b.actor
  AND c.country = 'United States'
GROUP BY 1,2
ORDER BY COUNT(*) DESC;

-- This makes the same determination as above, but limits it to the United States *and*, specifically, to movies:

SELECT
	a.actor AS actor_A,
    b.actor AS actor_B,
    COUNT(*) AS collaborations
FROM actor_title_bridge a
	JOIN actor_title_bridge b
      ON a.show_id = b.show_id
    LEFT JOIN netflix_work nw
      ON a.show_id = nw.show_id
WHERE a.actor > b.actor
  AND nw.country LIKE '%United States%'
  AND nw.type = 'Movie'
GROUP BY 1,2
ORDER BY COUNT(*) DESC;

-- This query seeks the same answers as above, but attempts to limit the results to non-sequels/non-franchise films.

SELECT
	a.actor AS actor_A,
    b.actor AS actor_B,
    COUNT(*) AS collaborations
FROM actor_title_bridge a
	JOIN actor_title_bridge b
      ON a.show_id = b.show_id
    LEFT JOIN netflix_work nw
      ON a.show_id = nw.show_id
WHERE a.actor > b.actor

  AND nw.country LIKE '%United States%'
  AND nw.type = 'Movie'

  AND a.title NOT LIKE '%Monster High%'
  AND a.title NOT LIKE '%My Little Pony%'
  AND a.title NOT LIKE '%Twilight%'
  AND a.title NOT LIKE '%Power Rangers%'
  AND a.title NOT LIKE '%Rocky%'
  AND a.title NOT LIKE '%Kung Fu Panda%'
  AND a.title NOT LIKE '%Spy Kids%'
  AND a.title NOT LIKE '%Marvel Super Hero%'
  AND a.title NOT LIKE '%American Tail%'
  AND a.title NOT LIKE '%Karate%'
  AND a.title NOT LIKE '%Underpants%'
  AND a.title NOT LIKE '%Matrix%'
  AND a.title NOT LIKE '%Rogue Warfare%'
  AND a.title NOT LIKE '%To All The Boys%'
  AND a.title NOT LIKE '%Dragons: Rescue Riders%'
  AND a.title NOT LIKE '%Cloudy%'
  AND a.title NOT LIKE '%Christmas Prince%'
  AND a.title NOT LIKE '%House Party%'
  AND a.title NOT LIKE '%Norm of the North%'

  AND a.actor NOT LIKE '%Brosnan%'
GROUP BY 1,2
ORDER BY COUNT(*) DESC;


-- The query below determines which countries have participated in the most co-productions.
-- ("Co-production" is defined as any movie with more than two countries listed in the "country" field.)

WITH collab_country_count_table AS (
	SELECT
		show_id,
		COUNT(country) AS country_count
	FROM country_title_bridge
	GROUP BY show_id
),
country_count_table AS (
	SELECT country,
		   COUNT(*) AS overall_productions
	FROM country_title_bridge
    GROUP BY country
)
SELECT
	csb.country,
    COUNT(*) AS coproductions,
    ROUND(COUNT(*) / MAX(cct.overall_productions),2) AS percent_of_countries_overall_productions
FROM collab_country_count_table ccct
   LEFT JOIN country_title_bridge csb
      ON ccct.show_id = csb.show_id
   LEFT JOIN country_count_table cct
      ON csb.country = cct.country
WHERE ccct.country_count > 1
GROUP BY csb.country
ORDER BY coproductions DESC
LIMIT 10;

/*
The following query makes a similar determination as above, but sorts by the percentage that 
the number of co-productions is of each country's overall output. It also limits the results
to those countries that have more than 100 titles in the datset.
*/

WITH collab_country_count_table AS (
	SELECT
		show_id,
		COUNT(country) AS country_count
	FROM country_title_bridge
	GROUP BY show_id
),
country_count_table AS (
	SELECT country,
		   COUNT(*) AS overall_productions
	FROM country_title_bridge
    GROUP BY country
)
SELECT
	csb.country,
    COUNT(*) AS coproductions,
    ROUND(COUNT(*) / MAX(cct.overall_productions),2) AS percent_of_countries_overall_productions
FROM collab_country_count_table ccct
   LEFT JOIN country_title_bridge csb
      ON ccct.show_id = csb.show_id
   LEFT JOIN country_count_table cct
      ON csb.country = cct.country
WHERE ccct.country_count > 1
  AND cct.overall_productions >= 100
GROUP BY csb.country
ORDER BY percent_of_countries_overall_productions DESC
LIMIT 10;

-- This query determines which actors have most focused in one particular genre:

SELECT
	a.actor,
    g.genre,
    COUNT(*) AS title_count
FROM actor_title_bridge a
	LEFT JOIN netflix_work nw
		ON a.show_id = nw.show_id
	LEFT JOIN genre_title_bridge g
		ON a.show_id = g.show_id
	LEFT JOIN country_title_bridge c
		ON a.show_id = c.show_id
WHERE c.country = 'United States'
  AND nw.type = 'Movie'
GROUP BY a.actor,
		 g.genre
ORDER BY COUNT(*) DESC, actor
LIMIT 10;

/*
This query returns similar results as the query above, but instead bases its
rankings on the respective percentages of each actor's participation in various
genres, and which genre sees their highest participation, percentage-wise. The
results are limited to those actors with at least 5 roles.
*/
WITH US_movie_actor_pool AS (
	SELECT DISTINCT 
        a.actor,
        a.show_id
	FROM actor_title_bridge a
		JOIN country_title_bridge c
			ON a.show_id = c.show_id
		LEFT JOIN netflix_work nw
		    ON a.show_id = nw.show_id
	WHERE c.country = 'United States'
      AND nw.type = 'Movie'
 ),
titles_count AS (
	SELECT
		actor,
        show_id,
		SUM(COUNT(DISTINCT show_id)) OVER(PARTITION BY actor) AS total_titles
	FROM US_movie_actor_pool
	GROUP BY actor, show_id
),
genre_count AS (
	SELECT tc.actor,
           tc.show_id,
           tc.total_titles,
		   g.genre
	--	   COUNT(g.genre)
    FROM titles_count tc
		LEFT JOIN genre_title_bridge g
			ON tc.show_id = g.show_id
)
SELECT actor,
	   genre,
       COUNT(genre),
       SUM(COUNT(genre)) OVER(PARTITION BY actor) AS total_genre_count_per_actor,
       COUNT(genre) / SUM(COUNT(genre)) OVER(PARTITION BY actor) AS percent_genre
FROM genre_count
WHERE total_titles > 4
GROUP BY actor, genre
ORDER BY percent_genre DESC;

-- This query determines the top 10 movie genres (disregarding "international"):

SELECT
	DISTINCT g.genre,
    COUNT(g.title)
FROM genre_title_bridge g
  LEFT JOIN netflix_work n
	 ON g.show_id = n.show_id
WHERE n.type = 'Movie'
GROUP BY g.genre
ORDER BY count(g.title) desc
limit 11;

-- This query determines the various ratings that a production classified as a "movie" can receive:

SELECT DISTINCT
	rating
FROM netflix_work
WHERE type = 'Movie';

-- This query produces a ratings breakdown (i.e., G, PG, PG-13, R, or NC-17) for the 10 most popular genres:

SELECT
	g.genre,
    SUM(CASE WHEN n.rating = 'G' THEN 1 ELSE 0 END) AS G,
    SUM(CASE WHEN n.rating = 'PG' THEN 1 ELSE 0 END) AS PG,
    SUM(CASE WHEN n.rating = 'PG-13' THEN 1 ELSE 0 END) AS 'PG-13',
    SUM(CASE WHEN n.rating = 'R' THEN 1 ELSE 0 END) AS R,
    SUM(CASE WHEN n.rating = 'NC-17' THEN 1 ELSE 0 END) AS 'NC-17',
    SUM(CASE WHEN n.rating = 'NR' THEN 1 ELSE 0 END) AS 'NR',
	SUM(CASE WHEN n.rating = 'UR' THEN 1 ELSE 0 END) AS 'UR',
    SUM(CASE WHEN n.rating NOT IN ('G','PG','PG-13','R','NC-17','NR','UR') THEN 1 ELSE 0 END) AS 'Other rating'
FROM genre_title_bridge g
	LEFT JOIN netflix_work n
		ON g.show_id = n.show_id
WHERE g.genre IN ('Dramas','Comedies','Documentaries','Action & Adventure','Independent Movies','Children & Family Movies','Romantic Movies','Thrillers','Music & Musicals','Horror Movies')
  AND n.type = 'Movie'
GROUP BY g.genre
ORDER BY g.genre;

-- This query investigates what genres of U.S. movie productions received "NR" or "UR" ratings:

WITH unrated_movies AS (
	SELECT show_id
	FROM netflix_work
	WHERE rating = 'NR'
	   OR rating = 'UR'
)
SELECT
	g.genre,
    COUNT(um.show_id) AS genre_count
FROM unrated_movies um
	LEFT JOIN genre_title_bridge g
		ON um.show_id = g.show_id
GROUP BY g.genre
ORDER BY genre_count DESC;