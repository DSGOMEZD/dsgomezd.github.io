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
      title: "Proyecto Final — UB-Deporte",
      description:
        "Sistema de gestión deportiva para la Universidad del Bosque. Cubre el ciclo completo de una BD: modelado conceptual con MERE en Lucidchart, diseño relacional, normalización, álgebra relacional, selección de RDBMS (Oracle) e implementación con scripts DDL e inserts.",
      technologies: ["Oracle DB", "Lucidchart", "DDL / DML", "MERE", "VM Linux"],
      liveLink: "https://youtu.be/d-I0SLjs_gE",
      githubLink: "https://github.com/MarianaDuran2903/BD-Final",
    },
    {
      title: "Taller Grupal — Modelo E-R",
      description:
        "Primer taller entregado del semestre. Ejercicios de modelado Entidad-Relación desarrollados en grupo, aplicando los conceptos de entidades, atributos, relaciones, cardinalidades y restricciones de participación.",
      technologies: ["Modelo E-R", "Entidades", "Cardinalidades", "Participación"],
      liveLink: "/evidencias/01-modelo-entidad-relacion/EJERCICIOS%20TALLER%20GRUPAL.pdf",
      githubLink: "/posts",
    },
    {
      title: "Modelo E-R — Hospital",
      description:
        "Práctica de modelado Entidad-Relación aplicada al dominio hospitalario. Identifica las entidades principales (paciente, médico, consulta, habitación), sus atributos y las relaciones que las conectan.",
      technologies: ["Modelo E-R", "Draw.io", "Diseño Conceptual"],
      liveLink: "/evidencias/01-modelo-entidad-relacion/MODELO%20HOSPITAL.pdf",
      githubLink: "/posts",
    },
    {
      title: "Modelo E-R — Aerolínea",
      description:
        "Práctica de modelado Entidad-Relación en el contexto de una aerolínea. Cubre entidades como vuelo, pasajero, tripulación y aeropuerto, con sus relaciones y restricciones de integridad.",
      technologies: ["Modelo E-R", "Draw.io", "Diseño Conceptual"],
      liveLink: "/evidencias/01-modelo-entidad-relacion/MODELO%20AEROLINEA.pdf",
      githubLink: "/posts",
    },
    {
      title: "Modelo E-R Extendido (MERE)",
      description:
        "Aplicación del Modelo Entidad-Relación Extendido con conceptos avanzados: especialización, generalización y herencia entre entidades. Permite representar jerarquías y categorías dentro del esquema.",
      technologies: ["MERE", "Generalización", "Especialización", "Herencia"],
      liveLink: "/evidencias/01-modelo-entidad-relacion/Taller_MERE_v3.pdf",
      githubLink: "/posts",
    },
    {
      title: "Normalización — Hospital y Universidad",
      description:
        "Talleres de normalización aplicados a esquemas reales de hospital y universidad. Se recorren las formas normales 1FN, 2FN, 3FN y BCNF, eliminando dependencias parciales y transitivas para obtener esquemas libres de anomalías.",
      technologies: ["1FN", "2FN", "3FN", "BCNF", "Dependencias Funcionales"],
      liveLink: "/evidencias/03-normalizacion/PROCESO%20DE%20NORMALIZACI%C3%93N%20EJERCICIO%20HOSPITAL.pdf",
      githubLink: "/posts",
    },
    {
      title: "Álgebra Relacional",
      description:
        "Taller de operaciones formales sobre relaciones: selección (σ), proyección (π), unión (∪), diferencia (−), producto cartesiano (×) y join (⋈). Base matemática formal del lenguaje SQL.",
      technologies: ["Selección σ", "Proyección π", "Join ⋈", "Unión ∪"],
      liveLink: "/evidencias/04-algebra-relacional/Taller_Algebra_Relacional.pdf",
      githubLink: "/posts",
    },
    {
      title: "Scripts SQL — Compilado de Clase",
      description:
        "Recopilación de todos los scripts SQL desarrollados durante las sesiones de clase: creación de tablas (DDL), consultas y manipulación de datos (DML), vistas, índices y control de transacciones (DCL).",
      technologies: ["DDL", "DML", "DCL", "SELECT", "JOIN", "Vistas"],
      liveLink: "/evidencias/05-scripts-sql/SCRIPTS%20SQL.pdf",
      githubLink: "/posts",
    },
    {
      title: "Modelo Relacional — Ejercicios en Software",
      description:
        "Transformación del modelo conceptual a tablas relacionales usando software especializado de modelado. Incluye la definición de claves primarias, foráneas y restricciones de integridad referencial.",
      technologies: ["Modelo Relacional", "Claves Primarias", "Claves Foráneas", "Integridad"],
      liveLink: "/evidencias/02-modelo-relacional/EJERCICIO%20TODOS.zip",
      githubLink: "/posts",
    },
    {
      title: "Modelos Colaborativos — Toda la Clase",
      description:
        "Diagramas de Modelo Entidad-Relación construidos colaborativamente por todo el grupo en Draw.io. Trabajo en equipo donde cada estudiante aportó entidades y relaciones al modelo conjunto.",
      technologies: ["Draw.io", "Colaborativo", "Modelo E-R", "Trabajo en Equipo"],
      liveLink: "https://app.diagrams.net/#G1n0KUsF-P7YeSn3PlNEnPnecMFY2kuSXQ#%7B%22pageId%22%3A%22iXLh9eBu8gFIoPICc3FG%22%7D",
      githubLink: "/posts",
    },
  ],
};
