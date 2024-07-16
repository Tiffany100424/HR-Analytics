CREATE DATABASE hr_project;

SELECT *
FROM dbo.HRDataset;

SELECT DateofTermination
FROM dbo.HRDataset
WHERE NOT DateofTermination =  GETDATE();

-- CHECK IF HAVING DUPLICATE VALUES:
SELECT EmpID, COUNT(*)
FROM dbo.HRDataset
GROUP BY EmpID
HAVING COUNT(*) > 1;

--EmpID & Position:
SELECT EmpID, Position, COUNT(*)
FROM dbo.HRDataset
GROUP BY EmpID, Position
HAVING COUNT(*) > 1;    

-- CHANGE DATE FORMAT:
UPDATE dbo.HRDataset
SET DOB = CONVERT(VARCHAR,CONVERT(DATE,DOB,101),23);

UPDATE dbo.HRDataset
SET DateofHire = FORMAT(DateofHire, 'yyyy-MM-dd');--- Update `DateofTermination` to `YYYY-MM-DD` format where not null or empty:
UPDATE dbo.HRDataset
SET DateofTermination = FORMAT(DateofTermination,'yyyy-MM-dd')
WHERE DateofTermination IS NOT NULL AND DateofTermination != ' ';

--Adding and Updating Age Column:
-- Add `Age` column:

ALTER TABLE dbo.HRDataset
ADD Age INT;
--Update `Age` based on `DOB`:

UPDATE dbo.HRDataset
SET Age = DATEDIFF(YEAR, DOB, GETDATE());

    
--Age Group Categorization:**
--Add `Age_Group` column:
    
ALTER TABLE dbo.HRDataset
ADD AgeGroup VARCHAR(10);
    
--Update `Age_Group` based on `Age`:
    
UPDATE dbo.HRDataset
SET AgeGroup = CASE 
                    WHEN Age <= 24 THEN 'UNDER 24'
                    WHEN Age BETWEEN 25 AND 34 THEN '25 - 34'
                    WHEN Age BETWEEN 35 AND 44 THEN '35 - 44'
                    WHEN Age BETWEEN 45 AND 54 THEN '45 - 54'
                    ELSE 'Over 55'
                    END;
    


------------------------------------------------------- Analysis-----------------------------------------------------------------------------------
--A.Employee Demographics

-- Total Employees
SELECT COUNT('EmpID') as total_emp
FROm dbo.HRDataset;

-- Total Active Employees:**
SELECT COUNT(*) as ActiveEmployees
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active';

-- Total New Employees by Month/Year:**
  
SELECT YEAR(DateofHire) AS year, MONTH(DateofHire) AS month, COUNT(*) AS NewEmp
FROM dbo.HRDataset
GROUP BY YEAR(DateofHire), MONTH(DateofHire)
ORDER BY year, month
;

-- Total Active Employees by Gender and Year:
SELECT Sex, COUNT(*) AS ActiveEmployees
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Sex;

-- Total Active Employees by Departments and Gender:
SELECT Department, Sex , COUNT(*) AS total_emp
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Department, Sex
ORDER BY Department ;

-- Total Active Employees by Departments and Position:
SELECT Department, Position, COUNT(EmpID) AS total_emp
FROM dbo.HRDataset
WHERE DateofTermination IS NULL
GROUP BY Department, Position
ORDER BY Department;

SELECT MIN(Age) AS youngest, MAX(Age) AS oldest
FROM dbo.HRDataset;


-- Calculate the AVG Salary of Active Employees:
SELECT AVG(Salary) as avg_salary
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active';

-- Calculate % Active versus Total Employees:
SELECT 
COUNT(*) as active_emps,
ROUND(COUNT(*) * 100/ (SELECT CAST(COUNT(*) AS float) FROM dbo.HRDataset), 2)

FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active';

