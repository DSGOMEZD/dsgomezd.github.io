export default {
  file: "bodega-de-datos-modelo-estrella-y-scd",
  out: "evidencias/bd2/08-etl",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 71,
  slides: [
    { type: "cover", title: "BODEGA DE DATOS: MODELO ESTRELLA Y SCD", subtitle: "El destino del ETL y cómo guardar la historia" },
    {
      type: "compare",
      title: "OLTP VS OLAP",
      cols: [
        { title: "OLTP (operación)", items: ["Registra el día a día: ventas, pagos, alquileres.", "Muchas escrituras pequeñas y rápidas.", "Modelo normalizado (3FN).", "Datos actuales."] },
        { title: "OLAP (análisis)", items: ["Responde preguntas sobre el negocio.", "Pocas lecturas, pero sobre millones de filas.", "Modelo dimensional, desnormalizado a propósito.", "Datos históricos."] },
      ],
    },
    {
      type: "compare",
      title: "HECHOS Y DIMENSIONES",
      cols: [
        { title: "Tabla de hechos", items: ["Guarda **medidas** numéricas: monto, cantidad, días.", "Una fila por evento del negocio.", "Es la tabla más grande.", "Se conecta a las dimensiones con llaves foráneas."] },
        { title: "Dimensiones", items: ["Dan el **contexto**: quién, qué, cuándo, dónde.", "Muchas columnas descriptivas.", "Relativamente pequeñas.", "Por ellas se filtra y se agrupa."] },
      ],
    },
    {
      type: "steps",
      title: "DISEÑO EN 4 PASOS (KIMBALL)",
      steps: [
        { t: "Proceso", d: "Elegir el proceso de negocio: por ejemplo, el alquiler." },
        { t: "Grano", d: "Definir qué representa una fila: un contrato de alquiler." },
        { t: "Dimensiones", d: "Fecha, moto, propietario, repartidor." },
        { t: "Hechos", d: "Valor pagado, días de alquiler, kilómetros." },
      ],
      note: "El grano se decide primero: todo lo demás depende de él.",
    },
    {
      type: "compare",
      title: "ESTRELLA VS COPO DE NIEVE",
      cols: [
        { title: "Estrella", items: ["Cada dimensión es **una sola tabla**.", "Menos joins, consultas más simples.", "Algo de redundancia (ciudad repetida en cada cliente).", "La más usada en la práctica."] },
        { title: "Copo de nieve", items: ["Las dimensiones se **normalizan** en varias tablas.", "Menos redundancia.", "Más joins y consultas más largas.", "Útil cuando una dimensión es enorme."] },
      ],
    },
    {
      type: "code",
      title: "ESTRELLA PARA MOTOGO",
      code: `CREATE TABLE fact_alquiler (
  sk_fecha       NUMBER REFERENCES dim_fecha,
  sk_moto        NUMBER REFERENCES dim_moto,
  sk_propietario NUMBER REFERENCES dim_propietario,
  sk_repartidor  NUMBER REFERENCES dim_repartidor,
  dias           NUMBER,
  valor_pagado   NUMBER(12,2)
);

-- Ingresos por ciudad y mes, con subtotales
SELECT f.anio, f.mes, p.ciudad, SUM(a.valor_pagado) AS ingresos
  FROM fact_alquiler a
  JOIN dim_fecha f        ON f.sk_fecha = a.sk_fecha
  JOIN dim_propietario p  ON p.sk_propietario = a.sk_propietario
 GROUP BY ROLLUP (f.anio, f.mes, p.ciudad);`,
      side: [
        "Propuesta de análisis sobre los datos del proyecto.",
        "Las `sk_` son **claves sustitutas** propias de la bodega.",
        "`ROLLUP` agrega subtotales por mes y año en una sola consulta.",
      ],
    },
    {
      type: "text",
      title: "¿Y SI UN DATO CAMBIA?",
      text: "Un propietario se muda de Bogotá a Medellín. ¿Los alquileres del año pasado deben contarse en Bogotá o en Medellín? Las **Slowly Changing Dimensions (SCD)** son las formas de decidirlo.",
      icon: "gear",
    },
    {
      type: "table",
      title: "TIPOS DE SCD",
      head: ["Tipo", "Qué hace", "Historia"],
      rows: [
        ["0", "El valor nunca cambia (fecha de nacimiento).", "No aplica"],
        ["1", "Se sobrescribe el valor viejo.", "Se pierde"],
        ["2", "Se cierra la fila vieja y se inserta una nueva versión.", "Completa"],
        ["3", "Se guarda el valor anterior en otra columna.", "Solo un cambio"],
        ["4 / 6", "Tabla de historia aparte / combinación de 1 + 2 + 3.", "Completa"],
      ],
      note: "El tipo 2 es el más usado cuando la historia importa para el análisis.",
    },
    {
      type: "code",
      title: "SCD TIPO 2 EN SQL",
      code: `-- 1. Cerrar la versión vigente si la ciudad cambió
UPDATE dim_propietario d
   SET d.fecha_fin = SYSDATE, d.vigente = 'N'
 WHERE d.vigente = 'S'
   AND EXISTS (SELECT 1 FROM stg_propietario s
                WHERE s.id_origen = d.id_origen
                  AND s.ciudad   <> d.ciudad);

-- 2. Insertar la nueva versión (y los propietarios nuevos)
INSERT INTO dim_propietario
       (sk_propietario, id_origen, nombre, ciudad,
        fecha_inicio, fecha_fin, vigente)
SELECT seq_dim_prop.NEXTVAL, s.id_origen, s.nombre, s.ciudad,
       SYSDATE, NULL, 'S'
  FROM stg_propietario s
 WHERE NOT EXISTS (SELECT 1 FROM dim_propietario d
                    WHERE d.id_origen = s.id_origen
                      AND d.vigente = 'S');`,
      side: [
        "Cada versión tiene su propia **clave sustituta**.",
        "Los hechos viejos siguen apuntando a la versión de Bogotá.",
        "Los nuevos alquileres apuntan a la versión de Medellín.",
      ],
    },
    {
      type: "bullets",
      title: "CONCLUSIONES",
      cols: 1,
      items: [
        "La bodega es el **destino** del ETL y se diseña para preguntar, no para registrar.",
        "Hechos = medidas; dimensiones = contexto. El grano se define primero.",
        "La estrella sacrifica normalización a cambio de consultas simples y rápidas.",
        "Las SCD deciden si la historia se conserva o se sobrescribe.",
      ],
    },
    {
      type: "refs",
      items: [
        "Kimball, R. y Ross, M. (2013). *The Data Warehouse Toolkit* (3.ª ed.). Wiley.",
        "Inmon, W. H. (2005). *Building the Data Warehouse* (4.ª ed.). Wiley.",
        "Oracle. *Database Data Warehousing Guide 19c*.",
        "Kimball Group. *Dimensional Modeling Techniques* — Slowly Changing Dimensions.",
      ],
    },
    { type: "thanks" },
  ],
};
