-- ---------------------------------------------------------------------------
-- task 1 -- create schema and load denormalized table 

CREATE SCHEMA pandemic;

USE pandemic;

-- import denormalized infectious_cases table 

SELECT * FROM infectious_cases;

SELECT COUNT(*) FROM infectious_cases;

-- ---------------------------------------------------------------------------
-- task 2 -- table normalization

-- create countries table
CREATE TABLE countries (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(50),
code VARCHAR(8)
);

SELECT COUNT(DISTINCT Entity, Code) as unique_countries FROM infectious_cases;

INSERT INTO countries (name, code) (SELECT DISTINCT Entity, Code  FROM infectious_cases);

SELECT * FROM countries;

-- normalize infectious_cases table
ALTER TABLE infectious_cases ADD COLUMN id INT FIRST;

SET @row_number = 0;

UPDATE infectious_cases SET id = (@row_number:= @row_number+1) ORDER BY Entity;

ALTER TABLE infectious_cases MODIFY COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE infectious_cases  ADD COLUMN country_id INT DEFAULT NULL AFTER id, 
ADD FOREIGN KEY (country_id) REFERENCES countries(id); 

-- insert correspondent country_id into infectious_cases table
UPDATE infectious_cases ic JOIN countries c ON ic.Entity=c.name SET ic.country_id=c.id;

-- drop unnecessary columns 
ALTER TABLE infectious_cases DROP COLUMN Entity, DROP COLUMN Code;

SELECT * FROM infectious_cases;

-- ---------------------------------------------------------------------------
-- task 3 -- count by country_id
SELECT temp.country_id,  
AVG(temp.Number_rabies) as avg_num_rabies, 
MIN(temp.Number_rabies) as min_num_rabies, 
MAX(temp.Number_rabies) as max_num_rabies,
SUM(temp.Number_rabies) as sum_num_rabies
FROM (SELECT country_id, Number_rabies FROM infectious_cases WHERE Number_rabies!="") as temp
GROUP BY temp.country_id
ORDER BY  avg_num_rabies DESC
LIMIT 10;

-- ---------------------------------------------------------------------------
-- task 4 -- count difference in years
ALTER TABLE infectious_cases ADD COLUMN `date` DATE AFTER `Year`, 
ADD COLUMN `current_date` DATE AFTER `date`, 
ADD COLUMN `difference_in_years` INT AFTER `current_date`;

UPDATE infectious_cases SET `date`= MAKEDATE(Year, 1),`current_date`= CURDATE();

UPDATE infectious_cases SET `difference_in_years`= TIMESTAMPDIFF(YEAR, `date`,`current_date`);

SELECT * FROM infectious_cases;

-- ---------------------------------------------------------------------------
-- task 5 -- create a function to calculate difference detween dates in years
DROP FUNCTION IF EXISTS get_date_diff_in_years;

DELIMITER //

CREATE FUNCTION get_date_diff_in_years(year INT)
RETURNS INT
NO SQL
BEGIN
    DECLARE years_diff INT;
    SET years_diff = TIMESTAMPDIFF(YEAR, MAKEDATE(year, 1),CURDATE());
    RETURN years_diff;
END //

DELIMITER ;

SELECT get_date_diff_in_years(Year) as diff_in_years FROM infectious_cases LIMIT 5;

-- ---------------------------------------------------------------------------
-- task 5.1 -- create a function to calculate number of desease per period
DROP FUNCTION IF EXISTS get_number__of_desease_per_period;

DELIMITER //

CREATE FUNCTION get_number__of_desease_per_period(number_per_year INT,  divider INT)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    DECLARE des_number INT;
    SET des_number = number_per_year / divider;
    RETURN des_number;
END //

DELIMITER ;

SELECT get_number__of_desease_per_period(SUM(temp.Number_malaria), 12) as malaria_per_month_1999 
FROM (SELECT Number_malaria FROM infectious_cases WHERE Year=1999 AND Number_malaria != "") as temp; 

SELECT get_number__of_desease_per_period(SUM(temp.Number_malaria), 4) as malaria_per_quater_1991
FROM (SELECT Number_malaria FROM infectious_cases WHERE Year=1991 AND Number_malaria != "") as temp;

SELECT get_number__of_desease_per_period(SUM(temp.Number_cholera_cases), 2) as cholera_per_half_year_2005 
FROM (SELECT Number_cholera_cases FROM infectious_cases WHERE Year=2005  AND Number_cholera_cases != "") as temp;
