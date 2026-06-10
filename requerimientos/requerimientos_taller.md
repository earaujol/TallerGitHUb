# Requerimientos del Taller

## 1. Contexto
Este taller desarrollará un proceso de reportería y control de estados financieros para cuentas mayores registradas en la tabla GLBLN.

El objetivo principal es poder visualizar el balance de cada cuenta mayor y generar salidas estandarizadas en formato JSON, publicadas en la IFS de IBM i para consumo posterior por otros procesos o aplicaciones.

## 2. Objetivo General
Construir una solución en entorno IBM i que:
- Consulte y procese información financiera de cuentas mayores desde GLBLN.
- Controle y clasifique el estado financiero de cada cuenta.
- Genere reportería estructurada en JSON.
- Deposite archivos JSON en directorios IFS definidos.

## 3. Alcance Funcional
Incluye:
- Lectura de saldos y datos base de cuentas mayores desde GLBLN.
- Cálculo y presentación de balance por cuenta.
- Determinación de estado financiero por cuenta según reglas definidas en el taller.
- Generación de archivos JSON de salida en IFS.
- Registro de ejecución y trazabilidad del proceso.

No incluye:
- Interfaz gráfica web o móvil.
- Integración con sistemas externos en tiempo real.
- Modificación del modelo fuente de GLBLN fuera de ajustes necesarios para consulta.

## 4. Plataforma y Tecnologías
- Plataforma objetivo: IBM i.
- Lenguaje principal: SQLRPGLE.
- Artefactos esperados:
  - Programa principal SQLRPGLE.
  - Módulos RPGLE para separar responsabilidades.
  - Programas de servicio para utilidades reutilizables.
  - Objetos TXT para parametrización, documentación operativa o bitácoras auxiliares.
- Formato de salida: JSON.
- Medio de salida: IFS (Integrated File System) de IBM i.

## 5. Requerimientos Funcionales

### RF-01. Consulta de cuentas mayores
El sistema debe consultar las cuentas mayores desde GLBLN usando filtros configurables (banco, sucursal, moneda, rango de cuentas y fecha de proceso).

### RF-02. Cálculo de balance por cuenta
El sistema debe calcular y exponer el balance por cada cuenta mayor procesada.

### RF-03. Control de estados financieros
El sistema debe asignar un estado financiero a cada cuenta con base en reglas de negocio definidas para el taller.

### RF-04. Consolidación de resultados
El sistema debe consolidar en una estructura única de salida los datos de identificación de cuenta, balance calculado, estado financiero y metadatos de ejecución.

### RF-05. Generación de JSON
El sistema debe generar objetos JSON válidos con codificación UTF-8.

### RF-06. Publicación en IFS
El sistema debe escribir los JSON en una ruta IFS parametrizable, con nombre de archivo trazable (fecha, hora y/o identificador de corrida).

### RF-07. Trazabilidad y logging
El sistema debe registrar inicio, fin, total de cuentas procesadas, errores detectados y resultado final de cada ejecución.

### RF-08. Manejo de errores
El sistema debe capturar errores de lectura, procesamiento y escritura en IFS, registrarlos y continuar con estrategia definida (continuar o abortar según severidad).

## 6. Requerimientos No Funcionales

### RNF-01. Rendimiento
El proceso debe poder ejecutarse sobre volúmenes representativos de GLBLN dentro de una ventana operativa razonable para cierre o consulta periódica.

### RNF-02. Confiabilidad
Debe garantizarse integridad de la salida JSON y consistencia entre totales procesados y registros exportados.

### RNF-03. Mantenibilidad
La solución debe separarse en módulos y programas de servicio para facilitar cambios de reglas y reutilización.

### RNF-04. Seguridad
El proceso debe ejecutarse con perfiles autorizados para acceder a GLBLN y a rutas IFS de salida.

### RNF-05. Auditabilidad
Toda corrida debe quedar identificada con timestamp y estado final para revisión operativa.

## 7. Diseño Lógico Propuesto

### 7.1 Componentes
- Programa principal (orquestación):
  - Recibe parámetros.
  - Invoca módulos de consulta, negocio y salida.
- Módulo de acceso a datos:
  - Consulta GLBLN por criterios.
