export default {
  file: "etl-y-elt-fundamentos",
  out: "evidencias/bd2/08-etl",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 51,
  slides: [
    { type: "cover", title: "ETL Y ELT: FUNDAMENTOS", subtitle: "Cómo se mueven los datos desde donde nacen hasta donde se analizan" },
    {
      type: "text",
      title: "¿QUÉ ES ETL?",
      text: "**Extract, Transform, Load**: el proceso que toma datos de los sistemas que operan el negocio, los limpia y los adapta, y los deja en un destino pensado para **analizar**, normalmente una bodega de datos.",
      note: "Las bases transaccionales (OLTP) están hechas para registrar; la bodega (OLAP) para preguntar.",
      icon: "funnel",
    },
    {
      type: "steps",
      title: "LAS TRES FASES",
      steps: [
        { t: "Extraer", d: "Leer de bases relacionales, NoSQL, archivos CSV/JSON o APIs sin afectar al sistema de origen." },
        { t: "Transformar", d: "Limpiar, estandarizar, unir fuentes, calcular campos y aplicar reglas de negocio." },
        { t: "Cargar", d: "Insertar o actualizar el destino: bodega, data mart o lago de datos." },
      ],
      note: "Entre extraer y cargar suele existir un área de staging donde los datos crudos esperan su transformación.",
    },
    {
      type: "compare",
      title: "TIPOS DE EXTRACCIÓN",
      cols: [
        { title: "Completa", items: ["Se copia toda la tabla en cada ejecución.", "Simple y fácil de verificar.", "Costosa cuando la tabla crece.", "Útil para catálogos pequeños."] },
        { title: "Incremental", items: ["Solo lo que cambió desde la última vez.", "Usa una marca de tiempo o un ID creciente.", "O **CDC** (Change Data Capture): lee el log de cambios del motor.", "Necesaria para volúmenes grandes."] },
      ],
    },
    {
      type: "bullets",
      title: "TRANSFORMACIONES COMUNES",
      cols: 2,
      items: [
        "**Limpieza**: nulos, espacios, valores imposibles.",
        "**Estandarización**: mismos formatos de fecha, texto y códigos.",
        "**Deduplicación**: un cliente registrado dos veces es uno solo.",
        "**Integración**: unir datos de varias fuentes con una misma clave.",
        "**Derivación**: calcular edad, totales, categorías.",
        "**Claves sustitutas**: IDs propios de la bodega, independientes del origen.",
        "**Agregación**: resumir por día, mes o región.",
      ],
    },
    {
      type: "code",
      title: "CARGA INCREMENTAL CON MERGE",
      code: `MERGE INTO dw.dim_cliente d
USING (SELECT id_cliente, nombre, ciudad
         FROM stg.cliente
        WHERE fecha_mod > :ultima_carga) s
   ON (d.id_cliente_origen = s.id_cliente)
 WHEN MATCHED THEN UPDATE SET
      d.nombre = s.nombre,
      d.ciudad = s.ciudad
 WHEN NOT MATCHED THEN INSERT
      (id_cliente_origen, nombre, ciudad)
      VALUES (s.id_cliente, s.nombre, s.ciudad);`,
      side: [
        "Solo procesa lo modificado desde la última carga.",
        "Si el cliente ya existe lo actualiza, si no lo inserta (**upsert**).",
        "Es el mismo MERGE que practicamos en SQL avanzado.",
      ],
    },
    {
      type: "compare",
      title: "ETL VS ELT",
      cols: [
        { title: "ETL", items: ["Se transforma **antes** de cargar, en un servidor intermedio.", "El destino recibe datos ya limpios.", "Clásico en bodegas on-premise (Oracle, SQL Server).", "Herramientas: Pentaho, Talend, SSIS, ODI."] },
        { title: "ELT", items: ["Se carga el dato **crudo** y se transforma dentro del destino.", "Aprovecha la potencia de bodegas en la nube.", "Se conserva el dato original para reprocesar.", "Herramientas: dbt sobre Snowflake, BigQuery, Redshift."] },
      ],
    },
    {
      type: "compare",
      title: "BATCH VS STREAMING",
      cols: [
        { title: "Batch (por lotes)", items: ["Corre cada cierto tiempo: cada noche, cada hora.", "Más simple de construir y de reintentar.", "Los reportes muestran datos de la última corrida."] },
        { title: "Streaming", items: ["Procesa cada evento apenas ocurre.", "Kafka, Spark Streaming, Flink.", "Para alertas, fraude o tableros en vivo."] },
      ],
    },
    {
      type: "text",
      title: "APLICADO A MOTOGO",
      text: "Una propuesta de ETL para nuestro proyecto: extraer **contratos y pagos de MySQL** y la **auditoría de MongoDB**, unirlos por usuario y moto, y cargarlos cada noche a una bodega para ver ingresos por propietario, motos más alquiladas y horas pico.",
      note: "Hoy esas preguntas requerirían consultas pesadas sobre la base que atiende a la aplicación.",
      icon: "database",
    },
    {
      type: "bullets",
      title: "HERRAMIENTAS",
      cols: 2,
      items: [
        "**Apache Airflow**: orquesta y programa los flujos.",
        "**Pentaho Data Integration** (Kettle): ETL visual, libre.",
        "**Talend**: ETL visual con generación de código.",
        "**SSIS**: el ETL de Microsoft SQL Server.",
        "**Oracle Data Integrator**: enfoque ELT sobre Oracle.",
        "**dbt**: transformaciones SQL versionadas dentro de la bodega.",
        "**AWS Glue / Azure Data Factory**: servicios administrados en la nube.",
      ],
    },
    {
      type: "refs",
      items: [
        "Kimball, R. y Caserta, J. (2004). *The Data Warehouse ETL Toolkit*. Wiley.",
        "Kimball, R. y Ross, M. (2013). *The Data Warehouse Toolkit* (3.ª ed.). Wiley.",
        "Reis, J. y Housley, M. (2022). *Fundamentals of Data Engineering*. O'Reilly.",
        "Oracle. *Database SQL Language Reference* — sentencia MERGE.",
      ],
    },
    { type: "thanks" },
  ],
};
