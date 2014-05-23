/* 12/9/09 ECL */
/* Add SortOrder and ShowInNav columns */
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE `cms_sys` ADD COLUMN `sys_GoogleTracker` text AFTER `sys_UseFavIcon`;
SET FOREIGN_KEY_CHECKS = 1;
