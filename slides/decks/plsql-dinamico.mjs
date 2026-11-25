export default {
  file: "sql-dinamico-e-inyeccion-sql",
  out: "evidencias/bd2/07-plsql/investigacion",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 23,
  slides: [
    { type: "cover", title: "SQL DINÁMICO E INYECCIÓN SQL", subtitle: "Cómo construir sentencias en tiempo de ejecución sin abrir una puerta" },
    {
      type: "text",
      title: "¿QUÉ ES EL SQL DINÁMICO?",
      text: "Es SQL que no está escrito fijo en el código, sino que se **arma como texto mientras el programa corre** y luego se le pide a Oracle que lo ejecute.",
      note: "El SQL estático se valida al compilar; el dinámico solo se valida al ejecutarse.",
    },
    {
      type: "bullets",
      title: "¿CUÁNDO SE NECESITA?",
      cols: 1,
      items: [
        "Ejecutar **DDL** desde PL/SQL (CREATE, ALTER, DROP, TRUNCATE).",
        "Cuando el **nombre de la tabla o columna** solo se conoce en ejecución.",
        "Búsquedas con **filtros opcionales** que el usuario activa o no.",
        "Procesos genéricos de administración: recompilar objetos, recolectar estadísticas de varias tablas.",
      ],
      note: "Si el SQL estático alcanza, es mejor: lo revisa el compilador y queda registrado en las dependencias.",
    },
    {
      type: "compare",
      title: "DOS FORMAS EN ORACLE",
      cols: [
        { title: "EXECUTE IMMEDIATE", items: ["SQL dinámico nativo (NDS).", "Corto y fácil de leer.", "`INTO` para una fila, `BULK COLLECT INTO` para varias.", "`OPEN cursor FOR texto USING ...` para recorrer resultados."] },
        { title: "DBMS_SQL", items: ["Paquete con API paso a paso: parse, bind, execute, fetch.", "Sirve cuando no se sabe cuántas columnas o binds habrá.", "Más código, más control.", "`DBMS_SQL.TO_REFCURSOR` convierte entre ambos mundos."] },
      ],
    },
    {
      type: "code",
      title: "EXECUTE IMMEDIATE CON BIND",
      code: `CREATE OR REPLACE FUNCTION fn_contar(
  p_tabla     IN VARCHAR2,
  p_categoria IN VARCHAR2
) RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM ' ||
      DBMS_ASSERT.SIMPLE_SQL_NAME(p_tabla) ||
    ' WHERE categoria = :cat'
    INTO v_total
    USING p_categoria;
  RETURN v_total;
END;`,
      side: [
        "El **valor** va como variable bind `:cat` con USING: nunca se pega al texto.",
        "El **nombre de tabla** no puede ser bind, por eso se valida con DBMS_ASSERT.",
        "Si p_tabla no es un identificador válido, DBMS_ASSERT lanza ORA-44003.",
      ],
    },
    {
      type: "text",
      title: "¿QUÉ ES LA INYECCIÓN SQL?",
      text: "Pasa cuando un dato que escribe el usuario se **concatena** dentro de la sentencia y termina cambiando su significado. El motor no distingue qué parte era código y qué parte era dato.",
      note: "Sigue estando en el OWASP Top 10 dentro de la categoría “Injection”.",
    },
    {
      type: "code",
      title: "EJEMPLO VULNERABLE",
      code: `-- MAL: el dato se pega al texto de la sentencia
v_sql := 'SELECT saldo FROM cuenta ' ||
         'WHERE usuario = ''' || p_usuario || '''';
EXECUTE IMMEDIATE v_sql INTO v_saldo;

-- Si p_usuario llega como:   x' OR '1'='1
-- la sentencia final queda:
SELECT saldo FROM cuenta
 WHERE usuario = 'x' OR '1'='1'   -- siempre verdadero`,
      side: [
        "El atacante cerró la comilla y agregó su propia condición.",
        "La misma idea sirve para UNION, comentarios `--` o subconsultas.",
        "La solución **no** es “escapar comillas a mano”.",
      ],
    },
    {
      type: "bullets",
      title: "CÓMO DEFENDERSE",
      cols: 1,
      items: [
        "**Variables bind** (`USING`) para todo valor: el dato nunca se interpreta como código.",
        "**DBMS_ASSERT** para identificadores: SIMPLE_SQL_NAME, SQL_OBJECT_NAME, ENQUOTE_NAME.",
        "**Lista blanca**: si el usuario elige una columna para ordenar, compararla contra un conjunto fijo.",
        "**Mínimo privilegio**: el esquema que ejecuta solo debe tener los permisos necesarios.",
        "Revisar `AUTHID DEFINER` vs `CURRENT_USER`: con DEFINER el código corre con los permisos del dueño.",
      ],
    },
    {
      type: "compare",
      title: "BINDS TAMBIÉN DAN RENDIMIENTO",
      cols: [
        { title: "Con literales", items: ["Cada valor distinto genera un texto SQL distinto.", "Oracle hace un **hard parse** cada vez.", "El shared pool se llena de cursores casi iguales."] },
        { title: "Con binds", items: ["El texto SQL es siempre el mismo.", "Se reutiliza el plan: **soft parse**.", "Menos CPU y menos contención en el shared pool."] },
      ],
      note: "Se conecta con lo visto en optimización: el plan se comparte entre ejecuciones de la misma sentencia.",
    },
    {
      type: "bullets",
      title: "CONCLUSIONES",
      cols: 1,
      items: [
        "El SQL dinámico es necesario en casos puntuales, no como forma general de programar.",
        "Valores siempre con binds; nombres de objetos siempre validados.",
        "Usar binds protege y además mejora el rendimiento.",
        "Un procedimiento seguro es el que no necesita confiar en quien lo llama.",
      ],
    },
    {
      type: "refs",
      items: [
        "Oracle. *PL/SQL Language Reference 19c* — capítulo “PL/SQL Dynamic SQL” y sección “SQL Injection”.",
        "Oracle. *PL/SQL Packages and Types Reference* — DBMS_ASSERT y DBMS_SQL.",
        "Llewellyn, B. (2017). *How to write SQL injection proof PL/SQL*. Oracle White Paper.",
        "OWASP Foundation. *SQL Injection Prevention Cheat Sheet*.",
      ],
    },
    { type: "thanks" },
  ],
};
