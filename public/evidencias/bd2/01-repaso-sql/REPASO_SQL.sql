-- ================================================================
-- REPASO 1 - SQL FUNDAMENTAL
-- Repaso con ejercicios que fui pidiendo a una IA para practicar,
-- en vez de quedarme solo con la teoria de como funciona cada tema.
-- Oracle HR + ejemplos generales.
-- ================================================================

-- 1. SELECT BASICO
SELECT employee_id, first_name, last_name, salary
FROM hr.employees;

-- 2. ALIAS Y EXPRESIONES
SELECT employee_id AS codigo,
       first_name || ' ' || last_name AS nombre_completo,
       salary,
       salary * 12 AS salario_anual
FROM hr.employees;

-- 3. WHERE
SELECT *
FROM hr.employees
WHERE salary > 8000;

SELECT *
FROM hr.employees
WHERE department_id IS NULL;

SELECT *
FROM hr.employees
WHERE salary BETWEEN 5000 AND 10000
  AND job_id IN ('IT_PROG', 'SA_REP');

-- 4. NULL
SELECT employee_id,
       first_name,
       NVL(department_id, 0) AS departamento
FROM hr.employees;

SELECT employee_id,
       first_name,
       NVL(commission_pct, 0) AS comision
FROM hr.employees;

-- 5. DISTINCT
SELECT DISTINCT department_id
FROM hr.employees
WHERE department_id IS NOT NULL;

-- 6. ORDER BY
SELECT first_name, salary
FROM hr.employees
ORDER BY salary DESC, first_name ASC;

-- 7. FUNCIONES DE TEXTO
SELECT first_name,
       UPPER(first_name) AS mayusculas,
       LOWER(last_name) AS minusculas,
       LENGTH(first_name) AS longitud
FROM hr.employees;

SELECT first_name || ' ' || last_name AS nombre,
       SUBSTR(first_name, 1, 3) AS primeras_letras
FROM hr.employees;

-- 8. FUNCIONES NUMERICAS
SELECT salary,
       ROUND(salary / 3, 2) AS redondeado,
       TRUNC(salary / 3, 2) AS truncado,
       MOD(salary, 2) AS residuo
FROM hr.employees;

-- 9. FUNCIONES DE FECHA
SELECT first_name,
       hire_date,
       SYSDATE AS fecha_actual,
       MONTHS_BETWEEN(SYSDATE, hire_date) AS meses_trabajados,
       TRUNC(SYSDATE - hire_date) AS dias_trabajados
FROM hr.employees;

-- 10. AGREGACIONES
SELECT COUNT(*) AS empleados,
       COUNT(commission_pct) AS con_comision,
       MIN(salary) AS salario_minimo,
       MAX(salary) AS salario_maximo,
       ROUND(AVG(salary),2) AS salario_promedio,
       SUM(salary) AS nomina_total
FROM hr.employees;

-- 11. GROUP BY
SELECT department_id,
       COUNT(*) AS cantidad,
       ROUND(AVG(salary),2) AS promedio,
       SUM(salary) AS total_nomina
FROM hr.employees
WHERE department_id IS NOT NULL
GROUP BY department_id
ORDER BY promedio DESC;

-- 12. HAVING
SELECT department_id,
       COUNT(*) AS cantidad,
       ROUND(AVG(salary),2) AS promedio
FROM hr.employees
WHERE department_id IS NOT NULL
GROUP BY department_id
HAVING COUNT(*) >= 2
   AND AVG(salary) > 8000
ORDER BY promedio DESC;

-- 13. INNER JOIN
SELECT e.employee_id,
       e.first_name,
       d.department_name
FROM hr.employees e
JOIN hr.departments d
  ON e.department_id = d.department_id;

-- 14. LEFT JOIN
SELECT e.employee_id,
       e.first_name,
       NVL(d.department_name, 'SIN DEPARTAMENTO') AS departamento
FROM hr.employees e
LEFT JOIN hr.departments d
  ON e.department_id = d.department_id;

-- 15. RIGHT JOIN
SELECT e.employee_id,
       e.first_name,
       NVL(d.department_name, 'SIN DEPARTAMENTO') AS departamento
FROM hr.departments d
RIGHT JOIN hr.employees e
  ON e.department_id = d.department_id;

