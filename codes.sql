CREATE TABLE IF NOT EXISTS `codes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP FUNCTION IF EXISTS RANDOM_STRING;

delimiter //
CREATE FUNCTION RANDOM_STRING(alphabet text, length INT)
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
 DECLARE result VARCHAR(255);
 DECLARE symbol CHAR(1);
 DECLARE alphabetLength INT;
 DECLARE i INT;
 DECLARE r INT;
 SET result = '';
 SET alphabetLength = CHAR_LENGTH(alphabet);
 SET i = 0;
 SET symbol = '';
 WHILE i < length DO
  SET r = FLOOR(RAND()*alphabetLength);
  SET symbol = SUBSTRING(alphabet, r+1, 1);
  SET result = CONCAT(result, symbol);
  SET i = i + 1;
 END WHILE;
 RETURN result;
END//
delimiter ;

DROP PROCEDURE IF EXISTS `GENERATE_CODE`;

delimiter //
CREATE PROCEDURE `GENERATE_CODE`(tail_length INT, count INT, alphabet text)
BEGIN
 DECLARE balance INT;
 DECLARE bufer INT;
 DECLARE insertSql LONGBLOB;
 DECLARE valuesSQL LONGBLOB;
 IF alphabet IS NULL OR alphabet = '' THEN
 	SET alphabet = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ';
 END IF;
 SET insertSql = 'INSERT IGNORE INTO `codes` (`code`) VALUES';
 SET valuesSQL = '';
 SET balance = count;
 SET bufer = 0;
 WHILE balance > 0 DO
  IF valuesSQL != '' THEN
    SET valuesSQL = CONCAT(valuesSQL,',');
  END IF;
  SET valuesSQL = CONCAT(valuesSQL,"('",RANDOM_STRING(alphabet,tail_length),"')");
  SET balance = balance - 1;
  SET bufer = bufer + 1;
  IF balance = 0 OR bufer = 1000 THEN
    SET @fullSQL = CONCAT(insertSql,valuesSQL);
    SET valuesSQL = '';
    PREPARE stmt FROM @fullSQL;
    EXECUTE stmt;
    SET balance = count - ROW_COUNT();
    SET count = balance;
    SET bufer = 0;
    DEALLOCATE PREPARE stmt;
  END IF;
 END WHILE;
END//
delimiter ;

TRUNCATE TABLE `codes`;
CALL GENERATE_CODE(4,50, '124567890abcdef');
SELECT `code` FROM `codes`;

DROP PROCEDURE IF EXISTS `GENERATE_CODE`;
DROP FUNCTION IF EXISTS `RANDOM_STRING`;
DROP TABLE IF EXISTS `codes`;
