DROP TABLE IF EXISTS vanco.dx_sepsis_infection CASCADE;
CREATE TABLE vanco.dx_sepsis_infection
(
    category VARCHAR(50) NOT NULL,
    dx TEXT NOT NULL
);

\copy vanco.dx_sepsis_infection FROM 'dx_sepsis_infection.csv' CSV;