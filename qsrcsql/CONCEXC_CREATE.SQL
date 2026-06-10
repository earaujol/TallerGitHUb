-- ========================================================================
-- TABLA: CONCEXC (Ejecuciones y Auditoría)
-- ========================================================================
-- METADATA FUNCIONAL
-- Nombre:        Ejecuciones de Conciliación
-- Descripción:   Registra cada ejecución del proceso de conciliación con
--                metadata de inicio, fin, estado, contadores y resultado.
-- Objetivo:      Crear un histórico auditable de todas las corridas del
--                proceso de conciliación para trazabilidad operativa.
-- Tipo:          Tabla de hechos/auditoría.
-- Origen:        Programa principal GLRPT001.
-- Permanencia:   Permanente (histórica completa).
-- Uso:           Consultas de auditoría, seguimiento de corridas, 
--                debugging y análisis de resultados.
-- Restricciones: idEjecucion debe ser único. Timestamps deben ser 
--                coherentes (inicio <= fin). Contadores >= 0.
--
-- METADATA DE PROYECTO
-- Equipo:        Taller GitHub Copilot
-- Fecha:         2026-06-09
-- Proyecto:      Conciliación de Cuentas Mayores (GLBLN)
-- Versión:       1.0
-- ========================================================================

CREATE OR REPLACE TABLE EARAUJOL1.CONCEXC
  FOR SYSTEM NAME CONCEXC
  (
    -- Campos de Clave Primaria
    ID_EJECUCION          VARCHAR(30) NOT NULL
      FOR COLUMN IDEXEC,
    
    -- Identificadores de Contexto
    BANCO                 CHAR(2) NOT NULL
      FOR COLUMN BANCO,
    SUCURSAL              CHAR(3) NOT NULL
      FOR COLUMN SUCUR,
    MONEDA                CHAR(3) NOT NULL
      FOR COLUMN MONDA,
    FECHA_PROCESO         DATE NOT NULL
      FOR COLUMN FECHP,
    
    -- Identificación del Proceso
    USUARIO               CHAR(10) NOT NULL
      FOR COLUMN USRID,
    PROGRAMA              CHAR(10) NOT NULL
      FOR COLUMN PROG,
    LIBRERIA              CHAR(10) NOT NULL
      FOR COLUMN LIB,
    
    -- Timestamps de Ejecución
    FECHA_HORA_INICIO     TIMESTAMP NOT NULL
      FOR COLUMN FICHST,
    FECHA_HORA_FIN        TIMESTAMP
      FOR COLUMN FICHFN,
    
    -- Estado de Ejecución
    ESTADO_EJECUCION      CHAR(20) NOT NULL
      FOR COLUMN ESTEJ,
    
    -- Contadores de Procesamiento
    TOTAL_CUENTAS_PROCESADAS    INTEGER NOT NULL DEFAULT 0
      FOR COLUMN TCTPRC,
    TOTAL_CUENTAS_CONCILIADAS   INTEGER NOT NULL DEFAULT 0
      FOR COLUMN TCTCNC,
    TOTAL_CUENTAS_CON_DIFERENCIA INTEGER NOT NULL DEFAULT 0
      FOR COLUMN TCTDIF,
    
    -- Sumarización de Saldos
    SUMATORIA_SALDO_FUENTE      DECIMAL(18,2) NOT NULL DEFAULT 0
      FOR COLUMN SUMSFO,
    SUMATORIA_SALDO_CONCILIADO  DECIMAL(18,2) NOT NULL DEFAULT 0
      FOR COLUMN SUMSCN,
    SUMATORIA_DIFERENCIA_NETA   DECIMAL(18,2) NOT NULL DEFAULT 0
      FOR COLUMN SUMDIF,
    
    -- Campos de Auditoría
    USUARIO_CREACION      CHAR(10) NOT NULL
      FOR COLUMN USRCR,
    FECHA_CREACION        TIMESTAMP NOT NULL
      FOR COLUMN FECHCR,
    
    -- Definición de Clave Primaria
    CONSTRAINT PK_CONCEXC PRIMARY KEY (ID_EJECUCION)
  )
  RCDFMT CONCEXCREC;

-- Comentarios sobre la tabla
COMMENT ON TABLE EARAUJOL1.CONCEXC IS
  'Tabla de auditoría de ejecuciones del proceso de conciliación. Cada fila representa una corrida completa con metadata y contadores.';

LABEL ON TABLE EARAUJOL1.CONCEXC IS 'Ejecuciones Conciliación';

-- Comentarios y etiquetas por columna
COMMENT ON COLUMN EARAUJOL1.CONCEXC.ID_EJECUCION IS
  'Identificador único y trazable de cada ejecución. Formato: YYYYMMDD_HHMMSS_secuencial.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.ID_EJECUCION IS 'ID Ejecución';
LABEL ON COLUMN EARAUJOL1.CONCEXC.ID_EJECUCION
  TEXT IS 'Identificador único trazable de la ejecución (YYYYMMDD_HHMMSS_seq)';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.BANCO IS
  'Código de banco procesado. Copia del parámetro de entrada.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.BANCO IS 'Banco';
