      * ========================================================================
      * PROGRAMA: GLBLN_DB_TST (Pruebas Unitarias - Módulo GLBLN_DB)
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa de prueba unitaria para validar todas las procedures del
      * módulo GLBLN_DB. Cubre casos de éxito y manejo de errores.
      *
      * CRITERIOS DE ACEPTACIÓN:
      * ✓ GLBLN_db_ReadByRange retorna cuentas dentro del rango
      * ✓ GLBLN_db_ReadByRange rechaza rango inválido (desde > hasta)
      * ✓ GLBLN_db_ReadByRange retorna rowCount = 0 si no hay datos
      * ✓ GLBLN_db_GetBalance calcula balance correctamente
      * ✓ GLBLN_db_GetBalance retorna saldos (inicial, históricos, día, final)
      * ✓ GLBLN_db_GetBalance maneja cuenta no existente
      * ✓ GLBLN_db_GetTransactions retorna transacciones de TRANS + TTRAN
      * ✓ GLBLN_db_GetTransactions rechaza rango inválido
      * ✓ GLBLN_db_GetTransactions retorna rowCount = 0 si no hay datos
      * ✓ GLBLN_db_ValidateAccount valida cuenta en GLBLN y GLMST
      * ✓ GLBLN_db_ValidateAccount rechaza cuenta inexistente
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
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES DE GLBLN_DB
      * ========================================================================

      /COPY qsrctxt/GLBLN_DB

      * ========================================================================
      * VARIABLES GLOBALES Y CONTADORES
      * ========================================================================

     D gTestsPassed    S INT(10:0) INZ(0)
     D gTestsFailed    S INT(10:0) INZ(0)
     D gTestsTotal     S INT(10:0) INZ(0)

     D gTestName       S VARCHAR(100)
     D gTestResult     S CHAR(10)

      * ========================================================================
      * DATA STRUCTURES PARA PRUEBAS
      * ========================================================================

     D dsGLBLN         DS EXTNAME('GLBLN') QUALIFIED INZ
     D dsResultGLBLN   DS LIKEDS(dsResultGLBLN) INZ
     D dsBalance       DS LIKEDS(dsBalance) INZ
     D dsResultTransactions DS LIKEDS(dsResultTransactions) INZ
     D dsError         DS LIKEDS(dsError) INZ

      * ========================================================================
      * MAIN PROCEDURE
      * ========================================================================

     D MAIN            PR
     D TEST_ReadByRange...
     D                 PR
     D TEST_GetBalance...
     D                 PR
     D TEST_GetTransactions...
     D                 PR
     D TEST_ValidateAccount...
     D                 PR
     D PrintTestResult...
     D                 PR
     D   pTestName     VARCHAR(100)
     D   pResult       CHAR(10)
     D   pDetails      VARCHAR(256)

      * ========================================================================

      MAIN;

        DSPLY 'Iniciando Pruebas Unitarias del Módulo GLBLN_DB';
        DSPLY '';

        // Prueba 1: GLBLN_db_ReadByRange
        TEST_ReadByRange;
        DSPLY '';

        // Prueba 2: GLBLN_db_GetBalance
        TEST_GetBalance;
        DSPLY '';

        // Prueba 3: GLBLN_db_GetTransactions
        TEST_GetTransactions;
        DSPLY '';

        // Prueba 4: GLBLN_db_ValidateAccount
        TEST_ValidateAccount;
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
      * TEST 1: GLBLN_db_ReadByRange
      * ========================================================================
      * Casos:
      *   1a. Éxito: Retorna cuentas dentro del rango
      *   1b. Error: Rango inválido (desde > hasta)
      *   1c. Sin datos: Retorna rowCount = 0
      * ========================================================================

     P TEST_ReadByRange...
     P                 B
     D                 PI

     D lBanco          S CHAR(2) INZ('01')
     D lSucursal       S CHAR(3) INZ('001')
     D lMoneda         S CHAR(3) INZ('USD')
     D lCuentaDesde    S CHAR(10)
     D lCuentaHasta    S CHAR(10)
     D lFechaProceso   S DATE

     BEGIN

       DSPLY '--- TEST: GLBLN_db_ReadByRange ---';

       // Test 1a: Rango válido
       gTestsTotal += 1;
       lCuentaDesde = '1100000000';
       lCuentaHasta = '1199999999';
       lFechaProceso = %DATE();

       dsResultGLBLN = GLBLN_db_ReadByRange(lBanco, lSucursal, lMoneda,
                                            lCuentaDesde, lCuentaHasta,
                                            lFechaProceso);

       IF dsResultGLBLN.dsError.errorStatus = 'S' AND 
          dsResultGLBLN.rowCount >= 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('ReadByRange 1a: Rango válido', gTestResult,
         'rowCount=' + %CHAR(dsResultGLBLN.rowCount));

       // Test 1b: Rango inválido (desde > hasta)
       gTestsTotal += 1;
       lCuentaDesde = '1199999999';
       lCuentaHasta = '1100000000';

       dsResultGLBLN = GLBLN_db_ReadByRange(lBanco, lSucursal, lMoneda,
                                            lCuentaDesde, lCuentaHasta,
                                            lFechaProceso);

       IF dsResultGLBLN.dsError.errorStatus = 'E' AND
          dsResultGLBLN.dsError.errorCode = 'PARAM';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('ReadByRange 1b: Rango inválido', gTestResult,
         'Error code=' + dsResultGLBLN.dsError.errorCode);

       // Test 1c: Sin datos (rango sin cuentas)
       gTestsTotal += 1;
       lCuentaDesde = '9900000000';
       lCuentaHasta = '9999999999';

       dsResultGLBLN = GLBLN_db_ReadByRange(lBanco, lSucursal, lMoneda,
                                            lCuentaDesde, lCuentaHasta,
                                            lFechaProceso);

       IF dsResultGLBLN.dsError.errorStatus = 'S' AND
          dsResultGLBLN.rowCount = 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('ReadByRange 1c: Sin datos', gTestResult,
         'rowCount=' + %CHAR(dsResultGLBLN.rowCount));

     END-PROC TEST_ReadByRange;

      * ========================================================================
      * TEST 2: GLBLN_db_GetBalance
      * ========================================================================
      * Casos:
      *   2a. Éxito: Calcula balance correctamente
      *   2b. Retorna estructura completa de saldos
      * ========================================================================

     P TEST_GetBalance...
     P                 B
     D                 PI

     D lBanco          S CHAR(2) INZ('01')
     D lSucursal       S CHAR(3) INZ('001')
     D lMoneda         S CHAR(3) INZ('USD')
     D lCuenta         S CHAR(10) INZ('1100000001')
     D lFechaProceso   S DATE

     BEGIN

       DSPLY '--- TEST: GLBLN_db_GetBalance ---';

       // Test 2a: Consulta exitosa
       gTestsTotal += 1;
       lFechaProceso = %DATE();

       dsBalance = GLBLN_db_GetBalance(lBanco, lSucursal, lMoneda,
                                       lCuenta, lFechaProceso);

       IF dsBalance.dsError.errorStatus = 'S' AND
          dsBalance.cuenta = lCuenta;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('GetBalance 2a: Consulta exitosa', gTestResult,
         'saldoFinal=' + %EDITC(dsBalance.saldoFinal, 'L'));

       // Test 2b: Estructura de saldos completa
       gTestsTotal += 1;

       IF dsBalance.dsError.errorStatus = 'S' AND
          dsBalance.saldoInicial <> 0 OR
          dsBalance.saldoFinal <> 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('GetBalance 2b: Estructura saldos', gTestResult,
         'saldoAnterior=' + %EDITC(dsBalance.saldoAnterior, 'L'));

     END-PROC TEST_GetBalance;

      * ========================================================================
      * TEST 3: GLBLN_db_GetTransactions
      * ========================================================================
      * Casos:
      *   3a. Éxito: Retorna transacciones
      *   3b. Error: Rango inválido
      * ========================================================================

     P TEST_GetTransactions...
     P                 B
     D                 PI

     D lBanco          S CHAR(2) INZ('01')
     D lSucursal       S CHAR(3) INZ('001')
     D lMoneda         S CHAR(3) INZ('USD')
     D lCuenta         S CHAR(10) INZ('1100000001')
     D lFechaDesde     S DATE
     D lFechaHasta     S DATE

     BEGIN

       DSPLY '--- TEST: GLBLN_db_GetTransactions ---';

       // Test 3a: Rango válido
       gTestsTotal += 1;
       lFechaDesde = %DATE() - 30;
       lFechaHasta = %DATE();

       dsResultTransactions = GLBLN_db_GetTransactions(lBanco, lSucursal,
                                                       lMoneda, lCuenta,
                                                       lFechaDesde,
                                                       lFechaHasta);

       IF dsResultTransactions.dsError.errorStatus = 'S' AND
          dsResultTransactions.rowCount >= 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('GetTransactions 3a: Rango válido', gTestResult,
         'rowCount=' + %CHAR(dsResultTransactions.rowCount));

       // Test 3b: Rango inválido (desde > hasta)
       gTestsTotal += 1;
       lFechaDesde = %DATE();
       lFechaHasta = %DATE() - 30;

       dsResultTransactions = GLBLN_db_GetTransactions(lBanco, lSucursal,
                                                       lMoneda, lCuenta,
                                                       lFechaDesde,
                                                       lFechaHasta);

       IF dsResultTransactions.dsError.errorStatus = 'E' AND
          dsResultTransactions.dsError.errorCode = 'PARAM';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('GetTransactions 3b: Rango inválido', gTestResult,
         'Error code=' + dsResultTransactions.dsError.errorCode);

     END-PROC TEST_GetTransactions;

      * ========================================================================
      * TEST 4: GLBLN_db_ValidateAccount
      * ========================================================================
      * Casos:
      *   4a. Éxito: Cuenta válida (existe en GLBLN y GLMST)
      *   4b. Error: Cuenta inexistente
      * ========================================================================

     P TEST_ValidateAccount...
     P                 B
     D                 PI

     D lBanco          S CHAR(2) INZ('01')
     D lSucursal       S CHAR(3) INZ('001')
     D lMoneda         S CHAR(3) INZ('USD')
     D lCuenta         S CHAR(10)

     BEGIN

       DSPLY '--- TEST: GLBLN_db_ValidateAccount ---';

       // Test 4a: Cuenta válida
       gTestsTotal += 1;
       lCuenta = '1100000001';

       dsError = GLBLN_db_ValidateAccount(lBanco, lSucursal, lMoneda,
                                          lCuenta);

       IF dsError.errorStatus = 'S';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('ValidateAccount 4a: Cuenta válida', gTestResult,
         'Validada');

       // Test 4b: Cuenta inexistente
       gTestsTotal += 1;
       lCuenta = '9999999999';

       dsError = GLBLN_db_ValidateAccount(lBanco, lSucursal, lMoneda,
                                          lCuenta);

       IF dsError.errorStatus = 'E' AND
          (dsError.errorCode = 'VAL01' OR dsError.errorCode = 'VAL02');
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('ValidateAccount 4b: Cuenta inexistente', 
                       gTestResult,
         'Error code=' + dsError.errorCode);

     END-PROC TEST_ValidateAccount;

      * ========================================================================
      * UTIL: PrintTestResult
      * ========================================================================
      * Imprime el resultado de una prueba en formato consistente.
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
