# Reglas de Generación SQL - Db2 for IBM i

## 1. Convenciones de Nombres (Naming Conventions)
*   **Tablas (SQL):** Nombres descriptivos largos (`snake_case`).
*   **Tablas (System):** Nombres de 10 caracteres máximo (ej. `PREF` + `OBJ`).
*   **Campos:** Nombres descriptivos, mayúsculas preferidas.
### 1.1 Campos

*   Por cada campo el agente debe solicitar
1. Nombre largo
2. Nombre corto para `FOR COLUMN`
3. Tipo de dato
4. Longitud
5. ¿Permite NULL?

## 2. Estructura de Tabla SQL (CREATE TABLE)
*   Usar `CREATE OR REPLACE TABLE`.
*   Definir siempre `FOR SYSTEM NAME` para compatibilidad con DDS.
*   Especificar formato de registro `RCDFMT`.
*   Definir claves primarias (`PRIMARY KEY`) en lugar de índices únicos si es posible.

### 2.1 Llave Primaria   
*   El agente debe solicitar los campos que conforman la llave primaria.

## 3. Tipos de Datos Compatibles
*   **Texto:** `VARCHAR(n)` o `CHAR(n)`.
*   **Números:** `INTEGER`, `DECIMAL(p,s)`.
*   **Fechas:** `DATE`, `TIMESTAMP` (usar `CURRENT TIMESTAMP` para auditoría).

## 4. Índices y Restricciones
*   Los índices deben llevar un prefijo `I`.
*   Las llaves foráneas deben tener reglas `ON DELETE RESTRICT`.

## 5. Auditoría e Integridad
*   Incluir campos estándar: `FECHA_CREACION TIMESTAMP`, `FECHA_MODIFICACION`, `USUARIO_CREACION CHAR(10)`, `USUARIO_MODIFICA CHAR(10)`.
