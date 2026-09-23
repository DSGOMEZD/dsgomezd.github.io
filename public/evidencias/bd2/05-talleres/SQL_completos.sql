-- =====================================================================
-- Bases de Datos 2 · Taller integrador — MercaAndes
-- Taller resuelto en clase con ejercicios que fui pidiendo a una IA
-- para practicar, en vez de quedarme solo con la teoria de como
-- funciona cada tema.
-- 01_sesion_A.sql        >>>  CONEXIÓN A  <<<
-- =====================================================================
-- #####################################################################
-- EJERCICIO 1.1 — La venta que se pierde (actualización perdida)
-- #####################################################################

-- PASO 1  (A)  Estado inicial
--> Anote el valor de DISPONIBLE. 
-- En este paso DISPONIBLE = 10

--  PREGUNTA 1.1 — Se vendieron 3 unidades (A) más 4 (B) = 7 de 10.
--  Deberían quedar 3. ¿Cuántas quedan? ¿Quién "ganó"? ¿Hubo algún error,
--  alguna advertencia, algún registro de que algo salió mal?
-- RTA:/ Quedaron 6, en esta sentencia, ganó B, ya que segun el orden del commit hecho por A y B, B hizo commit despues;
-- no estamos haciendo operaciones sino cambiando el resultado con un set por lo que no se puede decir que se vendieron 
-- unidades, sino que se cambio el valor por orden. En conclusion B ganó.

--  PREGUNTA 1.2 — El bloqueo de fila SÍ funcionó: B esperó a que A
--  confirmara. Explique entonces por qué se perdió una venta de todos
--  modos.
-- RTA:/ La venta se perdio por que la sentencia no calculo el valor restandole lo que se vendio, si no simplemente se actualizo el dato con un set por un 
-- dato en especifico. B hizo lo mismo anulando la venta anterior asumiendo que seguian habiendo 10 disponibles, cuando realmente se redujo. 

-- #####################################################################
-- EJERCICIO 1.2 — Defensa pesimista: SELECT ... FOR UPDATE
-- #####################################################################

--  PREGUNTA 1.3 — Ahora sí quedan 3. ¿Qué dos cosas cambiaron respecto
--  al ejercicio anterior? (pista: una es el FOR UPDATE, la otra está
--  dentro del UPDATE mismo)
-- RTA:/ - El FOR UPDATE bloquea la fila desde que se lee, no desde que se escribe. B no puede leer con intencion de escribir hasta que A termine.
--      - En el UPDATE el valor nuevo lo calcula la base de datos sobre el dato actual, no sobre un dato viejo.
--
--  PREGUNTA 1.4 — ¿Cuál fue el precio que se pagó por esta seguridad?
-- RTA:/Se pierde la concurrencia: - las operaciones sobre esa fila dejan de ejecutarse en paralelo. 
--                                 - el bloqueo se mantiene hasta el COMMIT y no hasta el UPDATE, cada sesion que espera consume una conexion sin trabajar.

-- #####################################################################
-- EJERCICIO 1.3 — Defensa optimista: columna de versión
-- #####################################################################

-- PASO 2  (A)  Leo el stock y la versión.  NO bloqueo nada.
--> Anote la versión que ve. 
-- RTA:/ Para el producto 100, la version vista es 0.

-- PASO 5  (A)  Intento escribir con la versión que leí
--  Mire el mensaje: ¿cuántas filas actualizó?
-- RTA:/ El mensaje dice: 0 filas actualizadas

--  PREGUNTA 1.5 — Su UPDATE afectó 0 filas. ¿Qué debe hacer la
--  aplicación en ese momento, y qué NO debe hacer nunca?
--  RTA:/  -Lo que debe hacer: verificar siempre la fila con la versión nueva, teniendo en cuenta si alcanza el stock, y en caso tal, reintentar.
--         -Lo que nunca debe hacer: ignorar el resultado y seguir como si el UPDATE hubiera funcionado. "0 filas actualizadas" no es un error. 
--          Si la aplicacion no revisa cuantas filas afecto, existen fallas.
--
--  PREGUNTA 1.6 — Compare las dos defensas. ¿En qué escenario de este
--  marketplace usaría la pesimista y en cuál la optimista? Justifique
--  con el nivel de contención esperado, no con opiniones.
-- RTA;/ La decision depende de qué tan seguido dos sesiones se peleen la misma fila
-- Pesimista: En INVENTARIO, porque muchos pedidos pueden modificar las mismas filas al mismo tiempo. 
-- Como los conflictos son frecuentes, es mejor bloquear y esperar que tener que reintentar constantemente.
-- Optimista: En CLIENTE o PEDIDO, porque normalmente una fila es modificada por una sola persona. 
-- Como los conflictos son poco frecuentes, es mejor no bloquear y reintentar solo si ocurre un conflicto.

-- #####################################################################
-- EJERCICIO 1.4 — Repartir la cola de despacho: SKIP LOCKED
-- #####################################################################
-- PASO 1  (A)  Tomo 5 tareas y las marco como mías
--> Anote los id_tarea que le tocaron.  NO confirme todavía.
-- RTA:/ id_tarea: 1,2,3,4,5

--  PREGUNTA 1.7 — ¿Qué habría pasado sin SKIP LOCKED? Describa los dos
--  comportamientos posibles según se use FOR UPDATE simple o NOWAIT.
-- RTA:/ sin SKIP LOCKED: - con FOR UPDATE: B al intentar trababjar en una fila ocupada, lo deja esperando a que A lo libere. 
--                          Con el SKIP busca filas que no esten ocupadas para asi no tener que esperar.
--                        - FOR UPDATE NOWAIT: B falla de inmediato con error. No espera, pero tampoco puede trabajar con otras filas.
--
--  PREGUNTA 1.8 — ¿Por qué SKIP LOCKED es la base de las colas de
--  trabajo implementadas sobre tablas? ¿Qué componente de arquitectura
--  se ahorra uno con esto?
-- RTA:/ Es la base de las colas de trabajo porque reparte las tareas de manera automatica sin que a una persona 
--       le toque la tarea de otro, osea sin repetir tareas.
--      - Se ahorra un sistema de colas externo como puede ser un Message Broker
-- #####################################################################
-- EJERCICIO 1.5 — El bloqueo que nadie espera: FK sin índice
-- #####################################################################
--
--  PREGUNTA 1.9 — Explique por qué Oracle toma un bloqueo de TABLA sobre
--  el hijo cuando se borra un padre y la FK no está indexada.
-- RTA/ Al borrar un pedido, se debe comprobar que no queden pagos apuntando a él. 
-- Como PAGO.ID_PEDIDO no tiene índice, se recorre la tabla de pagos entera, bloqueando toda la tabla PAGO. 
-- Por eso una sesión que borra un pedido cualquiera bloquea a otra que está trabajando en pagos que no tienen nada que ver. 
-- Con el índice, la comprobación es una búsqueda puntual y basta con bloquear a nivel de fila.
--
--  PREGUNTA 1.10 — Revise el esquema completo de MercaAndes. ¿Qué OTRAS
--  llaves foráneas están sin índice? ¿Cuáles de ellas son realmente un
--  problema y cuáles no? Justifique.
-- RTA:/
--    FKs sin indice en el esquema:
--    categoria.id_padre
--    producto.id_categoria
--    inventario.id_bodega
--    pedido.id_cliente
--    pedido_detalle.id_producto
--  Cuales son un problema real: solo las que apuntan a un padre del que se borran filas. Sin borrados de padre no hay bloqueo de tabla.
--  No son problema: producto.id_categoria, inventario.id_bodega. El bloqueo de tabla solo aparece cuando borras una fila del padre. 
--  Si nadie borra el padre, el bloqueo nunca se activa

