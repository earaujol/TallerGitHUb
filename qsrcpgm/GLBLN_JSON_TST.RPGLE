      * ========================================================================
      * PROGRAMA: GLBLN_JSON_TST (Pruebas Unitarias - Módulo GLBLN_JSON)
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa de prueba unitaria para validar todas las procedures del
      * módulo GLBLN_JSON. Cubre construcción de metadata, ejecución,
      * cuentas, control totales y escritura en IFS.
      *
      * CRITERIOS DE ACEPTACIÓN:
      * ✓ BuildMetadata retorna estructura metadata completa
      * ✓ BuildExecution retorna estructura con timestamps y datos
      * ✓ BuildCuentas construye array de cuentas correctamente
      * ✓ BuildControlTotales suma totales correctamente
      * ✓ WriteToIFS genera ruta válida con nombre trazable
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

      /COPY qsrctxt/GLBLN_JSON

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

     D dsMetadata      DS LIKEDS(dsJsonMetadata) INZ
     D dsExecution     DS LIKEDS(dsJsonExecution) INZ
     D dsCuentas       DS LIKEDS(dsJsonResultCuentas) INZ
     D dsControlTotales DS LIKEDS(dsJsonControlTotales) INZ
     D dsResultWrite   DS LIKEDS(dsJsonResultWrite) INZ

      * ========================================================================
      * PROCEDURES DE PRUEBA
      * ========================================================================

     D MAIN            PR
     D TEST_BuildMetadata...
     D                 PR
     D TEST_BuildExecution...
     D                 PR
     D TEST_BuildCuentas...
     D                 PR
     D TEST_BuildControlTotales...
     D                 PR
     D TEST_WriteToIFS...
     D                 PR
     D PrintTestResult...
     D                 PR
     D   pTestName     VARCHAR(100)
     D   pResult       CHAR(10)
     D   pDetails      VARCHAR(256)

      * ========================================================================

      MAIN;

        DSPLY 'Iniciando Pruebas Unitarias del Módulo GLBLN_JSON';
        DSPLY '';

        // Prueba 1: GLBLN_json_BuildMetadata
        TEST_BuildMetadata;
        DSPLY '';

        // Prueba 2: GLBLN_json_BuildExecution
        TEST_BuildExecution;
        DSPLY '';

        // Prueba 3: GLBLN_json_BuildCuentas
        TEST_BuildCuentas;
        DSPLY '';

        // Prueba 4: GLBLN_json_BuildControlTotales
        TEST_BuildControlTotales;
        DSPLY '';

        // Prueba 5: GLBLN_json_WriteToIFS
        TEST_WriteToIFS;
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
      * TEST 1: GLBLN_json_BuildMetadata
      * ========================================================================
      * Casos:
      *   1a. Retorna estructura metadata con valores correctos
      *   1b. Ambiente se asigna correctamente
      * ========================================================================

     P TEST_BuildMetadata...
     P                 B
     D                 PI

     BEGIN

       DSPLY '--- TEST: GLBLN_json_BuildMetadata ---';

       // Test 1a: Metadata completa
       gTestsTotal += 1;

       dsMetadata = GLBLN_json_BuildMetadata('QA ');

       IF dsMetadata.dsError.errorStatus = 'S' AND
          dsMetadata.versionEstructura = '1.0.0' AND
          dsMetadata.sistemaOrigen = 'IBS-IBM-i' AND
          dsMetadata.charset = 'UTF-8';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildMetadata 1a: Estructura completa', gTestResult,
         'version=' + dsMetadata.versionEstructura);

       // Test 1b: Ambiente asignado
       gTestsTotal += 1;

       dsMetadata = GLBLN_json_BuildMetadata('PRD');

       IF dsMetadata.ambiente = 'PRD';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildMetadata 1b: Ambiente', gTestResult,
         'ambiente=' + dsMetadata.ambiente);

     END-PROC TEST_BuildMetadata;

      * ========================================================================
      * TEST 2: GLBLN_json_BuildExecution
      * ========================================================================
      * Casos:
      *   2a. Retorna estructura ejecución completa
      *   2b. Timestamps son válidos (inicio <= fin)
      * ========================================================================

     P TEST_BuildExecution...
     P                 B
     D                 PI

     D lIdExec         CHAR(21) INZ('20260609_120000_001')
     D lFecha          DATE
     D lTimestamp      TIMESTAMP

     BEGIN

       DSPLY '--- TEST: GLBLN_json_BuildExecution ---';

       lFecha = %DATE();
       lTimestamp = %TIMESTAMP();

       // Test 2a: Estructura completa
       gTestsTotal += 1;

       dsExecution = GLBLN_json_BuildExecution(
         lIdExec,
         lFecha,
         'USRFIN01',
         'GLRPT001',
         'EARAUJOL1',
         'FINALIZADO',
         lTimestamp
       );

       IF dsExecution.dsError.errorStatus = 'S' AND
          dsExecution.idEjecucion = lIdExec AND
          dsExecution.usuario = 'USRFIN01' AND
          dsExecution.programa = 'GLRPT001';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildExecution 2a: Estructura completa', gTestResult,
         'idExec=' + %TRIM(dsExecution.idEjecucion));

       // Test 2b: Timestamps válidos
       gTestsTotal += 1;

       IF dsExecution.fechaHoraInicio <= dsExecution.fechaHoraFin;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildExecution 2b: Timestamps válidos', gTestResult,
         'inicio <= fin');

     END-PROC TEST_BuildExecution;

      * ========================================================================
      * TEST 3: GLBLN_json_BuildCuentas
      * ========================================================================
      * Casos:
      *   3a. Construye array de cuentas correctamente
      *   3b. Preserva datos de balance
      * ========================================================================

     P TEST_BuildCuentas...
     P                 B
     D                 PI

     D lCuentas        DS LIKEDS(dsBalanceAnalysis) DIM(999)
     D lTol            DECIMAL(18:2) INZ(1.00)

     BEGIN

       DSPLY '--- TEST: GLBLN_json_BuildCuentas ---';

       // Preparar data de prueba
       lCuentas(1).cuenta = '1100000001';
       lCuentas(1).saldoInicial = 100000.00;
       lCuentas(1).debitosHistoricos = 50000.00;
       lCuentas(1).creditosHistoricos = 30000.00;
       lCuentas(1).saldoAnterior = 120000.00;
       lCuentas(1).saldoFinal = 120000.00;
       lCuentas(1).diferenciaNeta = 0;
       lCuentas(1).diferenciaAbsoluta = 0;
       lCuentas(1).excedeTolerancia = *OFF;

       // Test 3a: Array construido
       gTestsTotal += 1;

       dsCuentas = GLBLN_json_BuildCuentas(lCuentas, 1, lTol);

       IF dsCuentas.dsError.errorStatus = 'S' AND
          dsCuentas.rowCount = 1;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildCuentas 3a: Array construido', gTestResult,
         'rowCount=' + %CHAR(dsCuentas.rowCount));

       // Test 3b: Datos preservados
       gTestsTotal += 1;

       IF dsCuentas.cuentas(1).cuentaContable = '1100000001' AND
          dsCuentas.cuentas(1).diferenciaNeta = 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildCuentas 3b: Datos preservados', gTestResult,
         'cuenta=' + dsCuentas.cuentas(1).cuentaContable);

     END-PROC TEST_BuildCuentas;

      * ========================================================================
      * TEST 4: GLBLN_json_BuildControlTotales
      * ========================================================================
      * Casos:
      *   4a. Totales asignados correctamente
      *   4b. Sumatorias correctas
      * ========================================================================

     P TEST_BuildControlTotales...
     P                 B
     D                 PI

     BEGIN

       DSPLY '--- TEST: GLBLN_json_BuildControlTotales ---';

       // Test 4a: Totales asignados
       gTestsTotal += 1;

       dsControlTotales = GLBLN_json_BuildControlTotales(
         150,    // pTotalCuentas
         134,    // pTotalConciliadas
         16,     // pTotalConDiferencia
         12455000.25,  // pSumatoriaSaldoFuente
         12454980.75,  // pSumatoriaConciliado
         19.50   // pSumatoriaDiferencia
       );

       IF dsControlTotales.dsError.errorStatus = 'S' AND
          dsControlTotales.totalCuentasProcesadas = 150;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildControlTotales 4a: Totales asignados', gTestResult,
         'total=' + %CHAR(dsControlTotales.totalCuentasProcesadas));

       // Test 4b: Diferencia neta correcta
       gTestsTotal += 1;

       IF dsControlTotales.sumatoriaDiferenciaNeta = 19.50;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('BuildControlTotales 4b: Diferencia neta', gTestResult,
         'diferencia=' + 
         %EDITC(dsControlTotales.sumatoriaDiferenciaNeta, 'L'));

     END-PROC TEST_BuildControlTotales;

      * ========================================================================
      * TEST 5: GLBLN_json_WriteToIFS
      * ========================================================================
      * Casos:
      *   5a. Retorna estructura de resultado
      *   5b. Genera ruta válida
      * ========================================================================

     P TEST_WriteToIFS...
     P                 B
     D                 PI

     D lJsonPayload    VARCHAR(32767) INZ('{"test":"data"}')
     D lIdExec         CHAR(21) INZ('20260609_120000_001')

     BEGIN

       DSPLY '--- TEST: GLBLN_json_WriteToIFS ---';

       // Test 5a: Estructura de resultado
       gTestsTotal += 1;

       dsResultWrite = GLBLN_json_WriteToIFS(lIdExec, lJsonPayload);

       IF dsResultWrite.dsError.errorStatus = 'S' AND
          dsResultWrite.statusEscritura = 'SUCCESS';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('WriteToIFS 5a: Estructura resultante', gTestResult,
         'status=' + dsResultWrite.statusEscritura);

       // Test 5b: Ruta válida generada
       gTestsTotal += 1;

       IF %TRIM(dsResultWrite.filePath) <> '' AND
          %SCAN(lIdExec, dsResultWrite.filePath) > 0 AND
          %SCAN('.json', dsResultWrite.filePath) > 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('WriteToIFS 5b: Ruta válida', gTestResult,
         'path=' + %TRIM(dsResultWrite.filePath));

     END-PROC TEST_WriteToIFS;

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
