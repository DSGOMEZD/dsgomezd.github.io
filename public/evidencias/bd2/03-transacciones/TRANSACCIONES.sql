-- ================================================================
-- REPASO 3 - TRANSACCIONES ORACLE
-- Repaso con ejercicios que fui pidiendo a una IA para practicar,
-- en vez de quedarme solo con la teoria de como funciona cada tema.
-- COMMIT, ROLLBACK, SAVEPOINT, aislamiento, bloqueos y concurrencia.
-- ================================================================

-- Practicas en tabla de prueba, no sobre datos reales.

-- 1. TABLA DE PRUEBA
CREATE TABLE cuenta_prueba (
    id_cuenta NUMBER PRIMARY KEY,
    titular VARCHAR2(100),
    saldo NUMBER(12,2) CHECK (saldo >= 0)
);

INSERT INTO cuenta_prueba VALUES (1,'Cuenta A',1000);
INSERT INTO cuenta_prueba VALUES (2,'Cuenta B',500);
COMMIT;

-- 2. TRANSACCION SIMPLE
UPDATE cuenta_prueba SET saldo = saldo - 100 WHERE id_cuenta = 1;
UPDATE cuenta_prueba SET saldo = saldo + 100 WHERE id_cuenta = 2;
SELECT * FROM cuenta_prueba;
COMMIT;

-- 3. ROLLBACK
UPDATE cuenta_prueba SET saldo = saldo - 200 WHERE id_cuenta = 1;
SELECT * FROM cuenta_prueba;
ROLLBACK;
SELECT * FROM cuenta_prueba;

-- 4. SAVEPOINT
UPDATE cuenta_prueba SET saldo = saldo - 100 WHERE id_cuenta = 1;
SAVEPOINT despues_de_retiro;
UPDATE cuenta_prueba SET saldo = saldo + 100 WHERE id_cuenta = 2;
ROLLBACK TO despues_de_retiro;
-- El primer UPDATE sigue pendiente; el segundo se deshizo.
SELECT * FROM cuenta_prueba;
ROLLBACK;

-- 5. TRANSFERENCIA COMPLETA
UPDATE cuenta_prueba SET saldo = saldo - 150 WHERE id_cuenta = 1;
UPDATE cuenta_prueba SET saldo = saldo + 150 WHERE id_cuenta = 2;
COMMIT;

-- 6. AUTOCOMMIT
-- Revisar en SQL Developer que este desactivado, para decidir
-- manualmente cuando hacer COMMIT/ROLLBACK.

-- 7. LOCK DE FILA
-- SESION A:
SELECT * FROM cuenta_prueba WHERE id_cuenta = 1 FOR UPDATE;
-- Mantener la transaccion abierta.
-- SESION B:
-- UPDATE cuenta_prueba SET saldo = saldo + 100 WHERE id_cuenta = 1;
-- Queda esperando el bloqueo de SESION A.
-- SESION A:
COMMIT;
-- SESION B continua despues de liberarse el bloqueo.

-- 8. NOWAIT
SELECT * FROM cuenta_prueba WHERE id_cuenta = 1 FOR UPDATE NOWAIT;
-- Si otra sesion tiene la fila bloqueada, Oracle devuelve error de inmediato.

-- 9. WAIT
SELECT * FROM cuenta_prueba WHERE id_cuenta = 1 FOR UPDATE WAIT 10;
-- Espera hasta 10 segundos por el bloqueo.

-- 10. DEADLOCK - EJERCICIO DE CONCURRENCIA
-- SESION A: UPDATE cuenta_prueba SET saldo = saldo + 10 WHERE id_cuenta = 1;
-- SESION B: UPDATE cuenta_prueba SET saldo = saldo + 20 WHERE id_cuenta = 2;
-- SESION A: UPDATE cuenta_prueba SET saldo = saldo + 10 WHERE id_cuenta = 2;
-- SESION B: UPDATE cuenta_prueba SET saldo = saldo + 20 WHERE id_cuenta = 1;
-- Oracle detecta el ciclo y una sesion recibe ORA-00060.

-- 11. READ COMMITTED (nivel por defecto en Oracle)
SELECT * FROM cuenta_prueba WHERE id_cuenta = 1;
-- No ve cambios sin COMMIT de otra sesion; tras el COMMIT ajeno, si se
-- repite la consulta puede verse el nuevo valor.

-- 12. SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM cuenta_prueba WHERE id_cuenta = 1;
ROLLBACK;

