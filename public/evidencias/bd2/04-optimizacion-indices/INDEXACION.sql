-- ================================================================
-- REPASO 5 - INDEXACION
-- Repaso con ejercicios que fui pidiendo a una IA para practicar,
-- en vez de quedarme solo con la teoria de como funciona cada tema.
-- Indices B-tree, compuestos, function-based, selectividad,
-- mantenimiento, EXPLAIN PLAN y casos donde un indice no ayuda.
-- ================================================================

-- ADVERTENCIA: estas sentencias crean objetos en el esquema.
-- Hacerlas en un esquema de practica o eliminarlas al terminar.

-- 1. VER INDICES EXISTENTES
SELECT index_name, table_name, uniqueness, status
FROM user_indexes
WHERE table_name IN ('EMPLOYEES','DEPARTMENTS');

-- 2. COLUMNAS DE INDICES
SELECT index_name, table_name, column_name, column_position
FROM user_ind_columns
WHERE table_name = 'EMPLOYEES'
ORDER BY index_name, column_position;

-- 3. CREAR INDICE SIMPLE
CREATE INDEX idx_emp_department ON hr.employees(department_id);

-- 4. PROBAR CONSULTA
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
WHERE department_id = 60;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 5. INDICE COMPUESTO (bueno para predicados que empiezan por department_id)
CREATE INDEX idx_emp_dept_salary ON hr.employees(department_id, salary);

EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
WHERE department_id = 60
  AND salary > 5000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 6. ORDEN DE COLUMNAS: en (department_id, salary), department_id va primero
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE department_id = 60;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE salary > 5000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 7. FUNCTION-BASED INDEX
CREATE INDEX idx_emp_upper_lastname ON hr.employees(UPPER(last_name));

EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 8. INDICE SOBRE FECHA
CREATE INDEX idx_emp_hire_date ON hr.employees(hire_date);

EXPLAIN PLAN FOR
SELECT employee_id, first_name
FROM hr.employees
WHERE hire_date >= DATE '2005-01-01';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 9. POR QUE TRUNC PUEDE CAMBIAR EL USO DEL INDICE
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE TRUNC(hire_date) = DATE '2005-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- Alternativa sargable, sin funcion sobre la columna:
EXPLAIN PLAN FOR
SELECT * FROM hr.employees
WHERE hire_date >= DATE '2005-01-01'
  AND hire_date < DATE '2005-01-02';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 10. SELECTIVIDAD
SELECT COUNT(*) total,
       COUNT(DISTINCT department_id) departamentos,
       COUNT(DISTINCT job_id) trabajos
FROM hr.employees;

-- 11. INDICE NO SIEMPRE ES MEJOR (si devuelve gran parte de la tabla, Oracle prefiere FULL)
EXPLAIN PLAN FOR
SELECT * FROM hr.employees WHERE salary > 1000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 12. COLUMNAS CON MUCHOS NULL
-- Un B-tree de una sola columna no guarda entradas donde esa columna es NULL.
SELECT COUNT(*) AS total,
       COUNT(commission_pct) AS con_comision,
       COUNT(*) - COUNT(commission_pct) AS sin_comision
FROM hr.employees;

-- 13. INDICE COMPUESTO DE PRACTICA
CREATE TABLE ventas_prueba (
    id_venta NUMBER PRIMARY KEY,
    id_cliente NUMBER,
    fecha_venta DATE,
    total NUMBER(12,2),
    estado VARCHAR2(20)
);

CREATE INDEX idx_vp_cliente_fecha ON ventas_prueba(id_cliente, fecha_venta);

-- Favorable: WHERE id_cliente = :x  /  WHERE id_cliente = :x AND fecha_venta >= :f
-- Menos directo: WHERE fecha_venta >= :f (sin id_cliente)

-- 14. ESTADISTICAS (el optimizador las necesita para estimar cardinalidad)
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'VENTAS_PRUEBA');
END;
/

-- 15. REVISAR ESTADO
SELECT index_name, table_name, status, visibility
FROM user_indexes
WHERE table_name = 'VENTAS_PRUEBA';

-- 16. VISIBILIDAD (probar el impacto sin eliminar el indice)
ALTER INDEX idx_vp_cliente_fecha INVISIBLE;
-- Probar planes aqui.
ALTER INDEX idx_vp_cliente_fecha VISIBLE;

