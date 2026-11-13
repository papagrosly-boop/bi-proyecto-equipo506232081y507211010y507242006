-- Entrega 3: tabla de predicciones del modelo y vista de departamentos
USE matricula;

DROP TABLE IF EXISTS pred_caida_matricula_depto;

CREATE TABLE pred_caida_matricula_depto (
    sk_tiempo_base   INT          NOT NULL COMMENT 'Llave a dim_tiempo: semestre 1 del año en que se hace la predicción',
    cod_dpto         VARCHAR(5)   NOT NULL COMMENT 'Llave a vw_dim_departamento (y a dim_geografia.cod_dpto)',
    anio_objetivo    SMALLINT     NOT NULL COMMENT 'Año cuya matrícula se predice (año base + 1)',
    conjunto         VARCHAR(30)  NOT NULL COMMENT 'entrenamiento, prueba o futuro',
    modelo           VARCHAR(40)  NOT NULL COMMENT 'Algoritmo elegido',
    prob_caida       DECIMAL(6,4) NOT NULL COMMENT 'Probabilidad estimada de que la matrícula caiga',
    caida_predicha   TINYINT      NOT NULL COMMENT '1 = el modelo predice caída',
    caida_real       TINYINT      NULL     COMMENT '1 = la matrícula cayó; NULL si el año objetivo aún no existe',
    matricula_base   INT          NOT NULL COMMENT 'Matrícula del semestre 1 del año base',
    matricula_real   INT          NULL     COMMENT 'Matrícula del semestre 1 del año objetivo; NULL si no existe',
    fecha_ejecucion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_tiempo_base, cod_dpto),
    KEY ix_pred_dpto (cod_dpto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- La predicción es por departamento, pero dim_geografia tiene una fila por municipio.
-- Esta vista da una fila por departamento para relacionarla con la tabla de predicciones.
CREATE OR REPLACE VIEW vw_dim_departamento AS
SELECT DISTINCT cod_dpto, nom_dpto
FROM dim_geografia
WHERE sk_geografia <> -1;