-- 13. READ ONLY
SET TRANSACTION READ ONLY;
SELECT COUNT(*) FROM cuenta_prueba;
SELECT SUM(saldo) FROM cuenta_prueba;
COMMIT;

-- 14. TRANSACCION CON SAVEPOINT PARA VALIDACION
UPDATE cuenta_prueba SET saldo = saldo - 50 WHERE id_cuenta = 1;
SAVEPOINT validar_transferencia;
UPDATE cuenta_prueba SET saldo = saldo + 50 WHERE id_cuenta = 2;
-- Si la validacion falla: ROLLBACK TO validar_transferencia;
COMMIT;

-- 15. CONSISTENCIA
SELECT SUM(saldo) AS dinero_total FROM cuenta_prueba;
-- La suma debe conservarse despues de una transferencia.

-- 16. DDL Y TRANSACCIONES EN ORACLE
-- CREATE, ALTER, DROP, TRUNCATE provocan COMMIT implicito:
-- no mezclar DDL con una transaccion que necesite poder hacer ROLLBACK.

-- 17. EJERCICIO FINAL
-- Transferencia de 300 de A a B, con SAVEPOINT antes del segundo UPDATE,
-- deshaciendo solo la segunda parte y luego todo.
UPDATE cuenta_prueba SET saldo = saldo - 300 WHERE id_cuenta = 1;
SAVEPOINT antes_de_acreditar;
UPDATE cuenta_prueba SET saldo = saldo + 300 WHERE id_cuenta = 2;
SELECT * FROM cuenta_prueba;
ROLLBACK TO antes_de_acreditar;
-- Solo se deshizo el segundo UPDATE; el retiro de 300 en A sigue pendiente.
SELECT * FROM cuenta_prueba;
ROLLBACK;

-- 18. PREGUNTAS DE REPASO
--
-- a) Diferencia entre COMMIT y ROLLBACK.
-- RTA/: COMMIT hace permanentes todos los cambios de la transaccion actual
-- y libera los bloqueos. ROLLBACK deshace todos los cambios desde el ultimo
-- COMMIT y tambien libera los bloqueos.
--
-- b) Diferencia entre ROLLBACK y ROLLBACK TO SAVEPOINT.
-- RTA/: ROLLBACK deshace toda la transaccion. ROLLBACK TO SAVEPOINT solo
-- deshace lo hecho despues del punto marcado; la transaccion sigue abierta
-- y lo anterior al SAVEPOINT queda en pie, listo para seguir o confirmar.
--
-- c) Que problema resuelve SELECT FOR UPDATE?
-- RTA/: Evita que dos sesiones lean la misma fila y despues escriban una
-- encima de la otra (actualizacion perdida). Bloquea la fila desde que se
-- lee con intencion de modificarla, no solo cuando se hace el UPDATE.
--
-- d) Que sucede con dos sesiones actualizando la misma fila?
-- RTA/: La primera que llega toma el bloqueo y sigue trabajando. La segunda
-- queda esperando (o falla si se uso NOWAIT/WAIT n) hasta que la primera
-- haga COMMIT o ROLLBACK y libere la fila.
--
-- e) Que es un deadlock?
-- RTA/: Dos sesiones que se bloquean entre si en orden cruzado: A tiene lo
-- que B necesita y B tiene lo que A necesita, y ninguna puede avanzar.
-- Oracle detecta el ciclo y aborta una de las dos con ORA-00060.
--
-- f) Que significa READ COMMITTED?
-- RTA/: Cada sentencia dentro de la transaccion solo ve datos que ya
-- tuvieron COMMIT en el momento en que esa sentencia arranca; nunca ve
-- cambios de otra sesion todavia sin confirmar. Es el nivel por defecto
-- en Oracle.
--
-- g) Que diferencia conceptual existe con SERIALIZABLE?
-- RTA/: SERIALIZABLE fija la foto de los datos al inicio de toda la
-- transaccion, no sentencia por sentencia: aunque otras sesiones hagan
-- COMMIT mientras tanto, la transaccion sigue viendo el mismo estado hasta
-- que ella misma termine. Da mas consistencia pero mas probabilidad de
-- fallos por conflicto entre sesiones concurrentes.
--
-- h) Que operaciones hacen COMMIT implicito en Oracle?
-- RTA/: Cualquier DDL (CREATE, ALTER, DROP, TRUNCATE) y tambien un CONNECT
-- o DISCONNECT normal de la sesion.

-- LIMPIEZA
DROP TABLE cuenta_prueba;
