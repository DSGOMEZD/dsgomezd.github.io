-- ================================================================
-- REPASO 2 - SQL AVANZADO
-- Repaso con ejercicios que fui pidiendo a una IA para practicar,
-- en vez de quedarme solo con la teoria de como funciona cada tema.
-- CTE, analiticas, ranking, ventanas, jerarquias, MERGE, PIVOT,
-- LISTAGG y subconsultas avanzadas.
-- ================================================================

-- 1. CTE SIMPLE
WITH salarios AS (
    SELECT department_id,
           AVG(salary) promedio
    FROM hr.employees
    GROUP BY department_id
)
SELECT *
FROM salarios
WHERE promedio > 8000;

-- 2. CTE + AGREGACION
WITH ventas AS (
    SELECT pr.id_categoria,
           pr.id_producto,
           pr.nombre,
           SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
    JOIN producto pr ON pr.id_producto = d.id_producto
    WHERE p.fecha_pedido >= DATE '2026-01-01'
      AND p.fecha_pedido < DATE '2027-01-01'
      AND p.estado <> 'ANULADO'
    GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
)
SELECT *
FROM ventas;

-- 3. ROW_NUMBER / RANK / DENSE_RANK
WITH ventas AS (
    SELECT pr.id_categoria, pr.id_producto, pr.nombre,
           SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
    JOIN producto pr ON pr.id_producto = d.id_producto
    WHERE p.estado <> 'ANULADO'
    GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
)
SELECT id_categoria,
       nombre,
       facturado,
       ROW_NUMBER() OVER (
         PARTITION BY id_categoria ORDER BY facturado DESC
       ) AS row_num,
       RANK() OVER (
         PARTITION BY id_categoria ORDER BY facturado DESC
       ) AS ranking,
       DENSE_RANK() OVER (
         PARTITION BY id_categoria ORDER BY facturado DESC
       ) AS dense_ranking
FROM ventas;

-- 4. TOP 3 POR GRUPO
WITH ventas AS (
    SELECT pr.id_categoria, pr.id_producto, pr.nombre,
           SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
    JOIN producto pr ON pr.id_producto = d.id_producto
    WHERE p.estado <> 'ANULADO'
    GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
),
ranking AS (
    SELECT v.*,
           ROW_NUMBER() OVER (
             PARTITION BY id_categoria
             ORDER BY facturado DESC, id_producto
           ) rn
    FROM ventas v
)
SELECT *
FROM ranking
WHERE rn <= 3;

-- 5. PORCENTAJE DEL TOTAL DEL GRUPO
WITH ventas AS (
    SELECT pr.id_categoria, pr.id_producto, pr.nombre,
           SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
    JOIN producto pr ON pr.id_producto = d.id_producto
    WHERE p.estado <> 'ANULADO'
    GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
)
SELECT id_categoria,
       nombre,
       facturado,
       ROUND(
         100 * RATIO_TO_REPORT(facturado)
         OVER (PARTITION BY id_categoria), 2
       ) AS porcentaje_categoria
FROM ventas;