-- #####################################################################
-- EJERCICIO 1.6 (si alcanza el tiempo) — Interbloqueo
-- #####################################################################

--  PREGUNTA 1.11 — Oracle abortó UNA sentencia, no la transacción
--  completa. ¿En qué estado queda la sesión víctima y qué debe hacer?
-- RTA:/ En nuestro ejercicio A fue la victima, recibio el ORA-00060.
-- A queda con su transaccion abierta y todavia con el bloqueo del producto 100 puesto, estorbando.
-- debe hacer un ROLLBACK para soltar todo y volver a empezar la operacion completa. 
-- no debe repetir la segunda sentencia, porque repetira el circulo.

--  PREGUNTA 1.12 — Escriba la regla de diseño, en una frase, que habría
--  hecho imposible este interbloqueo.
-- RTA:/Se debe reservar las filas de manera ordenada; si todos siguen esa regla, se evitan los ciclos, 
-- ya que simplemente las actualizaciones se harian de manera secuencial esperando que una persona 
-- termine para que la otra pueda seguir.

-- =====================================================================
-- 02_indices.sql   Índices y optimización de consultas
-- =====================================================================
-- #####################################################################
-- EJERCICIO 2.1 — La consulta del informe diario
-- #####################################################################
-- PASO 2  Vea el plan
--  ANOTE:  operación = _______Table Access Full_______   COST = ___309___   filas = ___5289___
--
--  PREGUNTA 2.1 — La tabla tiene 200.000 filas y la consulta devuelve
--  unos pocos miles. ¿Por qué el optimizador está leyendo la tabla
--  completa? ¿Es un error del optimizador?
-- RTA/: no es un error del optimizador, es que no hay ningún índice que pueda usar,
-- es por eso que la unica opcion que le queda es leer la tabla completa con TABLE ACCESS FULL.

-- PASO 4  Repita la medición
--  ANOTE:  operación = _______TABLE ACCESS FULL_______   COST = ___309___    filas = ___4715___
--
--  PREGUNTA 2.2 — ¿Cuánto bajó el COST? Ejecute también con F6
--  (Autotrace) antes y después y compare los "consistent gets".
-- RTA/: El costo no bajo, porque el hecho de que el indice exista no significa que lo vaya a usar 
--       si el optimizador no lo considera util o eficiente en este caso, aunque el numero de filas si bajo.
--
--  PREGUNTA 2.3 — ¿Cuál de los dos índices elige el optimizador cuando
--  no se le fuerza nada? Compare el COST de los dos SELECT anteriores.
--  Formule la regla general sobre el orden de columnas en un índice
--  compuesto, distinguiendo el predicado de IGUALDAD del de RANGO.

-- RTA 2.3/: El optimizador elige IX_PEDIDO_ESTADO_FECHA, que tiene el COST mas bajo de los dos.
-- En un indice compuesto van primero las columnas con predicado de
-- IGUALDAD y de ultima la del predicado de RANGO. Aqui estado='ENTREGADO'
-- es igualdad y fecha_pedido es rango, asi que (estado, fecha_pedido)
-- permite entrar por un punto exacto y recorrer un tramo continuo del
-- indice. Con (fecha_pedido, estado) toca recorrer todas las entradas de
-- marzo y descartar una por una las que no son ENTREGADO.
--
--  PREGUNTA 2.4 — Suponga ahora que existe además un informe que filtra
--  SOLO por rango de fechas, sin estado. ¿Cuál de los dos índices le
--  sirve a ese informe y cuál no? ¿Cambia eso su recomendación?
--  Responda cuál de los dos conservaría en producción y por qué.
-- RTA 2.4/: A ese informe le sirve IX_PEDIDO_FECHA_ESTADO, porque fecha_pedido es la primera columna del indice.
-- IX_PEDIDO_ESTADO_FECHA no le sirve: sin un valor de estado no hay por donde entrar al indice.
-- Si, cambia la recomendacion. En produccion conservaria IX_PEDIDO_FECHA_ESTADO: es un poco peor para la consulta del 2.1, pero
-- sirve a las dos, y un solo indice cuesta la mitad en escrituras que dos.
-- No se elige el indice optimo para una consulta, sino el mejor conjunto para toda la carga.

-- #####################################################################
-- EJERCICIO 2.2 — El índice que existe y no se usa
-- #####################################################################
--  PREGUNTA 2.5 — El índice existe y sigue haciendo FULL SCAN.
--  ¿Por qué? ¿Qué le hizo la consulta a la columna indexada?
--  RTA/: Sigue en FULL SCAN porque se le aplico la funcion
-- UPPER a la columna indexada. El indice guarda el nombre tal como esta y la consulta busca la version en
-- mayusculas, que no esta guardada en ninguna parte.asi que lee cada fila, le aplica UPPER y compara. 

--  PREGUNTA 2.6 — Las dos consultas devuelven exactamente lo mismo.
--  Compare los planes. Escriba la regla, en una frase, que todo
--  desarrollador debería tener presente al filtrar por fecha.
-- RTA 2.6/: La primera consulta hace FULL SCAN y la segunda usa el indice,
-- aunque devuelven lo mismo(274 pedidos). El TRUNC() le cambia el valor a la columna, y
-- el indice guarda la fecha original, no la truncada: Oracle no puede
-- buscar algo que el indice no tiene, asi que le toca leer toda la tabla.
-- Regla: nunca aplicarle una funcion a la columna de fecha en el WHERE;
-- convertir el filtro en un rango  fecha >= inicio AND fecha < fin.

-- #####################################################################
-- EJERCICIO 2.3 — Cuándo NO conviene un índice
-- #####################################################################

