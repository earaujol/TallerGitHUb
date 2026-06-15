      * ========================================================================
      * PROTOTIPOS Y DATA STRUCTURES: SRV_AUDIT
      * ========================================================================
      * Este archivo contiene las definiciones de data structures y prototipos
      * utilizados por el programa de servicio SRV_AUDIT.
      *
      * USO: /COPY qsrctxt/SRV_AUDIT
      *
      * CONTENIDO:
      * - dsAuditResult              - Resultado de operación de auditoría
      * - 3 Prototipos (PR)          - Procedures exportadas
      *
      * ========================================================================

      * Importar estructuras base
      /COPY qsrctxt/GLBLN_DB

      * ========================================================================
      * ESTRUCTURA 1: dsAuditResult
      * ========================================================================
      * Resultado de una operación de auditoría (insert/update).
      *
     D dsAuditResult   DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   idEjecucion                 CHAR(21)
     D   operacion                   VARCHAR(30)
     D   statusOperacion             VARCHAR(10)
     D   timestampOperacion          TIMESTAMP

      * ========================================================================
      * PROTOTIPO 1: SRV_AUDIT_LogStart
      * ========================================================================
      * Registra el inicio de una ejecución en CONCEXC.
      *
     D SRV_AUDIT_LogStart...
     D                 PR LIKEDS(dsAuditResult)
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

      * ========================================================================
      * PROTOTIPO 2: SRV_AUDIT_LogEnd
      * ========================================================================
      * Registra el fin de una ejecución y actualiza contadores en CONCEXC.
      *
     D SRV_AUDIT_LogEnd...
     D                 PR LIKEDS(dsAuditResult)
     D   pIdEjecucion  CHAR(21)
     D   pTotalCuentas INT(10:0)
     D   pTotalConciliadas INT(10:0)
     D   pTotalConDif  INT(10:0)
     D   pTotalErrores INT(10:0)
     D   pEstadoFinal  CHAR(20)

      * ========================================================================
      * PROTOTIPO 3: SRV_AUDIT_LogIncident
      * ========================================================================
      * Registra un incidente/error en CONCERR.
      *
     D SRV_AUDIT_LogIncident...
     D                 PR LIKEDS(dsAuditResult)
     D   pIdEjecucion      CHAR(21)
     D   pCodigoIncidente  VARCHAR(10)
     D   pTipoIncidente    VARCHAR(20)
     D   pSeveridad        VARCHAR(10)
     D   pCuentaContable   CHAR(10)
     D   pMensaje          VARCHAR(256)
