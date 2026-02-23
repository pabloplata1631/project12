DROP TABLE IF EXISTS #calendar;
CREATE TABLE #calendar (
 date DATE PRIMARY KEY,
    day_of_week VARCHAR(10),
    is_standup_day BIT,
	is_1v1_day BIT
);

-- * from #calendar;

DROP TABLE IF EXISTS #standup_attendance ;
CREATE TABLE #standup_attendance  (
    id INT IDENTITY(1,1),
    date DATE NOT NULL,
    boss_attended BIT,
	boss_late BIT,
	boss_attended_1v1 BIT,
	boss_late_1v1 BIT,
    notes NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE(),
   FOREIGN KEY (date) REFERENCES #calendar(date)
);


--Select * from #standup_attendance;


WITH date_range AS (
    SELECT CAST('2025-01-01' AS DATE) as date
    UNION ALL
    SELECT DATEADD(DAY, 1, date)
    FROM date_range
    WHERE date < '2025-12-31'
)
INSERT INTO #calendar (date, day_of_week, is_standup_day,is_1v1_day)
SELECT 
    date,
    DATENAME(WEEKDAY, date) as day_of_week,
    CASE DATENAME(WEEKDAY, date)
        WHEN 'Monday' THEN 1
        WHEN 'Wednesday' THEN 1
        WHEN 'Friday' THEN 1
        ELSE 0
    END as is_standup_day,
	    CASE DATENAME(WEEKDAY, date)
        WHEN 'Monday' THEN 1
        ELSE 0
    END as is_1v1_day
FROM date_range
WHERE DATENAME(WEEKDAY, date) NOT IN ('Saturday', 'Sunday')
OPTION (MAXRECURSION 0);

---Below updating all weekdays in nov to 1 since all standups 
UPDATE #calendar
SET is_standup_day = 1
WHERE date IN (

'2025-11-05','2025-11-06','2025-11-07','2025-11-10','2025-11-11','2025-11-13','2025-11-14','2025-11-17','2025-11-18',
'2025-11-20','2025-11-21','2025-11-24','2025-11-25','2025-11-26','2025-11-28','2025-12-01','2025-12-02','2025-12-03',
'2025-12-04','2025-12-05','2025-12-08','2025-12-09','2025-12-10','2025-12-11','2025-12-12'

);




--Select * from #calendar;
 ----Insert record when boss NO SHOW
Insert INTO #standup_attendance (date, boss_attended, notes)
VALUES 
('2025-11-24',	0, 	'No show at 9am standup'),
('2025-11-25',	0,	'No show at 9am standup'),
('2025-12-02',	0,	'No show - No Notice'),
('2025-12-04',	0,	'Jason Moline  9:31 AM sorry i missed standup- anything urgent? Tysen Singletary  9:31 AM Nah youre golden'),
('2025-12-17', 0, 'Jason - Message Tysen he isnt coming '),
('2025-12-19', 0, 'No show - No Notice');

----Insert record when boss Late
Insert INTO #standup_attendance (date, boss_late, notes)
VALUES 
('2025-12-08',	0, 	'Jason Moline  9:07 AM - Running late myself, be right there'),
('2025-12-09',	0,	'Joined 9:09')
;

----Insert record when boss Lateto 1v1

