CREATE TABLE pigeons (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  park_id INTEGER,

  FOREIGN KEY(park_id) REFERENCES park(id)
);

CREATE TABLE parks (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  city_id INTEGER,

  FOREIGN KEY(city_id) REFERENCES city(id)
);

CREATE TABLE cities (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

INSERT INTO
  cities (id, name)
VALUES
  (1, "New York City"), (2, "Boston");

INSERT INTO
  parks (id, name, city_id)
VALUES
  (1, "Central Park", 1),
  (2, "Riverside Park", 1),
  (3, "Kendall Square", 2),

INSERT INTO
  cats (id, name, park_id)
VALUES
  (1, "Ralph", 1),
  (2, "Rolph", 2),
  (3, "Relph", 3),
  (4, "Rulph", 3),
  (5, "Infinite Flight Pigeon", NULL);
