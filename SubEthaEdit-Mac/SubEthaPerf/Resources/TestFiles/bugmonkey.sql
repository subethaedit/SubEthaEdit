-- MySQL dump 10.9
--
-- Host: localhost    Database: bugmonkey
-- ------------------------------------------------------
-- Server version	4.1.14-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `issue_id` int(11) NOT NULL default '0',
  `user_id` int(11) NOT NULL default '1',
  `comment` text NOT NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `private` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `issue_attachments`
--

DROP TABLE IF EXISTS `issue_attachments`;
CREATE TABLE `issue_attachments` (
  `id` int(11) NOT NULL auto_increment,
  `issue_id` int(11) NOT NULL default '0',
  `position` int(11) NOT NULL default '0',
  `uploader_id` int(11) NOT NULL default '0',
  `attachment_type` varchar(255) NOT NULL default '',
  `original_filename` varchar(255) NOT NULL default '',
  `filename` varchar(255) NOT NULL default '',
  `content_type` varchar(255) default NULL,
  `filesize` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `issue_changes`
--

DROP TABLE IF EXISTS `issue_changes`;
CREATE TABLE `issue_changes` (
  `id` int(11) NOT NULL auto_increment,
  `issue_id` int(11) NOT NULL default '0',
  `user_id` int(11) NOT NULL default '1',
  `action` varchar(255) NOT NULL default '',
  `area_of_change` varchar(255) NOT NULL default '',
  `old_value` text,
  `new_value` text,
  `private` tinyint(4) NOT NULL default '0',
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `issue_priorities`
--

DROP TABLE IF EXISTS `issue_priorities`;
CREATE TABLE `issue_priorities` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) default NULL,
  `name` varchar(32) NOT NULL default '',
  `description` text,
  `icon_name` varchar(255) default NULL,
  `color` varchar(8) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `issue_priorities`
--


/*!40000 ALTER TABLE `issue_priorities` DISABLE KEYS */;
LOCK TABLES `issue_priorities` WRITE;
INSERT INTO `issue_priorities` VALUES (1,1,'Blocker','Blocks development and/or testing work, production could not run','priority_blocker.png','#CC0000'),(2,2,'Critical','Crashes, loss of data, severe memory leak.','priority_critical.png','#FF0000'),(3,3,'Major','Major loss of function','priority_major.png','#009900'),(4,4,'Minor','Minor loss of function, or other problem where easy workaround is present.','priority_minor.png','#006600'),(5,5,'Trivial','Cosmetic problem like misspelled text.','priority_trivial.png','#003300');
UNLOCK TABLES;
/*!40000 ALTER TABLE `issue_priorities` ENABLE KEYS */;

--
-- Table structure for table `issue_reproducibilities`
--

DROP TABLE IF EXISTS `issue_reproducibilities`;
CREATE TABLE `issue_reproducibilities` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) NOT NULL default '0',
  `name` varchar(32) NOT NULL default '',
  `description` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `issue_reproducibilities`
--


/*!40000 ALTER TABLE `issue_reproducibilities` DISABLE KEYS */;
LOCK TABLES `issue_reproducibilities` WRITE;
INSERT INTO `issue_reproducibilities` VALUES (1,1,'Always','This issue behaves always this way.'),(2,2,'Sometimes','The issue doens\'t occur all the time'),(3,3,'Unable','The issue occured once, but isn\'t reproducable.'),(4,4,'I Didn\'t Try','There is no data on reproducibility of the issue'),(5,5,'Not Applicable','Reproducabilty is not applicable for this issue.');
UNLOCK TABLES;
/*!40000 ALTER TABLE `issue_reproducibilities` ENABLE KEYS */;

--
-- Table structure for table `issue_resolutions`
--

DROP TABLE IF EXISTS `issue_resolutions`;
CREATE TABLE `issue_resolutions` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) NOT NULL default '0',
  `name` varchar(32) NOT NULL default '',
  `description` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `issue_resolutions`
--


/*!40000 ALTER TABLE `issue_resolutions` DISABLE KEYS */;
LOCK TABLES `issue_resolutions` WRITE;
INSERT INTO `issue_resolutions` VALUES (1,1,'Unresolved','This issue hasn\'t been resolved yet.'),(2,2,'Fixed','A fix for this issue is checked into the tree and tested.'),(3,3,'Won\'t Fix','The problem described is an issue which will never be fixed.'),(4,4,'Duplicate','The problem is a duplicate of an existing issue.'),(5,5,'Incomplete','The problem is not completely described.'),(6,6,'Can\'t Reproduce','All attempts at reproducing this issue failed, or not enough information was available to reproduce the issue. Reading the code produces no clues as to why this behavior would occur. If more information appears later, please reopen the issue.'),(7,7,'Postponed','The problem will be considered for a fix in the future.');
UNLOCK TABLES;
/*!40000 ALTER TABLE `issue_resolutions` ENABLE KEYS */;

--
-- Table structure for table `issue_statuses`
--

DROP TABLE IF EXISTS `issue_statuses`;
CREATE TABLE `issue_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) default NULL,
  `name` varchar(32) default NULL,
  `description` text,
  `icon_name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `issue_statuses`
--


