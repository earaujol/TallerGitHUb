# Reglas CRUD - SQL RPG Full Free

## Descripción General

Conjunto de reglas para implementar operaciones CRUD (Create, Read, Update, Delete) en RPG Full Free utilizando SQL embebido, con manejo consistente de parámetros y errores.

---

## Estructura de Parámetros

### Parámetros de Entrada

1. **Data Structure (DS) con descripción externa de la tabla**
   - Debe contener todos los campos de la tabla
   - Definida con `EXTNAME()` para sincronización automática
   - Ejemplo: `DCL-DS dsClientes EXTNAME('CLIENTES') INZ;`

2. **Código de Operación (pOperation)**
   - Tipo: `CHAR(1)`
   - Valores permitidos:
     - `'C'` = CREATE (Insertar)
     - `'R'` = READ (Leer/Consultar)
     - `'U'` = UPDATE (Actualizar)
     - `'D'` = DELETE (Eliminar)

### Parámetros de Salida

1. **Data Structure de Error (dsError)**
   - Estructura consistente para todos los métodos
   - Campos:
     - `errorCode` (CHAR(5)) - Código de error SQL
     - `errorMsg` (VARCHAR(256)) - Mensaje descriptivo del error
     - `errorStatus` (CHAR(1)) - 'S' = Éxito, 'E' = Error

---

## Convención de Nombres

### Métodos CRUD

```
<NombreTabla>_db_<Operación>
```

**Ejemplos:**
- `CLIENTES_db_Insert()` - Insertar cliente
- `CLIENTES_db_Read()` - Consultar cliente
- `CLIENTES_db_Update()` - Actualizar cliente
- `CLIENTES_db_Delete()` - Eliminar cliente

### Otros Métodos Auxiliares

```
<NombreTabla>_db_<Función>
```

**Ejemplos:**
- `CLIENTES_db_ValidateData()` - Validar datos antes de operación
- `CLIENTES_db_GetByID()` - Obtener registro por ID

---

## Estructura de Programa Modelo

### Definición de Data Structures

```rpgle
DCL-DS dsClientes EXTNAME('CLIENTES') INZ;
END-DS;

DCL-DS dsError QUALIFIED;
  errorCode   CHAR(5);
  errorMsg    VARCHAR(256);
  errorStatus CHAR(1);
END-DS;

DCL-DS dsResult QUALIFIED;
  success   IND;
  rowCount  INT(10:0);
  dsError   LIKEDS(dsError);
END-DS;
```

### Método INSERT (CREATE)

```rpgle
DCL-PROC CLIENTES_db_Insert EXPORT;
  DCL-PI *N LIKEDS(dsResult);
    pCliente LIKEDS(dsClientes);
  END-PI;

  DCL-DS lResult LIKEDS(dsResult) INZ;
  
  TRY;
    EXEC SQL
      INSERT INTO CLIENTES
        (ID, NOMBRE, EMAIL, TELEFONO, ESTADO, FECHA_CREACION)
      VALUES
        (:pCliente.ID, :pCliente.NOMBRE, :pCliente.EMAIL,
         :pCliente.TELEFONO, :pCliente.ESTADO, CURRENT_TIMESTAMP);
    
    lResult.success = (SQLCODE = 0);
    lResult.rowCount = 1;
    
    IF NOT lResult.success;
      lResult.dsError.errorCode = %CHAR(SQLCODE);
      lResult.dsError.errorMsg = SQLERRMC;
      lResult.dsError.errorStatus = 'E';
    ELSE;
      lResult.dsError.errorStatus = 'S';
    ENDIF;
    
  CATCH;
    lResult.success = *OFF;
    lResult.rowCount = 0;
    lResult.dsError.errorStatus = 'E';
    lResult.dsError.errorMsg = 'Error no controlado en INSERT';
  ENDTRY;
  
  RETURN lResult;
END-PROC;
```

### Método READ (SELECT)

```rpgle
DCL-PROC CLIENTES_db_Read EXPORT;
  DCL-PI *N LIKEDS(dsResult);
    pClienteID PACKED(9:0);
  END-PI;

  DCL-DS lResult LIKEDS(dsResult) INZ;
  DCL-DS lCliente LIKEDS(dsClientes);
  
  TRY;
    EXEC SQL
      SELECT *
        INTO :lCliente
        FROM CLIENTES
        WHERE ID = :pClienteID;
    
    lResult.success = (SQLCODE = 0);
    
    IF lResult.success;
      lResult.rowCount = 1;
      lResult.dsError.errorStatus = 'S';
    ELSEIF SQLCODE = 100;
      lResult.rowCount = 0;
      lResult.dsError.errorCode = '100';
      lResult.dsError.errorMsg = 'Registro no encontrado';
      lResult.dsError.errorStatus = 'E';
    ELSE;
      lResult.dsError.errorCode = %CHAR(SQLCODE);
      lResult.dsError.errorMsg = SQLERRMC;
      lResult.dsError.errorStatus = 'E';
    ENDIF;
    
  CATCH;
    lResult.success = *OFF;
    lResult.rowCount = 0;
    lResult.dsError.errorStatus = 'E';
    lResult.dsError.errorMsg = 'Error no controlado en SELECT';
  ENDTRY;
  
  RETURN lResult;
END-PROC;
```

