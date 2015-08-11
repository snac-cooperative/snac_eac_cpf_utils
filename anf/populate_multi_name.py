#!/usr/bin/env python
# -*- coding: utf-8 -*-

#!/usr/pkg/bin/python

#!/usr/bin/python

# Run this script once to populate the alternate names table alt_name. It assumes that the csv file has been
# imported, the database is postgress, and running on port 5433.

# Must put the database password into ~/.dbpass

# ./populate_multi_name.py > pop.log 2>&1 &

# split multiple names from otherNameEntries, and populate a second table.

from __future__ import print_function
import re
import codecs
import os
import fileinput
import sys
# Import XML parser
import xml.etree.ElementTree as ET

# Import Postgres connector
import psycopg2 as pgsql
import psycopg2.extras

# Apparently the % operator is the "sprintf" operator, which explains how printf() works.
# "A = %d\n , B = %s\n" % (a, b)

def printf(format, *args):
    sys.stdout.write(format % args)

# Create the db as a global, but create each db.cursor() inside each sql func.

# Create the cursor in a func, because we may want to change how the cursor is created, as in creating it with
# a cursor_factory that adds extra functionality.

def new_cursor(db):
    cur = db.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
    return cur

# from one of the pyscopg2 web pages:
#  And remember that Python requires a comma to create a single element tuple:
# >>> cur.execute("INSERT INTO foo VALUES (%s)", "bar")    # WRONG
# >>> cur.execute("INSERT INTO foo VALUES (%s)", ("bar"))  # WRONG
# >>> cur.execute("INSERT INTO foo VALUES (%s)", ("bar",)) # correct
# >>> cur.execute("INSERT INTO foo VALUES (%s)", ["bar"])  # correct

def sql_select_name(db) :
    dbc = new_cursor(db)
    # sql = "SELECT recordIdentifier, otherNameEntries from file_list where recordIdentifier=%s and "
    # sql = "SELECT recordIdentifier, authorizedNameEntry, otherNameEntries from file_list where othernameentries is not null limit 10"
    sql = "SELECT recordIdentifier, authorizedNameEntry, otherNameEntries from file_list where othernameentries is not null"
    dbc.execute(sql)
    tmp = dbc.fetchall()
    if tmp is not None:
        return tmp


def sql_insert_alt(db, rid, name) :
    dbc = new_cursor(db)
    sql = "insert into alt_name (rid, name) values (%s,%s)"

    # for now, assume no errors. If you want to catch exceptions, see
    # http://initd.org/psycopg/docs/advanced.html
    dbc.execute(sql, [rid, name])
    db.commit();


def main():
    # connect to db
    # foreach record if otherNameEntries parse, and insert into table alt_name
    # commit

    # Need to use env vars sometime. In the meantime, just create a list of places to look for the .dbpass
    # file.

    passlocs = ["/home/twl8n/.dbpass", "/Users/twl/.dbpass"]

    # What if both locations are valid? Will there be two open files but only one file handle?
    success = 0
    for passloc in passlocs:
        try:
            fh = open(passloc)
            success = 1
        except :
            printf("Can't open file %s\n", passloc)
    if not success:
        sys.exit(1)

    passw = fh.read()
 
    # v3 feature flags=M not supported, but apparently in v2 \s+ includes \n. Go figure.
    passw = re.sub(pattern='\s+', repl='', string=passw)

    # https://docs.python.org/2.6/library/string.html#formatexamples

    # Apparently the % operator is the "sprintf" operator, something to use as an alternative to .format()
    # "A = %d\n , B = %s\n" % (a, b)

    # The docs suggest that any connect() that does not explicitly have autocommit=True is transactional, and
    # must be ended with a commit.
    db = pgsql.connect("host=localhost dbname=anf user=twl8n password={0!s} port=5433".format(passw))
    all = sql_select_name(db) 
    for rec in all: 
        # printf("%s %s has alt %s\n",
        #        rec['recordidentifier'],
        #        rec['authorizednameentry'],
        #        rec['othernameentries'])
        other_name = rec['othernameentries']

        rid = rec['recordidentifier']

        # Happily, unique_alt is re-initialized each time through the for loop
        unique_alt = {}
        while(other_name):
            # split on pipe or end of line. Throw out the separator character (dummy)
            # hat is the leading unmatched portion of the string. This isn't re.sub().
            (hat, capture, dummy, other_name) = re.split(pattern='^(.*?)(\||$)', string=other_name)

            # trim leading and trailing space. Probably a func to do this somewhere.
            capture = re.sub('^\s+', '', capture)
            capture = re.sub('\s+$', '', capture)

            # There are some numbers in alt names. Ignore those numeric-only "names".
            # Ignore indéterminé as well
            if (capture and
                not re.match(pattern='^\d+', string=capture) and
                capture != 'indéterminé'):
                unique_alt[capture] = 1
            
        for alt in unique_alt.keys():
            sql_insert_alt(db, rid, alt)
            printf("inserting: rid: %s alt: %s\n", rid, alt)
    printf("Done\n")


if __name__ == '__main__':
    main()
