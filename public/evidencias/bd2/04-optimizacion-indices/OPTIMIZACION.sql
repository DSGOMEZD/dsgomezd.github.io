-- ================================================================
-- REPASO 4 - OPTIMIZACION DE CONSULTAS
-- Repaso con ejercicios que fui pidiendo a una IA para practicar,
-- en vez de quedarme solo con la teoria de como funciona cada tema.
-- EXPLAIN PLAN, DBMS_XPLAN, cardinalidad, joins, subconsultas,
-- filtros, funciones y comparacion de planes.
-- ================================================================

-- 1. PLAN BASICO
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE department_id = 60;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 2. SELECT * VS COLUMNAS NECESARIAS
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE salary > 8000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary FROM hr.employees WHERE salary > 8000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 3. FILTRO SARGABLE: comparar la columna directa, sin funcion encima
EXPLAIN PLAN FOR
SELECT employee_id FROM hr.employees WHERE hire_date >= DATE '2005-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT employee_id FROM hr.employees WHERE TRUNC(hire_date) = DATE '2005-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 4. JOIN Y FILTROS
EXPLAIN PLAN FOR
SELECT e.employee_id, e.first_name, d.department_name
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id
WHERE e.salary > 8000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 5. SUBCONSULTA VS JOIN
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees e
WHERE e.department_id IN (
    SELECT d.department_id FROM hr.departments d WHERE d.location_id = 1700
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT e.*
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id
WHERE d.location_id = 1700;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 6. EXISTS
EXPLAIN PLAN FOR
SELECT d.department_id, d.department_name
FROM hr.departments d
WHERE EXISTS (SELECT 1 FROM hr.employees e WHERE e.department_id = d.department_id);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 7. CUIDADO CON FUNCIONES (comparar ambos planes)
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE last_name = 'King';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 8. ORDER BY + TOP N
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 9. AGREGACION
EXPLAIN PLAN FOR
SELECT department_id, AVG(salary) FROM hr.employees GROUP BY department_id;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 10. ANALITICAS
EXPLAIN PLAN FOR
SELECT employee_id, salary, RANK() OVER (ORDER BY salary DESC) ranking
FROM hr.employees;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 11. PLAN REAL DE UNA CONSULTA (si el entorno permite ejecutar y recopilar estadisticas)
SELECT /*+ GATHER_PLAN_STATISTICS */
       e.employee_id, e.first_name, d.department_name
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id
WHERE e.salary > 8000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- 12. COMPARAR COST VS ROWS
-- No asumir que menor COST siempre significa menor tiempo real: comparar
-- COST estimado, E-Rows, A-Rows, Buffers, Reads y tiempo real.

-- 13. SELECTIVIDAD
SELECT department_id, COUNT(*) cantidad
FROM hr.employees
GROUP BY department_id
ORDER BY cantidad DESC;
-- Un filtro muy selectivo reduce filas rapido.

-- 14. EVITAR TRAER FILAS INNECESARIAS
SELECT * FROM hr.employees;                          -- menos recomendable
SELECT employee_id, first_name, salary FROM hr.employees; -- preferible

-- 15. UNION VS UNION ALL (UNION elimina duplicados y hace trabajo extra)
SELECT department_id FROM hr.employees
UNION
SELECT department_id FROM hr.departments;

SELECT department_id FROM hr.employees
UNION ALL
SELECT department_id FROM hr.departments;

-- 16. COUNT(*)
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM hr.employees;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 17. EJERCICIO COMPARATIVO
-- Empleados que ganan mas que el promedio de su departamento, en tres
-- versiones: subconsulta correlacionada, JOIN y CTE.

-- A) Subconsulta correlacionada
EXPLAIN PLAN FOR
SELECT e.employee_id, e.first_name, e.salary
FROM hr.employees e
WHERE e.salary > (
    SELECT AVG(e2.salary) FROM hr.employees e2
    WHERE e2.department_id = e.department_id
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- B) JOIN contra el promedio ya agregado
EXPLAIN PLAN FOR
SELECT e.employee_id, e.first_name, e.salary
FROM hr.employees e
JOIN (
    SELECT department_id, AVG(salary) AS promedio
    FROM hr.employees
    GROUP BY department_id
) prom ON prom.department_id = e.department_id
WHERE e.salary > prom.promedio;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- C) CTE
EXPLAIN PLAN FOR
WITH promedio_depto AS (
    SELECT department_id, AVG(salary) AS promedio
    FROM hr.employees
    GROUP BY department_id
)
SELECT e.employee_id, e.first_name, e.salary
FROM hr.employees e
JOIN promedio_depto p ON p.department_id = e.department_id
WHERE e.salary > p.promedio;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- RTA 17/: la subconsulta correlacionada (A) recalcula el promedio del
-- departamento por cada fila de employees, mientras que B y C agregan una
-- sola vez y despues hacen JOIN contra ese resultado ya reducido; el
-- optimizador de Oracle suele transformar A internamente para que termine
-- pareciendose al plan de B, pero escribirla como B o C deja esa
-- transformacion explicita en vez de depender de que el optimizador la
-- encuentre.

-- 18. PRINCIPIOS PARA RECORDAR
-- * Medir antes de optimizar.
-- * Mirar el plan, no adivinar.
-- * Reducir filas temprano cuando sea posible.
-- * Evitar funciones innecesarias sobre columnas filtradas.
-- * Seleccionar solo columnas necesarias.
-- * Revisar cardinalidad estimada vs real.
-- * No asumir que un indice siempre mejora una consulta.
