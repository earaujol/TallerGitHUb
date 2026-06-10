      * ========================================================================
      * MÓDULO: GLBLN_DB (Acceso a Datos - Cuentas Mayores)
      * ========================================================================
      * DESCRIPCIÓN:
      * Módulo SQLRPGLE con procedures para consultar y validar cuentas mayores
      * desde GLBLN, así como obtener balances y transacciones históricas.
      *
      * PROCEDURES:
      *   1. GLBLN_db_ReadByRange()      - Lee cuentas por filtros (CURSOR)
      *   2. GLBLN_db_GetBalance()       - Calcula balance (GLBLN + TRANS + TTRAN)
      *   3. GLBLN_db_GetTransactions()  - Lista transacciones (TRANS + TTRAN)
      *   4. GLBLN_db_ValidateAccount()  - Valida cuenta en GLBLN y GLMST
      *
      * PRINCIPIOS ARQUITECTÓNICOS:
      *   - Responsabilidad única: Acceso a datos desde tablas de negocio.
      *   - Desacoplamiento: No contiene lógica de negocio.
      *   - Manejo de errores: dsError con código/mensaje/status.
      *   - TRY/CATCH para excepciones no controladas.
      *   - Data structures con EXTNAME() para sincronización con BD.
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
      * DEFINICIÓN DE DATA STRUCTURES
      * ========================================================================

      * DS: Registro de GLBLN (sincronización automática)
     D dsGLBLN         DS EXTNAME('GLBLN') QUALIFIED INZ

      * DS: Registro de TRANS (históricas)
     D dsTRANS         DS EXTNAME('TRANS') QUALIFIED INZ

      * DS: Registro de TTRAN (transacciones del día)
     D dsTTRAN         DS EXTNAME('TTRAN') QUALIFIED INZ

      * DS: Registro de GLMST (maestro de cuentas contables)
     D dsGLMST         DS EXTNAME('GLMST') QUALIFIED INZ

      * DS: Estructura de Error Estándar
     D dsError         DS QUALIFIED
     D  errorCode        CHAR(5)
     D  errorMsg         VARCHAR(256)
     D  errorStatus      CHAR(1)

      * DS: Resultado de Lectura (GLBLN_ReadByRange)
     D dsResultGLBLN   DS QUALIFIED
     D  rowCount         INT(10:0)
     D  dataArray        LIKE(dsGLBLN) DIM(9999)
     D  dsError          LIKEDS(dsError)

      * DS: Estructura de Balance (GLBLN_GetBalance)
     D dsBalance       DS QUALIFIED
     D  cuenta           CHAR(10)
     D  saldoInicial     DECIMAL(18:2)
     D  debitosHistoricos DECIMAL(18:2)
     D  creditosHistoricos DECIMAL(18:2)
     D  saldoAnterior    DECIMAL(18:2)
     D  debitosDia       DECIMAL(18:2)
     D  creditosDia      DECIMAL(18:2)
     D  saldoFinal       DECIMAL(18:2)
     D  dsError          LIKEDS(dsError)

      * DS: Estructura de Transacción (GLBLN_GetTransactions)
     D dsTransaction   DS QUALIFIED
     D  tipoTransaccion  CHAR(1)
     D  numTransaccion   VARCHAR(20)
     D  fechaTransaccion DATE
     D  monto            DECIMAL(18:2)
     D  concepto         VARCHAR(100)
     D  origen           CHAR(10)

     D dsResultTransactions DS QUALIFIED
     D  rowCount         INT(10:0)
     D  transactions     LIKE(dsTransaction) DIM(9999)
     D  dsError          LIKEDS(dsError)

      * ========================================================================
      * VARIABLES LOCALES
      * ========================================================================

     D lIndex          S INT(10:0)
     D lRowCount       S INT(10:0)
     D lSQLCode        S INT(10:0)
     D lSQLState       S CHAR(5)
     D lSQLMsg         S VARCHAR(512)

      * ========================================================================
      * PROCEDURE 1: GLBLN_db_ReadByRange
      * ========================================================================
      * DESCRIPCIÓN:
      * Lee todas las cuentas mayores de GLBLN dentro de un rango de cuentas,
      * filtradas por banco, sucursal y moneda. Retorna array de registros.
      *
      * PARÁMETROS DE ENTRADA:
      *   pBanco              - CHAR(2)   - Código de banco
      *   pSucursal           - CHAR(3)   - Código de sucursal
      *   pMoneda             - CHAR(3)   - Código de moneda
      *   pCuentaDesde        - CHAR(10)  - Cuenta inicial del rango
      *   pCuentaHasta        - CHAR(10)  - Cuenta final del rango
      *   pFechaProceso       - DATE      - Fecha de corte
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - rowCount:  Cantidad de registros leídos
      *   - dataArray: Array con registros de GLBLN
      *   - dsError:   Estructura de error
      *
      * LÓGICA:
      *   1. Validar que pCuentaDesde <= pCuentaHasta
      *   2. Abrir CURSOR SELECT sobre GLBLN con filtros
      *   3. FETCH en loop hasta fin de datos
      *   4. Llenar array de resultado
      *   5. Manejar excepciones SQL
      *
      * ========================================================================

     P GLBLN_db_ReadByRange...
     P                 B EXPORT
     D                 PI LIKEDS(dsResultGLBLN)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuentaDesde  CHAR(10)
     D   pCuentaHasta  CHAR(10)
     D   pFechaProceso DATE

     D lResult         DS LIKEDS(dsResultGLBLN) INZ
     D lCursor         CURSOR FOR
     D   SELECT codigo_banco, codigo_sucursal, codigo_moneda,
     D          cuenta_contable, descripcion_cuenta, naturaleza_cuenta,
     D          nivel_cuenta, saldo_actual, fecha_proceso_sistema,
     D          estado_registro
     D     FROM GLBLN
     D    WHERE codigo_banco = :pBanco
     D      AND codigo_sucursal = :pSucursal
     D      AND codigo_moneda = :pMoneda
     D      AND cuenta_contable >= :pCuentaDesde
     D      AND cuenta_contable <= :pCuentaHasta
     D    ORDER BY cuenta_contable

     BEGIN

       lResult.rowCount = 0;
       lResult.dsError.errorStatus = 'S';

       TRY;

         // Validar parámetros
         IF pCuentaDesde > pCuentaHasta;
           lResult.dsError.errorCode = 'PARAM';
           lResult.dsError.errorMsg = 
             'Rango inválido: CuentaDesde > CuentaHasta';
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         // Abrir cursor
         OPEN lCursor;

         // FETCH en loop
         FETCH NEXT FROM lCursor INTO dsGLBLN;
         WHILE SQLSTATE = '00000' AND lResult.rowCount < 9999;

           lResult.rowCount += 1;
           lResult.dataArray(lResult.rowCount) = dsGLBLN;

           FETCH NEXT FROM lCursor INTO dsGLBLN;

         ENDWHILE;

         CLOSE lCursor;

         // Verificar si hubo error en FETCH
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
           'Excepción no controlada en GLBLN_db_ReadByRange';
       ENDTRY;

       RETURN lResult;

     END-PROC GLBLN_db_ReadByRange;

      * ========================================================================
      * PROCEDURE 2: GLBLN_db_GetBalance
      * ========================================================================
      * DESCRIPCIÓN:
      * Calcula el balance de una cuenta contable combinando:
      *   1. SALDO_INICIAL de GLBLN
      *   2. DEBITOS y CREDITOS de TRANS hasta fecha anterior
      *   3. Movimientos de TTRAN (día actual)
      *
      * PARÁMETROS DE ENTRADA:
      *   pBanco              - CHAR(2)   - Código de banco
      *   pSucursal           - CHAR(3)   - Código de sucursal
      *   pMoneda             - CHAR(3)   - Código de moneda
      *   pCuenta             - CHAR(10)  - Cuenta contable
      *   pFechaProceso       - DATE      - Fecha de corte
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - cuenta:              Cuenta consultada
      *   - saldoInicial:        De GLBLN
      *   - debitosHistoricos:   De TRANS (hasta fecha -1)
      *   - creditosHistoricos:  De TRANS (hasta fecha -1)
      *   - saldoAnterior:       Saldo al cierre del día anterior
      *   - debitosDia:          De TTRAN (día actual)
      *   - creditosDia:         De TTRAN (día actual)
      *   - saldoFinal:          Balance calculado
      *   - dsError:             Estructura de error
      *
      * LÓGICA:
      *   1. Obtener SALDO_INICIAL de GLBLN
      *   2. Sumar DEBITOS de TRANS < pFechaProceso
      *   3. Restar CREDITOS de TRANS < pFechaProceso
      *   4. Sumar DEBITOS de TTRAN = pFechaProceso
      *   5. Restar CREDITOS de TTRAN = pFechaProceso
      *   6. Calcular saldoFinal = saldoInicial + débitos - créditos
      *
      * ========================================================================

     P GLBLN_db_GetBalance...
     P                 B EXPORT
     D                 PI LIKEDS(dsBalance)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuenta       CHAR(10)
     D   pFechaProceso DATE

     D lResult         DS LIKEDS(dsBalance) INZ
     D lSaldoIni       DECIMAL(18:2)
     D lDebHistoricos  DECIMAL(18:2)
     D lCredHistoricos DECIMAL(18:2)
     D lDebDia         DECIMAL(18:2)
     D lCredDia        DECIMAL(18:2)

     BEGIN

       lResult.cuenta = pCuenta;
       lResult.dsError.errorStatus = 'S';

       TRY;

         // 1. Obtener saldo inicial de GLBLN
         EXEC SQL
           SELECT COALESCE(saldo_actual, 0)
             INTO :lSaldoIni
             FROM GLBLN
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta;

         IF SQLCODE <> 0 AND SQLCODE <> 100;
           lResult.dsError.errorCode = %CHAR(SQLCODE);
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         IF SQLCODE = 100;
           lSaldoIni = 0;
         ENDIF;

         lResult.saldoInicial = lSaldoIni;

         // 2. Sumar débitos históricos de TRANS (fecha < pFechaProceso)
         EXEC SQL
           SELECT COALESCE(SUM(CASE WHEN tipo_movimiento = 'D'
                                   THEN monto ELSE 0 END), 0)
             INTO :lDebHistoricos
             FROM TRANS
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta
              AND fecha_transaccion < :pFechaProceso;

         IF SQLCODE <> 0;
           lResult.dsError.errorCode = %CHAR(SQLCODE);
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         lResult.debitosHistoricos = lDebHistoricos;

         // 3. Restar créditos históricos de TRANS (fecha < pFechaProceso)
         EXEC SQL
           SELECT COALESCE(SUM(CASE WHEN tipo_movimiento = 'C'
                                   THEN monto ELSE 0 END), 0)
             INTO :lCredHistoricos
             FROM TRANS
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta
              AND fecha_transaccion < :pFechaProceso;

         IF SQLCODE <> 0;
           lResult.dsError.errorCode = %CHAR(SQLCODE);
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         lResult.creditosHistoricos = lCredHistoricos;

         // 4. Calcular saldo anterior
         lResult.saldoAnterior = lSaldoIni + lDebHistoricos - lCredHistoricos;

         // 5. Sumar débitos del día de TTRAN (fecha = pFechaProceso)
         EXEC SQL
           SELECT COALESCE(SUM(CASE WHEN tipo_movimiento = 'D'
                                   THEN monto ELSE 0 END), 0)
             INTO :lDebDia
             FROM TTRAN
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta
              AND fecha_transaccion = :pFechaProceso;

         IF SQLCODE <> 0;
           lResult.dsError.errorCode = %CHAR(SQLCODE);
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         lResult.debitosDia = lDebDia;

         // 6. Restar créditos del día de TTRAN (fecha = pFechaProceso)
         EXEC SQL
           SELECT COALESCE(SUM(CASE WHEN tipo_movimiento = 'C'
                                   THEN monto ELSE 0 END), 0)
             INTO :lCredDia
             FROM TTRAN
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta
              AND fecha_transaccion = :pFechaProceso;

         IF SQLCODE <> 0;
           lResult.dsError.errorCode = %CHAR(SQLCODE);
           lResult.dsError.errorMsg = SQLERRMC;
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         lResult.creditosDia = lCredDia;

         // 7. Calcular saldo final
         lResult.saldoFinal = lResult.saldoAnterior + lDebDia - lCredDia;

         lResult.dsError.errorStatus = 'S';

       CATCH;
         lResult.dsError.errorStatus = 'E';
         lResult.dsError.errorCode = 'EXCP';
         lResult.dsError.errorMsg = 
           'Excepción no controlada en GLBLN_db_GetBalance';
       ENDTRY;

       RETURN lResult;

     END-PROC GLBLN_db_GetBalance;

      * ========================================================================
      * PROCEDURE 3: GLBLN_db_GetTransactions
      * ========================================================================
      * DESCRIPCIÓN:
      * Retorna array de transacciones de una cuenta contable en un rango
      * de fechas, combinando registros de TRANS (históricas) y TTRAN (día).
      *
      * PARÁMETROS DE ENTRADA:
      *   pBanco              - CHAR(2)   - Código de banco
      *   pSucursal           - CHAR(3)   - Código de sucursal
      *   pMoneda             - CHAR(3)   - Código de moneda
      *   pCuenta             - CHAR(10)  - Cuenta contable
      *   pFechaDesde         - DATE      - Fecha inicial del rango
      *   pFechaHasta         - DATE      - Fecha final del rango
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - rowCount:      Cantidad de transacciones
      *   - transactions:  Array de transacciones
      *   - dsError:       Estructura de error
      *
      * LÓGICA:
      *   1. UNION: SELECT de TRANS + UNION de TTRAN
      *   2. Filtrar por banco, sucursal, moneda, cuenta, rango de fechas
      *   3. Ordenar por fecha y número de transacción
      *   4. FETCH en loop
      *
      * ========================================================================

     P GLBLN_db_GetTransactions...
     P                 B EXPORT
     D                 PI LIKEDS(dsResultTransactions)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuenta       CHAR(10)
     D   pFechaDesde   DATE
     D   pFechaHasta   DATE

     D lResult         DS LIKEDS(dsResultTransactions) INZ
     D lTipoTransac    CHAR(1)
     D lNumTransac     VARCHAR(20)
     D lFechaTransac   DATE
     D lMonto          DECIMAL(18:2)
     D lConcepto       VARCHAR(100)
     D lOrigen         CHAR(10)

     D lCursor         CURSOR FOR
     D   SELECT 'H' AS tipo_transaccion,
     D          numero_transaccion,
     D          fecha_transaccion,
     D          monto,
     D          concepto,
     D          'TRANS' AS origen
     D     FROM TRANS
     D    WHERE codigo_banco = :pBanco
     D      AND codigo_sucursal = :pSucursal
     D      AND codigo_moneda = :pMoneda
     D      AND cuenta_contable = :pCuenta
     D      AND fecha_transaccion >= :pFechaDesde
     D      AND fecha_transaccion <= :pFechaHasta
     D    UNION ALL
     D   SELECT 'D' AS tipo_transaccion,
     D          numero_documento,
     D          fecha_transaccion,
     D          monto,
     D          descripcion_movimiento,
     D          'TTRAN' AS origen
     D     FROM TTRAN
     D    WHERE codigo_banco = :pBanco
     D      AND codigo_sucursal = :pSucursal
     D      AND codigo_moneda = :pMoneda
     D      AND cuenta_contable = :pCuenta
     D      AND fecha_transaccion >= :pFechaDesde
     D      AND fecha_transaccion <= :pFechaHasta
     D    ORDER BY fecha_transaccion, numero_transaccion

     BEGIN

       lResult.rowCount = 0;
       lResult.dsError.errorStatus = 'S';

       TRY;

         // Validar parámetros
         IF pFechaDesde > pFechaHasta;
           lResult.dsError.errorCode = 'PARAM';
           lResult.dsError.errorMsg = 
             'Rango inválido: FechaDesde > FechaHasta';
           lResult.dsError.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         // Abrir cursor
         OPEN lCursor;

         // FETCH en loop
         FETCH NEXT FROM lCursor INTO 
           lTipoTransac, lNumTransac, lFechaTransac, lMonto,
           lConcepto, lOrigen;

         WHILE SQLSTATE = '00000' AND lResult.rowCount < 9999;

           lResult.rowCount += 1;

           lResult.transactions(lResult.rowCount).tipoTransaccion = 
             lTipoTransac;
           lResult.transactions(lResult.rowCount).numTransaccion = 
             lNumTransac;
           lResult.transactions(lResult.rowCount).fechaTransaccion = 
             lFechaTransac;
           lResult.transactions(lResult.rowCount).monto = 
             lMonto;
           lResult.transactions(lResult.rowCount).concepto = 
             lConcepto;
           lResult.transactions(lResult.rowCount).origen = 
             lOrigen;

           FETCH NEXT FROM lCursor INTO 
             lTipoTransac, lNumTransac, lFechaTransac, lMonto,
             lConcepto, lOrigen;

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
           'Excepción no controlada en GLBLN_db_GetTransactions';
       ENDTRY;

       RETURN lResult;

     END-PROC GLBLN_db_GetTransactions;

      * ========================================================================
      * PROCEDURE 4: GLBLN_db_ValidateAccount
      * ========================================================================
      * DESCRIPCIÓN:
      * Valida que una cuenta contable existe en GLBLN y en GLMST.
      *
      * PARÁMETROS DE ENTRADA:
      *   pBanco              - CHAR(2)   - Código de banco
      *   pSucursal           - CHAR(3)   - Código de sucursal
      *   pMoneda             - CHAR(3)   - Código de moneda
      *   pCuenta             - CHAR(10)  - Cuenta contable
      *
      * PARÁMETROS DE SALIDA:
      *   Retorna DS QUALIFIED con:
      *   - success:  Indicador TRUE/FALSE
      *   - dsError:  Estructura de error
      *
      * LÓGICA:
      *   1. Validar que existe en GLBLN
      *   2. Validar que existe en GLMST (maestro)
      *   3. Retornar success = TRUE solo si existe en ambas
      *
      * ========================================================================

     P GLBLN_db_ValidateAccount...
     P                 B EXPORT
     D                 PI LIKEDS(dsError)
     D   pBanco        CHAR(2)
     D   pSucursal     CHAR(3)
     D   pMoneda       CHAR(3)
     D   pCuenta       CHAR(10)

     D lResult         DS LIKEDS(dsError) INZ
     D lCountGLBLN     INT(10:0)
     D lCountGLMST     INT(10:0)

     BEGIN

       lResult.errorStatus = 'S';

       TRY;

         // 1. Verificar existencia en GLBLN
         EXEC SQL
           SELECT COUNT(*)
             INTO :lCountGLBLN
             FROM GLBLN
            WHERE codigo_banco = :pBanco
              AND codigo_sucursal = :pSucursal
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta;

         IF SQLCODE <> 0;
           lResult.errorCode = %CHAR(SQLCODE);
           lResult.errorMsg = 'Error consultando GLBLN: ' + SQLERRMC;
           lResult.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         // 2. Verificar existencia en GLMST (maestro de cuentas)
         EXEC SQL
           SELECT COUNT(*)
             INTO :lCountGLMST
             FROM GLMST
            WHERE codigo_banco = :pBanco
              AND codigo_moneda = :pMoneda
              AND cuenta_contable = :pCuenta;

         IF SQLCODE <> 0;
           lResult.errorCode = %CHAR(SQLCODE);
           lResult.errorMsg = 'Error consultando GLMST: ' + SQLERRMC;
           lResult.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         // 3. Validar que existe en ambas tablas
         IF lCountGLBLN = 0;
           lResult.errorCode = 'VAL01';
           lResult.errorMsg = 
             'Cuenta no encontrada en GLBLN: ' + pCuenta;
           lResult.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         IF lCountGLMST = 0;
           lResult.errorCode = 'VAL02';
           lResult.errorMsg = 
             'Cuenta no encontrada en GLMST: ' + pCuenta;
           lResult.errorStatus = 'E';
           RETURN lResult;
         ENDIF;

         lResult.errorStatus = 'S';

       CATCH;
         lResult.errorStatus = 'E';
         lResult.errorCode = 'EXCP';
         lResult.errorMsg = 
           'Excepción no controlada en GLBLN_db_ValidateAccount';
       ENDTRY;

       RETURN lResult;

     END-PROC GLBLN_db_ValidateAccount;
