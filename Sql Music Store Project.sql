
/* ✅ Music Store Analysis Project Using SQL  
 This SQL project explores a music store database to answer real business questions.
I wrote 15+ queries using JOINs, CTEs, and window functions to extract deep insights.
From customer spending to genre trends, every query connects data to decisions. */


--Tables Data Query for Understanding the Data.

SELECT * FROM customer ; 
SELECT * FROM track ; 
SELECT * FROM genre ; 
SELECT * FROM invoice ; 
SELECT * FROM invoice_line ; 
SELECT * FROM media_type ; 
SELECT * FROM playlist ; 
SELECT * FROM album ; 
SELECT * FROM employee ; 
SELECT * FROM artist ; 
SELECT * FROM invoice ; 
SELECT * FROM playlist_track ; 


-- Who is Senior Most employee based on Job Title 

SELECT * from employee
ORDER BY levels desc
LIMIT 1

-- which Country has Most invoices

SELECT * from invoice

SELECT COUNT(*) as c , billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c desc 


-- what are top three values of total  invoice.
SELECT total from invoice
ORDER BY total desc
lIMIT 3 


/* Problem : which city has the best customers ? we would like to throw a Promotioanl music festival in the city we made the most money.
-- write a query that returns one city that has the highest sum of total invoice totals.
-- Return Both city name and sum of all invoice total. */


SELECT SUM(total) as invoice_total  , billing_city 
from invoice
GROUP BY billing_city 
ORDER by invoice_total desc


/* Problem : who is the best customer . the customer who spend the most money will be declared best customer , write query that returns the 
 person  who has spend the most money.
 Here we need Help for schema bcs we dont enought in one table. */


SELECT customer.customer_id , customer.first_name  , customer.last_name , SUM(invoice.total) as total
FROM customer
JOIN invoice 
ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total desc
limit 1 ;



/* Problem  : write query  to return the email  , first_name , last_name , genre , of all Rock Music listners , 
-- Return your list order Aplphabetically by email starting  with A  */

SELECT DISTINCT email, first_name , last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id 
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id 
WHERE track_id IN (
SELECT track_id from  track 
JOIN genre ON track.genre_id = genre.genre_id 
WHERE genre.name LIKE 'Rock' 
)
ORDER BY email  ; 


/* Problem  Another way to deal to make it more efficient
-- You avoid the subquery.
-- It’s clearer to read because you directly follow the table relationships.
-- choose as per efficiency */

SELECT DISTINCT c.email, c.first_name, c.last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY c.email;


--This is more readable and often more efficient in SQL engines : 

SELECT DISTINCT c.email , c.first_name , c.last_name 
FROM customer c 
JOIN invoice i ON c.customer_id = i.customer_id 
JOIN invoice_line il on i.invoice_id = il.invoice_id 
JOIN track t ON il.track_id = t.track_id 
JOIN genre g ON t.genre_id = g.genre_id 
WHERE g.name LIKE 'Rock'
ORDER BY c.email ; 



/* Problem  Let's invite the artists who written the most Rock music in our dataset . Write query that returns 
-- the Artist name and Total track count of the TOP 10 ROCK bands */

SELECT a.artist_id ,  a.name , COUNT(a.artist_id) AS no_of_songs
FROM artist a 
JOIN album al ON a.artist_id = al.artist_id 
JOIN track t ON al.album_id = t.album_id 
JOIN genre g ON t.genre_id = g.genre_id 
WHERE g.name LIKE 'Rock' 
GROUP BY a.artist_id 
ORDER BY no_of_songs DESC
LIMIT 10 ; 


/* Problem  : Return all the track names that have song length longer than the average song length . 
--Return the name and Milliseconds for each track 
--Order by the song length with the longest songs listed first */


SELECT t.name , t.milliseconds 
FROM track t
WHERE milliseconds > ( 

SELECT AVG(milliseconds) AS avg_song_length
FROM track 
) ORDER BY milliseconds DESC ; 




/*Problem : Find how much amount spent by each customer on artists? Write a query to return customer name,
artist name and total spent */


WITH best_selling_artist AS (

SELECT artist.artist_id AS artist_id  , artist.name AS artist_name , 
SUM( invoice_line.unit_price * invoice_line.quantity) AS total_sales
FROM invoice_line

JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 1 
ORDER BY 3 DESC 
LIMIT 1 
)


SELECT c.customer_id , c.first_name , c.last_name , bsa.artist_name ,
SUM(il.unit_price*il.quantity)  AS amount_spent 
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id 
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id 
JOIN album al ON al.album_id  = t.album_id 
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id 
GROUP BY 1 ,2,3,4 
ORDER BY 5 DESC ; 


/*Problem: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */




WITH popular_genre AS (
SELECT COUNT(invoice_line.quantity) AS purchases , customer.country , genre.name , genre.genre_id ,
ROW_NUMBER() OVER( PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC ) AS RowNo
FROM invoice_line 
JOIN invoice ON  invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN track ON track.track_id = invoice_line.track_id 
JOIN genre ON genre.genre_id = track.genre_id 
GROUP BY 2,3,4
ORDER BY 2 ASC , 1 DESC )

SELECT * FROM popular_genre WHERE RowNo <=1 ; 




/*Problem Method 2 : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;



/* Problem: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

  -- Solution 

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1




/* ✅ Completed an end-to-end SQL project using real-world music store data.
   📊 Wrote advanced queries with JOINs, CTEs, subqueries & window functions.
   🔍 Solved business problems like top customers, genre trends, and revenue insights.
   💡 Learned how to turn raw data into meaningful business decisions. */

