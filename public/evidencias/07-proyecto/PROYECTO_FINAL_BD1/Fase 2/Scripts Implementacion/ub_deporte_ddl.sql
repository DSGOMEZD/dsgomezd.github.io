DROP DATABASE IF EXISTS ub_deporte;
CREATE DATABASE ub_deporte
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

USE ub_deporte;

CREATE TABLE PERSONA (
    cedula           CHAR(15)     NOT NULL,
    telefono         VARCHAR(20)  NOT NULL,
    correo           VARCHAR(50)  NOT NULL,
    password         VARCHAR(255) NOT NULL,
    primer_nombre    VARCHAR(15)  NOT NULL,
    segundo_nombre   VARCHAR(15)  NULL,
    primer_apellido  VARCHAR(15)  NOT NULL,
    segundo_apellido VARCHAR(15)  NOT NULL,
    fecha_nacimiento DATE         NOT NULL,
    rol              ENUM('miembro','entrenador','operador','administrador') NOT NULL,
    CONSTRAINT PERSONA_PK           PRIMARY KEY (cedula),
    CONSTRAINT PERSONA_CORREO_UNIQUE UNIQUE (correo)
) COMMENT = 'Tabla base con credenciales de acceso y datos personales';

CREATE TABLE MIEMBRO (
    cedula            CHAR(15)     NOT NULL,
    altura            SMALLINT     NOT NULL COMMENT 'Altura en centímetros',
    peso_actual       DECIMAL(5,2) NOT NULL COMMENT 'Peso en kg',
    nivel_experiencia ENUM('novato','avanzado','profesional') NOT NULL,
    CONSTRAINT MIEMBRO_PK         PRIMARY KEY (cedula),
    CONSTRAINT MIEMBRO_PERSONA_FK FOREIGN KEY (cedula) REFERENCES PERSONA (cedula)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Atributos específicos para usuarios del gimnasio';

CREATE TABLE ENTRENADOR (
    cedula             CHAR(15) NOT NULL,
    tipo_entrenamiento ENUM('fuerza','aerobico','flexibilidad','equilibrio') NOT NULL,
    tiempo_experiencia SMALLINT NOT NULL COMMENT 'Experiencia en meses',
    nivel_exigencia    ENUM('bajo','moderado','medio','alto','extremo') NOT NULL,
    fecha_ingreso_sis  DATE     NOT NULL,
    CONSTRAINT ENTRENADOR_PK         PRIMARY KEY (cedula),
    CONSTRAINT ENTRENADOR_PERSONA_FK FOREIGN KEY (cedula) REFERENCES PERSONA (cedula)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Personal entrenador del gimnasio';

CREATE TABLE OPERADOR (
    cedula        CHAR(15) NOT NULL,
    nivel_tecnico ENUM('basico','intermedio','avanzado','experto') NOT NULL,
    especialidad  ENUM('mecanico','electrico','inspeccion','gestion_instalaciones') NOT NULL,
    tipo_operador ENUM('preventivo','correctivo','locativo') NOT NULL,
    CONSTRAINT OPERADOR_PK         PRIMARY KEY (cedula),
    CONSTRAINT OPERADOR_PERSONA_FK FOREIGN KEY (cedula) REFERENCES PERSONA (cedula)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Personal de mantenimiento';

CREATE TABLE DEPORTE (
    id_deporte  INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(20)  NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT DEPORTE_PK PRIMARY KEY (id_deporte)
);

CREATE TABLE Especializar (
    ENTRENADOR_cedula  CHAR(15) NOT NULL,
    DEPORTE_id_deporte INT      NOT NULL,
    CONSTRAINT Especializar_PK            PRIMARY KEY (ENTRENADOR_cedula, DEPORTE_id_deporte),
    CONSTRAINT Especializar_ENTRENADOR_FK FOREIGN KEY (ENTRENADOR_cedula)
        REFERENCES ENTRENADOR (cedula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Especializar_DEPORTE_FK    FOREIGN KEY (DEPORTE_id_deporte)
        REFERENCES DEPORTE (id_deporte) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Sala (
    id_sala   INT      NOT NULL AUTO_INCREMENT,
    capacidad SMALLINT NOT NULL,
    CONSTRAINT Sala_PK PRIMARY KEY (id_sala)
);

CREATE TABLE Horario (
    id_horario  INT  NOT NULL AUTO_INCREMENT,
    dia_semana  ENUM('lunes','martes','miercoles','jueves','viernes','sabado','domingo') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin    TIME NOT NULL,
    CONSTRAINT Horario_PK PRIMARY KEY (id_horario)
);

CREATE TABLE CLASE (
    id_clase           INT      NOT NULL AUTO_INCREMENT,
    estado             ENUM('programada','cancelada','finalizada') NOT NULL,
    comentario         TEXT     NOT NULL,
    cupos              SMALLINT NOT NULL,
    fecha              DATE     NOT NULL,
    Sala_id_sala       INT      NOT NULL,
    Horario_id_horario INT      NOT NULL,
    DEPORTE_id_deporte INT      NOT NULL,
    ENTRENADOR_cedula  CHAR(15) NOT NULL,
    CONSTRAINT CLASE_PK            PRIMARY KEY (id_clase, Sala_id_sala, Horario_id_horario),
    CONSTRAINT CLASE_Sala_FK       FOREIGN KEY (Sala_id_sala)
        REFERENCES Sala (id_sala) ON UPDATE CASCADE,
    CONSTRAINT CLASE_Horario_FK    FOREIGN KEY (Horario_id_horario)
        REFERENCES Horario (id_horario) ON UPDATE CASCADE,
    CONSTRAINT CLASE_DEPORTE_FK    FOREIGN KEY (DEPORTE_id_deporte)
        REFERENCES DEPORTE (id_deporte) ON UPDATE CASCADE,
    CONSTRAINT CLASE_ENTRENADOR_FK FOREIGN KEY (ENTRENADOR_cedula)
        REFERENCES ENTRENADOR (cedula) ON UPDATE CASCADE
);

CREATE TABLE Asistir (
    MIEMBRO_cedula   CHAR(15) NOT NULL,
    CLASE_id_clase   INT      NOT NULL,
    CLASE_id_sala    INT      NOT NULL,
    CLASE_id_horario INT      NOT NULL,
    CONSTRAINT Asistir_PK         PRIMARY KEY (MIEMBRO_cedula, CLASE_id_clase, CLASE_id_sala, CLASE_id_horario),
    CONSTRAINT Asistir_MIEMBRO_FK FOREIGN KEY (MIEMBRO_cedula)
        REFERENCES MIEMBRO (cedula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Asistir_CLASE_FK   FOREIGN KEY (CLASE_id_clase, CLASE_id_sala, CLASE_id_horario)
        REFERENCES CLASE (id_clase, Sala_id_sala, Horario_id_horario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE CONTENIDO (
    id_contenido       INT          NOT NULL AUTO_INCREMENT,
    titulo             VARCHAR(50)  NOT NULL,
    descripcion        VARCHAR(200) NOT NULL,
    tipo_contenido     ENUM('video','articulo','guia','tutorial','podcast','infografia') NOT NULL,
    duracion           INT          NULL,
    url_del_recurso    VARCHAR(500) NULL,
    fecha_publicacion  DATE         NOT NULL,
    autor              VARCHAR(100) NOT NULL,
    DEPORTE_id_deporte INT          NOT NULL,
    CONSTRAINT CONTENIDO_PK         PRIMARY KEY (id_contenido, DEPORTE_id_deporte),
    CONSTRAINT CONTENIDO_DEPORTE_FK FOREIGN KEY (DEPORTE_id_deporte)
        REFERENCES DEPORTE (id_deporte) ON UPDATE CASCADE
);

CREATE TABLE PLAN (
    id_plan  INT           NOT NULL AUTO_INCREMENT,
    duracion ENUM('mensual','trimestral','semestral','anual') NOT NULL,
    precio   DECIMAL(10,2) NOT NULL,
    CONSTRAINT PLAN_PK PRIMARY KEY (id_plan)
);

CREATE TABLE MEMBRESIA (
    MIEMBRO_cedula CHAR(15) NOT NULL,
    PLAN_id_plan   INT      NOT NULL,
    fecha_inicio   DATE     NOT NULL,
    fecha_fin      DATE     NOT NULL,
    estado         ENUM('activa','inactiva','vencida','suspendida') NOT NULL,
    CONSTRAINT MEMBRESIA_PK         PRIMARY KEY (MIEMBRO_cedula, PLAN_id_plan, fecha_inicio),
    CONSTRAINT MEMBRESIA_MIEMBRO_FK FOREIGN KEY (MIEMBRO_cedula)
        REFERENCES MIEMBRO (cedula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT MEMBRESIA_PLAN_FK    FOREIGN KEY (PLAN_id_plan)
        REFERENCES PLAN (id_plan) ON UPDATE CASCADE
);

CREATE TABLE PAGO (
    id_pago                INT           NOT NULL AUTO_INCREMENT,
    metodo_pago            ENUM('efectivo','tarjeta_credito','tarjeta_debito','transferencia') NOT NULL,
    fecha_pago             DATE          NOT NULL,
    valor_pagado           DECIMAL(10,2) NOT NULL,
    MEMBRESIA_cedula       CHAR(15)      NOT NULL,
    MEMBRESIA_PLAN_id_plan INT           NOT NULL,
    MEMBRESIA_fecha_inicio DATE          NOT NULL,
    CONSTRAINT PAGO_PK           PRIMARY KEY (id_pago, MEMBRESIA_cedula, MEMBRESIA_PLAN_id_plan, MEMBRESIA_fecha_inicio),
    CONSTRAINT PAGO_MEMBRESIA_FK FOREIGN KEY (MEMBRESIA_cedula, MEMBRESIA_PLAN_id_plan, MEMBRESIA_fecha_inicio)
        REFERENCES MEMBRESIA (MIEMBRO_cedula, PLAN_id_plan, fecha_inicio) ON UPDATE CASCADE
);

CREATE TABLE Asignacion (
    id_asignacion     INT      NOT NULL AUTO_INCREMENT,
    ENTRENADOR_cedula CHAR(15) NOT NULL,
    MIEMBRO_cedula    CHAR(15) NOT NULL,
    fecha_asignacion  DATE     NOT NULL,
    CONSTRAINT Asignacion_PK            PRIMARY KEY (id_asignacion),
    CONSTRAINT Asignacion_UNIQUE        UNIQUE (ENTRENADOR_cedula, MIEMBRO_cedula),
    CONSTRAINT Asignacion_ENTRENADOR_FK FOREIGN KEY (ENTRENADOR_cedula)
        REFERENCES ENTRENADOR (cedula) ON UPDATE CASCADE,
    CONSTRAINT Asignacion_MIEMBRO_FK    FOREIGN KEY (MIEMBRO_cedula)
        REFERENCES MIEMBRO (cedula) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PLAN_ENTRENAMIENTO (
    id_asignacion INT          NOT NULL,
    descripcion   VARCHAR(100) NOT NULL,
    CONSTRAINT PLAN_ENTRENAMIENTO_PK            PRIMARY KEY (id_asignacion),
    CONSTRAINT PLAN_ENTRENAMIENTO_ASIGNACION_FK FOREIGN KEY (id_asignacion)
        REFERENCES Asignacion (id_asignacion) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE EJERCICIO (
    id_ejercicio                     INT          NOT NULL AUTO_INCREMENT,
    nombre_ejerc                     VARCHAR(50)  NOT NULL,
    descripcion_ejerc                VARCHAR(100) NOT NULL,
    reps_serie                       SMALLINT     NOT NULL,
    num_series                       SMALLINT     NOT NULL,
    PLAN_ENTRENAMIENTO_id_asignacion INT          NOT NULL,
    CONSTRAINT EJERCICIO_PK          PRIMARY KEY (id_ejercicio),
    CONSTRAINT EJERCICIO_PLAN_ENT_FK FOREIGN KEY (PLAN_ENTRENAMIENTO_id_asignacion)
        REFERENCES PLAN_ENTRENAMIENTO (id_asignacion) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Restriccion_medica (
    id_restriccion  INT          NOT NULL AUTO_INCREMENT,
    tipo            ENUM('lesion','enfermedad','limitacion_fisica','alergia','otra') NOT NULL,
    descripcion     VARCHAR(200) NOT NULL,
    nivel_gravedad  ENUM('leve','moderado','alto','critico') NOT NULL,
    recomendaciones VARCHAR(200) NOT NULL,
    MIEMBRO_cedula  CHAR(15)     NOT NULL,
    CONSTRAINT Restriccion_medica_PK         PRIMARY KEY (id_restriccion, MIEMBRO_cedula),
    CONSTRAINT Restriccion_medica_MIEMBRO_FK FOREIGN KEY (MIEMBRO_cedula)
        REFERENCES MIEMBRO (cedula) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Equipamiento (
    id_equipamiento INT          NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(30)  NOT NULL,
    descripcion     VARCHAR(200) NOT NULL,
    cantidad        INT          NOT NULL,
    CONSTRAINT Equipamiento_PK PRIMARY KEY (id_equipamiento)
);

CREATE TABLE Usarv3 (
    Equipamiento_id_equipamiento INT      NOT NULL,
    CLASE_id_clase               INT      NOT NULL,
    CLASE_Sala_id_sala           INT      NOT NULL,
    CLASE_Horario_id_horario     INT      NOT NULL,
    cantidad_equipo              SMALLINT NOT NULL,
    CONSTRAINT Usarv3_PK               PRIMARY KEY (Equipamiento_id_equipamiento, CLASE_id_clase, CLASE_Sala_id_sala, CLASE_Horario_id_horario),
    CONSTRAINT Usarv3_Equipamiento_FK  FOREIGN KEY (Equipamiento_id_equipamiento)
        REFERENCES Equipamiento (id_equipamiento) ON UPDATE CASCADE,
    CONSTRAINT Usarv3_CLASE_FK         FOREIGN KEY (CLASE_id_clase, CLASE_Sala_id_sala, CLASE_Horario_id_horario)
        REFERENCES CLASE (id_clase, Sala_id_sala, Horario_id_horario) ON UPDATE CASCADE
);

CREATE TABLE MAQUINAS (
    codigo_serie   INT          NOT NULL AUTO_INCREMENT,
    nombre_maquina VARCHAR(30)  NOT NULL,
    modelo         VARCHAR(30)  NOT NULL,
    marca          VARCHAR(30)  NOT NULL,
    tipo_maquina   ENUM('cardio','fuerza','funcional','rehabilitacion','pesas','otra') NOT NULL,
    estado         ENUM('operativa','en_mantenimiento','fuera_de_servicio','en_reparacion') NOT NULL,
    capacidad      DECIMAL(4,2) NOT NULL,
    CONSTRAINT MAQUINAS_PK PRIMARY KEY (codigo_serie)
);

CREATE TABLE Mantenimiento (
    OPERADOR_cedula       CHAR(15) NOT NULL,
    MAQUINAS_codigo_serie INT      NOT NULL,
    tipo_mant             ENUM('preventivo','correctivo','locativo') NOT NULL,
    fecha_mantenimiento   DATE     NOT NULL,
    descripcion_mant      TEXT     NOT NULL,
    CONSTRAINT Mantenimiento_PK          PRIMARY KEY (OPERADOR_cedula, MAQUINAS_codigo_serie),
    CONSTRAINT Mantenimiento_OPERADOR_FK FOREIGN KEY (OPERADOR_cedula)
        REFERENCES OPERADOR (cedula) ON UPDATE CASCADE,
    CONSTRAINT Mantenimiento_MAQUINAS_FK FOREIGN KEY (MAQUINAS_codigo_serie)
        REFERENCES MAQUINAS (codigo_serie) ON UPDATE CASCADE
);