Insert INTO #standup_attendance (date, boss_attended_1v1, notes)
VALUES 
('2025-12-08',	0, 	'Jason Moline  12:51 PM good to know, i''ll poke around on who to sort that out with
12:51 anything new to catch up on? or did our earlier convo do us good for 1:1? Pablo Plata');

----Insert record when boss Lateto 1v1

Insert INTO #standup_attendance (date, boss_late_1v1, notes)
VALUES 
('2025-12-15',	0, 	'Jason Moline  1:07 PM hey- coming');

----- ANALYSIS  

--Select * from #calendar;
	With calendar as (
	select * from #calendar c
	where c.date >= '2025-11-10' -- Jason arrival
	--AND is_standup_day = 1
	AND c.date <= GETDATE() --- Only count standups that have already happened
	)
	--,total_meetings as(
	Select 
   SUM(CAST(is_standup_day AS INT)) + 
    CASE WHEN MAX(c.date) >= '2025-12-08' 
         THEN SUM(CAST(is_1v1_day AS INT)) 
         ELSE 0 
    END as test 
	from calendar c
	)
	, standup_attendance as
	(
	Select * from #standup_attendance sa Where  sa.date > '2025-11-10' ---- START OF Standups
	)


SELECT 
    COUNT(c.is_standup_day) as total_meetings,
    COUNT(c.is_standup_day) - COUNT(sa.date) as attended,
    COUNT(sa.date) as missed,
    ROUND(
        ((COUNT(c.is_standup_day) - COUNT(sa.date)) * 100.0) / COUNT(c.is_standup_day), 
        2
    ) as attendance_rate_percent
FROM calendar c
LEFT JOIN standup_attendance sa ON c.date = sa.date
WHERE c.is_standup_day = 1
    AND c.date <= GETDATE() -- Only count standups that have already happened
	And c.date > '2025-11-10' --  START OF Standups
	;

	--------

	SELECT 
    COUNT(c.date) as total_standups,
    COUNT(c.date) - COUNT(CASE WHEN sa.boss_attended = 0 THEN 1 END) as attended,
    COUNT(CASE WHEN sa.boss_attended = 0 THEN 1 END) as missed,
    ROUND(
        ((COUNT(c.date) - COUNT(CASE WHEN sa.boss_attended = 0 THEN 1 END)) * 100.0) / COUNT(c.date), 
        2
    ) as attendance_rate_percent,
	COUNT(CASE WHEN sa.boss_late = 0 THEN 1 END) as late,
    ROUND(
        ((COUNT(c.date) - COUNT(CASE WHEN sa.boss_late = 0 THEN 1 END)) * 100.0) / COUNT(c.date), 
        2
    ) as late_rate_percent,
	    ROUND(
        ((COUNT(c.date) - COUNT(sa.date)) * 100.0) / COUNT(c.date), 
        2
    ) as late_rate_percent
FROM #calendar c
LEFT JOIN #standup_attendance sa ON c.date = sa.date
WHERE c.is_standup_day = 1
    AND c.date <= GETDATE() -- Only count standups that have already happened
	And c.date > '2025-11-10' -- Jason arrival
	;


	----
	--Select * from #calendar;
	With calendar as (
	select * from #calendar c
	where c.date >= '2025-12-08' --- START OF 1v1s
	AND is_1v1_day = 1
	AND c.date <= GETDATE() --- Only count standups that have already happened
	), standup_attendance as
	(
	Select * from #standup_attendance sa Where  sa.date >= '2025-12-08' ---- START OF 1v1s
	)


		SELECT 
    COUNT(c.is_1v1_day) as total_1v1,
    COUNT(c.is_1v1_day) - COUNT(boss_attended_1v1) as attended,
    COUNT(boss_attended_1v1) as missed,
ROUND(
        ((COUNT(is_1v1_day) - COUNT(boss_attended_1v1)) * 100.0) / 
        NULLIF(COUNT(is_1v1_day), 0), 
        2
    ) attendance_rate_percent,
    COUNT(boss_late_1v1) as late,
ROUND(
        ((COUNT(is_1v1_day) - COUNT(  sa.boss_late_1v1 )) * 100.0) / 
        NULLIF(COUNT(is_1v1_day), 0), 
        2
    ) as on_time_rate_percent_1v1
FROM calendar c
LEFT JOIN standup_attendance sa ON c.date = sa.date
WHERE 1=1
--and c.is_1v1_day = 1
    AND c.date <= GETDATE() -- Only count standups that have already happened
	
	;


-- Query to see recent attendance with details (only showing missed standups)
SELECT 
    c.date,
    c.day_of_week,
    CASE WHEN sa.boss_attended = 0 THEN 'ABSENT' WHEN sa.boss_late = 0 THEN 'LATE'  ELSE 'PRESENT' END as status,
    sa.notes
FROM #calendar c
LEFT JOIN #standup_attendance sa ON c.date = sa.date
WHERE c.is_standup_day = 1
    AND c.date <= GETDATE()
	And c.date > '2025-11-10'
ORDER BY c.date DESC;


-- Query to see recent attendance with details (only showing missed standups)

With calendar as (
	Select distinct 
    c.date,
    c.day_of_week
	FROM #calendar c
WHERE c.is_1v1_day = 1
    AND c.date <= GETDATE()
	And c.date >= '2025-12-08'
)  ,
attendance_1v1 as 
(
Select * from 
#standup_attendance
WHERE boss_attended_1v1 = 0 or boss_late_1v1 = 0
)
SELECT 
    c.date,
    c.day_of_week,
    CASE WHEN sa.boss_attended_1v1 = 0 THEN 'ABSENT' WHEN sa.boss_late_1v1 = 0 THEN 'LATE'  ELSE 'PRESENT' END as status,
    sa.notes
FROM calendar c
LEFT JOIN  attendance_1v1 sa ON c.date = sa.date
WHERE 1=1
    AND c.date <= GETDATE()
	And c.date >= '2025-12-08'
ORDER BY c.date DESC;

