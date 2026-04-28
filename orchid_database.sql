-- Orchid Database for PostgreSQL
-- Generated from Mount Busa Orchid Study

-- Drop tables if they exist
DROP TABLE IF EXISTS species_conservation;
DROP TABLE IF EXISTS conservation_status;
DROP TABLE IF EXISTS species_use;
DROP TABLE IF EXISTS use_type;
DROP TABLE IF EXISTS species_distribution;
DROP TABLE IF EXISTS species;
DROP TABLE IF EXISTS genus;
DROP TABLE IF EXISTS forest_type;
DROP TABLE IF EXISTS study;

-- 1. Study Table
CREATE TABLE study (
    study_id SERIAL PRIMARY KEY,
    title TEXT,
    location TEXT,
    description TEXT,
    total_species INT,
    total_genera INT,
    endemic_species INT,
    mindanao_endemic INT
);

-- 2. Genus Table
CREATE TABLE genus (
    genus_id SERIAL PRIMARY KEY,
    genus_name VARCHAR(100) UNIQUE
);

-- 3. Species Table
CREATE TABLE species (
    species_id SERIAL PRIMARY KEY,
    genus_id INT,
    scientific_name VARCHAR(255) UNIQUE,
    endemic BOOLEAN,
    distribution VARCHAR(100),
    FOREIGN KEY (genus_id) REFERENCES genus(genus_id)
);

-- 4. Forest Types
CREATE TABLE forest_type (
    forest_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    elevation_min INT,
    elevation_max INT,
    species_count INT
);

-- 5. Species Distribution
CREATE TABLE species_distribution (
    distribution_id SERIAL PRIMARY KEY,
    species_id INT,
    forest_id INT,
    altitude_min INT,
    altitude_max INT,
    vertical_distribution VARCHAR(50),
    FOREIGN KEY (species_id) REFERENCES species(species_id),
    FOREIGN KEY (forest_id) REFERENCES forest_type(forest_id)
);

-- 6. Use Types
CREATE TABLE use_type (
    use_id SERIAL PRIMARY KEY,
    use_name VARCHAR(50)
);

CREATE TABLE species_use (
    species_id INT,
    use_id INT,
    PRIMARY KEY (species_id, use_id),
    FOREIGN KEY (species_id) REFERENCES species(species_id),
    FOREIGN KEY (use_id) REFERENCES use_type(use_id)
);

-- 7. Conservation Status
CREATE TABLE conservation_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50)
);

CREATE TABLE species_conservation (
    species_id INT,
    status_id INT,
    PRIMARY KEY (species_id, status_id),
    FOREIGN KEY (species_id) REFERENCES species(species_id),
    FOREIGN KEY (status_id) REFERENCES conservation_status(status_id)
);

-- Insert core data
INSERT INTO study (title, location, total_species, total_genera, endemic_species, mindanao_endemic)
VALUES ('Richness and Distribution of Orchids in Mount Busa',
        'Mount Busa, Sarangani, Philippines',
        108, 51, 53, 15);

INSERT INTO forest_type (name, elevation_min, elevation_max, species_count) VALUES
('MESLEF', 400, 600, 17),
('MASLEF', 700, 1100, 39),
('LMF', 1200, 1600, 20),
('UMF', 1700, 2046, 28);

INSERT INTO use_type (use_name) VALUES ('Ornamental');

INSERT INTO conservation_status (status_name) VALUES
('Critically Endangered'),
('Endangered'),
('Vulnerable');

-- Sample genus and species
INSERT INTO genus (genus_name) VALUES ('Phalaenopsis');

INSERT INTO species (genus_id, scientific_name, endemic, distribution)
VALUES (1, 'Phalaenopsis sanderiana', TRUE, 'Mindanao');

INSERT INTO species_use VALUES (1, 1);
INSERT INTO species_conservation VALUES (1, 2);
