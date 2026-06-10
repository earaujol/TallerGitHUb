-- ========================================================================
-- TABLA: CONCPAR (Parámetros de Conciliación)
-- ========================================================================
-- METADATA FUNCIONAL
-- Nombre:        Parámetros de Conciliación
-- Descripción:   Almacena los parámetros de configuración para cada 
--                ejecución del proceso de conciliación de cuentas mayores.
-- Objetivo:      Centralizar la parametrización del proceso de conciliación
--                (banco, sucursal, moneda, rango de cuentas, fecha proceso,
--                ruta IFS destino, modo ejecución).
-- Tipo:          Tabla maestra de parámetros.
-- Origen:        Proceso de conciliación GLBLN.
-- Permanencia:   Permanente (histórica).
-- Uso:           Consulta y configuración de parámetros antes de ejecución
--                del proceso de conciliación.
-- Restricciones: Debe validarse que banco, sucursal, moneda sean válidos.
--                La ruta IFS debe ser accesible. El rango de cuentas debe
--                ser coherente (desde <= hasta).
--
-- METADATA DE PROYECTO
-- Equipo:        Taller GitHub Copilot
-- Fecha:         2026-06-09
-- Proyecto:      Conciliación de Cuentas Mayores (GLBLN)
-- Versión:       1.0
-- ========================================================================

CREATE OR REPLACE TABLE EARAUJOL1.CONCPAR
  FOR SYSTEM NAME CONCPAR
  (
    -- Campos de Clave Primaria
    CODIGO_PARAMETRO      INTEGER NOT NULL
      FOR COLUMN CODPARM,
    
    -- Identificadores de Contexto
    BANCO                 CHAR(2) NOT NULL
      FOR COLUMN BANCO,
    SUCURSAL              CHAR(3) NOT NULL
      FOR COLUMN SUCUR,
    MONEDA                CHAR(3) NOT NULL
      FOR COLUMN MONDA,
    
    -- Parámetros de Rango de Cuentas
    RANGO_CUENTA_DESDE    CHAR(10) NOT NULL
      FOR COLUMN CNTFR,
    RANGO_CUENTA_HASTA    CHAR(10) NOT NULL
      FOR COLUMN CNTTO,
    
    -- Parámetros de Proceso
    FECHA_PROCESO         DATE NOT NULL
      FOR COLUMN FECHP,
    RUTA_IFS              VARCHAR(256) NOT NULL
      FOR COLUMN RUTIFS,
    MODO_EJECUCION        CHAR(1) NOT NULL
      FOR COLUMN MODEJ,
    PARAMETROS_ADICIONALES VARCHAR(512)
      FOR COLUMN PARAAD,
    
    -- Campos de Auditoría
    USUARIO_CREACION      CHAR(10) NOT NULL
      FOR COLUMN USRCR,
    FECHA_CREACION        TIMESTAMP NOT NULL
      FOR COLUMN FECHCR,
    USUARIO_MODIFICA      CHAR(10)
      FOR COLUMN USRMOD,
    FECHA_MODIFICA        TIMESTAMP
      FOR COLUMN FECHMOD,
    
    -- Definición de Clave Primaria
    CONSTRAINT PK_CONCPAR PRIMARY KEY (CODIGO_PARAMETRO)
  )
  RCDFMT CONCPARREC;

-- Renombrar tabla para sistema (10 caracteres)
-- Nota: El nombre corto CONCPAR ya tiene 7 caracteres, compatible con DDS

-- Comentarios sobre la tabla
COMMENT ON TABLE EARAUJOL1.CONCPAR IS
  'Tabla maestra de parámetros de conciliación de cuentas mayores. Almacena configuración por corrida.';

LABEL ON TABLE EARAUJOL1.CONCPAR IS 'Parámetros Conciliación';

-- Comentarios y etiquetas por columna
COMMENT ON COLUMN EARAUJOL1.CONCPAR.CODIGO_PARAMETRO IS
  'Identificador único secuencial de cada configuración de parámetros.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.CODIGO_PARAMETRO IS 'Código Parámetro';
