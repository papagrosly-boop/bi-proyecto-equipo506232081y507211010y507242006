# Proyecto final BI · Matrícula en educación superior (MEN / SNIES)

Sistema de inteligencia de negocios para monitorear la matrícula de la educación superior en Colombia (2015-2021): ETL con Pentaho PDI, data warehouse en MySQL con esquema en estrella y tablero en Power BI.

Curso: Business Intelligence and Data Analytics · Docente: Leandro Pájaro Fuentes

## Integrantes

| Nombre | Código |
|---|---|
| Daniel Felipe Grisales Corredor | 506232081 |
| Giancarlo Guevara Orjuela | 507211010 |
| Johan Arturo González Feo | 507242006 |

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `datos/descarga.md` | De dónde y cómo se descargaron las tres fuentes |
| `datos/diccionarios/` | Diccionarios de datos de las fuentes (Anexo A de la Entrega 1) |
| `datos/muestras/` | Muestras de 20 filas de cada fuente |
| `datos/raw/` | Carpeta para los archivos originales completos (no se versionan) |
| `dw/ddl/` | Scripts SQL que crean la base `matricula`, las tablas y la dimensión de tiempo |
| `dw/conciliacion/` | Consultas que concilian la carga contra las fuentes |
| `etl/` | Trabajo y transformaciones de Pentaho PDI, con su propio `README.md` |
| `dashboard/` | Tablero de Power BI (`.pbix`) y capturas |
| `docs/` | Diagramas y documentos de cada entrega |
| `modelo/` | Reservada para el modelo predictivo (Entrega 3) |

## Fuentes de datos

Las tres fuentes son de datos.gov.co y se descargaron el 23/10/2026. El detalle, con enlaces y pasos, está en [`datos/descarga.md`](datos/descarga.md).

| Fuente | Formato | Registros |
|---|---|---|
| F1 Instituciones de Educación Superior | CSV | 361 |
| F2 Matrícula estadística de educación superior | CSV (unos 99 MB) | 390.903 |
| F3 DIVIPOLA, códigos de municipios | XML | 1.122 |

F2 pesa más de 50 MB, por eso no está en el repositorio. Hay que descargarla y guardarla en su carpeta local de fuentes.

## Requisitos

- MySQL Community Server 8.0 (probado con 8.0.46)
- Pentaho Data Integration Community Edition 9.4, con el conector MySQL Connector/J 5.1.49 en la carpeta `lib` de PDI
- Power BI Desktop

## Cómo reproducir la solución

### 1. Preparar las fuentes
Descargue los tres archivos siguiendo `datos/descarga.md` y guárdelos en una carpeta local, por ejemplo `C:\bi\fuentes`, con estos nombres:

- `MEN_INSTITUCIONES_EDUCACIÓN_SUPERIOR_20261023.csv`
- `MEN_MATRICULA_ESTADISTICA_ES_20261023.csv`
- `DIVIPOLA-_Códigos_municipios_20261023.xml`

### 2. Crear la base de datos
En MySQL, ejecute `dw/ddl/00_crear_todo.sql`. Crea la base `matricula` (`utf8mb4`), las cinco dimensiones, la tabla de hechos `fact_matricula`, las filas «Desconocido» (llave -1) y los 14 periodos de `dim_tiempo`.

También puede ejecutar los scripts por separado, en orden numérico (`01_crear_base.sql` a `08_poblar_dim_tiempo.sql`).

### 3. Crear el usuario de carga
```sql
CREATE USER 'etl'@'localhost' IDENTIFIED BY '<contraseña>';
GRANT ALL PRIVILEGES ON matricula.* TO 'etl'@'localhost';
```

### 4. Definir las variables de PDI
Agregue estas cinco variables al archivo `kettle.properties` de su equipo (en Windows, `C:\Users\<usuario>\.kettle\kettle.properties`). Ese archivo nunca se sube al repositorio.

```
FUENTES_DIR=C:/bi/fuentes
DB_HOST=localhost
DB_NAME=matricula
DB_USER=etl
DB_PASS=<contraseña>
```

Reinicie Spoon después de editarlo. El significado de cada variable está en [`etl/README.md`](etl/README.md).

### 5. Ejecutar la carga
Abra `etl/trabajos/j_carga_dw.kjb` en Spoon y ejecútelo. Carga primero las cuatro dimensiones y al final `fact_matricula`. La carga se puede repetir sin duplicar filas.

### 6. Conciliar
Ejecute `dw/conciliacion/01_conteos_dw.sql` y `dw/conciliacion/02_totales_dw.sql`. Resultado esperado:

| Tabla | Registros |
|---|---|
| dim_tiempo | 14 |
| dim_institucion | 362 |
| dim_programa | 15.527 |
| dim_geografia | 1.123 |
| dim_genero | 3 |
| fact_matricula | 230.078 |

Hechos con institución desconocida: 78; con programa, geografía o género desconocidos: 0. El total de `total_matriculados` en el DW es 16.774.645.

### 7. Ver el tablero
Abra `dashboard/tablero_matricula.pbix` en Power BI Desktop. En *Transformar datos → Configuración de origen de datos*, apunte la conexión de MySQL a su servidor y a la base `matricula`, y actualice. El tablero tiene una página por pregunta de negocio:

| Página | Pregunta |
|---|---|
| 1. Matrícula | P0: concentración y evolución de la matrícula |
| 2. Acreditación | P1: matrícula en instituciones acreditadas y no acreditadas |
| 3. Género y áreas | P2: distribución por género en cada núcleo del conocimiento |

## Seguridad

Las contraseñas no están en el repositorio. PDI las lee de `kettle.properties` mediante las variables `${DB_USER}` y `${DB_PASS}`.
