**free
// * ========================================================================
// * MÓDULO: GLBLN_BIZ (Lógica de Negocio - Conciliación GLBLN);
// * ========================================================================
// * DESCRIPCIÓN:
// * Módulo SQLRPGLE con procedures de lógica de negocio para el proceso
// * de conciliación de cuentas mayores. Encapsula cálculos, determinación
// * de estado financiero, identificación de partidas en tránsito y 
// * validación de tolerancias.
// *
// * PROCEDURES:
// *   1. GLBLN_biz_CalculateBalance();    - Prepara estructura con balance
// *   2. GLBLN_biz_DetermineFiState();    - Asigna estado financiero
// *   3. GLBLN_biz_IdentifyTransit();     - Identifica partidas en tránsito
// *   4. GLBLN_biz_CheckTolerance();      - Valida tolerancia de diferencia
// *
// * PRINCIPIOS ARQUITECTÓNICOS:
// *   - Responsabilidad única: Reglas de negocio de conciliación.
// *   - Desacoplamiento: Usa resultados de GLBLN_DB, no consulta tablas directo.
// *   - Lógica centralizada: Todas las reglas en procedures reutilizables.
// *   - Sin side-effects: Procedures puras, no modifican BD.
// *   - Testeable: Algoritmos independientes, fáciles de validar.
// *
// * PARÁMETROS DE NEGOCIO:
// *   - Tolerancia:  1.00 (diferencia máxima permitida);
// *   - Estados:     CONCILIADA, PARCIAL, DIFERENCIA, ERROR
// *   - Severidades: BAJA, MEDIA, ALTA, CRITICA
// *
// * EQUIPO:        Taller GitHub Copilot
// * FECHA:         2026-06-09
// * PROYECTO:      Conciliación GLBLN
// * VERSIÓN:       1.0
// * ========================================================================

ctl-opt NOMAIN BNDDIR('QSys.Lib/EARAUJOL1.Lib') ACTGRP(*CALLER)
        OPTION(*SRCSTMT : *NODEBUGIO); //FIXNUMLIT

//  ========================================================================
//  IMPORTAR PROTOTIPOS Y DATA STRUCTURES
//  ========================================================================

/include qsrctxt/GLBLN_DB
/
//  ========================================================================
//  DEFINICIÓN DE DATA STRUCTURES
//  ========================================================================

// DS: Estructura de Balance Extendida (con análisis);
dcl-ds dsBalanceAnalysis QUALIFIED;
  cuenta             CHAR(10);
  saldoInicial       PACKED(18:2);
  debitosHistoricos  PACKED(18:2);
  creditosHistoricos PACKED(18:2);
  saldoAnterior      PACKED(18:2);
  debitosDia         PACKED(18:2);
  creditosDia        PACKED(18:2);
  saldoFinal         PACKED(18:2);
  diferenciaNeta     PACKED(18:2);
  diferenciaAbsoluta PACKED(18:2);
  tolerancia         PACKED(18:2);
  excedeTolerancia   IND;
  dsError            LIKEDS(dsError);
end-ds;     

// DS: Estructura de Estado Financiero
dcl-ds dsFinancialState  QUALIFIED;
  cuenta           CHAR(10);
  codigo           VARCHAR(20);      // CONCILIADA, PARCIAL, DIFERENCIA, ERROR
  descripcion      VARCHAR(100);
  requiereRevision IND;
  severidad        VARCHAR(10);      // BAJA, MEDIA, ALTA, CRITICA
  dsError          LIKEDS(dsError);
end-ds;

// DS: Partida Conciliatoria en Tránsito;
dcl-ds dsTransitPartida  QUALIFIED;
  idPartida        VARCHAR(30);
  tipo             VARCHAR(20);      // DEPOSITO, TRANSFERENCIA, CHEQUE, etc
  numero           VARCHAR(20);      // Número del documento
  monto            PACKED(18:2);
  fechaDocumento   DATE;
  fechaAplicacion  DATE;
  diasEnTransito   INT(10:0);
  estado           VARCHAR(20);      // PENDIENTE, APLICADA, CANCELADA
  observacion      VARCHAR(256);
end-ds;  

//  DS: Resultado de Partidas en Tránsito
dcl-ds dsResultTransit   QUALIFIED;
  rowCount         INT(10:0);
  partidas         LIKE(dsTransitPartida) DIM(999);
  dsError          LIKEDS(dsError);
end-ds;  

// * ========================================================================
// * CONSTANTS
// * ========================================================================

