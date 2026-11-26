// Investigaciones cortas para las secciones 01–04 (solo tenían script).
const byline = "Santiago Gómez · Bases de Datos II · Universidad El Bosque";
const B = "evidencias/bd2";

export default [
  {
    file: "orden-logico-de-una-consulta-sql", out: `${B}/01-repaso-sql`, byline, seed: 81,
    slides: [
      { type: "cover", title: "EL ORDEN LÓGICO DE UNA CONSULTA SQL", subtitle: "Se escribe en un orden, se ejecuta en otro" },
      { type: "steps", title: "ASÍ LA PROCESA EL MOTOR", steps: [
        { t: "FROM / JOIN", d: "Arma las filas de las tablas unidas." },
        { t: "WHERE", d: "Filtra filas una por una." },
        { t: "GROUP BY / HAVING", d: "Agrupa y filtra grupos." },
        { t: "SELECT", d: "Calcula columnas y alias." },
        { t: "ORDER BY", d: "Ordena el resultado final." },
      ], note: "Es un orden lógico: el optimizador puede ejecutar distinto, pero el resultado debe ser el mismo." },
      { type: "bullets", title: "¿QUÉ EXPLICA?", cols: 1, items: [
        "Por qué un **alias del SELECT** no se puede usar en el WHERE, pero sí en el ORDER BY.",
        "Por qué una función de agregación va en **HAVING** y no en WHERE.",
        "Por qué una condición sobre la tabla derecha de un LEFT JOIN en el WHERE lo vuelve un INNER JOIN.",
      ] },
      { type: "refs", items: [
        "Oracle. *Database SQL Language Reference 19c* — sentencia SELECT.",
        "Ben-Gan, I. (2016). *T-SQL Fundamentals* (3.ª ed.), cap. 2 “Logical query processing”. Microsoft Press.",
      ] },
      { type: "thanks" },
    ],
  },
  {
    file: "funciones-de-ventana-rows-vs-range", out: `${B}/02-sql-avanzado`, byline, seed: 83,
    slides: [
      { type: "cover", title: "FUNCIONES DE VENTANA: ROWS VS RANGE", subtitle: "El marco que decide qué filas entran en el cálculo" },
      { type: "compare", title: "DOS FORMAS DE MARCAR LA VENTANA", cols: [
        { title: "ROWS", items: ["Cuenta **filas físicas**.", "`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` = la fila y las 2 anteriores.", "Ideal para promedios móviles."] },
        { title: "RANGE", items: ["Cuenta por **valor** del ORDER BY.", "Las filas empatadas entran juntas.", "Es el marco por defecto cuando hay ORDER BY."] },
      ] },
      { type: "code", title: "LA DIFERENCIA EN UN ACUMULADO", code: `SELECT fecha, monto,
       SUM(monto) OVER (ORDER BY fecha) AS acum_range,
       SUM(monto) OVER (ORDER BY fecha
         ROWS UNBOUNDED PRECEDING)      AS acum_rows
  FROM ventas;`, side: [
        "Si dos ventas tienen la misma fecha, `acum_range` les da el **mismo** total.",
        "`acum_rows` las suma una por una.",
        "Error típico: creer que el acumulado por defecto va fila a fila.",
      ] },
      { type: "refs", items: [
        "Oracle. *Database SQL Language Reference 19c* — “Analytic Functions”, windowing_clause.",
        "Winand, M. *Modern SQL* — “OVER and the window frame”. modern-sql.com.",
      ] },
      { type: "thanks" },
    ],
  },
  {
    file: "mvcc-y-consistencia-de-lectura", out: `${B}/03-transacciones`, byline, seed: 85,
    slides: [
      { type: "cover", title: "MVCC Y CONSISTENCIA DE LECTURA", subtitle: "Por qué en Oracle leer no bloquea escribir" },
      { type: "text", title: "LA IDEA", text: "Oracle guarda las versiones anteriores de los datos en el **undo**. Cuando una consulta empieza, ve los datos tal como estaban en ese instante (su **SCN**), aunque otra sesión los esté cambiando." },
      { type: "bullets", title: "CONSECUENCIAS", cols: 1, items: [
        "Los lectores **no bloquean** a los escritores y los escritores no bloquean a los lectores.",
        "No existen las lecturas sucias: nunca se ve un cambio sin COMMIT.",
        "Si el undo se sobrescribe antes de terminar una consulta larga aparece **ORA-01555** (snapshot too old).",
        "En SERIALIZABLE la foto es de toda la transacción, no solo de cada sentencia.",
      ] },
      { type: "refs", items: [
        "Oracle. *Database Concepts 19c* — “Data Concurrency and Consistency”.",
        "Kyte, T. y Kuhn, D. (2014). *Expert Oracle Database Architecture* (3.ª ed.), cap. 7. Apress.",
      ] },
      { type: "thanks" },
    ],
  },
  {
    file: "indices-btree-vs-bitmap", out: `${B}/04-optimizacion-indices`, byline, seed: 87,
    slides: [
      { type: "cover", title: "ÍNDICES B-TREE VS BITMAP", subtitle: "Dos estructuras para dos tipos de datos" },
      { type: "compare", title: "COMPARACIÓN", cols: [
        { title: "B-tree", items: ["Árbol balanceado con el valor y el ROWID.", "Bueno para columnas con **muchos valores distintos**.", "Soporta bien muchas escrituras concurrentes.", "El índice por defecto en Oracle."] },
        { title: "Bitmap", items: ["Un mapa de bits por cada valor distinto.", "Bueno para **pocos valores** (sexo, estado, región).", "Combina condiciones con AND/OR muy rápido.", "Bloquea mucho al actualizar: solo para bodegas de datos."] },
      ] },
      { type: "code", title: "CUÁNDO USAR CADA UNO", code: `-- OLTP: búsqueda por un valor muy selectivo
CREATE INDEX idx_cliente_doc ON cliente(documento);

-- Bodega: filtros combinados sobre pocos valores
CREATE BITMAP INDEX bix_venta_region ON fact_venta(region);
CREATE BITMAP INDEX bix_venta_canal  ON fact_venta(canal);`, side: [
        "En OLTP un bitmap puede causar bloqueos y deadlocks.",
        "En una bodega, con cargas por lotes, el bitmap es pequeño y rápido.",
      ] },
      { type: "refs", items: [
        "Oracle. *Database Concepts 19c* — “Indexes and Index-Organized Tables”.",
        "Oracle. *Database Data Warehousing Guide 19c* — “Using Bitmap Indexes”.",
      ] },
      { type: "thanks" },
    ],
  },
];
