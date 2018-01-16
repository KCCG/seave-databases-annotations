CREATE DATABASE LOGGING;

USE LOGGING;

CREATE TABLE website_events (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user_id INT UNSIGNED, # Can be NULL if the user isn't logged in or the user is deleted
	FOREIGN KEY (user_id) REFERENCES ACCOUNTS.users(id) ON UPDATE CASCADE ON DELETE SET NULL,
	user_email VARCHAR(255), # If the user is deleted, this will be the only record of who performed the action
	seave_version VARCHAR(30) NOT NULL,
	event TEXT NOT NULL,
	ip INT(11) UNSIGNED NOT NULL,
	`time` DATETIME NOT NULL
);