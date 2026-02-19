-- Chinook (SQLite) - Reto final
-- Nota: Estas consultas asumen el esquema estándar de Chinook:
-- Customer, Invoice, InvoiceLine, Track, Album.
-- (SQLite >= 3.25 recomendado para funciones de ventana)

--------------------------------------------------------------------------------
-- 1) Identificar cuáles son los clientes que más han gastado históricamente
--    y determinar su ranking dentro de cada país.
--------------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        i.BillingCountry AS country,
        c.CustomerId     AS customer_id,
        c.FirstName || ' ' || c.LastName AS customer_name,
        SUM(i.Total)     AS total_spent
    FROM Invoice i
    JOIN Customer c
      ON c.CustomerId = i.CustomerId
    GROUP BY i.BillingCountry, c.CustomerId
)
SELECT
    country,
    customer_id,
    customer_name,
    total_spent,
    DENSE_RANK() OVER (
        PARTITION BY country
        ORDER BY total_spent DESC
    ) AS spend_rank_in_country
FROM customer_spend
ORDER BY country, spend_rank_in_country, customer_name;

--------------------------------------------------------------------------------
-- 2) Detectar qué álbumes tienen un precio promedio por canción superior
--    al promedio general de toda la tienda (catálogo).
--    (Promedio por canción = AVG(Track.UnitPrice) dentro del álbum)
--------------------------------------------------------------------------------
SELECT 
    a.AlbumId,
    a.Title,
    AVG(t.UnitPrice) AS AlbumAvgPrice
FROM Album a
JOIN Track t 
    ON a.AlbumId = t.AlbumId
GROUP BY a.AlbumId
HAVING AVG(t.UnitPrice) > (
    SELECT AVG(UnitPrice) FROM Track
);

--------------------------------------------------------------------------------
-- 3) Determinar qué álbumes pueden considerarse “premium” al tener un precio
--    promedio por pista mayor que el promedio global y calcular la diferencia.
--------------------------------------------------------------------------------
SELECT 
    a.AlbumId,
    a.Title,
    AVG(t.UnitPrice) AS AlbumAvgPrice
FROM Album a
JOIN Track t 
    ON a.AlbumId = t.AlbumId
GROUP BY a.AlbumId
HAVING AVG(t.UnitPrice) > (
    SELECT AVG(UnitPrice) FROM Track
);
--------------------------------------------------------------------------------
-- 4) Identificar clientes cuya segunda compra haya sido al menos 30% menor que
--    su primera compra (segunda <= 70% de la primera).
--------------------------------------------------------------------------------
-- Clientes cuya segunda compra fue al menos 30% menor que la primera

WITH ordered_invoices AS (
    SELECT
        CustomerId,
        InvoiceDate,
        Total,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerId
            ORDER BY InvoiceDate
        ) AS rn
    FROM Invoice
),

first_second AS (
    SELECT
        CustomerId,
        MAX(CASE WHEN rn = 1 THEN Total END) AS first_purchase,
        MAX(CASE WHEN rn = 2 THEN Total END) AS second_purchase
    FROM ordered_invoices
    WHERE rn IN (1, 2)
    GROUP BY CustomerId
)

SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS CustomerName,
    fs.first_purchase,
    fs.second_purchase
FROM first_second fs
JOIN Customer c 
    ON c.CustomerId = fs.CustomerId
WHERE fs.second_purchase <= fs.first_purchase * 0.7;

--------------------------------------------------------------------------------
-- 5) Obtener el Top 3 de canciones con mayores ingresos generados en cada país,
--    incluyendo su ranking dentro del país.
--    (Ingresos = SUM(InvoiceLine.UnitPrice * Quantity))
--------------------------------------------------------------------------------
-- Top 3 canciones con mayores ingresos en cada país

WITH track_revenue AS (
    SELECT 
        i.BillingCountry,
        t.TrackId,
        t.Name AS TrackName,
        SUM(il.UnitPrice * il.Quantity) AS Revenue
    FROM Invoice i
    JOIN InvoiceLine il 
        ON i.InvoiceId = il.InvoiceId
    JOIN Track t 
        ON il.TrackId = t.TrackId
    GROUP BY i.BillingCountry, t.TrackId
),

ranked_tracks AS (
    SELECT
        BillingCountry,
        TrackId,
        TrackName,
        Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY BillingCountry
            ORDER BY Revenue DESC
        ) AS Ranking
    FROM track_revenue
)

SELECT *
FROM ranked_tracks
WHERE Ranking <= 3
ORDER BY BillingCountry, Ranking;

--------------------------------------------------------------------------------
-- 6) Determinar qué clientes conforman el grupo que acumula ~80% de los ingresos
--    dentro de cada país (concentración tipo Pareto).
--    Incluye el cliente que cruza el umbral del 80%.
--------------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        i.BillingCountry AS country,
        c.CustomerId AS customer_id,
        c.FirstName || ' ' || c.LastName AS customer_name,
        SUM(i.Total) AS total_spent
    FROM Invoice i
    JOIN Customer c
      ON c.CustomerId = i.CustomerId
    GROUP BY i.BillingCountry, c.CustomerId
),
country_totals AS (
    SELECT country, SUM(total_spent) AS country_total
    FROM customer_spend
    GROUP BY country
),
ranked AS (
    SELECT
        cs.country,
        cs.customer_id,
        cs.customer_name,
        cs.total_spent,
        ct.country_total,
        SUM(cs.total_spent) OVER (
            PARTITION BY cs.country
            ORDER BY cs.total_spent DESC, cs.customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_spent
    FROM customer_spend cs
    JOIN country_totals ct
      ON ct.country = cs.country
),
with_pct AS (
    SELECT
        country,
        customer_id,
        customer_name,
        total_spent,
        country_total,
        cum_spent,
        (cum_spent * 1.0 / country_total) AS cum_pct,
        LAG(cum_spent * 1.0 / country_total) OVER (
            PARTITION BY country
            ORDER BY total_spent DESC, customer_id
        ) AS prev_cum_pct
    FROM ranked
)
SELECT
    country,
    customer_id,
    customer_name,
    total_spent,
    country_total,
    cum_spent,
    ROUND(cum_pct, 4) AS cumulative_pct_of_country_revenue
FROM with_pct
WHERE cum_pct <= 0.80
   OR (prev_cum_pct < 0.80 AND cum_pct > 0.80)
ORDER BY country, total_spent DESC, customer_name;
