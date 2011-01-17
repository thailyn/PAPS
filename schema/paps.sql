-- -*- sql -*- --

-- Recreate the paps database using this sql file.
-- Sample command:
--   psql -U papsuser [-W] papsdb -f schema/paps.sql
-- Including the -W argument makes entering a password required.

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
  edition smallint,
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

INSERT INTO works (work_type_id, title, subtitle, edition) VALUES (1, 'Artificial Intelligence', 'A Modern Approach', 2);
INSERT INTO works (work_type_id, title, subtitle, edition) VALUES (1, 'Artificial Intelligence', 'A Systems Approach', 1);
INSERT INTO works (work_type_id, title, edition, num_references, doi_name) VALUES (3, 'Takeover Times on Scale-Free Topologies', 1, 33, 'http://doi.acm.org/10.1145/1276958.1277018');

INSERT INTO people (first_name, last_name) VALUES ('Stuart', 'Russell');
INSERT INTO people (first_name, last_name) VALUES ('Peter', 'Norvig');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('M.', 'Tim', 'Jones');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('Joshua', 'L.', 'Payne');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('Margaret', 'J.', 'Eppstein');

INSERT INTO work_authors (work_id, person_id, author_position) VALUES (1, 1, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (1, 2, 2);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (2, 3, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (3, 4, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (3, 5, 2);
