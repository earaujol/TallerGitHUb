# Reglas de Arquitectura - Taller IBM i

## 1. Objetivo
Lineamientos e arquitectura para el taller y así asegurar calidad tecnica, mantenibilidad, trazabilidad y cumplimiento funcional.

Esta guia define:
- Que lineamientos debe seguir un agente.

## 2. Alcance
Aplica a todos los proyectos del taller que incluyan:
- Componentes IBM i (SQLRPGLE, modulos, programas de servicio, salida JSON en IFS).
- Documentacion tecnica y evidencia de pruebas.

## 3. Obligatorio de Cumplimiento

### 3.1 Principios SOLID en arquitectura IBM i
- SRP: cada programa/modulo tiene una responsabilidad clara.
- OCP: reglas de negocio extensibles sin romper nucleo.
- LSP: procedimientos intercambiables sin romper contrato.
- ISP: contratos separados por contexto funcional.
- DIP: negocio desacoplado de acceso a datos/IFS.
- La logica de negocio y salida IFS deben estar fuertemente desacopladas.

Entregables minima:
- Mapa de componentes y responsabilidades.
- Identificacion de contratos de servicio.

### 3.2 Arquitectura de software IBM i
Debe existir una arquitectura modular clara:
- Programa principal de orquestacion.
- Módulos separados para acceso a datos, negocio y salida JSON.
- Los programas de servicio encapsulan utilidades reutilizables.
- El flujo batch es trazable por id de ejecucion.

Entregables minima:
- Diagrama/logica de flujo.
- Estructura de objetos y responsabilidades.


### 3.3 Codigo limpio
- Procedimientos cortos y legibles.
- Nula o baja duplicacion de logica (DRY).
- Complejidad ciclomatica razonable.
- Comentarios utiles y consistentes.

Evidencia minima:
- Muestras de modulos clave.
- Resultado de formateo/linter si aplica.


### 3.4 Automatizacion de pruebas y documentacion
- Pruebas unitarias de reglas clave de conciliacion.
- Pruebas de integracion del flujo principal.
- Validacion estructural del JSON de salida.
- Documentacion de ejecucion y troubleshooting.

Evidencia minima:
- Reporte de pruebas con resultado.
- Ejemplo de JSON validado.
- README actualizado.


### 3.5 Refactorizacion de codigo
- Mejoras incrementales sin romper funcionalidad.
- Reduccion de deuda tecnica.
- Cambios respaldados por pruebas.

Evidencia minima:
- Registro de cambios/refactor.
- Comparacion antes/despues en areas criticas.

### 3.6 Nomenclatura y estandar de nombres
- Convenciones de nombres documentadas.
- Nombres semanticos en programas, modulos, procedimientos y variables.
- Patron consistente para archivos JSON y objetos IFS.

Evidencia minima:
- Seccion de convenciones en documentacion.
- Muestra de nombres de objetos/codigo.

## 4. Funcionales Minimas (JSON y Conciliacion)
- Debe generar JSON valido UTF-8.
- El JSON de contener: metadata, ejecucion, contexto, cuentas, controlTotales, incidentes.
- `controlTotales.sumatoriaDiferenciaNeta` coincide con sumatoria de diferencias por cuenta.
- Cuentas con diferencia fuera de tolerancia estan marcadas para revision.
- Incidentes severidad ALTA/CRITICA impactan estado de ejecucion.


## 5. Minima por Entrega
- Codigo fuente actualizado.
- JSON de salida de ejemplo real.
- Evidencia de pruebas (unitarias/integracion).
- Documentacion tecnica actualizada.
- Resultado de revision con checklist completo.

## 6. Checklist de cumplimiento Programas y Servicios IBM i (Obligatorio)
- [ ] Arquitectura modular IBM i identificable.
- [ ] Principios SOLID aplicados en componentes criticos.
- [ ] Codigo legible, cohesivo y sin duplicacion grave.
- [ ] Pruebas automatizadas ejecutadas y evidenciadas.
- [ ] JSON de conciliacion valido y consistente.
- [ ] Nomenclatura y estandares respetados.

## 7. Estandar Obligatorio para Scripts SQL de Tablas
Toda tabla creada en el taller debe cumplir la estructura de metadata y comentarios del patron definido en el archivo de reglas "sql.md".

### 7.1 Estructura obligatoria minima por tabla
El agente debe generar cada script de creacion de tabla incluya, en este orden logico:
- Bloque de encabezado con metadata funcional (nombre, descripcion, objetivo, tipo, origen, permanencia, uso, restricciones).
- Bloque de autoria y contexto (equipo, fecha, proyecto).
- Sentencia `CREATE OR REPLACE TABLE`.
- Definicion de columnas con alias de sistema mediante `FOR COLUMN`.
- Definicion de `PRIMARY KEY` por `CONSTRAINT`.
- `RCDFMT` definido para formato de registro.
- `RENAME TABLE ... TO ... FOR SYSTEM NAME ...` cuando aplique estandar de nombres largos/cortos.
- `COMMENT ON TABLE` y `LABEL ON TABLE`.
- `COMMENT ON COLUMN` para todas las columnas.
- `LABEL ON COLUMN` para headers de todas las columnas.
- `LABEL ON COLUMN ... TEXT IS` para descripcion larga de todas las columnas.

### 7.3 Cobertura total de comentarios
El agente debe contemplar que todas las columnas definidas en la tabla tengan:
- Comment tecnico.
- Label corto.
- Label texto largo.

## 8. Regla de Objetos Permitidos en BD (IBM i)

### 8.1 Restriccion de tipos de objeto
Para el alcance del taller, solo se permite crear:
- Tablas SQL.
- Vistas SQL.

No se permite crear:
- PF (Physical Files tradicionales DDS).
- LF (Logical Files tradicionales DDS).

### 8.2 Obligatoria del agente
El agente debe revisar scripts y evidencia de despliegue para confirmar que:
- Toda estructura nueva de datos fue creada via SQL DDL (`CREATE TABLE` / `CREATE VIEW`).

## 9. Checklist de cumplimiento SQL (Obligatorio)
- [ ] Cada tabla incluye bloque completo de metadata funcional y de proyecto.
- [ ] Cada tabla define `CREATE OR REPLACE TABLE` con `FOR COLUMN` y `PRIMARY KEY`.
- [ ] Cada tabla incluye `COMMENT ON TABLE` y `LABEL ON TABLE`.
- [ ] Todas las columnas tienen `COMMENT ON COLUMN`.
- [ ] Todas las columnas tienen `LABEL ON COLUMN` y `LABEL ... TEXT IS`.
- [ ] No existen PF ni LF en scripts, despliegues ni evidencias.
- [ ] Solo se crean tablas y vistas SQL.
