CREATE DATABASE * music_database

------------------------------------------------------------------------------------------------------------------------

CREATE table album
(
album_id numeric primary key,
tittle varchar,
artist_id numeric
);

CREATE table artist
(
artist_id numeric primary key,
name varchar
);

CREATE table customer
(
customer_id numeric primary key,
first_name varchar,
last_name varchar,
company varchar,
address varchar,
city varchar,
state varchar,
country varchar,
postal_code varchar,
phone varchar,
fax varchar,
email varchar,
support_rep_id numeric
);

CREATE table employee
(
employee_id numeric primary key,
last_name varchar,
first_name varchar,
tittle varchar,
reports_to numeric,
levels varchar,
birthdate date,
hire_date date,
address varchar,
city varchar,
state varchar,
country varchar,
postal_code varchar,
phone varchar,
fax varchar,
email varchar
);

CREATE table genre
(
genre_id numeric primary key,
name varchar
);

CREATE TABLE invoice
(
invoice_id numeric PRIMARY KEY,
customer_id numeric,
invoice_date DATE,
billing_address varchar,
billing_city varchar,
billing_state varchar,
billing_country varchar,
billing_postal varchar,
total numeric(10,2)
);

CREATE TABLE invoice_line
(
invoice_line_id numeric PRIMARY KEY,
invoice_id numeric,
track_id numeric,
unit_price numeric,
quantity numeric
);

CREATE table media_type
(
media_type_id numeric primary key,
name varchar
);

CREATE table playlist
(
playlist_id numeric primary key,
name varchar
);

CREATE table playlist_track
(
playlist_id numeric,
track_id numeric,
primary key (playlist_id, track_id)
);

CREATE TABLE track
(
track_id numeric primary key,
name varchar,
album_id numeric,
media_type_id numeric,
genre_id numeric,
composer varchar,
milliseconds numeric,
bytes numeric,
unit_price numeric
);

---------------------------------------------------------------------------------------------------------------------


-- Q 1 Who is the senior most employee based om job tittle ?

Select * from employee
Order by levels desc
Limit 1

-- Q 2 which country have the most invoices ?

select count(*) as c, billing_country
from invoice 
group by billing_country 
order by c desc

-- Q 3 what are top 3 values of total invoice ?

select total from invoice 
order by total desc 
limit 3

--Q 4 which city has the best customer ? we would like to throw a pramotional music festival in the city we made
-- the most money write a query that return one city which has the highest sum of invoice total ,
-- return both the city name and some of invoice in total.

select SUM(total) as invoice_total, billing_city
from invoice 
group by billing_city
Order by invoice_total desc

-- Q 5 who is the best customer ? The customer who has spent the most money will be declared 
-- as the best customer, write the query that returns the person who has spent the most money.

select customer.customer_id, customer.first_name, customer.last_name, Sum(invoice.total) as total 
from customer
Join invoice
on customer.customer_id = invoice.customer_id
Group by customer.customer_id
order by total desc
limit 1


-- Q 6 Write query that return the emai, first name , last name and genre of all rock music listner ,
-- return your list order alphabetically by email starting with A

Select DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
Join invoice_line ON invoice.invoice_id = invoice_line.invoice_id
where track_id IN(
Select track_id from track
join genre on track.genre_id = genre.genre_id
where genre.name Like 'Rock'
)
order by email;


--Q 7 Let's invite the artist who have written the most rock music in our database , write a query that return
-- the artist name and total track count of the top 10 rock bands

Select artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
Where genre.name LIKE 'Rock'
GROUP by artist.artist_id
order by number_of_songs DESC
LIMIT 10;

-- Q 8 Return all the track names that have a song length longer then the average song length
-- return the name of milliseconds for each track order by the length with the longest songs listed first

select name, milliseconds
from track 
Where milliseconds > (
Select AVG (milliseconds) as avg_track_length
from track)
order by milliseconds DESC;

-- Q 9 Find how much amount spent by each customer on artist ? write a query to return customer name, 
-- artist name and total spent

WITH best_selling_artist AS (
select artist.artist_id AS artist_id, artist.name AS artist_name,
SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
From invoice_line
JOIN track on track.track_id = invoice_line.track_id
JOIN album on album.album_id = track.album_id
JOIN artist on artist.artist_id = album.artist_id
GROUP by 1
Order by 3 DESC
Limit 1
)

Select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c on c.customer_id = i.customer_id
JOIN invoice_line il on il.invoice_id = i.invoice_id
JOIN track t on t.track_id = il.track_id
JOIN album alb on alb.album_id = t.album_id
JOIN best_selling_artist bsa on bsa.artist_id = alb.artist_id
GROUP by 1,2,3,4
Order by 5 DESC;

-- Q 10 We want to find out the most popular music genre for each country we determine the most popular genre as
-- the genre with the highest amount of purchase write a query that returns each country along with the top 
-- genre for countries where the maximum number of purchased is shared return to all genre.

WITH popular_genre as 
(
 Select count (invoice_line.quantity) as purchases, customer.country, genre.name,  genre.genre_id,
 ROW_NUMBER() OVER(Partition by customer.country order by count (invoice_line.quantity) desc) as RowNo
 from invoice_line
 Join invoice on invoice.invoice_id = invoice_line.invoice_id
 Join customer on customer.customer_id = invoice.customer_id
 Join track on track.track_id = invoice_line.track_id
 Join genre on genre.genre_id = track.genre_id
 Group by 2,3,4
 Order by 2 ASC, 1 Desc
 
)

Select * From popular_genre Where RowNo <= 1

-- 2nd method

WITH RECURSIVE 
sales_per_country as (

 Select count (*) as purchases_per_genre, customer.country, genre.name,  genre.genre_id
 FROM invoice_line
 Join invoice on invoice.invoice_id = invoice_line.invoice_id
 Join customer on customer.customer_id = invoice.customer_id
 Join track on track.track_id = invoice_line.track_id
 Join genre on genre.genre_id = track.genre_id
 Group by 2,3,4
 Order by 2
 ),
 max_genre_per_country as (select max(purchases_per_genre) AS max_genre_number, country
 From sales_per_country
 Group by 2
 order by 2)

Select sales_per_country.* 
From sales_per_country
Join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
Where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number

-- Q 11 Write a quesry that determines the customer that has spent the most on each country, 
-- write a query that returns the country along with the top customer and how much they spent.
-- for countries where the top amount spent is shared, Provide all customer who spent this amount.

WITH RECURSIVE 
customer_with_country AS (
select customer.customer_id, first_name, last_name, billing_country,
SUM (total) as total_spending
from invoice
join customer 
on customer.customer_id = invoice.customer_id
group by 1,2,3,4
Order by 2,3 DESC),

country_max_spending AS (
select billing_country,
MAX (total_spending) AS max_spending
FROM customer_with_country
Group by billing_country)

select cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
from customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER by 1;

-- Method 2

WITH customer_with_country AS (
Select customer.customer_id, first_name, last_name, billing_country,
SUM (total) as total_spending,
ROW_NUMBER () OVER (PARTITION BY billing_country ORDER BY SUM(total) DESC ) AS RowNo
FROM invoice
JOIN customer
ON customer.customer_id = invoice.customer_id
group by 1,2,3,4
Order by 4 ASC, 5 DESC)

SELECT * FROM customer_with_country 
WHERE RowNo <= 1




  
