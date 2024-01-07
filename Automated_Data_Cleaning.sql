-- Automated Data Cleaning

SELECT * FROM bakery.us_household_income;

SELECT * FROM bakery.us_household_income_Cleaned;


DELIMITER //
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
-- Creating our table
    CREATE TABLE IF NOT EXISTS `us_household_income_Cleaned` (
    `row_id` int DEFAULT NULL,
    `id` int DEFAULT NULL,
    `State_Code` int DEFAULT NULL,
    `State_Name` text,
    `State_ab` text,
    `County` text,
    `City` text,
    `Place` text,
    `Type` text,
    `Primary` text,
    `Zip_Code` int DEFAULT NULL,
    `Area_Code` int DEFAULT NULL,
    `ALand` int DEFAULT NULL,
    `AWater` int DEFAULT NULL,
    `Lat` text,
    `Lon` text,
    `TimeStamp` TIMESTAMP DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copy data to new table
	INSERT INTO us_household_income_Cleaned
    SELECT *, CURRENT_TIMESTAMP()
    FROM bakery.us_household_income;

-- Remove Duplicates
	DELETE FROM us_household_income_Cleaned 
	WHERE 
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id, `TimeStamp`
				ORDER BY id, `TimeStamp`) AS row_num
		FROM 
			us_household_income_Cleaned
	) duplicates
	WHERE 
		row_num > 1
	);

-- Fixing some data quality issues by fixing typos and general standardization
	UPDATE us_household_income_Cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_Cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_Cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_Cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_Cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_Cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_Cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';


END//
DELIMITER ;


CALL Copy_and_Clean_Data();


DROP EVENT run_data_cleaned;
CREATE EVENT run_data_cleaned
	ON SCHEDULE EVERY 30 DAY
	DO CALL Copy_and_Clean_Data();



-- Create Trigger
DELIMITER //
DROP TRIGGER IF EXISTS Transfer_cleaned_data;
CREATE TRIGGER Transfer_cleaned_data
AFTER INSERT ON bakery.us_household_income
FOR EACH ROW
BEGIN
    CALL Copy_and_Clean_Data();
END;
//

DELIMITER ;


INSERT INTO bakery.us_household_income
()
VALUES
();




-- Debugging or checking store procedure work before
 
	SELECT row_id, id, row_num
    FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM 
		us_household_income
	) duplicates
	WHERE 
		row_num > 1;

SELECT COUNT(row_id)
FROM us_household_income;

SELECT State_name, COUNT(State_name)
FROM us_household_income
GROUP BY (State_name);


-- Debugging or checking store procedure work after


SELECT row_id, id, row_num
    FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM 
		us_household_income_Cleaned
	) duplicates
	WHERE 
		row_num > 1;

SELECT COUNT(row_id)
FROM us_household_income_Cleaned;

SELECT State_name, COUNT(State_name)
FROM us_household_income_Cleaned
GROUP BY (State_name);