--  PREGUNTA 2.7 — El mismo índice, la misma consulta, distinto valor:
--  en un caso se usa y en el otro no. ¿Cómo lo sabe el optimizador?
--  ¿Qué información necesita para tomar esa decisión?
-- RTA 2.7/: Lo sabe por las estadisticas. Oracle estima cuantas filas va a devolver el filtro antes de 
-- ejecutar: ENTREGADO es el 62% de la tabla y ANULADO el 2%. Cuando el filtro trae casi toda la tabla, saltar fila por
-- fila desde el indice sale mas caro que leerla de corrido; con el 2% el indice gana. 
-- La info que necesita: num_distinct, density y sobre todo el HISTOGRAMA, porque sin el asumiria que cada uno 
-- de los 5 estados es el 20% y trataria igual a los dos casos.
--
--  PREGUNTA 2.8 — Consulte la selectividad y el clustering factor:

--  ¿Qué le dice el CLUSTERING FACTOR de IX_PEDIDO_FECHA_ESTADO comparado
--  con el de IX_PEDIDO_ESTADO? ¿Por qué son tan distintos?

-- RTA 2.8/: El clustering factor dice cuantos saltos a la tabla toca dar para
-- leer las filas por ese indice. Entre mas alto, mas caro es usarlo.
-- IX_PEDIDO_FECHA_ESTADO = 200.001 con NUM_ROWS = 200.011: un salto por cada
-- fila, o sea el peor caso posible. IX_PEDIDO_ESTADO = 5.345, mucho mejor.
-- El ideal seria el numero de bloques de la tabla, que son ~1.071, y eso es
-- justo lo que da PK_PEDIDO.
-- Son distintos por como quedaron guardadas las filas. Los pedidos se
-- insertaron en orden de id_pedido, y por eso la PK tiene el mejor valor. La
-- fecha en cambio se calculo con MOD(n*7,730), que salta en cada fila, asi que
-- dos pedidos con fechas seguidas quedaron en extremos opuestos de la tabla.
-- Y el estado solo tiene 5 valores que se repiten todo el tiempo, asi que las
-- filas de un mismo estado caen muchas por bloque y el numero baja.

-- #####################################################################
-- EJERCICIO 2.4 — El índice que evita tocar la tabla
-- #####################################################################
--  PREGUNTA 2.9 — Desapareció el TABLE ACCESS. ¿Cómo se llama esta
--  técnica y por qué es tan efectiva? ¿Cuál es su límite: hasta dónde
--  tiene sentido seguir agregando columnas al índice?

-- RTA 2.9/: Se llama indice de cobertura. Desaparecio el TABLE ACCESS
-- porque el indice ya trae fecha_pedido e id_cliente, que es todo lo que la
-- consulta necesita: no hay que ir a la tabla a buscar nada mas. Se ahorra
-- un salto a la tabla por cada fila encontrada.
-- El limite: cada columna extra engorda el indice y encarece cada INSERT,
-- UPDATE y DELETE. Vale la pena con una o dos columnas para una consulta
-- frecuente; meter media tabla ya es hacer una copia que toca mantener.

-- #####################################################################
-- EJERCICIO 2.5 — Lo que cuesta un índice
-- #####################################################################
-- PASO 3  Ahora sin índices secundarios
DROP INDEX ix_pedido_fecha_estado;
DROP INDEX ix_pedido_estado;
DROP INDEX ix_pedido_fecha_cliente;

INSERT INTO pedido (id_pedido, id_cliente, fecha_pedido, estado, canal, total)
SELECT 2000000 + LEVEL, MOD(LEVEL,20000)+1,
       DATE '2026-06-01' + MOD(LEVEL,30), 'CREADO', 'WEB', 100000
  FROM dual CONNECT BY LEVEL <= 50000;
COMMIT;
--> Anote el tiempo: ___0.373___

--  PREGUNTA 2.10 — ¿Cuál fue la diferencia de tiempo? Extrapole:
--  MercaAndes recibe 8.000 pedidos por hora en temporada. ¿Qué costo
--  operativo tiene cada índice que se agrega "por si acaso"?
-- 
-- RTA 2.10/: Con los 3 indices el INSERT de 50.000 filas tardo 2,189 s y sin
-- ellos 0,373 s: casi 6 veces mas lento. El 83% del tiempo se fue en mantener
-- los indices, no en escribir los datos. Son 1,816 s de sobrecosto por 50.000
-- filas, o sea unos 0,036 ms por fila con los tres indices.
-- Extrapolando a 8.000 pedidos por hora, cada indice cuesta ~0,10 s por hora,
-- ~2,3 s al dia y ~14 min de CPU al año, y eso solo en PEDIDO: si el indice
-- fuera sobre PEDIDO_DETALLE seria el doble o el triple, porque cada pedido
-- tiene de 1 a 3 lineas.
-- El costo real no es solo tiempo: cada indice ocupa disco, alarga los
-- backups y consume memoria. Un indice puesto "por si acaso" que ninguna
-- consulta usa es costo puro sin beneficio, y se paga en cada escritura,
-- para siempre.
--
--  PREGUNTA 2.11 — Proponga la lista DEFINITIVA de índices para este
--  esquema. Para cada uno escriba: qué consulta lo justifica, y por qué
--  no se puede resolver con otro índice ya existente.
-- RTA/:
--
-- 1. PEDIDO (fecha_pedido, estado). Lo usan los informes mensuales y el
--    tablero. Ningun indice tiene la fecha, la PK es por id_pedido. Se
--    prefiere este orden porque tambien sirve a los informes que filtran
--    solo por fecha.
--
-- 2. PAGO (id_pedido). La FK del ejercicio 1.5. La PK es por id_pago, y
--    sin este indice borrar un pedido bloquea toda la tabla PAGO.
--
-- 3. PEDIDO_DETALLE (id_producto). Las ventas por producto y la FK hacia
--    PRODUCTO. La PK empieza por id_pedido, no sirve para buscar producto.
--
-- 4. PEDIDO (id_cliente). El historial por cliente, el informe de PREMIUM
--    inactivos y la FK hacia CLIENTE. La PK es por id_pedido.
--
-- 5. PRODUCTO (UPPER(nombre)). La busqueda de soporte del 2.2. El indice
--    normal sobre nombre no se usa cuando el predicado aplica UPPER.
--
-- SE DESCARTAN:
-- - PEDIDO (estado): ENTREGADO es el 62% de la tabla, el optimizador no lo
--   usa (ejercicio 2.3).
-- - PEDIDO (fecha_pedido, id_cliente): se solapa con el 1 y seria un tercer
--   indice sobre la tabla que mas escribe (ejercicio 2.5).
-- - FK sobre datos maestros (producto.id_categoria, categoria.id_padre,
--   inventario.id_bodega): de esas tablas casi no se borran filas.


-- =====================================================================
-- 03_sql_avanzado.sql   SQL analítico, jerárquico y MERGE
-- =====================================================================
-- #####################################################################
-- EJERCICIO 3.1 — Ranking dentro de grupos
-- #####################################################################

