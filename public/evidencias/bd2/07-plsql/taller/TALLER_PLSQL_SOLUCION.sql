--------------------------------------------------------------------------------
-- UNIVERSIDAD EL BOSQUE — INGENIERIA DE SISTEMAS
-- Asignatura: Bases de Datos 2
-- Docente: Ing., Esp., M.Ed. Christian Felipe Duarte
--
-- TALLER PL/SQL — PLANTILLA DE ENTREGA
--
-- GRUPO No.: 3
-- INTEGRANTES: 1) Santiago Gomez
--              2) Gabriel Amortegui
--              3) David Herrera
-- FECHA DE ENTREGA: 06/10/2026
--------------------------------------------------------------------------------
--
-- COMO TRABAJAR
--   1. Ejecute primero, completo, el script 01_esquema_inventario.sql
--   2. Desarrolle cada punto en la seccion correspondiente de este archivo
--   3. No borre los encabezados de cada ejercicio ni cambie los nombres de los
--      objetos solicitados. La revision los busca por nombre: un objeto correcto
--      con otro nombre se califica como no entregado.
--   4. Los esqueletos de la Parte 5 no incluyen la clausula de disparo. Definirla
--      hace parte del ejercicio, de modo que esos bloques no compilan tal como se
--      entregan.
--
-- DISTRIBUCION DEL PUNTAJE                                     Total: 50 puntos
--   Parte 1  Procedimientos almacenados .................  8 puntos
--   Parte 2  Funciones ...................................  8 puntos
--   Parte 3  Cursores .................................... 10 puntos
--   Parte 4  Manejo de excepciones .......................  9 puntos
--   Parte 5  Disparadores ................................ 10 puntos
--   Parte 6  Caso integrador .............................  5 puntos
--
-- CRITERIOS DE EVALUACION
--   Correccion tecnica ....... 40%   El objeto compila y cumple el enunciado
--   Justificacion ............ 40%   Las decisiones de diseno estan argumentadas
--   Analisis operacional ..... 20%   Se anticipa el comportamiento ante
--                                    concurrencia, volumen y error
--
--   Cada objeto debe incluir su justificacion en el espacio marcado. Un ejercicio
--   sin justificacion obtiene como maximo el 40% de su puntaje aunque funcione.
--   Una justificacion que confunde la causa con el efecto no obtiene puntaje.
--   Describir lo que hace el codigo, sin argumentar por que se eligio esa
--   construccion y no otra, equivale a no justificar.
--
-- ENTREGA
--   Este archivo renombrado como TALLER_PLSQL_GRUPO_<n>.sql, junto con un
--   documento que contenga las salidas de DBMS_OUTPUT de cada bloque ejecutado.
--   Ambos archivos deben incluir los nombres de los tres integrantes.
--
-- SUSTENTACION
--   20 minutos por grupo. Los tres integrantes deben poder explicar cualquier
--   parte del codigo, no solamente la que desarrollaron.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED

--==============================================================================
-- PARTE 1 — PROCEDIMIENTOS ALMACENADOS                        (8 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 1.1 (2 pts)
-- SP_REGISTRAR_PRODUCTO
-- Registra un producto nuevo. Debe asignar el identificador desde SEQ_PRODUCTO,
-- validar que el precio de venta supere el costo unitario, verificar que la
-- categoria exista y manejar el caso de codigo duplicado. Devuelve el
-- identificador generado.
-------------------------------------------------------------------------------

-- JUSTIFICACION:
-- 1) Valido precio > costo y la categoria ANTES de pedir el numero a la
--    secuencia. Asi, si algo falla, no se gasta un id (no quedan huecos).
-- 2) La categoria se valida con un SELECT COUNT(*): siempre devuelve una fila,
--    asi evito el NO_DATA_FOUND y el codigo queda mas simple.
-- 3) El codigo duplicado lo captura DUP_VAL_ON_INDEX. Es mejor que hacer un
--    SELECT previo, porque con dos usuarios a la vez ese SELECT puede pasar
--    los dos y solo la restriccion UNIQUE de la BD es segura.
-- 4) Uso RAISE_APPLICATION_ERROR para dar mensajes claros y distintos
--    (-20001, -20002, -20003) a quien llame el procedimiento.
-- 5) p_id_producto solo se asigna al final, cuando el INSERT ya funcionó.

CREATE OR REPLACE PROCEDURE SP_REGISTRAR_PRODUCTO (
    p_codigo        IN  VARCHAR2,
    p_nombre        IN  VARCHAR2,
    p_id_categoria  IN  NUMBER,
    p_precio        IN  NUMBER,
    p_costo         IN  NUMBER,
    p_stock_minimo  IN  NUMBER DEFAULT 0,
    p_id_producto   OUT NUMBER
) IS
    vn_existe NUMBER;
BEGIN
    -- Precio debe ser mayor al costo
    IF p_precio IS NULL OR p_costo IS NULL OR p_precio <= p_costo THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El precio de venta debe ser mayor al costo unitario');
    END IF;

    -- La categoria debe existir
    SELECT COUNT(*) INTO vn_existe
      FROM CATEGORIA
     WHERE id_categoria = p_id_categoria;

    IF vn_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'La categoria ' || p_id_categoria || ' no existe');
    END IF;
    
    --sacar el id e insertar
    p_id_producto := SEQ_PRODUCTO.NEXTVAL;

    INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria,
                          precio_unitario, costo_unitario, stock_minimo)
    VALUES (p_id_producto, p_codigo, p_nombre, p_id_categoria,
            p_precio, p_costo, p_stock_minimo);
 -- Codigo duplicado   
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ya existe un producto con ese codigo');
END SP_REGISTRAR_PRODUCTO;

/
-- Probar la salida
DECLARE
    vn_id NUMBER;
BEGIN
    -- precio menor al costo
    BEGIN
        SP_REGISTRAR_PRODUCTO('TEST-001', 'Prueba', 1, 2000, 3000, 10, vn_id);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Precio: ' || SQLERRM);
    END;

    --categoria inexistente
    BEGIN
        SP_REGISTRAR_PRODUCTO('TEST-001', 'Prueba', 9999, 5000, 3000, 10, vn_id);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Categoria: ' || SQLERRM);
    END;

    --caso correcto
    SP_REGISTRAR_PRODUCTO('TEST-001', 'Prueba', 1, 5000, 3000, 10, vn_id);
    DBMS_OUTPUT.PUT_LINE('Creado con id: ' || vn_id);

    --  codigo duplicado
    BEGIN
        SP_REGISTRAR_PRODUCTO('TEST-001', 'Prueba', 1, 5000, 3000, 10, vn_id);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Duplicado: ' || SQLERRM);
    END;
END;
/
ROLLBACK;
/

------------------------------------------------------------------- 1.2 (3 pts)
-- SP_AJUSTAR_STOCK
-- Registra una ENTRADA, SALIDA o AJUSTE de inventario sobre una bodega.
-- Debe actualizar EXISTENCIA e insertar el registro en MOVIMIENTO_INVENTARIO,
-- devolviendo el saldo resultante.
--   * Si la combinacion bodega-producto no existe y el tipo es ENTRADA, crearla
--   * Si el tipo es SALIDA y no existe la combinacion, rechazar la operacion
--   * Una SALIDA nunca puede dejar la existencia en negativo
-- Proteja la lectura de la existencia frente a modificaciones concurrentes.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Se valida el tipo y la cantidad antes de tocar las tablas, para dar
--    errores claros (-20004, -20005) y no gastar trabajo inutil.
-- 2) La existencia se lee con SELECT ... FOR UPDATE, que bloquea la fila.
--    Asi, si dos usuarios hacen una salida al tiempo, el segundo espera y no
--    lee un saldo desactualizado.
-- 3) Si no existe la fila, NO_DATA_FOUND se maneja segun el tipo: en ENTRADA
--    se parte de 0 y se crea la fila; en SALIDA o AJUSTE se rechaza (-20006).
-- 4) En SALIDA se compara con el saldo antes de restar (-20007), para que la
--    existencia nunca quede negativa.
-- 5) AJUSTE deja la existencia en la cantidad indicada (conteo fisico).
-- 6) El movimiento se inserta al final, cuando la existencia ya se actualizo.
--    No se hace COMMIT para que quien llame decida guardar o deshacer todo.
CREATE OR REPLACE PROCEDURE SP_AJUSTAR_STOCK (
    p_id_producto  IN  NUMBER,
    p_id_bodega    IN  NUMBER,
    p_tipo         IN  VARCHAR2,
    p_cantidad     IN  NUMBER,
    p_observacion  IN  VARCHAR2 DEFAULT NULL,
    p_saldo_final  OUT NUMBER
) IS
    vn_actual  NUMBER;         
    vb_existe  BOOLEAN := TRUE; 
BEGIN
-- validar el tipo y la cantidad
    IF p_tipo IS NULL OR p_tipo NOT IN ('ENTRADA', 'SALIDA', 'AJUSTE') THEN
        RAISE_APPLICATION_ERROR(-20004,
            'El tipo debe ser ENTRADA, SALIDA o AJUSTE');
    END IF;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE_APPLICATION_ERROR(-20005,
            'La cantidad debe ser mayor a cero');
    END IF;
--leer la existencia actual y bloquear la fila
    BEGIN
        SELECT cantidad INTO vn_actual
          FROM EXISTENCIA
         WHERE id_bodega = p_id_bodega
           AND id_producto = p_id_producto
           FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF p_tipo = 'ENTRADA' THEN
                vn_actual := 0;
                vb_existe := FALSE;
            ELSE
                RAISE_APPLICATION_ERROR(-20006,
                    'No existe el producto en esa bodega');
            END IF;
    END;
--calcular el nuevo saldo
    IF p_tipo = 'ENTRADA' THEN
        p_saldo_final := vn_actual + p_cantidad;
    ELSIF p_tipo = 'SALIDA' THEN
        IF p_cantidad > vn_actual THEN
            RAISE_APPLICATION_ERROR(-20007,
                'Stock insuficiente: hay ' || vn_actual || ' unidades');
        END IF;
        p_saldo_final := vn_actual - p_cantidad;
    ELSE  
        p_saldo_final := p_cantidad;
    END IF;

--actualizar o crear la existencia
    IF vb_existe THEN
        UPDATE EXISTENCIA
           SET cantidad = p_saldo_final
         WHERE id_bodega = p_id_bodega
           AND id_producto = p_id_producto;
    ELSE
        INSERT INTO EXISTENCIA (id_bodega, id_producto, cantidad)
        VALUES (p_id_bodega, p_id_producto, p_saldo_final);
    END IF;
 -- registrar el movimiento   
    INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega,
                                       tipo, cantidad, observacion)
    VALUES (SEQ_MOVIMIENTO.NEXTVAL, p_id_producto, p_id_bodega,
            p_tipo, p_cantidad, p_observacion);
END SP_AJUSTAR_STOCK;
/
-- Prueba 
DECLARE
    v_saldo NUMBER;
