-- -*- sql -*- --

-- Drop any tables if they already exist.
DROP TABLE IF EXISTS work_types CASCADE;
DROP TABLE IF EXISTS works CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS work_authors CASCADE;

-- Create the table.  Required to, of course, create tables that are
-- referenced before the tables that reference them.
CREATE TABLE work_types (
  work_type_id SERIAL PRIMARY KEY,
  work_type varchar NOT NULL
);

CREATE TABLE works (
  work_id SERIAL PRIMARY KEY,
  work_type_id int NOT NULL REFERENCES work_types (work_type_id),
  title varchar NOT NULL,
  subtitle varchar,
  num_references smallint,
  doi_name varchar
);

CREATE TABLE people (
  person_id SERIAL PRIMARY KEY,
  first_name varchar,
  middle_name varchar,
  last_name varchar,
  date_of_birth date
);

CREATE TABLE work_authors (
  works_author_id SERIAL PRIMARY KEY,
  work_id int NOT NULL REFERENCES works (work_id),
  person_id int NOT NULL REFERENCES people (person_id),
  author_position smallint
);

-- Populate the tables with some example data.
INSERT INTO work_types (work_type) VALUES ('Textbook');
INSERT INTO work_types (work_type) VALUES ('Book');
INSERT INTO work_types (work_type) VALUES ('Paper');