-- MODELO (resuelto)
WITH ventas AS (
  SELECT pr.id_categoria,
         pr.id_producto,
         pr.nombre,
         SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d ON d.id_pedido   = p.id_pedido
    JOIN producto       pr ON pr.id_producto = d.id_producto
   WHERE p.fecha_pedido >= DATE '2026-01-01'
     AND p.fecha_pedido <  DATE '2027-01-01'
     AND p.estado <> 'ANULADO'
   GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
)
SELECT id_categoria, nombre, facturado, puesto
  FROM (SELECT v.*,
               RANK() OVER (PARTITION BY id_categoria
                                  ORDER BY facturado DESC) AS puesto
          FROM ventas v)
 WHERE puesto <= 3
 ORDER BY id_categoria, puesto;
 
--  PREGUNTA 3.1 — Cambie DENSE_RANK por RANK y luego por ROW_NUMBER.
--  Explique en qué se diferencian los tres cuando hay empates, y cuál
--  usaría usted para un "top 3" que debe devolver exactamente 3 filas.
--
--  RTA 3.1/: Los tres numeran, pero se comportan distinto ante empates.
--  Un ejemplo con 10, 2, 2, 1:
--    ROW_NUMBER -> 1, 2, 3, 4   (nunca repite, desempata arbitrariamente)
--    RANK       -> 1, 2, 2, 4   (empata y deja hueco)
--    DENSE_RANK -> 1, 2, 2, 3   (empata y no deja hueco)
--  Para un top 3 que debe devolver EXACTAMENTE 3 filas se usa ROW_NUMBER,
--  porque es el unico que garantiza numeros unicos. Con DENSE_RANK o RANK,
--  un triple empate en el tercer puesto devolveria 5 filas.
-- 
--  ESCRIBA 3.1 — La misma consulta, pero mostrando además qué porcentaje
--  representa cada producto sobre el total facturado de su categoría.
--  Use RATIO_TO_REPORT o una función de ventana con SUM() OVER.

WITH ventas AS (
  SELECT pr.id_categoria, pr.id_producto, pr.nombre,
         SUM(d.cantidad * d.precio_unit) AS facturado
    FROM pedido p
    JOIN pedido_detalle d  ON d.id_pedido    = p.id_pedido
    JOIN producto       pr ON pr.id_producto = d.id_producto
   WHERE p.fecha_pedido >= DATE '2026-01-01'
     AND p.fecha_pedido <  DATE '2027-01-01'
     AND p.estado <> 'ANULADO'
   GROUP BY pr.id_categoria, pr.id_producto, pr.nombre
)
SELECT id_categoria, nombre, ROUND(facturado) AS facturado, puesto,
       ROUND(pct_categoria, 2) AS pct_categoria
  FROM (SELECT v.*,
               DENSE_RANK() OVER (PARTITION BY id_categoria
                                  ORDER BY facturado DESC) AS puesto,
               100 * RATIO_TO_REPORT(facturado)
                       OVER (PARTITION BY id_categoria)    AS pct_categoria
          FROM ventas v)
 WHERE puesto <= 3
 ORDER BY id_categoria, puesto;
-- #####################################################################
-- EJERCICIO 3.2 — Series de tiempo: acumulado y variación
-- #####################################################################

