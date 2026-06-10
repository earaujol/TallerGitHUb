-- ========================================================================
-- TABLA: CONCERR (Incidentes por Corrida)
-- ========================================================================
-- METADATA FUNCIONAL
-- Nombre:        Incidentes de Conciliación
-- Descripción:   Registra todos los incidentes, advertencias y errores
--                ocurridos durante cada ejecución del proceso de conciliación.
-- Objetivo:      Crear un registro detallado de problemas detectados para
--                auditoría, debugging y análisis de calidad de datos.
-- Tipo:          Tabla de detalles/incidentes.
-- Origen:        Módulos de negocio y servicios (SRV_AUDIT, módulos GLBLN_*).
-- Permanencia:   Permanente (histórica completa).
-- Uso:           Análisis de problemas, trazabilidad de errores, reportes
--                de incidentes por severidad.
-- Restricciones: ID_EJECUCION debe existir en CONCEXC (referencia lógica).
--                SEVERIDAD debe ser: BAJA, MEDIA, ALTA, CRITICA.
--
-- METADATA DE PROYECTO
-- Equipo:        Taller GitHub Copilot
-- Fecha:         2026-06-09
-- Proyecto:      Conciliación de Cuentas Mayores (GLBLN)
-- Versión:       1.0
-- ========================================================================

CREATE OR REPLACE TABLE EARAUJOL1.CONCERR
  FOR SYSTEM NAME CONCERR
  (
    -- Campos de Clave Primaria
    ID_EJECUCION          VARCHAR(30) NOT NULL
      FOR COLUMN IDEXEC,
    SECUENCIA_INCIDENTE   INTEGER NOT NULL
      FOR COLUMN SECIN,
    
    -- Identificación del Incidente
    CODIGO_INCIDENTE      VARCHAR(20) NOT NULL
      FOR COLUMN CODIN,
    TIPO_INCIDENTE        CHAR(20) NOT NULL
      FOR COLUMN TIPIN,
    
    -- Contexto del Incidente
    CUENTA_CONTABLE       CHAR(10)
      FOR COLUMN CUENTA,
    
    -- Descripción del Incidente
    MENSAJE               VARCHAR(512) NOT NULL
      FOR COLUMN MSG,
    
    -- Severidad
    SEVERIDAD             CHAR(10) NOT NULL
      FOR COLUMN SEV,
    
    -- Timestamp del Incidente
    FECHA_HORA_INCIDENTE  TIMESTAMP NOT NULL
      FOR COLUMN FECHIN,
    
    -- Campos de Auditoría
    USUARIO_CREACION      CHAR(10) NOT NULL
      FOR COLUMN USRCR,
    FECHA_CREACION        TIMESTAMP NOT NULL
      FOR COLUMN FECHCR,
    
    -- Definición de Clave Primaria
    CONSTRAINT PK_CONCERR PRIMARY KEY (ID_EJECUCION, SECUENCIA_INCIDENTE)
  )
  RCDFMT CONCERRREC;

-- Comentarios sobre la tabla
COMMENT ON TABLE EARAUJOL1.CONCERR IS
  'Tabla de incidentes del proceso de conciliación. Cada fila registra un evento anómalo, advertencia o error.';

LABEL ON TABLE EARAUJOL1.CONCERR IS 'Incidentes Conciliación';

-- Comentarios y etiquetas por columna
COMMENT ON COLUMN EARAUJOL1.CONCERR.ID_EJECUCION IS
  'Identificador de la ejecución. Referencia lógica a CONCEXC.ID_EJECUCION. Formato: YYYYMMDD_HHMMSS_secuencial.';
LABEL ON COLUMN EARAUJOL1.CONCERR.ID_EJECUCION IS 'ID Ejecución';
LABEL ON COLUMN EARAUJOL1.CONCERR.ID_EJECUCION
  TEXT IS 'Identificador único de la ejecución a la que pertenece el incidente';

COMMENT ON COLUMN EARAUJOL1.CONCERR.SECUENCIA_INCIDENTE IS
  'Número secuencial de incidente dentro de la ejecución. Comienza en 1.';
