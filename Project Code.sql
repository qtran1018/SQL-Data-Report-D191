
CREATE TABLE detailed (
    film_id integer,
    title varchar(255),
    release_year integer,
    rating mpaa_rating,
    movie_count bigint,
    movie_language text
);
------------------------------------------------------------
CREATE TABLE summary (
    title varchar(255),
    movie_count_text text,
    rating mpaa_rating
);
------------------------------------------------------------
CREATE TRIGGER update_detailed
    AFTER INSERT ON detailed
    FOR EACH STATEMENT
    EXECUTE PROCEDURE update_summary();

------------------------------------------------------------
CREATE FUNCTION update_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
 
DELETE FROM summary;
INSERT INTO summary (
    SELECT title,
	CASE
		WHEN movie_count >= 0 AND movie_count < 10
			THEN '0 to 9'
		WHEN movie_count >= 10 AND movie_count < 20
			THEN '10 to 19'	
		WHEN movie_count >= 20 AND movie_count < 30
			THEN '20 to 29'	
		WHEN movie_count >= 30
			THEN 'Over 30'
	END AS movie_count_text,
	rating
    FROM detailed
    GROUP BY movie_count, title, rating
    ORDER BY movie_count DESC
);
RETURN NEW;
END; $$

------------------------------------------------------------
CREATE PROCEDURE refresh_tables ()
    LANGUAGE plpgsql AS $$
    
    BEGIN
    DELETE FROM detailed;
    INSERT INTO detailed (
    SELECT f.film_id, f.title, f.release_year, f.rating, COUNT(f.title) AS movie_count,
        CASE
	        WHEN f.language_id = '1'
	        THEN 'English'
	        ELSE 'we do not rent non-english movies'
	    END AS movie_language
   
    FROM rental AS r
    INNER JOIN inventory AS i
        ON i.inventory_id = r.inventory_id
    INNER JOIN public.film AS f
        ON f.film_id = i.film_id
    WHERE r.return_date IS NOT NULL 
    GROUP BY f.title, f.rating, f.release_year, f.film_id
    ORDER BY movie_count DESC
    );

    END; $$
------------------------------------------------------------

SELECT f.film_id, f.title, f.length, f.release_year, f.replacement_cost, f.rating, COUNT(f.title) AS movie_count, f.special_features,
CASE
	WHEN f.language_id = '1'
	THEN 'English'
	ELSE 'we do not rent non-english movies'
	END AS movie_language
FROM rental AS r
INNER JOIN inventory AS i
    ON i.inventory_id = r.inventory_id
INNER JOIN public.film AS f
    ON f.film_id = i.film_id
WHERE r.return_date IS NOT NULL 
GROUP BY f.title, f.rating, f.release_year, f.film_id
ORDER BY movie_count DESC
------------------------------------------------------------


ORDER OF EVENTS
Scheduler calls PROCEDURE, does inserts, updates the detailed table
PROCEDURE triggers the trigger, update_summary


SOURCES:
https://www.postgresqltutorial.com/postgresql-plpgsql/postgresql-create-procedure/
https://www.postgresqltutorial.com/postgresql-triggers/
https://www.postgresqltutorial.com/postgresql-triggers/creating-first-trigger-postgresql/
https://www.w3schools.com/sql/sql_insert.asp
https://www.w3schools.com/sql/sql_create_table.asp

“PostgreSQL Create Procedure.” PostgreSQL Tutorial, https://www.postgresqltutorial.com/postgresql-plpgsql/postgresql-create-procedure/. 
“PostgreSQL Create Trigger.” PostgreSQL Tutorial, https://www.postgresqltutorial.com/postgresql-triggers/creating-first-trigger-postgresql/. 
“PostgreSQL Triggers.” PostgreSQL Tutorial, https://www.postgresqltutorial.com/postgresql-triggers/. 
“The SQL CREATE TABLE Statement.” SQL Create Table Statement, https://www.w3schools.com/sql/sql_create_table.asp. 
“The SQL INSERT INTO Statement.” SQL Insert into Statement, https://www.w3schools.com/sql/sql_insert.asp. 