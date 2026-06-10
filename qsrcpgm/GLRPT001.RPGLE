      * ========================================================================
      * PROGRAMA PRINCIPAL: GLRPT001
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa SQLRPGLE que orquesta el proceso completo de conciliación de
      * cuentas mayores. Integra todos los módulos (GLBLN_DB, GLBLN_BIZ,
      * GLBLN_JSON) y servicios (SRV_AUDIT) en un flujo unificado.
      *
      * FLUJO DE PROCESO:
      * 1. Recibir parámetros de ejecución
      * 2. Validar parámetros y autorización
      * 3. Generar ID de ejecución único
      * 4. Registrar inicio en auditoría (SRV_AUDIT_LogStart)
      * 5. Consultar cuentas mayores por filtros (GLBLN_db_ReadByRange)
      * 6. Para cada cuenta:
      *    - Obtener balance (GLBLN_db_GetBalance)
      *    - Calcular diferencias (GLBLN_biz_CalculateBalance)
      *    - Determinar estado financiero (GLBLN_biz_DetermineFiState)
      *    - Identificar partidas en tránsito (GLBLN_biz_IdentifyTransit)
      *    - Registrar incidentes si aplica (SRV_AUDIT_LogIncident)
      * 7. Construir estructura JSON (GLBLN_JSON_Build*)
      * 8. Escribir archivo JSON en IFS (GLBLN_json_WriteToIFS)
      * 9. Registrar fin de ejecución (SRV_AUDIT_LogEnd)
      * 10. Mostrar resumen de resultados
      *
      * PARÁMETROS DE ENTRADA:
      *   Banco:           CHAR(2)     - Código de banco
      *   Sucursal:        CHAR(3)     - Código de sucursal
      *   Moneda:          CHAR(3)     - Código de moneda
      *   Cuenta Desde:    CHAR(10)    - Rango inicial de cuentas
      *   Cuenta Hasta:    CHAR(10)    - Rango final de cuentas
      *   Fecha Proceso:   CHAR(8)     - YYYYMMDD (fecha de corte)
      *   Modo:            CHAR(1)     - T=Test, P=Producción
      *
      * SALIDA:
      *   - Archivo JSON en IFS: /home/EARAUJOL/builds/TallerGitHub/reportes
      *   - Registros en CONCEXC/CONCERR para auditoría
      *   - Resumen en pantalla
      *
      * EQUIPO:        Taller GitHub Copilot
      * FECHA:         2026-06-09
      * PROYECTO:      Conciliación GLBLN - Programa Principal
      * VERSIÓN:       1.0
      * ========================================================================

     H DFTACTGRP(*YES)
     H SQLMODE(*DB2)
     H BNDDIR('QSys.Lib/EARAUJOL1.Lib')
     H OPTION(*SRCSTMT : *NODEBUGIO)

      * ========================================================================
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES
      * ========================================================================

      /COPY qsrctxt/GLBLN_JSON
      /COPY qsrctxt/SRV_AUDIT

      * ========================================================================
      * CONSTANTS
      * ========================================================================

     D CONST_TOLERANCIA S DECIMAL(18:2) INZ(1.00)
     D CONST_MAX_CUENTAS S INT(10:0) INZ(999)

      * ========================================================================
      * VARIABLES GLOBALES
      * ========================================================================

     D gIdEjecucion    S CHAR(21)
     D gBanco          S CHAR(2)
     D gSucursal       S CHAR(3)
     D gMoneda         S CHAR(3)
     D gCuentaDesde    S CHAR(10)
     D gCuentaHasta    S CHAR(10)
     D gFechaProceso   S DATE
     D gModo           S CHAR(1)
     D gFechaInicio    S TIMESTAMP
     D gFechaFin       S TIMESTAMP

      * Contadores de ejecución
     D gTotalCuentas   S INT(10:0) INZ(0)
     D gConciliadas    S INT(10:0) INZ(0)
     D gConDiferencia  S INT(10:0) INZ(0)
     D gErrores        S INT(10:0) INZ(0)
     D gSumatoriaDif   S DECIMAL(18:2) INZ(0)

      * Estado final
     D gEstadoFinal    S CHAR(20) INZ('FINALIZADO')

      * Data structures de retorno
     D dsCuentas       DS LIKEDS(dsBalanceAnalysis) DIM(999)
     D dsBalance       DS LIKEDS(dsBalance)
     D dsBalanceAnalysis DS LIKEDS(dsBalanceAnalysis)
     D dsFinState      DS LIKEDS(dsFinancialState)
     D dsTransitResult DS LIKEDS(dsResultTransit)

     D dsMetadata      DS LIKEDS(dsJsonMetadata)
     D dsExecution     DS LIKEDS(dsJsonExecution)
     D dsCuentasJson   DS LIKEDS(dsJsonResultCuentas)
     D dsControlTotales DS LIKEDS(dsJsonControlTotales)
     D dsResultWrite   DS LIKEDS(dsJsonResultWrite)

     D dsLogStart      DS LIKEDS(dsAuditResult)
     D dsLogEnd        DS LIKEDS(dsAuditResult)
     D dsLogIncident   DS LIKEDS(dsAuditResult)

      * ========================================================================
      * PROCEDURES
      * ========================================================================

     D ProcessAccount  PR
     D   pAccount      LIKEDS(dsBalance)

     D GenerateExecutionId...
     D                 PR CHAR(21)

     D ValidateParameters...
     D                 PR IND

     D DisplaySummary  PR

      * ========================================================================
      * MAIN PROCEDURE
      * ========================================================================

     C     *ENTRY        PLIST
     C                   PARM                    gBanco
     C                   PARM                    gSucursal
     C                   PARM                    gMoneda
     C                   PARM                    gCuentaDesde
     C                   PARM                    gCuentaHasta
     C                   PARM                    gFechaProceso
     C                   PARM                    gModo

      * Validar parámetros
      IF NOT ValidateParameters();
        DSPLY 'ERROR: Parámetros inválidos';
        *INLR = *ON;
        RETURN;
      ENDIF;

      * Generar ID de ejecución único
      gIdEjecucion = GenerateExecutionId();
      gFechaInicio = %NOW();

      DSPLY 'Iniciando proceso de conciliación GLBLN';
      DSPLY 'ID Ejecución: ' + gIdEjecucion;
      DSPLY 'Banco: ' + gBanco + ' Sucursal: ' + gSucursal + 
            ' Moneda: ' + gMoneda;
      DSPLY 'Rango cuentas: ' + gCuentaDesde + ' a ' + gCuentaHasta;

      * ===== PASO 1: REGISTRAR INICIO EN AUDITORÍA =====
      dsLogStart = SRV_AUDIT_LogStart(
        gIdEjecucion,
        gBanco,
        gSucursal,
        gMoneda,
        gCuentaDesde,
        gCuentaHasta,
        gFechaProceso,
        'USER',
        'GLRPT001',
        'EARAUJOL1'
      );

      IF dsLogStart.dsError.errorStatus <> 'S';
        DSPLY 'ERROR: No se pudo registrar inicio de ejecución';
        gEstadoFinal = 'ERROR';
      ENDIF;

      * ===== PASO 2: CONSULTAR CUENTAS MAYORES =====
      IF gEstadoFinal = 'FINALIZADO';

        // Leer cuentas por rango
        GLBLN_db_ReadByRange(gBanco, gSucursal, gMoneda,
                             gCuentaDesde, gCuentaHasta,
                             dsCuentas, gTotalCuentas);

        IF gTotalCuentas = 0;
          DSPLY 'ADVERTENCIA: No se encontraron cuentas en el rango';
        ENDIF;

        * ===== PASO 3: PROCESAR CADA CUENTA =====
        FOR gIdx = 1 BY 1 UNTIL gIdx > gTotalCuentas;

          // Obtener balance de la cuenta
          dsBalance = GLBLN_db_GetBalance(
            gBanco,
            gSucursal,
            gMoneda,
            dsCuentas(gIdx).cuenta,
            gFechaProceso
          );

          // Procesar cuenta
          ProcessAccount(dsBalance);

        ENDFOR;

      ENDIF;

      * ===== PASO 4: CONSTRUIR ESTRUCTURA JSON =====
      IF gEstadoFinal = 'FINALIZADO';

        // Metadata
        dsMetadata = GLBLN_json_BuildMetadata('QA ');

        // Execution info
        dsExecution = GLBLN_json_BuildExecution(
          gIdEjecucion,
          gFechaProceso,
          'USER',
          'GLRPT001',
          'EARAUJOL1',
          gEstadoFinal,
          gFechaInicio
        );

        // Control totales
        dsControlTotales = GLBLN_json_BuildControlTotales(
          gTotalCuentas,
          gConciliadas,
          gConDiferencia,
          0,                    // sumatoriaSaldoFuente (TODO)
          0,                    // sumatoriaConciliado (TODO)
          gSumatoriaDif
        );

        // TODO: Construir JSON completo y escribir en IFS
        // dsResultWrite = GLBLN_json_WriteToIFS(gIdEjecucion, lJsonPayload);

      ENDIF;

      * ===== PASO 5: REGISTRAR FIN EN AUDITORÍA =====
      dsLogEnd = SRV_AUDIT_LogEnd(
        gIdEjecucion,
        gTotalCuentas,
        gConciliadas,
        gConDiferencia,
        gErrores,
        gEstadoFinal
      );

      IF dsLogEnd.dsError.errorStatus <> 'S';
        DSPLY 'ADVERTENCIA: Error al registrar fin de ejecución';
      ENDIF;

      * ===== PASO 6: MOSTRAR RESUMEN =====
      DisplaySummary();

      *INLR = *ON;
      RETURN;

      * ========================================================================
      * PROCEDURE: ProcessAccount
      * ========================================================================
      * Procesa una cuenta individual: calcula balance, estado, partidas.
      *
     P ProcessAccount  B
     D                 PI
     D   pAccount      LIKEDS(dsBalance)

     D lBalanceAnalysis DS LIKEDS(dsBalanceAnalysis)
     D lFinState       DS LIKEDS(dsFinancialState)
     D lTransitCount   INT(10:0)
     D lIdx            INT(10:0)

     BEGIN

       gTotalCuentas += 1;

       TRY;

         * Calcular diferencias
         lBalanceAnalysis = GLBLN_biz_CalculateBalance(
           pAccount,
           CONST_TOLERANCIA
         );

         * Identificar partidas en tránsito
         lTransitCount = 0;
         lFinState = GLBLN_biz_DetermineFiState(
           lBalanceAnalysis,
           lTransitCount,
           *OFF
         );

         * Contar según estado
         EVALUATE lFinState.codigo;
           WHEN 'CONCILIADA';
             gConciliadas += 1;

           WHEN 'PARCIAL';
             gConDiferencia += 1;
             gSumatoriaDif += %ABS(lBalanceAnalysis.diferenciaNeta);

           WHEN 'DIFERENCIA';
             gConDiferencia += 1;
             gSumatoriaDif += %ABS(lBalanceAnalysis.diferenciaNeta);

             // Registrar incidente
             dsLogIncident = SRV_AUDIT_LogIncident(
               gIdEjecucion,
               'DIFF-' + %TRIM(pAccount.cuenta),
               'VALIDACION',
               lFinState.severidad,
               pAccount.cuenta,
               'Diferencia: ' + %EDITC(lBalanceAnalysis.diferenciaNeta, 'L')
             );

           WHEN 'ERROR';
             gErrores += 1;
             gEstadoFinal = 'PARCIAL';

         END-EVALUATE;

       CATCH;

         gErrores += 1;
         gEstadoFinal = 'PARCIAL';

         dsLogIncident = SRV_AUDIT_LogIncident(
           gIdEjecucion,
           'ERR-' + %TRIM(pAccount.cuenta),
           'ERROR',
           'ALTA',
           pAccount.cuenta,
           'Error procesando cuenta'
         );

       ENDTRY;

     END-PROC ProcessAccount;

      * ========================================================================
      * PROCEDURE: GenerateExecutionId
      * ========================================================================
      * Genera ID único: YYYYMMDD_HHMMSS_seq
      *
     P GenerateExecutionId...
     P                 B
     D                 PI CHAR(21)

     D lNow            S TIMESTAMP
     D lDatePart       S CHAR(8)
     D lTimePart       S CHAR(6)
     D lSeq            S CHAR(3) INZ('001')
     D lIdExec         S CHAR(21)

     BEGIN

       lNow = %NOW();
       lDatePart = %CHAR(lNow : *YYYYMMDD);
       lTimePart = %CHAR(lNow : *HHMMSS);
       lIdExec = lDatePart + '_' + lTimePart + '_' + lSeq;

       RETURN lIdExec;

     END-PROC GenerateExecutionId;

      * ========================================================================
      * PROCEDURE: ValidateParameters
      * ========================================================================
      * Valida parámetros de entrada.
      *
     P ValidateParameters...
     P                 B
     D                 PI IND

     BEGIN

       * Validar banco (2 dígitos)
       IF %LEN(%TRIM(gBanco)) <> 2;
         RETURN *OFF;
       ENDIF;

       * Validar sucursal (3 dígitos)
       IF %LEN(%TRIM(gSucursal)) <> 3;
         RETURN *OFF;
       ENDIF;

       * Validar moneda (3 caracteres)
       IF %LEN(%TRIM(gMoneda)) <> 3;
         RETURN *OFF;
       ENDIF;

       * Validar rango de cuentas
       IF gCuentaDesde > gCuentaHasta;
         RETURN *OFF;
       ENDIF;

       * Validar modo (T o P)
       IF gModo <> 'T' AND gModo <> 'P';
         RETURN *OFF;
       ENDIF;

       RETURN *ON;

     END-PROC ValidateParameters;

      * ========================================================================
      * PROCEDURE: DisplaySummary
      * ========================================================================
      * Muestra resumen de ejecución en pantalla.
      *
     P DisplaySummary  B
     D                 PI

     BEGIN

       gFechaFin = %NOW();

       DSPLY '';
       DSPLY '========================================';
       DSPLY 'RESUMEN DE EJECUCIÓN';
       DSPLY '========================================';
       DSPLY 'ID Ejecución:          ' + gIdEjecucion;
       DSPLY 'Estado Final:          ' + gEstadoFinal;
       DSPLY '';
       DSPLY 'Total de Cuentas:      ' + %CHAR(gTotalCuentas);
       DSPLY 'Cuentas Conciliadas:   ' + %CHAR(gConciliadas);
       DSPLY 'Cuentas con Diferencia: ' + %CHAR(gConDiferencia);
       DSPLY 'Errores Encontrados:   ' + %CHAR(gErrores);
       DSPLY '';
       DSPLY 'Sumatoria de Diferencias: ' +
             %EDITC(gSumatoriaDif, 'L');
       DSPLY '';
       DSPLY 'Hora Inicio:           ' + %CHAR(gFechaInicio);
       DSPLY 'Hora Fin:              ' + %CHAR(gFechaFin);
       DSPLY '========================================';
       DSPLY '';

       IF gEstadoFinal = 'FINALIZADO';
         DSPLY '✓ PROCESO COMPLETADO EXITOSAMENTE';
       ELSE;
         DSPLY '⚠ PROCESO COMPLETADO CON ADVERTENCIAS';
       ENDIF;

     END-PROC DisplaySummary;
