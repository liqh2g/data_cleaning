/*
A survey was done of current club members and we would like to restructure the data to a more organized and usable form.
In this project, we will 
	1. Identify and remove any duplicate entries in the dataset.
	2. Remove any extraneous spaces or invalid characters that could interfere with data analysis.
	3. Split or combine values as necessary to better represent the underlying data.
	4. Ensure that specific values (such as ages or dates) fall within expected ranges.
	5. Check for and address any outliers or unusual values that could skew the analysis.
	6. Correct any misspelled words or input errors that may impact the accuracy of the data.
	7. Add new rows or columns to the dataset as needed to provide additional relevant information.
	8. Identify and handle any null or empty values to avoid issues with data analysis.
*/

--Examining the initial rows of data in their original form can provide valuable insights, so lets take a look at the first few rows.
SELECT TOP 10 *
FROM MEMBER_INFOR
GO

-- check the validity of an email 
WITH Check_email AS(
	SELECT 
		email
	FROM 
		MEMBER_INFOR
	WHERE 
		email LIKE '%@%.%' -- Check if there is at least one character '@' and one character '.' in the value.
		AND email NOT LIKE '%@%@%' -- Check if there are no two consecutive '@' characters.
		AND email NOT LIKE '%..%' -- Check if there are no two consecutive '.' characters.
		AND PATINDEX('%[^a-zA-Z0-9.@_-]%', email) = 0 -- Check if there are no invalid characters other than letters, numbers, special characters '@', '.', '_', and 
)
SELECT
	COUNT(email) AS 'result'
FROM 
	MEMBER_INFOR
WHERE 
	email NOT IN ( SELECT email FROM Check_email)
GO

--Creating a function to remove special characters mixed in a first name 
CREATE FUNCTION 
	dbo.Remove_SpecialCharacters( @str VARCHAR(MAX))
RETURNS VARCHAR(MAX) AS
BEGIN
	SET @str = SUBSTRING(TRIM(LOWER(@str)),1,PATINDEX('% %', TRIM(LOWER(@str))) - 1)
	DECLARE @expres  VARCHAR(50) = '%[~,@,#,$,%,&,*,(,),.,!,?,-]%'
	WHILE PATINDEX( @expres, @str ) > 0
		SET @str = REPLACE( @str, SUBSTRING( @str, PATINDEX( @expres, @str ), 1 ),'')
RETURN @str
END
GO


--Lets create a temp table where we can manipulate and restructure the data without altering the original.
SELECT	MEMBER_ID,

		--Some names contain additional spaces and special characters. Remove any excess white space, eliminate special characters, and convert the names to lowercase
		--In this specific dataset, special characters only appear in the first name and can be removed by using the previously created function
		dbo.Remove_SpecialCharacters(full_name) AS FIRST_NAME,

		--Some last names have multiple words ('de palma' or 'de la cruz').
		--Extract a substring from the full name, starting at the position of the first space and ending at the end of the string. This substring represents the last name of the members.
		SUBSTRING(TRIM(LOWER(full_name)),PATINDEX('% %', TRIM(LOWER(full_name))),LEN(full_name)) AS LAST_NAME,

		/*
		-Some ages entered contain an extra digit at the end. Remove it for ages with three digits.
		-Convert empty values to NULL.
		-Check the character length. If the condition is true, extract the first two digits.*/
		CASE 
			WHEN LEN(age) = 0 THEN NULL
			WHEN LEN(age) = 3 THEN SUBSTRING(age,1,2)
			ELSE age
		END AGE,

		--Remove any whitespace from the 'maritial_status' column and if it is blank, convert it to a null value
		CASE 
			WHEN TRIM(maritial_status) = '' THEN NULL
			ELSE TRIM(maritial_status)
		END MARITIAL_STATUS,

		/*
		Email addresses are mandatory, and this dataset includes valid email addresses. 
		As email addresses are case-insensitive, convert them to lowercase and remove any leading or trailing whitespace.
		*/
		TRIM(LOWER(email)) AS MEMBER_EMAIL,

		--Remove any whitespace from the 'phone' column and if it is blank or incomplete, convert it to a null value.
		CASE 
			WHEN TRIM(phone) = '' THEN NULL
			WHEN LEN(TRIM(phone)) < 12 THEN NULL
			ELSE TRIM(phone) 
		END PHONE,

		--Members need a full address for billing, but since multiple members can live in the same household, the address cannot be unique.
		--Trim the address, then split it into individual fields for street, city, and state
		SUBSTRING(TRIM(full_address),1,CHARINDEX(',', TRIM(full_address))-1) AS STREET_ADDRESS,
		SUBSTRING(TRIM(full_address),CHARINDEX(',', TRIM(full_address))+1,CHARINDEX(',',TRIM(full_address),CHARINDEX(',', TRIM(full_address))+1)-CHARINDEX(',', TRIM(full_address))-1) AS CITY,
		SUBSTRING(TRIM(full_address),CHARINDEX(',',TRIM(full_address),CHARINDEX(',',TRIM(full_address))+1)+1, LEN(TRIM(full_address))) as [STATE],

		--Within the dataset, certain job titles use Roman numerals (I, II, III, IV) to indicate a level of seniority. 
		--To standardize these titles, convert the Roman numerals to their corresponding numbers and add a descriptor (such as 'Level 4'). 
		--Additionally, remove any leading or trailing whitespace from the job title, rename it to 'occupation,' and if it is empty, convert it to a null value
		CASE 
			WHEN TRIM(TRIM(job_title)) = '' THEN NULL
		ELSE
			CASE
				WHEN PATINDEX('% I',TRIM(job_title)) <> 0 AND SUBSTRING(TRIM(job_title),PATINDEX('% I%',TRIM(job_title)),PATINDEX('% I',TRIM(job_title))) = ' I'
					THEN REPLACE(job_title,' I', ' Level 1')
				WHEN PATINDEX('% II',TRIM(job_title)) <> 0 AND SUBSTRING(TRIM(job_title),PATINDEX('% II',TRIM(job_title)),PATINDEX('% II',TRIM(job_title))) = ' II'
					THEN REPLACE(job_title,' II', ' Level 2')
				WHEN PATINDEX('% III',TRIM(job_title)) <> 0 AND SUBSTRING(TRIM(job_title),PATINDEX('% III',TRIM(job_title)),PATINDEX('% III',TRIM(job_title))) = ' III'
					THEN REPLACE(job_title,' III', ' Level 3')
				WHEN PATINDEX('% IV',TRIM(job_title)) <> 0 AND SUBSTRING(TRIM(job_title),PATINDEX('% IV%',TRIM(job_title)),PATINDEX('% IV%',TRIM(job_title))) = ' IV'
					THEN REPLACE(job_title,' IV', ' Level 4')
				ELSE TRIM(job_title)
			END
		END OCCUPATION,
		
		--Some members have a membership_date year in the 1900s. To update these records, change the year to the 2000s
		CASE
			WHEN YEAR(membership_date) < 2000
				THEN CAST(DATEADD(YY,100,membership_date) AS DATE)
		ELSE membership_date
		END MEMBERSHIP_DATE