-- 16. FULL OUTER JOIN
SELECT e.employee_id,
       e.first_name,
       d.department_name
FROM hr.departments d
FULL OUTER JOIN hr.employees e
  ON e.department_id = d.department_id;

-- 17. SELF JOIN
SELECT e.first_name || ' ' || e.last_name AS empleado,
       m.first_name || ' ' || m.last_name AS manager
FROM hr.employees e
LEFT JOIN hr.employees m
  ON e.manager_id = m.employee_id;

-- 18. CROSS JOIN
SELECT d.department_name, e.first_name
FROM hr.departments d
CROSS JOIN hr.employees e;

-- 19. JOIN MULTIPLE
SELECT e.employee_id,
       e.first_name,
       d.department_name,
       j.job_title,
       m.first_name || ' ' || m.last_name AS manager,
       l.city,
       c.country_name
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id
JOIN hr.jobs j ON e.job_id = j.job_id
LEFT JOIN hr.employees m ON e.manager_id = m.employee_id
JOIN hr.locations l ON d.location_id = l.location_id
JOIN hr.countries c ON l.country_id = c.country_id;

-- 20. CASE
SELECT first_name,
       salary,
       CASE
         WHEN salary >= 10000 THEN 'ALTO'
         WHEN salary >= 6000 THEN 'MEDIO'
         ELSE 'BAJO'
       END AS rango_salarial
FROM hr.employees;

-- 21. DECODE
SELECT first_name,
       department_id,
       DECODE(department_id,
              10, 'Administracion',
              20, 'Marketing',
              30, 'Compras',
              'Otro') AS area
FROM hr.employees;

-- 22. SUBCONSULTA SENCILLA
SELECT *
FROM hr.employees
WHERE salary < (SELECT AVG(salary) FROM hr.employees);

-- 23. EXISTS
SELECT d.department_id, d.department_name
FROM hr.departments d
WHERE EXISTS (
    SELECT 1
    FROM hr.employees e
    WHERE e.department_id = d.department_id
);

-- 24. IN
SELECT *
FROM hr.employees
WHERE department_id IN (
    SELECT department_id
    FROM hr.departments
    WHERE manager_id = 100
);

-- 25. ROWNUM / TOP-N BASICO
SELECT *
FROM (
    SELECT first_name, salary
    FROM hr.employees
    ORDER BY salary DESC
)
WHERE ROWNUM <= 5;

-- 26. FETCH
SELECT first_name, salary
FROM hr.employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;

-- 27. UNION
SELECT department_id FROM hr.employees WHERE department_id IS NOT NULL
UNION
SELECT department_id FROM hr.departments;

-- 28. UNION ALL
SELECT department_id FROM hr.employees WHERE department_id IS NOT NULL
UNION ALL
SELECT department_id FROM hr.departments;

-- 29. INTERSECT
SELECT department_id FROM hr.employees WHERE department_id IS NOT NULL
INTERSECT
SELECT department_id FROM hr.departments;

-- 30. MINUS
SELECT department_id FROM hr.departments
MINUS
SELECT department_id FROM hr.employees WHERE department_id IS NOT NULL;

-- 31. VISTA
CREATE OR REPLACE VIEW vw_empleados_departamento AS
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name
FROM hr.employees e
LEFT JOIN hr.departments d
  ON e.department_id = d.department_id;

SELECT * FROM vw_empleados_departamento;

-- 32. PRACTICA FINAL
-- Muestre por departamento: nombre, cantidad de empleados,
-- salario minimo, maximo y promedio; solo departamentos
-- con al menos 3 empleados y promedio superior a 7000.
SELECT d.department_name,
       COUNT(e.employee_id) AS cantidad,
       MIN(e.salary) AS minimo,
       MAX(e.salary) AS maximo,
       ROUND(AVG(e.salary),2) AS promedio
FROM hr.departments d
JOIN hr.employees e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) >= 3
   AND AVG(e.salary) > 7000
ORDER BY promedio DESC;

-- ================================================================
-- REPASAR: SELECT, WHERE, NULL, funciones, GROUP BY/HAVING,
-- joins, subconsultas, conjuntos y vistas.
-- ================================================================
