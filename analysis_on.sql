-- 2 completely different users in the table for weight
-- using the formula we can find the height

SELECT id, weight_kg, bmi, SQRT(weight_kg / bmi) AS height_m
FROM (select id,avg(weight_kg) as weight_kg,avg(bmi) as bmi
	  from weight_log_info
	  group by 1
	  order by 2 desc)
/*
Underweight:
BMI less than 18.5 kg/m²

Normal Weight:
BMI between 18.5 and 24.9 kg/m²

Overweight:
BMI between 25.0 and 29.9 kg/m²

Obese:
BMI 30.0 kg/m² or higher*/

-- selecte users have almost the same height but have completely different bmi and weight 

-- grouped data for user in obese category weighing 130kg, height 1.67m and bmi around 47.5
select  SUBSTRING(CAST(activity_minute as TEXT),12,5) as time, avg(mets) as avg_met, avg(intensity) as avg_intensity, avg(calories) as avg_calories, avg(steps) as avg_steps  from minute_merged
where id = '1927972279'
group  by 1
order by 1

-- grouped data of user Normal Weight with weight 57kg, height 1.62m and bmi around 21.5 
select  SUBSTRING(CAST(activity_minute as TEXT),12,5) as time, avg(mets) as avg_met, avg(intensity) as avg_intensity, avg(calories) as avg_calories, avg(steps) as avg_steps from minute_merged
where id = '2873212765'
group  by 1
order by 1

-- For comparision between 2 , i am using minute_merged data
-- dataset saved as 'obese_vs_normal.csv'
WITH 
	obese_table as 
		(SELECT SUBSTRING(CAST(activity_minute as text),12,5) as minutes,
		 	CASE
				WHEN weekday = 'Sunday' THEN 'Weekend'
				WHEN weekday = 'Saturday' THEN 'Weekend'
				ELSE 'Weekday'
				END AS day,
		        avg(mets) as avg_met, avg (intensity) as avg_intensity,
				avg(calories) as avg_calories, avg(steps) as avg_steps
		FROM minute_merged
		WHERE id IN ('1927972279')
		GROUP BY 1,2
		order by 2,1),
	normal_table as 
		(SELECT SUBSTRING(CAST(activity_minute as text),12,5) as minutes,
		 	CASE
				WHEN weekday = 'Sunday' THEN 'Weekend'
				WHEN weekday = 'Saturday' THEN 'Weekend'
				ELSE 'Weekday'
				END AS day,
		 		avg(mets) as avg_met, avg (intensity) as avg_intensity,
				avg(calories) as avg_calories, avg(steps) as avg_steps
		FROM minute_merged
		WHERE id IN ('2873212765')
		GROUP BY 1,2
		ORDER by 2,1)

SELECT n.minutes, o.day as day, n.avg_met as met_n, o.avg_met as met_o, n.avg_intensity as intensity_n, o.avg_intensity as intensity_o,
	   n.avg_calories as calories_n, o.avg_calories as calories_o, n.avg_steps as steps_n, o.avg_steps as steps_o
FROM normal_table as n INNER JOIN obese_table as o ON n.minutes = o.minutes AND n.day = o.day
ORDER BY day,1;

----------------------------------------------------------------------------------------------------------
-- Extracting the daily averages for the 2 users 
WITH
	normal_daily as (
						SELECT weekday, AVG(total_steps) as steps, AVG(very_active_minutes) as very_active_minutes,
							   AVG(total_active_minutes)as total_active_minutes, AVG(total_active_hours) as active_hours, AVG(calories) as calories
						FROM daily_activity
						WHERE id = '2873212765'
						GROUP BY 1
						ORDER BY 1
					),
	obese_daily as (
						SELECT weekday, AVG(total_steps) as steps, AVG(very_active_minutes) as very_active_minutes,
							   AVG(total_active_minutes)as total_active_minutes, AVG(total_active_hours) as active_hours, AVG(calories) as calories
						FROM daily_activity
						WHERE id = '1927972279'
						GROUP BY 1
						ORDER BY 1
				   )

SELECT n.weekday as day, n.steps as steps_n,o.steps as steps_o, n.very_active_minutes as very_active_minutes_n,o.very_active_minutes as very_active_minutes_o,n.total_active_minutes as total_active_minutes_n,o.total_active_minutes as total_active_minutes_o,
		n.active_hours as active_hours_n,o.active_hours as active_hours_o, n.calories as calories_n,o.calories as calories_o
FROM normal_daily as n
INNER JOIN obese_daily as o
ON o.weekday = n.weekday

-- ANALYZING the most active hours of the day for each of these 2 adults

-- firstly identifying the most active hours for both of them
-- MET and intensity values are the deciding factors here

SELECT * 
FROM (  
	    SELECT *, RANK() OVER(PARTITION BY id ORDER BY intensity desc,met desc )
		FROM (
				SELECT id,hour, AVG(mets) as met,AVG(intensity) as intensity
				FROM minute_merged
				WHERE id in ('1927972279','2873212765')
				GROUP BY 1,2
			 ) subq1
	 ) subq2
WHERE rank in (1,2)

-- for the normal weight user most active hour is deom 8 to 9 am in the morning 
-- for the obese user its the 11 th hour of the day , which is a workhour, i'd rather choose an hour that is suitable for workout analysis
-- So taking the 2nd rank hour for the ibese user, i.e., 7 to 8pm in the evening

-- data set used for the analysis --> minute_merged

-- date and time range for the 2 users in the dataset
SELECT min(activity_minute) , max(activity_minute)
FROM minute_merged
WHERE id in ('2873212765') -- normal user

SELECT min(activity_minute) , max(activity_minute)
FROM minute_merged
WHERE id in ('1927972279') -- overweight user

-- DATASET for normal weighted per son --> id '2873212765'
--dataset as 'most_active_hour_8_normal.csv'
SELECT id, CAST(SUBSTRING(CAST(minutes as TEXT),4,2) as INTEGER) as minutes, AVG(met) as met, AVG(intensity) as intensity,
		AVG(steps)as steps, AVG(calories) as calories
FROM (  SELECT id,CAST(SUBSTRING(CAST(activity_minute as TEXT),12,8) as time) as minutes,AVG(mets) as met, AVG(intensity) as intensity,
				AVG(steps) as steps, AVG(calories) as calories
		FROM minute_merged
		WHERE id in ('2873212765')
		GROUP BY 1,2
	 ) subquery
WHERE minutes BETWEEN '08:00:00' AND '08:59:00'
GROUP BY 1,2


-- dataset as 'most_active_hour_19_obese.csv'
SELECT id,CAST(SUBSTRING(CAST(minutes as TEXT),4,2) as INTEGER) as minutes, AVG(met) as met, AVG(intensity) as intensity,
		AVG(steps)as steps, AVG(calories) as calories
FROM (  SELECT id,CAST(SUBSTRING(CAST(activity_minute as TEXT),12,8) as time) as minutes,AVG(mets) as met, AVG(intensity) as intensity,
				AVG(steps) as steps, AVG(calories) as calories
		FROM minute_merged
		WHERE id in ('1927972279')
		GROUP BY 1,2
	 ) subquery
WHERE minutes BETWEEN '19:00:00' AND '19:59:00'
GROUP BY 1,2




