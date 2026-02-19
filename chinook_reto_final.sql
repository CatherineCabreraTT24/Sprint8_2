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
WITH global_avg AS (
    SELECT AVG(UnitPrice) AS avg_unit_price_global
    FROM Track
),
album_avg AS (
    SELECT
        a.AlbumId   AS album_id,
        a.Title     AS album_title,
        AVG(t.UnitPrice) AS avg_unit_price_album,
        COUNT(*)    AS track_count
    FROM Album a
    JOIN Track t
      ON t.AlbumId = a.AlbumId
    GROUP BY a.AlbumId, a.Title
)
SELECT
    aa.album_id,
    aa.album_title,
    aa.track_count,
    aa.avg_unit_price_album,
    ga.avg_unit_price_global
FROM album_avg aa
CROSS JOIN global_avg ga
WHERE aa.avg_unit_price_album > ga.avg_unit_price_global
ORDER BY (aa.avg_unit_price_album - ga.avg_unit_price_global) DESC, aa.album_title;

--------------------------------------------------------------------------------
-- 3) Determinar qué álbumes pueden considerarse “premium” al tener un precio
--    promedio por pista mayor que el promedio global y calcular la diferencia.
--------------------------------------------------------------------------------
WITH global_avg AS (
    SELECT AVG(UnitPrice) AS avg_unit_price_global
    FROM Track
),
album_avg AS (
    SELECT
        a.AlbumId   AS album_id,
        a.Title     AS album_title,
        AVG(t.UnitPrice) AS avg_unit_price_album,
        COUNT(*)    AS track_count
    FROM Album a
    JOIN Track t
      ON t.AlbumId = a.AlbumId
    GROUP BY a.AlbumId, a.Title
)
SELECT
    aa.album_id,
    aa.album_title,
    aa.track_count,
    aa.avg_unit_price_album,
    ga.avg_unit_price_global,
    (aa.avg_unit_price_album - ga.avg_unit_price_global) AS premium_delta
FROM album_avg aa
CROSS JOIN global_avg ga
WHERE aa.avg_unit_price_album > ga.avg_unit_price_global
ORDER BY premium_delta DESC, aa.album_title;

--------------------------------------------------------------------------------
-- 4) Identificar clientes cuya segunda compra haya sido al menos 30% menor que
--    su primera compra (segunda <= 70% de la primera).
--------------------------------------------------------------------------------
WITH ordered_invoices AS (
    SELECT
        i.CustomerId,
        i.InvoiceId,
        i.InvoiceDate,
        i.Total,
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerId
            ORDER BY i.InvoiceDate, i.InvoiceId
        ) AS rn
    FROM Invoice i
),
first_second AS (
    SELECT
        CustomerId,
        MAX(CASE WHEN rn = 1 THEN Total END) AS first_purchase_total,
        MAX(CASE WHEN rn = 2 THEN Total END) AS second_purchase_total
    FROM ordered_invoices
    WHERE rn IN (1,2)
    GROUP BY CustomerId
)
SELECT
    c.CustomerId AS customer_id,
    c.FirstName || ' ' || c.LastName AS customer_name,
    c.Country AS customer_country,
    fs.first_purchase_total,
    fs.second_purchase_total,
    ROUND((fs.second_purchase_total / fs.first_purchase_total) - 1.0, 4) AS pct_change_second_vs_first
FROM first_second fs
JOIN Customer c
  ON c.CustomerId = fs.CustomerId
WHERE fs.first_purchase_total IS NOT NULL
  AND fs.second_purchase_total IS NOT NULL
  AND fs.second_purchase_total <= fs.first_purchase_total * 0.70
ORDER BY pct_change_second_vs_first ASC, customer_name;

--------------------------------------------------------------------------------
-- 5) Obtener el Top 3 de canciones con mayores ingresos generados en cada país,
--    incluyendo su ranking dentro del país.
--    (Ingresos = SUM(InvoiceLine.UnitPrice * Quantity))
--------------------------------------------------------------------------------
WITH track_revenue AS (
    SELECT
        i.BillingCountry AS country,
        t.TrackId        AS track_id,
        t.Name           AS track_name,
        SUM(il.UnitPrice * il.Quantity) AS revenue
    FROM Invoice i
    JOIN InvoiceLine il
      ON il.InvoiceId = i.InvoiceId
    JOIN Track t
      ON t.TrackId = il.TrackId
    GROUP BY i.BillingCountry, t.TrackId, t.Name
),
ranked AS (
    SELECT
        country,
        track_id,
        track_name,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY country
            ORDER BY revenue DESC
        ) AS revenue_rank_in_country
    FROM track_revenue
)
SELECT
    country,
    track_id,
    track_name,
    revenue,
    revenue_rank_in_country
FROM ranked
WHERE revenue_rank_in_country <= 3
ORDER BY country, revenue_rank_in_country, track_name;

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
