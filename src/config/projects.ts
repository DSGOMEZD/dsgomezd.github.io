// Projects configuration
export const projectsConfig = {
  images: [
    "/svg/project1.svg",
    "/svg/project2.svg",
    "/svg/project3.svg",
    "/svg/project4.svg",
    "/svg/project5.svg",
    "/svg/project6.svg",
    "/svg/project7.svg",
    "/svg/project8.svg",
    "/svg/project9.svg",
    "/svg/project10.svg",
  ],
  projects: [
    {
      title: "Proyecto Final BD2",
      description:
        "Proyecto integrador del semestre: diseño e implementación de una solución de datos completa combinando bases de datos relacionales y NoSQL. Incluirá modelado, implementación, optimización y análisis comparativo aplicados a un caso real.",
      technologies: ["MongoDB", "SQL", "NoSQL", "PL/SQL"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "MongoDB — CRUD Completo",
      description:
        "Implementación de todas las operaciones CRUD en MongoDB: insertOne/insertMany, find con filtros y proyecciones, update con operadores ($set, $inc, $push, $pull) y delete. Modelado de documentos vs tablas relacionales.",
      technologies: ["MongoDB", "BSON", "Documentos", "CRUD"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Aggregation Framework",
      description:
        "Pipelines de agregación en MongoDB con los stages más importantes: $match, $group, $project, $sort, $lookup (equivalente al JOIN relacional), $unwind para arrays y $addFields. Comparativa directa con SQL.",
      technologies: ["MongoDB", "$group", "$lookup", "$match", "Pipelines"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "PL/SQL — Stored Procedures",
      description:
        "Programación procedural en Oracle: bloques PL/SQL anónimos, stored procedures con parámetros IN/OUT, funciones almacenadas, cursores explícitos e implícitos y manejo de excepciones.",
      technologies: ["PL/SQL", "Oracle", "Stored Procedures", "Cursores"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Triggers y Vistas",
      description:
        "Implementación de triggers BEFORE/AFTER para auditoría y validación de datos, y creación de vistas y vistas materializadas para optimización de consultas recurrentes.",
      technologies: ["SQL", "Triggers", "Vistas", "DDL", "Auditoría"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Indexación y Optimización",
      description:
        "Análisis de planes de ejecución con EXPLAIN/EXPLAIN ANALYZE, creación de índices B-Tree, Hash y compuestos. Comparativa de performance antes y después de indexar con casos reales.",
      technologies: ["EXPLAIN", "Índices", "B-Tree", "Query Planning"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Comparativa SQL vs NoSQL",
      description:
        "Análisis técnico de cuándo usar bases de datos relacionales vs NoSQL: consistencia, disponibilidad, particionamiento (Teorema CAP), escalabilidad horizontal vs vertical y casos de uso.",
      technologies: ["Teorema CAP", "SQL", "NoSQL", "Análisis", "BASE vs ACID"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Repaso SQL Avanzado",
      description:
        "Profundización en SQL: subconsultas correlacionadas, CTEs (WITH), window functions (ROW_NUMBER, RANK, LAG, LEAD, PARTITION BY) y JOINs avanzados con múltiples tablas y auto-joins.",
      technologies: ["SQL", "CTEs", "Window Functions", "Subconsultas"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "MongoDB — Modelado de Documentos",
      description:
        "Principios de diseño de esquemas en MongoDB: documentos embebidos vs referencias, cuándo desnormalizar, y patrones de diseño como subset pattern, computed pattern y bucket pattern.",
      technologies: ["MongoDB", "Schema Design", "Embebidos", "Referencias"],
      liveLink: "#",
      githubLink: "#",
    },
    {
      title: "Introducción a NoSQL",
      description:
        "Panorama general del ecosistema NoSQL: bases de datos documentales (MongoDB), clave-valor (Redis), columnares (Cassandra) y grafos (Neo4j). Casos de uso de cada tipo y criterios de selección.",
      technologies: ["NoSQL", "Redis", "Cassandra", "Neo4j", "MongoDB"],
      liveLink: "#",
      githubLink: "#",
    },
  ],
};
