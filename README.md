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
3. ¿Cuál es la duración promedio de las canciones (`Milliseconds`) en minutos (un minuto son 6000 milisegundos)?  

---

## 2️⃣ CAST y tipos de datos

### 📖 Teoría
A veces queremos cambiar el tipo de dato:  
- **SQLite** → `CAST(expr AS TYPE)`  
- **PostgreSQL** → `expr::TYPE` o `CAST(expr AS TYPE)`  
- **MySQL** → `CAST(expr AS TYPE)`

#### 📊 Tipos de datos comunes en MySQL, PostgreSQL y SQLite

| Categoría   | MySQL              | PostgreSQL        | SQLite (afinidades) |
|-------------|--------------------|-------------------|----------------------|
| Números enteros | INT, BIGINT       | INTEGER, BIGINT   | INTEGER |
| Decimales   | DECIMAL, FLOAT, DOUBLE | NUMERIC, REAL, DOUBLE PRECISION | REAL, NUMERIC |
| Texto       | VARCHAR(n), TEXT   | VARCHAR(n), TEXT  | TEXT |
| Booleanos   | BOOLEAN (en realidad 0/1) | BOOLEAN (TRUE/FALSE) | INTEGER (0 = falso, 1 = verdadero) |
| Fechas      | DATE, DATETIME, TIMESTAMP | DATE, TIMESTAMP | TEXT o INTEGER (según formato) |

---

✅ **Notas rápidas para la clase:**
- En **SQLite** casi todo se guarda como `TEXT`, `INTEGER`, `REAL` o `BLOB`.  
- **MySQL** y **Postgres** sí distinguen más tipos.  
- El `BOOLEAN` en SQLite no existe de forma nativa, se maneja como `0/1`.  

### 💻 Ejemplo
```sql
SELECT Total, 
       CAST(Total AS INTEGER) AS TotalEntero
FROM Invoice
LIMIT 5;
```
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
1. ¿Cuáles son las 5 canciones más largas del compositor 'Jerry Cantrell'?

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
1. ¿Cuál es el "gasto total" (aquí representado con la suma de CustomerId) agrupado por ciudad y nombre del cliente, y quiénes aparecen con los valores más altos?

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
1. ¿Cuántos clientes hay en cada ciudad? 

---

## 6️⃣ Fechas: EXTRACT y DATE_TRUNC

### 📖 Teoría

El manejo de fechas depende del motor de base de datos.  
En este curso veremos **SQLite** y **PostgreSQL**.

---

### 🟦 SQLite → `strftime`

- No tiene tipo de fecha/hora nativo.  
- Se usa `strftime(format, fecha)` para extraer partes.
📌 Formatos comunes:
%Y = Año, %m = Mes, %d = Día, %H = Hora, %M = Minuto

```sql
-- Año de la factura
SELECT strftime('%Y', InvoiceDate) AS Anio, COUNT(*) 
FROM Invoice
GROUP BY Anio;
```
### 🟪 PostgreSQL → EXTRACT y DATE_TRUNC
- Maneja DATE/TIMESTAMP nativos.
   - EXTRACT devuelve valores numéricos.
   - DATE_TRUNC “recorta” fechas a año, mes, etc.

 ```sql
-- Año de la factura
SELECT EXTRACT(YEAR FROM InvoiceDate) AS Anio, COUNT(*) 
FROM Invoice
GROUP BY Anio;

-- Truncar a mes
SELECT DATE_TRUNC('month', InvoiceDate) AS Mes, COUNT(*) 
FROM Invoice
GROUP BY Mes;
```

### ❓ Preguntas
1. ¿Cuántas facturas se emitieron por año?  
2. Agrupa las facturas por mes.  


---

## 8️⃣ Funciones de ventana

### 📖 Teoría
Las funciones de ventana permiten realizar cálculos sobre un conjunto de filas **relacionadas** sin necesidad de agrupar y perder el detalle de cada fila (a diferencia de `GROUP BY`).  

👉 Se definen con la cláusula `OVER()`, que puede incluir:  
- `PARTITION BY` → divide los datos en grupos.  
- `ORDER BY` → define un orden dentro del grupo.  

```sql
-- Muestra la suma acumulada y el porcentaje del total de compras por cliente
SELECT 
    CustomerId,
    InvoiceId,
    Total,
    SUM(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS Acumulado,
    -- Porcentaje del total de compras de cada cliente
    100.0 * SUM(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)
           / SUM(Total) OVER (PARTITION BY CustomerId) AS PorcentajeDelTotal
FROM Invoice
ORDER BY PorcentajeDelTotal; 
```

## 7️⃣ Subconsultas

### 📖 Teoría
Una consulta dentro de otra. Muy útil para preguntas encadenadas.  

### 💻 Ejemplo
```sql
--Encuentra los artistas que tienen un álbum con “Greatest Hits”.
SELECT Name
FROM Artist
WHERE ArtistId IN (
    SELECT ArtistId
    FROM Album
    WHERE Title LIKE '%Greatest Hits%'
);
```

### ❓ Preguntas 
1. ¿Qué canciones pertenecen a los álbumes del artista “Queen”?  

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
-- Une clientes con sus facturas y muestra el total.
SELECT c.FirstName, c.LastName, i.Total
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
ORDER BY i.Total DESC
LIMIT 5;
```

### ❓ Preguntas  
1. Muestra las canciones junto con el nombre de su álbum y artista.  

---

## 🏁 Ejercicio Final

¡Hora del reto final! 🔥  

### ❓ Preguntas
- ¿Cuáles son los clientes que más han gastado, y cuál es su ranking dentro de cada país?
- ¿Qué álbumes tienen un precio promedio de pista mayor que el promedio general?

---

✨ ¡Y listo! Ya tienes tu toolkit de consultas SQL para practicar con SQL🚀  