INTO 
	#CLEANED_MEMBER_INFOR
FROM 
	MEMBER_INFOR
GO

--Let's take a look at our cleaned table data.
SELECT TOP 10 * FROM #CLEANED_MEMBER_INFOR
GO

--Now that the data has been cleaned, let's search for any duplicate entries and determine the total count of records
SELECT COUNT(*)AS TOTAL
FROM #CLEANED_MEMBER_INFOR
GO

--All members must have a unique email address to join. Lets try to find duplicate entries.
SELECT MEMBER_EMAIL, COUNT(*) QUANTIY
FROM #CLEANED_MEMBER_INFOR
GROUP BY MEMBER_EMAIL
HAVING COUNT(*) > 1
GO

--Now, there are 10 duplicate entries, let's delete them
DELETE FROM 
	#CLEANED_MEMBER_INFOR
WHERE 
	MEMBER_ID NOT IN 
	(
		SELECT MAX(MEMBER_ID)
		FROM #CLEANED_MEMBER_INFOR
		GROUP BY MEMBER_EMAIL	
	)
GO

-- What is the record after detetion?
SELECT 
	COUNT(*) AS QUANTITY
FROM 
	#CLEANED_MEMBER_INFOR
GO

--Let's find out how many types of maritial statuses there are and check the spelling error.

SELECT
	MARITIAL_STATUS,
	COUNT(*) AS quantiy
FROM #CLEANED_MEMBER_INFOR
GROUP BY MARITIAL_STATUS
GO

--As we can see, we have a spelling error for 4 records.  Let's correct the error.

UPDATE 
	#CLEANED_MEMBER_INFOR
SET 
	MARITIAL_STATUS  = 'divorced'
WHERE 
	MARITIAL_STATUS = 'divored'
GO

--Now, let's check the records
SELECT
	MARITIAL_STATUS,
	COUNT(*) AS quantiy
FROM #CLEANED_MEMBER_INFOR
GROUP BY MARITIAL_STATUS
GO

--Check spelling error of state names
SELECT 
	[STATE]
FROM
	#CLEANED_MEMBER_INFOR
GROUP BY [STATE]
ORDER BY [STATE] ASC
GO

-- As you can see, there are a few misspellings here. So, we will correct the misspelled state names

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'Puerto Rico'
WHERE 
	[STATE] = ' Puerto Rico'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'New York'
WHERE 
	[STATE] = 'NewYork'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'Kansas'
WHERE 
	[STATE] = 'Kansus'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'District of Columbia'
WHERE 
	[STATE] = 'Districts of Columbia'

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'North Carolina'
WHERE 
	[STATE] = 'NorthCarolina'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'California'
WHERE 
	[STATE] = 'Kalifornia'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'Texas'
WHERE 
	[STATE] = 'Tejas' OR [STATE] = 'Tej+F823as'
GO

UPDATE
	#CLEANED_MEMBER_INFOR
SET 
	[STATE] = 'Tennessee'
WHERE 
	[STATE] = 'Tennesseeee';

--Let's check again

SELECT 
	[STATE]
FROM
	#CLEANED_MEMBER_INFOR
GROUP BY [STATE]
ORDER BY [STATE] ASC
GO