-- 17. MONITOREAR USO - EJERCICIO
-- ALTER INDEX nombre MONITORING USAGE;
-- SELECT * FROM V$OBJECT_USAGE;
-- ALTER INDEX nombre NOMONITORING USAGE;

-- 18. BORRAR INDICES DE PRACTICA
DROP INDEX idx_emp_department;
DROP INDEX idx_emp_dept_salary;
DROP INDEX idx_emp_upper_lastname;
DROP INDEX idx_emp_hire_date;
DROP INDEX idx_vp_cliente_fecha;
DROP TABLE ventas_prueba;

-- 19. PREGUNTAS DE REPASO
--
-- a) Que es un indice?
-- RTA/: Una estructura aparte (normalmente un B-tree) que guarda los
-- valores de una o mas columnas ya ordenados junto con la direccion de la
-- fila, para no tener que leer la tabla completa buscando un valor.
--
-- b) Por que un indice puede acelerar un SELECT?
-- RTA/: Porque buscar en una estructura ordenada es mucho mas rapido que
-- recorrer fila por fila (TABLE ACCESS FULL), sobre todo cuando el filtro
-- deja pocas filas: Oracle salta directo al punto del indice y de ahi va a
-- la tabla solo por esas filas.
--
-- c) Que costo tiene mantener indices en INSERT/UPDATE/DELETE?
-- RTA/: Cada indice se tiene que actualizar ademas de la tabla, asi que
-- cada escritura hace mas trabajo por cada indice que exista sobre esa
-- tabla. Con muchos indices, las escrituras se vuelven notablemente mas
-- lentas aunque las lecturas mejoren.
--
-- d) Que es selectividad?
-- RTA/: Que tan pocas filas deja un filtro frente al total de la tabla.
-- Un filtro muy selectivo (pocas filas) le conviene a un indice; uno poco
-- selectivo (devuelve gran parte de la tabla) no, porque saltar fila por
-- fila desde el indice termina costando mas que leer todo de corrido.
--
-- e) Que es un indice compuesto?
-- RTA/: Un indice que combina varias columnas en un mismo orden, por
-- ejemplo (department_id, salary), pensado para consultas que filtran por
-- esas columnas juntas.
--
-- f) Por que importa el orden de columnas?
-- RTA/: Un indice compuesto solo se puede "entrar" por su primera columna.
-- Si el orden es (department_id, salary), sirve para filtrar por
-- department_id solo o por los dos juntos, pero no sirve para filtrar solo
-- por salary.
--
-- g) Que es un function-based index?
-- RTA/: Un indice creado sobre el resultado de una expresion o funcion
-- (por ejemplo UPPER(last_name)) en vez de sobre la columna cruda, para que
-- consultas que filtran por esa misma expresion puedan usarlo.
--
-- h) Por que TRUNC(columna) puede impedir un acceso eficiente?
-- RTA/: Porque el indice guarda el valor original de la columna, no el
-- resultado de aplicarle una funcion. Si el WHERE le aplica TRUNC a la
-- columna, Oracle no puede buscar ese valor transformado en el indice y
-- le toca leer cada fila, calcular TRUNC y comparar (FULL SCAN).
--
-- i) Cuando Oracle puede preferir TABLE ACCESS FULL?
-- RTA/: Cuando el filtro no es selectivo (devuelve una parte grande de la
-- tabla), cuando no hay estadisticas confiables, o cuando el indice tiene
-- mal clustering factor: en esos casos leer la tabla completa de corrido
-- sale mas barato que saltar entrada por entrada desde el indice.
--
-- j) Por que las estadisticas son importantes?
-- RTA/: El optimizador decide el plan segun cardinalidad estimada, y esa
-- estimacion sale de las estadisticas (num_distinct, density, histogramas).
-- Con estadisticas desactualizadas puede elegir un plan que no corresponde
-- a los datos reales de la tabla.

-- 20. EJERCICIO FINAL DE EXAMEN
-- Para una consulta lenta:
-- 1) Ejecutar la consulta original.
-- 2) Obtener plan.
-- 3) Revisar E-Rows/A-Rows y buffers si estan disponibles.
-- 4) Identificar filtros y joins.
-- 5) Proponer indice.
-- 6) Crear indice.
-- 7) Actualizar estadisticas.
-- 8) Volver a medir.
-- 9) Comparar el resultado.
-- 10) Eliminar el indice si no aporta beneficio.