BEGIN
    -- 1) ENTRADA sobre existencia que ya existe: 120 + 10 = 130
    SP_AJUSTAR_STOCK(1001, 1, 'ENTRADA', 10, 'Prueba entrada', v_saldo);
    DBMS_OUTPUT.PUT_LINE('1) Entrada - saldo: ' || v_saldo);

    -- 2) SALIDA normal: 130 - 5 = 125
    SP_AJUSTAR_STOCK(1001, 1, 'SALIDA', 5, 'Prueba salida', v_saldo);
    DBMS_OUTPUT.PUT_LINE('2) Salida - saldo: ' || v_saldo);

    -- 3) SALIDA mayor al stock: debe dar error -20007
    BEGIN
        SP_AJUSTAR_STOCK(1001, 1, 'SALIDA', 9999, NULL, v_saldo);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('3) Stock insuficiente  ' || SQLERRM);
    END;

    -- 4) SALIDA donde no existe la combinacion: debe dar error -20006
    BEGIN
        SP_AJUSTAR_STOCK(1001, 3, 'SALIDA', 1, NULL, v_saldo);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('4) Sin existencia  ' || SQLERRM);
    END;

    -- 5) ENTRADA que crea la combinacion: saldo 20
    SP_AJUSTAR_STOCK(1001, 3, 'ENTRADA', 20, 'Crea existencia', v_saldo);
    DBMS_OUTPUT.PUT_LINE('5) Entrada que crea - saldo: ' || v_saldo);

    -- 6) AJUSTE: deja la existencia en 100
    SP_AJUSTAR_STOCK(1001, 1, 'AJUSTE', 100, 'Conteo fisico', v_saldo);
    DBMS_OUTPUT.PUT_LINE('6) Ajuste - saldo: ' || v_saldo);
END;
/

-- Para ver los movimientos registrados:
SELECT tipo, cantidad, id_bodega, observacion
  FROM MOVIMIENTO_INVENTARIO
 WHERE id_producto = 1001
 ORDER BY id_movimiento DESC;


ROLLBACK;
------------------------------------------------------------------- 1.3 (3 pts)
-- SP_CREAR_PEDIDO
-- Crea la cabecera de un pedido en estado BORRADOR y devuelve el identificador
-- generado. Debe rechazar clientes inactivos y clientes sin cupo de credito
-- disponible, con mensajes distinguibles entre si.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Los datos del cliente se leen con un solo SELECT (activo, cupo y saldo)
--    y las variables usan %TYPE para seguir el tipo de la columna.
-- 2) Si el cliente no existe se captura NO_DATA_FOUND (-20101) para dar un
--    mensaje claro y no el error tecnico.
-- 3) El cliente inactivo (-20102) se revisa ANTES que el cupo, porque un
--    cliente inactivo puede tener cupo libre y recibiria el mensaje
--    equivocado. Cada rechazo tiene su propio codigo para distinguirlos.
-- 4) El id se pide a la secuencia despues de las validaciones, para no gastar
--    numeros en pedidos rechazados.
-- 5) No se usa FOR UPDATE porque el borrador no consume cupo. Tampoco se hace
--    COMMIT: lo decide quien llame al procedimiento.
CREATE OR REPLACE PROCEDURE SP_CREAR_PEDIDO (
    p_id_cliente  IN  NUMBER,
    p_id_pedido   OUT NUMBER
) IS
  vc_activo  CLIENTE.activo%TYPE;
  vn_cupo    CLIENTE.cupo_credito%TYPE;
  vn_saldo   CLIENTE.saldo_pendiente%TYPE;
BEGIN
    -- leer los datos del cliente
    BEGIN
        SELECT activo, cupo_credito, saldo_pendiente
          INTO vc_activo, vn_cupo, vn_saldo
          FROM CLIENTE
         WHERE id_cliente = p_id_cliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20101,
                'El cliente ' || p_id_cliente || ' no existe');
    END;
    --  rechazar cliente inactivo
    IF vc_activo = 'N' THEN
        RAISE_APPLICATION_ERROR(-20102,
            'El cliente ' || p_id_cliente || ' esta inactivo');
    END IF;
    -- rechazar cliente sin cupo disponible
    IF vn_cupo - vn_saldo <= 0 THEN
        RAISE_APPLICATION_ERROR(-20103,
            'El cliente ' || p_id_cliente || ' no tiene cupo de credito disponible');
    END IF;
    --crear el pedido en estado BORRADOR
    p_id_pedido := SEQ_PEDIDO.NEXTVAL;

    INSERT INTO PEDIDO (id_pedido, id_cliente, estado)
    VALUES (p_id_pedido, p_id_cliente, 'BORRADOR');
    NULL;
END SP_CREAR_PEDIDO;


-- prueba
DECLARE
    vn_pedido NUMBER;
BEGIN
    -- Cliente activo y con cupo: crea el pedido
    SP_CREAR_PEDIDO(501, vn_pedido);
    DBMS_OUTPUT.PUT_LINE('1) Pedido creado con id: ' || vn_pedido);

    -- Cliente inactivo: debe dar error -20102
    BEGIN
        SP_CREAR_PEDIDO(506, vn_pedido);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('2) Inactivo - ' || SQLERRM);
    END;

    -- Cliente sin cupo: debe dar error -20103
    BEGIN
        SP_CREAR_PEDIDO(505, vn_pedido);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('3) Sin cupo - ' || SQLERRM);
    END;

    -- Cliente que no existe: debe dar error -20101
    BEGIN
        SP_CREAR_PEDIDO(999, vn_pedido);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('4) No existe - ' || SQLERRM);
    END;
END;
/

-- Para ver que el pedido quedó en BORRADOR 
SELECT id_pedido, id_cliente, estado, total
  FROM PEDIDO
 WHERE estado = 'BORRADOR'
 ORDER BY id_pedido DESC;

ROLLBACK;
/

--==============================================================================
-- PARTE 2 — FUNCIONES                                         (8 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 2.1 (2 pts)
-- FN_STOCK_DISPONIBLE
-- Retorna la cantidad disponible de un producto. Si se indica bodega, devuelve
-- el saldo de esa bodega; si p_id_bodega llega nulo, el consolidado de todas.
-- Un producto inexistente debe retornar cero y no una excepcion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Una sola consulta resuelve los dos casos con
--    (p_id_bodega IS NULL OR id_bodega = p_id_bodega): si la bodega es nula
--    se suman todas, y si llega una se suma solo esa.
-- 2) Se usa SUM con NVL. Si no hay filas, SUM devuelve NULL; NVL lo vuelve 0.
-- 3) Como SUM siempre devuelve una fila, no se produce NO_DATA_FOUND y el
--    producto inexistente retorna 0 sin necesitar manejo de excepciones.
-- 4) No se filtra por bodega activa porque el enunciado no lo pide y la vista
--    V_STOCK_CONSOLIDADO tampoco lo hace.

CREATE OR REPLACE FUNCTION FN_STOCK_DISPONIBLE (
    p_id_producto IN NUMBER,
    p_id_bodega   IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    vn_stock NUMBER;
BEGIN
    -- sumar la existencia
    SELECT NVL(SUM(cantidad), 0)
      INTO vn_stock
      FROM EXISTENCIA
     WHERE id_producto = p_id_producto
       AND (p_id_bodega IS NULL OR id_bodega = p_id_bodega);

    -- devolver el resultado
    RETURN vn_stock;
END FN_STOCK_DISPONIBLE;
/
-- Prueba
BEGIN
    DBMS_OUTPUT.PUT_LINE('1) Producto 1001, bodega 1: ' || FN_STOCK_DISPONIBLE(1001, 1));
    DBMS_OUTPUT.PUT_LINE('2) Producto 1001, todas las bodegas: ' || FN_STOCK_DISPONIBLE(1001, NULL));
    DBMS_OUTPUT.PUT_LINE('3) Producto 1001, bodega 3 (sin existencia): ' || FN_STOCK_DISPONIBLE(1001, 3));
    DBMS_OUTPUT.PUT_LINE('4) Producto 9999 (no existe): ' || FN_STOCK_DISPONIBLE(9999));
END;
/

------------------------------------------------------------------- 2.2 (2 pts)
-- FN_CUPO_DISPONIBLE
-- Retorna el cupo de credito disponible del cliente, entendido como cupo menos
-- saldo pendiente. Un cliente inactivo retorna cero y el resultado nunca puede
-- ser negativo.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Se lee activo, cupo y saldo con un solo SELECT por llave primaria.
-- 2) El cliente inactivo retorna 0 antes de calcular, porque puede tener cupo
--    libre pero no puede comprar a credito.
-- 3) GREATEST(cupo - saldo, 0) evita resultados negativos. La tabla no
--    impide que el saldo supere al cupo, por eso la proteccion es necesaria.
-- 4) Si el cliente no existe se retorna 0 y no un error, para que la funcion
--    no detenga una consulta SQL que la use (punto 2.4).
CREATE OR REPLACE FUNCTION FN_CUPO_DISPONIBLE (
    p_id_cliente IN NUMBER
) RETURN NUMBER IS
 vc_activo  CLIENTE.activo%TYPE;
    vn_cupo    CLIENTE.cupo_credito%TYPE;
    vn_saldo   CLIENTE.saldo_pendiente%TYPE;
BEGIN
-- leer los datos del cliente
    BEGIN
        SELECT activo, cupo_credito, saldo_pendiente
          INTO vc_activo, vn_cupo, vn_saldo
          FROM CLIENTE
         WHERE id_cliente = p_id_cliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;
-- cliente inactivo
    IF vc_activo = 'N' THEN
        RETURN 0;
    END IF;
-- calcular el cupo sin que sea negativo
    RETURN GREATEST(vn_cupo - vn_saldo, 0);
END FN_CUPO_DISPONIBLE;
/
-- Prueba
BEGIN
    DBMS_OUTPUT.PUT_LINE('1) Cliente 501 (activo, con cupo): ' || FN_CUPO_DISPONIBLE(501));
    DBMS_OUTPUT.PUT_LINE('2) Cliente 505 (cupo agotado):     ' || FN_CUPO_DISPONIBLE(505));
    DBMS_OUTPUT.PUT_LINE('3) Cliente 506 (inactivo):         ' || FN_CUPO_DISPONIBLE(506));
    DBMS_OUTPUT.PUT_LINE('4) Cliente 999 (no existe):        ' || FN_CUPO_DISPONIBLE(999));

    -- Saldo mayor al cupo: se fuerza el caso y se deshace al final
    UPDATE CLIENTE SET saldo_pendiente = 9000000 WHERE id_cliente = 505;
    DBMS_OUTPUT.PUT_LINE('5) Cliente 505 con saldo mayor al cupo: ' || FN_CUPO_DISPONIBLE(505));
    ROLLBACK;
END;
/
------------------------------------------------------------------- 2.3 (3 pts)
-- FN_CALCULAR_DESCUENTO
-- Retorna el VALOR en pesos del descuento aplicable, segun estas reglas
-- acumulables:
--     Monto mayor o igual a 2.000.000 ................. 8%
--     Monto entre 800.000 y 1.999.999 ................. 5%
--     Monto menor a 800.000 ........................... 0%
--     Adicional si el cliente no tiene saldo pendiente . 2%
--     Tope maximo acumulado ........................... 10%
-- La funcion retorna el valor del descuento, no el porcentaje.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Los tramos se escriben con >= y se pregunta primero por el mas alto, asi
--    un monto como 1.999.999,50 tambien cae en el 5% y no queda en un hueco.
-- 2) El 2% adicional se suma al porcentaje del monto (reglas acumulables),
--    tambien cuando el monto es menor a 800.000, porque el enunciado no pone
--    un minimo para ese adicional.
-- 3) Si el cliente no existe se captura NO_DATA_FOUND y solo se aplica el
--    descuento por monto, para que la funcion no se caiga.
-- 4) LEAST aplica el tope de 10%. Hoy el maximo es 8% + 2% = 10%, pero se deja
--    porque el enunciado lo exige y protege si las reglas cambian.
-- 5) Se retorna el VALOR (monto * porcentaje / 100) y no el porcentaje, con
--    ROUND a 2 decimales como las columnas de dinero.