dcl-c CONST_TOLERANCIA        PACKED(18:2) INZ(1.00);
dcl-c CONST_ESTADO_CONCILIADA VARCHAR(20) INZ('CONCILIADA');
dcl-c CONST_ESTADO_PARCIAL    VARCHAR(20) INZ('PARCIAL');
dcl-c CONST_ESTADO_DIFERENCIA VARCHAR(20) INZ('DIFERENCIA');
dcl-c CONST_ESTADO_ERROR      VARCHAR(20) INZ('ERROR');

dcl-c CONST_SEV_BAJA    VARCHAR(10) INZ('BAJA');
dcl-c CONST_SEV_MEDIA   VARCHAR(10) INZ('MEDIA');
dcl-c CONST_SEV_ALTA    VARCHAR(10) INZ('ALTA');
dcl-c ONST_SEV_CRITICA  VARCHAR(10) INZ('CRITICA');

// * ========================================================================
// * PROCEDURE 1: GLBLN_biz_CalculateBalance
// * ========================================================================
// * DESCRIPCIÓN:
// * Convierte resultado de GLBLN_db_GetBalance en estructura de análisis
// * con cálculo de diferencia, diferencia absoluta y análisis de tolerancia.
// *
// * PARÁMETROS DE ENTRADA:
// *   pBalance            - LIKEDS(dsBalance); - Balance de GLBLN_db_GetBalance
// *   pTolerancia         - PACKED(18:2); - Monto máximo permitido (1.00);
// *
// * PARÁMETROS DE SALIDA:
// *   Retorna DS QUALIFIED con estructura analítica de balance
// *
// * LÓGICA:
// *   1. Copiar campos de entrada
// *   2. Calcular diferenciaNeta = saldoFinal - saldoFuente (GLBLN);
// *   3. Calcular diferenciaAbsoluta = ABS(diferenciaNeta);
// *   4. Validar si excedeTolerancia = (diferenciaAbsoluta > pTolerancia);
// *
// * ========================================================================

DCL-PROC GLBLN_biz_CalculateBalance EXPORT;
  dcl-pi *n LIKEDS(dsBalanceAnalysis);
    pBalance      LIKEDS(dsBalance);
    pTolerancia   PACKED(18:2);
  end-pi;
                   

  DCL-DS lResult         LIKEDS(dsBalanceAnalysis) INZ;
  DCL-S  lDifNeta        PACKED(18:2);
  DCL-S  lDifAbsoluta    PACKED(18:2);

  lResult.cuenta = pBalance.cuenta;
  lResult.saldoInicial = pBalance.saldoInicial;
  lResult.debitosHistoricos = pBalance.debitosHistoricos;
  lResult.creditosHistoricos = pBalance.creditosHistoricos;
  lResult.saldoAnterior = pBalance.saldoAnterior;
  lResult.debitosDia = pBalance.debitosDia;
  lResult.creditosDia = pBalance.creditosDia;
  lResult.saldoFinal = pBalance.saldoFinal;
  lResult.tolerancia = pTolerancia;

  // Calcular diferencia neta (saldoFinal - saldoInicial - movimientos);
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

// * ========================================================================
// * PROCEDURE 2: GLBLN_biz_DetermineFiState
// * ========================================================================
// * DESCRIPCIÓN:
// * Determina el estado financiero de una cuenta basado en:
// *   - Diferencia neta vs. tolerancia
// *   - Presencia de partidas en tránsito
// *   - Errors en cálculo
// *
// * PARÁMETROS DE ENTRADA:
// *   pBalance            - LIKEDS(dsBalanceAnalysis); - Balance analizado
// *   pTransitCount       - INT(10:0); - Cantidad de partidas en tránsito
// *   pHayError           - IND - TRUE si hay error en datos
// *
// * PARÁMETROS DE SALIDA:
// *   Retorna DS QUALIFIED con:
// *   - codigo: Estado (CONCILIADA, PARCIAL, DIFERENCIA, ERROR);
// *   - descripcion: Texto descriptivo
// *   - requiereRevision: TRUE si necesita revisión manual
// *   - severidad: Nivel de urgencia (BAJA, MEDIA, ALTA, CRITICA);
// *
// * LÓGICA:
// *   1. Si pHayError = TRUE → ERROR (CRITICA);
// *   2. Si diferencia = 0 Y sin partidas → CONCILIADA (BAJA);
// *   3. Si diferencia <= tolerancia Y CON partidas → PARCIAL (MEDIA);
// *   4. Si diferencia > tolerancia → DIFERENCIA (ALTA);
// *   5. Default → DIFERENCIA (ALTA);
// *
// * ========================================================================

