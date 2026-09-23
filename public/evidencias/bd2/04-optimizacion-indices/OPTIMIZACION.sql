-- ================================================================
-- REPASO 4 - OPTIMIZACION DE CONSULTAS
-- EXPLAIN PLAN, DBMS_XPLAN, cardinalidad, joins, subconsultas,
-- filtros, funciones y comparacion de planes.
-- ================================================================

-- 1. PLAN BASICO
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE department_id = 60;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 2. COMPARAR SELECT * VS COLUMNAS NECESARIAS
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE salary > 8000;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
WHERE salary > 8000;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 3. FILTRO SARGABLE
-- Generalmente es preferible comparar directamente la columna:
EXPLAIN PLAN FOR
SELECT employee_id
FROM hr.employees
WHERE hire_date >= DATE '2005-01-01';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- Evitar aplicar una funcion sobre la columna si no es necesario:
EXPLAIN PLAN FOR
SELECT employee_id
FROM hr.employees
WHERE TRUNC(hire_date) = DATE '2005-01-01';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 4. JOIN Y FILTROS
EXPLAIN PLAN FOR
SELECT e.employee_id, e.first_name, d.department_name
FROM hr.employees e
JOIN hr.departments d
  ON e.department_id = d.department_id
WHERE e.salary > 8000;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 5. SUBCONSULTA VS JOIN
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees e
WHERE e.department_id IN (
    SELECT d.department_id
    FROM hr.departments d
    WHERE d.location_id = 1700
);

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT e.*
FROM hr.employees e
JOIN hr.departments d
  ON e.department_id = d.department_id
WHERE d.location_id = 1700;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 6. EXISTS
EXPLAIN PLAN FOR
SELECT d.department_id, d.department_name
FROM hr.departments d
WHERE EXISTS (
    SELECT 1
    FROM hr.employees e
    WHERE e.department_id = d.department_id
);

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 7. CUIDADO CON FUNCIONES
-- Comparar ambos planes:
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE UPPER(last_name) = 'KING';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE last_name = 'King';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 8. ORDER BY + TOP N
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 9. AGREGACION
EXPLAIN PLAN FOR
SELECT department_id, AVG(salary)
FROM hr.employees
GROUP BY department_id;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 10. ANALITICAS
EXPLAIN PLAN FOR
SELECT employee_id,
       salary,
       RANK() OVER (ORDER BY salary DESC) ranking
FROM hr.employees;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 11. PLAN REAL DE UNA CONSULTA
-- Si el entorno permite ejecutar y recopilar estadisticas:
SELECT /*+ GATHER_PLAN_STATISTICS */
       e.employee_id, e.first_name, d.department_name
FROM hr.employees e
JOIN hr.departments d
  ON e.department_id = d.department_id
WHERE e.salary > 8000;

SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        NULL, NULL,
        'ALLSTATS LAST'
    )
);

-- 12. COMPARAR COST VS ROWS
-- No asumir que menor COST siempre significa menor tiempo real.
-- Compare:
-- COST estimado
-- E-Rows (filas estimadas)
-- A-Rows (filas reales)
-- Buffers
-- Reads
-- tiempo

-- 13. SELECTIVIDAD
SELECT department_id, COUNT(*) cantidad
FROM hr.employees
GROUP BY department_id
ORDER BY cantidad DESC;

-- Un filtro muy selectivo suele reducir filas rápidamente.

-- 14. EVITAR TRAER FILAS INNECESARIAS
-- Menos recomendable:
SELECT *
FROM hr.employees;

-- Preferible cuando solo se necesitan estas columnas:
SELECT employee_id, first_name, salary
FROM hr.employees;

-- 15. UNION VS UNION ALL
-- UNION elimina duplicados y puede requerir trabajo adicional.
SELECT department_id FROM hr.employees
UNION
SELECT department_id FROM hr.departments;

SELECT department_id FROM hr.employees
UNION ALL
SELECT department_id FROM hr.departments;

-- 16. COUNT(*)
EXPLAIN PLAN FOR
SELECT COUNT(*)
FROM hr.employees;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 17. EJERCICIO COMPARATIVO
-- Tome una consulta de tus practicas y construya:
-- A) version con subconsulta
-- B) version con JOIN
-- C) version con CTE
-- Ejecute EXPLAIN PLAN para las tres y compare.

-- 18. PRINCIPIOS PARA RECORDAR
-- * Medir antes de optimizar.
-- * Mirar el plan, no adivinar.
-- * Reducir filas temprano cuando sea posible.
-- * Evitar funciones innecesarias sobre columnas filtradas.
-- * Seleccionar solo columnas necesarias.
-- * Revisar cardinalidad estimada vs real.
-- * No asumir que un indice siempre mejora una consulta.
