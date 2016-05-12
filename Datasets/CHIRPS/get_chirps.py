from bs4 import BeautifulSoup
import urllib2
import os

## GET LIST OF CHIRPS FILES

url = "ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/global_daily/netcdf/p25/"
req = urllib2.Request(url)
response = urllib2.urlopen(req)
the_page = response.read()

page = str(BeautifulSoup(the_page)) # entire page

firstsplit=page.split('\r\n')
secondsplit = [x.split(' ') for x in firstsplit]
flatlist = [item for sublist in secondsplit for item in sublist]
chirpsfiles = [x for x in flatlist if 'chirps' in x]  



# DOWNLOAD THE CHIRP FILES

base = 'ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/global_daily/netcdf/p25/'
for file in chirpsfiles:
    os.system('wget "' + base+file+'"')


# alternative
#for file in chirpsfiles:
#    u = urllib2.urlopen(base+chirpsfiles[1])
#    localFile = open(chirpsfiles[1], 'w')
#    localFile.write(u.read())
#    localFile.close()

