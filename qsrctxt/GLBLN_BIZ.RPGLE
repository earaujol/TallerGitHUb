      * ========================================================================
      * PROTOTIPOS: GLBLN_BIZ (Lógica de Negocio - Conciliación)
      * ========================================================================
      * ARCHIVO: qsrctxt/GLBLN_BIZ.RPGLE
      * 
      * DESCRIPCIÓN:
      * Declaración de prototipos (procedure interface) para el módulo GLBLN_BIZ.
      * Estos prototipos deben ser incluidos en cualquier programa que use
      * las procedures del módulo.
      *
      * USO EN OTROS PROGRAMAS:
      *   /COPY qsrctxt/GLBLN_DB      (dependencia)
      *   /COPY qsrctxt/GLBLN_BIZ
      *
      * ========================================================================

      * ========================================================================
      * IMPORTS: Data Structures de GLBLN_DB
      * ========================================================================

      /COPY qsrctxt/GLBLN_DB

      * ========================================================================
      * DEFINE: Data Structures Adicionales de GLBLN_BIZ
      * ========================================================================

      * DS: Estructura de Balance Extendida (con análisis)
     D dsBalanceAnalysis DS QUALIFIED
     D  cuenta           CHAR(10)
     D  saldoInicial     DECIMAL(18:2)
     D  debitosHistoricos DECIMAL(18:2)
     D  creditosHistoricos DECIMAL(18:2)
     D  saldoAnterior    DECIMAL(18:2)
     D  debitosDia       DECIMAL(18:2)
     D  creditosDia      DECIMAL(18:2)
     D  saldoFinal       DECIMAL(18:2)
     D  diferenciaNeta   DECIMAL(18:2)
     D  diferenciaAbsoluta DECIMAL(18:2)
     D  tolerancia       DECIMAL(18:2)
     D  excedeTolerancia IND
     D  dsError          LIKEDS(dsError)

      * DS: Estructura de Estado Financiero
     D dsFinancialState  DS QUALIFIED
     D  cuenta           CHAR(10)
     D  codigo           VARCHAR(20)      // CONCILIADA, PARCIAL, DIFERENCIA, ERROR
     D  descripcion      VARCHAR(100)
     D  requiereRevision IND
     D  severidad        VARCHAR(10)      // BAJA, MEDIA, ALTA, CRITICA
     D  dsError          LIKEDS(dsError)

      * DS: Partida Conciliatoria en Tránsito
     D dsTransitPartida  DS QUALIFIED
     D  idPartida        VARCHAR(30)
     D  tipo              VARCHAR(20)      // DEPOSITO, TRANSFERENCIA, CHEQUE, etc
     D  numero           VARCHAR(20)      // Número del documento
     D  monto            DECIMAL(18:2)
     D  fechaDocumento   DATE
     D  fechaAplicacion  DATE
     D  diasEnTransito   INT(10:0)
     D  estado           VARCHAR(20)      // PENDIENTE, APLICADA, CANCELADA
     D  observacion      VARCHAR(256)

      * DS: Resultado de Partidas en Tránsito
     D dsResultTransit   DS QUALIFIED
     D  rowCount         INT(10:0)
     D  partidas         LIKE(dsTransitPartida) DIM(999)
     D  dsError          LIKEDS(dsError)

      * ========================================================================
      * PROTOTYPE 1: GLBLN_biz_CalculateBalance
      * ========================================================================
      * Convierte resultado de GLBLN_db_GetBalance en estructura de análisis
      * con cálculo de diferencia, diferencia absoluta y análisis de tolerancia.
      *
      * Parámetros:
      *   pBalance            LIKEDS(dsBalance)    - Balance de GLBLN_db_GetBalance
      *   pTolerancia         DECIMAL(18:2)        - Monto máximo permitido (1.00)
      *
      * Retorna: dsBalanceAnalysis
      * ========================================================================

     D GLBLN_biz_CalculateBalance...
     D                 PR LIKEDS(dsBalanceAnalysis)
     D   pBalance      LIKEDS(dsBalance)
     D   pTolerancia   DECIMAL(18:2)

      * ========================================================================
      * PROTOTYPE 2: GLBLN_biz_DetermineFiState
      * ========================================================================
      * Determina el estado financiero de una cuenta basado en:
      *   - Diferencia neta vs. tolerancia
      *   - Presencia de partidas en tránsito
      *   - Errors en cálculo
      *
      * Parámetros:
      *   pBalance            LIKEDS(dsBalanceAnalysis) - Balance analizado
      *   pTransitCount       INT(10:0)  - Cantidad de partidas en tránsito
      *   pHayError           IND        - TRUE si hay error en datos
      *
      * Retorna: dsFinancialState
      * ========================================================================

     D GLBLN_biz_DetermineFiState...
     D                 PR LIKEDS(dsFinancialState)
     D   pBalance      LIKEDS(dsBalanceAnalysis)
     D   pTransitCount INT(10:0)
     D   pHayError     IND

      * ========================================================================
      * PROTOTYPE 3: GLBLN_biz_IdentifyTransit
      * ========================================================================
      * Identifica partidas en tránsito basándose en:
      *   1. Tipo de documento específico en TTRAN (DEP, TRF, CHQ)
      *   2. Diferencia entre fecha de documento y fecha de aplicación
      *   3. Documentos que permanecen pendientes de aplicación
      *
      * Parámetros:
      *   pBanco              CHAR(2)   - Código de banco
      *   pSucursal           CHAR(3)   - Código de sucursal
      *   pMoneda             CHAR(3)   - Código de moneda
      *   pCuenta             CHAR(10)  - Cuenta contable
      *   pFechaProceso       DATE      - Fecha de corte
      *
      * Retorna: dsResultTransit
      * ========================================================================

     D GLBLN_biz_IdentifyTransit...
     D                 PR LIKEDS(dsResultTransit)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuenta       CHAR(10)
     D   pFechaProceso DATE

      * ========================================================================
      * PROTOTYPE 4: GLBLN_biz_CheckTolerance
      * ========================================================================
      * Valida si una diferencia está dentro de la tolerancia permitida
      * y retorna indicador de éxito + severidad del incidente.
      *
      * Parámetros:
      *   pDiferencia         DECIMAL(18:2)  - Diferencia neta
      *   pTolerancia         DECIMAL(18:2)  - Límite permitido (1.00)
      *   pTransitCount       INT(10:0)      - Cantidad de partidas en tránsito
      *
      * Retorna: CHAR(1)
      *   - 'S': Dentro de tolerancia (OK)
      *   - 'A': Fuera de tolerancia pero con partidas (advertencia)
      *   - 'E': Fuera de tolerancia sin explicación (error)
      * ========================================================================

     D GLBLN_biz_CheckTolerance...
     D                 PR CHAR(1)
     D   pDiferencia   DECIMAL(18:2)
     D   pTolerancia   DECIMAL(18:2)
     D   pTransitCount INT(10:0)
