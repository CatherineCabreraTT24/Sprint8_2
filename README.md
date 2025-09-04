# 🎶 SQL - Todo lo que necesitas saber

El día de hoy practicaremos SQL usando la base de datos **Chinook** 🎧  
Piensa en **Chinook** como una tienda de música tipo *iTunes* o *Spotify viejo*:  
- Tiene **clientes**, **facturas**, **álbumes**, **artistas**, **canciones** 🎵  
- Perfecta para aprender a consultar datos con SQL 🚀  

---

## 🗂️ Orden de ejecución en SQL

Imagina SQL como una receta de cocina 👩‍🍳: primero eliges los ingredientes, luego los filtras, después agrupas y al final los sirves.  

| Cláusula            | Función                                                                      |
| ------------------- | ---------------------------------------------------------------------------- |
| `WITH`              | Define CTEs para organizar subconsultas reutilizables.    OPCIONAL           |
| `SELECT [DISTINCT] [COUNT] [AGG_FUNCTIONS]` | Elige columnas/expresiones. `DISTINCT` elimina duplicados del **resultado**. `COUNT` Cuenta los valores del resultado. `AFF_FUNCTIONS` Son una serie de funciones para hacer cálculos (se explican más abajo)  |
| `FROM`              | Tabla (o subconsulta) base.                                                  |
| `JOIN ... ON ...`   | Une tablas relacionadas (uno o varios `JOIN`).                               |
| `WHERE`             | Filtra **filas** antes de agrupar. No ve alias del `SELECT`.                 |
| `GROUP BY`          | Agrupa para aplicar agregaciones (`SUM`, `AVG`, ...).                        |
| `HAVING`            | Filtra **grupos** ya agregados.                                              |
| `ORDER BY`          | Ordena el conjunto final (sí puede usar alias del `SELECT`).                 |
| `LIMIT`             | Número máximo de filas a devolver.                                           |
| `OFFSET`            | Salta las primeras `m` filas del resultado.                                  |


---

## 1️⃣ Funciones de agregación y operaciones

### 📖 Teoría
Sirven para **resumir datos**:  
- `SUM()` suma 💰  
- `AVG()` promedio 📏  
- `MAX()` máximo ⛰️  
- `MIN()` mínimo 🐜  
- `COUNT()` cuenta filas 🔢  

### 💻 Ejemplo
```sql
SELECT COUNT(*) AS TotalFacturas,
       AVG(Total) AS Promedio,
       MAX(Total) AS MayorFactura
FROM Invoice;
```

### ❓ Preguntas
1. ¿Cuántos clientes existen en la tabla `Customer`?  
2. ¿Cuál es el valor total de todas las facturas?  
3. ¿Cuál es la duración promedio de las canciones (`Milliseconds`) en minutos?  

---

## 2️⃣ CAST y tipos de datos

### 📖 Teoría
A veces queremos cambiar el tipo de dato:  
- **SQLite** → `CAST(expr AS TYPE)`  
- **PostgreSQL** → `expr::TYPE` o `CAST(expr AS TYPE)`  
- **MySQL** → `CAST(expr AS TYPE)`  

### 💻 Ejemplo
```sql
SELECT Total, 
       CAST(Total AS INTEGER) AS TotalEntero
FROM Invoice
LIMIT 5;
```

### ❓ Preguntas
1. Convierte la columna `Milliseconds` de la tabla `Track` a minutos enteros.  
2. ¿Qué diferencia hay entre `CAST` en SQLite y `::` en PostgreSQL?  

---

## 3️⃣ GROUP BY

### 📖 Teoría
Agrupa filas según una o más columnas. Ideal para **resúmenes**.  

### 💻 Ejemplo
```sql
SELECT BillingCountry, COUNT(*) AS NumFacturas
FROM Invoice
GROUP BY BillingCountry;
```

### ❓ Preguntas
1. Muestra cuántas facturas se hicieron por cada país.  
2. Agrupa las ventas por país y año de la factura.  

---

## 4️⃣ ORDER BY y LIMIT

### 📖 Teoría
- `ORDER BY` ordena (`ASC` / `DESC`)  
- `LIMIT` muestra un número de filas  