dcl-proc GLBLN_biz_DetermineFiState EXPORT;
  dcl-pi *n LIKEDS(dsFinancialState);
    pBalance      LIKEDS(dsBalanceAnalysis);
    pTransitCount INT(10:0);
    pHayError     IND;
  end-pi;
  
  DCL-DS lResult    LIKEDS(dsFinancialState) INZ;

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
              'Conciliada con ' + %TRIM(%CHAR(pTransitCount)); + 
              ' partida(s); en tránsito';
    lResult.requiereRevision = *ON;
    lResult.severidad = CONST_SEV_MEDIA;
    lResult.dsError.errorStatus = 'S';
    RETURN lResult;
  ENDIF;

       // Caso 4: Diferencia dentro de tolerancia SIN partidas (raro pero posible);
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

       // Caso 5: Diferencia FUERA de tolerancia (con o sin partidas);
  IF pBalance.excedeTolerancia;
    lResult.codigo = CONST_ESTADO_DIFERENCIA;
    lResult.descripcion = 
              'Diferencia significativa: ' + 
              %TRIM(%EDITC(pBalance.diferenciaNeta, 'L')); + 
              '. Excede tolerancia de ' + 
              %TRIM(%EDITC(pBalance.tolerancia, 'L'));
    lResult.requiereRevision = *ON;
    lResult.severidad = CONST_SEV_ALTA;
    lResult.dsError.errorStatus = 'S';
    RETURN lResult;
  ENDIF;

  // Default (fallback);
  lResult.codigo = CONST_ESTADO_DIFERENCIA;
  lResult.descripcion = 'Estado indeterminado';
  lResult.requiereRevision = *ON;
  lResult.severidad = CONST_SEV_MEDIA;
  lResult.dsError.errorStatus = 'S';

  RETURN lResult;

END-PROC GLBLN_biz_DetermineFiState;

// * ========================================================================
// * PROCEDURE 3: GLBLN_biz_IdentifyTransit
// * ========================================================================
// * DESCRIPCIÓN:
// * Identifica partidas en tránsito basándose en:
// *   1. Tipo de documento específico en TTRAN (DEPOSITO, TRANSFERENCIA);
// *   2. Diferencia entre fecha de documento y fecha de aplicación
// *   3. Documentos que permanecen pendientes de aplicación
// *
// * PARÁMETROS DE ENTRADA:
// *   pBanco              - CHAR(2);
// *   pSucursal           - CHAR(3);
// *   pMoneda             - CHAR(3);
// *   pCuenta             - CHAR(10);
// *   pFechaProceso       - DATE
// *
// * PARÁMETROS DE SALIDA:
// *   Retorna DS QUALIFIED con:
// *   - rowCount: Cantidad de partidas en tránsito
// *   - partidas: Array de partidas (max 999);
// *   - dsError: Estructura de error
// *
// * LÓGICA:
// *   1. SELECT de TTRAN donde:
// *      - tipo_documento IN ('DEP', 'TRF', 'CHQ');
// *      - fecha_documento < pFechaProceso (retraso);
// *      - estado != 'APLICADA'
// *   2. Calcular diasEnTransito = pFechaProceso - fecha_documento
// *   3. Retornar array de partidas
// *
// * ========================================================================
Dcl-Proc GLBLN_biz_IdentifyTransit EXPORT;
  dcl-PI *n LIKEDS(dsResultTransit);      
    pBanco        CHAR(2);
    pSucursal     CHAR(3);
    pMoneda       CHAR(3);
    pCuenta       CHAR(10);
    pFechaProceso DATE;
  end-PI;  

  dcl-ds lResult         LIKEDS(dsResultTransit) INZ;
  DCL-S  lNumDoc         VARCHAR(20);
  DCL-S  lTipoDoc        VARCHAR(20);
  DCL-S  lMonto          PACKED(18:2);
  DCL-S  lFechaDoc       DATE;
  DCL-S  lFechaApl       DATE;
  DCL-S  lEstado         VARCHAR(20);
  DCL-S  lDescr          VARCHAR(256);
  DCL-S  lDiasTransito   INT(10);  

  monitor; 
 
    EXEC SQL
      DECLARE lCursor CURSOR FOR
        SELECT DISTINCT
              numero_documento,
              tipo_documento,
              monto,
              fecha_documento,
              fecha_transaccion,
              estado_documento,
              descripcion_movimiento
        FROM TTRAN
        WHERE codigo_banco = :pBanco
          AND codigo_sucursal = :pSucursal
          AND codigo_moneda = :pMoneda
          AND cuenta_contable = :pCuenta
          AND tipo_documento IN ('DEP', 'TRF', 'CHQ')
          AND fecha_documento < :pFechaProceso
          AND estado_documento <> 'APLICADA'
        ORDER BY fecha_documento;

    lResult.rowCount = 0;
    lResult.dsError.errorStatus = 'S';

    EXEC SQL OPEN lCursor;

    EXEC SQL FETCH NEXT FROM lCursor INTO
              :lNumDoc, :lTipoDoc, :lMonto, :lFechaDoc, :lFechaApl,
              :lEstado, :lDescr;

    DOW SQLSTATE = '00000' AND lResult.rowCount < 999;

      lResult.rowCount += 1;

      // Generar ID único de partida
      lResult.partidas(lResult.rowCount).idPartida = 
      + '-' + %TRIM(lNumDoc);

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
                  'Pendiente ' + %TRIM(%CHAR(lDiasTransito)); + 
                  ' días. ' + %TRIM(lDescr);

      FETCH NEXT FROM lCursor INTO
                  :lNumDoc, :lTipoDoc, :lMonto, :lFechaDoc, :lFechaApl,
                  :lEstado, :lDescr;

    ENDDO;

    EXEC SQL CLOSE lCursor;

    IF SQLSTATE <> '00000' AND SQLSTATE <> '02000';
      lResult.dsError.errorCode = SQLSTATE;
      lResult.dsError.errorMsg = SQLERRMC;
      lResult.dsError.errorStatus = 'E';
    ELSE;
      lResult.dsError.errorStatus = 'S';
    ENDIF;

  on-error;
   lResult.dsError.errorStatus = 'E';
   lResult.dsError.errorCode = 'EXCP';
   lResult.dsError.errorMsg = 
             'Excepción no controlada en GLBLN_biz_IdentifyTransit'; 
  endmon;

  RETURN lResult;

