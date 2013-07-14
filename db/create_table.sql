delimiter $$

CREATE TABLE `reply` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `body` text NOT NULL,
  `user_id` int(11) NOT NULL,
  `thread_id` int(11) NOT NULL,
  `create_datetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8$$

delimiter $$

CREATE TABLE `thread` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject` varchar(45) NOT NULL,
  `body` text NOT NULL,
  `deadline` datetime NOT NULL,
  `user_id` int(11) NOT NULL,
  `status` varchar(16) NOT NULL,
  `create_datetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8$$

delimiter $$

CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_name` varchar(45) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `display_name` varchar(45) NOT NULL,
  `mail_address` varchar(100) DEFAULT NULL,
  `password` varchar(128) NOT NULL,
  `activate` tinyint(1) NOT NULL DEFAULT '1',
  `role` varchar(8) NOT NULL,
  `expire_datetime` datetime DEFAULT NULL,
  `reset_hash` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_UNIQUE` (`user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8$$

