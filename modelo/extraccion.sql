-- Extracción del conjunto de datos del modelo (Entrega 3)
-- Una fila por departamento y año, con la matrícula del semestre 1 y sus atributos.
-- Se usa solo el semestre 1 porque la matrícula es semiaditiva: no se suma entre los
-- dos semestres de un año (mismo criterio del tablero de la Entrega 2).
-- Se excluyen los hechos con geografía desconocida (llave -1).
USE matricula;

SELECT
    t.sk_tiempo                                    AS sk_tiempo,
    t.anio                                         AS anio,
    g.cod_dpto                                     AS cod_dpto,
    g.nom_dpto                                     AS nom_dpto,
    SUM(f.total_matriculados)                      AS matricula_s1,
    SUM(CASE WHEN i.acreditada_alta_calidad = 'SI'
             THEN f.total_matriculados ELSE 0 END) AS matricula_acreditada,
    SUM(CASE WHEN ge.descripcion_genero = 'Femenino'
             THEN f.total_matriculados ELSE 0 END) AS matricula_mujeres,
    COUNT(DISTINCT f.sk_programa)                  AS n_programas,
    COUNT(DISTINCT f.sk_geografia)                 AS n_municipios
FROM fact_matricula f
JOIN dim_tiempo      t  ON t.sk_tiempo      = f.sk_tiempo
JOIN dim_geografia   g  ON g.sk_geografia   = f.sk_geografia
JOIN dim_institucion i  ON i.sk_institucion = f.sk_institucion
JOIN dim_genero      ge ON ge.sk_genero     = f.sk_genero
WHERE t.semestre = 1
  AND f.sk_geografia <> -1
GROUP BY t.sk_tiempo, t.anio, g.cod_dpto, g.nom_dpto
ORDER BY g.cod_dpto, t.anio;