LABEL ON COLUMN EARAUJOL1.CONCPAR.CODIGO_PARAMETRO
  TEXT IS 'Identificador único de parámetros de conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.BANCO IS
  'Código de banco según tabla CNTRLCNT. Ejemplo: 01, 02.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.BANCO IS 'Banco';
LABEL ON COLUMN EARAUJOL1.CONCPAR.BANCO
  TEXT IS 'Código de banco para conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.SUCURSAL IS
  'Código de sucursal según tabla CNTRLBRN. Ejemplo: 001, 002.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.SUCURSAL IS 'Sucursal';
LABEL ON COLUMN EARAUJOL1.CONCPAR.SUCURSAL
  TEXT IS 'Código de sucursal para filtro';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.MONEDA IS
  'Código de moneda según tablas de referencia. Ejemplo: USD, MXN, COP.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.MONEDA IS 'Moneda';
LABEL ON COLUMN EARAUJOL1.CONCPAR.MONEDA
  TEXT IS 'Código ISO de moneda para conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_DESDE IS
  'Cuenta contable inicial del rango a conciliar. Formato: 10 dígitos.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_DESDE IS 'Cuenta Desde';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_DESDE
  TEXT IS 'Cuenta contable inicial del rango de procesamiento';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_HASTA IS
  'Cuenta contable final del rango a conciliar. Formato: 10 dígitos.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_HASTA IS 'Cuenta Hasta';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RANGO_CUENTA_HASTA
  TEXT IS 'Cuenta contable final del rango de procesamiento';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.FECHA_PROCESO IS
  'Fecha de corte para la conciliación. Determina qué saldos y movimientos se incluyen.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_PROCESO IS 'Fecha Proceso';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_PROCESO
  TEXT IS 'Fecha de corte para conciliación de cuentas';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.RUTA_IFS IS
  'Ruta en Integrated File System (IFS) donde se depositará el JSON de salida. Ej: /home/usuario/reportes.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RUTA_IFS IS 'Ruta IFS';
LABEL ON COLUMN EARAUJOL1.CONCPAR.RUTA_IFS
  TEXT IS 'Ruta del Integrated File System para escribir salida JSON';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.MODO_EJECUCION IS
  'Modo de ejecución: P=Productivo, T=Prueba, D=Depuración.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.MODO_EJECUCION IS 'Modo Ejecución';
LABEL ON COLUMN EARAUJOL1.CONCPAR.MODO_EJECUCION
  TEXT IS 'Modo de operación: P=Productivo, T=Prueba, D=Depuración';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.PARAMETROS_ADICIONALES IS
  'Campo de extensión para parámetros adicionales en formato JSON o delimitado. Uso futuro.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.PARAMETROS_ADICIONALES IS 'Parámetros Adicionales';
LABEL ON COLUMN EARAUJOL1.CONCPAR.PARAMETROS_ADICIONALES
  TEXT IS 'Parámetros adicionales extensibles en formato JSON';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.USUARIO_CREACION IS
  'Identificador del usuario que creó el registro. Asignado por el sistema.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.USUARIO_CREACION IS 'Usuario Creación';
LABEL ON COLUMN EARAUJOL1.CONCPAR.USUARIO_CREACION
  TEXT IS 'Usuario que creó el parámetro de conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.FECHA_CREACION IS
  'Timestamp de creación del registro. Asignado por el sistema (CURRENT_TIMESTAMP).';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_CREACION IS 'Fecha Creación';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_CREACION
  TEXT IS 'Timestamp de creación del parámetro';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.USUARIO_MODIFICA IS
  'Identificador del usuario que modificó el registro. NULL si no ha sido modificado.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.USUARIO_MODIFICA IS 'Usuario Modifica';
LABEL ON COLUMN EARAUJOL1.CONCPAR.USUARIO_MODIFICA
  TEXT IS 'Usuario que modificó el parámetro por última vez';

COMMENT ON COLUMN EARAUJOL1.CONCPAR.FECHA_MODIFICA IS
  'Timestamp de última modificación. NULL si no ha sido modificado.';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_MODIFICA IS 'Fecha Modifica';
LABEL ON COLUMN EARAUJOL1.CONCPAR.FECHA_MODIFICA
  TEXT IS 'Timestamp de última modificación del parámetro';
