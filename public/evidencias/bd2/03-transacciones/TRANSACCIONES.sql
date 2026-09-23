-- ================================================================
-- REPASO 3 - TRANSACCIONES ORACLE
-- COMMIT, ROLLBACK, SAVEPOINT, aislamiento, bloqueos y concurrencia.
-- Esta categoria tenia poco contenido en los scripts originales,
-- por eso se amplio de forma importante.
-- ================================================================

-- IMPORTANTE:
-- Hacer estas practicas en tablas de prueba, no sobre datos reales.

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
UPDATE cuenta_prueba
SET saldo = saldo - 100
WHERE id_cuenta = 1;

UPDATE cuenta_prueba
SET saldo = saldo + 100
WHERE id_cuenta = 2;

-- Ver cambios antes de confirmar
SELECT * FROM cuenta_prueba;

COMMIT;

-- 3. ROLLBACK
UPDATE cuenta_prueba
SET saldo = saldo - 200
WHERE id_cuenta = 1;

SELECT * FROM cuenta_prueba;

ROLLBACK;

SELECT * FROM cuenta_prueba;

-- 4. SAVEPOINT
UPDATE cuenta_prueba
SET saldo = saldo - 100
WHERE id_cuenta = 1;

SAVEPOINT despues_de_retiro;

UPDATE cuenta_prueba
SET saldo = saldo + 100
WHERE id_cuenta = 2;

-- Volver solo al punto guardado
ROLLBACK TO despues_de_retiro;

-- El primer UPDATE sigue pendiente; el segundo se deshizo.
SELECT * FROM cuenta_prueba;

ROLLBACK;

-- 5. TRANSFERENCIA COMPLETA
UPDATE cuenta_prueba
SET saldo = saldo - 150
WHERE id_cuenta = 1;

UPDATE cuenta_prueba
SET saldo = saldo + 150
WHERE id_cuenta = 2;

COMMIT;

-- 6. AUTOCOMMIT
-- En SQL Developer revisar si AUTOCOMMIT esta activo.
-- Para estudiar correctamente una transaccion, conviene tenerlo
-- desactivado y decidir manualmente COMMIT/ROLLBACK.

-- 7. LOCK DE FILA
-- SESION A:
SELECT *
FROM cuenta_prueba
WHERE id_cuenta = 1
FOR UPDATE;

-- Mantenga la transaccion abierta.
-- SESION B:
-- UPDATE cuenta_prueba SET saldo = saldo + 100 WHERE id_cuenta = 1;
-- La sentencia queda esperando el bloqueo de SESION A.

-- SESION A:
COMMIT;

-- SESION B continua despues de liberarse el bloqueo.

-- 8. NOWAIT
SELECT *
FROM cuenta_prueba
WHERE id_cuenta = 1
FOR UPDATE NOWAIT;

-- Si otra sesion tiene la fila bloqueada, Oracle devuelve error
-- inmediatamente en lugar de esperar.

-- 9. WAIT
SELECT *
FROM cuenta_prueba
WHERE id_cuenta = 1
FOR UPDATE WAIT 10;

-- Espera hasta 10 segundos por el bloqueo.

-- 10. DEADLOCK - EJERCICIO DE CONCURRENCIA
-- SESION A:
-- UPDATE cuenta_prueba SET saldo = saldo + 10 WHERE id_cuenta = 1;
-- SESION B:
-- UPDATE cuenta_prueba SET saldo = saldo + 20 WHERE id_cuenta = 2;
-- SESION A:
-- UPDATE cuenta_prueba SET saldo = saldo + 10 WHERE id_cuenta = 2;
-- SESION B:
-- UPDATE cuenta_prueba SET saldo = saldo + 20 WHERE id_cuenta = 1;
-- Oracle detecta el ciclo y una sesion recibe ORA-00060.

-- 11. READ COMMITTED
-- Oracle usa READ COMMITTED como nivel de aislamiento por defecto.
SELECT *
FROM cuenta_prueba
WHERE id_cuenta = 1;

-- Una consulta no ve cambios NO COMMIT de otra sesion.
-- Si la otra sesion hace COMMIT y se vuelve a ejecutar la consulta,
-- puede observar el nuevo valor.

-- 12. SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT *
FROM cuenta_prueba
WHERE id_cuenta = 1;

-- Haga aqui una operacion de prueba y luego:
ROLLBACK;

-- 13. READ ONLY
SET TRANSACTION READ ONLY;

SELECT COUNT(*) FROM cuenta_prueba;
SELECT SUM(saldo) FROM cuenta_prueba;

COMMIT;

-- 14. TRANSACCION CON SAVEPOINT PARA VALIDACION
UPDATE cuenta_prueba
SET saldo = saldo - 50
WHERE id_cuenta = 1;

SAVEPOINT validar_transferencia;

-- Simular segunda parte
UPDATE cuenta_prueba
SET saldo = saldo + 50
WHERE id_cuenta = 2;

-- Si la validacion falla:
-- ROLLBACK TO validar_transferencia;
-- Si todo esta correcto:
COMMIT;

-- 15. CONSISTENCIA
SELECT SUM(saldo) AS dinero_total
FROM cuenta_prueba;

-- La suma debe conservarse después de una transferencia.

-- 16. DDL Y TRANSACCIONES EN ORACLE
-- CREATE, ALTER, DROP, TRUNCATE y otros DDL provocan COMMIT implicito.
-- No mezcle DDL con una transaccion que necesite poder hacer ROLLBACK.

-- 17. EJERCICIO FINAL
-- Realice una transferencia de 300:
-- A -> B
-- Use SAVEPOINT antes del segundo UPDATE.
-- Consulte saldos.
-- Deshaga hasta SAVEPOINT.
-- Compruebe que solo se deshizo la segunda parte.
-- Finalmente haga ROLLBACK completo.

-- 18. PREGUNTAS DE REPASO
-- a) Diferencia entre COMMIT y ROLLBACK.
-- b) Diferencia entre ROLLBACK y ROLLBACK TO SAVEPOINT.
-- c) Que problema resuelve SELECT FOR UPDATE?
-- d) Que sucede con dos sesiones actualizando la misma fila?
-- e) Que es un deadlock?
-- f) Que significa READ COMMITTED?
-- g) Que diferencia conceptual existe con SERIALIZABLE?
-- h) Que operaciones hacen COMMIT implicito en Oracle?

-- LIMPIEZA
DROP TABLE cuenta_prueba;
