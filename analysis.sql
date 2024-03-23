SELECT *
FROM minute_merged 
WHERE mets = 0;

-- Deleting these rows as practically MET value for a person is never 0
DELETE FROM minute_merged
WHERE mets = 0;

-- AVG values of mets, intensity, calories with respect to each minute of the day
SELECT SUBSTRING(CAST(activity_minute as TEXT),12,5) as time, AVG(mets) as met_avg, AVG(intensity) as intensity_avg, AVG(calories) as avg_calories
FROM minute_merged
GROUP BY 1
ORDER BY 1


-- AVG values for various metrics per hour grouped as average for various users
-- This table is made by merging hourly and minute merged on id and hour 
-- The data here is strictly in general for all the users.
-- dataset saved as 'avg_met_intensity_calorie_perminute.csv'
SELECT hour, AVG(calories) as calories, avg(met) as met, avg(steps) as steps, avg(intensity_count) as intensity_count
FROM (  SELECT h.id, h.hour, h.calories, m.met ,h.steps, h.intensity_count
		FROM (SELECT id,hour, avg(calories) as calories, avg(step_total) as steps, avg(total_intensity) as intensity_count
			 FROM hourly_merged
			 GROUP BY 1,2
			 ORDER BY 1,2) as h
		INNER JOIN (
					SELECT CAST(id AS VARCHAR), hour, avg(mets) as met
					FROM minute_merged
					GROUP BY 1,2
					ORDER BY 1,2 ) as m
		ON h.id = m.id AND h.hour = m.hour
	 )
GROUP BY 1
ORDER BY 1


/* hourly_table is made by using minute merged and hourly_merged tables
AVG of MET values was taken and merged with the houly_merged
days are now divided into two categories 'Weekday' and 'Weekend'
all the numeric columns are avg */
-- Dataset savedas 'weekday_vs_weekend.csv'
with hourly_table as 
(SELECT h.id,h.hour,
		CASE
			WHEN weekday = 'Sunday' THEN 'Weekend'
			WHEN weekday = 'Saturday' THEN 'Weekend'
			ELSE 'Weekday'
			END AS day,
		AVG(m.mets) as avg_met,AVG(h.calories) as calories, AVG(step_total) as steps, avg(avg_intensity) as intensity_avg
FROM hourly_merged AS h
INNER JOIN (SELECT CAST(id AS VARCHAR) as id, AVG(mets) as mets FROM minute_merged GROUP BY 1) AS m
ON h.id = m.id
GROUP BY 1,3,2
ORDER BY 1,2)

SELECT hour,day,avg(avg_met) as avg_met, avg(calories) as avg_calories, avg(steps) as avg_steps, avg(intensity_avg)as avg_intensity
FROM hourly_table
GROUP BY 2,1

-- analysis on daily activity level
SELECT *
FROM daily_activity

-- Table representing the ingeneral calories burnt , alongside total active minutes and total minutes and total steps 
-- above data is with respect to each weekday 
-- Dataset saved as "general_avtivity_7days.csv"
SELECT weekday , AVG(total_steps) as steps ,AVG(total_active_minutes) as tot_active_mins, AVG(total_minutes) as tot_min, AVG(calories) as calories
FROM daily_activity
GROUP BY weekday

-- Trying to obtain the most active hours of each day
-- This table provided with avg values of total active hours on each day in general
SELECT weekday, ROUND(AVG(total_active_hours),3) as active_hours
FROM daily_activity
GROUP BY weekday
--This table tells that there are approx total 4 hours on every weekday except sunday(3)

-- Fetching top 4 active hours for every day
-- Dataset save as "top_4_activehours_weekday.csv"
SELECT weekday, hour, intensity,rank
FROM (
		SELECT weekday, hour,intensity,
				RANK() OVER (PARTITION BY weekday ORDER BY intensity DESC) as rank
		FROM(
				SELECT weekday,hour,AVG(avg_intensity) as intensity
				FROM hourly_merged
				GROUP BY weekday ,hour
				ORDER BY weekday, intensity desc
			) subq1
	 ) subq2
WHERE rank < 5


-- Calculating AVG sleep taken on each weekday
-- Dataset as 'sleeptime_per_weekday.csv'
SELECT weekday,avg(total_minute_asleep) as sleeptime
FROM sleepday
GROUP BY 1


-- exploring minute_heartrate_merged
SELECT *
FROM minute_heartrate_merged
ORDER BY 1,2

SELECT max(heartrate) as max_heartrate, min(heartrate) as min_heartrate
FROM minute_heartrate_merged
-- minimum heartrte and maximum heartrate in the dataset are 36.8 bpm and 202 bpm repectively
-- According to medical data heartrate below 40 bpm may be concerning and related directly to dizziness, fatigue and other medical conditions 

-- cheacking for rows with heartrate lower than 40 bpm
SELECT *
FROM minute_heartrate_merged
WHERE heartrate < 40
-- There are 5 cases of heartrate to be rcorded below 40 and those are due instances while the user might be sleeping.
-- in such a case the low bpm can be explained 

-- Checking avg heartrate, avg met values, avg calories for correponding intensity values
SELECT distinct intensity , AVG(mets) as avg_met, AVG(calories) as avg_calories, AVG(heartrate) as heartrate
FROM minute_heartrate_merged
GROUP BY 1
ORDER BY heartrate desc
--Data show a general trend , while the intensity value decreases ,so does the met, calories and heartrate 


-- Now in the following query i am assigning classififcations to specific heartrate and calculating the amount of time in each category

SELECT day, heartrate_zone, ((count(heartrate_zone)) as minute_count  
FROM (
		SELECT SUBSTRING(CAST(activity_minute as TEXT),12,5) as minutes, heartrate, 
				CASE
					WHEN heartrate < 100 THEN 'resting'
					WHEN heartrate BETWEEN 100 AND 140 THEN 'moderate'
					WHEN heartrate BETWEEN 141 AND 170 THEN 'vigorous'
					ELSE 'peak'
					END AS heartrate_zone,
				CASE
						WHEN weekday = 'Sunday' THEN 'Weekend'
						WHEN weekday = 'Saturday' THEN 'Weekend'
						ELSE 'Weekday'
						END AS day
		FROM minute_heartrate_merged
		WHERE heartrate IS NOT NULL
	 ) subq
GROUP BY 1,2




--------------------------------------------------------------------------------------------------------------------------------------------------------
							 
							 
							 
							 
							 
							 