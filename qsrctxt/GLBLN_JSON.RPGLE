      * ========================================================================
      * PROTOTIPOS Y DATA STRUCTURES: GLBLN_JSON
      * ========================================================================
      * Este archivo contiene las definiciones de data structures y prototipos
      * utilizados por el módulo GLBLN_JSON.
      *
      * USO: /COPY qsrctxt/GLBLN_JSON (incluye automáticamente GLBLN_BIZ)
      *
      * CONTENIDO:
      * - dsJsonMetadata           - Sección metadata del JSON
      * - dsJsonExecution          - Sección ejecución del JSON
      * - dsJsonCuenta             - Objeto cuenta contable
      * - dsJsonResultCuentas      - Array de cuentas
      * - dsJsonControlTotales     - Sección control totales
      * - dsJsonResultWrite        - Resultado de escritura IFS
      * - 5 Prototipos (PR)        - Procedures exportadas
      *
      * ========================================================================

      * Importar estructuras de módulos previos
      /COPY qsrctxt/GLBLN_BIZ

      * ========================================================================
      * ESTRUCTURA 1: dsJsonMetadata
      * ========================================================================
      * Metadata del proceso JSON.
      *
     D dsJsonMetadata  DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   versionEstructura           VARCHAR(10)
     D   sistemaOrigen               VARCHAR(30)
     D   proceso                     VARCHAR(50)
     D   ambiente                    CHAR(3)
     D   charset                     VARCHAR(10)

      * ========================================================================
      * ESTRUCTURA 2: dsJsonExecution
      * ========================================================================
      * Datos de ejecución (timestamps, usuario, programa, librería).
      *
     D dsJsonExecution...
     D                 DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   idEjecucion                 CHAR(21)
     D   fechaProceso                DATE
     D   fechaHoraInicio             TIMESTAMP
     D   fechaHoraFin                TIMESTAMP
     D   usuario                     CHAR(10)
     D   programa                    CHAR(10)
     D   libreria                    CHAR(10)
     D   estadoEjecucion             VARCHAR(20)

      * ========================================================================
      * ESTRUCTURA 3: dsJsonCuenta
      * ========================================================================
      * Objeto cuenta individual con balance, estado y diferencias.
      *
     D dsJsonCuenta    DS QUALIFIED INTZ
     D   cuentaContable              CHAR(10)
     D   saldoInicial                DECIMAL(18:2)
     D   debitosPeriodo              DECIMAL(18:2)
     D   creditosPeriodo             DECIMAL(18:2)
     D   saldoFinalCalculado         DECIMAL(18:2)
     D   saldoFinalFuente            DECIMAL(18:2)
     D   diferenciaNeta              DECIMAL(18:2)
     D   diferenciaAbsoluta          DECIMAL(18:2)
     D   toleranciaPermitida         DECIMAL(18:2)
     D   excedeTolerancia            IND

      * ========================================================================
      * ESTRUCTURA 4: dsJsonResultCuentas
      * ========================================================================
      * Array de cuentas procesadas (máximo 999).
      *
     D dsJsonResultCuentas...
     D                 DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   rowCount                    INT(10:0)
     D   cuentas                      LIKEDS(dsJsonCuenta) DIM(999)

      * ========================================================================
      * ESTRUCTURA 5: dsJsonControlTotales
      * ========================================================================
      * Totales de control para cuadratura del JSON.
      *
     D dsJsonControlTotales...
     D                 DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   totalCuentasProcesadas      INT(10:0)
     D   totalCuentasConciliadas     INT(10:0)
     D   totalCuentasConDiferencia   INT(10:0)
     D   sumatoriaSaldoFinalFuente   DECIMAL(18:2)
     D   sumatoriaSaldoFinalConciliado...
     D                               DECIMAL(18:2)
     D   sumatoriaDiferenciaNeta     DECIMAL(18:2)

      * ========================================================================
      * ESTRUCTURA 6: dsJsonResultWrite
      * ========================================================================
      * Resultado de escritura del archivo JSON en IFS.
      *
     D dsJsonResultWrite...
     D                 DS QUALIFIED INTZ
     D   dsError                      LIKEDS(dsError)
     D   filePath                    VARCHAR(256)
     D   fileSize                    INT(10:0)
     D   statusEscritura             VARCHAR(10)
     D   timestampEscritura          TIMESTAMP

      * ========================================================================
      * PROTOTIPOS - GLBLN_json_BuildMetadata
      * ========================================================================
     D GLBLN_json_BuildMetadata...
     D                 PR LIKEDS(dsJsonMetadata)
     D   pAmbiente     CHAR(3)

      * ========================================================================
      * PROTOTIPOS - GLBLN_json_BuildExecution
      * ========================================================================
     D GLBLN_json_BuildExecution...
     D                 PR LIKEDS(dsJsonExecution)
     D   pIdEjecucion  CHAR(21)
     D   pFechaProceso DATE
     D   pUsuario      CHAR(10)
     D   pPrograma     CHAR(10)
     D   pLibreria     CHAR(10)
     D   pEstado       CHAR(20)
     D   pFechaInicio  TIMESTAMP

      * ========================================================================
      * PROTOTIPOS - GLBLN_json_BuildCuentas
      * ========================================================================
     D GLBLN_json_BuildCuentas...
     D                 PR LIKEDS(dsJsonResultCuentas)
     D   pCuentas      LIKEDS(dsBalanceAnalysis) DIM(999)
     D   pRowCount     INT(10:0)
     D   pTolerancia   DECIMAL(18:2)

      * ========================================================================
      * PROTOTIPOS - GLBLN_json_BuildControlTotales
      * ========================================================================
     D GLBLN_json_BuildControlTotales...
     D                 PR LIKEDS(dsJsonControlTotales)
     D   pTotalCuentas         INT(10:0)
     D   pTotalConciliadas     INT(10:0)
     D   pTotalConDiferencia   INT(10:0)
     D   pSumatoriaSaldoFuente DECIMAL(18:2)
     D   pSumatoriaConciliado  DECIMAL(18:2)
     D   pSumatoriaDiferencia  DECIMAL(18:2)

      * ========================================================================
      * PROTOTIPOS - GLBLN_json_WriteToIFS
      * ========================================================================
     D GLBLN_json_WriteToIFS...
     D                 PR LIKEDS(dsJsonResultWrite)
     D   pIdEjecucion  CHAR(21)
     D   pJsonPayload  VARCHAR(32767)
