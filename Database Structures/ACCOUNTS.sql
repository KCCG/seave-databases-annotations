CREATE DATABASE ACCOUNTS;

USE ACCOUNTS;

CREATE TABLE users (
     id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
     email VARCHAR(255) NOT NULL UNIQUE, # "According to RFC 5321, forward and reverse path can be up to 256 chars long, so the email address can be up to 254 characters long. You're safe with using 255 chars."
     password VARCHAR(255) NOT NULL, # "it is recommended to store the result in a database column that can expand beyond 60 characters (255 characters would be a good choice)"
     is_administrator BOOL NOT NULL,
     date_added DATETIME NOT NULL
);

ALTER TABLE users ADD INDEX (email);

CREATE TABLE groups (
     id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
     group_name VARCHAR(50) NOT NULL UNIQUE,
     group_description VARCHAR(100) NOT NULL,
     date_added DATETIME NOT NULL
);

CREATE TABLE users_in_groups (
     user_id INT UNSIGNED NOT NULL,
	 	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE, # If a user is deleted, automatically delete all their group memberships
     group_id INT UNSIGNED NOT NULL,
     	FOREIGN KEY (group_id) REFERENCES groups(id) ON UPDATE CASCADE ON DELETE CASCADE, # If a group is deleted, automatically delete all user memberships to it
     date_added DATETIME NOT NULL,
     PRIMARY KEY(user_id, group_id)
);

#--For Seave AMI only:

#--Create a 'default' group
INSERT INTO groups (group_name, group_description, date_added) VALUES ('default', 'Seave default group', now());

#--Create admin user with hashed password yA0s8KHF
INSERT INTO users (email, password, is_administrator, date_added) VALUES ('admin@seave.bio', '$2y$13$z5yU4SkxcwXoIB2t7Sp07ubJ/eBDsgET2EEK7Q.5vcdiA2prCuueS', '1', now());

#--Create default user with hashed password u0FKn5DA
INSERT INTO users (email, password, is_administrator, date_added) VALUES ('default@seave.bio', '$2y$13$.oVQJ7s/hpQavv/s.b4nzuDBZhn6cq9kSwalABM2mrXAW.i/eOqvm', '0', now());

#--Add the users to the default group
INSERT INTO users_in_groups (user_id, group_id, date_added) VALUES ((SELECT id FROM users WHERE email = 'admin@seave.bio'), (SELECT id FROM groups WHERE group_name = 'default'), now());
INSERT INTO users_in_groups (user_id, group_id, date_added) VALUES ((SELECT id FROM users WHERE email = 'default@seave.bio'), (SELECT id FROM groups WHERE group_name = 'default'), now());