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
| `dw/ddl/` | Scripts SQL que crean la base `matricula`, las tablas y la dimensión de tiempo (`01` a `08`), y la tabla de predicciones del modelo (`09_pred_caida_matricula_depto.sql`) |
| `dw/conciliacion/` | Consultas que concilian la carga contra las fuentes |
| `etl/` | Trabajo y transformaciones de Pentaho PDI, con su propio `README.md` |
| `dashboard/` | Tablero de Power BI (`.pbix`) y capturas |
| `docs/` | Diagramas (`diagramas/`) y el PDF de cada entrega (`entregas/`) |
| `modelo/` | Modelo predictivo (Entrega 3): notebook `modelo_matricula.ipynb`, consulta `extraccion.sql`, `requirements.txt` y `datos/dataset_depto_anio.csv` |

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
| 4. Predicciones | P3: predicción de caída de matrícula por departamento, junto a los valores reales (Entrega 3) |

## Cómo reproducir y visualizar el modelo (Entrega 3)

El modelo responde la pregunta P3 (¿qué departamentos tendrán caída de matrícula el próximo año?). Es una clasificación binaria: para cada departamento y año predice si la matrícula del semestre 1 del año siguiente será menor que la del año actual. Compara una regresión logística y un bosque aleatorio, con división temporal (entrenamiento con años base 2016-2018, prueba con 2019-2020 y predicción para 2022).

### 1. Ejecutar el notebook

Las librerías y sus versiones están en `modelo/requirements.txt`. El notebook es `modelo/modelo_matricula.ipynb` y funciona de dos maneras:

- **Sin acceso al data warehouse (recomendado, por ejemplo en Google Colab).** El notebook lee `modelo/datos/dataset_depto_anio.csv`, que ya está en el repositorio y es el resultado de `modelo/extraccion.sql` (231 filas). En Colab, ejecute en una celda:
  ```
  !git clone https://github.com/papagrosly-boop/bi-proyecto-equipo506232081y507211010y507242006.git
  %cd bi-proyecto-equipo506232081y507211010y507242006/modelo
  ```
  Luego abra `modelo_matricula.ipynb` y use *Entorno de ejecución → Ejecutar todo*.
- **Con acceso al data warehouse.** Defina las variables de entorno `DB_HOST`, `DB_NAME`, `DB_USER` y `DB_PASS` antes de abrir Jupyter. El notebook corre `extraccion.sql`, actualiza el CSV y carga las predicciones directamente en MySQL.

En un entorno local, instale las librerías con:
```
pip install -r modelo/requirements.txt
```

Al terminar, el notebook crea la carpeta `modelo/resultados/` con `resumen_resultados.md` (tablas y métricas), `predicciones.csv`, `riesgo_proximo_anio.csv`, `carga_predicciones.sql` y las figuras (`figuras/`).

### 2. Cargar las predicciones en el data warehouse

1. Ejecute `dw/ddl/09_pred_caida_matricula_depto.sql`. Crea la tabla `pred_caida_matricula_depto` y la vista `vw_dim_departamento` (una fila por departamento).
2. Cargue las 198 filas de una de estas dos maneras:
   - Con las variables `DB_*` definidas, el notebook las inserta solo.
   - Sin ellas, ejecute `modelo/resultados/carga_predicciones.sql` en MySQL como script completo.
3. Verifique:
   ```sql
   SELECT conjunto, COUNT(*) FROM matricula.pred_caida_matricula_depto GROUP BY conjunto;
   ```
   Resultado esperado: 99 de entrenamiento, 66 de prueba y 33 de futuro.

### 3. Ver las predicciones en el tablero

Abra `dashboard/tablero_matricula.pbix` y vaya a la página **4. Predicciones**. Muestra, por departamento, la matrícula base, la matrícula real del año siguiente, si cayó realmente, si el modelo predijo caída y su probabilidad, con filtros por departamento, año objetivo y conjunto (entrenamiento, prueba o futuro). Si cambió el servidor de MySQL, actualice la conexión como en el paso 7 de la Entrega 2. La captura de la página está en `dashboard/captura_pagina_predicciones.png`.

### Resultado

La regresión logística fue el algoritmo elegido. En la prueba (2020-2021) detectó 7 de 18 caídas reales (recall de 38,9 %) y no alcanzó el criterio de éxito. El detalle está en el documento `docs/entregas/BI-Entrega-3-Equipo506232081.pdf`.

## Seguridad

Las contraseñas no están en el repositorio. PDI las lee de `kettle.properties` mediante las variables `${DB_USER}` y `${DB_PASS}`, y el notebook las lee de variables de entorno.
