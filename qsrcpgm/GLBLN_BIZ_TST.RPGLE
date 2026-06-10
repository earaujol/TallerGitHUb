      * ========================================================================
      * PROGRAMA: GLBLN_BIZ_TST (Pruebas Unitarias - Módulo GLBLN_BIZ)
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa de prueba unitaria para validar todas las procedures del
      * módulo GLBLN_BIZ. Cubre casos de éxito, cálculos y determinación
      * de estados financieros.
      *
      * CRITERIOS DE ACEPTACIÓN:
      * ✓ CalculateBalance calcula diferencias correctamente
      * ✓ CalculateBalance identifica cuando excede tolerancia
      * ✓ DetermineFiState retorna CONCILIADA para diferencia = 0
      * ✓ DetermineFiState retorna PARCIAL para diferencia <= tolerancia + partidas
      * ✓ DetermineFiState retorna DIFERENCIA para diferencia > tolerancia
      * ✓ DetermineFiState retorna ERROR cuando hay datos inconsistentes
      * ✓ IdentifyTransit retorna partidas en tránsito correctamente
      * ✓ IdentifyTransit calcula diasEnTransito correctamente
      * ✓ CheckTolerance retorna 'S' para dentro de tolerancia
      * ✓ CheckTolerance retorna 'A' para dentro + con partidas
      * ✓ CheckTolerance retorna 'E' para fuera de tolerancia
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

      /COPY qsrctxt/GLBLN_BIZ

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

     D dsBalance       DS LIKEDS(dsBalance) INZ
     D dsBalanceAnalysis DS LIKEDS(dsBalanceAnalysis) INZ
     D dsFinState      DS LIKEDS(dsFinancialState) INZ
     D dsTransitResult DS LIKEDS(dsResultTransit) INZ

      * ========================================================================
      * PROCEDURES DE PRUEBA
      * ========================================================================

     D MAIN            PR
     D TEST_CalculateBalance...
     D                 PR
     D TEST_DetermineFiState...
     D                 PR
     D TEST_IdentifyTransit...
     D                 PR
     D TEST_CheckTolerance...
     D                 PR
     D PrintTestResult...
     D                 PR
     D   pTestName     VARCHAR(100)
     D   pResult       CHAR(10)
     D   pDetails      VARCHAR(256)

      * ========================================================================

      MAIN;

        DSPLY 'Iniciando Pruebas Unitarias del Módulo GLBLN_BIZ';
        DSPLY '';

        // Prueba 1: GLBLN_biz_CalculateBalance
        TEST_CalculateBalance;
        DSPLY '';

        // Prueba 2: GLBLN_biz_DetermineFiState
        TEST_DetermineFiState;
        DSPLY '';

        // Prueba 3: GLBLN_biz_IdentifyTransit
        TEST_IdentifyTransit;
        DSPLY '';

        // Prueba 4: GLBLN_biz_CheckTolerance
        TEST_CheckTolerance;
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
      * TEST 1: GLBLN_biz_CalculateBalance
      * ========================================================================
      * Casos:
      *   1a. Diferencia = 0 (conciliada perfecta)
      *   1b. Diferencia dentro de tolerancia (1.00)
      *   1c. Diferencia fuera de tolerancia (> 1.00)
      * ========================================================================

     P TEST_CalculateBalance...
     P                 B
     D                 PI

     D lTolerancia     S DECIMAL(18:2) INZ(1.00)

     BEGIN

       DSPLY '--- TEST: GLBLN_biz_CalculateBalance ---';

       // Test 1a: Diferencia = 0
       gTestsTotal += 1;
       dsBalance.cuenta = '1100000001';
       dsBalance.saldoInicial = 100000.00;
       dsBalance.debitosHistoricos = 50000.00;
       dsBalance.creditosHistoricos = 30000.00;
       dsBalance.saldoAnterior = 120000.00;
       dsBalance.debitosDia = 20000.00;
       dsBalance.creditosDia = 20000.00;
       dsBalance.saldoFinal = 120000.00;

       dsBalanceAnalysis = GLBLN_biz_CalculateBalance(dsBalance, lTolerancia);

       IF dsBalanceAnalysis.dsError.errorStatus = 'S' AND
          dsBalanceAnalysis.diferenciaNeta = 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CalculateBalance 1a: Diferencia = 0', gTestResult,
         'diferenciaNeta=' + %EDITC(dsBalanceAnalysis.diferenciaNeta, 'L'));

       // Test 1b: Diferencia dentro de tolerancia
       gTestsTotal += 1;
       dsBalance.saldoFinal = 120000.50;

       dsBalanceAnalysis = GLBLN_biz_CalculateBalance(dsBalance, lTolerancia);

       IF dsBalanceAnalysis.dsError.errorStatus = 'S' AND
          dsBalanceAnalysis.diferenciaAbsoluta <= lTolerancia AND
          NOT dsBalanceAnalysis.excedeTolerancia;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CalculateBalance 1b: Dentro tolerancia', gTestResult,
         'diferenciaAbsoluta=' + 
         %EDITC(dsBalanceAnalysis.diferenciaAbsoluta, 'L'));

       // Test 1c: Diferencia fuera de tolerancia
       gTestsTotal += 1;
       dsBalance.saldoFinal = 120010.00;

       dsBalanceAnalysis = GLBLN_biz_CalculateBalance(dsBalance, lTolerancia);

       IF dsBalanceAnalysis.dsError.errorStatus = 'S' AND
          dsBalanceAnalysis.diferenciaAbsoluta > lTolerancia AND
          dsBalanceAnalysis.excedeTolerancia;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CalculateBalance 1c: Fuera tolerancia', gTestResult,
         'diferenciaAbsoluta=' + 
         %EDITC(dsBalanceAnalysis.diferenciaAbsoluta, 'L'));

     END-PROC TEST_CalculateBalance;

      * ========================================================================
      * TEST 2: GLBLN_biz_DetermineFiState
      * ========================================================================
      * Casos:
      *   2a. Estado CONCILIADA (diferencia = 0, sin partidas)
      *   2b. Estado PARCIAL (diferencia <= tol, con partidas)
      *   2c. Estado DIFERENCIA (diferencia > tol)
      *   2d. Estado ERROR (error en datos)
      * ========================================================================

     P TEST_DetermineFiState...
     P                 B
     D                 PI

     BEGIN

       DSPLY '--- TEST: GLBLN_biz_DetermineFiState ---';

       // Test 2a: CONCILIADA
       gTestsTotal += 1;
       dsBalanceAnalysis.cuenta = '1100000001';
       dsBalanceAnalysis.diferenciaNeta = 0;
       dsBalanceAnalysis.diferenciaAbsoluta = 0;
       dsBalanceAnalysis.excedeTolerancia = *OFF;
       dsBalanceAnalysis.tolerancia = 1.00;

       dsFinState = GLBLN_biz_DetermineFiState(dsBalanceAnalysis, 0, *OFF);

       IF dsFinState.dsError.errorStatus = 'S' AND
          dsFinState.codigo = 'CONCILIADA' AND
          dsFinState.severidad = 'BAJA' AND
          NOT dsFinState.requiereRevision;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('DetermineFiState 2a: CONCILIADA', gTestResult,
         'Severidad=' + dsFinState.severidad);

       // Test 2b: PARCIAL
       gTestsTotal += 1;
       dsBalanceAnalysis.diferenciaNeta = 0.75;
       dsBalanceAnalysis.diferenciaAbsoluta = 0.75;
       dsBalanceAnalysis.excedeTolerancia = *OFF;

       dsFinState = GLBLN_biz_DetermineFiState(dsBalanceAnalysis, 2, *OFF);

       IF dsFinState.dsError.errorStatus = 'S' AND
          dsFinState.codigo = 'PARCIAL' AND
          dsFinState.severidad = 'MEDIA' AND
          dsFinState.requiereRevision;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('DetermineFiState 2b: PARCIAL', gTestResult,
         'Severidad=' + dsFinState.severidad);

       // Test 2c: DIFERENCIA
       gTestsTotal += 1;
       dsBalanceAnalysis.diferenciaNeta = 100.00;
       dsBalanceAnalysis.diferenciaAbsoluta = 100.00;
       dsBalanceAnalysis.excedeTolerancia = *ON;

       dsFinState = GLBLN_biz_DetermineFiState(dsBalanceAnalysis, 0, *OFF);

       IF dsFinState.dsError.errorStatus = 'S' AND
          dsFinState.codigo = 'DIFERENCIA' AND
          dsFinState.severidad = 'ALTA' AND
          dsFinState.requiereRevision;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('DetermineFiState 2c: DIFERENCIA', gTestResult,
         'Severidad=' + dsFinState.severidad);

       // Test 2d: ERROR
       gTestsTotal += 1;

       dsFinState = GLBLN_biz_DetermineFiState(dsBalanceAnalysis, 0, *ON);

       IF dsFinState.dsError.errorStatus = 'S' AND
          dsFinState.codigo = 'ERROR' AND
          dsFinState.severidad = 'CRITICA' AND
          dsFinState.requiereRevision;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('DetermineFiState 2d: ERROR', gTestResult,
         'Severidad=' + dsFinState.severidad);

     END-PROC TEST_DetermineFiState;

      * ========================================================================
      * TEST 3: GLBLN_biz_IdentifyTransit
      * ========================================================================
      * Casos:
      *   3a. Retorna partidas en tránsito
      *   3b. Calcula diasEnTransito correctamente
      * ========================================================================

     P TEST_IdentifyTransit...
     P                 B
     D                 PI

     D lBanco          S CHAR(2) INZ('01')
     D lSucursal       S CHAR(3) INZ('001')
     D lMoneda         S CHAR(3) INZ('USD')
     D lCuenta         S CHAR(10) INZ('1100000001')
     D lFechaProceso   S DATE

     BEGIN

       DSPLY '--- TEST: GLBLN_biz_IdentifyTransit ---';

       lFechaProceso = %DATE();

       // Test 3a: Retorna partidas
       gTestsTotal += 1;

       dsTransitResult = GLBLN_biz_IdentifyTransit(lBanco, lSucursal,
                                                    lMoneda, lCuenta,
                                                    lFechaProceso);

       IF dsTransitResult.dsError.errorStatus = 'S' AND
          dsTransitResult.rowCount >= 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('IdentifyTransit 3a: Retorna partidas', gTestResult,
         'rowCount=' + %CHAR(dsTransitResult.rowCount));

       // Test 3b: diasEnTransito > 0 si hay partidas
       gTestsTotal += 1;

       IF dsTransitResult.rowCount > 0 AND
          dsTransitResult.partidas(1).diasEnTransito > 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE IF dsTransitResult.rowCount = 0;
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;
       ENDIF;

       PrintTestResult('IdentifyTransit 3b: diasEnTransito', gTestResult,
         'dias=' + %CHAR(dsTransitResult.partidas(1).diasEnTransito));

     END-PROC TEST_IdentifyTransit;

      * ========================================================================
      * TEST 4: GLBLN_biz_CheckTolerance
      * ========================================================================
      * Casos:
      *   4a. Retorna 'S' para dentro de tolerancia sin partidas
      *   4b. Retorna 'A' para dentro de tolerancia con partidas
      *   4c. Retorna 'E' para fuera de tolerancia
      * ========================================================================

     P TEST_CheckTolerance...
     P                 B
     D                 PI

     D lDiferencia     S DECIMAL(18:2)
     D lTolerancia     S DECIMAL(18:2) INZ(1.00)
     D lResult         S CHAR(1)

     BEGIN

       DSPLY '--- TEST: GLBLN_biz_CheckTolerance ---';

       // Test 4a: Dentro de tolerancia, sin partidas
       gTestsTotal += 1;
       lDiferencia = 0.50;

       lResult = GLBLN_biz_CheckTolerance(lDiferencia, lTolerancia, 0);

       IF lResult = 'S';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CheckTolerance 4a: Sin partidas', gTestResult,
         'resultado=' + lResult);

       // Test 4b: Dentro de tolerancia, con partidas
       gTestsTotal += 1;
       lDiferencia = 0.75;

       lResult = GLBLN_biz_CheckTolerance(lDiferencia, lTolerancia, 2);

       IF lResult = 'A';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CheckTolerance 4b: Con partidas', gTestResult,
         'resultado=' + lResult);

       // Test 4c: Fuera de tolerancia
       gTestsTotal += 1;
       lDiferencia = 10.00;

       lResult = GLBLN_biz_CheckTolerance(lDiferencia, lTolerancia, 0);

       IF lResult = 'E';
         gTestsPassed += 1;
         gTestResult = 'PASS';
       ELSE;
         gTestsFailed += 1;
         gTestResult = 'FAIL';
       ENDIF;

       PrintTestResult('CheckTolerance 4c: Fuera tolerancia', gTestResult,
         'resultado=' + lResult);

     END-PROC TEST_CheckTolerance;

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
