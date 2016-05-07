# GDELT Database


**YEM.csv** : counts of events related to Yemen every month since 2010, from https://cloudplatform.googleblog.com/2014/05/worlds-largest-event-dataset-now-publicly-available-in-google-bigquery.html

Query:
SELECT MonthYear, EventCode, Count(*) as N_events
FROM [gdelt-bq:full.events]
WHERE (Actor1CountryCode == 'YEM' OR Actor2CountryCode == 'YEM') 
AND MonthYear > 201001
GROUP BY MonthYear, EventCode
ORDER BY MonthYear


**CAMEO.eventcodes.txt**  Event code, from http://gdeltproject.org/data/lookups/CAMEO.eventcodes.txt


**GDELT.ipynb** reads the YEM.csv file and makes a table where each row is a different type of event, and each column is a month from 2010 to now
