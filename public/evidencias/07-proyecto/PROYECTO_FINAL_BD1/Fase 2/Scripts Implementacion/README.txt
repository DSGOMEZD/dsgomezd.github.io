UB-DEPORTE — Base de Datos del Sistema de Gestion del Gimnasio
Universidad El Bosque | CodeNova

Este repositorio contiene los scripts SQL para crear y poblar la base de datos del sistema de gestion del gimnasio UB-DEPORTE. El sistema administra personas con distintos roles (miembros, entrenadores, operadores y administradores), clases deportivas, membresias, planes de entrenamiento personalizados, equipamiento y mantenimiento de maquinas.

Los archivos son dos: ub_deporte_ddl.sql contiene la creacion de la base de datos y todas sus tablas, y ub_deporte_inserts.sql contiene todos los datos de prueba listos para insertar.


REQUISITOS

Se necesita MySQL 8.0 o superior y un cliente MySQL como MySQL Workbench, DBeaver o la terminal. El usuario debe tener permisos de CREATE, DROP, INSERT y SELECT.


INSTRUCCIONES DE USO

Primero se debe ejecutar el script DDL. Este script elimina la base de datos si ya existe y la crea desde cero con todas sus tablas. Una vez creadas las tablas, se ejecuta el script de inserciones con los datos de prueba. Es importante ejecutar siempre el DDL antes que los inserts, ya que los inserts dependen de que las tablas existan previamente.


ESTRUCTURA DEL SISTEMA

El sistema parte de una tabla PERSONA que funciona como entidad base con los datos personales y las credenciales de acceso de todos los usuarios. A partir de ella se especializan tres roles: MIEMBRO, que agrega datos fisicos como altura, peso y nivel de experiencia; ENTRENADOR, que incluye el tipo de entrenamiento, los meses de experiencia y el nivel de exigencia; y OPERADOR, que define el nivel tecnico, la especialidad y el tipo de operacion que realiza.

Para las clases, el sistema maneja un catalogo de deportes y una tabla de salas fisicas con su capacidad. Los horarios se definen como plantillas semanales por dia de la semana, sin fechas especificas, y la fecha concreta se asigna en cada clase al momento de crearla. Cada clase tiene un estado que puede ser programada, finalizada o cancelada, y registra cupos, sala, horario, deporte y entrenador asignado. La asistencia de los miembros a las clases se registra en una tabla intermedia llamada Asistir.

El sistema de membresias permite que un miembro tenga varios planes a lo largo del tiempo, ya que la clave primaria de MEMBRESIA incluye la fecha de inicio, lo que permite guardar el historial de renovaciones. Cada membresia tiene asociado al menos un pago con su metodo y valor.

El entrenamiento personalizado funciona a traves de una tabla de Asignacion que relaciona entrenadores con miembros de forma N a M, con la restriccion de que un par entrenador-miembro no se puede duplicar. Cada asignacion puede tener exactamente un plan de entrenamiento, y cada plan tiene sus ejercicios con repeticiones y series definidas. Adicionalmente, los miembros pueden tener restricciones medicas registradas que los entrenadores deben tener en cuenta.

Para el equipamiento, el sistema lleva un inventario de materiales con su cantidad disponible y registra cuales se usan en cada clase. Las maquinas se gestionan por separado con su modelo, marca, tipo y estado operativo, y los operadores registran los mantenimientos realizados con fecha, tipo y descripcion. Por ultimo, el sistema cuenta con una tabla de contenido digital donde se almacenan videos, articulos, guias, tutoriales, podcasts e infografias asociados a cada deporte.


DATOS DE PRUEBA INCLUIDOS

Los datos incluyen 25 personas en total: un administrador, cuatro entrenadores, dos operadores y dieciocho miembros. De los dieciocho miembros, diez tienen membresia activa con su entrenador asignado y su plan de entrenamiento, y los otros cinco estan registrados en el sistema pero aun no tienen membresia ni entrenador, lo que representa el caso de usuarios que se registran pero todavia no han adquirido un plan. Hay ademas dos membresias vencidas para representar historico.

El sistema tiene seis deportes, cinco salas, setenta y un horarios distribuidos de lunes a domingo, y veintidos clases entre programadas, finalizadas y canceladas. Los planes de entrenamiento suman diecisiete con cuarenta y nueve ejercicios en total, siete restricciones medicas, diez tipos de equipamiento, diez maquinas y siete registros de mantenimiento. El contenido digital cuenta con doce recursos de distintos tipos.


CONTRASENAS

Las contrasenas en los datos de prueba son texto plano para facilitar las pruebas. El administrador usa admin2024, los entrenadores usan entrenador123, los operadores usan operador123 y los miembros usan miembro123. En un entorno de produccion estas deben reemplazarse por hashes bcrypt o el algoritmo que use el sistema de autenticacion implementado.


CODIFICACION

La base de datos usa utf8mb4 con colacion utf8mb4_spanish_ci para soporte completo de caracteres especiales del espanol.
