# MANUAL OPERATIVO - Sistema de Conciliación GLBLN

**Documento:** Manual Operativo del Sistema  
**Fecha:** 2026-06-09  
**Versión:** 1.0  
**Plataforma:** IBM i SQLRPGLE  
**Auditor:** Taller GitHub Copilot

---

## Tabla de Contenidos

1. [Inicio Rápido](#inicio-rápido)
2. [Parámetros de Ejecución](#parámetros-de-ejecución)
3. [Procedimientos Operacionales](#procedimientos-operacionales)
4. [Monitoreo y Auditoría](#monitoreo-y-auditoría)
5. [Resolución de Problemas](#resolución-de-problemas)
6. [Checklist Operativo](#checklist-operativo)

---

## Inicio Rápido

### Ejecución Básica

```
CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1199999999' '20260609' 'T')
```

### Resultado Esperado

```
Iniciando proceso de conciliación GLBLN
ID Ejecución: 20260609_120000_001
...
✓ PROCESO COMPLETADO EXITOSAMENTE
```

### Archivo Generado

```
/home/EARAUJOL/builds/TallerGitHub/reportes/20260609_120000_001.json
```

---

## Parámetros de Ejecución

### Parámetro 1: Banco (CHAR(2))

**Descripción:** Código de banco  
**Formato:** Exactamente 2 caracteres numéricos  
**Ejemplos válidos:** '01', '02', '99'  
**Ejemplos inválidos:** '1' (1 carácter), '001' (3 caracteres), 'AB' (letras)

```
CALL GLRPT001 PARM('01' ...)
```

### Parámetro 2: Sucursal (CHAR(3))

**Descripción:** Código de sucursal  
**Formato:** Exactamente 3 caracteres numéricos  
**Ejemplos válidos:** '001', '100', '999'  
**Ejemplos inválidos:** '1' (1 carácter), '0001' (4 caracteres)

```
CALL GLRPT001 PARM(...'001'...)
```

### Parámetro 3: Moneda (CHAR(3))

**Descripción:** Código de moneda  
**Formato:** Exactamente 3 caracteres alfabéticos  
**Ejemplos válidos:** 'USD', 'EUR', 'MXN'  
**Ejemplos inválidos:** 'US' (2 caracteres), 'USDA' (4 caracteres)

```
CALL GLRPT001 PARM(...'USD'...)
```

### Parámetro 4: Cuenta Desde (CHAR(10))

**Descripción:** Inicio del rango de cuentas mayores  
**Formato:** Exactamente 10 caracteres (alfanuméricos)  
**Regla:** Debe ser <= Cuenta Hasta  
**Ejemplos válidos:** '1100000001', '1200000000'  
**Ejemplo con ceros:** '0000000001'

```
CALL GLRPT001 PARM(...'1100000001'...)
```

### Parámetro 5: Cuenta Hasta (CHAR(10))

**Descripción:** Fin del rango de cuentas mayores  
**Formato:** Exactamente 10 caracteres (alfanuméricos)  
**Regla:** Debe ser >= Cuenta Desde  
**Ejemplos válidos:** '1199999999', '1999999999'

```
CALL GLRPT001 PARM(...'1199999999'...)
```

### Parámetro 6: Fecha Proceso (DATE)

**Descripción:** Fecha de corte para conciliación  
**Formato:** YYYYMMDD (8 dígitos)  
**Ejemplos válidos:** '20260609', '20260630'  
**Nota:** Suele ser fecha del cierre contable o fin de mes

```
CALL GLRPT001 PARM(...'20260609'...)
```

### Parámetro 7: Modo (CHAR(1))

**Descripción:** Modo de ejecución  
**Valores válidos:**
- `'T'` = Test (sin publicar en producción)
- `'P'` = Producción (publicar resultados)

**Ejemplos válidos:** 'T', 'P'  
**Ejemplos inválidos:** 't' (minúscula), 'TEST', 'PROD'

```
CALL GLRPT001 PARM(...'T')  /* Test */
CALL GLRPT001 PARM(...'P')  /* Producción */
```

---

## Procedimientos Operacionales

### Procedimiento 1: Conciliación Diaria

**Objetivo:** Procesar conciliación de todas las cuentas al cierre del día.

**Pasos:**

1. **Determinar fecha de proceso:**
   ```
   Fecha de hoy: 2026-06-09
   ```

2. **Preparar parámetros:**
   ```
   Banco:        01 (principal)
   Sucursal:     001 (central)
   Moneda:       USD (moneda fuerte)
   Cuenta Desde: 1100000001 (inicio de activos)
   Cuenta Hasta: 1199999999 (fin de activos)
   Fecha:        20260609
   Modo:         P (producción)
   ```

3. **Ejecutar programa:**
   ```
   CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1199999999' '20260609' 'P')
   ```

4. **Validar resultado:**
   - ✓ Resumen mostrado en pantalla
   - ✓ Estado = FINALIZADO
   - ✓ Archivo JSON en IFS

5. **Revisar auditoría:**
   ```
   SELECT * FROM CONCEXC 
   WHERE ID_EJECUCION LIKE '20260609%'
   ORDER BY FECHA_CREACION DESC
   ```

---

### Procedimiento 2: Conciliación de Prueba

**Objetivo:** Validar sistema antes de ejecución en producción.

**Pasos:**

1. **Ejecutar en modo TEST:**
   ```
   CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1199999999' '20260609' 'T')
   ```

2. **Revisar pantalla:**
   - Verificar que no hay errores críticos
   - Validar contadores lógicos (total = conciliadas + con diferencia)
   - Revisar sumatoria de diferencias

3. **Inspeccionar JSON generado:**
   ```
   DSPF '/home/EARAUJOL/builds/TallerGitHub/reportes/20260609_*.json'
   ```

4. **Validar estructura JSON:**
   - ✓ Contiene metadata
   - ✓ Contiene ejecución con timestamps
   - ✓ Contiene array cuentas
   - ✓ Contiene controlTotales

5. **Si todo OK, ejecutar en PRODUCCIÓN**

---

### Procedimiento 3: Conciliación por Rango Específico

**Objetivo:** Procesar solo un grupo de cuentas (ej: una línea de negocio).

**Ejemplos:**

**Cuentas de Caja (1100000001-1100999999):**
```
CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1100999999' '20260609' 'P')
```

**Cuentas de Banco (1200000001-1200999999):**
```
CALL GLRPT001 PARM('01' '001' 'USD' '1200000001' '1200999999' '20260609' 'P')
```

**Cuentas de Inversiones (1300000001-1399999999):**
```
CALL GLRPT001 PARM('01' '001' 'USD' '1300000001' '1399999999' '20260609' 'P')
```

---

### Procedimiento 4: Ejecución Programada (Job Scheduler)

**Objetivo:** Automatizar la conciliación diaria.

**Crear entrada en QBATCH:**

```
SBMJOB CMD(CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1199999999' '20260609' 'P')) 
       JOB(GLBLN_CONC) 
       JOBQ(EARAUJOL1/QBATCH)
       SCDDATE(*DAILY)
       SCDTIME(020000)
       USER(EARAUJOL)
```

**Resultado:**
- Se ejecuta diariamente a las 02:00 AM
- Genera JSON con conciliación del día anterior
- Registra auditoría automáticamente

---

## Monitoreo y Auditoría

### Consultar Ejecuciones

**Ver todas las ejecuciones del día:**
```sql
SELECT ID_EJECUCION, 
       FECHA_HORA_INICIO, 
       FECHA_HORA_FIN, 
       ESTADO_EJECUCION,
       TOTAL_CUENTAS_PROCESADAS,
       TOTAL_CUENTAS_CONCILIADAS,
       TOTAL_CUENTAS_CON_DIFERENCIA
FROM CONCEXC 
WHERE DATE(FECHA_CREACION) = CURRENT_DATE
ORDER BY FECHA_CREACION DESC
```

### Consultar Incidentes

**Ver incidentes de una ejecución:**
```sql
SELECT SECUENCIA_INCIDENTE, 
       CODIGO_INCIDENTE,
       TIPO_INCIDENTE,
       SEVERIDAD,
       CUENTA_CONTABLE,
       MENSAJE
FROM CONCERR 
WHERE ID_EJECUCION = '20260609_120000_001'
ORDER BY SECUENCIA_INCIDENTE
```

**Ver incidentes críticos:**
```sql
SELECT ID_EJECUCION,
       CUENTA_CONTABLE,
       SEVERIDAD,
       MENSAJE
FROM CONCERR 
WHERE SEVERIDAD IN ('ALTA', 'CRITICA')
  AND DATE(FECHA_CREACION) = CURRENT_DATE
ORDER BY ID_EJECUCION DESC
```

### Validar Integridad JSON

**Verificar que archivo JSON existe:**
```
DSPLF '/home/EARAUJOL/builds/TallerGitHub/reportes/20260609_120000_001.json'
```

**Validar estructura JSON básica:**
- Contiene `metadata`
- Contiene `ejecucion`
- Contiene `cuentas[]`
- Contiene `controlTotales`

---

## Resolución de Problemas

### Problema 1: "ERROR: Parámetros inválidos"

**Causa:** Uno o más parámetros no cumplen validaciones.

**Validación checklist:**
- [ ] Banco = 2 caracteres: ej. '01'
- [ ] Sucursal = 3 caracteres: ej. '001'
- [ ] Moneda = 3 caracteres: ej. 'USD'
- [ ] Cuenta Desde <= Cuenta Hasta
- [ ] Modo = 'T' o 'P' (no minúsculas)
- [ ] Fecha válida: YYYYMMDD

**Corrección:**
```
CALL GLRPT001 PARM('01' '001' 'USD' '1100000001' '1199999999' '20260609' 'T')
```

---

### Problema 2: "ADVERTENCIA: No se encontraron cuentas en el rango"

**Causa:** GLBLN no contiene cuentas en el rango especificado.

**Investigación:**
```sql
SELECT COUNT(*) FROM GLBLN 
WHERE codigo_banco = '01'
  AND codigo_sucursal = '001'
  AND codigo_moneda = 'USD'
  AND cuenta_contable BETWEEN '1100000001' AND '1199999999'
```

**Acciones:**
- [ ] Verificar rango de cuentas correcto
- [ ] Verificar que GLBLN contiene datos
- [ ] Revisar filtros (banco, sucursal, moneda)

---

### Problema 3: "ERROR: No se pudo registrar inicio de ejecución"

**Causa:** Falla al insertar en CONCEXC.

**Investigación:**
```sql
SELECT * FROM EARAUJOL1.CONCEXC LIMIT 1
```

**Acciones:**
- [ ] Verificar tabla CONCEXC existe
- [ ] Verificar permisos INSERT en CONCEXC
- [ ] Revisar espacio disponible en BD
- [ ] Revisar job log para detalles SQL

---

### Problema 4: "Archivo JSON no aparece en IFS"

**Causa:** Error en escritura de archivo en IFS.

**Investigación:**
```
DSPLF '/home/EARAUJOL/builds/TallerGitHub/reportes/'
```

**Acciones:**
- [ ] Verificar directorio existe: `/home/EARAUJOL/builds/TallerGitHub/reportes/`
- [ ] Verificar permisos escritura (ls -la)
- [ ] Verificar espacio disponible (df)
- [ ] Revisar user de ejecución tiene permisos

**Crear directorio si no existe:**
```
MKDIR DIR('/home/EARAUJOL/builds/TallerGitHub/reportes')
CHMOD MODE('755') FILE('/home/EARAUJOL/builds/TallerGitHub/reportes')
```

---

### Problema 5: "Diferencias muy altas en saldos"

**Causa:** Tolerancia de 1.00 podría ser insuficiente o hay error de datos.

**Investigación:**
1. Revisar conciliación manual de cuenta
2. Consultar transacciones en TRANS y TTRAN
3. Identificar partidas en tránsito

**Consulta de transacciones:**
```sql
SELECT fecha_transaccion, 
       tipo_movimiento,
       monto
FROM TRANS 
WHERE codigo_banco = '01'
  AND cuenta_contable = '1100000001'
  AND fecha_transaccion = '2026-06-09'
ORDER BY fecha_transaccion DESC
```

**Consulta de partidas pendientes:**
```sql
SELECT numero_documento,
       tipo_documento,
       monto,
       fecha_documento,
       estado_documento
FROM TTRAN 
WHERE codigo_banco = '01'
  AND cuenta_contable = '1100000001'
  AND estado_documento <> 'APLICADA'
ORDER BY fecha_documento
```

---

## Checklist Operativo

### Pre-ejecución

- [ ] Validar fecha de proceso (debe ser fecha válida)
- [ ] Validar rango de cuentas (desde <= hasta)
- [ ] Confirmar que GLBLN tiene datos para el período
- [ ] Verificar directorio IFS tiene espacio disponible
- [ ] Revisar auditoría anterior (si aplica)

### Ejecución

- [ ] Ejecutar en modo TEST primero
- [ ] Validar que no hay errores en pantalla
- [ ] Revisar contadores: total = conciliadas + con diferencia + errores
- [ ] Si TEST OK, ejecutar en PRODUCCIÓN
- [ ] Validar archivo JSON se generó

### Post-ejecución

- [ ] Revisar resumen en pantalla
- [ ] Verificar estado = FINALIZADO
- [ ] Inspeccionar JSON en IFS
- [ ] Consultar CONCEXC para auditoría
- [ ] Revisar CONCERR si hay incidentes
- [ ] Archivar JSON si aplica

### Entrega

- [ ] Documentar ID de ejecución
- [ ] Guardar copia de JSON
- [ ] Notificar a usuariosfinal resultado
- [ ] Registrar en log operativo

---

## Contacto

**Responsable técnico:** Taller GitHub Copilot  
**Fecha:** 2026-06-09  
**Versión:** 1.0

---

**Última actualización:** 2026-06-09