LABEL ON COLUMN EARAUJOL1.CONCEXC.BANCO
  TEXT IS 'Código de banco para la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.SUCURSAL IS
  'Código de sucursal procesada. Copia del parámetro de entrada.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUCURSAL IS 'Sucursal';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUCURSAL
  TEXT IS 'Código de sucursal para la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.MONEDA IS
  'Código de moneda procesada. Copia del parámetro de entrada.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.MONEDA IS 'Moneda';
LABEL ON COLUMN EARAUJOL1.CONCEXC.MONEDA
  TEXT IS 'Código de moneda para la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.FECHA_PROCESO IS
  'Fecha de corte de la conciliación. Copia del parámetro de entrada.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_PROCESO IS 'Fecha Proceso';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_PROCESO
  TEXT IS 'Fecha de corte de la conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.USUARIO IS
  'Identificador del usuario que ejecutó el programa (GETUSERID).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.USUARIO IS 'Usuario';
LABEL ON COLUMN EARAUJOL1.CONCEXC.USUARIO
  TEXT IS 'Usuario que ejecutó el proceso de conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.PROGRAMA IS
  'Nombre del programa que ejecutó el proceso (GLRPT001).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.PROGRAMA IS 'Programa';
LABEL ON COLUMN EARAUJOL1.CONCEXC.PROGRAMA
  TEXT IS 'Programa principal que ejecutó la conciliación';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.LIBRERIA IS
  'Librería donde reside el programa (EARAUJOL1).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.LIBRERIA IS 'Librería';
LABEL ON COLUMN EARAUJOL1.CONCEXC.LIBRERIA
  TEXT IS 'Librería donde reside el programa ejecutado';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_INICIO IS
  'Timestamp de inicio del proceso. Asignado al comenzar la ejecución.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_INICIO IS 'Fecha Hora Inicio';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_INICIO
  TEXT IS 'Timestamp de inicio de la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_FIN IS
  'Timestamp de finalización. Puede ser NULL si la ejecución está en progreso o falló.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_FIN IS 'Fecha Hora Fin';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_HORA_FIN
  TEXT IS 'Timestamp de finalización de la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.ESTADO_EJECUCION IS
  'Estado final del proceso: INICIADO, EN_PROCESO, FINALIZADO, FINALIZADO_CON_ERRORES, ABORTADO, ERROR_CRITICO.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.ESTADO_EJECUCION IS 'Estado Ejecución';
LABEL ON COLUMN EARAUJOL1.CONCEXC.ESTADO_EJECUCION
  TEXT IS 'Estado final: INICIADO, EN_PROCESO, FINALIZADO, etc.';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_PROCESADAS IS
  'Total de registros de cuentas mayores leídos y procesados.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_PROCESADAS IS 'Total Cuentas Procesadas';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_PROCESADAS
  TEXT IS 'Cantidad total de cuentas procesadas';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CONCILIADAS IS
  'Total de cuentas con estado CONCILIADA (diferencia = 0 o dentro de tolerancia).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CONCILIADAS IS 'Total Cuentas Conciliadas';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CONCILIADAS
  TEXT IS 'Cantidad de cuentas conciliadas exitosamente';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CON_DIFERENCIA IS
  'Total de cuentas con diferencia fuera de tolerancia o pendiente de revisión.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CON_DIFERENCIA IS 'Total Cuentas Con Diferencia';
LABEL ON COLUMN EARAUJOL1.CONCEXC.TOTAL_CUENTAS_CON_DIFERENCIA
  TEXT IS 'Cantidad de cuentas con diferencias no conciliadas';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_FUENTE IS
  'Suma total de saldos finales directamente de la fuente (GLBLN).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_FUENTE IS 'Suma Saldo Fuente';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_FUENTE
  TEXT IS 'Sumatoria de saldos de fuente de todas las cuentas';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_CONCILIADO IS
  'Suma total de saldos después de conciliación (ajuste por partidas en tránsito).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_CONCILIADO IS 'Suma Saldo Conciliado';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_SALDO_CONCILIADO
  TEXT IS 'Sumatoria de saldos conciliados de todas las cuentas';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_DIFERENCIA_NETA IS
  'Suma total de diferencias netas por cuenta. Debe coincidir con (SUMATORIA_SALDO_FUENTE - SUMATORIA_SALDO_CONCILIADO).';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_DIFERENCIA_NETA IS 'Suma Diferencia Neta';
LABEL ON COLUMN EARAUJOL1.CONCEXC.SUMATORIA_DIFERENCIA_NETA
  TEXT IS 'Sumatoria de diferencias netas de todas las cuentas';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.USUARIO_CREACION IS
  'Usuario que registró la ejecución en la BD. Generalmente coincide con USUARIO.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.USUARIO_CREACION IS 'Usuario Creación';
LABEL ON COLUMN EARAUJOL1.CONCEXC.USUARIO_CREACION
  TEXT IS 'Usuario que registró la ejecución';

COMMENT ON COLUMN EARAUJOL1.CONCEXC.FECHA_CREACION IS
  'Timestamp de creación del registro de auditoría.';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_CREACION IS 'Fecha Creación';
LABEL ON COLUMN EARAUJOL1.CONCEXC.FECHA_CREACION
  TEXT IS 'Timestamp de registro de la ejecución';
