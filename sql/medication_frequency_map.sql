DROP TABLE IF EXISTS vanco.medication_frequency_map CASCADE;
CREATE TABLE vanco.medication_frequency_map
(
    frequency TEXT,
    classification VARCHAR(50),
    n INT NOT NULL,
    n_pat INT NOT NULL
);

\copy vanco.medication_frequency_map FROM 'medication_frequency_map.csv' CSV HEADER;

-- delete the two null frequency values which are unclassified
DELETE FROM vanco.medication_frequency_map
WHERE frequency IS NULL;

-- ensure it is unique, etc.
ALTER TABLE vanco.medication_frequency_map ALTER COLUMN frequency SET NOT NULL;
ALTER TABLE vanco.medication_frequency_map ADD CONSTRAINT med_freq_map_pk PRIMARY KEY (frequency);