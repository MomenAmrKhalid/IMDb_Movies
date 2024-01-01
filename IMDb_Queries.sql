USE Box_Office

-- 1 Top 3 profitable writers with their movie
 
SELECT 
     TOP(3) CONCAT(w.Writer_Fname , w.Writer_Lname ) AS Writer_Name,
     SUM(f.Gross_Million - f.Budget_Million) AS Total_Profit, 
     v.Movie_name

FROM 
     writer w 
JOIN 
     movie_writer m ON w.Writer_ID = m.Writer_ID
JOIN 
     movie v ON m.Movie_ID = v.Movie_id
JOIN 
     finance f ON f.Finance_ID = v.Finance_ID
GROUP BY 
     w.Writer_ID, w.Writer_Fname ,w.Writer_Lname ,v.Movie_name
ORDER BY 
     Total_Profit DESC

----------------------------------------------------------------------------------------------
-- 2 The most actors nationalities which participated in action movies

SELECT 
     TOP(1) COUNT(n.Nationality_ID) AS Nationality_count, 
     n.Nationality_Name 

FROM 
     nationality n 
JOIN 
     actor a ON  n.Nationality_ID = a.Nat_ID
JOIN 
     movie_actor m ON a.Actor_ID = m.Actor_ID
JOIN 
     movie e ON m.Movie_ID = e.Movie_id
WHERE 
     e.Genre ='Action'
GROUP BY 
     n.Nationality_ID , n.Nationality_Name 
ORDER BY 
     Nationality_count DESC

----------------------------------------------------------------------------------------------
-- 3 number of movies for each actor and the total avg revenue  

SELECT 
     CONCAT(a.Actor_Fname, ' ' , a.Actor_Lname)  AS Full_Name,
     COUNT(mo.Actor_ID) AS NumMoviesPerActor,
     AVG(Gross_Million-Budget_Million) AS Avg_Reveneu

FROM 
     movie_actor mo 
JOIN 
     actor a ON mo.Actor_ID = a.Actor_ID 
JOIN 
     movie m ON m.Movie_id = mo.Movie_ID 
JOIN 
     finance f ON f.Finance_ID = m.Finance_ID 
GROUP BY 
     CONCAT(a.Actor_Fname, ' ' , a.Actor_Lname)
ORDER BY 
     NumMoviesPerActor DESC

----------------------------------------------------------------------------------------------
-- 4 Count the movie for range of time

CREATE OR ALTER PROC 
     mv_count (@year1 INT , @year2 INT)  AS 

SELECT  
     COUNT(Movie_id ) AS Num_Of_Movies, 
	 AVG(rating) AS Avg_Rating 
FROM 
     movie
WHERE 
     [Release year] BETWEEN @year1 AND @year2

EXEC mv_count 2010, 2019

----------------------------------------------------------------------------------------------
-- 5 This stored procedure retrieves the top N actors or directors based on the number of movies they've worked on.

CREATE OR ALTER PROC 
     GetTopMovieCountPerRole
     @roleType NVARCHAR(50), -- 'Actor' or 'Director'
     @topCount INT
AS
BEGIN
    IF @roleType = 'Actor'
    BEGIN
        SELECT 
		     TOP (@topCount) a.Actor_ID, a.Actor_Fname, a.Actor_Lname, 
			 COUNT(ma.Movie_ID) AS Movie_Count
         FROM 
		     actor a
         LEFT JOIN 
		     movie_actor ma ON a.Actor_ID = ma.Actor_ID
        GROUP BY 
		     a.Actor_ID, a.Actor_Fname, a.Actor_Lname
        ORDER BY 
		     Movie_Count DESC;
    END
    ELSE IF @roleType = 'Director'
    BEGIN
        SELECT 
		     TOP (@topCount) d.Direct_ID, d.Direct_Fname, d.Direct_Lname,
			 COUNT(md.Movie_ID) AS Movie_Count
        FROM 
		     director d
        LEFT JOIN 
		     movie_director md ON d.Direct_ID = md.Direct_ID
        GROUP BY 
		     d.Direct_ID, d.Direct_Fname, d.Direct_Lname
        ORDER BY 
		     Movie_Count DESC
    END
