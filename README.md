## Cleaning-and-Preparing-a-Netflix_Dataset-project
This project is a data exploration and cleaning case study, undertaken to gain experience with the hygienic and normalizing functions of SQL and PowerQuery. This report will recount the process of preparing a Kaggle Netflix dataset for analysis, along with the performance of a small set of analytical experiments.

### Findings

Working with this dataset offered valuable educational exposure to certain less-than-ideal realities of data handling (such as bumpy importing processes and stubbornly persistent hidden characters). As well, the analyses presented here offered welcome insight into not only the importance of establishing clear definitions and parameters, but also the many challenges that one can encounter when trying to make those determinations.

### Tools used

PowerQuery was used to create bridge (junction) tables to normalize fields in the original dataset that contained multiple comma-separated items.

SQL was used to clean and prepare the data, as well as to perform a number of exploratory analyses on the above-mentioned bridge tables.

### Data import

*Shivam Bansal • Netflix Movies and TV Shows dataset*

[https://www.kaggle.com/datasets/shivamb/netflix-shows/](https://www.kaggle.com/datasets/shivamb/netflix-shows/)

Repeated efforts to employ MySQL Workbench’s Table Data Import Wizard came to grief. I was likewise stymied when I tried to import the CSV using a `LOAD DATA LOCAL INFILE` from within MySQL. Ultimately, I executed the statement via MySQL’s command-line client from the cmd terminal.

Before getting underway, I created a working version of the dataset, netflix_work, in order to preserve the original.

### Initial data examination

I began by running a `DESCRIBE` query to confirm that the columns had successfully imported in the desired formats.

### Format corrections / Duplicate search

Because fields in the original CSV’s date_added column were written in the “March 30, 2026” style, it was necessary to import them in the `VARCHAR` format. I then employed a `STR_TO_DATE` function to convert them to MySQL’s preferred orientation:
```sql
UPDATE netflix_work
SET date_added = STR_TO_DATE(date_added, '%M %d, %Y');
```
An inspection of a sampling from the dataset suggested that capitalization was a non-issue.

I also ran a query to confirm that the dataset did not contain duplicate rows.

### Empty cells

The dataset clearly had numerous empty cells: They were apparent at a glance. I ran a query to determine the extent of the NULLs. (Query abridged in the example given below.)
```sql
SELECT
  COUNT(*)                     AS total_rows,
  COUNT(show_id)               AS non_null_show_id,
     COUNT(*) - COUNT(show_id) AS missing_show_id,
  COUNT(type)                  AS non_null_type,
     COUNT(*) - COUNT(type)    AS missing_type,
…
FROM netflix_work;
```
The results indicated that — while there were indeed hundreds of empty strings contained among netflix_work’s approximately 8,800 rows — there were in fact zero NULLs.

It is my understanding that, while there is not a universally agreed-upon best practice in such instances, a good argument can be made for the superior analytical firepower of NULLs as compared to empty strings. Accordingly, I opted to convert the empty cells to NULLs. (Query below abridged.)
```sql
UPDATE netflix_work
SET
  show_id = NULLIF(show_id, ''),
  type = NULLIF(type, ''),
  title = NULLIF(title, ''),
  director = NULLIF(director, '') …
```
### NULLs

I then re-ran the “NULL count” query. Most notable among the results was that three categories — director, cast, and country — had significant percentages of NULLs.

The Netflix dataset is a mix of two categories in the `type` column: “Movie” and “TV show.” The significant percentage of NULLs in the director column was largely explained by there being no such listing for entries classified as TV shows.

Of the remaining instances, they were largely ephemera — such as comedy specials and “making-of”s — that were classified in the dataset as movies (despite not fitting any conventional definition of that term).

In the case of the many NULL occurrences in the cast field, these were a mix of documentaries, docuseries, reality TV programs, crime TV programs, and international movies and TV shows. (International movies and TV shows were not as well-documented in this area as were their domestic counterparts.)

These repeated oversights — in the cast listings for international movies and TV shows — carried over to the country field, the lion’s share of whose NULL values were also in those same two “abroad” categories.

​Cleanliness checks
I ran a query on each column to check if its fields were hiding any leading or trailing spaces. Happily, these tests found them free of any such stowaways.

SELECT column1
FROM dataset_clean
WHERE column1 <> TRIM(column1);

Having determined this, I decided — taking into consideration that this was a well-known public dataset and that the likely risk was low — it would be unnecessary to perform further searches for hidden and/or non-printing characters.

(Ironically enough, although this assumption about the original data would appear to have been correct, hidden characters would end up being introduced into the dataset later in the process: See “Hidden characters,” below.)

While reviewing the various columns to ensure that each contained the expected type of data, I discovered a small error in the original dataset: a smattering of titles whose running time was listed in the rating field, instead of duration.

To correct this, I ran the following corrective query (which took advantage of the fact that movie duration fields contained the abbreviation “min” for minutes):

UPDATE netflix_work
SET duration = rating,
    rating = NULL
WHERE rating LIKE '%min%';

​(As for TV shows, their duration fields listed number of seasons.)

​Building bridge tables
Four columns — most extensively the cast and listed_in columns, but also those for director and country — included cells that contained multiple names or identifiers separated by commas.

Fields in the cast column, of course, contained actors’ names, while those in the listed_in column contained the various possible classifications or genres that might identify the movie or TV show in questions (“drama,” “comedy,” “reality TV,” “crime TV,” etc.)

In order to simplify potential future analyses, I used PowerQuery to create a separate table based on each of these columns. In these “bridge,” or junction, tables, I broke the comma-separated names into individual rows so that — in the newly-created cast table, for example — the granularity would be one distinct row per actor/movie combination.

PowerQuery process
To create these tables, I imported the original dataset into PowerQuery. I then transformed the column in question by splitting it by the comma delimiter — specifically, splitting it into rows — in order to create the desired one-row-per-actor-title-combination result.

To eliminate the white spaces that carried over from the field contents’ original comma-separated state, I selected the newly reformatted column and applied Transform -> Format -> Trim.

I then deleted those columns not needed for a junction-style table. Each of these newly created tables, then, contained a show_id column (i.e., the original table’s primary key); a column for the movie/TV show title; and a column for the now-separated items.

(E.g., where the column name was cast in the original dataset, it became an individuated actor column in the newly created table. What was once listed_in was now genre, etc.)

For readability’s sake, I retained the movie/TV show title, although technically the primary-key show_id would be sufficient identification: In a larger dataset where size was a concern, the title could be eliminated.

Import into SQL
I then loaded the results to Excel and exported each as a separate CSV file: actor_title_bridge, genre_title_bridge, director_title_bridge, and country_title_bridge. These then were imported into MySQL Workbench.

Review of these newly created tables revealed a handful of extra, garbled rows that resulted from an errant paragraph return in one of the dataset’s title entries. These unnecessary rows — in which misplaced text made its way into the show_id field — were eliminated.

DELETE FROM actor_movie_bridge
WHERE show_id LIKE '%Flying Fortress';

A note on normalization, granularity, and potential duplicates
These bridge/junction tables are not fully normalized. For one, they contain redundancies, in that TV show/movie titles were retained for the sake of readability. (Although, as noted earlier, those titles could be removed without affecting the tables’ functionality.)

More to the point, full normalization would require the creation of primary-key IDs for each of the tables along with separate junction tables to connect each to the main table’s show_id.

(In a fully normalized system, for example, the actor table would consist solely of distinct actor names and a unique actor_id assigned to each. In turn, the main table would not contain a cast or actor column: Instead, a separate actor <-> title table would exist that would sync show_ids and actor_ids according to each actor’s various appearances.)

That said, the bridge tables created for this project will simplify various analyses that would focus specifically on their subjects — say, actors or genres. This would make it unnecessary, for example — in the event that one were using solely the original dataset — to employ criteria that would have to search within multi-item fields using wildcards.

However, because these tables contain many-to-many relationships, any analysis that employs them must emphasize the potential for duplications in their counts. For example, whereas the main table encompasses approximately 8,800 individual titles, a listing of genre types along with a count for how many titles are classified in each genre adds up to over twice that amount.

Hidden characters
As noted above, cast and listed_in were the two columns most conspicuously in need of bridge tables — virtually every field in these columns contained numerous comma-separated items. I therefore created those tables first and then experimented with some various “test run” queries on the results.

In that process, I discovered a curious behavior: Any effort to filter according to a specific actor’s name was producing zero results.

Suspecting hidden characters, I ran the following query and discovered that, yes, every field’s orig_length exceeded its potential cleaned_length by 1:

SELECT DISTINCT actor,
       LENGTH(actor)                                       AS orig_length,
       LENGTH(REPLACE(REPLACE(actor, '\r', ''), '\n', '')) AS cleaned_length
FROM actor_title_bridge
ORDER BY actor;

A follow-up query would narrow the culprit down to a carriage return — i.e., \r — that appeared at the end of every field’s contents in the newly created column.

In response to this, I cleaned both my newly created actor_title_bridge and genre_title_bridge tables:

UPDATE actor_title_bridge
SET actor = REPLACE(actor, '\r', '');

Concluding that the carriage returns were most likely an unintended side-effect of the column-splitting performed in PowerQuery, I attempted to “nip the problem in the bud,” as it were, with the subsequent bridge tables that I created.

I would discover, however, that all attempts to eliminate these hidden characters at the source, i.e., within the PowerQuery or Excel environment, would come to naught.

Such efforts as running “Trim” and/or “Clean” from PowerQuery’s Transform -> Format menu were not sufficient to eliminate the carriage returns, nor were the TRIM() and/or CLEAN() functions any more effective when applied to the data once loaded to Excel.

Similarly, efforts to replace or substitute the hidden characters with an empty string — whether performed in PowerQuery or in Excel — could not eradicate them: Inevitably, they would appear in the table once imported to SQL.

Although I had hoped that these could be eliminated earlier in the process, I accepted that they could only be removed within SQL, itself, and accordingly applied the aforementioned cleaning query to the director_title_bridge and country_title_bridge tables, as well.

Bridge table analyses
Having created the bridge tables, I wanted to experiment with putting them to use, both with internal comparisons and in conjunction with one another.

Actor collaborations
One potentially interesting use to which an actor_title_bridge table can be put is employing a self join to determine which actors have most frequently collaborated with one another.

The actual execution of this analysis, though, casts an illustrative light on the various sorts of judgment calls that can be necessary to glean valuable insight from potentially “noisy” results.

For example: In an effort to make the results of such a query more focused, one might specify the content type be “movies” (as distinct from TV shows, which are also included in the dataset).

And if one were attempting to make the results more relevant to, say, a primarily American audience, one might also specify the country of production be “United States.”

But even with such guardrails in place, the “top collaborators” results might seem oddly overpopulated with certain recurring — and largely unfamiliar — names. Take the “Top 10,” for instance:
