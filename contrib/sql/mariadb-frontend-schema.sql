-- Schema version v4 - 2026-02-18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE TABLE IF NOT EXISTS `frontend_session` (
  `session_id` varchar(255) NOT NULL,
  `data` longtext,
  `created` int(10) unsigned NOT NULL,
  `modified` int(10) unsigned NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;

ALTER TABLE `frontend_session`
 ADD PRIMARY KEY (`session_id`),
 ADD INDEX(`modified`);
