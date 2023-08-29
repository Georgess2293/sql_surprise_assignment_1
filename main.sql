-- Create a dimension table for customers.

CREATE TABLE IF NOT EXISTS reporting_schema.customers_dimension(
customer_id INT PRIMARY KEY,
first_name TEXT,
last_name TEXT
);

INSERT INTO reporting_schema.customers_dimension
SELECT 
    se_customer.customer_id,
    se_customer.first_name,
    se_customer.last_name
FROM public.customer AS se_customer

--Create a fact table for rentals

CREATE TABLE IF NOT EXISTS reporting_schema.rentals_fact(
rentals_id INT,
customer_id INT REFERENCES reporting_schema.customers_dimension(customer_id),
rental_date DATE,
return_date DATE,
rental_fee NUMERIC
);

WITH CTE_RENTALS AS(
SELECT
	se_rental.rental_id,
	se_rental.customer_id,
	CAST(se_rental.rental_date AS DATE),
	CAST(se_rental.return_date AS DATE),
	COALESCE(se_payment.amount,0) AS rental_fee
FROM public.rental AS se_rental
LEFT OUTER JOIN public.payment AS se_payment
ON se_rental.rental_id=se_payment.rental_id
	)

INSERT INTO reporting_schema.rentals_fact
SELECT * FROM CTE_RENTALS

--create agg table for customer_id

WITH CTE_CUSTOMERS_AGG AS(
SELECT
	se_customer.customer_id,
	COALESCE(COUNT(se_rental.rental_id),0) AS total_movies_rented,
	COALESCE(SUM(se_payment.amount),0) AS total_paid,
	COALESCE(ROUND(AVG(se_film.rental_duration),2),0) AS average_rental_duration
FROM public.customer AS se_customer
LEFT OUTER JOIN public.payment AS se_payment
ON se_customer.customer_id=se_payment.customer_id
LEFT OUTER JOIN public.rental AS se_rental
ON se_payment.rental_id=se_rental.rental_id
LEFT OUTER JOIN public.inventory AS se_inventory
ON se_rental.inventory_id=se_inventory.inventory_id
LEFT OUTER JOIN public.film AS se_film
ON se_inventory.film_id=se_film.film_id
GROUP BY se_customer.customer_id
)

INSERT INTO reporting_schema.customer_agg
SELECT * FROM CTE_CUSTOMERS_AGG