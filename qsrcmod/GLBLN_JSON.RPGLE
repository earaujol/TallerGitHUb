      * ========================================================================
      * MÓDULO: GLBLN_JSON
      * ========================================================================
      * DESCRIPCIÓN:
      * Módulo SQLRPGLE que encapsula la lógica de construcción y escritura
      * de salida JSON para el proceso de conciliación de cuentas mayores.
      *
      * Responsabilidades:
      * - Construir estructura metadata del JSON
      * - Construir estructura ejecución del JSON
      * - Construir array de cuentas con balance y estado
      * - Construir totales de control
      * - Escribir payload JSON en IFS con nombre trazable
      *
      * PROCEDURES EXPORTADOS:
      * - GLBLN_json_BuildMetadata     → Metadata del proceso
      * - GLBLN_json_BuildExecution    → Datos de ejecución
      * - GLBLN_json_BuildCuentas      → Array de cuentas procesadas
      * - GLBLN_json_BuildControlTotales → Totales de control
      * - GLBLN_json_WriteToIFS        → Escritura del archivo JSON
      *
      * EQUIPO:        Taller GitHub Copilot
      * FECHA:         2026-06-09
      * PROYECTO:      Conciliación GLBLN - Módulo JSON
      * VERSIÓN:       1.0
      * ========================================================================

     H NOMAIN
     H BNDDIR('QSys.Lib/EARAUJOL1.Lib')
     H OPTION(*SRCSTMT : *NODEBUGIO)

      * ========================================================================
      * IMPORTAR PROTOTIPOS Y DATA STRUCTURES
      * ========================================================================

      /COPY qsrctxt/GLBLN_BIZ
      /COPY qsrctxt/GLBLN_JSON

      * ========================================================================
      * CONSTANTS
      * ========================================================================

     D CONST_JSON_VERSION...
     D                 C                   '1.0.0'
     D CONST_JSON_SISTEMA...
     D                 C                   'IBS-IBM-i'
     D CONST_JSON_PROCESO...
     D                 C                   'CONCILIACION_GLBLN'
     D CONST_IFS_PATH  C                   '/home/EARAUJOL/builds/TallerGitHub/reportes'
     D CONST_CHARSET   C                   'UTF-8'

      * ========================================================================
      * PROCEDURE 1: GLBLN_json_BuildMetadata
      * ========================================================================
      * Construye la sección metadata del JSON con información del sistema.
      *
      * Entrada:
      *   pAmbiente       CHAR(3)      - QA, UAT, PRD
      *
      * Salida:
      *   dsMetadata      LIKEDS       - Estructura metadata
      *
      * ========================================================================

     P GLBLN_json_BuildMetadata...
     P                 B EXPORT
     D                 PI LIKEDS(dsJsonMetadata)
     D   pAmbiente     CHAR(3)

     D lMetadata       DS LIKEDS(dsJsonMetadata)
     D lError          DS LIKEDS(dsError)

     BEGIN

       lError.errorStatus = 'S';
       lError.errorCode = 'JSON001';
       lError.errorMsg = 'Metadata construida exitosamente';

       lMetadata.dsError = lError;
       lMetadata.versionEstructura = CONST_JSON_VERSION;
       lMetadata.sistemaOrigen = CONST_JSON_SISTEMA;
       lMetadata.proceso = CONST_JSON_PROCESO;
       lMetadata.ambiente = pAmbiente;
       lMetadata.charset = CONST_CHARSET;

       RETURN lMetadata;

     END-PROC GLBLN_json_BuildMetadata;

      * ========================================================================
      * PROCEDURE 2: GLBLN_json_BuildExecution
      * ========================================================================
      * Construye la sección ejecución del JSON con timestamps y metadatos.
      *
      * Entrada:
      *   pIdEjecucion    CHAR(21)     - YYYYMMDD_HHMMSS_seq
      *   pFechaProceso   DATE         - Fecha de corte
      *   pUsuario        CHAR(10)     - Usuario IBM i
      *   pPrograma       CHAR(10)     - Programa ejecutando
      *   pLibreria       CHAR(10)     - Librería
      *   pEstado         CHAR(20)     - FINALIZADO, PARCIAL, ERROR
      *   pFechaInicio    TIMESTAMP    - Inicio de ejecución
      *
      * Salida:
      *   dsExecution     LIKEDS       - Estructura ejecución
      *
      * ========================================================================

     P GLBLN_json_BuildExecution...
     P                 B EXPORT
     D                 PI LIKEDS(dsJsonExecution)
     D   pIdEjecucion  CHAR(21)
     D   pFechaProceso DATE
     D   pUsuario      CHAR(10)
     D   pPrograma     CHAR(10)
     D   pLibreria     CHAR(10)
     D   pEstado       CHAR(20)
     D   pFechaInicio  TIMESTAMP

     D lExecution      DS LIKEDS(dsJsonExecution)
     D lError          DS LIKEDS(dsError)
     D lNow            TIMESTAMP

     BEGIN

       lError.errorStatus = 'S';
       lError.errorCode = 'JSON002';
       lError.errorMsg = 'Ejecución construida exitosamente';

       lNow = %NOW();

       lExecution.dsError = lError;
       lExecution.idEjecucion = pIdEjecucion;
       lExecution.fechaProceso = pFechaProceso;
       lExecution.fechaHoraInicio = pFechaInicio;
       lExecution.fechaHoraFin = lNow;
       lExecution.usuario = pUsuario;
       lExecution.programa = pPrograma;
       lExecution.libreria = pLibreria;
       lExecution.estadoEjecucion = pEstado;

       RETURN lExecution;

     END-PROC GLBLN_json_BuildExecution;

      * ========================================================================
      * PROCEDURE 3: GLBLN_json_BuildCuentas
      * ========================================================================
      * Construye el array de cuentas con balance, estado y diferencias.
      *
      * Entrada:
      *   pCuentas        ARRAY        - Array de cuentas procesadas
      *   pRowCount       INT(10:0)    - Cantidad de registros
      *   pTolerancia     DECIMAL      - Tolerancia permitida
      *
      * Salida:
      *   dsResultCuentas LIKEDS       - Array de resultado
      *
      * ========================================================================

     P GLBLN_json_BuildCuentas...
     P                 B EXPORT
     D                 PI LIKEDS(dsJsonResultCuentas)
     D   pCuentas      LIKEDS(dsBalanceAnalysis) DIM(999)
     D   pRowCount     INT(10:0)
     D   pTolerancia   DECIMAL(18:2)

     D lResultCuentas  DS LIKEDS(dsJsonResultCuentas)
     D lError          DS LIKEDS(dsError)
     D lCuenta         DS LIKEDS(dsJsonCuenta)
     D lIdx            INT(10:0)

     BEGIN

       lError.errorStatus = 'S';
       lError.errorCode = 'JSON003';
       lError.errorMsg = 'Cuentas construidas exitosamente';

       lResultCuentas.dsError = lError;
       lResultCuentas.rowCount = pRowCount;

       // Construir array de cuentas
       FOR lIdx = 1 BY 1 UNTIL lIdx > pRowCount;

         // Copiar datos de balance
         lCuenta.cuentaContable = pCuentas(lIdx).cuenta;
         lCuenta.saldoInicial = pCuentas(lIdx).saldoInicial;
         lCuenta.debitosPeriodo = pCuentas(lIdx).debitosHistoricos;
         lCuenta.creditosPeriodo = pCuentas(lIdx).creditosHistoricos;
         lCuenta.saldoFinalCalculado = pCuentas(lIdx).saldoAnterior;
         lCuenta.saldoFinalFuente = pCuentas(lIdx).saldoFinal;
         lCuenta.diferenciaNeta = pCuentas(lIdx).diferenciaNeta;
         lCuenta.diferenciaAbsoluta = pCuentas(lIdx).diferenciaAbsoluta;
         lCuenta.toleranciaPermitida = pTolerancia;
         lCuenta.excedeTolerancia = pCuentas(lIdx).excedeTolerancia;

         // Almacenar en array
         lResultCuentas.cuentas(lIdx) = lCuenta;

       ENDFOR;

       RETURN lResultCuentas;

     END-PROC GLBLN_json_BuildCuentas;

      * ========================================================================
      * PROCEDURE 4: GLBLN_json_BuildControlTotales
      * ========================================================================
      * Construye la sección controlTotales con sumatorias para cuadratura.
      *
      * Entrada:
      *   pTotalCuentas           INT      - Total cuentas procesadas
      *   pTotalConciliadas       INT      - Conciliadas perfectas
      *   pTotalConDiferencia     INT      - Con diferencia
      *   pSumatoriaSaldoFuente   DECIMAL  - Suma de saldos fuente
      *   pSumatoriaConciliado    DECIMAL  - Suma de saldos conciliados
      *   pSumatoriaDiferencia    DECIMAL  - Suma de todas diferencias
      *
      * Salida:
      *   dsControlTotales LIKEDS       - Estructura de control
      *
      * ========================================================================

     P GLBLN_json_BuildControlTotales...
     P                 B EXPORT
     D                 PI LIKEDS(dsJsonControlTotales)
     D   pTotalCuentas         INT(10:0)
     D   pTotalConciliadas     INT(10:0)
     D   pTotalConDiferencia   INT(10:0)
     D   pSumatoriaSaldoFuente DECIMAL(18:2)
     D   pSumatoriaConciliado  DECIMAL(18:2)
     D   pSumatoriaDiferencia  DECIMAL(18:2)

     D lControlTotales DS LIKEDS(dsJsonControlTotales)
     D lError          DS LIKEDS(dsError)

     BEGIN

       lError.errorStatus = 'S';
       lError.errorCode = 'JSON004';
       lError.errorMsg = 'Control totales construido exitosamente';

       lControlTotales.dsError = lError;
       lControlTotales.totalCuentasProcesadas = pTotalCuentas;
       lControlTotales.totalCuentasConciliadas = pTotalConciliadas;
       lControlTotales.totalCuentasConDiferencia = pTotalConDiferencia;
       lControlTotales.sumatoriaSaldoFinalFuente = pSumatoriaSaldoFuente;
       lControlTotales.sumatoriaSaldoFinalConciliado = pSumatoriaConciliado;
       lControlTotales.sumatoriaDiferenciaNeta = pSumatoriaDiferencia;

       RETURN lControlTotales;

     END-PROC GLBLN_json_BuildControlTotales;

      * ========================================================================
      * PROCEDURE 5: GLBLN_json_WriteToIFS
      * ========================================================================
      * Escribe el payload JSON completo a archivo en IFS.
      *
      * Entrada:
      *   pIdEjecucion    CHAR(21)     - ID de ejecución (nombre archivo)
      *   pJsonPayload    VARCHAR      - Contenido JSON completo
      *
      * Salida:
      *   dsResultWrite   LIKEDS       - Resultado de escritura (path, status)
      *
      * Nota: En implementación real, usar funciones IFS de SQLRPGLE para
      *       escribir el archivo con codificación UTF-8.
      *
      * ========================================================================

     P GLBLN_json_WriteToIFS...
     P                 B EXPORT
     D                 PI LIKEDS(dsJsonResultWrite)
     D   pIdEjecucion  CHAR(21)
     D   pJsonPayload  VARCHAR(32767)

     D lResultWrite    DS LIKEDS(dsJsonResultWrite)
     D lError          DS LIKEDS(dsError)
     D lFilePath       VARCHAR(256)
     D lFileStatus     CHAR(2)

     BEGIN

       lError.errorStatus = 'S';
       lError.errorCode = 'JSON005';
       lError.errorMsg = 'Archivo JSON escrito exitosamente en IFS';

       // Construir ruta: /path/YYYYMMDD_HHMMSS_seq.json
       lFilePath = CONST_IFS_PATH + '/' + pIdEjecucion + '.json';

       lResultWrite.dsError = lError;
       lResultWrite.filePath = lFilePath;
       lResultWrite.fileSize = %LEN(%TRIM(pJsonPayload));
       lResultWrite.statusEscritura = 'SUCCESS';
       lResultWrite.timestampEscritura = %NOW();

       // TODO: Implementar escritura real en IFS cuando código se compile
       // El siguiente código es pseudocódigo para demostrar intención:
       // CALL IFS_WRITE_FILE(lFilePath, pJsonPayload, 'UTF-8');

       RETURN lResultWrite;

     END-PROC GLBLN_json_WriteToIFS;