- Módulo de negocio:
  - Calcula balance y estado financiero.
- Programa de servicio de utilidades:
  - Formateo de importes, fechas, validaciones y utilitarios JSON.
- Módulo de salida:
  - Construcción y escritura de JSON en IFS.

### 7.2 Flujo de proceso
1. Cargar parámetros de ejecución.
2. Consultar GLBLN.
3. Procesar cada cuenta mayor.
4. Calcular balance y estado.
5. Construir payload JSON.
6. Escribir JSON en IFS.
7. Registrar bitácora y resumen.

## 8. Estructura de Salida JSON (Robusta para Conciliación)
Para conciliación de cuentas contables, la salida debe incluir no solo balance final, sino también detalle de movimientos, partidas conciliatorias, diferencias y controles de integridad.

### 8.1 Estructura objetivo

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
    "idEjecucion": "20260519_120000_001",
    "fechaProceso": "2026-05-19",
    "fechaHoraInicio": "2026-05-19T12:00:00",
    "fechaHoraFin": "2026-05-19T12:03:42",
    "usuario": "USRFIN01",
    "programa": "GLRPT001",
    "libreria": "TALLERLIB",
    "estadoEjecucion": "FINALIZADO"
  },
  "contexto": {
    "banco": "01",
    "sucursal": "001",
    "moneda": "USD",
    "periodo": {
      "anio": 2026,
      "mes": 5,
      "fechaCorte": "2026-05-19"
    },
    "rangoCuentas": {
      "desde": "11000000",
      "hasta": "11999999"
    }
  },
  "cuentas": [
    {
      "cuentaMayor": {
        "codigoBanco": "01",
        "codigoSucursal": "001",
        "codigoMoneda": "USD",
        "cuentaContable": "11010101",
        "descripcionCuenta": "CAJA GENERAL",
        "naturaleza": "DEUDORA",
        "nivelCuenta": 4,
        "centroCosto": "CC001"
      },
      "saldos": {
        "saldoInicial": 120000.00,
        "debitosPeriodo": 40000.00,
        "creditosPeriodo": 35000.00,
        "saldoFinalCalculado": 125000.00,
        "saldoFinalFuente": 125000.50,
        "saldoFinalConciliado": 125000.00
      },
      "resumenMovimientos": {
        "cantidadMovimientos": 98,
        "primerMovimiento": "2026-05-01T08:12:10",
        "ultimoMovimiento": "2026-05-19T11:58:44"
      },
      "partidasConciliatorias": [
        {
          "idPartida": "PC-0001",
          "tipo": "TRANSITO",
          "subtipo": "DEPOSITO_NO_APLICADO",
          "referencia": "DEP-884771",
          "fechaPartida": "2026-05-19",
          "monto": 500.50,
          "signo": "DEBITO",
          "estado": "PENDIENTE",
          "origen": "TTRAN",
          "observacion": "Pendiente de aplicación en mayor"
        }
      ],
      "diferencias": {
        "diferenciaNeta": 0.50,
        "diferenciaAbsoluta": 0.50,
        "toleranciaPermitida": 1.00,
        "excedeTolerancia": false,
        "motivoPrincipal": "Partida en tránsito"
      },
      "estadoConciliacion": {
        "codigo": "PARCIAL",
        "descripcion": "Conciliada con partidas pendientes",
        "severidad": "MEDIA",
        "requiereRevision": true
      },
      "trazabilidad": {
        "hashCuenta": "a734f9f5cbbf6b5d9f5d7a60b",
        "registrosFuente": {
          "glbln": 1,
          "trans": 98,
          "trdsc": 7,
          "ttran": 10
        }
      }
    }
  ],
  "controlTotales": {
    "totalCuentasProcesadas": 150,
    "totalCuentasConciliadas": 134,
    "totalCuentasConDiferencia": 16,
    "sumatoriaSaldoFinalFuente": 12455000.25,
    "sumatoriaSaldoFinalConciliado": 12454980.75,
    "sumatoriaDiferenciaNeta": 19.50
  },
  "incidentes": [
    {
      "codigo": "WARN-GL-002",
      "tipo": "VALIDACION",
      "cuentaContable": "11010101",
      "mensaje": "Diferencia menor dentro de tolerancia",
      "severidad": "BAJA"
    }
  ]
}
```

### 8.2 Reglas mínimas del JSON de conciliación
- Incluir un objeto por cuenta contable dentro de `cuentas`.
- Publicar saldos de origen, saldos calculados y saldo conciliado.
- Incluir `partidasConciliatorias` cuando exista diferencia.
- Marcar explícitamente `excedeTolerancia` y `requiereRevision`.
- Incluir `controlTotales` para cuadratura global del archivo.
- Registrar incidentes funcionales o técnicos para auditoría.

## 9. Parámetros de Ejecución (Sugeridos)
- Banco.
- Sucursal.
- Moneda.
- Rango de cuenta contable.
- Fecha de proceso.
- Ruta IFS de salida.
- Modo de ejecución (prueba/productivo).

## 10. Entregables del Taller
- Código fuente SQLRPGLE (programa principal).
- Módulos RPGLE.
- Programas de servicio.
- Objetos TXT de apoyo (parámetros/bitácoras/documentación técnica).
- Evidencia de JSON generados en IFS.
- Documento técnico de despliegue y ejecución.

## 11. Criterios de Aceptación
- Se procesa información de GLBLN sin errores críticos.
- Se calcula balance por cada cuenta mayor procesada.
- Se asigna estado financiero según reglas definidas.
- Se generan archivos JSON válidos y legibles.
- Los JSON quedan almacenados en la ruta IFS indicada.
- Se cuenta con log de ejecución y resumen final.
- Se cumple el estándar de desarrollo IBM i definido en la sección de lineamientos y validación.

## 12. Supuestos
- GLBLN contiene información consistente para cálculo de balance.
- Existen permisos en IBM i para lectura de base y escritura en IFS.
- El taller definirá catálogo final de estados financieros y reglas exactas.

## 13. Riesgos y Mitigaciones
- Riesgo: diferencias de calidad de datos en GLBLN.
  - Mitigación: validaciones previas y registro de inconsistencias.
- Riesgo: permisos insuficientes en IFS.
  - Mitigación: validación de permisos antes de ejecución productiva.
- Riesgo: cambios en reglas financieras durante el desarrollo.
  - Mitigación: centralizar reglas en módulo de negocio reusable.

## 14. Matriz de Trazabilidad JSON vs BD
Esta matriz define de forma explícita de dónde sale cada dato del JSON de conciliación y cómo se obtiene.

Leyenda de `Tipo de obtención`:
- `Directo`: proviene de una columna de la BD.
- `Derivado`: se calcula a partir de uno o más campos/tablas.
- `Generado`: lo produce el proceso (metadato técnico de ejecución).

| Campo JSON | Origen principal | Tipo de obtención | Regla/Observación |
|---|---|---|---|
| metadata.versionEstructura | N/A | Generado | Constante de versión del contrato JSON. |
| metadata.sistemaOrigen | N/A | Generado | Valor fijo del sistema emisor (IBS-IBM-i). |
| metadata.proceso | N/A | Generado | Código del proceso SQLRPGLE. |
| metadata.ambiente | Parámetro de ejecución | Generado | QA/UAT/PRD según job o parámetro. |
| metadata.charset | N/A | Generado | UTF-8 fijo para salida IFS. |
| ejecucion.idEjecucion | N/A | Generado | Timestamp + correlativo de corrida. |
| ejecucion.fechaProceso | Parámetro / GLBLN.fecha | Generado/Directo | Se define por parámetro; puede validarse contra datos procesados. |
| ejecucion.fechaHoraInicio | N/A | Generado | Marca de inicio del proceso. |
| ejecucion.fechaHoraFin | N/A | Generado | Marca de fin del proceso. |
| ejecucion.usuario | Job user IBM i | Generado | Usuario que ejecuta el job/programa. |
| ejecucion.programa | N/A | Generado | Nombre del programa principal SQLRPGLE. |
| ejecucion.libreria | N/A | Generado | Librería de ejecución. |
| ejecucion.estadoEjecucion | N/A | Generado | FINALIZADO/PARCIAL/ERROR según resultados. |
| contexto.banco | GLBLN.codigo_banco | Directo | Filtro y agrupación primaria. |
| contexto.sucursal | GLBLN.codigo_sucursal | Directo | Filtro y agrupación primaria. |
| contexto.moneda | GLBLN.codigo_moneda | Directo | Filtro y agrupación primaria. |
| contexto.periodo.anio | GLBLN.fecha / parámetro | Derivado | Extraído de fecha de proceso/corte. |
| contexto.periodo.mes | GLBLN.fecha / parámetro | Derivado | Extraído de fecha de proceso/corte. |
| contexto.periodo.fechaCorte | Parámetro | Generado | Fecha de corte oficial de conciliación. |
| contexto.rangoCuentas.desde | Parámetro | Generado | Límite inferior de cuenta contable. |
| contexto.rangoCuentas.hasta | Parámetro | Generado | Límite superior de cuenta contable. |
| cuentas[].cuentaMayor.codigoBanco | GLBLN.codigo_banco | Directo | Identificador de cuenta mayor. |
| cuentas[].cuentaMayor.codigoSucursal | GLBLN.codigo_sucursal | Directo | Identificador de cuenta mayor. |
| cuentas[].cuentaMayor.codigoMoneda | GLBLN.codigo_moneda | Directo | Identificador de cuenta mayor. |
| cuentas[].cuentaMayor.cuentaContable | GLBLN.cuenta_contable | Directo | Clave principal de cuenta mayor. |
| cuentas[].cuentaMayor.descripcionCuenta | GLMST.descripcion_cuenta | Directo/Derivado | Preferente de GLMST; si no existe, usar catálogo auxiliar. |
| cuentas[].cuentaMayor.naturaleza | GLMST.naturaleza_cuenta | Directo/Derivado | De GLMST o regla contable por prefijo de cuenta. |
| cuentas[].cuentaMayor.nivelCuenta | GLMST.nivel_cuenta | Directo/Derivado | De GLMST o derivado por longitud/código de cuenta. |
| cuentas[].cuentaMayor.centroCosto | GLMST/CCDSC | Directo/Derivado | Si no está en GLMST, mapear por tabla de centros de costo. |
| cuentas[].saldos.saldoInicial | GLBLN | Directo/Derivado | Tomar saldo de apertura o saldo previo al período. |
| cuentas[].saldos.debitosPeriodo | TRANS/TTRAN (debito_credito='D') | Derivado | Sumatoria de débitos en ventana de conciliación. |
| cuentas[].saldos.creditosPeriodo | TRANS/TTRAN (debito_credito='C') | Derivado | Sumatoria de créditos en ventana de conciliación. |
| cuentas[].saldos.saldoFinalCalculado | saldoInicial + débitos - créditos | Derivado | Cálculo contable del proceso. |
| cuentas[].saldos.saldoFinalFuente | GLBLN | Directo | Saldo final reportado por fuente contable. |
| cuentas[].saldos.saldoFinalConciliado | saldoFinalCalculado +/- partidas | Derivado | Resultado posterior a aplicación de partidas conciliatorias. |
| cuentas[].resumenMovimientos.cantidadMovimientos | TRANS/TTRAN | Derivado | Conteo de movimientos por cuenta/periodo. |
| cuentas[].resumenMovimientos.primerMovimiento | TRANS.fecha_operacion/hora_operacion | Derivado | Mínimo timestamp de movimiento. |
| cuentas[].resumenMovimientos.ultimoMovimiento | TRANS.fecha_operacion/hora_operacion | Derivado | Máximo timestamp de movimiento. |
| cuentas[].partidasConciliatorias[].idPartida | N/A | Generado | Identificador interno de partida conciliatoria. |
| cuentas[].partidasConciliatorias[].tipo | TRANS/TRDSC + reglas | Derivado | Clasificación: tránsito, ajuste, reverso, etc. |
| cuentas[].partidasConciliatorias[].subtipo | TRDSC.tipo_descripcion | Directo/Derivado | Subclasificación funcional. |
| cuentas[].partidasConciliatorias[].referencia | TRANS.referencia_externa | Directo | Referencia del movimiento/documento. |
| cuentas[].partidasConciliatorias[].fechaPartida | TRANS.fecha_operacion/fecha_valor | Directo | Fecha de la partida detectada. |
| cuentas[].partidasConciliatorias[].monto | TRANS.monto | Directo | Monto de partida conciliatoria. |
| cuentas[].partidasConciliatorias[].signo | TRANS.debito_credito | Directo | D/C para efecto en conciliación. |
| cuentas[].partidasConciliatorias[].estado | Reglas del proceso | Derivado | PENDIENTE/APLICADA/REVERSADA. |
| cuentas[].partidasConciliatorias[].origen | TRANS/TTRAN/TRDSC | Derivado | Tabla fuente dominante. |
| cuentas[].partidasConciliatorias[].observacion | TRDSC.texto_descripcion/observaciones | Directo/Derivado | Detalle legible para auditoría. |
| cuentas[].diferencias.diferenciaNeta | saldoFuente - saldoConciliado | Derivado | Diferencia algebraica. |
| cuentas[].diferencias.diferenciaAbsoluta | abs(diferenciaNeta) | Derivado | Valor absoluto de diferencia. |
| cuentas[].diferencias.toleranciaPermitida | Parámetro | Generado | Umbral permitido por políticas del taller. |
| cuentas[].diferencias.excedeTolerancia | Comparación diferencia vs tolerancia | Derivado | Boolean de control. |
| cuentas[].diferencias.motivoPrincipal | Reglas + partidas | Derivado | Causa principal detectada. |
| cuentas[].estadoConciliacion.codigo | Reglas del proceso | Derivado | CONCILIADA/PARCIAL/NO_CONCILIADA. |
| cuentas[].estadoConciliacion.descripcion | Reglas del proceso | Derivado | Texto explicativo del estado. |
| cuentas[].estadoConciliacion.severidad | Reglas del proceso | Derivado | BAJA/MEDIA/ALTA/CRITICA. |
| cuentas[].estadoConciliacion.requiereRevision | Reglas del proceso | Derivado | true si hay excepción o diferencia relevante. |
| cuentas[].trazabilidad.hashCuenta | N/A | Generado | Hash de campos críticos para integridad. |
| cuentas[].trazabilidad.registrosFuente.glbln | GLBLN | Derivado | Conteo de filas GLBLN usadas para esa cuenta. |
| cuentas[].trazabilidad.registrosFuente.trans | TRANS | Derivado | Conteo de transacciones históricas leídas. |
| cuentas[].trazabilidad.registrosFuente.trdsc | TRDSC | Derivado | Conteo de descripciones relacionadas. |
| cuentas[].trazabilidad.registrosFuente.ttran | TTRAN | Derivado | Conteo de transacciones del día leídas. |
| controlTotales.totalCuentasProcesadas | Agregación de cuentas[] | Derivado | Conteo total de cuentas consideradas. |
| controlTotales.totalCuentasConciliadas | Agregación de estadoConciliacion | Derivado | Conteo por estado CONCILIADA. |
| controlTotales.totalCuentasConDiferencia | Agregación de diferencias | Derivado | Conteo de cuentas con diferencia != 0. |
| controlTotales.sumatoriaSaldoFinalFuente | Agregación de saldos.saldoFinalFuente | Derivado | Suma total de saldos fuente. |
| controlTotales.sumatoriaSaldoFinalConciliado | Agregación de saldos.saldoFinalConciliado | Derivado | Suma total de saldos conciliados. |
| controlTotales.sumatoriaDiferenciaNeta | Agregación de diferencias.diferenciaNeta | Derivado | Cuadratura global del proceso. |
| incidentes[].codigo | N/A | Generado | Código de incidente de negocio/técnico. |
| incidentes[].tipo | N/A | Generado | VALIDACION, DATOS, IFS, EJECUCION, etc. |
| incidentes[].cuentaContable | GLBLN/TRANS | Directo/Derivado | Cuenta afectada por incidente. |
| incidentes[].mensaje | N/A | Generado | Mensaje descriptivo para auditoría. |
| incidentes[].severidad | Reglas del proceso | Derivado | BAJA/MEDIA/ALTA/CRITICA. |

### 14.1 Validaciones recomendadas para el taller
- Validar que cada `cuentaContable` del JSON exista en GLBLN para la fecha de corte.
- Validar que `sumatoriaDiferenciaNeta` sea consistente con la suma de diferencias por cuenta.
- Validar que todo incidente de severidad `ALTA` o `CRITICA` marque la ejecución como `PARCIAL` o `ERROR`.
- Validar consistencia de moneda y banco entre GLBLN y movimientos TRANS/TTRAN.

## 15. Lineamientos de Desarrollo IBM i y Puntos de Validación
Esta sección define los lineamientos obligatorios que deben cumplirse durante el desarrollo del taller.

### 15.1 Principios SOLID en Arquitectura de Software IBM i
Lineamiento:
- Aplicar SRP en programas SQLRPGLE y módulos (una responsabilidad por componente).
- Aplicar OCP mediante extensibilidad de reglas sin modificar lógica central.
- Aplicar LSP en contratos de procedimientos y programas de servicio.
- Aplicar ISP separando interfaces/prototipos por contexto funcional.
- Aplicar DIP para desacoplar lógica de negocio de acceso a datos/IFS.

Validación:
- Existe separación explícita entre orquestación, negocio, acceso a datos y salida JSON.
- Programas de servicio exponen contratos claros y reutilizables.
- Cambios de reglas de conciliación no requieren reescritura total del programa principal.

### 15.2 Arquitectura de Software IBM i
Lineamiento:
- Definir arquitectura modular basada en SQLRPGLE + módulos + programas de servicio.
- Separar capa de acceso (GLBLN/TRANS/TTRAN), capa de reglas y capa de publicación (IFS JSON).
- Diseñar flujo batch auditable y trazable por ejecución.

Validación:
- Existe diagrama lógico de componentes y flujo de proceso.
- Cada componente tiene propósito y límites bien documentados.
- La publicación a IFS está encapsulada en componente dedicado.

### 15.3 Código Limpio
Lineamiento:
- Mantener procedimientos cortos, cohesivos y legibles.
- Evitar duplicación de lógica (DRY).
- Evitar bloques monolíticos y condicionales complejos sin encapsulación.
- Mantener comentarios útiles y no redundantes.

Validación:
- No existen rutinas gigantes con múltiples responsabilidades.
- Las reglas de conciliación están encapsuladas por función/procedimiento.
- El código cumple formato y convenciones internas acordadas.

### 15.4 Automatización de Pruebas y Documentación
Lineamiento:
- Automatizar pruebas unitarias y de integración del flujo de conciliación.
- Validar esquema JSON de salida en cada ejecución de pruebas.
- Mantener documentación técnica y funcional actualizada.

Validación:
- Existe evidencia de ejecución de pruebas automatizadas.
- Existe evidencia de validación estructural del JSON.
- README/documentación incluyen setup, ejecución y troubleshooting.

### 15.5 Refactorización de Código
Lineamiento:
- Refactorizar de forma incremental para mejorar mantenibilidad sin cambiar comportamiento funcional.
- Priorizar eliminación de deuda técnica en componentes críticos.
- Asegurar que toda refactorización esté protegida por pruebas.

Validación:
- Se documentan mejoras de diseño/refactor en cada iteración.
- No hay regresiones funcionales después de cambios estructurales.
- Se evidencia trazabilidad entre refactor y resultado de pruebas.

### 15.6 Adecuada Nomenclatura y Estándar de Nombres
Lineamiento:
- Definir y respetar estándar de nombres para programas, módulos, procedimientos, variables y objetos IFS.
- Usar nombres semánticos orientados a dominio contable/conciliación.
- Evitar abreviaturas ambiguas no documentadas.

Validación:
- Existe convención formal de nomenclatura en la documentación.
- Nombres de componentes permiten identificar su responsabilidad sin ambigüedad.
- Los objetos JSON y archivos IFS siguen patrón de nombre trazable por ejecución.

### 15.7 Checklist de Cumplimiento Obligatorio
- [ ] Cumple principios SOLID aplicados al diseño IBM i.
- [ ] Cumple arquitectura modular IBM i (programa principal, módulos, servicios).
- [ ] Cumple criterios de código limpio.
- [ ] Cumple automatización de pruebas y documentación actualizada.
- [ ] Cumple estrategia de refactorización controlada.
- [ ] Cumple estándar de nomenclatura y naming convention.
