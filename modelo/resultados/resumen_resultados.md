# Resumen de resultados (generado por el notebook)

## 2.2 Conjunto de datos
- Origen: archivo datos/dataset_depto_anio.csv (resultado de modelo/extraccion.sql).
- Filas extraídas: 231 (departamento-año); periodo 2015-2021; 33 departamentos en el panel.
- Excluidos por no tener matrícula en todos los años: 0 [].
- Registros etiquetados: 165; filas para predecir el año 2022: 33.

| Variable | Tipo | Papel | Origen (tabla.columna) | Descripción |
|---|---|---|---|---|
| cod_dpto | Texto | Identificador | dim_geografia.cod_dpto | Código DANE del departamento |
| nom_dpto | Texto | Identificador | dim_geografia.nom_dpto | Nombre del departamento |
| anio | Numérica | Identificador | dim_tiempo.anio | Año base t (semestre 1) |
| matricula_s1 | Numérica | Entrada (base de derivadas) | fact_matricula.total_matriculados | Estudiantes matriculados en el semestre 1 del año t |
| matricula_acreditada | Numérica | Entrada (base de derivadas) | fact_matricula.total_matriculados + dim_institucion.acreditada_alta_calidad | Matriculados en instituciones con acreditación de alta calidad |
| matricula_mujeres | Numérica | Entrada (base de derivadas) | fact_matricula.total_matriculados + dim_genero.descripcion_genero | Matriculadas de género femenino |
| n_programas | Numérica | Entrada (base de derivadas) | fact_matricula.sk_programa | Programas académicos distintos con matrícula |
| n_municipios | Numérica | Entrada (base de derivadas) | fact_matricula.sk_geografia | Municipios del departamento con matrícula |
| cae_siguiente | Binaria (0/1) | Objetivo | fact_matricula.total_matriculados (años t y t+1) | 1 si la matrícula del semestre 1 de t+1 es menor que la de t |
| log_matricula | Numérica | Entrada | Derivada de matricula_s1 | Logaritmo natural de la matrícula del año t |
| var_anual | Numérica | Entrada | Derivada de matricula_s1 (t y t-1) | Variación porcentual frente al año anterior |
| cayo_anio_actual | Binaria (0/1) | Entrada | Derivada de var_anual | 1 si la matrícula ya cayó en el año t |
| pct_acreditada | Numérica | Entrada | Derivada de matricula_acreditada | Proporción de la matrícula en instituciones acreditadas |
| pct_mujeres | Numérica | Entrada | Derivada de matricula_mujeres | Proporción de la matrícula femenina |
| log_programas | Numérica | Entrada | Derivada de n_programas | log(1 + programas con matrícula) |
| log_municipios | Numérica | Entrada | Derivada de n_municipios | log(1 + municipios con matrícula) |
| region | Categórica | Entrada | dim_geografia.cod_dpto + clasificación regional externa | Región natural del departamento (Andina, Caribe, Pacífica, Orinoquía, Amazonía, Insular) |

## 2.3 Variable objetivo
- Cae (1): 64 registros (38,8 %); no cae (0): 101.
- Variación del año siguiente: mínima -42,9 %, mediana 1,7 %, máxima 541,7 %; 20 atípicos por la regla IQR.

## 2.4 Exploración
Medianas por clase (0 = no cae, 1 = cae):

| cae_siguiente | var_anual_original | pct_acreditada | pct_mujeres | log_matricula | n_programas |
|---|---|---|---|---|---|
| 0,000 | 0,016 | 0,561 | 0,536 | 10,332 | 253,000 |
| 1,000 | 0,017 | 0,567 | 0,542 | 10,281 | 245,500 |

% de departamentos que caen por año objetivo: 2017: 36,4 %; 2018: 54,5 %; 2019: 48,5 %; 2020: 36,4 %; 2021: 18,2 %

## 3.1 Limpieza y transformación
| Tratamiento | Variable(s) | Qué se hizo | Registros afectados |
|---|---|---|---|
| Nulos estructurales | var_anual, cayo_anio_actual | Sin año anterior en el primer año de cada departamento: se descartan para el modelo | 33 |
| Nulos estructurales | cae_siguiente | Sin año siguiente en el último año: esas filas se usan solo para predecir el futuro | 33 |
| Departamentos incompletos | todas | Se excluyen los departamentos sin matrícula en todos los años | 0 |
| Atípicos | var_anual | Se acota a [-14,9 %, 17,2 %] (regla IQR con el entrenamiento) | 27 |
| Transformación | matricula_s1, n_programas, n_municipios | Logaritmo para reducir la asimetría | — |
| Codificación categórica | region | One-hot encoding (una columna 0/1 por región) | — |