/*!40000 ALTER TABLE `issue_statuses` DISABLE KEYS */;
LOCK TABLES `issue_statuses` WRITE;
INSERT INTO `issue_statuses` VALUES (1,1,'Open','The issue is open and ready for the assignee to start work on it','status_open.png'),(2,2,'Reopened','This issue was once resolved, but the resolution was deemed incorrect. From here issues are either marked assigned or resolved.','status_reopened.png'),(3,3,'In Progress','This issue is being actively worked on at the moment by the assignee.','status_inprogress.png'),(4,4,'Feedback','This issue requires feedback to be worked on.','status_feedback.png'),(5,5,'Resolved','A resolution has been taken, and it is awaiting verification by reporter. From here issues are either reopened, or are closed.','status_resolved.png'),(6,6,'Closed','The issue is considered finished, the resolution is correct. Issues which are not closed can be reopened.','status_closed.png'),(7,7,'Incoming','This issue was reported by a public reporter and has to be reviewed by an insider to become an open or closed duplicate.','status_incoming.png');
UNLOCK TABLES;
/*!40000 ALTER TABLE `issue_statuses` ENABLE KEYS */;

--
-- Table structure for table `issue_types`
--

DROP TABLE IF EXISTS `issue_types`;
CREATE TABLE `issue_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(32) NOT NULL default '',
  `description` text,
  `position` int(11) NOT NULL default '0',
  `icon_name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `issue_types`
--


/*!40000 ALTER TABLE `issue_types` DISABLE KEYS */;
LOCK TABLES `issue_types` WRITE;
INSERT INTO `issue_types` VALUES (1,'Bug','A problem which impairs or prevents the functions of the product.',1,'issue_bug.png'),(3,'Feature','A new feature of the product, which has yet to be developed.',3,'issue_newfeature.png'),(4,'Task','a taks that needs to be done.',4,'issue_task.png'),(2,'Improvement','An improvement or enhancement to an existing feature or task.',2,'issue_improvement.png');
UNLOCK TABLES;
/*!40000 ALTER TABLE `issue_types` ENABLE KEYS */;

--
-- Table structure for table `issues`
--

DROP TABLE IF EXISTS `issues`;
CREATE TABLE `issues` (
  `id` int(11) NOT NULL auto_increment,
  `reporter_id` int(11) NOT NULL default '1',
  `project_id` int(11) NOT NULL default '0',
  `duplicates_issue_id` int(11) default NULL,
  `relation_cloud_id` int(11) default NULL,
  `affects_project_version_id` int(11) default NULL,
  `fix_for_project_version_id` int(11) default NULL,
  `issue_number` int(11) NOT NULL default '0',
  `issue_type_id` int(11) NOT NULL default '0',
  `assignee_id` int(11) default '0',
  `issue_status_id` int(11) NOT NULL default '1',
  `issue_priority_id` int(11) default NULL,
  `issue_resolution_id` int(11) NOT NULL default '1',
  `issue_reproducibility_id` int(11) default NULL,
  `title` varchar(255) NOT NULL default '',
  `details` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `closed_at` datetime default NULL,
  `index_text` text,
  PRIMARY KEY  (`id`),
  FULLTEXT KEY `newindex` (`title`,`details`,`index_text`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


--
-- Table structure for table `issues_tags`
--

DROP TABLE IF EXISTS `issues_tags`;
CREATE TABLE `issues_tags` (
  `issue_id` int(11) NOT NULL default '0',
  `tag_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`issue_id`,`tag_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `next_ids`
--

DROP TABLE IF EXISTS `next_ids`;
CREATE TABLE `next_ids` (
  `name` varchar(250) NOT NULL default '',
  `next_id` int(10) unsigned NOT NULL default '2',
  PRIMARY KEY  (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `project_versions`
--

DROP TABLE IF EXISTS `project_versions`;
CREATE TABLE `project_versions` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) NOT NULL default '0',
  `project_id` int(11) NOT NULL default '0',
  `name` varchar(255) NOT NULL default '',
  `description` varchar(255) default NULL,
  `released_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
CREATE TABLE `projects` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(100) default NULL,
  `project_key` varchar(32) default NULL,
  `description` text,
  `image_extension` varchar(100) default NULL,
  `public` tinyint(1) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `relation_clouds`
--

DROP TABLE IF EXISTS `relation_clouds`;
CREATE TABLE `relation_clouds` (
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `login` varchar(100) NOT NULL default '',
  `hashed_password` varchar(88) NOT NULL default '',
  `email` varchar(255) NOT NULL default '',
  `firstname` varchar(100) NOT NULL default '',
  `surname` varchar(100) NOT NULL default '',
  `insider` int(11) NOT NULL default '0',
  `registered` int(11) NOT NULL default '0',
  `image_extension` varchar(100) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `logged_in_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `login_index` USING BTREE (`login`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `users`
--


/*!40000 ALTER TABLE `users` DISABLE KEYS */;
LOCK TABLES `users` WRITE;
INSERT INTO `users` VALUES (1,'anonymous','','','Ano','Nymous',0,0,NULL,'2005-12-15 21:54:24','2005-12-15 21:54:24',NULL),(2,'admin','x61Ey612Kl2gpFL56FT9weDnpSo4AV8j8+qx2AuTHdRyY036xxzTTrw10Wq3+4qQyB+XURPWx1ONxp3Y3pB37A==','','Admini','Strator',1,1,'jpg','2005-12-15 21:54:24','2005-12-20 11:38:02','2005-12-20 10:54:34');
UNLOCK TABLES;
/*!40000 ALTER TABLE `users` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