-- What is the average age of Active Employees:
SELECT AVG(Age) as avg_age
FROM(SELECT 
DATEDIFF(YEAR, DOB, GETDATE()) AS Age
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active') AS t;

-- What is the number of Active Employees base on Age Group:
WITH t0 AS (
SELECT 
CASE WHEN Age <= 24 THEN'Under 24'
     WHEN Age <= 34 THEN '25-34'
	 WHEN Age <= 44 THEN '35-44'
	 WHEN Age <= 54 THEN '45-54'
	 ELSE 'Over 55' END AS AgeGroup
FROM (SELECT 
Sex,
DATEDIFF(YEAR, DOB, GETDATE()) AS Age
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active') AS t)

SELECT 
AgeGroup,
COUNT(*) AS total_active_employees
FROM t0
GROUP BY AgeGroup;

-- What is the number of Active Employees by Age Group and Gender:
WITH t0 AS (
SELECT 
Sex,
CASE WHEN Age <= 24 THEN'Under 24'
     WHEN Age <= 34 THEN '25-34'
	 WHEN Age <= 44 THEN '35-44'
	 WHEN Age <= 54 THEN '45-54'
	 ELSE 'Over 55' END AS AgeGroup
FROM (SELECT 
Sex,
DATEDIFF(YEAR, DOB, GETDATE()) AS Age
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active') AS t)

SELECT
AgeGroup,
Sex,
COUNT (*)
FROM t0
GROUP BY AgeGroup,Sex;

-- What are the avg age based on each department:
SELECT Department, AVG(Age) AS avg_age
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Department;

-- What are the avg salary of each department:
SELECT Department, AVG(Salary) AS avg_salary
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Department;

-- What are the number of absences based on departments:
SELECT Department, SUM(Absences) AS Absences
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Department
ORDER BY Absences DESC;

-- Which department had the highest performance score:
SELECT Department, PerformanceScore, COUNT(PerformanceScore) AS performance_score_count
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY Department, PerformanceScore
ORDER BY PerformanceScore, performance_score_count DESC;

-- What are the number of Active Employees based on Employment Satisfaction:
SELECT Department, emp_satisfaction, COUNT(emp_satisfaction) AS satisfaction_count
FROM (SELECT
Department,
CASE WHEN EmpStatusID <=2 THEN 'Low'
     WHEN EmpSatisfaction <= 4 THEN 'Medium'
	 ELSE 'High' END AS emp_satisfaction
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active') AS t
GROUP BY Department, emp_satisfaction
ORDER BY  Department, satisfaction_count DESC
;

-- Calculate the average of Working Years (Years of Experience):
WITH t AS(
SELECT
    CASE WHEN EmploymentStatus = 'Active' THEN DATEDIFF(YEAR, DateofHire, GETDATE())
         END AS WorkingYear
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active')

SELECT AVG(WorkingYear) AS avg_working_year
FROM t
;


-- Calculate the average of Working Years for each department:
WITH t AS(
SELECT
    Department,
	Salary,
    CASE WHEN EmploymentStatus = 'Active' THEN DATEDIFF(YEAR, DateofHire, GETDATE())
         END AS WorkingYear
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
)

SELECT Department, AVG(WorkingYear) AS avg_working_year, AVG(Salary) AS avg_salary
FROM t
GROUP BY Department
ORDER BY avg_working_year DESC
;

-- Determine the number of actives based on Employment Satisfaction:
SELECT COUNT(*) AS active_count
FROM (SELECT 
CASE WHEN EmpSatisfaction <3 THEN 'Low'
     WHEN EmpSatisfaction < 4 THEN 'Medium'
	 ELSE 'High'
	 END AS NewSatisfaction
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active') AS t
GROUP BY NewSatisfaction;

-- Determined the number of actives based on Performance score:
SELECT 
PerformanceScore, COUNT(PerformanceScore) AS Actives
FROM dbo.HRDataset
WHERE EmploymentStatus = 'Active'
GROUP BY PerformanceScore
ORDER BY Actives DESC
;


--B.Employee Turnover Analysis
SELECT Department, Position
FROM dbo.HRDataset
GROUP BY Department, Position;

-- Separations by Year:
SELECT Year(DateofTermination) AS Year, COUNT(*) AS Separations
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Active'
GROUP BY Year(DateofTermination)
ORDER BY Year;

-- Separations by Department & Position:
SELECT Department, Position , COUNT(*) AS Separations
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Active'
GROUP BY Department, Position
ORDER BY COUNT(*) DESC ;

-- Separations by Department & Gender:
SELECT Department, Position , COUNT(*) AS Separations
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Active'
GROUP BY Department, Position
ORDER BY COUNT(*) DESC ;

--Which department has highest turnover:
SELECT Department,
total_emps,
separations,
ROUND((CAST(separations AS float)/total_emps),2) * 100 AS turnover_rate,
ROUND((CAST(separations AS float)/(SELECT COUNT(*) FROM dbo.HRDataset WHERE EmploymentStatus <> 'Active' )),2) * 100 AS attrition_rate
FROM (SELECT 
Department,
COUNT(*) AS total_emps,
SUM(CASE WHEN EmploymentStatus <> 'Active' THEN 1 ELSE 0 END ) AS separations
FROM dbo.HRDataset
GROUP BY Department) as t;

-- Caculate the average tenure of employees who left:
WITH t1 AS (
SELECT 
EmploymentStatus,
Department,
(CASE WHEN EmploymentStatus = 'Active' THEN DATEDIFF(YEAR, DateofHire, GETDATE())
     ELSE DATEDIFF(YEAR, DateofHire, DateofTermination)
END) AS tenure
FROM dbo.HRDataset
) 

SELECT AVG(tenure)
FROM t1
WHERE EmploymentStatus <> 'Active';


-- Calculate the average age of separations :
SELECT
AVG(CASE WHEN EmploymentStatus <> 'Active' THEN DATEDIFF( YEAR, DOB, DateofTermination)
     ELSE DATEDIFF(YEAR, DOB, GETDATE()) END )AS NewAge
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Active';

-- Separations by Age Group:
WITH t2(EmploymentStatus,AgeGroup) AS(
SELECT 
EmploymentStatus,
CASE WHEN NewAGe <= 24 THEN 'Under 24'
     WHEN NewAge <= 34 THEN '25-34'
	 WHEN NewAge <= 44 THEN '35-44'
	 WHEN NewAge <= 54 THEN '45-54'
	 ELSE 'Over 55' END AS AgeGroup
FROM (SELECT
EmploymentStatus,
CASE WHEN EmploymentStatus <> 'Active' THEN DATEDIFF( YEAR, DOB, DateofTermination)
     ELSE DATEDIFF(YEAR, DOB, GETDATE()) END AS NewAge
FROM dbo.HRDataset
) AS t
WHERE EmploymentStatus <> 'Active')

SELECT 
AgeGroup,
COUNT (*)
FROM t2
GROUP BY AgeGroup;

-- Separations by termination reasons:
SELECT TerminationReason, COUNT(TerminationReason) AS turnover_count
FROM (SELECT 
EmploymentStatus,
CASE WHEN EmploymentStatus = 'Terminated for Cause' THEN 'Involuntary'
     WHEN EmploymentStatus = 'Voluntarily Terminated' THEN 'Voluntary' END AS TerminationReason
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Avtive') AS t
WHERE TerminationReason IS NOT NULL
GROUP BY TerminationReason;

-- Separations by Recruitment Sources:
SELECT RecruitmentSource, COUNT(EmploymentStatus) AS Separations
FROM dbo.HRDataset
WHERE EmploymentStatus <> 'Active'
GROUP BY RecruitmentSource
ORDER BY Separations DESC;








