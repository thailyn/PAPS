-- -*- sql -*- --

-- Recreate the paps database using this sql file.
-- Sample command:
--   psql -U papsuser [-W] papsdb -f schema/paps.sql
-- Including the -W argument makes entering a password required.

-- Drop any tables if they already exist.
DROP TABLE IF EXISTS metaworks CASCADE;
DROP TABLE IF EXISTS work_types CASCADE;
DROP TABLE IF EXISTS works CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS work_authors CASCADE;
DROP TABLE IF EXISTS reference_types CASCADE;
DROP TABLE IF EXISTS work_references CASCADE;

-- Create the tables.  Required to, of course, create tables that are
-- referenced before the tables that reference them.

-- The metaworks table serves as a link between different works that
-- represent the same overal "work."  For example, two different editions of
-- the same book will be represented as two different works, as they could
-- have virtually completely different metadata (different authors, etc.), but
-- would be connected by referencing the same meta work.
CREATE TABLE metaworks (
  id SERIAL PRIMARY KEY
);

CREATE TABLE work_types (
  work_type_id SERIAL PRIMARY KEY,
  work_type varchar NOT NULL
);

CREATE TABLE works (
  work_id SERIAL PRIMARY KEY,
  meta_work_id int REFERENCES metaworks (id),
  work_type_id int NOT NULL REFERENCES work_types (work_type_id),
  title varchar NOT NULL,
  subtitle varchar,
  edition smallint,
  num_references smallint,
  doi varchar
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

CREATE SEQUENCE reference_types_id_seq;
CREATE TABLE reference_types (
  id smallint DEFAULT nextval('reference_types_id_seq') PRIMARY KEY,
  name varchar NOT NULL UNIQUE
);
ALTER SEQUENCE reference_types_id_seq OWNED BY reference_types.id;

CREATE TABLE work_references ( -- or, 'citations'
  id BIGSERIAL PRIMARY KEY,
  referencing_work_id integer NOT NULL REFERENCES works (work_id),
  referenced_work_id integer NULL REFERENCES works (work_id),
  reference_type_id smallint NOT NULL REFERENCES reference_types (id),
  rank smallint NOT NULL,
  chapter smallint NULL,
  reference_text text NULL
);

-- Populate the tables with some example data.
INSERT INTO work_types (work_type) VALUES ('Textbook');
INSERT INTO work_types (work_type) VALUES ('Book');
INSERT INTO work_types (work_type) VALUES ('Paper');

INSERT INTO works (work_type_id, title, subtitle, edition) VALUES (1, 'Artificial Intelligence', 'A Modern Approach', 2);
INSERT INTO works (work_type_id, title, subtitle, edition) VALUES (1, 'Artificial Intelligence', 'A Systems Approach', 1);
INSERT INTO works (work_type_id, title, edition, num_references, doi) VALUES (3, 'Takeover Times on Scale-Free Topologies', 1, 33, '10.1145/1276958.1277018'); -- 'http://doi.acm.org/10.1145/1276958.1277018'
INSERT INTO works (work_type_id, title, edition, doi) VALUES (3, 'Parameterizing pair approximations for takeover dynamics', 1, '10.1145/1388969.1389047');

INSERT INTO people (first_name, last_name) VALUES ('Stuart', 'Russell');
INSERT INTO people (first_name, last_name) VALUES ('Peter', 'Norvig');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('M.', 'Tim', 'Jones');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('Joshua', 'L.', 'Payne');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('Margaret', 'J.', 'Eppstein');
INSERT INTO people (first_name, middle_name, last_name) VALUES ('Randal', 'L.', 'Schwartz');

INSERT INTO work_authors (work_id, person_id, author_position) VALUES (1, 1, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (1, 2, 2);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (2, 3, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (3, 4, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (3, 5, 2);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (4, 4, 1);
INSERT INTO work_authors (work_id, person_id, author_position) VALUES (4, 5, 2);

INSERT INTO reference_types (name) VALUES ('Bibliography'); -- or 'Works Cited'
INSERT INTO reference_types (name) VALUES ('Endnote');
INSERT INTO reference_types (name) VALUES ('Footnote');

INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (1, null, 1, 1, null, '**Aarup**, M., Arentoft, M. M., Parrod, Yo., Stader, J., and Stokes, L (1994). OPTIMUM-AIV: A knowledge-based planning and scheduling system for spacecraft AIV.  In Fox, M. and Zweben, M. (Eds.), _Knowledge Based Scheduling_. Morgan Kaufmann, San Mateo, California.');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (1, null, 1, 2, null, '**Abramson**, B. and Yung, M. (1989). Divide and conquer under global constraints:  A solution to the N-queens problem.  _Journal of Parallel and Distributed Computing, 6(3)_, 649-662.');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (1, null, 1, 3, null, '**Ackley**, D. H. and Littman, M. L. (1991).  Interactions between learning and evolution.  In Langton, C., Taylor, C., Farmer, J. D., and Ramussen, S. (Eds.), _Artificial Life II_, pp. 487-509.  Addison-Wesley, Redwood City, California.');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (2, null, 1, 1, 1, '[LISP 2007] Wikipedia "Lisp (programming language)", 2007. Available online at http://en.wikipedia.org/wiki/Lisp_%28programming_language%29');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (2, null, 1, 2, 1, '[Newell 1956] Newell, A., Shaw, J.C., Simon, H.A "Emperical Explorations of the Logic Theory Machine: A Case Study in Heuristics," in Proceedings of the Western Joint Computer Conference, 1956.');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (2, null, 1, 3, 1, '[Shannon 1950] Shannon, Claude, "Programming a Computer for Playing Chess," _Philisophical Magazine_ 41, 1950.');
INSERT INTO work_references (referencing_work_id, referenced_work_id, reference_type_id, rank, chapter, reference_text) VALUES (2, null, 1, 1, 2, '[Bouton 1901] "Nim, a game with a complete mathematical theory," Ann, Math, Princeton 3, 35-39, 1901-1902');