### Método UPDATE

```rpgle
DCL-PROC CLIENTES_db_Update EXPORT;
  DCL-PI *N LIKEDS(dsResult);
    pCliente LIKEDS(dsClientes);
  END-PI;

  DCL-DS lResult LIKEDS(dsResult) INZ;
  
  TRY;
    EXEC SQL
      UPDATE CLIENTES
        SET NOMBRE = :pCliente.NOMBRE,
            EMAIL = :pCliente.EMAIL,
            TELEFONO = :pCliente.TELEFONO,
            ESTADO = :pCliente.ESTADO,
            FECHA_MODIFICACION = CURRENT_TIMESTAMP
        WHERE ID = :pCliente.ID;
    
    lResult.success = (SQLCODE = 0);
    lResult.rowCount = SQL%ROWCOUNT;
    
    IF NOT lResult.success;
      lResult.dsError.errorCode = %CHAR(SQLCODE);
      lResult.dsError.errorMsg = SQLERRMC;
      lResult.dsError.errorStatus = 'E';
    ELSE;
      lResult.dsError.errorStatus = 'S';
    ENDIF;
    
  CATCH;
    lResult.success = *OFF;
    lResult.rowCount = 0;
    lResult.dsError.errorStatus = 'E';
    lResult.dsError.errorMsg = 'Error no controlado en UPDATE';
  ENDTRY;
  
  RETURN lResult;
END-PROC;
```

### Método DELETE

```rpgle
DCL-PROC CLIENTES_db_Delete EXPORT;
  DCL-PI *N LIKEDS(dsResult);
    pClienteID PACKED(9:0);
  END-PI;

  DCL-DS lResult LIKEDS(dsResult) INZ;
  
  TRY;
    EXEC SQL
      DELETE FROM CLIENTES
        WHERE ID = :pClienteID;
    
    lResult.success = (SQLCODE = 0);
    lResult.rowCount = SQL%ROWCOUNT;
    
    IF NOT lResult.success;
      lResult.dsError.errorCode = %CHAR(SQLCODE);
      lResult.dsError.errorMsg = SQLERRMC;
      lResult.dsError.errorStatus = 'E';
    ELSE;
      lResult.dsError.errorStatus = 'S';
    ENDIF;
    
  CATCH;
    lResult.success = *OFF;
    lResult.rowCount = 0;
    lResult.dsError.errorStatus = 'E';
    lResult.dsError.errorMsg = 'Error no controlado en DELETE';
  ENDTRY;
  
  RETURN lResult;
END-PROC;
```

---

## Manejo de Errores

### Códigos SQL Comunes

| Código | Descripción | Acción |
|--------|-------------|--------|
| 0 | Éxito | Continuar |
| 100 | Registro no encontrado | Retornar error específico |
| -803 | Violación de llave única | Validar duplicados |
| -530 | Violación de integridad referencial | Validar relaciones |
| -407 | Campo NOT NULL vacío | Validar obligatorios |

### Estructura de Respuesta

Todos los métodos retornan `dsResult` con:
- **success**: Indicador booleano del resultado
- **rowCount**: Número de filas afectadas
- **dsError**: Información de error

---

## Convenciones y Mejores Prácticas

### 1. Validación de Datos
- Validar datos ANTES de llamar al método CRUD
- Crear métodos auxiliares específicos por tabla
- Ejemplo: `CLIENTES_db_ValidateData(dsCliente)`

### 2. Transacciones
- Usar `EXEC SQL COMMIT` después de operaciones exitosas
- Usar `EXEC SQL ROLLBACK` en caso de error
- Considerar transacciones multi-tabla

### 3. Logging
- Registrar operaciones CRUD en tabla de auditoría
- Incluir: usuario, timestamp, tabla, operación, valores anteriores/nuevos

### 4. Seguridad
- Validar permisos antes de cada operación
- Usar prepared statements (implícito en EXEC SQL)
- Sanitizar entradas de usuario

### 5. Documentación
- Documentar parámetros requeridos para cada tabla
- Especificar campos clave de búsqueda
- Listar excepciones posibles por operación

---

## Ejemplo de Uso

```rpgle
// Programa llamador
DCL-DS dsCliente LIKEDS(dsClientes);
DCL-DS dsResultado LIKEDS(dsResult);

// Preparar datos
dsCliente.ID = 123;
dsCliente.NOMBRE = 'Juan Pérez';
dsCliente.EMAIL = 'juan@example.com';

// Insertar
dsResultado = CLIENTES_db_Insert(dsCliente);

IF dsResultado.success;
  DSPLY 'Cliente insertado correctamente';
ELSE;
  DSPLY 'Error: ' + dsResultado.dsError.errorMsg;
ENDIF;
```

---

## Control de Cambios

| Versión | Fecha | Descripción |
|---------|-------|-------------|
| 1.0 | 2026-05-11 | Creación inicial de reglas CRUD |

