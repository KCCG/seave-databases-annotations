-- This database is for tracking the versions of annotations used by Seave
-- Every update to an annotation is logged so a history can be maintained

CREATE DATABASE ANNOTATIONS;
USE ANNOTATIONS;


CREATE TABLE groups (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	group_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE annotations (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(30) NOT NULL UNIQUE,
	description VARCHAR(1000),
	group_id INT UNSIGNED,
	FOREIGN KEY (group_id) REFERENCES groups(id),
	active BOOL NOT NULL
);

CREATE TABLE update_methods (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	method_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE annotation_updates (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	annotation_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (annotation_id) REFERENCES annotations(id),
	version VARCHAR(60) NOT NULL,
	update_method_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (update_method_id) REFERENCES update_methods(id),
	update_time DATETIME NOT NULL
);

--INSERT INTO ANNOTATIONS.groups (group_name) VALUES ('');
--INSERT INTO ANNOTATIONS.update_methods (method_name) VALUES ('');


/*
Add an annotation:
INSERT INTO ANNOTATIONS.annotations 
	(name, description, group_id, active)
VALUES (
	'',
	'',
	(SELECT ANNOTATIONS.groups.id FROM ANNOTATIONS.groups WHERE ANNOTATIONS.groups.group_name = ''),
	1
);
*/

/*
Add an annotation update:
INSERT INTO ANNOTATIONS.annotation_updates 
	(annotation_id, version, update_method_id, update_time)
VALUES (
	(SELECT ANNOTATIONS.annotations.id FROM ANNOTATIONS.annotations WHERE ANNOTATIONS.annotations.name = ''),
	'',
	(SELECT ANNOTATIONS.update_methods.id FROM ANNOTATIONS.update_methods WHERE ANNOTATIONS.update_methods.method_name = ''),
	now()
);
*/

/*
View all annotations and updates:
SELECT 
	annotations.id, annotations.name, annotations.description, groups.group_name, annotations.active, annotation_updates.version, update_methods.method_name, annotation_updates.update_time 
FROM
	annotations
LEFT JOIN groups ON annotations.group_id = groups.id 
LEFT JOIN annotation_updates ON annotations.id = annotation_updates.annotation_id 
LEFT JOIN update_methods ON annotation_updates.update_method_id = update_methods.id 
;
*/