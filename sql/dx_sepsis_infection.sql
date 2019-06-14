DROP TABLE IF EXISTS dx_sepsis_infection CASCADE;
CREATE TABLE dx_sepsis_infection as
(
    category VARCHAR(50) NOT NULL,
    dx TEXT NOT NULL
);

\copy dx_sepsis_infection FROM 'dx_sepsis_infection.csv' CSV;