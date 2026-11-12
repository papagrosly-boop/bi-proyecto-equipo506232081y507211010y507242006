# Procesos ETL · Pentaho Data Integration

## 1. Herramientas

| Elemento | Detalle |
|---|---|
| Herramienta | Pentaho Data Integration (PDI) Community Edition 9.4 (Kettle) |
| Destino | MySQL 8.0.46, base `matricula` |
| Driver JDBC | MySQL Connector/J 5.1.49 (copiar a la carpeta `lib` de PDI) |
| Codificación | UTF-8 |

## 2. Variables

Las transformaciones no tienen rutas ni credenciales escritas. Todo se lee de cinco variables que cada integrante define en su archivo `kettle.properties` (en Windows: `C:\Users\<usuario>\.kettle\kettle.properties`). Ese archivo no se sube al repositorio. Después de editarlo hay que reiniciar Spoon.

| Variable | Qué contiene | Ejemplo |
|---|---|---|
| `${FUENTES_DIR}` | Carpeta local con los tres archivos originales. Las transformaciones arman la ruta de cada archivo a partir de ella | `C:/bi/fuentes` |
| `${DB_HOST}` | Servidor MySQL | `localhost` |
| `${DB_NAME}` | Base de datos destino | `matricula` |
| `${DB_USER}` | Usuario de carga, con privilegios solo sobre `matricula.*` | `etl` |
| `${DB_PASS}` | Contraseña del usuario | (no se publica) |

Ejemplo de `kettle.properties`:

```
FUENTES_DIR=C:/bi/fuentes
DB_HOST=localhost
DB_NAME=matricula
DB_USER=etl
DB_PASS=<contraseña>
```

## 3. Archivos que debe haber en `${FUENTES_DIR}`

Se descargan de datos.gov.co siguiendo `datos/descarga.md`.

| Fuente | Archivo |
|---|---|
| F1 Instituciones | `MEN_INSTITUCIONES_EDUCACIÓN_SUPERIOR_20261023.csv` |
| F2 Matrícula | `MEN_MATRICULA_ESTADISTICA_ES_20261023.csv` (unos 99 MB, no está en el repositorio) |
| F3 DIVIPOLA | `DIVIPOLA-_Códigos_municipios_20261023.xml` |

## 4. Trabajo y orden de ejecución

El trabajo `trabajos/j_carga_dw.kjb` ejecuta las transformaciones en este orden. Las dimensiones van primero porque la tabla de hechos busca en ellas sus llaves subrogadas.

| # | Transformación | Fuente | Destino | Qué hace |
|---|---|---|---|---|
| 1 | `t_dim_geografia.ktr` | F3 (XML) | `dim_geografia` | Cambia la coma decimal de latitud y longitud por punto y carga los municipios |
| 2 | `t_dim_institucion.ktr` | F1 (CSV) | `dim_institucion` | Quita el punto de miles del código de la institución, elimina el carácter «¿» de los nombres y carga la dimensión |
| 3 | `t_dim_programa.ktr` | F2 (CSV) | `dim_programa` | Deja un registro por programa, limpia el texto y carga la dimensión |
| 4 | `t_dim_genero.ktr` | F2 (CSV) | `dim_genero` | Toma los códigos de género distintos y les asigna descripción |
| 5 | `t_fact_matricula.ktr` | F2 (CSV) | `fact_matricula` | Elimina duplicados exactos, completa con cero los códigos de municipio de 4 dígitos, busca las cinco llaves (la llave -1 si no hay coincidencia), agrupa por la granularidad y carga con vaciado previo |

Las dimensiones se cargan con *Insert/Update* y los hechos se vacían antes de cargar, por eso el trabajo se puede ejecutar varias veces con el mismo resultado.

## 5. Cómo ejecutar

1. Cree la base con `dw/ddl/00_crear_todo.sql`.
2. Defina las cinco variables de la sección 2 y reinicie Spoon.
3. Abra `etl/trabajos/j_carga_dw.kjb` y ejecútelo. Debe terminar sin errores.
4. Concilie con las consultas de `dw/conciliacion/`.

## 6. Resultado esperado

| Fuente | Leídos | Cargados | Descartados |
|---|---|---|---|
| F1 Instituciones | 361 | 361 | 0 |
| F2 Matrícula | 390.903 | 230.078 | 160.825 (106.609 duplicados exactos y 54.216 por agrupar a la granularidad) |
| F3 DIVIPOLA | 1.122 | 1.122 | 0 |

`fact_matricula` queda con 230.078 filas.
