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
1. ¿Cuál es la duración promedio de las canciones (`Milliseconds`) en minutos (un minuto son 60000 milisegundos)?  

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
1. ¿Cuantos clientes hay por ciudad? Ordenar de mayor a menor

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

---
## RETO FINAL DE LA PRIMERA PARTE:
- Muestra las facturas cuyo total sea mayor a 10.
- Lista los clientes que sean de Canada o USA.
- Géneros con duración promedio mayor a 4 minutos.
- Países cuya venta total supere 100.
- Top 3 clientes que más han comprado (por número de facturas).
- Top 5 canciones más largas.
- ¿Cuál es el país con mayor venta total? (solo 1 resultado).

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
1. Agrupa las facturas por mes.

---
### 🔀 CASE en SQL

La sentencia CASE permite agregar lógica condicional dentro de una consulta SQL.
Es equivalente a un if / else en programación.

### Estructura básica
```sql
CASE
    WHEN condición THEN resultado
    WHEN condición THEN resultado
    ELSE resultado
END
```

### Ejemplo: 
```sql
SELECT
    InvoiceId,
    Total,
    CASE
        WHEN Total >= 15 THEN 'Alto'
        WHEN Total >= 5 THEN 'Medio'
        ELSE 'Bajo'
    END AS NivelDeCompra
FROM Invoice;

```

### ❓ Preguntas
1. El equipo comercial quiere entender mejor el comportamiento de compra. Necesitan que clasifiques cada factura como “Alta”, “Media” o “Baja” dependiendo del monto pagado, para luego analizar qué tipo de ventas predominan en el negocio.

## 8️⃣ Funciones de ventana

### 📖 Teoría
Las funciones de ventana permiten realizar cálculos sobre un conjunto de filas **relacionadas** sin necesidad de agrupar y perder el detalle de cada fila (a diferencia de `GROUP BY`).  

👉 Se definen con la cláusula `OVER()`, que puede incluir:  
- `PARTITION BY` → divide los datos en grupos.  
- `ORDER BY` → define un orden dentro del grupo.  

| Categoría                  | Función                | ¿Qué hace?                             | ¿Cuándo usarla?                                    | Ejemplo                                                              |
| -------------------------- | ---------------------- | -------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------- |
| **Ranking**                | `ROW_NUMBER()`         | Asigna un número único secuencial      | Cuando no quieres empates                          | `ROW_NUMBER() OVER (ORDER BY Total DESC)`                            |
|                            | `RANK()`               | Ranking con empates (salta posiciones) | Cuando los empates deben reflejar competencia real | `RANK() OVER (ORDER BY Total DESC)`                                  |
|                            | `DENSE_RANK()`         | Ranking con empates (sin saltos)       | Cuando quieres ranking compacto                    | `DENSE_RANK() OVER (ORDER BY Total DESC)`                            |
| **Agregación**             | `SUM()`                | Suma dentro de la ventana              | Totales por grupo sin colapsar filas               | `SUM(Total) OVER (PARTITION BY Country)`                             |
|                            | `AVG()`                | Promedio dentro de la ventana          | Comparar con promedio del grupo                    | `AVG(Total) OVER (PARTITION BY Country)`                             |
|                            | `COUNT()`              | Conteo dentro de la ventana            | Contar filas por grupo                             | `COUNT(*) OVER (PARTITION BY Country)`                               |
|                            | `MIN()` / `MAX()`      | Valor mínimo o máximo del grupo        | Detectar extremos dentro del grupo                 | `MAX(Total) OVER (PARTITION BY Country)`                             |
| **Acumulado**              | `SUM()` con `ORDER BY` | Suma acumulada progresiva              | Running totals                                     | `SUM(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)`     |
| **Navegación**             | `LAG()`                | Accede a la fila anterior              | Comparaciones temporales                           | `LAG(Total) OVER (ORDER BY InvoiceDate)`                             |
|                            | `LEAD()`               | Accede a la fila siguiente             | Comparaciones futuras                              | `LEAD(Total) OVER (ORDER BY InvoiceDate)`                            |
| **Distribución**           | `NTILE(n)`             | Divide en n grupos                     | Cuartiles / percentiles simples                    | `NTILE(4) OVER (ORDER BY Total DESC)`                                |
| **Valor dentro del grupo** | `FIRST_VALUE()`        | Primer valor de la ventana             | Obtener el mayor o menor dentro del grupo          | `FIRST_VALUE(Total) OVER (PARTITION BY Country ORDER BY Total DESC)` |
|                            | `LAST_VALUE()`         | Último valor de la ventana             | Comparar contra el menor del grupo                 | `LAST_VALUE(Total) OVER (PARTITION BY Country ORDER BY Total)`       |


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
### ❓ Preguntas 
1. El área de retención quiere saber si los clientes están aumentando o disminuyendo su gasto con el tiempo. Para cada compra de un cliente, necesitan ver cuánto gastó en su compra anterior y determinar si su consumo está subiendo, bajando o manteniéndose estable.


## 7️⃣ Subconsultas - CTE

### 📖 Teoría
Una CTE es una consulta temporal que se define antes del SELECT principal usando la palabra clave WITH.

Permite dividir una consulta compleja en pasos más claros y legibles.

### Estructura
```sql
WITH nombre_cte AS (
    SELECT ...
)
SELECT ...
FROM nombre_cte;
```

### 💻 Ejemplo simple
```sql
WITH total_por_cliente AS (
    SELECT
        CustomerId,
        SUM(Total) AS TotalSpent
    FROM Invoice
    GROUP BY CustomerId
)

SELECT *
FROM total_por_cliente
ORDER BY TotalSpent DESC;
```

### 💻 Ejemplo encadenado
```sql
WITH paso1 AS (...),
     paso2 AS (...)
SELECT ...
FROM paso2;
```
### ❓ Preguntas 
1. ¿Qué canciones pertenecen a los álbumes del artista “Queen”?  
---

## 🏁 Ejercicio Final

¡Hora del reto final! 🔥  

### ❓ Preguntas
- ¿Cuáles son los clientes que más han gastado, y cuál es su ranking dentro de cada país?
- ¿Qué álbumes tienen un precio promedio de pista mayor que el promedio general?
- El área de producto quiere evaluar si ciertos álbumes están posicionados como “premium”. Necesitan identificar cuáles álbumes tienen un precio promedio por canción superior al promedio general de toda la tienda.

---

✨ ¡Y listo! Ya tienes tu toolkit de consultas SQL para practicar con SQL🚀  