END

EXEC GetTopMovieCountPerRole @roleType = 'actor', @topCount = 5

----------------------------------------------------------------------------------------------
--- 6 This procedure recommends movies based on a specified genre and rating range

CREATE OR ALTER PROC 
    GetMovieRecommendations
    @movieGenre NVARCHAR(50),
    @minRating INT,
    @maxRating INT
AS
BEGIN
    SELECT Movie_id, Movie_name, Summary, [Release year], [Run_time(minute)], Rating
    FROM movie
    WHERE Genre = @movieGenre AND Rating BETWEEN @minRating AND @maxRating
END

EXEC GetMovieRecommendations @movieGenre= 'Comedy', @minRating = 7, @maxRating = 9

----------------------------------------------------------------------------------------------
--7--this query finds the actors and their number of movies and the most dominant genre in these movies.
go
CREATE OR Alter VIEW 
     ActorFilmCountView AS
SELECT 
     TOP 100 PERCENT 
     a.Actor_ID,
     a.Actor_Fname,
     a.Actor_Lname,
     COUNT(ma.Movie_ID) AS NumberOfFilms
FROM 
     Actor a
JOIN 
     Movie_actor ma ON a.Actor_ID = ma.Actor_ID
GROUP BY 
     a.Actor_ID, a.Actor_Fname, a.Actor_Lname
go
CREATE OR Alter VIEW 
     TopActorGenresView AS
SELECT 
     afc.Actor_ID,
     m.Genre AS GenreName,
     COUNT(*) AS GenreCount
FROM 
     ActorFilmCountView afc
JOIN 
     Movie_actor ma ON afc.Actor_ID = ma.Actor_ID
JOIN 
     Movie m ON ma.Movie_ID = m.Movie_id

GROUP BY 
    afc.Actor_ID, m.Genre
go
SELECT 
     CONCAT(Actor_Fname, Actor_Lname) AS ActorName,
     GenreName AS Genre, subquery.NumberOfFilms
	
FROM (
     SELECT TOP 100 Percent
        afc.Actor_ID,
        afc.Actor_Fname,
        afc.Actor_Lname,
        t.GenreName,
        ROW_NUMBER() OVER (PARTITION BY afc.Actor_ID ORDER BY afc.NumberOfFilms ) AS rn ,
		NumberOfFilms
     FROM 
        ActorFilmCountView afc
     JOIN 
        TopActorGenresView t ON afc.Actor_ID = t.Actor_ID
	ORDER BY 
	    NumberOfFilms DESC) AS subquery
WHERE 
     rn = 1
ORDER BY 
     NumberOfFilms DESC

----------------------------------------------------------------------------------------------
-- 8 the actor that gets the greatest profit

SELECT 
    TOP (1) CONCAT(Actor_Fname , Actor_Lname ) AS ActorName, 
    SUM(Gross_Million - Budget_Million) AS [TotalProfit (Millions)]
FROM 
    Actor
JOIN 
    Movie_actor ON Actor.Actor_ID = Movie_actor.Actor_ID
JOIN 
    Movie ON Movie_actor.Movie_ID = Movie.movie_id
JOIN 
    Finance ON Movie.Finance_ID = Finance.Finance_ID
GROUP BY 
    Actor.Actor_ID, Actor_Fname, Actor_Lname
ORDER BY 
    [TotalProfit (Millions)] DESC

----------------------------------------------------------------------------------------------
-- 9 duo actor and director who get the greates profit 

CREATE OR ALTER  PROC 
     top_DIRECT_ACTOR (@num INT) AS

SELECT 
     TOP (@num)  Actor_Fname + ' ' + Actor_Lname AS [Actor Name] ,
     direct_fname + ' ' + direct_lname AS [Director Name],
     SUM (f.Gross_Million - f.Budget_Million) AS [profit]
FROM  
    actor a 
JOIN 
    movie_actor ma ON a.Actor_ID = ma.Actor_ID 
JOIN
    movie m ON ma.Movie_ID = m.Movie_id 
JOIN 
    movie_director md  ON m.Movie_id = md.Movie_ID 