CREATE OR REPLACE FUNCTION FN_CALCULAR_DESCUENTO (
    p_id_cliente IN NUMBER,
    p_monto      IN NUMBER
) RETURN NUMBER IS
    vn_pct    NUMBER := 0;                  
    vn_saldo  CLIENTE.saldo_pendiente%TYPE; 
BEGIN
    -- porcentaje segun el monto
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN 0;
    END IF;

    IF p_monto >= 2000000 THEN
        vn_pct := 8;
    ELSIF p_monto >= 800000 THEN
        vn_pct := 5;
    ELSE
        vn_pct := 0;
    END IF;
    -- adicional por cliente sin saldo pendiente
    BEGIN
        SELECT saldo_pendiente
          INTO vn_saldo
          FROM CLIENTE
         WHERE id_cliente = p_id_cliente;

        IF vn_saldo = 0 THEN
            vn_pct := vn_pct + 2;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;  
    END;
-- tope de 10% y valor en pesos
    vn_pct := LEAST(vn_pct, 10);

    RETURN ROUND(p_monto * vn_pct / 100, 2);
END FN_CALCULAR_DESCUENTO;
/
-- prueba
BEGIN
    DBMS_OUTPUT.PUT_LINE('1) Cliente 501, monto 3.000.000 (8%):        ' || FN_CALCULAR_DESCUENTO(501, 3000000));
    DBMS_OUTPUT.PUT_LINE('2) Cliente 503, monto 3.000.000 (8% + 2%):   ' || FN_CALCULAR_DESCUENTO(503, 3000000));
    DBMS_OUTPUT.PUT_LINE('3) Cliente 501, monto 1.000.000 (5%):        ' || FN_CALCULAR_DESCUENTO(501, 1000000));
    DBMS_OUTPUT.PUT_LINE('4) Cliente 503, monto 1.000.000 (5% + 2%):   ' || FN_CALCULAR_DESCUENTO(503, 1000000));
    DBMS_OUTPUT.PUT_LINE('5) Cliente 501, monto 500.000 (0%):          ' || FN_CALCULAR_DESCUENTO(501, 500000));
    DBMS_OUTPUT.PUT_LINE('6) Cliente 503, monto 500.000 (0% + 2%):     ' || FN_CALCULAR_DESCUENTO(503, 500000));
    DBMS_OUTPUT.PUT_LINE('7) Cliente 501, monto 800.000 (limite, 5%):  ' || FN_CALCULAR_DESCUENTO(501, 800000));
    DBMS_OUTPUT.PUT_LINE('8) Cliente 501, monto 2.000.000 (limite, 8%):' || FN_CALCULAR_DESCUENTO(501, 2000000));
END;
/

------------------------------------------------------------------- 2.4 (1 pt)
-- Escriba una consulta que liste los clientes activos con su cupo disponible,
-- usando la funcion del punto 2.2, ordenados de mayor a menor.
-- Explique por que una funcion definida por el usuario puede invocarse desde
-- una sentencia SQL y que restriccion debe cumplir para poder hacerlo.
-------------------------------------------------------------------------------
-- RESPUESTA: Una funcion almacenada puede invocarse desde SQL porque devuelve un solo
-- valor de un tipo SQL (NUMBER, VARCHAR2, DATE), asi que el motor SQL la
-- trata como una expresion mas, igual que UPPER o ROUND, y la ejecuta una vez
-- por cada fila.
-- Restriccion: dentro de una consulta SELECT la funcion no puede modificar la
-- base de datos (no puede hacer INSERT, UPDATE ni DELETE, ni COMMIT o
-- ROLLBACK). Si lo hace, Oracle da el error ORA-14551. Ademas, sus parametros
-- deben ser solo de entrada (IN) y de tipos SQL.
-- FN_CUPO_DISPONIBLE cumple esto: solo lee la tabla CLIENTE, tiene un unico
-- parametro IN y retorna NUMBER.
SELECT c.id_cliente,
       c.nombre,
       FN_CUPO_DISPONIBLE(c.id_cliente) AS cupo_disponible
  FROM CLIENTE c
 WHERE c.activo = 'S'
 ORDER BY cupo_disponible DESC;


--==============================================================================
-- PARTE 3 — CURSORES                                         (10 puntos / 90 min)
--==============================================================================

------------------------------------------------------------------- 3.1 (2 pts)
-- Bloque anonimo que recorra, con un CURSOR EXPLICITO, los productos cuyo stock
-- consolidado este por debajo del stock minimo, e imprima un reporte con codigo,
-- nombre, stock actual, stock minimo y unidades faltantes, mas el total de
-- productos en esa condicion.
-- Debe usar OPEN, FETCH y CLOSE de forma explicita. El ciclo FOR implicito no se
-- acepta en este punto.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- 1) Cursor explicito: OPEN ejecuta la consulta, cada FETCH trae una fila y el
--    ciclo sale con EXIT WHEN %NOTFOUND. El EXIT va justo despues del FETCH; si
--    va antes, la ultima fila se procesaria dos veces. CLOSE libera la memoria.
-- 2) El stock consolidado sale de V_STOCK_CONSOLIDADO, que ya suma todas las
--    bodegas, asi no se repite ese calculo.
-- 3) Se filtra activo = 'S' porque un producto inactivo ya no se vende y no hay
--    que reponerlo (HM-0004 saldria sin ese filtro). La vista no trae la columna
--    activo, por eso se une con PRODUCTO.
-- 4) faltante = stock_minimo - stock_total (unidades a conseguir). Se ordena del
--    que mas falta al que menos, y el codigo desempata.
-- 5) %ROWTYPE da una variable por cada columna del cursor sin declararlas una
--    por una.
-- 6) Concurrencia: Oracle fija el resultado en el momento del OPEN, asi que
--    cambios de otras sesiones durante el reporte no lo alteran. El cursor solo
--    lee, no bloquea filas.
-- 7) Volumen: la vista suma toda la existencia en cada ejecucion. Con muchos
--    productos conviene un indice por id_producto en EXISTENCIA, y para
--    reportes muy grandes usar BULK COLLECT con LIMIT.
-- 8) Error: si algo falla dentro del ciclo se salta el CLOSE, por eso el
--    EXCEPTION lo cierra si sigue abierto (%ISOPEN) y RAISE vuelve a lanzar el
--    error para no ocultarlo.
DECLARE
    CURSOR cur_bajo_stock IS
        SELECT v.codigo,
               v.producto,
               v.stock_total,
               v.stock_minimo,
               v.stock_minimo - v.stock_total AS faltante
          FROM V_STOCK_CONSOLIDADO v
          JOIN PRODUCTO p ON p.id_producto = v.id_producto
         WHERE p.activo = 'S'
           AND v.stock_total < v.stock_minimo
         ORDER BY faltante DESC, v.codigo;

    r_Producto   cur_bajo_stock%ROWTYPE;
    vnProductos  PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Productos activos por debajo del stock minimo');
    DBMS_OUTPUT.PUT_LINE(RPAD('CODIGO', 10) || RPAD('PRODUCTO', 32) ||
                         LPAD('STOCK', 8) || LPAD('MINIMO', 8) || LPAD('FALTAN', 9));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');

    OPEN cur_bajo_stock;
    LOOP
        FETCH cur_bajo_stock INTO r_Producto;
        EXIT WHEN cur_bajo_stock%NOTFOUND;

        vnProductos := vnProductos + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r_Producto.codigo, 10) ||
                             RPAD(SUBSTR(r_Producto.producto, 1, 30), 32) ||
                             LPAD(r_Producto.stock_total, 8) ||
                             LPAD(r_Producto.stock_minimo, 8) ||
                             LPAD(r_Producto.faltante, 9));
    END LOOP;
    CLOSE cur_bajo_stock;

    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total de productos por debajo del minimo: ' || vnProductos);
EXCEPTION
    WHEN OTHERS THEN
        IF cur_bajo_stock%ISOPEN THEN
            CLOSE cur_bajo_stock;
        END IF;
        RAISE;
END;
/

/*
Autores: Brayan David Herrera Acero

Fecha: 06/10/2026
Descripción: Taller PL/SQL - Modelo de inventario y ventas. Solución de los ejercicios 09 a 16 (puntos 3.2 a 4.4): cursores y manejo de excepciones.
 
20261006- se creo el script con la solucion de los puntos 3.2 a 4.4
 */
 
 ------------------------------------------------------------------- 3.2 (2 pts)
-- Bloque anonimo con un CURSOR PARAMETRIZADO que reciba identificador de cliente
-- y un rango de fechas, y muestre los pedidos CONFIRMADOS de ese cliente en ese
-- rango, con su total y la cantidad de lineas de cada pedido.
-- Pruebelo con el cliente 501 entre 2026-01-01 y 2026-12-31.
-- Los parametros deben declararse en el cursor, no tomarse del alcance del bloque.
-------------------------------------------------------------------------------
-- JUSTIFICACION:

-- Se usa un cursor explicito parametrizado porque la misma consulta debe servir
-- para cualquier cliente y cualquier rango sin reescribirla. Los tres parametros
-- se declaran en el encabezado del cursor y se enlazan al ejecutar OPEN, de modo
-- que el cursor no depende de variables del bloque: puede abrirse varias veces
-- con valores distintos y su definicion queda cerrada sobre si misma.
-- Se usa LEFT JOIN con COUNT(d.linea) para que un pedido sin lineas aparezca con
-- cero en lugar de desaparecer del resultado, como ocurriria con un JOIN interno.
-- El limite superior se escribe como "< p_fecha_hasta + 1" y no con BETWEEN
-- porque fecha_pedido es DATE y puede traer hora (su valor por defecto es
-- SYSDATE); asi el ultimo dia del rango queda incluido completo.
-- El filtro de estado deja unicamente los pedidos CONFIRMADOS, por lo que los
-- pedidos en BORRADOR o ANULADO del mismo cliente no se listan.
--
--
DECLARE
    CURSOR cur_pedidos_cliente (p_id_cliente  NUMBER,
                                p_fecha_desde DATE,
                                p_fecha_hasta DATE) IS
        SELECT p.id_pedido,
               p.fecha_pedido,
               p.total,
               COUNT(d.linea) AS cantidad_lineas
          FROM PEDIDO p
          LEFT JOIN DETALLE_PEDIDO d ON d.id_pedido = p.id_pedido
         WHERE p.id_cliente   = p_id_cliente
           AND p.estado       = 'CONFIRMADO'
           AND p.fecha_pedido >= p_fecha_desde
           AND p.fecha_pedido <  p_fecha_hasta + 1
         GROUP BY p.id_pedido, p.fecha_pedido, p.total
         ORDER BY p.fecha_pedido, p.id_pedido;
 
    r_Pedido  cur_pedidos_cliente%ROWTYPE;
    vnPedidos PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Pedidos CONFIRMADOS del cliente 501 entre 2026-01-01 y 2026-12-31');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------');
 
    OPEN cur_pedidos_cliente(501, DATE '2026-01-01', DATE '2026-12-31');
    LOOP
        FETCH cur_pedidos_cliente INTO r_Pedido;
        EXIT WHEN cur_pedidos_cliente%NOTFOUND;
 
        vnPedidos := vnPedidos + 1;
        DBMS_OUTPUT.PUT_LINE('Pedido ' || LPAD(r_Pedido.id_pedido, 3) ||
                             ' | fecha '  || TO_CHAR(r_Pedido.fecha_pedido, 'YYYY-MM-DD') ||
                             ' | total '  || LPAD(TO_CHAR(r_Pedido.total, 'FM999G999G990'), 11) ||
                             ' | lineas ' || r_Pedido.cantidad_lineas);
    END LOOP;
    CLOSE cur_pedidos_cliente;
 
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Pedidos encontrados: ' || vnPedidos);
END;
/
 