-- MODELO (resuelto)
WITH mensual AS (
  SELECT TRUNC(fecha_pedido, 'MM') AS mes,
         SUM(total)                AS ventas,
         COUNT(*)                  AS pedidos
    FROM pedido
   WHERE fecha_pedido >= DATE '2026-01-01'
     AND fecha_pedido <  DATE '2027-01-01'
     AND estado <> 'ANULADO'
   GROUP BY TRUNC(fecha_pedido, 'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM')                          AS mes,
       pedidos,
       ROUND(ventas)                                   AS ventas,
       ROUND(SUM(ventas) OVER (ORDER BY mes
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS acumulado,
       ROUND(LAG(ventas) OVER (ORDER BY mes))          AS mes_anterior,
       ROUND(100 * (ventas - LAG(ventas) OVER (ORDER BY mes))
                 / NULLIF(LAG(ventas) OVER (ORDER BY mes),0), 1) AS var_pct
  FROM mensual
 ORDER BY mes;
 
--  PREGUNTA 3.2 — ¿Qué diferencia hay entre
--     ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--  y  RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ?
--  Constrúyase un caso donde den resultados distintos.
--
--  RTA 3.2/: ROWS cuenta filas, RANGE cuenta valores. Con ROWS, "las 2
--  anteriores y la actual" son 3 filas y ya. Con RANGE, si hay filas que
--  tienen el mismo valor en el ORDER BY, las mete todas en la ventana.
--  Por eso solo dan distinto cuando hay empates: si hubiera dos filas del
--  mismo mes, con ROWS cada una ve su propio acumulado y con RANGE las dos
--  ven el mismo total. Aqui no se nota porque el GROUP BY deja un solo mes
--  por fila, o sea que no hay empates.

--  ESCRIBA 3.2 — Agregue una columna con el promedio móvil de los
--  últimos 3 meses (mes actual y los dos anteriores).

WITH mensual AS (
  SELECT TRUNC(fecha_pedido, 'MM') AS mes,
         SUM(total)                AS ventas,
         COUNT(*)                  AS pedidos
    FROM pedido
   WHERE fecha_pedido >= DATE '2026-01-01'
     AND fecha_pedido <  DATE '2027-01-01'
     AND estado <> 'ANULADO'
   GROUP BY TRUNC(fecha_pedido, 'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM')                          AS mes,
       pedidos,
       ROUND(ventas)                                   AS ventas,
       ROUND(SUM(ventas) OVER (ORDER BY mes
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS acumulado,
       ROUND(LAG(ventas) OVER (ORDER BY mes))          AS mes_anterior,
       ROUND(100 * (ventas - LAG(ventas) OVER (ORDER BY mes))
                 / NULLIF(LAG(ventas) OVER (ORDER BY mes),0), 1) AS var_pct,
               ROUND(AVG(ventas) OVER (ORDER BY mes
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) AS prom_movil_3m
  FROM mensual
 ORDER BY mes;
-- #####################################################################
-- EJERCICIO 3.3 — La misma respuesta, dos planes muy distintos
-- #####################################################################

-- VERSIÓN A — subconsulta correlacionada  (la que sale sola al escribir)
EXPLAIN PLAN FOR
SELECT c.id_cliente, c.nombre, p.id_pedido, p.fecha_pedido, p.total
  FROM cliente c
  JOIN pedido  p ON p.id_cliente = c.id_cliente
 WHERE c.segmento = 'PREMIUM'
   AND p.fecha_pedido = (SELECT MAX(p2.fecha_pedido)
                           FROM pedido p2
                          WHERE p2.id_cliente = c.id_cliente);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- VERSIÓN B — función analítica
EXPLAIN PLAN FOR
SELECT id_cliente, nombre, id_pedido, fecha_pedido, total
  FROM (SELECT c.id_cliente, c.nombre, p.id_pedido, p.fecha_pedido, p.total,
               ROW_NUMBER() OVER (PARTITION BY c.id_cliente
                                  ORDER BY p.fecha_pedido DESC) AS rn
          FROM cliente c
          JOIN pedido  p ON p.id_cliente = c.id_cliente
         WHERE c.segmento = 'PREMIUM')
 WHERE rn = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

--  PREGUNTA 3.3 — Compare los dos planes. ¿Cuántas veces se lee PEDIDO
--  en cada versión? ¿Cuál es el COST de cada una?

--  RTA 3.3/: PEDIDO se lee 1 vez en cada version: en los dos planes hay un
--  solo TABLE ACCESS FULL PEDIDO con 200.011 filas. En la version A se
--  esperarian dos lecturas por la subconsulta correlacionada, pero el
--  optimizador la transformo internamente en funcion de ventana: por eso su
--  plan muestra VW_WIF_1, un WINDOW SORT y el filtro VW_COL_6 IS NOT NULL,
--  que no aparecen en la consulta escrita.
--  COST version A = 1217 (WINDOW SORT)
--  COST version B = 1109 (WINDOW SORT PUSHED RANK)
--
--  PREGUNTA 3.4 — Las dos consultas NO son totalmente equivalentes:
--  hay un caso en el que devuelven distinto número de filas. ¿Cuál es?
--  (pista: piense en dos pedidos del mismo cliente el mismo día)

--  RTA 3.4/: Cuando un cliente tiene DOS pedidos con la misma fecha_pedido
--  y esa es su fecha maxima. La version A devuelve los dos, porque ambos
--  cumplen fecha_pedido = MAX(...). La version B devuelve uno solo, porque
--  ROW_NUMBER = 1 escoge uno arbitrariamente entre los empatados. Para que
--  B se comportara como A habria que usar RANK() en vez de ROW_NUMBER().

-- #####################################################################
-- EJERCICIO 3.4 — Jerarquías: la CTE recursiva
-- #####################################################################

-- MODELO (resuelto) — ruta completa de cada categoría
WITH arbol (id_categoria, nombre, id_padre, nivel, ruta) AS (
  SELECT id_categoria, nombre, id_padre, 1, CAST(nombre AS VARCHAR2(400))
    FROM categoria
   WHERE id_padre IS NULL
  UNION ALL
  SELECT c.id_categoria, c.nombre, c.id_padre, a.nivel + 1,
         a.ruta || ' > ' || c.nombre
    FROM categoria c
    JOIN arbol a ON c.id_padre = a.id_categoria
)
SELECT LPAD(' ', (nivel-1)*3) || nombre AS jerarquia, nivel, ruta
  FROM arbol
 ORDER BY ruta;

-- El equivalente con CONNECT BY, sintaxis propia de Oracle
SELECT LPAD(' ', (LEVEL-1)*3) || nombre AS jerarquia,
       LEVEL AS nivel,
       SYS_CONNECT_BY_PATH(nombre, ' > ') AS ruta
  FROM categoria
 START WITH id_padre IS NULL
CONNECT BY PRIOR id_categoria = id_padre
 ORDER SIBLINGS BY nombre;
 
--  PREGUNTA 3.5 — ¿Qué ventaja tiene la CTE recursiva sobre CONNECT BY?
--  ¿Y qué le da CONNECT BY que la CTE no?

--  RTA 3.5/: Funcionan distinto. La CTE recursiva trabaja por niveles: se
--  arranca con una consulta base (las categorias sin padre) y esa consulta
--  se vuelve a ejecutar contra el resultado anterior, sacando un nivel
--  completo en cada vuelta hasta que ya no salen filas nuevas. CONNECT BY
--  en cambio recorre rama por rama: baja por un hijo hasta el fondo, vuelve
--  y sigue con el siguiente.
--  De ahi salen las diferencias. Como la CTE es un SELECT normal repetido,
--  se le pueden meter joins con otras tablas y calcular las columnas que
--  uno quiera, pero todo hay que armarlo a mano: en el modelo tocó declarar
--  'nivel' y 'ruta' e irlas acumulando en cada vuelta. CONNECT BY, al ir
--  bajando por la rama, siempre sabe a que profundidad va y por donde paso,
--  y por eso entrega LEVEL y SYS_CONNECT_BY_PATH sin que uno haga nada, y
--  puede ordenar hermanos con ORDER SIBLINGS BY. Como contra, es sintaxis
--  propia de Oracle y su parte recursiva es mas rigida.
--
--  ESCRIBA 3.3 — Facturación total de 2026 por categoría RAÍZ.
--  Es decir: las ventas de "Portátiles" deben sumar dentro de
--  "Tecnología". Use la CTE recursiva para resolver a qué raíz pertenece
--  cada categoría hoja, y únala con las ventas.

WITH arbol (id_categoria, id_raiz, nombre_raiz) AS (
  SELECT id_categoria, id_categoria, nombre
    FROM categoria
   WHERE id_padre IS NULL
  UNION ALL
  SELECT c.id_categoria, a.id_raiz, a.nombre_raiz
    FROM categoria c
    JOIN arbol a ON c.id_padre = a.id_categoria
)
SELECT a.nombre_raiz,
       COUNT(DISTINCT p.id_pedido)            AS pedidos,
       ROUND(SUM(d.cantidad * d.precio_unit)) AS facturado
  FROM pedido p
  JOIN pedido_detalle d  ON d.id_pedido    = p.id_pedido
  JOIN producto       pr ON pr.id_producto = d.id_producto
  JOIN arbol          a  ON a.id_categoria = pr.id_categoria
 WHERE p.fecha_pedido >= DATE '2026-01-01'
   AND p.fecha_pedido <  DATE '2027-01-01'
   AND p.estado <> 'ANULADO'
 GROUP BY a.nombre_raiz
 ORDER BY facturado DESC;

-- #####################################################################
-- EJERCICIO 3.5 — MERGE: aplicar los ajustes de inventario
-- #####################################################################

-- PASO 1  Antes
SELECT SUM(disponible) AS stock_total FROM inventario;
SELECT motivo, COUNT(*), SUM(delta) FROM ajuste_inventario GROUP BY motivo;

-- MODELO (resuelto)
MERGE INTO inventario i
USING (SELECT id_producto, id_bodega, SUM(delta) AS delta
         FROM ajuste_inventario
        GROUP BY id_producto, id_bodega) a
   ON (i.id_producto = a.id_producto AND i.id_bodega = a.id_bodega)
 WHEN MATCHED THEN
   UPDATE SET i.disponible = GREATEST(i.disponible + a.delta, 0),
              i.version    = i.version + 1
 WHEN NOT MATCHED THEN
   INSERT (i.id_producto, i.id_bodega, i.disponible, i.reservado, i.version)
   VALUES (a.id_producto, a.id_bodega, GREATEST(a.delta,0), 0, 0);

--> Mire el mensaje de SQL Developer: cuántas filas fusionó.
-- RTA/:500 filas fusionadas.
COMMIT;
-- PASO 2  Después
SELECT SUM(disponible) AS stock_total FROM inventario;

--  PREGUNTA 3.6 — ¿Por qué se agrupa la tabla de ajustes dentro del
--  USING en lugar de usarla directamente? ¿Qué error da Oracle si un
--  mismo (producto, bodega) aparece dos veces en el origen?
--
--  RTA 3.6/: Porque la tabla de ajustes puede traer varios movimientos del
--  mismo producto en la misma bodega, por ejemplo una merma y un ingreso.
--  MERGE necesita saber con que fila actualizar cada fila del inventario, y
--  si le llegan dos no sabe cual escoger. En ese caso no aplica ninguna:
--  falla toda la sentencia con el error ORA-30926.
--  Al agrupar con SUM(delta) queda una sola fila por producto y bodega, que
--  ademas es lo correcto: lo que se quiere aplicar es el saldo de todos los
--  movimientos, no uno de ellos.

--  PREGUNTA 3.7 — El GREATEST(..., 0) evita que el stock quede negativo.
--  ¿Es esa la forma correcta de resolverlo, o está escondiendo un
--  problema? ¿Qué haría usted en un sistema real?

--  RTA 3.7/: Lo esta escondiendo. Si el inventario tiene 3 unidades y llega
--  una merma de 10, el GREATEST guarda 0 y nadie se entera de que faltaron
--  7. La diferencia entre lo que dice el sistema y lo que hay fisicamente en
--  bodega se pierde sin dejar rastro.
--  En un sistema real yo dejaria que el ajuste falle la tabla ya tiene la
--  restriccion CHECK (disponible >= 0) para eso. Los ajustes que no cuadran
--  se separan de los que si, se guardan en una tabla de excepciones con su
--  motivo, y se le avisa a bodega para que haga conteo fisico.
--  La regla: un dato que no cuadra se reporta, no se redondea.

--
--  ESCRIBA 3.4 — Modifique el MERGE para que además registre en la
--  cláusula WHEN MATCHED ... DELETE las filas de inventario que queden
--  en cero y estén en una bodega distinta de la 1.

--  ESCRIBA 3.4 — MERGE que ademas borra las filas que quedan en cero
MERGE INTO inventario i
USING (SELECT id_producto, id_bodega, SUM(delta) AS delta
         FROM ajuste_inventario
        GROUP BY id_producto, id_bodega) a
   ON (i.id_producto = a.id_producto AND i.id_bodega = a.id_bodega)
 WHEN MATCHED THEN
   UPDATE SET i.disponible = GREATEST(i.disponible + a.delta, 0),
              i.version    = i.version + 1
   DELETE WHERE i.disponible = 0 AND i.id_bodega <> 1
 WHEN NOT MATCHED THEN
   INSERT (i.id_producto, i.id_bodega, i.disponible, i.reservado, i.version)
   VALUES (a.id_producto, a.id_bodega, GREATEST(a.delta,0), 0, 0);

-- #####################################################################
-- EJERCICIO 3.6 — PIVOT y LISTAGG
-- #####################################################################
-- MODELO (resuelto) — ventas por canal y trimestre, en columnas
SELECT *
  FROM (SELECT canal,
               'T' || TO_CHAR(fecha_pedido,'Q') AS trimestre,
               total
          FROM pedido
         WHERE fecha_pedido >= DATE '2026-01-01'
           AND fecha_pedido <  DATE '2027-01-01'
           AND estado <> 'ANULADO')
 PIVOT (ROUND(SUM(total)) FOR trimestre IN ('T1' AS t1, 'T2' AS t2,
                                            'T3' AS t3, 'T4' AS t4))
 ORDER BY canal;
 
-- MODELO (resuelto) — los 10 mejores clientes y qué categorías compraron
SELECT c.id_cliente, c.nombre,
       ROUND(SUM(d.cantidad * d.precio_unit)) AS facturado,
       LISTAGG(DISTINCT cat.nombre, ', ')
         WITHIN GROUP (ORDER BY cat.nombre) AS categorias
  FROM cliente c
  JOIN pedido         p   ON p.id_cliente   = c.id_cliente
  JOIN pedido_detalle d   ON d.id_pedido    = p.id_pedido
  JOIN producto       pr  ON pr.id_producto = d.id_producto
  JOIN categoria      cat ON cat.id_categoria = pr.id_categoria
 WHERE p.estado <> 'ANULADO'
 GROUP BY c.id_cliente, c.nombre
 ORDER BY facturado DESC
 FETCH FIRST 10 ROWS WITH TIES;

--  PREGUNTA 3.8 — ¿Qué diferencia hay entre FETCH FIRST 10 ROWS ONLY y
--  FETCH FIRST 10 ROWS WITH TIES? ¿En cuál de los dos casos puede
--  devolver más de 10 filas y por qué?

--  RTA 3.8/: ONLY corta en 10 filas exactas, sin importar si la fila 11
--  tiene el mismo valor que la 10. WITH TIES devuelve esas 10 mas todas las
--  que esten empatadas con la ultima segun la columna del ORDER BY.
--  El que puede devolver mas de 10 es WITH TIES: si el cliente numero 10 y
--  el 11 facturaron exactamente lo mismo, los trae a los dos, porque no
--  tiene forma de decidir cual dejar por fuera. Solo tiene sentido usarlo
--  con ORDER BY, que es lo que define el criterio del empate.
--
--  ESCRIBA 3.5 — Un informe de "clientes en riesgo": clientes PREMIUM
--  cuyo último pedido tiene más de 120 días, mostrando cuántos días
--  llevan sin comprar y cuánto facturaron históricamente.

--  ESCRIBA 3.5 — Clientes PREMIUM sin comprar hace mas de 120 dias
WITH actividad AS (
  SELECT id_cliente,
         MAX(fecha_pedido) AS ultima_compra,
         COUNT(*)          AS pedidos_historicos,
         SUM(total)        AS facturacion_historica
    FROM pedido
   WHERE estado <> 'ANULADO'
   GROUP BY id_cliente
)
SELECT c.id_cliente,
       c.nombre,
       c.ciudad,
       TRUNC(a.ultima_compra)                AS ultima_compra,
       TRUNC(SYSDATE - a.ultima_compra)      AS dias_inactivo,
       a.pedidos_historicos,
       ROUND(a.facturacion_historica)        AS facturado_historico
  FROM cliente   c
  JOIN actividad a ON a.id_cliente = c.id_cliente
 WHERE c.segmento = 'PREMIUM'
   AND a.ultima_compra < SYSDATE - 120
 ORDER BY dias_inactivo DESC;

-- =====================================================================
-- 04_reto.sql   Reto final (25 minutos)
-- =====================================================================
--   "Tenemos tres problemas desde el Black Friday:
--    1. Estamos vendiendo más unidades de las que hay en bodega. El
--       inventario del sistema no coincide con el físico y ya nos tocó
--       cancelar 40 pedidos.
--    2. Cuando la confirmación falla a la mitad, quedan pedidos en
--       estado PAGADO con el inventario ya descontado, o al revés.
--       Nadie sabe cuáles.
--    3. El tablero de la gerencia se demora casi un minuto en abrir.
-- ---------------------------------------------------------------------
-- #####################################################################
-- PIEZA 2 — La consulta del tablero de gerencia
-- #####################################################################

SELECT c.ciudad,
       COUNT(DISTINCT p.id_pedido)              AS pedidos,
       ROUND(SUM(d.cantidad * d.precio_unit))   AS facturado,
       ROUND(AVG(p.total))                      AS ticket
  FROM pedido         p
  JOIN cliente        c ON c.id_cliente  = p.id_cliente
  JOIN pedido_detalle d ON d.id_pedido   = p.id_pedido
 WHERE TO_CHAR(p.fecha_pedido, 'YYYY-MM') = '2026-03'
   AND p.estado <> 'ANULADO'
 GROUP BY c.ciudad
 ORDER BY facturado DESC;
-- #####################################################################
-- LO QUE HAY QUE ENTREGAR
-- #####################################################################
--
-- A. DIAGNÓSTICO  (4 puntos)
--    Identifique CUATRO defectos en la secuencia de la PIEZA 1.
--    Para cada uno indique:
--      - qué sentencia o qué parte de la secuencia lo causa
--      - cuál de los tres síntomas del ticket produce
--      - qué pasa en producción con 200 confirmaciones por minuto
--    Pista: uno es de concurrencia, uno es de transaccionalidad, uno
--    hace que el problema pase inadvertido, y uno es de rendimiento.

--    Para el primero, reprodúzcalo: ejecuten la secuencia desde las DOS
--    conexiones sobre el mismo producto y muestren el resultado.

-- A. DIAGNOSTICO
--
-- Defecto 1 - Concurrencia
-- El SELECT lee el stock pero no lo bloquea, y despues el UPDATE escribe un
-- numero fijo que la aplicacion calculo aparte (SET disponible = 7). Si otra
-- confirmacion del mismo producto se cuela en el medio, la segunda le escribe
-- encima a la primera y esa venta desaparece. Es el sintoma 1 del ticket:
-- se venden mas unidades de las que hay. Con 200 confirmaciones por minuto
-- esos cruces pasan todo el tiempo, y el inventario del sistema termina
-- siempre por encima del que hay en bodega.
--
-- Defecto 2 - Transaccionalidad
-- Hay tres COMMIT, uno por cada linea. Cada uno es un punto sin retorno, asi
-- que la confirmacion deja de ser una sola operacion. Si el proceso se cae
-- despues del primero, el producto 100 quedo descontado, el 200 no, y el
-- pedido sigue en CREADO. Ya no se puede deshacer nada. Es el sintoma 2, y
-- en produccion basta una caida o un timeout para dejar un pedido a medias.
--
-- Defecto 3 - El que hace que nadie se entere
-- Ninguna sentencia revisa cuantas filas afecto ni si alcanzaba el stock, y
-- el UPDATE del pedido tampoco verifica que estuviera en CREADO, asi que un
-- pedido se puede pagar dos veces. Como el valor lo pone la aplicacion y
-- siempre es positivo,como el valor lo calcula la aplicacion y lo escribe ya listo, el CHECK
-- (disponible >= 0) que si existe en la tabla nunca llega a evaluarse: le
-- llega un numero positivo y lo aprueba. La proteccion esta puesta, pero la
-- forma de escribir el UPDATE la esquiva. Este defecto no causa un sintoma
-- propio, lo que hace es tapar los otros dos. Por eso el problema aparecio
-- contando en bodega y no en un log de errores.
--
-- Defecto 4 - Rendimiento
-- La aplicacion manda un SELECT y un UPDATE por cada linea del pedido, en
-- viajes separados, y confirma en cada paso. Va de a una fila cuando podria
-- hacerlo todo en una sola sentencia. Con 200 confirmaciones por minuto eso
-- son cientos de sentencias y de COMMIT por minuto, y cada COMMIT obliga a
-- escribir en disco. Ademas la secuencia dura mas, que es justo cuando el
-- defecto 1 tiene chance de aparecer.
--
--
-- B. CORRECCIÓN  (4 puntos)
--    Reescriba la secuencia usando SQL. Debe cumplir las cuatro cosas:
--      1. que dos confirmaciones simultáneas del mismo producto no
--         puedan perder unidades
--      2. que sea atómica: o se confirma todo el pedido, o nada
--      3. que se note cuando algo no se aplicó, en lugar de pasar en
--         silencio
--      4. que no permita dejar el inventario en negativo
--
--    Debe resolverse con las herramientas que ya vieron hoy:
--      - SELECT ... FOR UPDATE   (parte 1)
--      - UPDATE ... SET col = col - n
--      - MERGE                   (parte 3)
--      - un solo COMMIT al final
--      - la restricción CHECK que ya tiene la tabla INVENTARIO
--
--    Demuéstrelo: ejecute su versión desde las DOS conexiones al mismo
--    tiempo sobre el mismo producto y muestre que el resultado es
--    correcto. Documente cómo lo probó.

-- Dejar el escenario en un valor conocido para poder probar
UPDATE inventario SET disponible = 10 WHERE id_producto IN (100,200) AND id_bodega = 1;
UPDATE pedido SET estado = 'CREADO' WHERE id_pedido = 950001;
COMMIT;
--- secuencia corregida ------------------------------------------------

-- 1. Bloquear TODAS las filas de inventario del pedido, en orden fijo
SELECT i.id_producto, i.disponible
  FROM inventario i
  JOIN pedido_detalle d ON d.id_producto = i.id_producto
 WHERE d.id_pedido = 950001
   AND i.id_bodega = 1
 ORDER BY i.id_producto
   FOR UPDATE OF i.disponible;

-- 2. Descontar TODO el pedido con UNA sola sentencia de conjunto
MERGE INTO inventario i
USING (SELECT id_producto, SUM(cantidad) AS cantidad
         FROM pedido_detalle
        WHERE id_pedido = 950001
        GROUP BY id_producto) d
   ON (i.id_producto = d.id_producto AND i.id_bodega = 1)
 WHEN MATCHED THEN
   UPDATE SET i.disponible = i.disponible - d.cantidad,
              i.version    = i.version + 1;
--> Debe decir "2 filas fusionadas". Si dice menos, ROLLBACK.

-- 3. Marcar el pedido SOLO si estaba en CREADO
UPDATE pedido
   SET estado = 'PAGADO'
 WHERE id_pedido = 950001
   AND estado    = 'CREADO';
--> Debe decir "1 fila actualizada". Si dice 0, alguien ya lo pagó: ROLLBACK.

-- 4. Un solo COMMIT
COMMIT;

--
-- C. OPTIMIZACIÓN DE LA CONSULTA  (1 punto)
--
--      - Capture el plan actual y anote COST y consistent gets
--      - Identifique qué impide el uso del índice
--      - Reescriba la consulta y/o cree el índice necesario
--      - Capture el plan nuevo y anote la mejora
--      - Justifique el índice: qué consulta lo usa y por qué no bastaba
--        con los que ya existen
--  RTA/:
--
-- PLAN ACTUAL:  COST = 941   consistent gets = 3295
-- PEDIDO entra con TABLE ACCESS FULL, leyendo las 200.000 filas para
-- devolver solo unos 3.946 pedidos de marzo.
--
-- QUE IMPIDE EL USO DEL INDICE:
-- En la seccion de predicados del plan aparece:
--   TO_CHAR(INTERNAL_FUNCTION(P.FECHA_PEDIDO),'YYYY-MM')='2026-03'
-- El TO_CHAR le cambia el valor a la columna. El indice guarda la fecha tal
-- cual, no convertida a texto, asi que Oracle no puede buscar ahi el valor
-- '2026-03' y le toca leer cada fila, convertirla y comparar.
-- Es el mismo error del ejercicio 2.2, esta vez con fechas.
--
-- CORRECCION: cambiar el TO_CHAR por un rango de fechas, dejando la columna
-- sin funciones encima. El < en vez de <= es porque el tipo DATE incluye la
-- hora, y con <= se perderian los pedidos del 31 de marzo despues de las
-- 00:00.

-- Consulta corregida
SELECT c.ciudad,
       COUNT(DISTINCT p.id_pedido)              AS pedidos,
       ROUND(SUM(d.cantidad * d.precio_unit))   AS facturado,
       ROUND(AVG(p.total))                      AS ticket
  FROM pedido         p
  JOIN cliente        c ON c.id_cliente  = p.id_cliente
  JOIN pedido_detalle d ON d.id_pedido   = p.id_pedido
 WHERE p.fecha_pedido >= DATE '2026-03-01'
   AND p.fecha_pedido <  DATE '2026-04-01'
   AND p.estado <> 'ANULADO'
 GROUP BY c.ciudad
 ORDER BY facturado DESC;
--
-- PLAN NUEVO:   COST = __938____   consistent gets = ___3295___
--
-- RESULTADO DE LA CORRECCION:
-- Con el filtro escrito como rango, la columna queda limpia y el indice ya
-- se puede usar. Aun asi el optimizador prefirio el FULL SCAN, y hace bien:
-- IX_PEDIDO_FECHA_ESTADO tiene clustering factor 200.001, igual a NUM_ROWS,
-- o sea que cada entrada del indice apunta a un bloque distinto. Traer las
-- ~9.395 filas de marzo por ahi serian 9.395 lecturas sueltas contra 479 de
-- leer la tabla de corrido.
-- La diferencia de fondo: antes el indice era imposible de usar, ahora es
-- posible pero no conviene. El TO_CHAR bloqueaba cualquier optimizacion.
--
-- POR QUE NO SE CREA OTRO INDICE:
-- Uno de cobertura sobre (fecha_pedido, estado, id_cliente, total) si
-- bajaria el costo, porque evitaria tocar la tabla. No se propone porque
-- PEDIDO es la tabla que mas escrituras recibe y en el ejercicio 2.5 medimos
-- que los indices multiplican por 5 el tiempo de insercion. Para un tablero
-- que se abre unas pocas veces al dia, no compensa.

EXPLAIN PLAN FOR
SELECT /*+ INDEX(p ix_pedido_fecha_estado) */
       c.ciudad, COUNT(DISTINCT p.id_pedido),
       ROUND(SUM(d.cantidad * d.precio_unit)), ROUND(AVG(p.total))
  FROM pedido p
  JOIN cliente c ON c.id_cliente = p.id_cliente
  JOIN pedido_detalle d ON d.id_pedido = p.id_pedido
 WHERE p.fecha_pedido >= DATE '2026-03-01'
   AND p.fecha_pedido <  DATE '2026-04-01'
   AND p.estado <> 'ANULADO'
 GROUP BY c.ciudad;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- en el plan anterior se ve como al forzar el uso del indice aumenta muchisimo el costo por el clustering factor,
--  por eso es que el optimizador sigue viendo como a mejor opcion el table access full ignorando el indice.


-- 1. Clustering factor de cada indice frente al tamaño real de la tabla
SELECT i.index_name,
       i.clustering_factor,
       i.num_rows,
       t.blocks AS bloques_tabla,
       ROUND(i.clustering_factor / t.blocks, 1) AS veces_peor_que_lo_ideal
  FROM user_indexes i
  JOIN user_tables  t ON t.table_name = i.table_name
 WHERE i.table_name = 'PEDIDO'
 ORDER BY i.clustering_factor;
-- se ve que el clustering factor es enorme empeorando el uso del indice y la unica forma de 
-- arreglar eso es reincertando los datos de manera ordenada en la tabla,
-- lo cual llevaria mucho tiempo y traeria otros problemas.

--
-- D. UNA RECOMENDACIÓN  (1 punto)
--
--    En un párrafo: ¿qué le diría al jefe de Operaciones para que este
--    problema no vuelva a aparecer? No hable de esta consulta ni de
--    estas sentencias: hable de la práctica que hay que cambiar.

-- RTA/:
-- El problema no es un pedido en particular, sino donde estan guardadas las
-- reglas del negocio. Hay tres que no se pueden romper nunca: que el
-- inventario no quede en negativo, que un pedido no se pague dos veces, y
-- que descontar el inventario y marcar el pedido pasen siempre juntos o
-- ninguno de los dos. Hoy esas reglas estan escritas dentro del codigo de
-- cada canal (la tienda web, la app, el call center y los procesos de
-- bodega), y todos escriben sobre las mismas tablas. Cada equipo las
-- interpreta a su manera, asi que basta con que uno la haga mal para
-- descuadrar el inventario de todos, y ningun otro se entera.
-- Lo que hay que cambiar es eso: las tres reglas deben estar en la base de
-- datos, que es el unico punto por donde pasan todos los canales, y cada
-- confirmacion de pago debe guardarse completa o no guardarse, avisando
-- cuando algo no se pudo aplicar en vez de seguir callada. Ademas hay que
-- cambiar como se prueba: hoy se prueba con un usuario a la vez y asi todo
-- funciona, pero el error solo aparece cuando varios clientes compran el
-- mismo producto al mismo tiempo, y eso hay que probarlo antes de cada
-- temporada alta.