JOIN 
    director d ON md.Direct_ID = d.Direct_ID 
JOIN 
    finance f ON m.Finance_ID = f.Finance_ID 

GROUP BY 
    Actor_Fname + ' ' + Actor_Lname, direct_fname + ' ' + direct_lname 
ORDER BY 
    profit DESC

EXEC top_DIRECT_ACTOR 5

----------------------------------------------------------------------------------------------
-- 10 top 3 making profit Genres.

SELECT   
     TOP(3)  genre, 
     SUM (f.Gross_Million - f.Budget_Million) AS [Profit of Genre] 
FROM 
     movie m 
JOIN 
     finance f ON m.Finance_ID = f.Finance_ID 
GROUP BY 
     Genre 
ORDER BY 
     SUM (f.Gross_Million - f.Budget_Million) DESC

----------------------------------------------------------------------------------------------
 -- 11 Calculate the avg run_time per each genre

SELECT 
     Genre,
     AVG([Run_time(minute)]) AS Avg_Runtime,
     AVG(Rating) AS Avg_Genre_Rating,
CASE
     WHEN AVG(Rating) > 7 THEN 'HIGH'
     ELSE 'LOW'
     END AS Rating_Classification
FROM 
     movie 
GROUP BY 
     Genre
ORDER BY 
     Avg_Runtime DESC

----------------------------------------------------------------------------------------------
 -- 12 number of movies for each actor and the total avg revenue  

SELECT 
     (a.Actor_Fname+a.Actor_Lname)  AS Full_Name,
     COUNT(mo.Actor_ID) AS NumMoviesPerActor,
     AVG(Gross_Million-Budget_Million) AS Avg_Reveneu
FROM 
     movie_actor mo 
JOIN 
     actor a ON mo.Actor_ID = a.Actor_ID 
JOIN 
     movie m ON m.Movie_id = mo.Movie_ID 
JOIN 
     finance f ON f.Finance_ID = m.Finance_ID 
GROUP BY 
     a.Actor_Fname+a.Actor_Lname 
ORDER BY 
     NumMoviesPerActor DESC


----------------------------------------------------------------------------------------------
-- 13 This stored procedure retrieves the number of movies for a specific genre and year.

CREATE OR ALTER PROC 
     Movies_By_Genre_and_year (@genre_param VARCHAR(255), @year_param INT )AS
BEGIN

SELECT 
     COUNT(Movie_id) AS Num_of_Movies_Per_Year
FROM 
     movie 
WHERE 
     Genre = @genre_param AND [Release year] = @year_param;
END

EXEC Movies_By_Genre_and_year 'Drama' , 2009

----------------------------------------------------------------------------------------------
-- 14 This stored procedure finds the movie with the highest budget and profit within a specific genre.

CREATE or ALTER PROC 
     Highest_profit_Movie_for_Genre (@genre_param VARCHAR(255)) AS 

BEGIN

    SELECT  
	     TOP 1 movie_name,genre, 
		 MAX(gross_million - budget_million) AS Profit 
    FROM 
	     movie m 
	JOIN 
	     finance f ON m.Finance_ID = f.Finance_ID
    WHERE 
	     genre = @genre_param
	GROUP BY 
	     Genre , Movie_name
    ORDER BY 
	     Profit desc  
END

EXEC Highest_profit_Movie_for_Genre 'Action'


----------------------------------------------------------------------------------------------
-- 15 --top 3 making profit Genres.

SELECT  
     TOP 3  genre, 
	 SUM (f.Gross_Million - f.Budget_Million) AS [Profit of Genre]
	 
FROM 
     movie m 
JOIN 
     finance f ON m.Finance_ID = f.Finance_ID 
GROUP BY 
     Genre 
ORDER BY 
     SUM (f.Gross_Million - f.Budget_Million) DESC 


----------------------------------------------------------------------------------------------
-- 16 Calculate the avg run_time per each genre  

SELECT 
     Genre,AVG([Run_time(minute)]) AS Avg_Runtime,
	 AVG(Rating) AS Avg_Genre_Rating,
     CASE
         WHEN AVG(Rating) > 7 THEN 'HIGH'
         ELSE 'LOW'
         END AS Rating_Classification
