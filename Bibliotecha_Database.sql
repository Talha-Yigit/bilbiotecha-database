CREATE TYPE sex_type AS ENUM ('M', 'F');
CREATE TYPE staff_roles AS ENUM ('Receptionist', 'Manager', 'IT', 'System Manager');
CREATE TYPE damage_levels AS ENUM ('Severe', 'Mild', 'OK', 'Good', 'Pristine');
CREATE TYPE language_tags AS ENUM ('AR', 'DE', 'EN', 'ES', 'FR', 'HI', 'IT', 'JA', 'RU', 'TUR', 'ZH');
CREATE TYPE genres AS ENUM ('Fantasy', 'Sci-Fi', 'Action & Adventure', 'Mystery', 'Horror', 'Romance', 'Graphic Novel', 'Children''s', 'Biography', 'History', 'Science & Technology');

CREATE TABLE "member" (
	member_id SMALLSERIAL NOT NULL PRIMARY KEY,
	citizen_id INTEGER UNIQUE NOT NULL,
	name VARCHAR(127) NOT NULL,
	surname VARCHAR(127) NOT NULL,
	birth_date DATE,
	age SMALLINT,
	sex sex_type,
	address VARCHAR(511),
	telephone VARCHAR(14) NOT NULL,
	email VARCHAR(255),
	membership_date DATE DEFAULT CURRENT_DATE NOT NULL,
	membership_expiry_date DATE GENERATED ALWAYS AS (membership_date + INTERVAL '1 year') STORED
);

CREATE TABLE author (
	author_id SMALLSERIAL NOT NULL PRIMARY KEY,
	name VARCHAR(127) NOT NULL,
	surname VARCHAR(127) NOT NULL,
	pen_name VARCHAR(127),
	birth_date DATE,
	death_date DATE,
	lifetime SMALLINT GENERATED ALWAYS AS (
		CASE
			WHEN death_date IS NOT NULL THEN (death_date - birth_date)
			ELSE NULL
		END
	) STORED,
	sex sex_type
);

CREATE TABLE publisher (
	publisher_id SMALLSERIAL NOT NULL PRIMARY KEY,
	publisher_name VARCHAR(255) NOT NULL
);

CREATE TABLE book (
	isbn13 VARCHAR(17) NOT NULL PRIMARY KEY,
	isbn10 VARCHAR(13),
	title VARCHAR(255) NOT NULL,
	release_date DATE,
	FK_publisher_id INTEGER,
	FOREIGN KEY (FK_publisher_id) REFERENCES publisher (publisher_id)
);

CREATE TABLE book_language (
	language_tag language_tags NOT NULL,
	FK_isbn13 VARCHAR(17) NOT NULL,
	FOREIGN KEY (FK_isbn13) REFERENCES book (isbn13) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE book_genre (
	genre genres NOT NULL,
	FK_isbn13 VARCHAR(17) NOT NULL,
	FOREIGN KEY (FK_isbn13) REFERENCES book (isbn13) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE authorship (
	FK_author_id INTEGER NOT NULL,
	FK_isbn13 VARCHAR(17) NOT NULL,
	FOREIGN KEY (FK_author_id) REFERENCES author (author_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (FK_isbn13) REFERENCES book (isbn13) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE staff (
	citizen_id INTEGER NOT NULL PRIMARY KEY,
	name VARCHAR(127) NOT NULL,
	surname VARCHAR(127) NOT NULL,
	staff_role staff_roles
);

CREATE TABLE "copy" (
	id SMALLSERIAL NOT NULL PRIMARY KEY,
	FK_isbn13 VARCHAR(17) NOT NULL,
	availability BOOLEAN NOT NULL,
	damage damage_levels,
	FOREIGN KEY (FK_isbn13) REFERENCES book (isbn13) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE lending (
	lending_id SERIAL NOT NULL PRIMARY KEY,
	FK_isbn13 VARCHAR(17) NOT NULL,
	FK_member_id INTEGER NOT NULL,
	FK_citizen_id INTEGER NOT NULL,
	lending_date DATE DEFAULT CURRENT_DATE NOT NULL,
	due_date DATE GENERATED ALWAYS AS (lending_date + 7) STORED,
	return_date DATE,
	fine REAL GENERATED ALWAYS AS (
		CASE
			WHEN return_date > (lending_date + 7) THEN 5 * (return_date - (lending_date + 7))
			ELSE 0
		END
	) STORED,
	FOREIGN KEY (FK_isbn13) REFERENCES book (isbn13),
	FOREIGN KEY (FK_member_id) REFERENCES "member" (member_id),
	FOREIGN KEY (FK_citizen_id) REFERENCES staff (citizen_id)
);

CREATE OR REPLACE FUNCTION set_generated_columns()
RETURNS TRIGGER AS $$
BEGIN
    NEW.age := EXTRACT(YEAR FROM AGE(NEW.birth_date));
    NEW.membership_expiry_date := NEW.membership_date + INTERVAL '1 year';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_member_insert_or_update
BEFORE INSERT OR UPDATE ON member
FOR EACH ROW
EXECUTE FUNCTION set_generated_columns();