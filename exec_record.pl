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
use session_lib qw(:config);

# Based on get_record.pl. Instead of getting records from the big file
# and creating a smaller file with an enclosing element, this pulls
# back each record, encloses with a marc:colletion (used to be <snac>) element, and pipes the
# resulting XML to the XSLT processor.

# Use global $line_buffer to imitate static var.
# If we put this in a local block would need to put this in a BEGIN block
# (which might not be so bad).

my $line_buffer = "";

# The saxon command line argument convention was changed between 8 and 9, so we must have a shell wrapper
# script and a printf format string to handle the command line argument substitution. We strongly suggest that
# you install saxon9he.jar. 

# Version 9he
# http://www.saxonica.com/documentation/using-xsl/commandline.xml
my $saxon_fmt = "saxon.sh -s:%s %s";

# Version 8
# http://saxon.sourceforge.net/saxon6.5.2/using-xsl.html
# my $saxon_fmt = "saxon.sh -s %s %s";

main();
exit();

sub main
{
    # unbuffer stdout
    $| = 1;
    
    my $record = "";

    # Yes, I know we are a commandline app, but Perl's CGI allows us
    # to use named args which is kind of nice, and as simple as it gets.

    my $qq = new CGI; 
    my %ch = $qq->Vars();
    
    if (! $ch{config})
    {
        die "Usage: $0 config=config_file.cfg\n";
    }

    if (! -e $ch{config})
    {
        die "Can't find config file: $ch{config}\n";
    }
    
    # jan 9 2015 add auth_form. Unclear why all the %cf values are put into intermediate vars. It isn't
    # necessary for most of them, and $cf comes from a trusted source (the config file). It isn't like this is
    # web data that can't be trusted and must be untainted, etc.

    my %cf = user_config($ch{config});
    check_config(\%cf, "auth_form,use_args,xsl_script,file,offset,chunk,iterations,log_file,chunk_prefix,output_dir,xsl_chunk_size");

    # the file name of the xslt script to run
    my $xsl_script = $cf{xsl_script};
    
    # when we're running oclc_marc2cpf.xsl, we need a bunch of args (params) for the saxon command line.
    my $use_args = $cf{use_args};

    # input xml file. 
    my $file = $cf{file};

    # Starting offset into $file. Usually 1.
    my $offset = $cf{offset};

    # Number of times we send a chunk of data to the xslt processor. Usually 'all'.
    my $iterations = $cf{iterations};
    
    # Size of chunk we send to the xslt processor. After this chunk size we
    # close the pipe to the xslt processor, and open a new pipe to the xslt
    # processor for the next chunk.
    my $chunk = $cf{chunk};

    # Number of records xslt processor handles before it creates a new output directory.
    my $xsl_chunk_size = $cf{xsl_chunk_size};

    # Prefix of the xslt processor output directory name. 
    my $chunk_prefix = $cf{chunk_prefix};

    # Where this script writes log output.
    my $log_file = $cf{log_file};

    # Top level directory where xslt processor writes its output.
    my $output_dir = $cf{output_dir};
    
    if (! -e $file || ! -f $file)
    {
        die "file: $file Error: not found or is not a file.\n";
    }

    if ($offset < 1)
    {
        die "offset: $offset Error: offset must be >= 1.\n";
    }

    if ($chunk < 1)
    {
        die "chunk: $chunk Error:chunk must be >= 1.\n";
    }

    unlink($log_file);
    
    # Now that we've passed the sanity checks, write out some time/date and
    # config info to the log file for posterity's sake.
    {
        my $fmt = "% 20s %s\n";
        my $config_str = sprintf($fmt, "starting:", scalar(localtime()));
        $config_str .= sprintf($fmt, "config file:", $ch{config});
        foreach my $key (sort(keys(%cf)))
        {
            $config_str .= sprintf($fmt, "$key:", $cf{$key});
        }
        log_message($log_file, $config_str);
    }

    # This checking seems a bit conservative since saxon/xslt will create necessary dirs in xsl:result-document.

    if (! -d $output_dir)
    {
        log_message($log_file, "output_dir: $output_dir Warning: directory does not exist. Creating.\n");
        mkdir $output_dir;
        if (! -d $output_dir)
        {
            log_message($log_file, "output_dir: $output_dir Error: could not create. Exiting.\n");
            exit(1);
        }
    }

    open(IN, "<", $file) || die "Cannot open $file for reading\n";
    
    # In the first loop we crawl forward until we are at $offset records. The
    # second loop below pulls records back and pipes each record to the xslt
    # processor until we have $chunk records.  In both loops, use 1-based counting
    # because these are countable, not indexes.
    
    # When offset==1 the first loop (below) doesn't run because we want the
    # first record. We test that $found_rec exists for the nth record, which
    # might not exist. Of course, if the file is empty, the first record won't
    # exist and this script hasn't been tested for that situation.
    
    # Add an outer element so we are more or less compliant. XSLT and
    # XML parsers complain if there isn't an outer element.
    
    my $found_rec = 0;
    for (my $count = 1; $count < $offset; $count++)
    {
        $record = next_record(\*IN);
        # print "doing: $count rec:" . substr($record, 1,20) . "\n";
        if ($record)
        {
            $found_rec = $count;
        }
    }
    
    my $iter_count = 0;
    my $recs_processed = 0;
    while (($iter_count < $iterations || $iterations eq 'all') && ($found_rec || $offset == 1))
    {
        my $fc_text;
        my $pipe; 

        # Reset these two vars to something false since they are also used as booleans to keep the while loop
        # going.
        $found_rec = 0;
        $offset = 0;

        # We could fork here and run the child(ren) in the background, although we would have to track the
        # number of active children so we didn't overload the server.

        # Exciting. Open a pipe to Saxon (the XSLT processor), and leave it open for an entire
        # chunk. We create an XML file on the fly, sending that XML through the pipe. The for loop
        # below keeps sending records, and after the for() loop, the pipe is finally closed.

        # Just a reminder: my $saxon_fmt = "saxon.sh -s:%s %s";

        if ($use_args)
        {
            my $args = "use_chunks=1 ";
            $args .= "chunk_prefix=$chunk_prefix ";
            $args .= "output_dir=$output_dir ";
            $args .= "chunk_size=$xsl_chunk_size ";
            $args .= "auth_form=$cf{auth_form} ";

            $args .= sprintf("offset=%d", $recs_processed+1);

            my $cmd = sprintf("$saxon_fmt  $args >> $log_file 2>&1", '-',  $xsl_script);
            log_message($log_file, $cmd);
            open($pipe, "|-", $cmd) || die "Cannot open pipe for command $cmd\n";
        }
        else
        {
            my $cmd = sprintf("$saxon_fmt >> $log_file 2>&1",  '-', $xsl_script);
            log_message($log_file, $cmd);
            open($pipe, "|-", $cmd) || die "Cannot open pipe for $cmd\n";
        }

        print $pipe "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        print $pipe "\n<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\"\n";
        print $pipe "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n";
        print $pipe "xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n";

        for (my $count = 1; $count <= $chunk; $count++)
        {
            $record = next_record(\*IN);
            if ($record)
            {
                # The pipe to XSLT processor is already open, just send another record.
                print $pipe "$record\n";
                $found_rec = $count;
                $recs_processed++;
            }
            else
            {
                $found_rec = 0;
                last;
            }
        }
        $iter_count++;
        # Send the final closing element, and close the pipe.
        print $pipe "\n</marc:collection>\n";
        close($pipe);
        my $date = scalar(localtime());
        log_message($log_file, "Finished chunk: $iter_count total records: " . commify($recs_processed) . " at $date\n");
    }
    close(IN);
}

sub log_message
{
    my $file = $_[0];
    my $msg = $_[1];
    open(my $log, ">>", $file) || die "Cannot open log $file for write.\n";
    print $log "$msg\n";
    close($log);
}

sub commify  
{
    my $arg = $_[0];
    $arg =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
    return $arg;
    # http://www.perlmonks.org/?node_id=653
    # http://www.perlmonks.org/?node_id=110137 
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