FROM 
     movie 
GROUP BY 
     Genre
ORDER BY 
     Avg_Runtime DESC


----------------------------------------------------------------------------------------------
-- 17 This trigger prevents the deletion of records from the director entity table if there are associated movies in the movie_director table. 

CREATE OR ALTER TRIGGER 
     PreventDirectorDeletion
ON 
     director
INSTEAD OF DELETE
  AS
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM 
		     deleted d
        JOIN 
		     movie_director md ON d.Direct_ID = md.Direct_ID
    )
    BEGIN
        PRINT ('Deletion failed. Directors associated with movies cannot be deleted')
        ROLLBACK TRANSACTION
    END
    ELSE
    BEGIN
        DELETE FROM director
        WHERE Direct_ID IN (SELECT Direct_ID FROM deleted)
    END
END


----------------------------------------------------------------------------------------------
-- 18 This trigger prevents the insertion of new records in the actor table if the first and last name of the actor already exists

CREATE OR ALTER TRIGGER 
     PreventDuplicateActor
ON 
     actor
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM 
		     inserted i
        JOIN 
		     actor a ON i.Actor_Fname = a.Actor_Fname AND i.Actor_Lname = a.Actor_Lname
    )
    BEGIN
        PRINT ('Insertion failed. Actor with the same first name and last name already exists')
        ROLLBACK TRANSACTION
    END
    ELSE
    BEGIN
        INSERT INTO actor (Actor_Fname, Actor_Lname, Actor_BD, Nat_ID)
        SELECT Actor_Fname, Actor_Lname, Actor_BD, Nat_ID
        FROM inserted
    END
END


----------------------------------------------------------------------------------------------
-- 19 create view top_profitable_Director as

SELECT 
     TOP(3) CONCAT(d.Direct_Fname , d.Direct_Lname ) AS Director_Name,
     SUM (f.Gross_Million - f.Budget_Million) AS Total_Profit,
     v.Movie_name
FROM 
     director d 
JOIN 
     movie_director m ON d.Direct_ID = m.Direct_ID
JOIN 
     movie v ON m.Movie_ID = v.Movie_id
JOIN 
     finance f ON f.Finance_ID = v.Finance_ID
GROUP BY 
     d.Direct_ID, d.Direct_Fname ,d.Direct_Lname ,v.Movie_name
ORDER BY 
     Total_Profit DESC



----------------------------------------------------------------------------------------------
--- 20 The most actors nationalities who participated in a specific genre movies

CREATE OR ALTER PROC 
     most_actor_nationality (@gen VARCHAR(50))  AS
BEGIN
     IF EXISTS ( SELECT m.Genre FROM movie m WHERE m.Genre = @gen )
	     BEGIN
            SELECT 
			     TOP (1) COUNT(n.Nationality_ID) AS Nationality_count, 
				 n.Nationality_Name 
            FROM 
			     nationality n 
			JOIN 
			     actor a ON  n.Nationality_ID = a.Nat_ID
            JOIN 
			     movie_actor m ON a.Actor_ID = m.Actor_ID
            JOIN 
			     movie e ON m.Movie_ID = e.Movie_id
            WHERE 
			     e.Genre =@gen
            GROUP BY 
			     n.Nationality_ID , n.Nationality_Name 
            ORDER BY 
			     Nationality_count DESC
	    END
    ELSE 
       BEGIN
	        PRINT 'the genre is not exist' 
	   END
END

EXEC most_actor_nationality @gen = 'Adventure'


----------------------------------------------------------------------------------------------
-- 21 writers who have high rated movies (rating > 8) and the number of those movies

SELECT 
     we.Writer_ID, we.Writer_Fname, we.Writer_Lname,
	 COUNT(mw.Movie_ID) AS High_Rated_Movies
FROM 
     writer we
JOIN 
     movie_writer mw ON we.Writer_ID = mw.Writer_ID
JOIN 
     movie me ON mw.Movie_ID = me.Movie_id
WHERE 
     me.Rating > 8
GROUP BY 
     we.Writer_ID, we.Writer_Fname, we.Writer_Lname

--END--