## 3.3 División
| Conjunto | Registros | Periodo |
|---|---|---|
| Entrenamiento | 99 | Años base 2016-2018 (objetivo 2017-2019) |
| Prueba | 66 | Años base 2019-2020 (objetivo 2020-2021) |

En entrenamiento caen 46,5 % de los casos; en prueba, 27,3 %.

## 4.1 Algoritmos
- Regresión logística: {'C': 1.0, 'class_weight': 'balanced', 'max_iter': 1000, 'random_state': 42}, variables estandarizadas.
- Bosque aleatorio: {'n_estimators': 300, 'max_depth': 4, 'min_samples_leaf': 3, 'class_weight': 'balanced', 'random_state': 42}.

## 5.1 Métricas sobre el conjunto de prueba
| Algoritmo | Caídas reales | Detectadas | No detectadas | Falsas alarmas | Exactitud | Precisión | Recall (caídas) | F1 |
|---|---|---|---|---|---|---|---|---|
| Regresión logística | 18 | 7 | 11 | 25 | 45,5 % | 21,9 % | 38,9 % | 0,28 |
| Bosque aleatorio | 18 | 6 | 12 | 25 | 43,9 % | 19,4 % | 33,3 % | 0,24 |
| Referencia: siempre «no cae» | 18 | 0 | 18 | 0 | 72,7 % | 0,0 % | 0,0 % | 0,00 |
| Referencia: persistencia | 18 | 9 | 9 | 19 | 57,6 % | 32,1 % | 50,0 % | 0,39 |

- De 18 departamentos que sí cayeron, Regresión logística detectó 7 y dejó pasar 11; además marcó como caída a 25 que no cayeron (de 48 que no cayeron).
- De 18 departamentos que sí cayeron, Bosque aleatorio detectó 6 y dejó pasar 12; además marcó como caída a 25 que no cayeron (de 48 que no cayeron).

## 5.2 Elección
Se elige **Regresión logística**: F1 de la clase «cae» de 0,28 frente a 0,24 de Bosque aleatorio; recall de 38,9 % frente a 33,3 %; exactitud de 45,5 % frente a 43,9 %.

| Año objetivo | Departamentos | Caídas reales | Detectadas | Falsas alarmas | Exactitud |
|---|---|---|---|---|---|
| 2020 | 33 | 12 | 4 | 9 | 48,5 % |
| 2021 | 33 | 6 | 3 | 16 | 42,4 % |

## 5.3 Variables más importantes

| Variable | Coeficiente (variables estandarizadas) | Promedio si cae | Promedio si no cae |
|---|---|---|---|
| region_Orinoquía | 0,548 | 0,196 | 0,057 |
| pct_acreditada | 0,390 | 0,537 | 0,477 |
| log_programas | -0,322 | 5,124 | 5,213 |
| region_Pacífica | -0,264 | 0,065 | 0,170 |
| cayo_anio_actual | -0,260 | 0,326 | 0,434 |
| var_anual | 0,246 | 0,023 | 0,008 |
| region_Amazonía | -0,231 | 0,152 | 0,208 |
| region_Insular | -0,182 | 0,022 | 0,038 |

## 5.4 Criterio de éxito

| Criterio (sección 1.3) | Valor obtenido | ¿Se alcanzó? |
|---|---|---|
| Detectar al menos 6 de cada 10 departamentos que caen (recall ≥ 60 %) | 38,9 % (7 de 18) | No |
| Exactitud mayor que la de predecir siempre «no cae» | 45,5 % frente a 72,7 % | No |

## 5.5 Respuesta a la pregunta de negocio
Para 2022 el modelo marca 17 de 33 departamentos con caída de matrícula; concentran 1.295.313 estudiantes (64,9 % de la matrícula del semestre 1 de 2021 en el panel).
Con mayor probabilidad de caída: VICHADA (73 %); META (73 %); ARAUCA (69 %); CASANARE (66 %); QUINDÍO (62 %); BOGOTÁ, D.C. (59 %); RISARALDA (58 %); SANTANDER (55 %).

## 6.1 Tabla de predicciones
- pred_caida_matricula_depto: 198 filas (99 entrenamiento, 66 prueba, 33 futuro).

## Limitaciones a declarar
- Muestra pequeña: un registro por departamento y año; las métricas de prueba se mueven mucho con pocos casos.
- La prueba incluye 2020 (pandemia), con un comportamiento distinto del de entrenamiento.
- La acreditación es la vigente en el catálogo de F1 (fecha de descarga) y se aplica a todos los años.