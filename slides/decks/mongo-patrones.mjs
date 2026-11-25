export default {
  file: "patrones-y-antipatrones-de-esquema",
  out: "evidencias/bd2/06-nosql-mongodb/investigacion",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 31,
  slides: [
    { type: "cover", title: "PATRONES Y ANTIPATRONES DE ESQUEMA EN MONGODB", subtitle: "Más allá de los patrones que usamos en el taller" },
    {
      type: "text",
      title: "LA REGLA DE ORO",
      text: "En MongoDB el esquema se diseña a partir de **cómo se van a consultar los datos**, no solo de qué datos existen. Lo que se lee junto, se guarda junto.",
      icon: "database",
    },
    {
      type: "table",
      title: "LO QUE YA APLICAMOS",
      head: ["Patrón", "Dónde lo usamos en el taller"],
      rows: [
        ["Extended Reference", "Nombre y precio del plato copiados en cada pedido."],
        ["Subset", "Solo las 10 reseñas más recientes dentro del restaurante."],
        ["Computed", "Promedio y total de reseñas guardados y actualizados con $inc."],
        ["Attribute", "Atributos variables de los platos como pares clave–valor."],
        ["Bucket", "Lecturas de sensores agrupadas por hora (calidad del aire)."],
        ["Schema Versioning", "Campo schema_version para sensores con y sin CO₂."],
      ],
      note: "Esta investigación cubre los patrones que no alcanzamos a usar y los errores más comunes.",
    },
    {
      type: "compare",
      title: "POLYMORPHIC Y OUTLIER",
      cols: [
        { title: "Polymorphic", items: ["Documentos con **formas distintas** en una misma colección.", "Un campo `tipo` indica cómo leer cada uno.", "Ej.: vehículos → motos y carros con campos propios.", "Permite consultar todo junto sin $lookup."] },
        { title: "Outlier", items: ["Pocos documentos **mucho más grandes** que el resto.", "Se marcan con `tieneExtras: true` y el exceso va a otra colección.", "Ej.: un libro con millones de compradores.", "El caso normal sigue siendo simple y rápido."] },
      ],
    },
    {
      type: "bullets",
      title: "TREE (JERARQUÍAS)",
      cols: 1,
      items: [
        "**Parent references**: cada nodo guarda a su padre. Fácil de mover nodos.",
        "**Child references**: cada nodo guarda la lista de hijos.",
        "**Array of ancestors**: guarda toda la ruta hacia la raíz; encuentra descendientes con un solo find.",
        "**Materialized path**: la ruta como texto (`,Tecnología,Bases de datos,`) y se busca con regex.",
        "`$graphLookup` recorre la jerarquía de forma recursiva dentro de un pipeline.",
      ],
    },
    {
      type: "code",
      title: "EJEMPLO CON $GRAPHLOOKUP",
      code: `// categorias: { _id, nombre, padre }
db.categorias.aggregate([
  { $match: { nombre: "Bases de datos" } },
  { $graphLookup: {
      from: "categorias",
      startWith: "$padre",
      connectFromField: "padre",
      connectToField: "_id",
      as: "ancestros",
      depthField: "nivel"
  } },
  { $project: { nombre: 1, "ancestros.nombre": 1,
                "ancestros.nivel": 1 } }
]);`,
      side: [
        "Sube desde la categoría hasta la raíz siguiendo el campo `padre`.",
        "`depthField` indica a qué distancia está cada ancestro.",
        "Es el equivalente a CONNECT BY de Oracle que vimos en SQL avanzado.",
      ],
    },
    {
      type: "compare",
      title: "APPROXIMATION Y ARCHIVE",
      cols: [
        { title: "Approximation", items: ["Cuando un número **no necesita ser exacto** (visitas, likes).", "En vez de escribir en cada evento, se escribe cada N eventos.", "Menos escrituras a cambio de un margen de error aceptado."] },
        { title: "Archive", items: ["Mover datos **viejos y poco consultados** a otra colección o almacenamiento.", "La colección activa queda pequeña y sus índices caben en memoria.", "En Atlas existe Online Archive para hacerlo automático."] },
      ],
    },
    {
      type: "bullets",
      title: "ANTIPATRONES",
      cols: 2,
      items: [
        "**Arrays sin límite**: crecen hasta acercarse al tope de 16 MB por documento.",
        "**Demasiadas colecciones**: cada una con sus índices consume recursos aunque esté vacía.",
        "**Índices innecesarios**: ocupan memoria y hacen más lentas las escrituras.",
        "**Documentos inflados**: guardar todo junto aunque casi nunca se lea.",
        "**Normalizar como en SQL**: cada pantalla termina dependiendo de varios $lookup.",
        "**Búsquedas sin distinguir mayúsculas** sin un índice con collation.",
      ],
    },
    {
      type: "table",
      title: "¿CUÁL USAR?",
      head: ["Situación", "Patrón"],
      rows: [
        ["Entidades parecidas con campos distintos", "Polymorphic"],
        ["Unos pocos documentos gigantes", "Outlier"],
        ["Categorías, organigramas, comentarios anidados", "Tree"],
        ["Contadores de alto tráfico", "Approximation"],
        ["Histórico que casi no se consulta", "Archive"],
      ],
    },
    {
      type: "bullets",
      title: "CONCLUSIONES",
      cols: 1,
      items: [
        "Los patrones son respuestas a **formas de consultar**, no recetas fijas.",
        "Casi todos aceptan algo de duplicación a cambio de lecturas más simples.",
        "Los antipatrones aparecen cuando se diseña como si fuera relacional o sin pensar en el crecimiento.",
        "Un buen esquema en MongoDB se revisa cuando cambian las consultas de la aplicación.",
      ],
    },
    {
      type: "refs",
      items: [
        "Coupal, D. y Alger, K. W. (2019). *Building with Patterns: A Summary*. MongoDB Blog.",
        "MongoDB. *Data Modeling — Schema Design Patterns*. Documentación oficial.",
        "Schaefer, L. (2020). *MongoDB Schema Design Anti-Patterns* (serie). MongoDB Developer Center.",
        "MongoDB. *$graphLookup (aggregation)*. Documentación oficial.",
      ],
    },
    { type: "thanks" },
  ],
};