------------------------------------------------------------------- 3.3 (3 pts)
-- Bloque anonimo con un CURSOR FOR UPDATE que recorra los productos de una
-- categoria y ajuste su precio un porcentaje dado, usando WHERE CURRENT OF.
--   * No debe modificar productos inactivos
--   * El precio resultante no puede quedar por debajo del costo mas el margen
--     minimo de la categoria
-- Explique que bloqueo genera FOR UPDATE, cuanto dura, y por que WHERE CURRENT OF
-- es preferible a un UPDATE por clave primaria.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- QUE BLOQUEO GENERA FOR UPDATE. Bloquea de forma exclusiva las FILAS que
-- devuelve el cursor, no la tabla completa. Otras sesiones pueden seguir
-- leyendo esas filas y pueden modificar las demas filas de la tabla, pero no
-- pueden modificar ni bloquear las que este cursor tomo: quedan esperando. El
-- bloqueo se toma al ejecutar OPEN, sobre todas las filas del resultado a la vez,
-- y no al llegar a cada una con el FETCH.
--
-- CUANTO DURA. Hasta que la transaccion termina con COMMIT o con ROLLBACK.
-- Cerrar el cursor con CLOSE no lo libera, ni tampoco terminar el bloque: lo que
-- libera los bloqueos es el cierre de la transaccion. De ahi que el COMMIT se
-- haga despues del END LOOP y no dentro del ciclo; si se hiciera dentro, se
-- liberarian los bloqueos y el siguiente FETCH fallaria con ORA-01002 (lectura
-- fuera de secuencia).
--
-- POR QUE WHERE CURRENT OF ES PREFERIBLE A UN UPDATE POR CLAVE PRIMARIA. Porque
-- actualiza la fila por su ROWID, la direccion fisica que Oracle ya conoce de la
-- lectura del cursor. Un UPDATE por clave primaria obliga a buscar otra vez la
-- fila por el indice, es decir un segundo acceso por cada fila del recorrido.
-- Ademas garantiza que se modifica exactamente la fila que se leyo y se bloqueo,
-- sin depender de que la condicion del WHERE se escriba bien ni de que el valor
-- de la clave siga siendo el mismo. Y es mas claro de leer: expresa "actualice la
-- fila en la que voy", que es justamente lo que se quiere hacer.
--
-- DECISIONES DE DISENO. Los productos inactivos se excluyen en el WHERE del
-- cursor (activo = 'S') y no con un IF dentro del ciclo, para que esas filas ni
-- siquiera lleguen a bloquearse. El piso de precio se calcula como
-- costo_unitario * (1 + margen_minimo / 100), porque margen_minimo esta en
-- porcentaje segun la restriccion ck_categoria_margen, y se aplica con GREATEST:
-- si el precio ajustado queda por debajo del piso, se deja el piso.
--

SET SERVEROUTPUT ON
DECLARE
    -- porcentaje de ajuste: negativo = descuento, positivo = incremento
    vnPorcentaje  NUMBER := -22;
    vnIdCategoria NUMBER := 1;

    CURSOR cur_productos_categoria (p_id_categoria NUMBER) IS
        SELECT p.id_producto,
               p.codigo,
               p.nombre,
               p.precio_unitario,
               p.costo_unitario,
               c.margen_minimo
          FROM PRODUCTO p
          JOIN CATEGORIA c ON c.id_categoria = p.id_categoria
         WHERE p.id_categoria = p_id_categoria
           AND p.activo       = 'S'
         ORDER BY p.id_producto
           FOR UPDATE OF p.precio_unitario;

    r_Producto     cur_productos_categoria%ROWTYPE;
    vnPrecioPiso   NUMBER;
    vnPrecioCalc   NUMBER;
    vnPrecioFinal  NUMBER;
    vnAjustados    PLS_INTEGER := 0;
    vnTopados      PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Ajuste de ' || vnPorcentaje || '% en la categoria ' || vnIdCategoria);
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');

    OPEN cur_productos_categoria(vnIdCategoria);
    LOOP
        FETCH cur_productos_categoria INTO r_Producto;
        EXIT WHEN cur_productos_categoria%NOTFOUND;

        vnPrecioPiso  := ROUND(r_Producto.costo_unitario * (1 + r_Producto.margen_minimo / 100), 2);
        vnPrecioCalc  := ROUND(r_Producto.precio_unitario * (1 + vnPorcentaje / 100), 2);
        vnPrecioFinal := GREATEST(vnPrecioCalc, vnPrecioPiso);

        UPDATE PRODUCTO
           SET precio_unitario = vnPrecioFinal
         WHERE CURRENT OF cur_productos_categoria;

        vnAjustados := vnAjustados + 1;
        IF vnPrecioFinal > vnPrecioCalc THEN
            vnTopados := vnTopados + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(r_Producto.codigo, 10) ||
                             RPAD(SUBSTR(r_Producto.nombre, 1, 30), 32) ||
                             'antes ' || LPAD(TO_CHAR(r_Producto.precio_unitario, 'FM999G999G990'), 9) ||
                             ' | piso '  || LPAD(TO_CHAR(vnPrecioPiso,  'FM999G999G990'), 9) ||
                             ' | ahora ' || LPAD(TO_CHAR(vnPrecioFinal, 'FM999G999G990'), 9) ||
                             CASE WHEN vnPrecioFinal > vnPrecioCalc
                                  THEN '  <- limitado por el margen minimo' END);
    END LOOP;
    CLOSE cur_productos_categoria;

    COMMIT;   -- fuera del ciclo: un COMMIT intermedio liberaria los bloqueos

    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Productos ajustados: ' || vnAjustados ||
                         ' (limitados por el margen minimo: ' || vnTopados || ')');
END;
/
SELECT id_producto, codigo, nombre, activo, precio_unitario, costo_unitario
  FROM PRODUCTO
 WHERE id_categoria = 1
 ORDER BY id_producto;

------------------------------------------------------------------- 3.4 (2 pts)
-- SP_LISTAR_MOVIMIENTOS
-- Procedimiento que reciba un identificador de producto y devuelva un
-- SYS_REFCURSOR con los movimientos de inventario de ese producto, ordenados
-- por fecha. Incluya un bloque anonimo que consuma el cursor devuelto y lo cierre.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--  un procedimiento almacenado  decide qué se consulta y abre la consulta. 
-- Un SYS_REFCURSOR es una variable que guarda una consulta ya abierta y que se
-- puede pasar como parametro. Eso permite separar al programa que decide la
-- consulta del programa que recorre las filas: el procedimiento solo ejecuta
-- OPEN ... FOR y entrega el cursor, y el bloque anonimo lo recorre y lo cierra.
-- El procedimiento NO cierra el cursor a proposito: si lo hiciera, quien lo
-- recibe tendria un cursor inutilizable y el primer FETCH fallaria con ORA-01001.
-- Cerrarlo es responsabilidad del consumidor, y por eso el bloque ejecuta CLOSE
-- al terminar el recorrido.
-- Sobre un SYS_REFCURSOR no se puede usar un FOR ... IN cursor, que solo admite
-- cursores declarados; hay que declarar una variable por cada columna del SELECT,
-- en el mismo orden y tipo, y recorrerlo con FETCH controlando la salida con
-- %NOTFOUND. Las variables se declaran con %TYPE para que tomen el tipo de su
-- columna y el bloque no se rompa si el modelo cambia.

CREATE OR REPLACE PROCEDURE SP_LISTAR_MOVIMIENTOS (
    p_id_producto IN  NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN P_CURSOR FOR
        SELECT m.id_movimiento,
               m.fecha_mov,
               m.tipo,
               m.cantidad,
               m.id_bodega,
               m.id_pedido,
               m.observacion
        FROM MOVIMIENTO_INVENTARIO m
         WHERE m.id_producto = p_id_producto
         ORDER BY m.fecha_mov, m.id_movimiento;
    -- el cursor NO se cierra aqui: lo cierra quien lo consume
    
END SP_LISTAR_MOVIMIENTOS;
/

-- Bloque consumidor:
DECLARE
     cur_movimientos SYS_REFCURSOR;

    vnIdMovimiento  MOVIMIENTO_INVENTARIO.id_movimiento%TYPE;
    vdFechaMov      MOVIMIENTO_INVENTARIO.fecha_mov%TYPE;
    vvTipo          MOVIMIENTO_INVENTARIO.tipo%TYPE;
    vnCantidad      MOVIMIENTO_INVENTARIO.cantidad%TYPE;
    vnIdBodega      MOVIMIENTO_INVENTARIO.id_bodega%TYPE;
    vnIdPedido      MOVIMIENTO_INVENTARIO.id_pedido%TYPE;
    vvObservacion   MOVIMIENTO_INVENTARIO.observacion%TYPE;

    vnIdProducto    NUMBER := 1001;
    vnFilas         PLS_INTEGER := 0;
BEGIN
SP_LISTAR_MOVIMIENTOS(vnIdProducto, cur_movimientos);

    DBMS_OUTPUT.PUT_LINE('Movimientos del producto ' || vnIdProducto);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');

    LOOP
        FETCH cur_movimientos
         INTO vnIdMovimiento, vdFechaMov, vvTipo, vnCantidad,
              vnIdBodega, vnIdPedido, vvObservacion;
        EXIT WHEN cur_movimientos%NOTFOUND;

        vnFilas := vnFilas + 1;
        DBMS_OUTPUT.PUT_LINE('Mov ' || LPAD(vnIdMovimiento, 3) ||
                             ' | ' || TO_CHAR(vdFechaMov, 'YYYY-MM-DD') ||
                             ' | ' || RPAD(vvTipo, 8) ||
                             ' | cant ' || LPAD(vnCantidad, 4) ||
                             ' | bodega ' || vnIdBodega ||
                             ' | pedido ' || NVL(TO_CHAR(vnIdPedido), '-') ||
                             ' | ' || vvObservacion);
    END LOOP;

    CLOSE cur_movimientos;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Movimientos listados: ' || vnFilas);
EXCEPTION
    WHEN OTHERS THEN
        IF cur_movimientos%ISOPEN THEN
            CLOSE cur_movimientos;
        END IF;
        RAISE;
END;
/
------------------------------------------------------------------- 3.5 (1 pt)
-- Bloque anonimo que cargue con BULK COLLECT los productos de una categoria en
-- una coleccion y use FORALL para actualizar su stock minimo.
-- Explique que costo concreto elimina esta tecnica y a partir de que volumen
-- empieza a notarse.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Oracle tiene dos motores: uno ejecuta la logica procedural (ciclos, IF,
-- variables) y otro las sentencias SQL. Cada paso de uno a otro es un cambio de
-- contexto y tiene un costo fijo. En un ciclo fila a fila ese costo se paga una
-- vez por fila; BULK COLLECT trae todas las filas en un solo viaje y FORALL envia
-- todas las actualizaciones en otro, de modo que el cambio de contexto ocurre una
-- sola vez. Eso es lo que elimina la tecnica: no ahorra disco ni bloqueos.
-- Con decenas de filas la diferencia es imperceptible. Empieza a notarse hacia
-- los miles y se vuelve decisiva en cientos de miles.
DECLARE
    TYPE t_ids    IS TABLE OF PRODUCTO.id_producto%TYPE  INDEX BY PLS_INTEGER;
    TYPE t_stocks IS TABLE OF PRODUCTO.stock_minimo%TYPE INDEX BY PLS_INTEGER;

    vnIdCategoria NUMBER := 3;
    vIds          t_ids;
    vStocks       t_stocks;
BEGIN
    SELECT id_producto,
           CEIL(stock_minimo * 1.1)        -- nuevo stock minimo: 10% mas alto
      BULK COLLECT INTO vIds, vStocks
      FROM PRODUCTO
     WHERE id_categoria = vnIdCategoria
       AND activo       = 'S';

    DBMS_OUTPUT.PUT_LINE('Productos leidos con BULK COLLECT: ' || vIds.COUNT);

    FORALL k IN 1 .. vIds.COUNT
        UPDATE PRODUCTO
           SET stock_minimo = vStocks(k)
         WHERE id_producto  = vIds(k);

    DBMS_OUTPUT.PUT_LINE('Filas actualizadas con FORALL   : ' || SQL%ROWCOUNT);
    COMMIT;

    FOR r_Producto IN (SELECT codigo, nombre, stock_minimo
                         FROM PRODUCTO
                        WHERE id_categoria = vnIdCategoria
                          AND activo       = 'S'
                        ORDER BY id_producto) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r_Producto.codigo, 10) ||
                             RPAD(SUBSTR(r_Producto.nombre, 1, 30), 32) ||
                             'stock minimo: ' || r_Producto.stock_minimo);
    END LOOP;
