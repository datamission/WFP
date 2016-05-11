
## Background
Climate Hazards Group InfraRed Precipitation with Station data (CHIRPS) is a 30+ year quasi-global rainfall dataset. The data is collected from satellite imagery and weather stations around the world. See http://chg.geog.ucsb.edu/data/chirps/index.html and http://chg-wiki.geog.ucsb.edu/wiki/CHIRPS_FAQ for more information.

## Data
You can download the data from ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/. Note there are two versions of CHIRPS, I have selected the latest (version 2.0). In this root ftp-folder there is also a README describing the data in the different subfolders.

The CHIRPS data is built around satellite imagery. This means that a lot of the data consists of image files (TIFF). In some of the folders there is however data availabe in the NetCDF format (https://en.wikipedia.org/wiki/NetCDF). This data is easier to transform into a table format and luckily there is a R package to help us with that (https://journal.r-project.org/archive/2013-2/michna-woods.pdf).

## Code
The R script ***parse_chirps.R*** reads in a NetCDF file and transforms it into a table format. The resulting data includes precipitation value per longitude, latitude and time value. The script was based on data taken from the global_daily subfolder of the ftp (ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/global_daily/netcdf/p25/). After parsing the data will look like what is in example_parsed.csv.

To download all the files from a subfolder you can use the ***download_subfolder.R*** script.

