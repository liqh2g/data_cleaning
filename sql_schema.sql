USE master
GO

IF EXISTS(SELECT * FROM SYSDATABASES WHERE NAME = 'SQL_CLEANING')
	DROP DATABASE SQL_CLEANING
GO

CREATE DATABASE SQL_CLEANING
GO

USE SQL_CLEANING
GO


IF EXISTS (SELECT * FROM SYS.tables WHERE NAME = 'MEMBER_INFOR')
	DROP TABLE MEMBER_INFOR
GO


CREATE TABLE MEMBER_INFOR(
	full_name varchar(100),
	age varchar(10) ,
	maritial_status varchar(50) ,
	email varchar(150) ,
	phone varchar(20) ,
	full_address varchar(150) ,
	job_title varchar(100) ,
	membership_date varchar(100) 
)
go
-- insert values into table from csv file using BULK INSERT
BULK INSERT MEMBER_INFOR
FROM 'D:\SQL\club_member_info.csv'
WITH(	
		Format = 'csv',
		FieldTerminator = ',', 
		RowTerminator= '0x0A',
		FIRSTROW = 2
    )
go
--create a key MEMBER_ID
ALTER TABLE MEMBER_INFOR
ADD MEMBER_ID INT IDENTITY PRIMARY KEY
go
-- converts the existing string values in the "membership_date" column into date values
UPDATE MEMBER_INFOR
SET membership_date = PARSE(membership_date AS DATE)