END-PROC GLBLN_biz_IdentifyTransit;

// * ========================================================================
// * PROCEDURE 4: GLBLN_biz_CheckTolerance
// * ========================================================================
// * DESCRIPCIÓN:
// * Valida si una diferencia está dentro de la tolerancia permitida
// * y retorna indicador de éxito + severidad del incidente.
// *
// * PARÁMETROS DE ENTRADA:
// *   pDiferencia         - PACKED(18:2); - Diferencia neta
// *   pTolerancia         - PACKED(18:2); - Límite permitido
// *   pTransitCount       - INT(10:0); - Cantidad de partidas en tránsito
// *
// * PARÁMETROS DE SALIDA:
// *   Retorna CHAR(1);:
// *   - 'S': Dentro de tolerancia (OK);
// *   - 'A': Fuera de tolerancia pero con partidas (advertencia);
// *   - 'E': Fuera de tolerancia sin explicación (error);
// *
// * LÓGICA:
// *   1. Si ABS(diferencia); <= tolerancia:
// *      - Si CON partidas → Retornar 'A' (advertencia);
// *      - Si SIN partidas → Retornar 'S' (éxito);
// *   2. Si ABS(diferencia); > tolerancia:
// *      - Retornar 'E' (error);
// *
// * ========================================================================

Dcl-Proc GLBLN_biz_CheckTolerance EXPORT;
  dcl-PI *n CHAR(1);
    pDiferencia   PACKED(18:2);
    pTolerancia   PACKED(18:2);
    pTransitCount INT(10:0);
  end-PI;  

  dcl-s lDifAbsoluta    PACKED(18:2);
  dcl-s lResult         CHAR(1);

  lDifAbsoluta = %ABS(pDiferencia);

  // Dentro de tolerancia
  IF lDifAbsoluta <= pTolerancia;

    // Con partidas en tránsito
    IF pTransitCount > 0;
      lResult = 'A';  // Advertencia (partidas pendientes);
    ELSE;
      lResult = 'S';  // Éxito (conciliado);
    ENDIF;

  ELSE;
    // Fuera de tolerancia
    lResult = 'E';  // Error (diferencia significativa);

  ENDIF;

  RETURN lResult;

END-PROC GLBLN_biz_CheckTolerance;
