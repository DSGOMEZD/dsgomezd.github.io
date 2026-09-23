-- ================================================================
-- REPASO 5 - INDEXACION
-- Indices B-tree, compuestos, function-based, selectividad,
-- mantenimiento, EXPLAIN PLAN y casos donde un indice no ayuda.
-- ================================================================

-- ADVERTENCIA:
-- Estas sentencias crean objetos en el esquema. Hacerlas en un esquema
-- de practica o eliminarlas al terminar.

-- 1. VER INDICES EXISTENTES
SELECT index_name,
       table_name,
       uniqueness,
       status
FROM user_indexes
WHERE table_name IN ('EMPLOYEES','DEPARTMENTS');

-- 2. COLUMNAS DE INDICES
SELECT index_name,
       table_name,
       column_name,
       column_position
FROM user_ind_columns
WHERE table_name = 'EMPLOYEES'
ORDER BY index_name, column_position;

-- 3. CREAR INDICE SIMPLE
CREATE INDEX idx_emp_department
ON hr.employees(department_id);

-- 4. PROBAR CONSULTA
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
WHERE department_id = 60;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 5. INDICE COMPUESTO
CREATE INDEX idx_emp_dept_salary
ON hr.employees(department_id, salary);

-- Bueno para predicados que empiezan por department_id.
EXPLAIN PLAN FOR
SELECT employee_id, first_name, salary
FROM hr.employees
WHERE department_id = 60
  AND salary > 5000;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 6. ORDEN DE COLUMNAS
-- En (department_id, salary), department_id es la primera columna.
-- Compare:
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE department_id = 60;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE salary > 5000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 7. FUNCTION-BASED INDEX
CREATE INDEX idx_emp_upper_lastname
ON hr.employees(UPPER(last_name));

EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE UPPER(last_name) = 'KING';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 8. INDICE SOBRE FECHA
CREATE INDEX idx_emp_hire_date
ON hr.employees(hire_date);

EXPLAIN PLAN FOR
SELECT employee_id, first_name
FROM hr.employees
WHERE hire_date >= DATE '2005-01-01';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 9. POR QUE TRUNC PUEDE CAMBIAR EL USO DEL INDICE
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE TRUNC(hire_date) = DATE '2005-01-01';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- Alternativa:
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE hire_date >= DATE '2005-01-01'
  AND hire_date < DATE '2005-01-02';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 10. SELECTIVIDAD
-- Un indice suele ser mas util cuando el predicado elimina una
-- proporcion considerable de filas.
SELECT COUNT(*) total,
       COUNT(DISTINCT department_id) departamentos,
       COUNT(DISTINCT job_id) trabajos
FROM hr.employees;

-- 11. INDICE NO SIEMPRE ES MEJOR
-- Si la consulta devuelve una gran parte de la tabla, Oracle puede
-- preferir TABLE ACCESS FULL.
EXPLAIN PLAN FOR
SELECT *
FROM hr.employees
WHERE salary > 1000;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- 12. COLUMNAS CON MUCHOS NULL
-- Un indice B-tree tradicional de una sola columna no almacena entradas
-- donde todas las columnas indexadas son NULL.
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

CREATE INDEX idx_vp_cliente_fecha
ON ventas_prueba(id_cliente, fecha_venta);

-- Casos favorables:
-- WHERE id_cliente = :x
-- WHERE id_cliente = :x AND fecha_venta >= :f

-- Menos directo para este indice:
-- WHERE fecha_venta >= :f

-- 14. ESTADISTICAS
-- El optimizador necesita estadisticas para estimar cardinalidad.
-- En un entorno de practica:
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'VENTAS_PRUEBA'
    );
END;
/

-- 15. REVISAR ESTADO
SELECT index_name,
       table_name,
       status,
       visibility
FROM user_indexes
WHERE table_name = 'VENTAS_PRUEBA';

-- 16. VISIBILIDAD
-- Oracle permite hacer un indice invisible para probar el impacto
-- sobre el optimizador sin eliminarlo.
ALTER INDEX idx_vp_cliente_fecha INVISIBLE;

-- Probar planes aqui.

ALTER INDEX idx_vp_cliente_fecha VISIBLE;

-- 17. MONITOREAR USO - EJERCICIO
-- En versiones/configuraciones donde aplique, estudiar:
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
-- a) Que es un indice?
-- b) Por que un indice puede acelerar un SELECT?
-- c) Que costo tiene mantener indices en INSERT/UPDATE/DELETE?
-- d) Que es selectividad?
-- e) Que es un indice compuesto?
-- f) Por que importa el orden de columnas?
-- g) Que es un function-based index?
-- h) Por que TRUNC(columna) puede impedir un acceso eficiente?
-- i) Cuando Oracle puede preferir TABLE ACCESS FULL?
-- j) Por que las estadisticas son importantes?

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
