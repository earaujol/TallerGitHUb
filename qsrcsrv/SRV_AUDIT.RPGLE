      * ========================================================================
      * PROGRAMA DE SERVICIO: SRV_AUDIT
      * ========================================================================
      * DESCRIPCIÓN:
      * Programa de servicio SQLRPGLE que encapsula la lógica de auditoría
      * para el proceso de conciliación de cuentas mayores.
      *
      * Responsabilidades:
      * - Registrar inicio de ejecución en tabla CONCEXC
      * - Registrar fin de ejecución y actualizaciones de contadores
      * - Registrar incidentes y errores en tabla CONCERR
      *
      * PROCEDURES EXPORTADOS:
      * - SRV_AUDIT_LogStart          → Registra inicio de ejecución
      * - SRV_AUDIT_LogEnd            → Registra fin y actualiza contadores
      * - SRV_AUDIT_LogIncident       → Registra incidente/error
      *
      * TABLAS UTILIZADAS:
      * - EARAUJOL1.CONCEXC           - Auditoría de ejecuciones
      * - EARAUJOL1.CONCERR           - Registro de incidentes
      *
      * EQUIPO:        Taller GitHub Copilot
      * FECHA:         2026-06-09
      * PROYECTO:      Conciliación GLBLN - Servicios de Auditoría
      * VERSIÓN:       1.0
      * ========================================================================

     H NOMAIN
     H SQLMODE(*DB2)
     H BNDDIR('QSys.Lib/EARAUJOL1.Lib')
     H OPTION(*SRCSTMT : *NODEBUGIO)

      * ========================================================================
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES
      * ========================================================================

      /COPY qsrctxt/SRV_AUDIT

      * ========================================================================
      * PROCEDURE 1: SRV_AUDIT_LogStart
      * ========================================================================
      * Inserta registro en CONCEXC para marcar inicio de ejecución.
      *
      * Entrada:
      *   pIdEjecucion    CHAR(21)     - ID único YYYYMMDD_HHMMSS_seq
      *   pBanco          CHAR(2)      - Código de banco
      *   pSucursal       CHAR(3)      - Código de sucursal
      *   pMoneda         CHAR(3)      - Código de moneda
      *   pCuentaDesde    CHAR(10)     - Rango desde
      *   pCuentaHasta    CHAR(10)     - Rango hasta
      *   pFechaProceso   DATE         - Fecha de corte
      *   pUsuario        CHAR(10)     - Usuario que ejecuta
      *   pPrograma       CHAR(10)     - Programa ejecutando
      *   pLibreria       CHAR(10)     - Librería de ejecución
      *
      * Salida:
      *   dsResultLog     LIKEDS       - Resultado (success/error)
      *
      * ========================================================================

     P SRV_AUDIT_LogStart...
     P                 B EXPORT
     D                 PI LIKEDS(dsAuditResult)
     D   pIdEjecucion  CHAR(21)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuentaDesde  CHAR(10)
     D   pCuentaHasta  CHAR(10)
     D   pFechaProceso DATE
     D   pUsuario      CHAR(10)
     D   pPrograma     CHAR(10)
     D   pLibreria     CHAR(10)

     D lResultLog      DS LIKEDS(dsAuditResult)
     D lError          DS LIKEDS(dsError)
     D lNow            TIMESTAMP

     BEGIN

       lNow = %NOW();
       lError.errorStatus = 'S';
       lError.errorCode = 'AUD001';
       lError.errorMsg = 'Registro de inicio insertado exitosamente';

       TRY;

         INSERT INTO EARAUJOL1.CONCEXC
         VALUES(
           pIdEjecucion,
           pBanco,
           pSucursal,
           pMoneda,
           pCuentaDesde,
           pCuentaHasta,
           pFechaProceso,
           lNow,
           NULL,
           pUsuario,
           pPrograma,
           pLibreria,
           0,
           0,
           0,
           0,
           0,
           0,
           'INICIADA',
           lNow,
           USER
         );

         lResultLog.dsError = lError;
         lResultLog.idEjecucion = pIdEjecucion;
         lResultLog.operacion = 'LogStart';
         lResultLog.statusOperacion = 'SUCCESS';
         lResultLog.timestampOperacion = lNow;

       CATCH;

         lError.errorStatus = 'E';
         lError.errorCode = 'AUD001_ERR';
         lError.errorMsg = 'Error al insertar registro de inicio en CONCEXC';

         lResultLog.dsError = lError;
         lResultLog.statusOperacion = 'ERROR';

       ENDTRY;

       RETURN lResultLog;

     END-PROC SRV_AUDIT_LogStart;

      * ========================================================================
      * PROCEDURE 2: SRV_AUDIT_LogEnd
      * ========================================================================
      * Actualiza registro en CONCEXC con fin de ejecución y contadores.
      *
      * Entrada:
      *   pIdEjecucion    CHAR(21)     - ID de ejecución
      *   pTotalCuentas   INT(10:0)    - Total de cuentas procesadas
      *   pTotalConciliadas INT(10:0) - Cuentas conciliadas
      *   pTotalConDif    INT(10:0)    - Cuentas con diferencia
      *   pTotalErrores   INT(10:0)    - Errores encontrados
      *   pEstadoFinal    CHAR(20)     - FINALIZADO, PARCIAL, ERROR
      *
      * Salida:
      *   dsResultLog     LIKEDS       - Resultado (success/error)
      *
      * ========================================================================

     P SRV_AUDIT_LogEnd...
     P                 B EXPORT
     D                 PI LIKEDS(dsAuditResult)
     D   pIdEjecucion  CHAR(21)
     D   pTotalCuentas INT(10:0)
     D   pTotalConciliadas INT(10:0)
     D   pTotalConDif  INT(10:0)
     D   pTotalErrores INT(10:0)
     D   pEstadoFinal  CHAR(20)

     D lResultLog      DS LIKEDS(dsAuditResult)
     D lError          DS LIKEDS(dsError)
     D lNow            TIMESTAMP

     BEGIN

       lNow = %NOW();
       lError.errorStatus = 'S';
       lError.errorCode = 'AUD002';
       lError.errorMsg = 'Registro de fin actualizado exitosamente';

       TRY;

         UPDATE EARAUJOL1.CONCEXC
            SET FECHA_HORA_FIN = lNow,
                TOTAL_CUENTAS_PROCESADAS = pTotalCuentas,
                TOTAL_CUENTAS_CONCILIADAS = pTotalConciliadas,
                TOTAL_CUENTAS_CON_DIFERENCIA = pTotalConDif,
                TOTAL_ERRORES = pTotalErrores,
                ESTADO_EJECUCION = pEstadoFinal,
                FECHA_ULTIMA_MODIFICACION = lNow
          WHERE ID_EJECUCION = pIdEjecucion;

         lResultLog.dsError = lError;
         lResultLog.idEjecucion = pIdEjecucion;
         lResultLog.operacion = 'LogEnd';
         lResultLog.statusOperacion = 'SUCCESS';
         lResultLog.timestampOperacion = lNow;

       CATCH;

         lError.errorStatus = 'E';
         lError.errorCode = 'AUD002_ERR';
         lError.errorMsg = 'Error al actualizar registro de fin en CONCEXC';

         lResultLog.dsError = lError;
         lResultLog.statusOperacion = 'ERROR';

       ENDTRY;

       RETURN lResultLog;

     END-PROC SRV_AUDIT_LogEnd;

      * ========================================================================
      * PROCEDURE 3: SRV_AUDIT_LogIncident
      * ========================================================================
      * Inserta registro en CONCERR para registrar incidentes/errores.
      *
      * Entrada:
      *   pIdEjecucion        CHAR(21)     - ID de ejecución (FK)
      *   pCodigoIncidente    VARCHAR(10)  - Código único del incidente
      *   pTipoIncidente      VARCHAR(20)  - VALIDACION, ERROR, ADVERTENCIA
      *   pSeveridad          VARCHAR(10)  - BAJA, MEDIA, ALTA, CRITICA
      *   pCuentaContable     CHAR(10)     - Cuenta afectada (opcional)
      *   pMensaje            VARCHAR(256) - Descripción del incidente
      *
      * Salida:
      *   dsResultLog         LIKEDS       - Resultado (success/error)
      *
      * ========================================================================

     P SRV_AUDIT_LogIncident...
     P                 B EXPORT
     D                 PI LIKEDS(dsAuditResult)
     D   pIdEjecucion      CHAR(21)
     D   pCodigoIncidente  VARCHAR(10)
     D   pTipoIncidente    VARCHAR(20)
     D   pSeveridad        VARCHAR(10)
     D   pCuentaContable   CHAR(10)
     D   pMensaje          VARCHAR(256)

     D lResultLog      DS LIKEDS(dsAuditResult)
     D lError          DS LIKEDS(dsError)
     D lNow            TIMESTAMP
     D lSecuencia      INT(10:0)

     BEGIN

       lNow = %NOW();
       lError.errorStatus = 'S';
       lError.errorCode = 'AUD003';
       lError.errorMsg = 'Incidente registrado exitosamente';

       TRY;

         // Obtener siguiente secuencia para esta ejecución
         SELECT MAX(SECUENCIA_INCIDENTE) + 1
           INTO :lSecuencia
           FROM EARAUJOL1.CONCERR
          WHERE ID_EJECUCION = pIdEjecucion;

         IF lSecuencia IS NULL THEN;
           lSecuencia = 1;
         ENDIF;

         // Insertar incidente
         INSERT INTO EARAUJOL1.CONCERR
         VALUES(
           pIdEjecucion,
           lSecuencia,
           pCodigoIncidente,
           pTipoIncidente,
           pSeveridad,
           pCuentaContable,
           pMensaje,
           lNow,
           USER,
           pIdEjecucion
         );

         lResultLog.dsError = lError;
         lResultLog.idEjecucion = pIdEjecucion;
         lResultLog.operacion = 'LogIncident';
         lResultLog.statusOperacion = 'SUCCESS';
         lResultLog.timestampOperacion = lNow;

       CATCH;

         lError.errorStatus = 'E';
         lError.errorCode = 'AUD003_ERR';
         lError.errorMsg = 'Error al insertar incidente en CONCERR';

         lResultLog.dsError = lError;
         lResultLog.statusOperacion = 'ERROR';

       ENDTRY;

       RETURN lResultLog;

     END-PROC SRV_AUDIT_LogIncident;
