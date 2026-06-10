# README - Sistema de Conciliación GLBLN (IBM i SQLRPGLE)

## 🎯 Objetivo

Construir un proceso de reportería y control de estados financieros para cuentas mayores (GLBLN) en IBM i. El sistema consulta, procesa y concilia información financiera, generando salidas JSON trazables y auditoría completa.

---

## 📋 Características Principales

- **Consulta inteligente:** Lee cuentas mayores por banco, sucursal, moneda y rango
- **Cálculo de balance:** Saldos iniciales + movimientos históricos + movimientos del día
- **Determinación de estado:** Clasifica en CONCILIADA, PARCIAL, DIFERENCIA, ERROR
- **Partidas en tránsito:** Identifica depósitos, transferencias y cheques pendientes
- **Salida JSON:** Estructura robusta con metadata, ejecución, saldos, diferencias y controles
- **Auditoría trazable:** Registro completo de inicio/fin y cada incidente por ejecución
- **IFS integrado:** Publica archivos JSON en directorios parametrizables

---

## 🏗️ Arquitectura

### Capas de Procesamiento

```
┌─────────────────────────────────────┐
│ GLRPT001 (Orquestación Principal)   │
├─────────────────────────────────────┤
│ GLBLN_DB (Acceso a Datos)           │ ← GLBLN, TRANS, TTRAN, GLMST
│ GLBLN_BIZ (Lógica de Negocio)       │ ← Cálculos, Estados, Tolerancia
│ GLBLN_JSON (Serialización JSON)     │ ← Construcción de salida
│ SRV_AUDIT (Auditoría)               │ ← CONCEXC, CONCERR
└─────────────────────────────────────┘
```

### Módulos SQLRPGLE

| Módulo | Ubicación | Responsabilidad | Procedures |
|--------|-----------|-----------------|-----------|
| **GLBLN_DB** | qsrcmod | Acceso a datos | ReadByRange, GetBalance, GetTransactions, ValidateAccount |
| **GLBLN_BIZ** | qsrcmod | Lógica financiera | CalculateBalance, DetermineFiState, IdentifyTransit, CheckTolerance |
| **GLBLN_JSON** | qsrcmod | Construcción JSON | BuildMetadata, BuildExecution, BuildCuentas, BuildControlTotales, WriteToIFS |
| **SRV_AUDIT** | qsrcsrv | Auditoría | LogStart, LogEnd, LogIncident |

### Tablas de Soporte (SQLRPGLE DDL)

| Tabla | Ubicación | Propósito |
|-------|-----------|----------|
| **CONCPAR** | qsrcsql | Parámetros de ejecución |
| **CONCEXC** | qsrcsql | Log de ejecuciones |
| **CONCERR** | qsrcsql | Registro de incidentes |

---

## 🚀 Instalación

### Requisitos Previos

- IBM i (V7R3+)
- SQLRPGLE compiler
- Librería EARAUJOL1 (crear si no existe)
- Permiso de lectura en GLBLN, TRANS, TTRAN, GLMST
- Permiso de escritura en /home/EARAUJOL/builds/TallerGitHub/reportes (IFS)

### Pasos de Instalación

#### 1. Crear Librería
```
CRTLIB LIB(EARAUJOL1) TEXT('Taller GitHub Copilot')
```

#### 2. Compilar Tablas SQL
```
RUNSQL SQLFILE('qsrcsql/CONCPAR_CREATE.SQL')
RUNSQL SQLFILE('qsrcsql/CONCEXC_CREATE.SQL')
RUNSQL SQLFILE('qsrcsql/CONCERR_CREATE.SQL')
```

#### 3. Compilar Módulos (en orden)
```
CRTRPGMOD MODULE(EARAUJOL1/GLBLN_DB) SRCFILE(QSRCMOD) SRCMBR(GLBLN_DB)
CRTRPGMOD MODULE(EARAUJOL1/GLBLN_BIZ) SRCFILE(QSRCMOD) SRCMBR(GLBLN_BIZ)
CRTRPGMOD MODULE(EARAUJOL1/GLBLN_JSON) SRCFILE(QSRCMOD) SRCMBR(GLBLN_JSON)

CRTSRVPGM SRVPGM(EARAUJOL1/SRV_AUDIT) MODULE(EARAUJOL1/SRV_AUDIT) ...
```

#### 4. Compilar Programa Principal
```
CRTBNDRPG PGM(EARAUJOL1/GLRPT001) SRCFILE(QSRCPGM) SRCMBR(GLRPT001) ...
```

#### 5. Compilar Programas de Prueba
```
CRTBNDRPG PGM(EARAUJOL1/GLBLN_DB_TST) SRCFILE(QSRCPGM) SRCMBR(GLBLN_DB_TST) ...
CRTBNDRPG PGM(EARAUJOL1/GLBLN_BIZ_TST) SRCFILE(QSRCPGM) SRCMBR(GLBLN_BIZ_TST) ...
CRTBNDRPG PGM(EARAUJOL1/GLBLN_JSON_TST) SRCFILE(QSRCPGM) SRCMBR(GLBLN_JSON_TST) ...
CRTBNDRPG PGM(EARAUJOL1/SRV_AUDIT_TST) SRCFILE(QSRCPGM) SRCMBR(SRV_AUDIT_TST) ...
CRTBNDRPG PGM(EARAUJOL1/GLRPT001_TST) SRCFILE(QSRCPGM) SRCMBR(GLRPT001_TST) ...
```

---

## 📖 Guía de Uso

