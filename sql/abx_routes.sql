DROP TABLE IF EXISTS vanco.abx_route CASCADE;
CREATE TABLE vanco.abx_route
(
    routeadmin TEXT NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    ambiguous INT NOT NULL
);

\copy vanco.abx_route FROM 'abx_route.csv' CSV HEADER;

-- ensure it is unique, etc.
ALTER TABLE vanco.abx_route ADD CONSTRAINT abx_route_pk PRIMARY KEY (routeadmin);