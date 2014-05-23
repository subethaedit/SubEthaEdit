/* 11/24/09 ECL */
/* Add SortOrder and ShowInNav columns */
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE `cms_content` ADD COLUMN `ShowInNav` char(1) NOT NULL DEFAULT 'Y' after `Story`;
ALTER TABLE `cms_content` ADD COLUMN `SortOrder` tinyint(2) NOT NULL DEFAULT '0' after `ShowInNav`;
SET FOREIGN_KEY_CHECKS = 1;