END;
/

--==============================================================================
-- PARTE 4 — MANEJO DE EXCEPCIONES                             (9 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 4.1 (2 pts)
-- FN_PRECIO_PRODUCTO
-- Funcion que reciba el CODIGO de un producto y retorne su precio, manejando
-- explicitamente NO_DATA_FOUND y TOO_MANY_ROWS, con retorno de -1 y -2
-- respectivamente, e imprimiendo un mensaje descriptivo en cada caso.
-- Explique en que situacion real se produciria TOO_MANY_ROWS sobre esta tabla,
-- considerando las restricciones que hoy tiene.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- JUSTIFICACION:
-- Un SELECT INTO exige exactamente una fila: si no encuentra ninguna levanta
-- NO_DATA_FOUND y si encuentra varias levanta TOO_MANY_ROWS. Se manejan por
-- separado porque son situaciones distintas: la primera es un dato que no existe
-- (un codigo mal digitado, por ejemplo) y la segunda es una inconsistencia del
-- modelo.
-- Con las restricciones que la tabla tiene HOY, TOO_MANY_ROWS no puede ocurrir en
-- esta consulta: la restriccion uk_producto_codigo declara codigo como UNIQUE, de
-- modo que un filtro por igualdad sobre esa columna devuelve a lo sumo una fila.
-- Solo se produciria si esa restriccion dejara de actuar, por ejemplo si se
-- deshabilita para una carga masiva y queda sin volver a habilitar, o si se
-- elimina al reestructurar la tabla. Tambien aparece si la busqueda deja de ser
-- por igualdad exacta: con UPPER(codigo) = UPPER(p_codigo) o con LIKE, los
-- valores 'HM-0001' y 'hm-0001' son distintos para la restriccion UNIQUE pero
-- iguales para la consulta.
-- El manejador se escribe aunque hoy no se active: protege a la funcion de un
-- cambio futuro en el modelo en lugar de confiar en el estado actual.


CREATE OR REPLACE FUNCTION FN_PRECIO_PRODUCTO (
    p_codigo IN VARCHAR2
) RETURN NUMBER IS
    vnPrecio PRODUCTO.precio_unitario%TYPE;
BEGIN
    SELECT precio_unitario
      INTO vnPrecio
      FROM PRODUCTO
     WHERE codigo = p_codigo;

    RETURN vnPrecio;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No existe ningun producto con el codigo ' || p_codigo);
        RETURN -1;
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Hay mas de un producto con el codigo ' || p_codigo ||
                             ': la unicidad del codigo no se esta cumpliendo');
        RETURN -2;
END FN_PRECIO_PRODUCTO;
/

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE('Caso 1 - codigo existente   (SI-0001): ' || FN_PRECIO_PRODUCTO('SI-0001'));
    DBMS_OUTPUT.PUT_LINE('Caso 2 - codigo inexistente (ZZ-9999): ' || FN_PRECIO_PRODUCTO('ZZ-9999'));
END;
/
------------------------------------------------------------------- 4.2 (2 pts)
-- SP_VALIDAR_DESPACHO
-- Procedimiento que verifique si puede despacharse una cantidad de un producto
-- desde una bodega. Debe declarar una EXCEPCION PROPIA, levantarla con RAISE
-- cuando la cantidad solicitada supere el disponible, y capturarla en el bloque
-- EXCEPTION.
-- Argumente por que conviene nombrar esa condicion en lugar de resolverla con un
-- condicional.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Nombrar la condicion separa DETECTAR el problema de DECIDIR que hacer con el.
-- El IF solo sabe que la cantidad no alcanza; con una excepcion con nombre, el
-- punto donde se detecta levanta e_stock_insuficiente y el bloque EXCEPTION
-- concentra la reaccion, de modo que cambiarla (registrar en LOG_ERRORES,
-- notificar, propagar) no obliga a tocar la logica de validacion.
-- Ademas, una excepcion se propaga sola: si manana este procedimiento se llama
-- desde otro, no hay que inventar codigos de retorno ni revisar una bandera en
-- cada nivel. Quien quiera atenderla la captura por su nombre y quien no, la deja
-- subir. Un IF obliga a que cada llamador recuerde comprobar el resultado, y
-- olvidarlo pasa inadvertido.
-- Por ultimo, el nombre documenta la regla de negocio: e_stock_insuficiente se
-- lee mejor que una comparacion suelta.
-- Se maneja tambien NO_DATA_FOUND porque la ausencia de fila en EXISTENCIA es una
-- condicion distinta: no es que falte stock, es que ese producto nunca se ha
-- manejado en esa bodega.


CREATE OR REPLACE PROCEDURE SP_VALIDAR_DESPACHO (
    p_id_producto IN NUMBER,
    p_id_bodega   IN NUMBER,
    p_cantidad    IN NUMBER
) IS
    e_stock_insuficiente EXCEPTION;

    vnDisponible EXISTENCIA.cantidad%TYPE;
BEGIN
    SELECT cantidad
      INTO vnDisponible
      FROM EXISTENCIA
     WHERE id_producto = p_id_producto
       AND id_bodega   = p_id_bodega;

    IF p_cantidad > vnDisponible THEN
        RAISE e_stock_insuficiente;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Despacho VIABLE: producto ' || p_id_producto ||
                         ', bodega ' || p_id_bodega ||
                         ', solicitado ' || p_cantidad ||
                         ', disponible ' || vnDisponible);
EXCEPTION
    WHEN e_stock_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('Despacho NO VIABLE: producto ' || p_id_producto ||
                             ', bodega ' || p_id_bodega ||
                             ', solicitado ' || p_cantidad ||
                             ', disponible ' || vnDisponible ||
                             ' (faltan ' || (p_cantidad - vnDisponible) || ')');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Despacho NO VIABLE: el producto ' || p_id_producto ||
                             ' no tiene existencia registrada en la bodega ' || p_id_bodega);
END SP_VALIDAR_DESPACHO;
/

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Caso 1: cantidad dentro del disponible ---');
    SP_VALIDAR_DESPACHO(1005, 1, 3);

    DBMS_OUTPUT.PUT_LINE('--- Caso 2: cantidad mayor al disponible (excepcion propia) ---');
    SP_VALIDAR_DESPACHO(1005, 1, 10);

    DBMS_OUTPUT.PUT_LINE('--- Caso 3: sin existencia registrada en esa bodega ---');
    SP_VALIDAR_DESPACHO(1004, 3, 1);
END;
/

------------------------------------------------------------------- 4.3 (2 pts)
-- SP_ANULAR_PEDIDO
-- Procedimiento que anule un pedido, usando RAISE_APPLICATION_ERROR con estos
-- codigos:
--     -20010  el pedido no existe
--     -20011  el pedido ya esta anulado
--     -20012  el pedido tiene mas de 30 dias
-- Explique la diferencia entre RAISE y RAISE_APPLICATION_ERROR, y en que caso el
-- cliente de la base de datos puede distinguirlos.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
CREATE OR REPLACE PROCEDURE SP_ANULAR_PEDIDO (
    p_id_pedido IN NUMBER
) IS
    vvEstado PEDIDO.estado%TYPE;
    vdFecha  PEDIDO.fecha_pedido%TYPE;
BEGIN
    BEGIN
        SELECT estado, fecha_pedido
          INTO vvEstado, vdFecha
          FROM PEDIDO
         WHERE id_pedido = p_id_pedido;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,
                'El pedido ' || p_id_pedido || ' no existe.');
    END;

    IF vvEstado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20011,
            'El pedido ' || p_id_pedido || ' ya esta anulado.');
    END IF;

    IF TRUNC(SYSDATE) - TRUNC(vdFecha) > 30 THEN
        RAISE_APPLICATION_ERROR(-20012,
            'El pedido ' || p_id_pedido || ' tiene ' ||
            (TRUNC(SYSDATE) - TRUNC(vdFecha)) || ' dias y supera el limite de 30.');
    END IF;

    UPDATE PEDIDO
       SET estado = 'ANULADO'
     WHERE id_pedido = p_id_pedido;

    DBMS_OUTPUT.PUT_LINE('Pedido ' || p_id_pedido || ' anulado correctamente.');
END SP_ANULAR_PEDIDO;
/

