

july 7 2015

Some semi-automated QA prior to review

> ls -l *.pl *.pm *.xml *.dat *.sql
-rw-r--r-- 1 twl8n snac   10824 Jul  7 14:32 anf.pm
-rw-r--r-- 1 twl8n snac    5416 May  8 10:15 av.pm
-rwxr-xr-x 1 twl8n snac   27909 Jul  7 14:27 cpf_norm.pl
-rw-r--r-- 1 twl8n snac    7690 Jul  7 14:34 cpf_template.xml
-rw-r--r-- 1 twl8n snac 1684786 Jun 19 15:50 frozen_data.dat
-rwxr-xr-x 1 twl8n snac    3584 Jun  8 15:03 get_missing_role.pl
-rwxr-xr-x 1 twl8n snac     611 May 27 15:10 missing_cpf_roles.pl
-rwxr-xr-x 1 twl8n snac   13988 Jun 19 15:50 parse_anf.pl
-rwxr-xr-x 1 twl8n snac   14424 Jul  7 14:32 render_anf.pl
-rw-r--r-- 1 twl8n snac     520 Apr 14 15:20 schema.sql
-rw-r--r-- 1 twl8n snac   64028 May 28 08:16 session_lib.pm

> find snac_files/ -type f -exec nice java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} + > jing.log 2>&1 &

> ls -l jing.log
-rw-r--r-- 1 twl8n snac 0 Jul  7 14:59 jing.log


> nice ~/eac_project/find_empty_elements.pl dir=snac_files/ empty > anf_empty.log 2>&1 &

# Odd looking empty elements are due to AnF CPF usage. Some are naturally empty in generated cpf stub files.

> grep empty: anf_empty.log| sort | uniq -c
      2 empty: description
      8 empty: descriptiveNote
      1 empty: entityId
   1704 empty: eventDescription
      1 empty: legalStatus
      1 empty: legalStatuses
     65 empty: mandate
     65 empty: mandates
   1699 empty: objectXMLWrap
     81 empty: p
      5 empty: placeEntry
      5 empty: relationEntry
      2 empty: resourceRelation
   4049 empty: script
   1699 empty: source
   1699 empty: sources
      1 empty: term
    739 empty: toDate

> ls -alt snac_files/ | head
total 36800
drwxrwxr-x 6 twl8n snac   4096 Jul  7 14:59 ..
-rw-r--r-- 1 twl8n snac   4222 Jul  7 14:35 FRAN_NP_011472.xml

> ls -alt snac_files/ | tail
-rw-r--r-- 1 twl8n snac  40395 Jul  7 14:15 FRAN_NP_010172.xml

> cp -a snac_files /data/extract/anf

> cd /uva-working/xtfTest8
> rm snac_files
> ln -s /data/extract/anf
> find /uva-working/xtfTest* -maxdepth 1 -mindepth 1 \( -type l -o -type d \) -printf "%p -> %l\n";
> cd ~/eac_project/
> xtf_index.pl 8 &
> cd ~/eac_project/anf
> cp readme.txt /data/extract/readme_anf.txt


How to run the extraction



Step 1 parse_anf.pl

# Create a list of entities which need CPF files created. We don't have all the AnF data, but we know from
# cpfRelations in data we do have that other entities exist.

# Creates an output file frozen_data.dat which is a hash of hashes of all the cpfRelations, including those we
# have files for an those we don't know about.

# Use the extra file anf-20150617-entityTypesForSNAC.csv with entity types from AnF query or script (and not
# from a corporateBody keyword guess).

# Run this before cpf_norm.pl, which now reads frozen_data.dat to get the extra entityType info for files we 
# don't have.

# Error messages are easier (possible) to find when stderr is in a separate file.

# ./parse_anf.pl > pa.log 2> err.log &

# > grep 'has_file => 1' pa.log| wc -l
# 1832
# > ls working_files/ | wc -l
# 2350
# > less pa.log 
# > grep 'fileinfo:' pa.log | wc -l 
# 2350

# > grep 'uid ' ra.log| wc -l
# 1699
# > ls snac_files/ | wc -l   
# 4049



Step 2 cpf_norm.pl

# Perform certain normalizations on existing CPF files from AnF.

# Start the local copy of Postgres before running this script.

# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data -l ~/pg9.4.1/logfile start
# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data stop

# The password is in ~/.dbpass
# ~/pg9.4.1/bin/psql anf

# sudo yum -y install perl-XML-LibXML
# 
# run parse_anf.pl before running cpf_norm.pl.

# ./cpf_norm.pl [--info|--noinfo] [--debug|--nodebug] > cpf_role.log 2>&1 &
# ./cpf_norm.pl --debug > cpf_role.log 2>&1 &

# Send all the logging to a single file. With this script, is it good for stdout and stderr to be in the same
# file.

# ./cpf_norm.pl > cpf_role.log 2>&1 &

# Historically derived from henry_dates.pl

Step 3 render_anf.pl

# Create CPF stub files for cpfRelation entities. Read data for cpfRelations parsed out of the existing files
# by parse_anf.pl, and saved in frozen (storable) format.

# Error messages are easier (possible) to find when stderr is in a separate file.
# run parse_anf.pl, cpf_norm.pl before this script.

# ./render_anf.pl --test > ra.log 2> err.log &
# ./render_anf.pl > ra.log 2> err.log &

# > grep 'has_file => 1' pa.log| wc -l
# 1832
# > ls working_files/ | wc -l
# 2350
# > less pa.log 
# > grep 'fileinfo:' pa.log | wc -l 
# 2350

# > grep 'uid ' ra.log| wc -l
# 1699
# > ls snac_files/ | wc -l   
# 4049
# > grep Created: ra.log| wc -l
# 1699


cpf_norm.pl requires a Pg database which is installed in ~/. The db is owned by twl8n

# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data -l ~/pg9.4.1/logfile start
# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data stop

# Run the psql command line. It will prompt for the password.
~/pg9.4.1/bin/psql anf

