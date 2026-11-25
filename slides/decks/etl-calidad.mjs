export default {
  file: "calidad-y-limpieza-de-datos",
  out: "evidencias/bd2/08-etl",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 61,
  slides: [
    { type: "cover", title: "CALIDAD Y LIMPIEZA DE DATOS", subtitle: "La “T” del ETL: transformar sin perder la confianza en el dato" },
    {
      type: "text",
      title: "¿POR QUÉ IMPORTA?",
      text: "Un reporte es tan bueno como los datos que lo alimentan. Si un cliente aparece tres veces o una fecha viene en otro formato, el resultado **se ve correcto pero está mal**, y nadie lo nota hasta tomar una mala decisión.",
      note: "“Garbage in, garbage out.”",
      icon: "funnel",
    },
    {
      type: "table",
      title: "DIMENSIONES DE CALIDAD",
      head: ["Dimensión", "Pregunta que responde"],
      rows: [
        ["Exactitud", "¿El dato refleja la realidad?"],
        ["Completitud", "¿Están todos los campos obligatorios?"],
        ["Consistencia", "¿Dice lo mismo en todas las fuentes?"],
        ["Unicidad", "¿Cada entidad aparece una sola vez?"],
        ["Validez", "¿Cumple el formato y el rango permitido?"],
        ["Oportunidad", "¿Llega a tiempo para ser útil?"],
      ],
    },
    {
      type: "bullets",
      title: "PROBLEMAS TÍPICOS",
      cols: 2,
      items: [
        "Nulos donde no debería haberlos.",
        "Duplicados por errores de captura o por unir dos sistemas.",
        "Fechas en formatos mezclados: `25/11/2026`, `2026-11-25`.",
        "Textos con espacios, tildes y mayúsculas distintas.",
        "Mismo valor escrito de varias formas: `Bogotá`, `BOGOTA`, `Bogota D.C.`",
        "Valores imposibles: edades negativas, precios en cero.",
        "Llaves que apuntan a registros que ya no existen.",
      ],
    },
    {
      type: "steps",
      title: "EL PROCESO",
      steps: [
        { t: "Perfilar", d: "Medir antes de tocar: conteos, nulos, valores distintos, mínimos y máximos." },
        { t: "Limpiar", d: "Estandarizar formatos, corregir y deduplicar con reglas claras." },
        { t: "Validar", d: "Aplicar reglas de negocio y separar lo que no las cumple." },
        { t: "Medir", d: "Comparar conteos origen vs destino y registrar los rechazos." },
      ],
    },
    {
      type: "code",
      title: "ESTANDARIZAR Y DEDUPLICAR EN SQL",
      code: `INSERT INTO cliente_limpio (documento, nombre, ciudad, correo)
SELECT documento, nombre, ciudad, correo
  FROM (
    SELECT TRIM(documento)                         AS documento,
           INITCAP(TRIM(nombre))                   AS nombre,
           CASE WHEN UPPER(TRANSLATE(ciudad, 'áéíóú', 'aeiou'))
                     LIKE 'BOGOTA%' THEN 'Bogotá'
                ELSE INITCAP(TRIM(ciudad)) END     AS ciudad,
           LOWER(TRIM(correo))                     AS correo,
           ROW_NUMBER() OVER (PARTITION BY TRIM(documento)
                              ORDER BY fecha_mod DESC) AS rn
      FROM stg_cliente
     WHERE documento IS NOT NULL
  )
 WHERE rn = 1;`,
      side: [
        "Funciones de texto para unificar formatos.",
        "`ROW_NUMBER` deja solo la versión **más reciente** de cada documento.",
        "La misma función de ventana que vimos en SQL avanzado.",
      ],
    },
    {
      type: "code",
      title: "NO PERDER LAS FILAS MALAS",
      code: `-- Crea la tabla ERR$_VENTA para guardar los rechazos
EXEC DBMS_ERRLOG.CREATE_ERROR_LOG('VENTA');

INSERT INTO venta (id_venta, fecha, valor)
SELECT id, TO_DATE(fecha_txt, 'YYYY-MM-DD'), valor
  FROM stg_venta
LOG ERRORS INTO err$_venta ('carga_2026_11_25')
REJECT LIMIT UNLIMITED;

SELECT ora_err_number$, ora_err_mesg$, id
  FROM err$_venta;`,
      side: [
        "**DML Error Logging** de Oracle: las filas que fallan no detienen la carga.",
        "Cada rechazo queda con su código y mensaje de error.",
        "Se revisan después en una tabla de **cuarentena**.",
      ],
    },
    {
      type: "code",
      title: "LO MISMO EN MONGODB",
      code: `db.stg_pedidos.aggregate([
  { $match: { total: { $gt: 0 } } },
  { $set: {
      ciudad: { $trim: { input: { $toUpper: "$ciudad" } } },
      fecha:  { $dateFromString: { dateString: "$fecha_txt",
                                   onError: null } }
  } },
  { $match: { fecha: { $ne: null } } },
  { $merge: { into: "pedidos_limpios",
              on: "_id", whenMatched: "replace" } }
]);`,
      side: [
        "Un pipeline también es una transformación ETL.",
        "`onError: null` evita que una fecha mala tumbe todo el proceso.",
        "`$merge` carga el resultado, igual que en la opción B de la sustentación.",
      ],
    },
    {
      type: "bullets",
      title: "MÉTRICAS DE CONTROL",
      cols: 1,
      items: [
        "**Reconciliación**: filas leídas = filas cargadas + filas rechazadas.",
        "**Porcentaje de rechazo** por carga; si sube de golpe, algo cambió en el origen.",
        "**Sumas de control**: el total de ventas debe coincidir entre origen y destino.",
        "**Trazabilidad**: cada fila cargada sabe de qué fuente y de qué ejecución vino.",
      ],
    },
    {
      type: "refs",
      items: [
        "DAMA International (2017). *DAMA-DMBOK: Data Management Body of Knowledge* (2.ª ed.). Technics Publications.",
        "Kimball, R. y Caserta, J. (2004). *The Data Warehouse ETL Toolkit*, cap. 4 “Cleaning and Conforming”. Wiley.",
        "Oracle. *PL/SQL Packages and Types Reference* — DBMS_ERRLOG.",
        "MongoDB. *$merge* y *$dateFromString* (aggregation). Documentación oficial.",
      ],
    },
    { type: "thanks" },
  ],
};
