## SQL DATA CLEANING:
- This is a project in which SQL will be used for data cleaning. The aim of the project is to make the data more accurate and reliable by removing any inconsistencies or errors present in the database using SQL commands.
- The data from a survey conducted among current club members needs to be restructured in order to enhance its organization and usability
- In this project, we will:
     - Identify and remove any duplicate entries in the dataset.
     - Remove any extraneous spaces or invalid characters that could interfere with data analysis.
     - Split or combine values as necessary to better represent the underlying data.
     - Ensure that specific values (such as ages or dates) fall within expected ranges.
     - Check for and address any outliers or unusual values that could skew the analysis.
     - Correct any misspelled words or input errors that may impact the accuracy of the data.
     - Add new rows or columns to the dataset as needed to provide additional relevant information.
     - Identify and handle any null or empty values to avoid issues with data analysis.
---
##### Checking the initial rows of data in their original form can provide valuable insights, so lets take a look at the first few rows:
```tsql
SELECT 
      TOP 10 *
FROM 
      MEMBER_INFOR
```
###### result:
 MEMBER_ID  | full_name             | age | maritial_status | email                    | phone        | full_address                                 | job_title                    | membership_date 
:----------:|:---------------------:|:---:|:---------------:|:------------------------:|:------------:|:--------------------------------------------:|:----------------------------:|:---------------:
 1          | addie lush            | 40  | married         | alush0@shutterfly.com    | 254-389-8708 | 3226 Eastlawn Pass,Temple,Texas              | Assistant Professor          | 2013-07-31      
 2          | ROCK CRADICK          | 46  | married         | rcradick1@newsvine.com   | 910-566-2007 | 4 Harbort Avenue,Fayetteville,North Carolina | Programmer III               | 2018-05-27      
 3          | ???Sydel Sharvell     | 46  | divorced        | ssharvell2@amazon.co.jp  | 702-187-8715 | 4 School Place,Las Vegas,Nevada              | Budget/Accounting Analyst I  | 2017-10-06      
 4          | Constantin de la cruz | 35  | NULL            | co3@bloglines.com        | 402-688-7162 | 6 Monument Crossing,Omaha,Nebraska           | Desktop Support Technician   | 2015-10-20      
 5          |   Gaylor Redhole      | 38  | married         | gredhole4@japanpost.jp   | 917-394-6001 | 88 Cherokee Pass,New York City,New York      | Legal Assistant              | 2019-05-29      
 6          | Wanda del mar         | 44  | single          | wkunzel5@slideshare.net  | 937-467-6942 | 10864 Buhler Plaza,Hamilton,Ohio             | Human Resources Assistant IV | 2015-03-24      
 7          | Jo-ann Kenealy        | 41  | married         | jkenealy6@bloomberg.com  | 513-726-9885 | 733 Hagan Parkway,Cincinnati,Ohio            | Accountant IV                | 2013-04-17      
 8          | Joete Cudiff          | 51  | separated       | jcudiff7@ycombinator.com | 616-617-0965 | 975 Dwight Plaza,Grand Rapids,Michigan       | Research Nurse               | 2014-11-16      
 9          | mendie alexandrescu   | 46  | single          | malexandrescu8@state.gov | 504-918-4753 | 34 Delladonna Terrace,New Orleans,Louisiana  | Systems Administrator III    | 1921-03-12      
##### Check the number of invalid values:
```tsql
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
```
###### result:
| result  |
|:-------:|
| 0       |
##### Creating a function to remove special characters mixed in a first name:
```tsql
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
```
##### Lets create a temp table where we can manipulate and restructure the data without altering the original:
```tsql
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
```
##### Let's take a look at our cleaned table data:
```tsql
SELECT TOP 10 * 
FROM #CLEANED_MEMBER_INFOR
```
###### result:
 MEMBER_ID | FIRST_NAME | LAST_NAME     | AGE | MARITIAL_STATUS | MEMBER_EMAIL             | PHONE        | STREET_ADDRESS        | CITY          | STATE          | OCCUPATION                        | MEMBERSHIP_DATE  
