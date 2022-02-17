#!/bin/bash

# Define variables and values.
COUNTRIES="countries"
COUNTRIES_ZIP="${COUNTRIES}.zip"
YOUR_LICENSE_KEY=""
OPNSENSE_HOST=""
OPNSENSE_USER="root"
OPNSENSE_SSH_PORT="22"

# Download .zip file from MaxMind.
wget -q -O $COUNTRIES_ZIP "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=$YOUR_LICENSE_KEY&suffix=zip"

if [ "$?" != 0 ]; then
    echo "Error downloading file"
     exit 1
fi

# Unpack .zip file.
unzip -qq -o $COUNTRIES_ZIP

# Delete potentially remained old data.
rm $COUNTRIES 2> /dev/null
# Copy original source files into a new directory.
cp -r GeoLite2-Country-CSV_* $COUNTRIES
# Delete original source files.
rm -rf GeoLite2-Country-CSV_*
# Navigate into new directory.
cd $COUNTRIES
# Delete unnecessary source '.txt' files.
rm *.txt

# Delete unnecessary first row of the source file 'GeoLite2-Country-Locations-en.csv';
# Merge into an new file 'comparison.csv'.
tail -n +2 GeoLite2-Country-Locations-en.csv > comparison.csv

# IPv4
# Delete unnecessary first row of the source file 'GeoLite2-Country-Blocks-IPv4.csv';
# Merge into an new temporary file 'temp01.csv'.
tail -n +2 GeoLite2-Country-Blocks-IPv4.csv > temp01.csv
# Cut out the first two columns of 'temp01.csv';
# Merge into a new temporary file 'temp02.csv'.
cut -d, -f1-2 temp01.csv |tee temp02.csv
# Delete 'temp01.csv'.
rm temp01.csv
# For every line on 'temp02.csv' compare the second column of 'temp02.csv' by the first column of 'comparison.csv';
# On match add the value of fifth column of 'comparison.csv' to the according line of 'temp02.csv' as a new third column;
# Merge into a new temporary file 'temp03.csv'.
join -t, -1 2 -2 1 -o 1.1,1.2,2.5 <(sort -t, -k2 temp02.csv) <(sort -t, -k1 comparison.csv) > temp03.csv
# Delete 'temp02.csv'.
rm temp02.csv
# Delete unnecessary second row of 'temp03.csv';
# Merge into a new temporary file 'temp04.csv'.
cut -d, -f2 --complement temp03.csv > temp04.csv
# Delete 'temp03.csv'.
rm temp03.csv

# IPv6
# Delete unnecessary first row of the source file 'GeoLite2-Country-Blocks-IPv6.csv';
# Merge into an new temporary file 'temp01.csv'.
tail -n +2 GeoLite2-Country-Blocks-IPv6.csv > temp01.csv
# Cut out the first two columns of 'temp01.csv';
# Merge into a new temporary file 'temp02.csv'.
cut -d, -f1-2 temp01.csv |tee temp02.csv
# Delete 'temp01.csv'.
rm temp01.csv
# For every line on 'temp02.csv' compare the second column of 'temp02.csv' by the first column of 'comparison.csv';
# On match add the value of fifth column of 'comparison.csv' to the according line of 'temp02.csv' as a new third column;
# Merge into a new temporary file 'temp03.csv'.
join -t, -1 2 -2 1 -o 1.1,1.2,2.5 <(sort -t, -k2 temp02.csv) <(sort -t, -k1 comparison.csv) > temp03.csv
# Delete 'temp02.csv'.
rm temp02.csv
# Delete unnecessary second row of 'temp03.csv';
# Append into existing 'temp04.csv'.
cut -d, -f2 --complement temp03.csv >> temp04.csv
# Delete 'temp03.csv' and delete 'comparison.csv'.
rm temp03.csv && rm comparison.csv

# Create final files:
# For every country create a single '.txt' file;
# Filenames based on [column 2] of 'temp4.csv';
# File contents based on [column 2] of 'temp4.csv'; Removing [column 2] of 'temp04.csv' including preliminary comma ',' char.
awk 'BEGIN{FS=","}{out=$2 ".txt";print $1 >> out; close(out) }' temp04.csv
# Delete all remaining '.csv' files.
rm *.csv

# Create '/etc/haproxy/geoip2' directory on OPNsense remote host via SSH.
ssh -p $OPNSENSE_SSH_PORT -o ConnectTimeout=5 $OPNSENSE_USER@$OPNSENSE_HOST 'mkdir -p /etc/haproxy/geoip2'
# Copy '.txt' files into the according remote directory via SCP.
scp -P $OPNSENSE_SSH_PORT -o ConnectTimeout=5 ./*.txt $OPNSENSE_USER@$OPNSENSE_HOST:/etc/haproxy/geoip2/
# Reload HAProxy on OPNsense via SSH.
ssh -p $OPNSENSE_SSH_PORT -o ConnectTimeout=5 $OPNSENSE_USER@$OPNSENSE_HOST 'service haproxy reload'

# Cleanup.
cd ..
rm $COUNTRIES_ZIP
rm -rf $COUNTRIES
