--- Respuestas reto 1 ----

-- Muestra las facturas cuyo total sea mayor a 10.

SELECT 
	invoiceid, 
    total 
FROM 
	Invoice
WHERE 
	total > 10;

-- Lista los clientes que sean de Canada o USA.
SELECT 
	customerid, 
	country
from 
	Customer
where 
	country in ('Canada','USA');

-- Géneros con duración promedio mayor a 4 minutos.
SELECT 
	G.Name,
    t.Milliseconds/60000 as minutes
FROM
 	Track t
JOIN 
	Genre G ON g.GenreId = t.GenreId
WHERE
	minutes > 4;

-- Países cuya venta total supere 100.
SELECT
	billingcountry,
    SUM(total) AS venta_total
FROM
	Invoice
GROUP BY 
	billingcountry
HAVING
	venta_total > 100;
-- Top 3 clientes que más han comprado (por número de facturas).
SELECT
	Customer.customerid,
    COUNT(Invoice.InvoiceId) AS venta_total,
    Customer.FirstName ||' '|| Customer.LastName AS nombre
FROM
	Invoice
JOIN 
	Customer ON Customer.CustomerId = Invoice.CustomerId
GROUP BY 
	billingcountry,
    nombre
ORDER by 
	venta_total DESC 
limit 3;

-- Top 5 canciones más largas.
SELECT 
	Name,
    milliseconds
FROM
	Track
ORDER by 
	milliseconds DESC
LIMIT 5;

-- ¿Cuál es el país con mayor venta total? (solo 1 resultado).
SELECT
	billingcountry,
    SUM(total) AS venta_total
FROM
	Invoice
GROUP BY 
	billingcountry
ORDER by 
	venta_total DESC 
limit 3;