SET SERVEROUTPUT ON
DECLARE
    vnIdPedidoNuevo PEDIDO.id_pedido%TYPE;   -- la variable va PRIMERO

    PROCEDURE probar (p_id_pedido NUMBER, p_caso VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- ' || p_caso || ' (pedido ' || p_id_pedido || ') ---');
        SP_ANULAR_PEDIDO(p_id_pedido);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SQLCODE ' || SQLCODE || ': ' || SQLERRM);
    END;
BEGIN
    probar(999, 'Caso 1 - pedido inexistente');
    probar(7,   'Caso 2 - pedido ya anulado');
    probar(1,   'Caso 3 - pedido con mas de 30 dias');

    INSERT INTO PEDIDO (id_pedido, id_cliente, fecha_pedido, estado, total)
    VALUES (SEQ_PEDIDO.NEXTVAL, 503, SYSDATE, 'BORRADOR', 0)
    RETURNING id_pedido INTO vnIdPedidoNuevo;

    probar(vnIdPedidoNuevo, 'Caso 4 - pedido reciente');

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ROLLBACK: el pedido de prueba se descarta.');
END;
/

------------------------------------------------------------------- 4.4 (2 pts)
-- Bloque anonimo que intente insertar un producto con una categoria inexistente
-- y capture el error de integridad referencial asociando ORA-02291 a una
-- excepcion con nombre.
-- Explique que aporta esa asociacion frente a atrapar el error en un manejador
-- generico.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- PRAGMA EXCEPTION_INIT asocia un error de Oracle que no tiene nombre
-- predefinido con una excepcion declarada , de modo que puede
-- capturarse en su propio WHEN en lugar de caer en WHEN OTHERS.
-- Frente al manejador generico aporta tres cosas. Primera, precision: WHEN OTHERS
-- atrapa TODO, asi que un error distinto  terminaria tratado como si fuera un
-- problema de categoria inexistente, y el mensaje al usuario seria falso.
-- Segunda, claridad: el nombre e_categoria_inexistente documenta que condicion se
-- espera, mientras que WHEN OTHERS obliga a leer SQLCODE dentro del manejador
-- para averiguarlo. Tercera, seguridad: un WHEN OTHERS mal usado silencia errores
-- que deberian propagarse; al nombrar el caso previsto, cualquier otro error sube
-- al llamador tal como corresponde.
-- Conviene no confundir ORA-02291 con ORA-02292: el primero ocurre al insertar o
-- actualizar un hijo cuyo padre no existe (es el caso de esta prueba, sobre
-- fk_producto_categoria), y el segundo al intentar borrar un padre que todavia
-- tiene hijos.

SET SERVEROUTPUT ON
DECLARE
    e_categoria_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_categoria_inexistente, -2291);

    vnIdCategoria NUMBER := 99;     -- categoria que no existe en CATEGORIA
    vnIdProducto  NUMBER := 999999; -- identificador libre, fuera del rango cargado
BEGIN
    INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria,
                          precio_unitario, costo_unitario, stock_minimo, activo)
    VALUES (vnIdProducto, 'XX-9999', 'Producto de prueba', vnIdCategoria,
            10000, 6000, 5, 'S');

    DBMS_OUTPUT.PUT_LINE('Insercion realizada (no deberia llegar aqui).');
    ROLLBACK;
EXCEPTION
    WHEN e_categoria_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('No se puede insertar el producto: la categoria ' ||
                             vnIdCategoria || ' no existe.');
        DBMS_OUTPUT.PUT_LINE('SQLCODE = ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('SQLERRM = ' || SQLERRM);
        ROLLBACK;
END;
/

 
 
 
------------------------------------------------------------------- 4.5 (1 pt)
-- SP_REGISTRAR_ERROR
-- Procedimiento que reciba el origen y registre en LOG_ERRORES el SQLCODE y el
-- SQLERRM actuales. El registro debe persistir aunque la transaccion principal
-- termine en ROLLBACK.
-- Explique por que se requiere esa independencia transaccional y describa un
-- escenario en el que esa misma independencia oculte informacion en lugar de
-- preservarla.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Se requiere PRAGMA AUTONOMOUS_TRANSACTION porque el INSERT en LOG_ERRORES debe
-- vivir en su propia transaccion. Si se hiciera dentro de la transaccion
-- principal, el ROLLBACK que normalmente sigue a un error tambien borraria el
-- registro del error, justo cuando mas se necesita. Al ser autonoma, su COMMIT
-- (obligatorio antes de terminar) confirma solo el log y no toca el trabajo
-- pendiente del llamador. SQLCODE y SQLERRM se capturan en la declaracion, antes
-- de cualquier otra sentencia, para que no se pierdan.
--
-- Escenario donde esa misma independencia OCULTA informacion:
--  a) Si el log falla (tabla llena, bloqueo, etc.) el WHEN OTHERS lo traga para
--     no enmascarar el error original, y entonces el error queda sin rastro.
--  b) El log queda confirmado aunque la operacion de negocio se revierta o se
--     reintente con exito: el log muestra un fallo de algo que luego si se hizo
--     (o de filas que ya no existen), y como la transaccion autonoma no ve los
--     cambios sin confirmar del llamador, no hay forma de correlacionarlo con el
--     estado real de los datos.
--
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_ERROR (
    p_origen  IN VARCHAR2,
    p_detalle IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_codigo  NUMBER        := SQLCODE;
    v_mensaje VARCHAR2(500) := SUBSTR(SQLERRM, 1, 500);
BEGIN
    INSERT INTO LOG_ERRORES (id_log, origen, codigo_error, mensaje, detalle)
    VALUES (SEQ_LOG.NEXTVAL, SUBSTR(p_origen, 1, 60), v_codigo, v_mensaje,
            SUBSTR(p_detalle, 1, 500));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END SP_REGISTRAR_ERROR;
/

-- Codigo prueba
SET SERVEROUTPUT ON
BEGIN
    UPDATE CLIENTE SET saldo_pendiente = 0 WHERE id_cliente = 501;  -- trabajo pendiente
    RAISE_APPLICATION_ERROR(-20999, 'Error de prueba para el log');
EXCEPTION
    WHEN OTHERS THEN
        SP_REGISTRAR_ERROR('PRUEBA_4_5', 'Error simulado');
        ROLLBACK;
END;
/
SELECT saldo_pendiente FROM CLIENTE WHERE id_cliente = 501;
SELECT id_log, origen, codigo_error, mensaje, detalle
  FROM LOG_ERRORES ORDER BY id_log DESC FETCH FIRST 3 ROWS ONLY;


--==============================================================================
-- PARTE 5 — DISPARADORES                                     (10 puntos / 90 min)
--==============================================================================
-- Los esqueletos de esta parte no incluyen la clausula de disparo. Definirla
-- hace parte del ejercicio.
--==============================================================================

------------------------------------------------------------------- 5.1 (2 pts)
-- TRG_CLIENTE_BI
-- Al insertar un cliente debe asignar el identificador desde SEQ_CLIENTE si
-- llega nulo, convertir el nombre a mayusculas sin espacios sobrantes y forzar
-- el estado activo a 'S' si no se indica.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Se usa BEFORE porque solo en un disparador BEFORE ROW se pueden modificar los
-- valores :NEW antes de que la fila se escriba (en AFTER :NEW es de solo lectura).
-- FOR EACH ROW porque se transforma cada fila insertada. UPPER(TRIM(...)) pasa a
-- mayusculas y quita espacios en los extremos; REGEXP_REPLACE colapsa los espacios
-- repetidos del interior. El estado se fuerza a 'S' solo si llega nulo.
--
CREATE OR REPLACE TRIGGER TRG_CLIENTE_BI
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
    IF :NEW.id_cliente IS NULL THEN
        :NEW.id_cliente := SEQ_CLIENTE.NEXTVAL;
    END IF;

    :NEW.nombre := UPPER(REGEXP_REPLACE(TRIM(:NEW.nombre), ' {2,}', ' '));

    IF :NEW.activo IS NULL THEN
        :NEW.activo := 'S';
    END IF;
END TRG_CLIENTE_BI;
/
--cofigo de prueba

INSERT INTO CLIENTE (id_cliente, documento, nombre, ciudad, cupo_credito, saldo_pendiente, activo)
VALUES (NULL, '900999001', '  ferreteria   el   tornillo  ', 'Bogota', 1000000, 0, NULL);

SELECT id_cliente, '[' || nombre || ']' AS nombre, activo
  FROM CLIENTE WHERE documento = '900999001';

ROLLBACK;

------------------------------------------------------------------- 5.2 (2 pts)
-- TRG_PRODUCTO_AU_PRECIO
-- Debe registrar en AUDITORIA_PRECIO todo cambio de precio, calculando la
-- variacion porcentual, y dispararse unicamente cuando el precio efectivamente
-- cambie, resolviendo esa condicion con la clausula WHEN y no dentro del cuerpo.
-- Explique la diferencia entre ambas formas.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Con la clausula WHEN la condicion se evalua ANTES de ejecutar el disparador: si
-- el precio no cambio, el cuerpo PL/SQL ni siquiera se invoca (no hay cambio de
-- contexto del motor SQL al de PL/SQL). Con un IF dentro del cuerpo el disparador
-- se ejecuta en cada UPDATE y solo adentro descarta el caso, pagando ese costo en
-- vano. Ademas, UPDATE OF precio_unitario filtra por la columna nombrada en el SET,
-- no por el valor: un UPDATE que reasigna el mismo precio lo dispararia igual,
-- mientras que WHEN lo filtra por valor. En WHEN se usa NEW y OLD sin dos puntos.
--
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_AU_PRECIO
AFTER UPDATE OF precio_unitario ON PRODUCTO
FOR EACH ROW
WHEN (NEW.precio_unitario <> OLD.precio_unitario)
BEGIN
    INSERT INTO AUDITORIA_PRECIO (id_auditoria, id_producto, precio_anterior,
                                  precio_nuevo, variacion_pct)
    VALUES (SEQ_AUDITORIA.NEXTVAL, :NEW.id_producto, :OLD.precio_unitario,
            :NEW.precio_unitario,
            ROUND((:NEW.precio_unitario - :OLD.precio_unitario)
                  / :OLD.precio_unitario * 100, 2));
END TRG_PRODUCTO_AU_PRECIO;
/

-- codigo prueba
SELECT COUNT(*) AS filas_antes FROM AUDITORIA_PRECIO;

UPDATE PRODUCTO SET precio_unitario = 49500 WHERE id_producto = 1001;  -- cambia el precio
UPDATE PRODUCTO SET precio_unitario = 49500 WHERE id_producto = 1001;  -- mismo precio
UPDATE PRODUCTO SET stock_minimo = 22        WHERE id_producto = 1001;  -- otra columna

SELECT COUNT(*) AS filas_despues FROM AUDITORIA_PRECIO;
SELECT id_producto, precio_anterior, precio_nuevo, variacion_pct
  FROM AUDITORIA_PRECIO ORDER BY id_auditoria DESC FETCH FIRST 1 ROW ONLY;

ROLLBACK;

------------------------------------------------------------------- 5.3 (2 pts)
-- TRG_PRODUCTO_BIU_MARGEN
-- Debe impedir que se guarde un producto cuyo precio no alcance el margen minimo
-- de su categoria, segun la formula precio >= costo * (1 + margen/100),
-- rechazando la operacion con el error -20020.
-- Considere que debe ocurrir cuando la categoria indicada no existe, y justifique
-- su decision.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Decision: si la categoria no existe, el disparador NO levanta -20020 y deja
-- pasar la fila. No es un problema de margen sino de integridad referencial, y esa
-- responsabilidad ya la tiene la llave foranea (ORA-02291). Asi cada error queda
-- con su causa real y el punto 4.4 puede capturar ORA-02291 como se espera. El
-- disparador es BEFORE, por lo que corre antes de que Oracle valide la FK; por eso
-- debe tolerar la categoria inexistente en lugar de fallar con NO_DATA_FOUND.
-- Se limita a UPDATE OF precio, costo y categoria, que son las columnas que
-- pueden romper el margen.
--
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_BIU_MARGEN
BEFORE INSERT OR UPDATE OF precio_unitario, costo_unitario, id_categoria
ON PRODUCTO
FOR EACH ROW
DECLARE
    v_margen CATEGORIA.margen_minimo%TYPE;
BEGIN
    BEGIN
        SELECT margen_minimo
          INTO v_margen
          FROM CATEGORIA
         WHERE id_categoria = :NEW.id_categoria;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;   -- la FK rechazara la fila con ORA-02291
    END;

    IF :NEW.precio_unitario < :NEW.costo_unitario * (1 + v_margen / 100) THEN
        RAISE_APPLICATION_ERROR(-20020,
            'Precio ' || :NEW.precio_unitario || ' por debajo del margen minimo ('
            || v_margen || '%) de la categoria; minimo permitido: '
            || (:NEW.costo_unitario * (1 + v_margen / 100)));
    END IF;
END TRG_PRODUCTO_BIU_MARGEN;
/
--codigo prueba
-- 1. Precio justo en el limite (28000 * 1.25 = 35000): se acepta
UPDATE PRODUCTO SET precio_unitario = 35000 WHERE id_producto = 1001;

-- 2. Precio por debajo del margen: debe fallar con -20020
UPDATE PRODUCTO SET precio_unitario = 30000 WHERE id_producto = 1001;

-- 3. Categoria inexistente: debe fallar con ORA-02291, no con -20020
INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria,
                      precio_unitario, costo_unitario, stock_minimo, activo)
