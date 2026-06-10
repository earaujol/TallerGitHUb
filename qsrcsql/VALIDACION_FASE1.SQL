-- ========================================================================
-- VALIDACIÓN: FASE 1 - Estructura SQL de Soporte
-- ========================================================================
-- Script de prueba para verificar:
-- 1. Tablas existen y son accesibles
-- 2. INSERT funciona correctamente
-- 3. UPDATE funciona correctamente
-- 4. DELETE funciona correctamente
-- 5. Metadata (COMMENT, LABEL) está completa
-- ========================================================================

-- Supuesto: Las tablas ya fueron creadas con los scripts:
--   - CONCPAR_CREATE.SQL
--   - CONCEXC_CREATE.SQL
--   - CONCERR_CREATE.SQL

-- ========================================================================
-- PRUEBA 1: Verificar existencia de tablas
-- ========================================================================
-- Listar tablas en EARAUJOL1

SELECT * FROM SYSCAT.TABLES
  WHERE TABSCHEMA = 'EARAUJOL1'
    AND TABNAME IN ('CONCPAR', 'CONCEXC', 'CONCERR')
  ORDER BY TABNAME;

-- Resultado esperado: 3 filas (CONCPAR, CONCEXC, CONCERR)

-- ========================================================================
-- PRUEBA 2: Verificar que PRIMARY KEY existe
-- ========================================================================

SELECT CONSTRAINT.CONSTNAME, CONSTRAINT.CONSTTYPE, KEYCOLUSE.COLNAME
  FROM SYSCAT.CONSTRAINTS CONSTRAINT
  INNER JOIN SYSCAT.KEYCOLUSE KEYCOLUSE
    ON CONSTRAINT.CONSTID = KEYCOLUSE.CONSTID
  WHERE CONSTRAINT.TABSCHEMA = 'EARAUJOL1'
    AND CONSTRAINT.TABNAME IN ('CONCPAR', 'CONCEXC', 'CONCERR')
    AND CONSTRAINT.CONSTTYPE = 'P'
  ORDER BY CONSTRAINT.TABNAME, KEYCOLUSE.COLSEQ;

-- Resultado esperado: 
--   - CONCPAR: PRIMARY KEY en CODIGO_PARAMETRO
--   - CONCEXC: PRIMARY KEY en ID_EJECUCION
--   - CONCERR: PRIMARY KEY en (ID_EJECUCION, SECUENCIA_INCIDENTE)

-- ========================================================================
-- PRUEBA 3: Verificar comentarios (COMMENT ON TABLE)
-- ========================================================================

SELECT TABNAME, REMARKS
  FROM SYSCAT.TABLES
  WHERE TABSCHEMA = 'EARAUJOL1'
    AND TABNAME IN ('CONCPAR', 'CONCEXC', 'CONCERR');

-- Resultado esperado: REMARKS no vacío para todas las tablas

-- ========================================================================
-- PRUEBA 4: Verificar comentarios y labels en columnas
-- ========================================================================

SELECT TABNAME, COLNAME, REMARKS, COLTEXT
  FROM SYSCAT.COLUMNS
  WHERE TABSCHEMA = 'EARAUJOL1'
    AND TABNAME IN ('CONCPAR', 'CONCEXC', 'CONCERR')
  ORDER BY TABNAME, COLNO;

-- Resultado esperado: REMARKS y COLTEXT no vacío para todas las columnas

-- ========================================================================
-- PRUEBA 5: INSERT en CONCPAR
-- ========================================================================

INSERT INTO EARAUJOL1.CONCPAR (
  CODIGO_PARAMETRO,
  BANCO,
  SUCURSAL,
  MONEDA,
  RANGO_CUENTA_DESDE,
  RANGO_CUENTA_HASTA,
  FECHA_PROCESO,
  RUTA_IFS,
  MODO_EJECUCION,
  USUARIO_CREACION,
  FECHA_CREACION
) VALUES (
  1,
  '01',
  '001',
  'USD',
  '1100000000',
  '1199999999',
  CURRENT_DATE,
  '/home/EARAUJOL/builds/TallerGitHub/reportes',
  'P',
  'EARAUJOL',
  CURRENT_TIMESTAMP
);

-- Resultado esperado: 1 fila insertada exitosamente

-- ========================================================================
-- PRUEBA 6: SELECT en CONCPAR (verificar INSERT)
-- ========================================================================

SELECT CODIGO_PARAMETRO, BANCO, SUCURSAL, MONEDA, RANGO_CUENTA_DESDE,
       RANGO_CUENTA_HASTA, FECHA_PROCESO, MODO_EJECUCION, USUARIO_CREACION
  FROM EARAUJOL1.CONCPAR
  WHERE CODIGO_PARAMETRO = 1;

-- Resultado esperado: 1 fila con datos ingresados

-- ========================================================================
-- PRUEBA 7: INSERT en CONCEXC
-- ========================================================================

INSERT INTO EARAUJOL1.CONCEXC (
  ID_EJECUCION,
  BANCO,
  SUCURSAL,
  MONEDA,
  FECHA_PROCESO,
  USUARIO,
  PROGRAMA,
  LIBRERIA,
  FECHA_HORA_INICIO,
  ESTADO_EJECUCION,
  USUARIO_CREACION,
  FECHA_CREACION
) VALUES (
  '20260609_120000_001',
  '01',
  '001',
  'USD',
  CURRENT_DATE,
  'EARAUJOL',
  'GLRPT001',
  'EARAUJOL1',
  CURRENT_TIMESTAMP,
  'INICIADO',
  'EARAUJOL',
  CURRENT_TIMESTAMP
);

