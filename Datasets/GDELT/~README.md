# GDELT Database


## Input

Input files are downloaded from https://cloudplatform.googleblog.com/2014/05/worlds-largest-event-dataset-now-publicly-available-in-google-bigquery.html using the following query

Query:
SELECT MonthYear, EventCode, Count(*) as N_events
FROM [gdelt-bq:full.events]
WHERE (Actor1CountryCode == 'COUNTRYCODE' OR Actor2CountryCode == 'COUNTRYCODE') 
AND MonthYear > 201001
GROUP BY MonthYear, EventCode
ORDER BY MonthYear

for instance **YEM.csv** contains counts of events related to Yemen every month since 2010, divided by event type (Conflict, Appeal for humanitarian aid, etc)


**CAMEO.eventcodes.txt**  contains the event code, from http://gdeltproject.org/data/lookups/CAMEO.eventcodes.txt

## Scripts

**GDELT.ipynb** reads the input csv files and makes a table where each row is a different type of event, and each column is a month from 2010 to now

## Output files

in clean_tables/ each file contains a table with columns:

*EventCode*, *EventDescription*, tye of 