:---------:|:----------:|:-------------:|:---:|:---------------:|:------------------------:|:------------:|:---------------------:|:-------------:|:--------------:|:---------------------------------:|:----------------:
 1         | addie      |  lush         | 40  | married         | alush0@shutterfly.com    | 254-389-8708 | 3226 Eastlawn Pass    | Temple        | Texas          | Assistant Professor               | 2013-07-31       
 2         | rock       |  cradick      | 46  | married         | rcradick1@newsvine.com   | 910-566-2007 | 4 Harbort Avenue      | Fayetteville  | North Carolina | Programmer Level 3                | 2018-05-27       
 3         | sydel      |  sharvell     | 46  | divorced        | ssharvell2@amazon.co.jp  | 702-187-8715 | 4 School Place        | Las Vegas     | Nevada         | Budget/Accounting Analyst Level 1 | 2017-10-06       
 4         | constantin |  de la cruz   | 35  | NULL            | co3@bloglines.com        | 402-688-7162 | 6 Monument Crossing   | Omaha         | Nebraska       | Desktop Support Technician        | 2015-10-20       
 5         | gaylor     |  redhole      | 38  | married         | gredhole4@japanpost.jp   | 917-394-6001 | 88 Cherokee Pass      | New York City | New York       | Legal Assistant                   | 2019-05-29       
 6         | wanda      |  del mar      | 44  | single          | wkunzel5@slideshare.net  | 937-467-6942 | 10864 Buhler Plaza    | Hamilton      | Ohio           | Human Resources Assistant Level 4 | 2015-03-24       
 7         | joann      |  kenealy      | 41  | married         | jkenealy6@bloomberg.com  | 513-726-9885 | 733 Hagan Parkway     | Cincinnati    | Ohio           | Accountant Level 4                | 2013-04-17       
 8         | joete      |  cudiff       | 51  | separated       | jcudiff7@ycombinator.com | 616-617-0965 | 975 Dwight Plaza      | Grand Rapids  | Michigan       | Research Nurse                    | 2014-11-16       
 9         | mendie     |  alexandrescu | 46  | single          | malexandrescu8@state.gov | 504-918-4753 | 34 Delladonna Terrace | New Orleans   | Louisiana      | Systems Administrator Level 3     | 2021-03-12       

##### Now that the data has been cleaned, let's search for any duplicate entries.
##### All members must have a unique email address to join. Lets try to find duplicate entries:
```TSQL
SELECT MEMBER_EMAIL, COUNT(*) QUANTIY
FROM #CLEANED_MEMBER_INFOR
GROUP BY MEMBER_EMAIL
HAVING COUNT(*) > 1
```
###### result:
 MEMBER_EMAIL               | QUANTIY  
:--------------------------:|:--------:
 ehuxterm0@marketwatch.com  | 3        
 gprewettfl@mac.com         | 2        
 greglar4r@answers.com      | 2        
 hbradenri@freewebs.com     | 2        
 mmorralleemj@wordpress.com | 2        
 nfilliskirkd5@newsvine.com | 2        
 omaccaughen1o@naver.com    | 2        
 slamble81@amazon.co.uk     | 2        

##### Now, there are 10 duplicate entries, let's delete them:
```tsql
DELETE FROM 
	#CLEANED_MEMBER_INFOR
WHERE 
	MEMBER_ID NOT IN 
	(
		SELECT MAX(MEMBER_ID)
		FROM #CLEANED_MEMBER_INFOR
		GROUP BY MEMBER_EMAIL	
	)
```

##### Let's find out how many types of maritial statuses there are and check the spelling error:
```tsql
SELECT
	MARITIAL_STATUS,
	COUNT(*) AS quantiy
FROM #CLEANED_MEMBER_INFOR
GROUP BY MARITIAL_STATUS
GO
```
###### result:
 MARITIAL_STATUS | quantiy  
:---------------:|:--------:
 married         | 876      
 separated       | 165      
 NULL            | 20       
 divorced        | 281      
 divored         | 4        

##### As we can see, we have a spelling error for 4 records.  Let's correct the error:
```tsql
UPDATE 
     #CLEANED_MEMBER_INFOR
SET 
     MARITIAL_STATUS  = 'divorced'
WHERE 
     MARITIAL_STATUS = 'divored'
GO
```

##### Now, let's check the records:
```tsql
SELECT
	MARITIAL_STATUS,
	COUNT(*) AS quantiy
FROM #CLEANED_MEMBER_INFOR
GROUP BY MARITIAL_STATUS
GO
```
###### result:
 MARITIAL_STATUS | quantiy  
:---------------:|:--------:
 married         | 876      
 separated       | 165      
 NULL            | 20       
 divorced        | 285

##### Check spelling error of state names:
```tsql
SELECT 
	[STATE]
FROM
	#CLEANED_MEMBER_INFOR
GROUP BY [STATE]
ORDER BY [STATE] ASC
GO
```
###### result:
| STATE  |
|---|
|  Puerto Rico  |
| Alabama  |
| Alaska  |
| Arizona  |
| Arkansas  |
| California  |
| Colorado  |
| Connecticut  |
| Delaware  |
| District of Columbia  |
| Districts of Columbia  |
| Florida  |
| Georgia  |
| Hawaii  |
| Idaho  |
| Illinois  |
| Indiana  |
| Iowa  |
| Kalifornia  |
| Kansas  |
| Kansus  |
| Kentucky  |
| Louisiana  |
| Maryland  |
| Massachusetts  |
| Michigan  |
| Minnesota  |
| Mississippi  |
| Missouri  |
| Montana  |
| Nebraska  |
| Nevada  |
| New Hampshire  |
| New Jersey  |
| New Mexico  |
| New York  |
| NewYork  |
| North Carolina  |
| North Dakota  |
| NorthCarolina  |
| Ohio  |
| Oklahoma  |
| Oregon  |
| Pennsylvania  |
| Rhode Island  |
| South Carolina  |
| South Dakota  |
| South Dakotaaa  |
| Tej\+F823as  |
| Tejas  |
| Tennessee  |
| Tennesseeee  |
| Texas  |
| Utah  |
| Virginia  |
| Washington  |
| West Virginia  |
      
 
##### As you can see, there are a few misspellings here. So, we will correct the misspelled state names:
```tsql
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
```