-- 6. ACUMULADO
WITH mensual AS (
    SELECT TRUNC(fecha_pedido,'MM') mes,
           SUM(total) ventas
    FROM pedido
    WHERE fecha_pedido >= DATE '2026-01-01'
      AND fecha_pedido < DATE '2027-01-01'
      AND estado <> 'ANULADO'
    GROUP BY TRUNC(fecha_pedido,'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM') mes,
       ventas,
       SUM(ventas) OVER (
         ORDER BY mes
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) acumulado
FROM mensual
ORDER BY mes;

-- 7. LAG / LEAD
WITH mensual AS (
    SELECT TRUNC(fecha_pedido,'MM') mes,
           SUM(total) ventas
    FROM pedido
    WHERE fecha_pedido >= DATE '2026-01-01'
      AND fecha_pedido < DATE '2027-01-01'
    GROUP BY TRUNC(fecha_pedido,'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM') mes,
       ventas,
       LAG(ventas) OVER (ORDER BY mes) mes_anterior,
       LEAD(ventas) OVER (ORDER BY mes) mes_siguiente,
       ROUND(
         100 * (ventas - LAG(ventas) OVER (ORDER BY mes))
         / NULLIF(LAG(ventas) OVER (ORDER BY mes),0), 2
       ) variacion_pct
FROM mensual
ORDER BY mes;

-- 8. PROMEDIO MOVIL
WITH mensual AS (
    SELECT TRUNC(fecha_pedido,'MM') mes,
           SUM(total) ventas
    FROM pedido
    WHERE fecha_pedido >= DATE '2026-01-01'
      AND fecha_pedido < DATE '2027-01-01'
    GROUP BY TRUNC(fecha_pedido,'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM') mes,
       ventas,
       ROUND(
         AVG(ventas) OVER (
           ORDER BY mes
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
         ), 2
       ) promedio_movil_3m
FROM mensual
ORDER BY mes;

-- 9. ULTIMO PEDIDO POR CLIENTE
SELECT id_cliente, nombre, id_pedido, fecha_pedido, total
FROM (
    SELECT c.id_cliente,
           c.nombre,
           p.id_pedido,
           p.fecha_pedido,
           p.total,
           ROW_NUMBER() OVER (
             PARTITION BY c.id_cliente
             ORDER BY p.fecha_pedido DESC, p.id_pedido DESC
           ) rn
    FROM cliente c
    JOIN pedido p ON p.id_cliente = c.id_cliente
    WHERE c.segmento = 'PREMIUM'
)
WHERE rn = 1;

-- 10. DIFERENCIA ENTRE ROWS Y RANGE
SELECT employee_id,
       salary,
       SUM(salary) OVER (
         ORDER BY salary
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) acumulado_rows,
       SUM(salary) OVER (
         ORDER BY salary
         RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) acumulado_range
FROM hr.employees
ORDER BY salary;

-- 11. CTE RECURSIVA
WITH arbol (id_categoria, nombre, id_padre, nivel, ruta) AS (
    SELECT id_categoria,
           nombre,
           id_padre,
           1,
           CAST(nombre AS VARCHAR2(400))
    FROM categoria
    WHERE id_padre IS NULL

    UNION ALL

    SELECT c.id_categoria,
           c.nombre,
           c.id_padre,
           a.nivel + 1,
           a.ruta || ' > ' || c.nombre
    FROM categoria c
    JOIN arbol a ON c.id_padre = a.id_categoria
)
SELECT LPAD(' ', (nivel-1)*3) || nombre AS jerarquia,
       nivel,
       ruta
FROM arbol
ORDER BY ruta;

-- 12. CONNECT BY
SELECT LPAD(' ', (LEVEL-1)*3) || nombre AS jerarquia,
       LEVEL AS nivel,
       SYS_CONNECT_BY_PATH(nombre,' > ') AS ruta
FROM categoria
START WITH id_padre IS NULL
CONNECT BY PRIOR id_categoria = id_padre
ORDER SIBLINGS BY nombre;

-- 13. PIVOT
SELECT *
FROM (
    SELECT canal,
           'T' || TO_CHAR(fecha_pedido,'Q') trimestre,
           total
    FROM pedido
    WHERE fecha_pedido >= DATE '2026-01-01'
      AND fecha_pedido < DATE '2027-01-01'
      AND estado <> 'ANULADO'
)
PIVOT (
    ROUND(SUM(total))
    FOR trimestre IN ('T1' AS t1,'T2' AS t2,'T3' AS t3,'T4' AS t4)
)
ORDER BY canal;

-- 14. LISTAGG
SELECT c.id_cliente,
       c.nombre,
       LISTAGG(DISTINCT cat.nombre, ', ')
         WITHIN GROUP (ORDER BY cat.nombre) AS categorias
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
JOIN producto pr ON pr.id_producto = d.id_producto
JOIN categoria cat ON cat.id_categoria = pr.id_categoria
WHERE p.estado <> 'ANULADO'
GROUP BY c.id_cliente, c.nombre;

-- 15. FETCH WITH TIES
SELECT c.id_cliente,
       c.nombre,
       SUM(d.cantidad * d.precio_unit) facturado
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
WHERE p.estado <> 'ANULADO'
GROUP BY c.id_cliente, c.nombre
ORDER BY facturado DESC
FETCH FIRST 10 ROWS WITH TIES;

-- 16. MERGE
MERGE INTO inventario i
USING (
    SELECT id_producto,
           id_bodega,
           SUM(delta) AS delta
    FROM ajuste_inventario
    GROUP BY id_producto, id_bodega
) a
ON (i.id_producto = a.id_producto AND i.id_bodega = a.id_bodega)
WHEN MATCHED THEN
    UPDATE SET i.disponible = GREATEST(i.disponible + a.delta,0),
               i.version = i.version + 1
WHEN NOT MATCHED THEN
    INSERT (id_producto,id_bodega,disponible,reservado,version)
    VALUES (a.id_producto,a.id_bodega,GREATEST(a.delta,0),0,0);

-- 17. MERGE + DELETE WHERE
MERGE INTO inventario i
USING (
    SELECT id_producto,id_bodega,SUM(delta) delta
    FROM ajuste_inventario
    GROUP BY id_producto,id_bodega
) a
ON (i.id_producto = a.id_producto AND i.id_bodega = a.id_bodega)
WHEN MATCHED THEN
    UPDATE SET i.disponible = GREATEST(i.disponible + a.delta,0),
               i.version = i.version + 1
    DELETE WHERE i.disponible = 0 AND i.id_bodega <> 1
WHEN NOT MATCHED THEN
    INSERT (id_producto,id_bodega,disponible,reservado,version)
    VALUES (a.id_producto,a.id_bodega,GREATEST(a.delta,0),0,0);

-- 18. SUBCONSULTA CORRELACIONADA VS ANALITICA
SELECT c.id_cliente, c.nombre, p.id_pedido, p.fecha_pedido
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
WHERE p.fecha_pedido = (
    SELECT MAX(p2.fecha_pedido)
    FROM pedido p2
    WHERE p2.id_cliente = c.id_cliente
);

-- 19. PERCENT_RANK / CUME_DIST
SELECT employee_id,
       salary,
       PERCENT_RANK() OVER (ORDER BY salary) percent_rank,
       CUME_DIST() OVER (ORDER BY salary) cume_dist
FROM hr.employees
ORDER BY salary;

-- 20. NTILE
SELECT employee_id,
       first_name,
       salary,
       NTILE(4) OVER (ORDER BY salary DESC) AS cuartil
FROM hr.employees;

-- ================================================================
-- PRACTICA EXTRA
-- ================================================================

-- 1) Segundo salario distinto mas alto.
SELECT salary
FROM (
    SELECT DISTINCT salary
    FROM hr.employees
    ORDER BY salary DESC
)
WHERE ROWNUM = 1
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

-- 2) Los 2 empleados mejor pagados de cada departamento.
SELECT department_id, employee_id, first_name, salary
FROM (
    SELECT department_id, employee_id, first_name, salary,
           ROW_NUMBER() OVER (
             PARTITION BY department_id ORDER BY salary DESC
           ) AS puesto
    FROM hr.employees
)
WHERE puesto <= 2;

-- 3) Diferencia entre salario y promedio del departamento.
SELECT employee_id, first_name, department_id, salary,
       ROUND(salary - AVG(salary) OVER (PARTITION BY department_id), 2)
         AS diferencia_vs_promedio
FROM hr.employees;

-- 4) Clientes cuyo ultimo pedido supera su promedio historico.
WITH pedidos_cliente AS (
    SELECT c.id_cliente,
           c.nombre,
           p.id_pedido,
           p.fecha_pedido,
           p.total,
           AVG(p.total) OVER (PARTITION BY c.id_cliente) AS promedio_historico,
           ROW_NUMBER() OVER (
             PARTITION BY c.id_cliente ORDER BY p.fecha_pedido DESC
           ) AS rn
    FROM cliente c
    JOIN pedido p ON p.id_cliente = c.id_cliente
)
SELECT id_cliente, nombre, id_pedido, fecha_pedido, total, promedio_historico
FROM pedidos_cliente
WHERE rn = 1
  AND total > promedio_historico;
-- ================================================================
