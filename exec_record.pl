#!/usr/bin/perl

use strict;
use CGI;
use session_lib;
# use CGI::Carp qw(fatalsToBrowser);

# Based on get_record.pl. Instead of getting records from the big file
# and creating a smaller file with an enclosing element, this pulls
# back each record, encloses with a marc:colletion (used to be <snac>) element, and pipes the
# resulting XML to the XSLT processor.

# Use global $line_buffer to imitate static var.
# If we put this in a local block would need to put this in a BEGIN block
# (which might not be so bad).

my $line_buffer = "";
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
    
    my %cf = user_config($ch{config});
    check_config(\%cf, "use_args,xsl_script,file,offset,chunk,iterations,log_file,chunk_prefix,output_dir,xsl_chunk_size");

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

    if (! -d $output_dir)
    {
        die "output_dir: $output_dir Error: directory does not exist.\n";
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
        my $config_str = "starting " . scalar(localtime()) . "\n";
        $config_str .= "config file: $ch{config}\n";
        foreach my $key (sort(keys(%cf)))
        {
            $config_str .= "$key: $cf{$key}\n";
        }
        log_message($log_file, $config_str);
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
        # Reset these two vars to something false since they are also used as
        # booleans to keep the while loop going.
        $found_rec = 0;
        $offset = 0;

        # Could fork here and run the child(ren) in the background, although we
        # would have to track the number of active children so we didn't
        # overload the server.

        # Exciting. Open the pipe to XSLT processor, and leave it open for an
        # entire chunk. Code below keeps sending records, and after the
        # for() loop, the pipe is finally closed.

        # open($pipe, "|-", "xsltproc oclc_marc2cpf.xsl - > /uva-working/twl8n/$fc_text.xml");

        if ($use_args)
        {
            my $args = sprintf("use_chunks=1 chunk_prefix=$chunk_prefix output_dir=$output_dir chunk_size=$xsl_chunk_size offset=%d", $recs_processed+1);
            my $cmd = "saxon - $xsl_script $args >> $log_file 2>&1";
            log_message($log_file, $cmd);
            open($pipe, "|-", $cmd) || die "Cannot open pipe for command $cmd\n";
        }
        else
        {
            my $cmd = "saxon - $xsl_script >> $log_file 2>&1";
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


sub next_record
{
    my $in = $_[0];
    my $record = "";
    my $have_open = 0;
    if (! $line_buffer)
    {
        if (! ($line_buffer .= <$in>) )
        {
            # print "End of file\n";
            return undef;
        }
    }
    
    my $debug = 0;
    my $continue = 1;
    while ($continue && $line_buffer && $record !~ m/<\/record>/)
    {
        # Cleanse the prefix if appropriate. By only cleaning junk to
        # the left of '<' we preserve partial open element such as
        # "<record\n".
        
        if (! $have_open)  #  && $line_buffer !~ m/</)
	{
            # .+? was bad because that matched "<leader...". Better to
            # match a character set not including '<'.
            $line_buffer =~ s/(^[^<]+?<)/</sm;
	}

        # Get the start element of the record.
        
        # This is interesting. 
        # (?!<record)* matches null string many times in regex; marked by <-- HERE in m/(<record.*?>(?!<record)* <-- HERE )/ at get_record.pl line 115.

        # if (! $have_open && $line_buffer =~ s/(<record.*?>(?!<record)*)//sm)
        if (! $have_open && $line_buffer =~ s/(<record.*?>)//sm)
        {
            $record = $1;
            $have_open = 1;
        }
        
        # Get text to end tag or end of text. Use /x modifier so that
        # non-escaped whitespace is ignored. With /x the regex is $))
        # not $\ )).

        if ($have_open && $line_buffer =~ s/((?:(?!<record).)*(?:<\/record>|$ ))//smx)
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
    }
    
    # Remove leading junk.
    $record =~ s/^.*(<record)/$1/;
    
    # Remove trailing junk.
    $record =~ s/(<\/record>).*$/$1/;
    
    return $record;
}
