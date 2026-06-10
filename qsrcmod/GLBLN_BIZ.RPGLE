      * ========================================================================
      * MÓDULO: GLBLN_BIZ (Lógica de Negocio - Conciliación GLBLN)
      * ========================================================================
      * DESCRIPCIÓN:
      * Módulo SQLRPGLE con procedures de lógica de negocio para el proceso
      * de conciliación de cuentas mayores. Encapsula cálculos, determinación
      * de estado financiero, identificación de partidas en tránsito y 
      * validación de tolerancias.
      *
      * PROCEDURES:
      *   1. GLBLN_biz_CalculateBalance()    - Prepara estructura con balance
      *   2. GLBLN_biz_DetermineFiState()    - Asigna estado financiero
      *   3. GLBLN_biz_IdentifyTransit()     - Identifica partidas en tránsito
      *   4. GLBLN_biz_CheckTolerance()      - Valida tolerancia de diferencia
      *
      * PRINCIPIOS ARQUITECTÓNICOS:
      *   - Responsabilidad única: Reglas de negocio de conciliación.
      *   - Desacoplamiento: Usa resultados de GLBLN_DB, no consulta tablas directo.
      *   - Lógica centralizada: Todas las reglas en procedures reutilizables.
      *   - Sin side-effects: Procedures puras, no modifican BD.
      *   - Testeable: Algoritmos independientes, fáciles de validar.
      *
      * PARÁMETROS DE NEGOCIO:
      *   - Tolerancia:  1.00 (diferencia máxima permitida)
      *   - Estados:     CONCILIADA, PARCIAL, DIFERENCIA, ERROR
      *   - Severidades: BAJA, MEDIA, ALTA, CRITICA
      *
      * EQUIPO:        Taller GitHub Copilot
      * FECHA:         2026-06-09
      * PROYECTO:      Conciliación GLBLN
      * VERSIÓN:       1.0
      * ========================================================================

     H NOMAIN BNDDIR('QSys.Lib/EARAUJOL1.Lib')
     H ACTGRP(*CALLER)
     H OPTION(*SRCSTMT : *NODEBUGIO)
     H FIXNUMLIT

      * ========================================================================
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES
      * ========================================================================

      /COPY qsrctxt/GLBLN_DB

      * ========================================================================
      * DEFINICIÓN DE DATA STRUCTURES
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
      * CONSTANTS
      * ========================================================================

     D CONST_TOLERANCIA S DECIMAL(18:2) INZ(1.00)
     D CONST_ESTADO_CONCILIADA S VARCHAR(20) INZ('CONCILIADA')
     D CONST_ESTADO_PARCIAL S VARCHAR(20) INZ('PARCIAL')
     D CONST_ESTADO_DIFERENCIA S VARCHAR(20) INZ('DIFERENCIA')
     D CONST_ESTADO_ERROR S VARCHAR(20) INZ('ERROR')

     D CONST_SEV_BAJA S VARCHAR(10) INZ('BAJA')
     D CONST_SEV_MEDIA S VARCHAR(10) INZ('MEDIA')
     D CONST_SEV_ALTA S VARCHAR(10) INZ('ALTA')
     D CONST_SEV_CRITICA S VARCHAR(10) INZ('CRITICA')

      * ========================================================================
      * PROCEDURE 1: GLBLN_biz_CalculateBalance
      * ========================================================================
      * DESCRIPCIÓN:
      * Convierte resultado de GLBLN_db_GetBalance en estructura de análisis
      * con cálculo de diferencia, diferencia absoluta y análisis de tolerancia.
      *
      * PARÁMETROS DE ENTRADA:
      *   pBalance            - LIKEDS(dsBalance) - Balance de GLBLN_db_GetBalance
      *   pTolerancia         - DECIMAL(18:2) - Monto máximo permitido (1.00)
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con estructura analítica de balance
      *
      * LÓGICA:
      *   1. Copiar campos de entrada
      *   2. Calcular diferenciaNeta = saldoFinal - saldoFuente (GLBLN)
      *   3. Calcular diferenciaAbsoluta = ABS(diferenciaNeta)
      *   4. Validar si excedeTolerancia = (diferenciaAbsoluta > pTolerancia)
      *
      * ========================================================================

     P GLBLN_biz_CalculateBalance...
     P                 B EXPORT
     D                 PI LIKEDS(dsBalanceAnalysis)
     D   pBalance      LIKEDS(dsBalance)
     D   pTolerancia   DECIMAL(18:2)

     D lResult         DS LIKEDS(dsBalanceAnalysis) INZ
     D lDifNeta        DECIMAL(18:2)
     D lDifAbsoluta    DECIMAL(18:2)

     BEGIN

       lResult.cuenta = pBalance.cuenta;
       lResult.saldoInicial = pBalance.saldoInicial;
       lResult.debitosHistoricos = pBalance.debitosHistoricos;
       lResult.creditosHistoricos = pBalance.creditosHistoricos;
       lResult.saldoAnterior = pBalance.saldoAnterior;
       lResult.debitosDia = pBalance.debitosDia;
       lResult.creditosDia = pBalance.creditosDia;
       lResult.saldoFinal = pBalance.saldoFinal;
       lResult.tolerancia = pTolerancia;

       // Calcular diferencia neta (saldoFinal - saldoInicial - movimientos)
       // Equivalente a: diferencia no explicada
       lDifNeta = pBalance.saldoFinal - pBalance.saldoInicial -
                  pBalance.debitosHistoricos + pBalance.creditosHistoricos -
                  pBalance.debitosDia + pBalance.creditosDia;

       lResult.diferenciaNeta = lDifNeta;
       lResult.diferenciaAbsoluta = %ABS(lDifNeta);
       lResult.excedeTolerancia = (lResult.diferenciaAbsoluta > pTolerancia);

       lResult.dsError.errorStatus = 'S';

       RETURN lResult;

     END-PROC GLBLN_biz_CalculateBalance;

      * ========================================================================
      * PROCEDURE 2: GLBLN_biz_DetermineFiState
      * ========================================================================
      * DESCRIPCIÓN:
      * Determina el estado financiero de una cuenta basado en:
      *   - Diferencia neta vs. tolerancia
      *   - Presencia de partidas en tránsito
      *   - Errors en cálculo
      *
      * PARÁMETROS DE ENTRADA:
      *   pBalance            - LIKEDS(dsBalanceAnalysis) - Balance analizado
      *   pTransitCount       - INT(10:0) - Cantidad de partidas en tránsito
      *   pHayError           - IND - TRUE si hay error en datos
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - codigo: Estado (CONCILIADA, PARCIAL, DIFERENCIA, ERROR)
      *   - descripcion: Texto descriptivo
      *   - requiereRevision: TRUE si necesita revisión manual
      *   - severidad: Nivel de urgencia (BAJA, MEDIA, ALTA, CRITICA)
      *
      * LÓGICA:
      *   1. Si pHayError = TRUE → ERROR (CRITICA)
      *   2. Si diferencia = 0 Y sin partidas → CONCILIADA (BAJA)
      *   3. Si diferencia <= tolerancia Y CON partidas → PARCIAL (MEDIA)
      *   4. Si diferencia > tolerancia → DIFERENCIA (ALTA)
      *   5. Default → DIFERENCIA (ALTA)
      *
      * ========================================================================

     P GLBLN_biz_DetermineFiState...
     P                 B EXPORT
     D                 PI LIKEDS(dsFinancialState)
     D   pBalance      LIKEDS(dsBalanceAnalysis)
     D   pTransitCount INT(10:0)
     D   pHayError     IND

     D lResult         DS LIKEDS(dsFinancialState) INZ

     BEGIN

       lResult.cuenta = pBalance.cuenta;

       // Caso 1: Error en datos de origen
       IF pHayError;
         lResult.codigo = CONST_ESTADO_ERROR;
         lResult.descripcion = 'Error en datos de origen o cálculo';
         lResult.requiereRevision = *ON;
         lResult.severidad = CONST_SEV_CRITICA;
         lResult.dsError.errorStatus = 'S';
         RETURN lResult;
       ENDIF;

       // Caso 2: Diferencia cero o dentro de tolerancia SIN partidas
       IF pBalance.diferenciaNeta = 0 AND pTransitCount = 0;
         lResult.codigo = CONST_ESTADO_CONCILIADA;
         lResult.descripcion = 'Cuenta conciliada perfectamente';
         lResult.requiereRevision = *OFF;
         lResult.severidad = CONST_SEV_BAJA;
         lResult.dsError.errorStatus = 'S';
         RETURN lResult;
       ENDIF;

       // Caso 3: Diferencia dentro de tolerancia CON partidas en tránsito
       IF pBalance.diferenciaAbsoluta <= pBalance.tolerancia AND
          pTransitCount > 0;
         lResult.codigo = CONST_ESTADO_PARCIAL;
         lResult.descripcion = 
           'Conciliada con ' + %TRIM(%CHAR(pTransitCount)) + 
           ' partida(s) en tránsito';
         lResult.requiereRevision = *ON;
         lResult.severidad = CONST_SEV_MEDIA;
         lResult.dsError.errorStatus = 'S';
         RETURN lResult;
       ENDIF;

       // Caso 4: Diferencia dentro de tolerancia SIN partidas (raro pero posible)
       IF pBalance.diferenciaAbsoluta <= pBalance.tolerancia AND
          pTransitCount = 0;
         lResult.codigo = CONST_ESTADO_CONCILIADA;
         lResult.descripcion = 
           'Diferencia menor dentro de tolerancia: ' + 
           %TRIM(%EDITC(pBalance.diferenciaNeta, 'L'));
         lResult.requiereRevision = *OFF;
         lResult.severidad = CONST_SEV_BAJA;
         lResult.dsError.errorStatus = 'S';
         RETURN lResult;
       ENDIF;

       // Caso 5: Diferencia FUERA de tolerancia (con o sin partidas)
       IF pBalance.excedeTolerancia;
         lResult.codigo = CONST_ESTADO_DIFERENCIA;
         lResult.descripcion = 
           'Diferencia significativa: ' + 
           %TRIM(%EDITC(pBalance.diferenciaNeta, 'L')) + 
           '. Excede tolerancia de ' + 
           %TRIM(%EDITC(pBalance.tolerancia, 'L'));
         lResult.requiereRevision = *ON;
         lResult.severidad = CONST_SEV_ALTA;
         lResult.dsError.errorStatus = 'S';
         RETURN lResult;
       ENDIF;

       // Default (fallback)
       lResult.codigo = CONST_ESTADO_DIFERENCIA;
       lResult.descripcion = 'Estado indeterminado';
       lResult.requiereRevision = *ON;
       lResult.severidad = CONST_SEV_MEDIA;
       lResult.dsError.errorStatus = 'S';

       RETURN lResult;

     END-PROC GLBLN_biz_DetermineFiState;

      * ========================================================================
      * PROCEDURE 3: GLBLN_biz_IdentifyTransit
      * ========================================================================
      * DESCRIPCIÓN:
      * Identifica partidas en tránsito basándose en:
      *   1. Tipo de documento específico en TTRAN (DEPOSITO, TRANSFERENCIA)
      *   2. Diferencia entre fecha de documento y fecha de aplicación
      *   3. Documentos que permanecen pendientes de aplicación
      *
      * PARÁMETROS DE ENTRADA:
      *   pBanco              - CHAR(2)
      *   pSucursal           - CHAR(3)
      *   pMoneda             - CHAR(3)
      *   pCuenta             - CHAR(10)
      *   pFechaProceso       - DATE
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - rowCount: Cantidad de partidas en tránsito
      *   - partidas: Array de partidas (max 999)
      *   - dsError: Estructura de error
      *
      * LÓGICA:
      *   1. SELECT de TTRAN donde:
      *      - tipo_documento IN ('DEP', 'TRF', 'CHQ')
      *      - fecha_documento < pFechaProceso (retraso)
      *      - estado != 'APLICADA'
      *   2. Calcular diasEnTransito = pFechaProceso - fecha_documento
      *   3. Retornar array de partidas
      *
      * ========================================================================

     P GLBLN_biz_IdentifyTransit...
     P                 B EXPORT
     D                 PI LIKEDS(dsResultTransit)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuenta       CHAR(10)
     D   pFechaProceso DATE

     D lResult         DS LIKEDS(dsResultTransit) INZ
     D lCursor         CURSOR FOR
     D   SELECT DISTINCT
     D          numero_documento,
     D          tipo_documento,
     D          monto,
     D          fecha_documento,
     D          fecha_transaccion,
     D          estado_documento,
     D          descripcion_movimiento
     D     FROM TTRAN
     D    WHERE codigo_banco = :pBanco
     D      AND codigo_sucursal = :pSucursal
     D      AND codigo_moneda = :pMoneda
     D      AND cuenta_contable = :pCuenta
     D      AND tipo_documento IN ('DEP', 'TRF', 'CHQ')
     D      AND fecha_documento < :pFechaProceso
     D      AND estado_documento <> 'APLICADA'
     D    ORDER BY fecha_documento

     D lNumDoc         VARCHAR(20)
     D lTipoDoc        VARCHAR(20)
     D lMonto          DECIMAL(18:2)
     D lFechaDoc       DATE
     D lFechaApl       DATE
     D lEstado         VARCHAR(20)
     D lDescr          VARCHAR(256)
     D lDiasTransito   INT(10:0)

     BEGIN

       lResult.rowCount = 0;
       lResult.dsError.errorStatus = 'S';

       TRY;

         OPEN lCursor;

         FETCH NEXT FROM lCursor INTO
           lNumDoc, lTipoDoc, lMonto, lFechaDoc, lFechaApl,
           lEstado, lDescr;

         WHILE SQLSTATE = '00000' AND lResult.rowCount < 999;

           lResult.rowCount += 1;

           // Generar ID único de partida
           lResult.partidas(lResult.rowCount).idPartida = 
             %TRIM(lTipoDoc) + '-' + %TRIM(lNumDoc);

           lResult.partidas(lResult.rowCount).tipo = lTipoDoc;
           lResult.partidas(lResult.rowCount).numero = lNumDoc;
           lResult.partidas(lResult.rowCount).monto = lMonto;
           lResult.partidas(lResult.rowCount).fechaDocumento = lFechaDoc;
           lResult.partidas(lResult.rowCount).fechaAplicacion = lFechaApl;

           // Calcular días en tránsito
           lDiasTransito = %DAYS(pFechaProceso) - %DAYS(lFechaDoc);
           lResult.partidas(lResult.rowCount).diasEnTransito = 
             lDiasTransito;

           lResult.partidas(lResult.rowCount).estado = lEstado;
           lResult.partidas(lResult.rowCount).observacion = 
             'Pendiente ' + %TRIM(%CHAR(lDiasTransito)) + 
             ' días. ' + %TRIM(lDescr);

           FETCH NEXT FROM lCursor INTO
             lNumDoc, lTipoDoc, lMonto, lFechaDoc, lFechaApl,
             lEstado, lDescr;

         ENDWHILE;

         CLOSE lCursor;

         IF SQLSTATE <> '00000' AND SQLSTATE <> '02000';
           lResult.dsError.errorCode = SQLSTATE;
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
         ELSE;
           lResult.dsError.errorStatus = 'S';
         ENDIF;

       CATCH;
         lResult.dsError.errorStatus = 'E';
         lResult.dsError.errorCode = 'EXCP';
         lResult.dsError.errorMsg = 
           'Excepción no controlada en GLBLN_biz_IdentifyTransit';
       ENDTRY;

       RETURN lResult;

     END-PROC GLBLN_biz_IdentifyTransit;

      * ========================================================================
      * PROCEDURE 4: GLBLN_biz_CheckTolerance
      * ========================================================================
      * DESCRIPCIÓN:
      * Valida si una diferencia está dentro de la tolerancia permitida
      * y retorna indicador de éxito + severidad del incidente.
      *
      * PARÁMETROS DE ENTRADA:
      *   pDiferencia         - DECIMAL(18:2) - Diferencia neta
      *   pTolerancia         - DECIMAL(18:2) - Límite permitido
      *   pTransitCount       - INT(10:0) - Cantidad de partidas en tránsito
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna CHAR(1):
      *   - 'S': Dentro de tolerancia (OK)
      *   - 'A': Fuera de tolerancia pero con partidas (advertencia)
      *   - 'E': Fuera de tolerancia sin explicación (error)
      *
      * LÓGICA:
      *   1. Si ABS(diferencia) <= tolerancia:
      *      - Si CON partidas → Retornar 'A' (advertencia)
      *      - Si SIN partidas → Retornar 'S' (éxito)
      *   2. Si ABS(diferencia) > tolerancia:
      *      - Retornar 'E' (error)
      *
      * ========================================================================

     P GLBLN_biz_CheckTolerance...
     P                 B EXPORT
     D                 PI CHAR(1)
     D   pDiferencia   DECIMAL(18:2)
     D   pTolerancia   DECIMAL(18:2)
     D   pTransitCount INT(10:0)

     D lDifAbsoluta    DECIMAL(18:2)
     D lResult         CHAR(1)

     BEGIN

       lDifAbsoluta = %ABS(pDiferencia);

       // Dentro de tolerancia
       IF lDifAbsoluta <= pTolerancia;

         // Con partidas en tránsito
         IF pTransitCount > 0;
           lResult = 'A';  // Advertencia (partidas pendientes)
         ELSE;
           lResult = 'S';  // Éxito (conciliado)
         ENDIF;

       ELSE;
         // Fuera de tolerancia
         lResult = 'E';  // Error (diferencia significativa)

       ENDIF;

       RETURN lResult;

     END-PROC GLBLN_biz_CheckTolerance;