VALUES (SEQ_PRODUCTO.NEXTVAL, 'XX-0001', 'Producto de prueba', 99, 1000, 500, 0, 'S');

ROLLBACK;

------------------------------------------------------------------- 5.4 (2 pts)
-- TRG_DETALLE_AI_STOCK
-- Al insertar una linea de pedido debe descontar el stock de la bodega indicada
-- y registrar el movimiento de SALIDA correspondiente. Si no hay stock suficiente
-- debe abortar la operacion con el error -20030.
-- Explique por que el momento de disparo que eligio es el correcto y que dejaria
-- de funcionar con el contrario.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Es AFTER INSERT FOR EACH ROW porque el inventario solo debe tocarse cuando la
-- linea ya es una fila valida y aceptada: ya paso la PK, las FK (pedido, producto,
-- bodega) y los CHECK (cantidad > 0, precio > 0). Con BEFORE el trigger correria
-- antes de esas validaciones, y dejaria de funcionar bien en dos sentidos:
--  a) Descontaria stock y registraria el movimiento de una linea que despues
--     podria ser rechazada; Oracle deberia deshacerlo y se hace trabajo en vano.
--  b) Enmascararia el error real: una linea con bodega inexistente o cantidad
--     invalida fallaria con -20030 (stock insuficiente) en lugar de con el error
--     de FK o CHECK que realmente corresponde.
-- El UPDATE condicionado (cantidad >= :NEW.cantidad) valida y descuenta en una
-- sola sentencia atomica, sin carrera entre leer el stock y restarlo.
--
CREATE OR REPLACE TRIGGER TRG_DETALLE_AI_STOCK
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    UPDATE EXISTENCIA
       SET cantidad = cantidad - :NEW.cantidad
     WHERE id_bodega   = :NEW.id_bodega
       AND id_producto = :NEW.id_producto
       AND cantidad   >= :NEW.cantidad;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20030,
            'Stock insuficiente del producto ' || :NEW.id_producto
            || ' en la bodega ' || :NEW.id_bodega
            || ' para la cantidad solicitada ' || :NEW.cantidad);
    END IF;

    INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo,
                                       cantidad, id_pedido, observacion)
    VALUES (SEQ_MOVIMIENTO.NEXTVAL, :NEW.id_producto, :NEW.id_bodega, 'SALIDA',
            :NEW.cantidad, :NEW.id_pedido,
            'Linea ' || :NEW.linea || ' del pedido ' || :NEW.id_pedido);
END TRG_DETALLE_AI_STOCK;
/
--codigo de prueba
-- Caso 1: hay stock (bodega 1 tiene 120 martillos)
SELECT cantidad FROM EXISTENCIA WHERE id_bodega = 1 AND id_producto = 1001;
INSERT INTO DETALLE_PEDIDO VALUES (6, 1, 1001, 1, 20, 45000, 900000);
SELECT cantidad FROM EXISTENCIA WHERE id_bodega = 1 AND id_producto = 1001;
SELECT tipo, cantidad, id_pedido, observacion
  FROM MOVIMIENTO_INVENTARIO WHERE id_pedido = 6;

-- Caso 2: no hay stock (bodega 1 solo tiene 4 pulidoras)
SELECT cantidad FROM EXISTENCIA WHERE id_bodega = 1 AND id_producto = 1005;
INSERT INTO DETALLE_PEDIDO VALUES (6, 2, 1005, 1, 10, 285000, 2850000);
SELECT COUNT(*) AS lineas_pedido_6 FROM DETALLE_PEDIDO WHERE id_pedido = 6;
SELECT cantidad FROM EXISTENCIA WHERE id_bodega = 1 AND id_producto = 1005;

ROLLBACK;

------------------------------------------------------------------- 5.5 (1 pt)
-- TRG_DETALLE_TOTAL
-- Debe recalcular el total de la cabecera del pedido despues de cualquier
-- insercion, actualizacion o borrado de sus lineas.
-- Documente el error que obtiene en su primer intento, en que momento aparece,
-- y como lo resuelve la construccion que finalmente utilizo.
-- Este punto no se califica sin esa explicacion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Primer intento: un trigger AFTER INSERT OR UPDATE OR DELETE FOR EACH ROW sobre
-- DETALLE_PEDIDO que hacia UPDATE PEDIDO SET total = (SELECT SUM(subtotal) FROM
-- DETALLE_PEDIDO WHERE id_pedido = ...).
-- Error: ORA-04091: la tabla DETALLE_PEDIDO esta mutando; es posible que el
-- disparador/funcion no pueda verlo. Aparece en TIEMPO DE EJECUCION, no al crear
-- el trigger (compila sin problema): se produce cuando el trigger de fila corre
-- durante una sentencia DML sobre DETALLE_PEDIDO (con certeza en UPDATE, DELETE o
-- INSERT ... SELECT) y su cuerpo consulta esa misma tabla, que en ese instante
-- esta a medias de modificarse.
-- Que es la tabla mutante: una tabla que esta siendo modificada por la sentencia
-- que disparo el trigger; un trigger de fila no puede leerla ni modificarla
-- porque veria un estado inconsistente (algunas filas ya cambiadas, otras no).
-- Solucion: COMPOUND TRIGGER. En AFTER EACH ROW solo se ANOTAN en una coleccion
-- los id_pedido afectados (sin consultar la tabla). En AFTER STATEMENT, cuando la
-- sentencia ya termino y la tabla dejo de estar mutando, se recalcula el total de
-- cada pedido anotado con un SELECT SUM permitido. Como la coleccion vive en la
-- seccion declarativa, comparte estado entre los momentos de disparo; se limpia
-- en BEFORE STATEMENT. Al usar un indice por id_pedido, cada pedido se recalcula
-- una sola vez aunque la sentencia toque varias de sus lineas.


-- triger que falla:
ALTER TRIGGER TRG_DETALLE_TOTAL DISABLE;

CREATE OR REPLACE TRIGGER TRG_DETALLE_TOTAL_INTENTO1
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    UPDATE PEDIDO p
       SET p.total = (SELECT NVL(SUM(d.subtotal), 0)
                        FROM DETALLE_PEDIDO d
                       WHERE d.id_pedido = NVL(:NEW.id_pedido, :OLD.id_pedido))
     WHERE p.id_pedido = NVL(:NEW.id_pedido, :OLD.id_pedido);
END;
/

UPDATE DETALLE_PEDIDO SET subtotal = subtotal WHERE id_pedido = 1;

DROP TRIGGER TRG_DETALLE_TOTAL_INTENTO1;
ALTER TRIGGER TRG_DETALLE_TOTAL ENABLE;

--solucion final
CREATE OR REPLACE TRIGGER TRG_DETALLE_TOTAL
FOR INSERT OR UPDATE OR DELETE ON DETALLE_PEDIDO
COMPOUND TRIGGER

    TYPE t_pedidos IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    g_pedidos t_pedidos;
    v_id      PLS_INTEGER;

    BEFORE STATEMENT IS
    BEGIN
        g_pedidos.DELETE;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF :NEW.id_pedido IS NOT NULL THEN
            g_pedidos(:NEW.id_pedido) := TRUE;
        END IF;
        IF :OLD.id_pedido IS NOT NULL THEN
            g_pedidos(:OLD.id_pedido) := TRUE;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        v_id := g_pedidos.FIRST;
        WHILE v_id IS NOT NULL LOOP
            UPDATE PEDIDO p
               SET p.total = (SELECT NVL(SUM(d.subtotal), 0)
                                FROM DETALLE_PEDIDO d
                               WHERE d.id_pedido = p.id_pedido)
             WHERE p.id_pedido = v_id;
            v_id := g_pedidos.NEXT(v_id);
        END LOOP;
        g_pedidos.DELETE;
    END AFTER STATEMENT;

END TRG_DETALLE_TOTAL;
/
--codigo de prueba
INSERT INTO DETALLE_PEDIDO VALUES (6, 1, 1001, 1, 20, 45000, 900000);
INSERT INTO DETALLE_PEDIDO VALUES (6, 2, 1002, 1,  5, 62000, 310000);
SELECT id_pedido, total FROM PEDIDO WHERE id_pedido = 6;

UPDATE DETALLE_PEDIDO SET subtotal = 450000 WHERE id_pedido = 6 AND linea = 1;
SELECT id_pedido, total FROM PEDIDO WHERE id_pedido = 6;

DELETE FROM DETALLE_PEDIDO WHERE id_pedido = 6 AND linea = 2;
SELECT id_pedido, total FROM PEDIDO WHERE id_pedido = 6;

ROLLBACK;

UPDATE DETALLE_PEDIDO SET subtotal = subtotal WHERE id_pedido = 1;
SELECT id_pedido, total FROM PEDIDO WHERE id_pedido = 1;
ROLLBACK;
------------------------------------------------------------------- 5.6 (1 pt)
-- TRG_V_STOCK_IO
-- Debe permitir actualizar el precio y el stock minimo del producto a traves de
-- la vista V_STOCK_CONSOLIDADO.
-- Explique por que esa vista no es actualizable de forma directa.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- La vista no es actualizable de forma directa porque contiene GROUP BY, la
-- funcion de agregacion SUM y joins con LEFT JOIN: cada fila de la vista resume
-- varias filas fisicas (todas las existencias del producto), asi que Oracle no
-- puede determinar a que fila base corresponde un cambio y rechaza el UPDATE con
-- ORA-01732 (operacion DML no valida en esta vista). El INSTEAD OF reemplaza la
-- accion: en lugar de actualizar la vista, traduce el cambio a un UPDATE sobre
-- PRODUCTO usando :OLD.id_producto. Solo precio_unitario y stock_minimo son
-- modificables; stock_total es un agregado y no tiene una fila base donde escribirse.
--
CREATE OR REPLACE TRIGGER TRG_V_STOCK_IO
INSTEAD OF UPDATE ON V_STOCK_CONSOLIDADO
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
       SET precio_unitario = :NEW.precio_unitario,
           stock_minimo    = :NEW.stock_minimo
     WHERE id_producto = :OLD.id_producto;
