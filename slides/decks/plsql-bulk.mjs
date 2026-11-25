export default {
  file: "bulk-collect-y-forall",
  out: "evidencias/bd2/07-plsql/investigacion",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 11,
  slides: [
    { type: "cover", title: "BULK COLLECT Y FORALL", subtitle: "Procesamiento masivo en PL/SQL" },
    {
      type: "text",
      title: "¿QUÉ PROBLEMA RESUELVEN?",
      text: "Cuando un bloque PL/SQL ejecuta SQL dentro de un ciclo, cada fila obliga a pasar del motor PL/SQL al motor SQL y volver. Ese **cambio de contexto** cuesta poco una vez, pero con miles de filas se vuelve el cuello de botella.",
      note: "Tom Kyte lo llamaba procesar “slow-by-slow” en vez de “row-by-row”.",
    },
    {
      type: "steps",
      title: "EL CAMBIO DE CONTEXTO",
      steps: [
        { t: "Motor PL/SQL", d: "Ejecuta el ciclo, las variables y la lógica procedural." },
        { t: "Cambio de contexto", d: "Cada SELECT, INSERT o UPDATE se envía al motor SQL." },
        { t: "Motor SQL", d: "Ejecuta la sentencia y devuelve el resultado al PL/SQL." },
      ],
      note: "10.000 filas en un FOR = 10.000 viajes de ida y vuelta. Con operaciones masivas = unos pocos viajes.",
    },
    {
      type: "bullets",
      title: "BULK COLLECT",
      cols: 1,
      items: [
        "Trae **muchas filas en una sola llamada** y las guarda en una colección.",
        "Se usa en `SELECT ... BULK COLLECT INTO` o en `FETCH ... BULK COLLECT INTO`.",
        "Colecciones válidas: tablas anidadas, VARRAY y arreglos asociativos.",
        "No lanza NO_DATA_FOUND: si no hay filas la colección queda vacía (`.COUNT = 0`).",
        "Con la cláusula **LIMIT** se procesa por lotes y no se llena la memoria (PGA).",
      ],
    },
    {
      type: "code",
      title: "BULK COLLECT POR LOTES",
      code: `DECLARE
  CURSOR c_prod IS
    SELECT id_producto, precio FROM producto;
  TYPE t_prod IS TABLE OF c_prod%ROWTYPE;
  v_lote t_prod;
BEGIN
  OPEN c_prod;
  LOOP
    FETCH c_prod BULK COLLECT INTO v_lote LIMIT 500;
    EXIT WHEN v_lote.COUNT = 0;
    FOR i IN 1 .. v_lote.COUNT LOOP
      NULL; -- lógica sobre v_lote(i)
    END LOOP;
  END LOOP;
  CLOSE c_prod;
END;`,
      side: [
        "Cada FETCH trae hasta **500 filas** de una vez.",
        "La salida se controla con `v_lote.COUNT = 0`, no con `%NOTFOUND`: el último lote puede venir incompleto.",
        "Un LIMIT entre 100 y 1000 suele ser buen equilibrio entre memoria y velocidad.",
      ],
    },
    {
      type: "bullets",
      title: "FORALL",
      cols: 1,
      items: [
        "Envía **una sola sentencia DML** (INSERT, UPDATE, DELETE, MERGE) con todos los valores de la colección.",
        "No es un ciclo: dentro solo puede ir una sentencia DML.",
        "`INDICES OF` y `VALUES OF` permiten recorrer colecciones con huecos.",
        "`SQL%BULK_ROWCOUNT(i)` dice cuántas filas afectó cada elemento.",
        "`SAVE EXCEPTIONS` deja seguir aunque fallen algunas filas y las reporta al final.",
      ],
    },
    {
      type: "code",
      title: "FORALL CON SAVE EXCEPTIONS",
      code: `DECLARE
  TYPE t_ids IS TABLE OF producto.id_producto%TYPE;
  v_ids t_ids;
  e_bulk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk, -24381);
BEGIN
  SELECT id_producto BULK COLLECT INTO v_ids
    FROM producto WHERE categoria = 'ASEO';

  FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
    UPDATE producto SET precio = precio * 1.05
     WHERE id_producto = v_ids(i);
EXCEPTION
  WHEN e_bulk THEN
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('Fila ' ||
        SQL%BULK_EXCEPTIONS(j).ERROR_INDEX || ': ' ||
        SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
END;`,
      side: [
        "Un solo viaje al motor SQL para todo el UPDATE.",
        "ORA-24381 se lanza **al final**, con la lista de filas que fallaron.",
        "Sin SAVE EXCEPTIONS el primer error detiene todo el FORALL.",
      ],
    },
    {
      type: "compare",
      title: "FILA POR FILA VS MASIVO",
      cols: [
        { title: "Fila por fila", items: ["Un cambio de contexto por cada fila.", "Más fácil de leer para lógica compleja.", "Aceptable con pocas filas.", "Errores se manejan uno por uno, en el momento."] },
        { title: "BULK COLLECT + FORALL", items: ["Unos pocos cambios de contexto por lote.", "Mucho más rápido con miles de filas.", "Usa memoria: siempre con LIMIT en tablas grandes.", "Errores agrupados con SAVE EXCEPTIONS."] },
      ],
      note: "Si se puede hacer con una sola sentencia SQL (INSERT ... SELECT, MERGE), eso sigue siendo lo más rápido.",
    },
    {
      type: "text",
      title: "RELACIÓN CON EL TALLER",
      text: "En el taller PL/SQL recorrimos productos y movimientos con cursores fila por fila. Para un inventario real, con miles de movimientos por día, ese mismo proceso se reescribiría con **BULK COLLECT LIMIT** para leer y **FORALL** para actualizar el stock en lote.",
      icon: "database",
    },
    {
      type: "bullets",
      title: "CONCLUSIONES",
      cols: 1,
      items: [
        "El costo no está en el SQL sino en los **viajes** entre los dos motores.",
        "BULK COLLECT reduce los viajes de lectura; FORALL, los de escritura.",
        "LIMIT protege la memoria; SAVE EXCEPTIONS protege el proceso de un error aislado.",
        "Primero intentar SQL puro; si hace falta lógica procedural, usar operaciones masivas.",
      ],
    },
    {
      type: "refs",
      items: [
        "Oracle. *PL/SQL Language Reference 19c* — capítulo “Bulk SQL and Bulk Binding”.",
        "Feuerstein, S. y Pribyl, B. (2014). *Oracle PL/SQL Programming* (6.ª ed.). O'Reilly.",
        "Kyte, T. y Kuhn, D. (2014). *Expert Oracle Database Architecture* (3.ª ed.). Apress.",
        "Oracle Live SQL — tutorial “Bulk Processing with BULK COLLECT and FORALL”.",
      ],
    },
    { type: "thanks" },
  ],
};
