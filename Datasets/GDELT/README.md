# GDELT Database

This database (http://www.gdeltproject.org/) contains a collection of events from news sources. We aggregated events in Yemen and Sierra Leone on a monthly base in clean_data/YEM.csv and clean_data/SLE.csv.

Each row is a different type of event. Each column is a month from 2010 to 2016. **GDELT.ipynb** contains an example (Example: protests in Yemen) on how to read the files and plot the distribution of protests in Yemen.


## FILES 


**raw_data/** : counts of events related to Yemen (YEM.csv) and Sierra Leone (SLE) every month since 2010, from https://cloudplatform.googleblog.com/2014/05/worlds-largest-event-dataset-now-publicly-available-in-google-bigquery.html

Query:

SELECT MonthYear, EventCode, Count(*) as N_events
FROM [gdelt-bq:full.events]
WHERE (Actor1CountryCode == CountryCode) 
AND MonthYear > 201001
GROUP BY MonthYear, EventCode
ORDER BY MonthYear


**CAMEO.eventcodes.txt**  Event code, from http://gdeltproject.org/data/lookups/CAMEO.eventcodes.txt


**GDELT.ipynb** :

_ reads the raw files file and makes a table per country where each row is a different type of event, and each column is a month from 2010 to now.

_ saves the output csv files in **clean_data**

_ shows an example of plotting a time-series of protests in Yemen