### 💻 Ejemplo
```sql
SELECT Name, Milliseconds/60000.0 AS DuracionMin
FROM Track
ORDER BY DuracionMin DESC
LIMIT 5;
```

### ❓ Preguntas
1. ¿Cuáles son las 5 canciones más largas?  
2. Lista los 3 clientes con mayores compras totales.  

---

## 5️⃣ HAVING vs WHERE

### 📖 Teoría
- `WHERE` → filtra filas ANTES de agrupar 🚪  
- `HAVING` → filtra grupos DESPUÉS de agrupar 🧐  

### 💻 Ejemplo
```sql
-- WHERE
SELECT *
FROM Invoice
WHERE BillingCountry = 'USA';

-- HAVING
SELECT BillingCountry, COUNT(*) AS NumFacturas
FROM Invoice
GROUP BY BillingCountry
HAVING COUNT(*) > 10;
```

### ❓ Preguntas
1. ¿Qué países tienen más de 10 facturas?  
2. Encuentra las facturas mayores a 15 en USA.  

---

## 6️⃣ Fechas: EXTRACT y DATE_TRUNC

### 📖 Teoría
- **SQLite** → `strftime`  
- **PostgreSQL** → `EXTRACT` y `DATE_TRUNC`  

### 💻 Ejemplo
```sql
-- Año de cada factura en SQLite
SELECT strftime('%Y', InvoiceDate) AS Anio, COUNT(*)
FROM Invoice
GROUP BY Anio;
```

### ❓ Preguntas
1. ¿Cuántas facturas se emitieron por año?  
2. Agrupa las facturas por mes.  

---

## 7️⃣ Subconsultas

### 📖 Teoría
Una consulta dentro de otra. Muy útil para preguntas encadenadas.  

### 💻 Ejemplo
```sql
SELECT Name
FROM Artist
WHERE ArtistId IN (
    SELECT ArtistId
    FROM Album
    WHERE Title LIKE '%Greatest Hits%'
);
```

### ❓ Preguntas
1. Encuentra los artistas que tienen un álbum con “Greatest Hits”.  
2. ¿Qué canciones pertenecen a los álbumes del artista “Queen”?  

---

## 8️⃣ Funciones de ventana

### 📖 Teoría
Permiten cálculos sobre un conjunto de filas relacionadas **sin agrupar**.  

### 💻 Ejemplo
```sql
SELECT CustomerId,
       Total,
       SUM(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS Acumulado
FROM Invoice;
```

### ❓ Preguntas
1. Muestra la suma acumulada de compras por cliente.  
2. Asigna un número de fila (`ROW_NUMBER`) a cada factura.  

---

## 9️⃣ JOINs

### 📖 Teoría
Sirven para unir tablas:  
- `INNER JOIN` → solo coincidencias  
- `LEFT JOIN` → todo lo de la izquierda + coincidencias  
- `RIGHT JOIN` → todo lo de la derecha + coincidencias (no en SQLite)  
- `FULL JOIN` → todo (no directo en SQLite)  

### 💻 Ejemplo
```sql
SELECT c.FirstName, c.LastName, i.Total
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
ORDER BY i.Total DESC
LIMIT 5;
```

### ❓ Preguntas
1. Une clientes con sus facturas y muestra el total.  
2. Muestra las canciones junto con el nombre de su álbum y artista.  

---

## 🏁 Ejercicio Final

¡Hora del reto final! 🔥  

```sql
SELECT a.Name AS Artista,
       COUNT(t.TrackId) AS NumCanciones,
       SUM(il.UnitPrice * il.Quantity) AS IngresosTotales
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist a ON al.ArtistId = a.ArtistId
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
WHERE strftime('%Y', i.InvoiceDate) = '2010'
GROUP BY a.Name
HAVING IngresosTotales > 20
ORDER BY IngresosTotales DESC
LIMIT 5;
```

### ❓ Pregunta
- ¿Cuáles son los 5 artistas más vendidos en 2010 con ingresos mayores a 20?  

---

✨ ¡Y listo! Ya tienes tu toolkit de consultas SQL para practicar con Chinook 🚀  
