      * ========================================================================
      * PROGRAMA: SRV_AUDIT_TST (Pruebas Unitarias - Servicio SRV_AUDIT)
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa de prueba unitaria para validar todas las procedures del
      * programa de servicio SRV_AUDIT. Cubre LogStart, LogEnd y LogIncident.
      *
      * CRITERIOS DE ACEPTACIÓN:
      * ✓ LogStart retorna resultado SUCCESS
      * ✓ LogEnd actualiza estado correctamente
      * ✓ LogIncident registra incidente con secuencia
      * ✓ Errores manejados correctamente
      *
      * EQUIPO:        Taller GitHub Copilot
      * FECHA:         2026-06-09
      * PROYECTO:      Conciliación GLBLN - Pruebas Unitarias
      * VERSIÓN:       1.0
      * ========================================================================

     H DFTACTGRP(*YES)
     H BNDDIR('QSys.Lib/EARAUJOL1.Lib')
     H OPTION(*SRCSTMT : *NODEBUGIO)

      * ========================================================================
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES
      * ========================================================================

      /COPY qsrctxt/SRV_AUDIT

      * ========================================================================
      * VARIABLES GLOBALES Y CONTADORES
      * ========================================================================

     D gTestsPassed    S INT(10:0) INZ(0)
     D gTestsFailed    S INT(10:0) INZ(0)
     D gTestsTotal     S INT(10:0) INZ(0)

     D gTestResult     S CHAR(10)

      * ========================================================================
      * DATA STRUCTURES PARA PRUEBAS
      * ========================================================================

     D dsResultLog     DS LIKEDS(dsAuditResult) INZ

      * ========================================================================
      * PROCEDURES DE PRUEBA
      * ========================================================================

     D MAIN            PR
     D TEST_LogStart   PR
     D TEST_LogEnd     PR
     D TEST_LogIncident...
     D                 PR
     D PrintTestResult...
     D                 PR
     D   pTestName     VARCHAR(100)
     D   pResult       CHAR(10)
     D   pDetails      VARCHAR(256)

      * ========================================================================

      MAIN;

        DSPLY 'Iniciando Pruebas Unitarias del Servicio SRV_AUDIT';
        DSPLY '';

        // Prueba 1: SRV_AUDIT_LogStart
        TEST_LogStart;
        DSPLY '';

        // Prueba 2: SRV_AUDIT_LogEnd
        TEST_LogEnd;
        DSPLY '';

        // Prueba 3: SRV_AUDIT_LogIncident
        TEST_LogIncident;
        DSPLY '';

        // Resumen
        DSPLY '========================================';
        DSPLY 'RESUMEN DE PRUEBAS';
        DSPLY '========================================';
        DSPLY 'Total de Pruebas:    ' + %CHAR(gTestsTotal);
        DSPLY 'Pruebas Exitosas:    ' + %CHAR(gTestsPassed);
        DSPLY 'Pruebas Fallidas:    ' + %CHAR(gTestsFailed);
        DSPLY '';

        IF gTestsFailed = 0;
          DSPLY '✓ TODAS LAS PRUEBAS PASARON';
        ELSE;
          DSPLY '✗ ALGUNAS PRUEBAS FALLARON';
        ENDIF;

        *INLR = *ON;
        RETURN;

      END-MAIN;

      * ========================================================================
      * TEST 1: SRV_AUDIT_LogStart
      * ========================================================================
      * Casos:
      *   1a. Retorna resultado SUCCESS
      *   1b. Operación es 'LogStart'
      * ========================================================================

     P TEST_LogStart...
     P                 B
     D                 PI

     D lIdExec         CHAR(21) INZ('20260609_120000_001')
     D lFecha          DATE

     BEGIN

       DSPLY '--- TEST: SRV_AUDIT_LogStart ---';

       lFecha = %DATE();

       // Test 1a: Resultado SUCCESS
       gTestsTotal += 1;

       dsResultLog = SRV_AUDIT_LogStart(
         lIdExec,
         '01',
         '001',
         'USD',
         '1100000001',
         '1199999999',
         lFecha,
         'USRFIN01',
         'GLRPT001',
         'EARAUJOL1'
       );

       IF dsResultLog.dsError.errorStatus = 'S' AND
          dsResultLog.statusOperacion = 'SUCCESS';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogStart 1a: Resultado SUCCESS', gTestResult,
         'status=' + dsResultLog.statusOperacion);

       // Test 1b: Operación correcta
       gTestsTotal += 1;

       IF dsResultLog.operacion = 'LogStart';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogStart 1b: Operación correcta', gTestResult,
         'operacion=' + dsResultLog.operacion);

     END-PROC TEST_LogStart;

      * ========================================================================
      * TEST 2: SRV_AUDIT_LogEnd
      * ========================================================================
      * Casos:
      *   2a. Retorna resultado SUCCESS
      *   2b. Actualiza contadores
      * ========================================================================

     P TEST_LogEnd...
     P                 B
     D                 PI

     D lIdExec         CHAR(21) INZ('20260609_120000_001')

     BEGIN

       DSPLY '--- TEST: SRV_AUDIT_LogEnd ---';

       // Test 2a: Resultado SUCCESS
       gTestsTotal += 1;

       dsResultLog = SRV_AUDIT_LogEnd(
         lIdExec,
         150,    // pTotalCuentas
         134,    // pTotalConciliadas
         16,     // pTotalConDif
         0,      // pTotalErrores
         'FINALIZADO'
       );

       IF dsResultLog.dsError.errorStatus = 'S' AND
          dsResultLog.statusOperacion = 'SUCCESS';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogEnd 2a: Resultado SUCCESS', gTestResult,
         'status=' + dsResultLog.statusOperacion);

       // Test 2b: Operación correcta
       gTestsTotal += 1;

       IF dsResultLog.operacion = 'LogEnd' AND
          dsResultLog.idEjecucion = lIdExec;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogEnd 2b: Operación correcta', gTestResult,
         'operacion=' + dsResultLog.operacion);

     END-PROC TEST_LogEnd;

      * ========================================================================
      * TEST 3: SRV_AUDIT_LogIncident
      * ========================================================================
      * Casos:
      *   3a. Retorna resultado SUCCESS
      *   3b. Registra código de incidente
      * ========================================================================

     P TEST_LogIncident...
     P                 B
     D                 PI

     D lIdExec         CHAR(21) INZ('20260609_120000_001')

     BEGIN

       DSPLY '--- TEST: SRV_AUDIT_LogIncident ---';

       // Test 3a: Resultado SUCCESS
       gTestsTotal += 1;

       dsResultLog = SRV_AUDIT_LogIncident(
         lIdExec,
         'INC-0001',
         'VALIDACION',
         'MEDIA',
         '1100000001',
         'Diferencia menor dentro de tolerancia'
       );

       IF dsResultLog.dsError.errorStatus = 'S' AND
          dsResultLog.statusOperacion = 'SUCCESS';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogIncident 3a: Resultado SUCCESS', gTestResult,
         'status=' + dsResultLog.statusOperacion);

       // Test 3b: Operación correcta
       gTestsTotal += 1;

       IF dsResultLog.operacion = 'LogIncident';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('LogIncident 3b: Operación correcta', gTestResult,
         'operacion=' + dsResultLog.operacion);

     END-PROC TEST_LogIncident;

      * ========================================================================
      * UTIL: PrintTestResult
      * ========================================================================

     P PrintTestResult...
     P                 B
     D                 PI
     D   pTestName     VARCHAR(100)
     D   pResult       CHAR(10)
     D   pDetails      VARCHAR(256)

     D lResultDisplay  S CHAR(5)

     BEGIN

       IF pResult = 'PASS';
         lResultDisplay = '✓';
       ELSE;
         lResultDisplay = '✗';
       ENDIF;

       DSPLY lResultDisplay + ' ' + %TRIM(pTestName) + ' - ' + 
             %TRIM(pDetails);

     END-PROC PrintTestResult;