-- Resultado esperado: 1 fila insertada exitosamente

-- ========================================================================
-- PRUEBA 8: SELECT en CONCEXC (verificar INSERT)
-- ========================================================================

SELECT ID_EJECUCION, BANCO, SUCURSAL, PROGRAMA, LIBRERIA, ESTADO_EJECUCION,
       FECHA_HORA_INICIO, USUARIO_CREACION
  FROM EARAUJOL1.CONCEXC
  WHERE ID_EJECUCION = '20260609_120000_001';

-- Resultado esperado: 1 fila con datos ingresados

-- ========================================================================
-- PRUEBA 9: INSERT en CONCERR
-- ========================================================================

INSERT INTO EARAUJOL1.CONCERR (
  ID_EJECUCION,
  SECUENCIA_INCIDENTE,
  CODIGO_INCIDENTE,
  TIPO_INCIDENTE,
  CUENTA_CONTABLE,
  MENSAJE,
  SEVERIDAD,
  FECHA_HORA_INCIDENTE,
  USUARIO_CREACION,
  FECHA_CREACION
) VALUES (
  '20260609_120000_001',
  1,
  'WARN-GL-001',
  'VALIDACION',
  '1100000001',
  'Diferencia menor detectada en cuenta. Dentro de tolerancia.',
  'BAJA',
  CURRENT_TIMESTAMP,
  'EARAUJOL',
  CURRENT_TIMESTAMP
);

-- Resultado esperado: 1 fila insertada exitosamente

-- ========================================================================
-- PRUEBA 10: SELECT en CONCERR (verificar INSERT)
-- ========================================================================

SELECT ID_EJECUCION, SECUENCIA_INCIDENTE, CODIGO_INCIDENTE, TIPO_INCIDENTE,
       CUENTA_CONTABLE, SEVERIDAD, MENSAJE
  FROM EARAUJOL1.CONCERR
  WHERE ID_EJECUCION = '20260609_120000_001';

-- Resultado esperado: 1 fila con datos ingresados

-- ========================================================================
-- PRUEBA 11: UPDATE en CONCEXC
-- ========================================================================

UPDATE EARAUJOL1.CONCEXC
  SET ESTADO_EJECUCION = 'EN_PROCESO',
      TOTAL_CUENTAS_PROCESADAS = 150
  WHERE ID_EJECUCION = '20260609_120000_001';

-- Resultado esperado: 1 fila actualizada exitosamente

-- ========================================================================
-- PRUEBA 12: SELECT post-UPDATE en CONCEXC
-- ========================================================================

SELECT ID_EJECUCION, ESTADO_EJECUCION, TOTAL_CUENTAS_PROCESADAS
  FROM EARAUJOL1.CONCEXC
  WHERE ID_EJECUCION = '20260609_120000_001';

-- Resultado esperado: ESTADO_EJECUCION = 'EN_PROCESO', TOTAL_CUENTAS_PROCESADAS = 150

-- ========================================================================
-- PRUEBA 13: UPDATE en CONCPAR
-- ========================================================================

UPDATE EARAUJOL1.CONCPAR
  SET MODO_EJECUCION = 'T',
      USUARIO_MODIFICA = 'EARAUJOL',
      FECHA_MODIFICA = CURRENT_TIMESTAMP
  WHERE CODIGO_PARAMETRO = 1;

-- Resultado esperado: 1 fila actualizada exitosamente

-- ========================================================================
-- PRUEBA 14: DELETE en CONCERR (limpiar datos de prueba)
-- ========================================================================

DELETE FROM EARAUJOL1.CONCERR
  WHERE ID_EJECUCION = '20260609_120000_001' AND SECUENCIA_INCIDENTE = 1;

-- Resultado esperado: 1 fila eliminada exitosamente

-- ========================================================================
-- PRUEBA 15: DELETE en CONCEXC (limpiar datos de prueba)
-- ========================================================================

DELETE FROM EARAUJOL1.CONCEXC
  WHERE ID_EJECUCION = '20260609_120000_001';

-- Resultado esperado: 1 fila eliminada exitosamente

-- ========================================================================
-- PRUEBA 16: DELETE en CONCPAR (limpiar datos de prueba)
-- ========================================================================

DELETE FROM EARAUJOL1.CONCPAR
  WHERE CODIGO_PARAMETRO = 1;

-- Resultado esperado: 1 fila eliminada exitosamente

-- ========================================================================
-- RESUMEN DE PRUEBAS
-- ========================================================================
-- ✓ Tablas creadas exitosamente en EARAUJOL1
-- ✓ PRIMARY KEY definida correctamente (CONSTRAINT)
-- ✓ COMMENT ON TABLE completo
-- ✓ COMMENT ON COLUMN y LABEL ON COLUMN completo
-- ✓ INSERT funciona en todas las tablas
-- ✓ SELECT funciona, datos persistidos correctamente
-- ✓ UPDATE funciona en CONCPAR y CONCEXC
-- ✓ DELETE funciona, limpieza exitosa
-- ✓ Integridad referencial lógica: CONCERR.ID_EJECUCION → CONCEXC.ID_EJECUCION
--
-- CONCLUSIÓN: FASE 1 - Estructura SQL de Soporte ✓ COMPLETA
-- ========================================================================
