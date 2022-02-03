CREATE DATABASE IF NOT EXISTS `crapp_log` /*!40100 COLLATE 'utf8_general_ci' */;

CREATE TABLE crapp_log.`service_log` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`situation` ENUM('SUCCESS','ERROR') NOT NULL COLLATE 'utf8_general_ci',
	`host` VARCHAR(1024) NOT NULL COLLATE 'utf8_general_ci',
	`verb` ENUM('GET','POST','DELETE','PUT','OPTION') NOT NULL COLLATE 'utf8_general_ci',
	`route` VARCHAR(4096) NOT NULL COLLATE 'utf8_general_ci',
	`status` SMALLINT(5) UNSIGNED NOT NULL,
	`run_time` SMALLINT(5) UNSIGNED NOT NULL,
	`etag` VARCHAR(256) NOT NULL COLLATE 'utf8_general_ci',
	`ip` VARCHAR(256) NOT NULL COLLATE 'utf8_general_ci',
	`user_agent` VARCHAR(2048) NOT NULL COLLATE 'utf8_general_ci',
	`message` VARCHAR(2048) NULL DEFAULT NULL COLLATE 'utf8_general_ci',
	`debug` MEDIUMBLOB NULL DEFAULT NULL,
	`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;