### Ejecutar Conciliación

```
CALL GLRPT001 PARM(
  '01'              /* Banco */
  '001'             /* Sucursal */
  'USD'             /* Moneda */
  '1100000001'      /* Cuenta Desde */
  '1199999999'      /* Cuenta Hasta */
  '2026-06-09'      /* Fecha Proceso */
  'P'               /* Modo: T=Test, P=Producción */
)
```

### Salida Esperada

**En Pantalla:**
```
Iniciando proceso de conciliación GLBLN
ID Ejecución: 20260609_120000_001
Banco: 01 Sucursal: 001 Moneda: USD
Rango cuentas: 1100000001 a 1199999999

========================================
RESUMEN DE EJECUCIÓN
========================================
ID Ejecución:          20260609_120000_001
Estado Final:          FINALIZADO

Total de Cuentas:      150
Cuentas Conciliadas:   134
Cuentas con Diferencia: 16
Errores Encontrados:   0

Sumatoria de Diferencias: 19.50

Hora Inicio:           2026-06-09T12:00:00
Hora Fin:              2026-06-09T12:03:42
========================================

✓ PROCESO COMPLETADO EXITOSAMENTE
```

**En IFS:**
```
/home/EARAUJOL/builds/TallerGitHub/reportes/20260609_120000_001.json
```

**En CONCEXC (Auditoría):**
```
ID_EJECUCION: 20260609_120000_001
USUARIO: USRFIN01
FECHA_HORA_INICIO: 2026-06-09T12:00:00
FECHA_HORA_FIN: 2026-06-09T12:03:42
TOTAL_CUENTAS_PROCESADAS: 150
TOTAL_CUENTAS_CONCILIADAS: 134
TOTAL_CUENTAS_CON_DIFERENCIA: 16
ESTADO_EJECUCION: FINALIZADO
```

---

## 🧪 Pruebas Unitarias

Ejecutar todas las pruebas:

```
CALL GLBLN_DB_TST      /* 9 test cases */
CALL GLBLN_BIZ_TST     /* 12 test cases */
CALL GLBLN_JSON_TST    /* 10 test cases */
CALL SRV_AUDIT_TST     /* 6 test cases */
CALL GLRPT001_TST      /* 7 test cases */
```

**Total: 44 test cases**

Esperado: Todos deben retornar `✓ TODAS LAS PRUEBAS PASARON`

---

## 📊 Estructura de Salida JSON

```json
{
  "metadata": {
    "versionEstructura": "1.0.0",
    "sistemaOrigen": "IBS-IBM-i",
    "proceso": "CONCILIACION_GLBLN",
    "ambiente": "QA",
    "charset": "UTF-8"
  },
  "ejecucion": {
    "idEjecucion": "20260609_120000_001",
    "fechaProceso": "2026-06-09",
    "fechaHoraInicio": "2026-06-09T12:00:00",
    "fechaHoraFin": "2026-06-09T12:03:42",
    "usuario": "USRFIN01",
    "programa": "GLRPT001",
    "libreria": "EARAUJOL1",
    "estadoEjecucion": "FINALIZADO"
  },
  "cuentas": [
    {
      "cuentaContable": "1100000001",
      "saldoInicial": 100000.00,
      "debitosPeriodo": 50000.00,
      "creditosPeriodo": 30000.00,
      "saldoFinalCalculado": 120000.00,
      "saldoFinalFuente": 120000.00,
      "diferenciaNeta": 0.00,
      "diferenciaAbsoluta": 0.00,
      "toleranciaPermitida": 1.00,
      "excedeTolerancia": false
    }
  ],
  "controlTotales": {
    "totalCuentasProcesadas": 150,
    "totalCuentasConciliadas": 134,
    "totalCuentasConDiferencia": 16,
    "sumatoriaSaldoFinalFuente": 12455000.25,
    "sumatoriaSaldoFinalConciliado": 12454980.75,
    "sumatoriaDiferenciaNeta": 19.50
  }
}
```

---

## 🔧 Troubleshooting

### Error: "Parámetros inválidos"
- Validar que Banco tenga exactamente 2 caracteres
- Validar que Sucursal tenga exactamente 3 caracteres
- Validar que Moneda tenga exactamente 3 caracteres
- Validar que Cuenta Desde <= Cuenta Hasta
- Validar que Modo sea 'T' o 'P'

### Error: "No se encontraron cuentas en el rango"
- Verificar que existan registros en GLBLN con el filtro especificado
- Validar fechas y rango de cuentas
- Verificar permisos de lectura en GLBLN

### Error: "No se pudo registrar inicio de ejecución"
- Verificar que tabla CONCEXC exista en EARAUJOL1
- Verificar permisos de INSERT en CONCEXC
- Verificar que usuario tenga autorización

### Archivo JSON no aparece en IFS
- Verificar ruta: /home/EARAUJOL/builds/TallerGitHub/reportes/
- Verificar permisos de escritura en directorio IFS
- Verificar que aplicación tenga permisos suficientes
- Revisar estado final de ejecución (FINALIZADO vs ERROR)

---

## 📞 Contacto y Soporte

**Proyecto:** Taller GitHub Copilot - Sistema de Conciliación GLBLN  
**Versión:** 1.0  
**Fecha:** 2026-06-09  
**Plataforma:** IBM i SQLRPGLE  
**Librería:** EARAUJOL1

---

## 📄 Licencia

Código desarrollado para fines educativos en el Taller GitHub Copilot.

---

**Última actualización:** 2026-06-09