LABEL ON COLUMN EARAUJOL1.CONCERR.SECUENCIA_INCIDENTE IS 'Secuencia Incidente';
LABEL ON COLUMN EARAUJOL1.CONCERR.SECUENCIA_INCIDENTE
  TEXT IS 'Número de secuencia del incidente dentro de la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCERR.CODIGO_INCIDENTE IS
  'Código único del tipo de incidente. Ejemplo: WARN-GL-001, ERR-GL-002, CRIT-IFS-001.';
LABEL ON COLUMN EARAUJOL1.CONCERR.CODIGO_INCIDENTE IS 'Código Incidente';
LABEL ON COLUMN EARAUJOL1.CONCERR.CODIGO_INCIDENTE
  TEXT IS 'Código único identificador del tipo de incidente';

COMMENT ON COLUMN EARAUJOL1.CONCERR.TIPO_INCIDENTE IS
  'Clasificación: VALIDACION, CALCULO, LECTURA_DATOS, ESCRITURA_IFS, AUTORIZACIÓN, OTRO.';
LABEL ON COLUMN EARAUJOL1.CONCERR.TIPO_INCIDENTE IS 'Tipo Incidente';
LABEL ON COLUMN EARAUJOL1.CONCERR.TIPO_INCIDENTE
  TEXT IS 'Tipo de incidente: VALIDACION, CALCULO, LECTURA_DATOS, etc.';

COMMENT ON COLUMN EARAUJOL1.CONCERR.CUENTA_CONTABLE IS
  'Cuenta contable afectada si el incidente es específico de una cuenta. NULL si es general del proceso.';
LABEL ON COLUMN EARAUJOL1.CONCERR.CUENTA_CONTABLE IS 'Cuenta Contable';
LABEL ON COLUMN EARAUJOL1.CONCERR.CUENTA_CONTABLE
  TEXT IS 'Cuenta contable relacionada con el incidente (opcional)';

COMMENT ON COLUMN EARAUJOL1.CONCERR.MENSAJE IS
  'Mensaje descriptivo del incidente. Incluye detalles técnicos o funcionales según corresponda.';
LABEL ON COLUMN EARAUJOL1.CONCERR.MENSAJE IS 'Mensaje';
LABEL ON COLUMN EARAUJOL1.CONCERR.MENSAJE
  TEXT IS 'Descripción detallada del incidente';

COMMENT ON COLUMN EARAUJOL1.CONCERR.SEVERIDAD IS
  'Nivel de severidad: BAJA, MEDIA, ALTA, CRITICA.';
LABEL ON COLUMN EARAUJOL1.CONCERR.SEVERIDAD IS 'Severidad';
LABEL ON COLUMN EARAUJOL1.CONCERR.SEVERIDAD
  TEXT IS 'Severidad del incidente: BAJA, MEDIA, ALTA, CRITICA';

COMMENT ON COLUMN EARAUJOL1.CONCERR.FECHA_HORA_INCIDENTE IS
  'Timestamp del momento en que se detectó el incidente.';
LABEL ON COLUMN EARAUJOL1.CONCERR.FECHA_HORA_INCIDENTE IS 'Fecha Hora Incidente';
LABEL ON COLUMN EARAUJOL1.CONCERR.FECHA_HORA_INCIDENTE
  TEXT IS 'Timestamp de detección del incidente';

COMMENT ON COLUMN EARAUJOL1.CONCERR.USUARIO_CREACION IS
  'Usuario bajo cuya sesión se registró el incidente. Generalmente el que ejecutó el programa.';
LABEL ON COLUMN EARAUJOL1.CONCERR.USUARIO_CREACION IS 'Usuario Creación';
LABEL ON COLUMN EARAUJOL1.CONCERR.USUARIO_CREACION
  TEXT IS 'Usuario que registró el incidente';

COMMENT ON COLUMN EARAUJOL1.CONCERR.FECHA_CREACION IS
  'Timestamp de creación del registro de incidente.';
LABEL ON COLUMN EARAUJOL1.CONCERR.FECHA_CREACION IS 'Fecha Creación';
LABEL ON COLUMN EARAUJOL1.CONCERR.FECHA_CREACION
  TEXT IS 'Timestamp de registro del incidente en la base de datos';
