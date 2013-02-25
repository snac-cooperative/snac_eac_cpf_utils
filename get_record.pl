#!/usr/bin/env perl

# Author: Tom Laudeman
# The Institute for Advanced Technology in the Humanities
#
# Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
# License at
#
# http://www.osedu.org/licenses/ECL-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and limitations under the License.

use strict;
use CGI; # Handles command line name=value pairs.

# Use global $line_buffer to imitate static var.
# If we put this in a local block would need to put this in a BEGIN block
# (which might not be so bad).

my $line_buffer = "";

main();
exit();

sub main
{
    $| = 1; # unbuffer stdout.
    
    # Yes, I know we are a commandline app, but Perl's CGI allows us
    # to use named args which is kind of nice.
    
    my $offset = 1;
    my $record = "";
    my $limit = 1;
    
    my $qq = new CGI; 
    my %ch = $qq->Vars();
    
    # Kind of amazing that ! $ARGV is a test for the @ARGV array being
    # empty, and !%ch is a test for the %ch hash being empty.
    
    if (! $ARGV && ! %ch)
    {
        print "Usage: $0 file=file_to_read.xml [offset=record_offset] [limit=num_of_recs]\n";
        exit();
    }
    
    if (! -e $ch{file} || ! -f $ch{file})
    {
        die "You must specify a file. file=foo\n";
    }
    
    if ($ch{offset})
    {
        if ($ch{offset} < 1)
        {
            die "Error: offset must be >= 1\n";
        }
        $offset = $ch{offset};
    }
    
    if ($ch{limit})
    {
        if ($ch{limit} < 1)
        {
            die "limit must be >= 1\n";
        }
        $limit = $ch{limit};
    }
    
    open(IN, "<", $ch{file});
    
    # crawl forward until we are at $offset records, then pull records
    # back until we have $limit records.  In both loops, use 1-based
    # counting because these are countable, not indexes.
    
    my $found_rec = 0;
    for (my $count = 1; $count < $offset; $count++)
    {
        $record = next_record(\*IN);
        if (! $record)
        {
            last;
        }
        # print "doing: $count rec:" . substr($record, 1,20) . "\n";
        if ($record)
        {
            $found_rec = $count;
        }
    }
    
    # When offset==1 the loop above doesn't run because we want the
    # first record. $found_rec exists for the nth record, which might
    # not exist. Of course, if the file is empty, the first record
    # won't exist and this script hasn't been tested for that
    # situation.
    
    # Add an outer element so we are compliant. XSLT and XML parsers complain if there isn't an outer element.
    
    # Note that we declare the URI for marc and bind the marc: prefix. Both are necessary to cover all
    # cases. By doing both declaring and binding, the XML can use the "marc:" prefix, or not.

    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "\n<collection xmlns=\"http://www.loc.gov/MARC21/slim\"\n";
    print "    xmlns:marc=\"http://www.loc.gov/MARC21/slim\"\n";
    print "    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n";
    print "    xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n";
    
    if ($found_rec || $offset == 1)
    {
        for (my $count = 1; $count <= $limit; $count++)
        {
            $record = next_record(\*IN);
            if (! $record)
            {
                last;
            }
            # print "rec num: $found_rec limit count: $count\n$record\n\n";
            print "$record\n";
        }
    }
    # print "final lb: $line_buffer\n";
    close(IN);
    
    # The close of the outer element.
    print "</collection>\n";
}

my $ns_prefix = "";
sub next_record
{
    my $in = $_[0];
    my $record = "";
    my $have_open = 0;
    if (! $line_buffer)
    {
        if (! ($line_buffer = <$in>) )
        {
            # print "End of file\n";
            return undef;
        }
        # If there is an xml header line, remove it.
        $line_buffer =~ s/<\?xml.*?>//;
    }

    # No need to remove <collection> or anything outside <record> because all that is trimmed away.

    my $debug = 0;
    my $continue = 1;
    my $xx = 0; 
    while ($continue && $line_buffer && ! ($record =~ m/(?:<\/marc:record|<\/record|<\/$ns_prefix:record)>/))
    {
        # Cleanse the prefix if appropriate. By only cleaning junk to
        # the left of '<' we preserve partial open element such as
        # "<record\n".
        
        if (! $have_open)         #  && $line_buffer !~ m/</)
 	{
            # .+? was bad because that matched "<leader...". Better to
            # match a character set not including '<'.
            $line_buffer =~ s/(^[^<]+?<)/</sm;
 	}
        
        # Get the start element of the record.
        
        # This is interesting. 
        # (?!<record)* matches null string many times in regex; marked by <-- HERE in m/(<record.*?>(?!<record)* <-- HERE )/ at get_record.pl line 115.
        
        
        # Using [^<]+? to match the first namespace prefix. This is only done when ! $have_open so it is not
        # computationally expensive. Save the namespace prefix. Throw out everything before <record>.

        if ((! $have_open) && $line_buffer =~ s/.*?((?:<([^<]+?):record|<record).*?>.*$)//sm)
        {
            # print "first:$line_buffer\n";
            $record = $1;
            if ($2)
            {
                $ns_prefix = $2;
            }
            $have_open = 1;
        }
        
        # Get text to end tag or end of text. Use /x modifier so that non-escaped whitespace is ignored. With
        # /x the regex is $)) not $\ )). Using /x and the extra space may have been originally added to a work
        # around for a bug in Emacs Perl parser.
        
        # When the code was added to deal with marc:record|record I found that (?:.*:record|record) is more
        # robust than (?:.*:)*record.
        
        # ?! is "/foo(?!bar)/" matches any occurrence of "foo" that isn't followed by "bar", but we have the nonsense (?!foo)bar.

        # ?!<(?:.*:record|record) matches any occurrence of "<" not followed by (?:.*:record|record).

        # if ($have_open && $line_buffer =~ s/((?:(?!<(?:.*:record|record)).)*(?:<\/.*:record|<\/record)>|$ )//smx)

        # The non-greedy up to closing </record> simpler than zero-width negative look ahead?
        if ($have_open && $line_buffer =~ s/(.*?(?:<\/marc:record|<\/record|<\/$ns_prefix:record)>|$ )//smx)
        {
            $record .= $1;
        }
        
        # If the xml is badly formed, there could be junk outside the
        # elements. The prefix cleaning at the top of the loop will
        # handle that.
        
        # ! and .= don't seem to work well together to detect end of file.
        # if (! ($line_buffer .= <$in>))
        if (my $temp = <$in>)
        {
            $line_buffer .= $temp;
        }
        else
        {
            $continue = 0;
        }
        # The while() has end of record detection, in addition to the boolean flag $continue.
        $xx++;
    }
    
    # Remove leading junk.
    $record =~ s/^.*((?:<marc:record|<record|<\/$ns_prefix:record))/$1/;
    
    # Remove trailing junk.
    $record =~ s/((?:<\/marc:record|<\/record|<\/$ns_prefix:record)>).*$/$1/;
    
    return $record;
}
