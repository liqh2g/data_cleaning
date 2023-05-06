## An SQL data cleaning project
---
#### A survey was done of current club members and we would like to restructure the data to a more organized and usable form.
#### In this project, we will:
     1. Identify and remove any duplicate entries in the dataset.
     2. Remove any extraneous spaces or invalid characters that could interfere with data analysis.
     3. Split or combine values as necessary to better represent the underlying data.
     4. Ensure that specific values (such as ages or dates) fall within expected ranges.
     5. Check for and address any outliers or unusual values that could skew the analysis.
     6. Correct any misspelled words or input errors that may impact the accuracy of the data.
     7. Add new rows or columns to the dataset as needed to provide additional relevant information.
     8. Identify and handle any null or empty values to avoid issues with data analysis.
##### Checking the initial rows of data in their original form can provide valuable insights, so lets take a look at the first few rows:
```tsql
SELECT 
      TOP 10 *
FROM 
      MEMBER_INFOR
```
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
##### Check  the validity of an email:
```tsql
SELECT 
email
FROM 
MEMBER_INFOR
WHERE 
email LIKE '%@%.%' -- Check if there is at least one character '@' and one character '.' in the value.
AND email NOT LIKE '%@%@%' -- Check if there are no two consecutive '@' characters.
AND email NOT LIKE '%..%' -- Check if there are no two consecutive '.' characters.
AND PATINDEX('%[^a-zA-Z0-9.@_-]%', email) = 0 -- Check if there are no invalid characters other than letters, numbers, special characters '@', '.', '_', and '-'.
GO 
```