END TRG_V_STOCK_IO;
/

-- codigo prueba
SELECT id_producto, precio_unitario, stock_minimo, stock_total
  FROM V_STOCK_CONSOLIDADO WHERE id_producto = 1001;

-- Sin el trigger la vista no se puede actualizar
ALTER TRIGGER TRG_V_STOCK_IO DISABLE;
UPDATE V_STOCK_CONSOLIDADO SET precio_unitario = 47000, stock_minimo = 25
 WHERE id_producto = 1001;
ALTER TRIGGER TRG_V_STOCK_IO ENABLE;

-- Con el trigger
UPDATE V_STOCK_CONSOLIDADO SET precio_unitario = 47000, stock_minimo = 25
 WHERE id_producto = 1001;
SELECT id_producto, precio_unitario, stock_minimo FROM PRODUCTO WHERE id_producto = 1001;

ROLLBACK;



--==============================================================================
-- PARTE 6 — CASO INTEGRADOR                                   (5 puntos / 45 min)
--==============================================================================

-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- PKG_VENTAS
-- Construya un PAQUETE que exponga el procedimiento SP_FACTURAR_PEDIDO, el cual,
-- para un pedido en estado BORRADOR, debe:
--
--   1. Validar que el pedido exista y este en BORRADOR
--   2. Recorrer sus lineas con un cursor y acumular el subtotal
--   3. Calcular el descuento con FN_CALCULAR_DESCUENTO
--   4. Validar contra FN_CUPO_DISPONIBLE que el cliente tenga cupo suficiente
--   5. Actualizar el total del pedido y cambiar su estado a CONFIRMADO
--   6. Incrementar el saldo pendiente del cliente
--   7. Usar SAVEPOINT y revertir parcialmente ante cualquier fallo, registrando
--      el error con SP_REGISTRAR_ERROR
--   8. Devolver por parametros OUT el total facturado y el descuento aplicado
--
-- Firma esperada:
--   PKG_VENTAS.SP_FACTURAR_PEDIDO(p_id_pedido IN NUMBER,
--                                 p_total     OUT NUMBER,
--                                 p_descuento OUT NUMBER)
--
-- Se evalua la integracion. El procedimiento debe apoyarse en los objetos de las
-- partes 1 a 5 y no reimplementar su logica: uno que vuelva a codificar el
-- calculo del descuento pierde la mitad del puntaje de esta parte.
-- Defina explicitamente el alcance transaccional y justifique donde decidio
-- ubicar la confirmacion de la transaccion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- Reutilizacion: el descuento sale de FN_CALCULAR_DESCUENTO, el cupo de
-- FN_CUPO_DISPONIBLE y el log de SP_REGISTRAR_ERROR; no se reimplementa ninguna
-- regla. El descuento se calcula ANTES de incrementar el saldo del cliente, porque
-- la funcion premia al cliente sin saldo pendiente. El cupo se valida contra el
-- total NETO (subtotal - descuento), que es lo que realmente se suma al saldo.
-- Se bloquean con FOR UPDATE el pedido (evita facturarlo dos veces a la vez) y el
-- cliente (evita que dos facturas simultaneas pasen la validacion de cupo con el
-- mismo saldo).
--
-- Alcance transaccional: el procedimiento abre un SAVEPOINT (sp_facturar) al
-- comenzar y ante CUALQUIER fallo revierte solo hasta ese punto (ROLLBACK TO),
-- registra el error con SP_REGISTRAR_ERROR (transaccion autonoma, por lo que el
-- log persiste) y relanza la excepcion con RAISE para que el llamador se entere.
-- Un pedido sin lineas se rechaza porque no hay nada que facturar.
-- La confirmacion (COMMIT) NO esta dentro del paquete: queda en el llamador.
-- Razon: el paquete es una unidad de trabajo que puede formar parte de otra mayor
-- (por ejemplo, facturar varios pedidos de forma atomica); si hiciera COMMIT, un
-- ROLLBACK posterior del llamador no podria deshacerlo y el SAVEPOINT perderia su
-- sentido, y el llamador perderia el control sobre su propia transaccion.
-- Los codigos -20040 a -20043 son propios de este paquete y no chocan con los
-- usados en las partes anteriores (-20010 a -20012, -20020, -20030).
-- Nota: el trigger TRG_DETALLE_TOTAL recalcula PEDIDO.total como suma de
-- subtotales cuando cambian las lineas; este procedimiento no toca DETALLE_PEDIDO,
-- por eso el total neto facturado no se sobrescribe al confirmar.
--
CREATE OR REPLACE PACKAGE PKG_VENTAS IS
    PROCEDURE SP_FACTURAR_PEDIDO (
        p_id_pedido IN  NUMBER,
        p_total     OUT NUMBER,
        p_descuento OUT NUMBER
    );
END PKG_VENTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_VENTAS IS

    c_err_no_existe   CONSTANT NUMBER := -20040;
    c_err_no_borrador CONSTANT NUMBER := -20041;
    c_err_sin_lineas  CONSTANT NUMBER := -20042;
    c_err_sin_cupo    CONSTANT NUMBER := -20043;

    PROCEDURE SP_FACTURAR_PEDIDO (
        p_id_pedido IN  NUMBER,
        p_total     OUT NUMBER,
        p_descuento OUT NUMBER
    ) IS
        v_id_cliente PEDIDO.id_cliente%TYPE;
        v_estado     PEDIDO.estado%TYPE;
        v_bloqueo    CLIENTE.id_cliente%TYPE;
        v_subtotal   NUMBER := 0;
        v_lineas     PLS_INTEGER := 0;
        v_descuento  NUMBER;
        v_total      NUMBER;

        CURSOR c_lineas (cp_id_pedido IN NUMBER) IS
            SELECT linea, subtotal
              FROM DETALLE_PEDIDO
             WHERE id_pedido = cp_id_pedido
             ORDER BY linea;
    BEGIN
        SAVEPOINT sp_facturar;

        -- 1. El pedido debe existir y estar en BORRADOR
        BEGIN
            SELECT id_cliente, estado
              INTO v_id_cliente, v_estado
              FROM PEDIDO
             WHERE id_pedido = p_id_pedido
               FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(c_err_no_existe,
                    'El pedido ' || p_id_pedido || ' no existe');
        END;

        IF v_estado <> 'BORRADOR' THEN
            RAISE_APPLICATION_ERROR(c_err_no_borrador,
                'El pedido ' || p_id_pedido || ' esta en estado ' || v_estado
                || '; solo se puede facturar un pedido en BORRADOR');
        END IF;

        SELECT id_cliente
          INTO v_bloqueo
          FROM CLIENTE
         WHERE id_cliente = v_id_cliente
           FOR UPDATE;

        -- 2. Recorrer las lineas con un cursor y acumular el subtotal
        FOR r IN c_lineas(p_id_pedido) LOOP
            v_subtotal := v_subtotal + r.subtotal;
            v_lineas   := v_lineas + 1;
        END LOOP;

        IF v_lineas = 0 THEN
            RAISE_APPLICATION_ERROR(c_err_sin_lineas,
                'El pedido ' || p_id_pedido || ' no tiene lineas para facturar');
        END IF;

        -- 3. Descuento (valor en pesos) con la funcion existente
        v_descuento := FN_CALCULAR_DESCUENTO(v_id_cliente, v_subtotal);
        v_total     := ROUND(v_subtotal - v_descuento, 2);

        -- 4. Validar el cupo con la funcion existente
        IF v_total > FN_CUPO_DISPONIBLE(v_id_cliente) THEN
            RAISE_APPLICATION_ERROR(c_err_sin_cupo,
                'Cupo insuficiente: el total ' || v_total
                || ' supera el cupo disponible del cliente ' || v_id_cliente);
        END IF;

        -- 5. Actualizar total y estado del pedido
        UPDATE PEDIDO
           SET total  = v_total,
               estado = 'CONFIRMADO'
         WHERE id_pedido = p_id_pedido;

        -- 6. Incrementar el saldo pendiente del cliente
        UPDATE CLIENTE
           SET saldo_pendiente = saldo_pendiente + v_total
         WHERE id_cliente = v_id_cliente;

        -- 8. Parametros de salida
        p_total     := v_total;
        p_descuento := v_descuento;

    EXCEPTION
        -- 7. Reversion parcial y registro del error
        WHEN OTHERS THEN
            SP_REGISTRAR_ERROR('PKG_VENTAS.SP_FACTURAR_PEDIDO',
                               'id_pedido=' || p_id_pedido);
            ROLLBACK TO SAVEPOINT sp_facturar;
            RAISE;
    END SP_FACTURAR_PEDIDO;

END PKG_VENTAS;
/
--codigo prueba

SET SERVEROUTPUT ON
-- Preparacion: una linea para el pedido 6 (cliente 501, en BORRADOR)
INSERT INTO DETALLE_PEDIDO VALUES (6, 1, 1001, 1, 20, 45000, 900000);

-- Caso 1: facturacion exitosa
DECLARE
    v_total NUMBER; v_desc NUMBER;
BEGIN
    PKG_VENTAS.SP_FACTURAR_PEDIDO(6, v_total, v_desc);
    DBMS_OUTPUT.PUT_LINE('Total facturado: ' || v_total || ' | Descuento: ' || v_desc);
END;
/
SELECT id_pedido, estado, total FROM PEDIDO WHERE id_pedido = 6;
SELECT id_cliente, cupo_credito, saldo_pendiente FROM CLIENTE WHERE id_cliente = 501;



-- Caso 2: el pedido ya no esta en BORRADOR (-20041)
DECLARE
    v_total NUMBER; v_desc NUMBER;
BEGIN
    PKG_VENTAS.SP_FACTURAR_PEDIDO(6, v_total, v_desc);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Caso 3: pedido inexistente (-20040)
DECLARE
    v_total NUMBER; v_desc NUMBER;
BEGIN
    PKG_VENTAS.SP_FACTURAR_PEDIDO(999, v_total, v_desc);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Caso 4: cupo insuficiente (-20043). El cliente 505 tiene el cupo agotado
INSERT INTO PEDIDO (id_pedido, id_cliente, estado, total) VALUES (100, 505, 'BORRADOR', 0);
INSERT INTO DETALLE_PEDIDO VALUES (100, 1, 1001, 1, 2, 45000, 90000);
DECLARE
    v_total NUMBER; v_desc NUMBER;
BEGIN
    PKG_VENTAS.SP_FACTURAR_PEDIDO(100, v_total, v_desc);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
SELECT id_pedido, estado FROM PEDIDO WHERE id_pedido = 100;

-- Registro de los errores
SELECT id_log, origen, codigo_error, detalle
  FROM LOG_ERRORES ORDER BY id_log DESC FETCH FIRST 3 ROWS ONLY;

ROLLBACK;

--==============================================================================
-- FIN DE LA PLANTILLA
--==============================================================================
