package session_lib;

# Copyright 2013 Tom Laudeman, Jim Roberts. Licensed under the Educational Community License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
# License at

# http://www.osedu.org/licenses/ECL-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and limitations under the License.

# $Id: session_lib.pm,v 1.88 2009/09/21 18:53:16 twl8n Exp $

use base qw( Exporter );

# Superceded by 'use base' above, and use base is a better practice.
# http://perldoc.perl.org/Exporter.html#Declaring-%40EXPORT_OK-and-Friends
# # Exporter must be in @ISA. Dynaloader seems to be optional.
# @ISA = qw(Exporter);

# Create a 2 groups of exported functions :config with all 3 of the necessary subs for app_config and :all
# with everything including app_config. There are other possible subsets.

# use session_lib qw(:config);
# use session_lib qw(:all);

%EXPORT_TAGS = (config => [qw(app_config user_config check_config)], 
                all => [qw(sqlite_db_handle app_config err_stuff get_url version next_fasta get_db_handle commit_handle
                clean_db_handles load_average busy check_config untaint capture_file login process_template
                user_config keep_one run_session save_session update_cookie safe_file init_progress_meter
                progress_meter multi_string save_upload_file index_url email exists_message final_message
                read_file read_file_array write_log write_log2 write_log3 log2file daemon_log current_view
                bs_view capture_url exp_time get_bitaccess_value big_mask happy_recs print_xml blast_qmh_lines
                make_column_lines seq_line_break_with_htmltags get_xml_tag get_all_xml_tag_values session_id
                dump_hash sl_list named_config)] );

# See also Exporter::export_tags('foo'); 

# add app_config user_config check_config to @EXPORT_OK
Exporter::export_ok_tags('config'); 
Exporter::export_ok_tags('all'); 

# subs we export by default
@EXPORT = qw();

# Subs we will export if asked. 
@EXPORT_OK = qw(sqlite_db_handle app_config err_stuff get_url version next_fasta get_db_handle commit_handle clean_db_handles
	     load_average busy check_config untaint
	     capture_file login process_template user_config keep_one
	     run_session save_session update_cookie
	     safe_file init_progress_meter progress_meter multi_string 
	     save_upload_file index_url email exists_message final_message 
	     read_file read_file_array write_log write_log2 write_log3 log2file daemon_log
	     current_view bs_view capture_url exp_time get_bitaccess_value big_mask
	     happy_recs print_xml blast_qmh_lines make_column_lines seq_line_break_with_htmltags 
	     get_xml_tag get_all_xml_tag_values session_id dump_hash
	     sl_list named_config);

# The "use" statement and $VERSION seem to be required.
use vars qw($VERSION);

# Updated jan 4 2012 There have been many small changes. Time to bump the version number.  ms_lims had an
# updated version 5.  cowpea has version 6.  This as improved config management, sql connection subs, etc.

$VERSION = '10';


# Don't move use strict up since some of the lines above are not strict.

use strict;
use CGI;
use DBI;

my $EXP_TIME='+3600'; # one hour in seconds
my %db_handles;

# apr 20 2007 This needs to be changed to use default_db from .app_config Fix later. It effects lots of code.
# For now start using default_db in new code.

my $default_alias = "omssa";


# Get abs path so this works from cron and PBS in dev and production areas

use Cwd qw(abs_path getcwd);
my $path = "";
if ($ENV{vela_path})
{
    $path = $ENV{vela_path};
}
else
{
    $path = abs_path($0);
    $path =~ s/(.*)\/.*/$1/;
}


# Call sl_list to get HTML that is all the info for available search libraries.  Everything outside the body
# tags is stripped off, so this should work inside most web pages.  Returns a single string.

sub sl_list
{
    my %arg = @_;
    my $slf_pk = $arg{slf_pk};
    my $sl_pk = $arg{sl_pk};
    my $db_name = $arg{db_name};

    my %ph;
    my @recs;
    if ($sl_pk && $slf_pk)
    {
	# Legacy method takes two CGI parameters.
	# See cpweb_sql_lib.pl.

	my $hr = main::sql_sl_info(db_name => $db_name,
				   sl_pk => $sl_pk,
				   slf_pk => $slf_pk);
	push(@recs, $hr);
	$ph{plural} = "y"; # singular
    }
    else
    {
	# If we don't have one specific pair of sl_pk and slf_pk, then
	# show the user everything they are allowed to use.
	# See cpweb_sql_lib.pl.
	
	@recs = main::sql_slf_list(db_name => $db_name);
	$ph{plural} = "ies"; # plural
    }
	
    my $allhtml = process_template("sl_list_core.html");
    my $template = HTML::Template->new(scalarref => \$allhtml, die_on_bad_params => 0);
    
    $template->param(recs => \@recs);
    $template->param(%ph);
    my $output = $template->output;

    # Remove everything outside the body, including <body> and </body> tags.

    $output =~ s/^.*?<.*?body.*?>//;
    $output =~ s/<.*?\/body.*?>.*$//;
    return $output;
}


# Used by cowpeaweb/CGKB/sl_retrieval.pl and web_xml_blast/munge_xml.pl

sub print_xml
{
    my @recs = @{$_[0]};
    my %cf = %{$_[1]};
    
    my $output = "";
    foreach my $hr (@recs)
    {
	my $sl_link_url = main::sql_bs_link(db_name => $cf{default_db}, bs_pk => $hr->{bs_pk});
        
        # jhr 12/05/08 if hit_accession is supplied use it
        
	if (!exists($hr->{hit_accession}))
        {
            $hr->{hit_accession} = $hr->{trace_name};
            if ($hr->{hit_accession} =~ m/^.*\|(.*)$/)
            {
                $hr->{hit_accession} = $1;
            }
        }
        
        # jhr 12/05/08 replaced with previous code ( if hit_accession is supplied use it )
        #
        #	$hr->{hit_accession} = $hr->{trace_name};
        #	if ($hr->{hit_accession} =~ m/^.*\|(.*)$/)
        #	{
        #	    $hr->{hit_accession} = $1;
        #	}
        #

	$sl_link_url =~ s/<(.*?)>/$hr->{$1}/g;
	
	my $out_rec = "<sl_link_url>$sl_link_url</sl_link_url>\n";
        
	# Don't print all the fields in $hr, since they might include all fields in bio_sequence. sl_link_url
	# is printed above differently because it is not in the $row hash.  jhr added tab to align xml within
	# output file (why? anal retentive maybe? )

	foreach my $key ('bs_pk','trace_name','description','sequence','coloredseq','seqnocolor')
	{
	    $out_rec .= "\t<$key>$hr->{$key}</$key>\n";
	}

	# This is going into an XML file. XML has issues with certain charcters in strings. No naked &
	# allowed. Must be &amp; There are probably many things that will break the XML. It's a fragile
	# technology.
	
	$out_rec =~ s/\&/&amp;/g;
	$output .= $out_rec;
    }
    return $output;
}

# Used by cowpeaweb/CGKB/sl_retrieval.pl and web_xml_blast/munge_xml.pl

# There are too many subs with _recs in the name. No naming convention based on function works, so just start
# naming subs with snappy catch phrases or something.

sub happy_recs
{
    my %ch = %{$_[0]};
    my %cf = %{$_[1]};

    my $msg;
    my @recs;
    my @tnames = split(/\n/,$ch{id});
    
    if (exists($ch{trace_name}))
    {
	push(@tnames, $ch{trace_name});
    }

    if (exists($ch{bs_pk}))
    {
	push(@tnames, $ch{bs_pk});
    }
    
    foreach my $id (@tnames)
    {
	# Fun fact: text from textarea can have decimal 13 (^M aka carriage return) chars on the end (and
	# maybe in the middle too) and chomp() doesn't get rid of them. This fun fact brought to you by an
	# hour of irritating debugging.

	$id =~ s/(\s+)//g;
	$id =~ s/\>//;

	# $row is a hash reference.
	my $row;

	if ($id =~ m/^\d+$/)
	{
	    $row = main::sql_core_get_bioseq(db_name=>$cf{default_db},
				       bs_pk=>$id);
	}

	if (! $row)
	{
	    # The slf_pk is optional here. See cpweb_sql_lib.pl.
	    $row = main::sql_getbioseq_2(db_name => $cf{default_db},
					 trace_name => $id,
					 slf_pk => $ch{slf_pk});
	}

	# Getting sequence info from fastacmd (via dobyfasta()) is less than optimal. We won't get a bs_pk, so
	# some downstream code may break in confusing ways.

	if (! $row)
	{
	    if (exists($ch{sl_pk}) && exists($ch{slf_pk}))
	    {
		my $hr = main::sql_sl_info(db_name => $cf{default_db}, sl_pk => $ch{sl_pk}, slf_pk => $ch{slf_pk});
		my $filename = "$hr->{slf_directory}/$hr->{slf_file_name}";
		$row = main::dobyfasta($filename);
		$msg = "Unable to extract sequences from database attempting fasta library $filename.<hr>\n";
	    }
	    else
	    {
		die "Database lookup failed. Fall back to fastcmd failed because no sl_pk or slf_pk\n";
	    }
	}
	push(@recs, $row);
    }
    return (@recs,$msg);
}


sub exp_time
{
    return $EXP_TIME;
}


# Normally, Perl is limited to 32 bit ints. Postgres allows 62 bits so use Math::BigInt to allow bitmasks up
# to 62 bits.

sub big_mask
{
    my $bit = $_[0];

    if ($bit < 0 || $bit > 62)
    {
	die "Out of range bit:$bit. Acceptable range is 0 thru 62\n";
    }

    use Math::BigInt;
    my $mask = Math::BigInt->new('2');
    $mask->bpow($bit);
    my $mask_as_str = $mask->bstr();
    return $mask_as_str;
}

# Used by database code to get the name of the view used to access the blast_result table.  Used in the
# cowpeaweb project.

sub current_view
{
    my %cf = app_config();
    check_config(\%cf, "view");
    return $cf{view};
}


# Get the view used by blast_result, and add a _bs suffix.  Also see cowpeaweb/CGKB/cpweb_sql_lib.pl
# sql_create_view().

sub bs_view
{
    my $proto = $_[0];
    my $view = "";
    if ($proto)
    {
	$view = "$proto\_bs";
    }
    else
    {
	$view = current_view();
	$view .= "\_bs";
    }
    return $view;
}


# get sl_access bit setting value for comaprison against search_info requires the view name from current_ciew

sub get_bitaccess_value
  {
    my  $dbh  = get_db_handle($_[0]);
    my  $view = current_view();
    my  $sql  = "select flag from sl_access where view = ?;";
    my  $sth  = $dbh->prepare($sql);
    if ($dbh->err()) { die "ERROR sql\n".$sql."\nprepare:".$DBI::errstr; }
    $sth->execute($view);
    if ($dbh->err()) { die "ERROR sql\n".$sql."\nexecute:".$DBI::errstr; }
    my $row   = $sth->fetchrow_hashref();
    $sth->finish();
    my  $bitval =   2**$row->{flag};
    return($bitval);
  }

# Called from sql libraries.
# Write logs and die.
# write_log3 is the new db resident logging routine.

# Use and eval for the log writing in case it fails. We still would like the stderr output from die.

sub err_stuff
{
    my $dbh = $_[0];
    my $sql = $_[1];
    my $msg = $_[2];
    my $dbname = $_[3];
    my $caller = $_[4];

    # Must save any necessary info from DBI before calling write_log3() because write_log3() uses DBI to write
    # log messages to the db.

    my $err = $dbh->err;
    my $errstr = $DBI::errstr;

    if ($dbh->err())
    {
	my $err = $dbh->err;
	my $errstr = $DBI::errstr;
	
	# Call write_log3() from an eval so that any failure in there is not fatal, because we want to also
	# die() after logging. This really should either check that the db log was written, or have an option
	# to log to a file regardless. If the db log fails, there is the die(), but if stderr is lost, it
	# would be helpful to have logging to a file (assuming that the user will even see the file.)

	eval 
	{
	    write_log3("vela", "db_error", "$dbname $msg $caller sql:$sql err:$err errstr:$errstr");
	};
	die "Routine: $caller err:$err errstr:$errstr sql:$sql\n";
    }
}



# twl: This could be improved to work from command line
# calls which might simplify testing.

sub get_url
{
    my $protocol;
    if ($ENV{SERVER_PROTOCOL} =~ m/http/i)
    {
	$protocol = "http://";
    }
    return "$protocol$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
}

sub version
{
    return $VERSION;
}


# %rec has: full_header, trace_name, description, sequence. However, trace_name and description may be missing
# from some entries.

# Use global $line_buffer to imitate static var.  If we put this in a local block would need to put this in a
# BEGIN block (which might not be so bad).

my $line_buffer = "";

sub next_fasta
{
    my $in = $_[0];
    my %rec;
    my $seq;
    if (! $line_buffer)
    {
	if (! ($line_buffer = <$in>) )
	{
	    return undef;
	}
    }

    # Make sure we have a fasta header line. If so, then attempt to get a trace_name and description separated
    # by \s+

    my $header_line;
    if ($line_buffer =~ m/^\>(.*)/)
    {
	$header_line = $1;
    }
    else
    {
	print "Bad header:$line_buffer. Exiting.\n";
	exit(1);
    }
    $rec{full_header} = $header_line;

    if ($header_line =~ m/(.*?)\s+(.*)/)
    {
	$rec{trace_name} = $1;
	$rec{description} = $2;
    }
    else
    {
	$rec{trace_name} = $header_line;
	$rec{description} = "";
    }

    # Remove, trim whitespace on the trace_name.
    # Clean illegal chars from trace_name but do not warn.
    # Save the orig string so it can be searched in the fasta file.
    # Count and keep track of illegal chars in the trace_name.
    # Change illegals to _ do not warn, and keep processing.
    
    $rec{trace_name} =~ s/^\s+//;
    $rec{trace_name} =~ s/\s+$//g;
    
    my $illegal_char = "";
    my $orig = $rec{trace_name};
    while ($rec{trace_name} =~ s/([^A-Za-z0-9\-_|.])/_/)
    {
	$illegal_char .= $1;
    }

    if ($illegal_char)
    {
	# print "In entry $orig\nFound illegal char(s): $illegal_char\n";
    }
    
    $line_buffer = "";
    while($line_buffer !~ m/^\>/)
    {
	$seq .= $line_buffer; # keep newline
	if (! ($line_buffer = <$in>) )
	{
	    last;
	}
    }

    $rec{sequence} = $seq;
    return \%rec;
}


# prints status messages during a run

sub run_status
{
    my $start = $_[0]; # start time in seconds since the epoch
    my $xx = $_[1];    # number of iterations completed
    my $total = $_[2]; # total number of iterations
    my $interval = $_[3]; # How often to print the status message

    if (($xx % $interval) == 0  || $xx == 1)
    {
	my $end = time();
	my $secs_per_rec = ($end - $start)/($xx);
	my $est_secs = $secs_per_rec * $total;
	$est_secs = $est_secs - ($end-$start);
	
	printf("Finished $xx recs. Secs/rec: %4.4f Est. complete in %2.2d:%2.2d:%2.2d\n",
	       $secs_per_rec,
	       ($est_secs/3600),
	       ($est_secs % 3600)/60,
	       ($est_secs%60));
    }
}


sub db_info
{
    my $db_alias = $_[0]; 

    my %cf = app_config();

    # In the simple case, no security is requried for our db info, so just get the normal, non-hide values
    # back. Non-secured db info records should not have password, but we won't enforce that here.

    if (! exists($cf{$db_alias}))
    {
	# We didn't find our db_alias in the non-hide section, so Here we are asking only for a db config set
	# of values. Getting this required that $db_alias is in "hide", and has a config value in db format
	# (whitespace separated fields).

	%cf = app_config($db_alias)
    }

    # Split as though we are keeping all fields. Simple records won't
    # have most of the fields, and must not have the password field.

    my %vars;
    if (exists($cf{$db_alias}))
    {
	($vars{db_name},
	 $vars{dbms},
	 $vars{db_host},
	 $vars{db_port},
	 $vars{db_user},
	 $vars{db_password}) = split('\s+', $cf{$db_alias});
	
	$vars{alias} = $db_alias;
	
	if (! $vars{db_name})
	{
	    die "Missing db info for alias:$db_alias from config:$cf{app_config}\n";
	}
    }
    else
    {
	die "No record for database $db_alias in $cf{app_config}.\n";
    }

    # Normal, secure connect string without user and password required
    # only by MySQL. This same connection string is also used by
    # non-secured SQLite.

    my $connect_string =
	sprintf("dbi:%s:dbname=%s;host=%s;port=%s;",
		$vars{dbms},
		$vars{db_name},
		$vars{db_host},
		$vars{db_port});
    
    if ($vars{dbms} eq "mysql")
    {
	# DBI::connect() always spews $connect_string to stderr in the
	# case of failure, no matter what you do. As far as I can
	# tell, MySQL only supports the connect string method. If you
	# can find a secure method to get the userid and password to
	# MySQL, please feel free to implement it here.  Test your
	# technique by making connect fail (i.e. bad password) and
	# running the test script at the command line.

	$connect_string =
	    sprintf("dbi:%s:dbname=%s;host=%s;port=%s;",
		    $vars{dbms},
		    $vars{db_name},
		    $vars{db_host},
		    $vars{db_port},
		    $vars{db_user},
		    $vars{db_password});
    }
    
    return ($connect_string, $vars{db_user}, $vars{db_password});
}


# Transactions must be enabled for some of the code to work.
# Transactions are explicitly enabled by setting AutoCommit to zero.
# We always use a tcp connection, even to the localhost,
# so we always need the host name and port.

# MySQL ignores all the args except the connect string.  The MySQL
# connection fails unless the user and password were in the connect
# string.  The Postgres driver conforms to the DBI documentation, and
# therefore requires the user and password arguments. SQLite conforms
# to the DBI docs, but SQLite ignores the host, port, user, and
# password fields.

sub get_db_handle
{
    # The name is an alias. See file .app_config
    my $db_alias = $_[0]; 

    if (! $db_alias)
    {
	my $str = sprintf("%s $0 %s must have an alias.", (caller(1))[3], (caller(0))[3]);
	die "$str\n";
    }

    if (! exists($db_handles{$db_alias}))
    {
	# See sub db_info above.
	(my $connect_string,
	 my $db_user,
	 my $db_password) = db_info($db_alias);
	
	my $dbargs = {AutoCommit => 0, PrintError => 1};
	
	$db_handles{$db_alias} =  DBI->connect($connect_string,
					       $db_user,
					       $db_password,
					       $dbargs);

	# The password is only in connect_string for MySQL, but always
	# try to make connect_string safe. See notes in db_info()
	# above.

	# Do not call any of the db-centric write_log subs on error. If
	# the db connection isn't working, we can't log to the db.

	if ($db_password)
        {
            $connect_string =~ s/$db_password/*******/g;
        }
	if ($DBI::err)
	{
	    my $str = sprintf("%s Couldn't connect using connect_string: $connect_string\n", (caller(0))[3]);
	    die "$str\n";
	}
    }
    return $db_handles{$db_alias};
    my $quiet_compile_warnings = $DBI::err;
}


# Like get_db_handle() but very simple for use with SQLite only. Maybe someday this should be merged with
# get_db_handle() in some backward compatible way.

# For now the filename is also the alias which is also the key in the %db_handles hash.

sub sqlite_db_handle
{
    my $db_file = $_[0];
    my $db_alias = $db_file; 
    my $db_user = '';
    my $db_password = '';
    
    if (! exists($db_handles{$db_alias}))
    {
        my $connect_string = "dbi:SQLite:dbname=$db_file;host=;port=;";
        
        # There was an occasion when transactions broke, and it was due to something disabling
        # sqlite_use_immediate_transaction. Force it to be enabled.
        my $dbargs = {sqlite_use_immediate_transaction => 1, AutoCommit => 0, PrintError => 1};
        
        $db_handles{$db_alias} =  DBI->connect($connect_string,
                                               $db_user,
                                               $db_password,
                                               $dbargs);
        
        # Do not call any of the db-centric write_log subs on error. If
        # the db connection isn't working, we can't log to the db.
        
        if ($db_password)
        {
            $connect_string =~ s/$db_password/*******/g;
        }
        if ($DBI::err)
        {
            my $str = sprintf("%s Couldn't connect using connect_string: $connect_string\n", (caller(0))[3]);
            die "$str\n";
        }
    }
    return $db_handles{$db_alias};
    my $quiet_compile_warnings = $DBI::err;
}

sub commit_handle
{
    my $db_alias = $_[0];
    if (! $db_alias)
    {
	die "You must supply a valid handle to commit_handle().\n";
    }

    if (exists($db_handles{$db_alias}))
    {
	my $dbh = $db_handles{$db_alias};
	$dbh->commit();
    }
    else
    {
	die "Don't have a db handle alias $db_alias. You must supply a valid handle to commit_handle().\n";
    }
}



# This cleans all db handles.
sub clean_db_handles
{
    foreach my $key (keys(%db_handles))
    {
	my $dbh = $db_handles{$key};
        $dbh->disconnect();
	delete($db_handles{$key});
    }
}

# This hasn't been tested. Called from busy() below
# on non-PBS systems.
sub load_average
{
    my $temp = `uptime`;
    $temp =~ m/load average:\s+(.*?),/;
    return $1;
}


# Requires qstat, qstat_args, max_launch
sub busy
{
    my %cf = app_config();
    check_config(\%cf, "qstat,qstat_args,max_launch");

    if (-e "$cf{qstat}")
    {
	my $total_jobs = -1;
	my $running = -1;
	my $queued = -1;
	my $temp = `$cf{qstat} $cf{qstat_args}`;
	
	if (0)
	{
	    # PBS queue depends on total jobs (including E) not just running and queued.
	    if ($temp =~ m/total_jobs = (\d+)/)
	    {
		$total_jobs = $1;
	    }
	    # Trap failures of qstat or the regex
	    if ($total_jobs == -1)
	    {
		my $date = localtime();
		write_log("$0 $date error Can't launch. Invalid value: t:$total_jobs");
		write_log("$0 $date error qstat responded:\n$temp");
		return 0;
	    }
	}
	else
	{
	    # In the old days we mistakenly only counted running and queued jobs.
	    if ($temp =~ m/Running:(\d+)/s)
	    {
		$running = $1;
	    }
	    if ($temp =~ m/Queued:(\d+)/s)
	    {
		$queued = $1;
	    }
	    
	    # Trap failures of qstat or the regexes
	    if ($running == -1 || $queued  == -1)
	    {
		print "Can't launch. Invalid values: r:$running q:$queued\n";
		print "qstat responded:\n$temp\n";
		return 0;
	    }
	    $total_jobs = $running + $queued;
	}
	my $num_to_launch = $cf{max_launch} - $total_jobs;
	if ($num_to_launch <= 0)
	{
	    $num_to_launch = 0;
	}
	return $num_to_launch;
    }
    else
    {
	# This is legacy(?) code for non-PBS. It doesn't work as it should.
	if (load_average() > 1.00)
	{
	    return 0; # Don't launch any more jobs
	}
	return 1; # Only launch one job 
    }
}


# check_config(\%cf, "name1,name2,name3");

# Use this to verify that the config we've read has the minimum
# required values.  usage: check_config(\%cf, "name1,name2,name3");
# CGI programs must not print to stdout unless they are printing a
# valid http reply. 

# twl sep 10 2008 Apache (or the CGI module) will only send a valid
# error message to back to the browser if we die only. Any extra
# printing to stdout (instead of to stderr) makes Apache send all the
# output back to stdout. Therefore, in spite of what the old comment
# below says, only print to stderr.

# Old comment: Therefore, since we want the following code to
# print to stdout, also make it die (print to stderr) to make Apache
# happy.

sub check_config
{
    my $cf = $_[0];
    my $str = $_[1];
    
    if (! (ref($cf) eq 'HASH'))
    {
        my $msg = sprintf("Expecting a hash reference. Wrong type of 1st arg in %s at line: %s called from file: %s line: %s\n",
                          __FILE__,
                          __LINE__,
                          (caller(0))[1],
                          (caller(0))[2]);
        die $msg;
    }

    my @list = split(',', $str);
    foreach my $item (@list)
    {
	if (!exists($cf->{$item}))
	{
	    my $dot_slash = abs_path("./");
	    my $output = "$0 error Missing required config: $item\n";
	    $output .= "app_config:$cf->{app_config}\n";
	    $output .= "Checking path: $path\nand: $dot_slash\n";
	    if (exists($ENV{APP_CONFIG}))
	    {
		$output .= "and: $ENV{APP_CONFIG}\n";
	    }
	    die $output;
	}
    }
}


# Make strings safe for exposure to the command line. 
# Allow only a minimal "file name" and "directory name" compatible set.
# jul 18 2008 twl add : and ~ to the list of approved chars. They seems harmless
# on the command line, and we need it for urls http://example.com/file.txt

sub untaint
{
    my $var = $_[0];
    $var =~ s/[^A-Za-z0-9\.\_\-\/:~]//g;
    return $var;
}

# Similar to capture_file below, but gets the file from a URL

sub capture_url
{
    my %cf = %{$_[0]}; # expecting cp_exe, unlink_exe, chmod_exe
    my $orig = $_[1];
    my $dest_dir = $_[2];
    my $comment = $_[3];

    my $suffix;
    my $stem;
    if ($orig =~ m/.*\/(.*)(\..*)/)
    {
	$stem = $1;
	$suffix = $2;
    }
    else
    {
	die "Can't understand URL: $orig\nExample: http://example.com/spectra_1234.dta\n";
    }

    
    my $fi_pk                = main::sql_insert_file(0, $dest_dir, $orig, $comment);
    my $dest_short_name      = "$stem\_$fi_pk$suffix";
    my $dest		     = "$dest_dir/$dest_short_name";
    
    # cp the file so the ownership will change.
    # remove the original, then chmod destination
    
    $orig = untaint($orig);
    $dest = untaint($dest);
    
    # Support both wget and curl. On mac osx wget_exe is probably curl. 
    # curl -s silent, -o output file
    # wget -q quiet, -O output file (cap O)

    my $silent_sw = "-q";
    my $output_sw = "-O";
    if ($cf{wget_exe} =~ m/curl/)
    {
	$silent_sw = "-s";
	$output_sw = "-o";
    }

    my $temp = `$cf{wget_exe} $silent_sw $orig $output_sw $dest 2>&1`;
    
    if (-e $dest)
    {
	`$cf{chmod_exe} 0644 $dest`;
    }
    else
    {
	die "Failed to get\norig:$orig\ndest:$dest.\n$temp\n";
    }
    main::sql_update_file($fi_pk, $dest_short_name);
    return ($dest_short_name, $fi_pk);
}


# Capture incoming file by writing its name to the database, and moving it (cp followed by unlink) into a
# private system directory.  This subroutine is derived from ms_lims/cmlib.pl sub capture_file.  Any
# processing of multi-select CGI menus has to be done before calling capture_file.  Require full path on the
# orig.

sub capture_file
{
    my %cf = %{$_[0]}; # expecting cp_exe, unlink_exe, chmod_exe
    my $orig = $_[1];
    my $dest_dir = $_[2];
    my $comment = $_[3];

    my $stem;
    my $suffix;
    if ($orig =~ m/.*\/(.*)(\..*)/)
    {
	$stem = $1;
	$suffix = $2; # includes leading dot
    }
    else
    {
	die "Can't understand file name: $orig\n";
    }
    
    my $fi_pk = main::sql_insert_file(0, $dest_dir, $orig, $comment);
    my $dest_short_name = "$stem\_$fi_pk$suffix";
    my $dest = "$dest_dir/$dest_short_name";
    
    # cp the file so the ownership will change.
    # remove the original, then chmod destination
    
    $orig = untaint($orig);
    $dest = untaint($dest);
    
    my $temp = `$cf{cp_exe} $orig $dest 2>&1`;
    
    if (-e $dest)
    {
	`$cf{unlink_exe} $orig`;
	`$cf{chmod_exe} 0644 $dest`;
    }
    else
    {
	die "Failed to copy\norig:$orig\ndest:$dest.\n$temp\n";
    }
    main::sql_update_file($fi_pk, $dest_short_name);
    return ($dest_short_name, $fi_pk);
}


# Someday the login could be more complex, i.e. we start using a real
# session.  twl: apr 22 2008 Add alternatives as a workaround for
# broken OSX Leopard.  Do not use database (Vela) logging here since
# this sub is called from the Vela logging facility. If this is
# broken, Vela won't be able to write log messages.

sub login
{
    my %cf = app_config();
    
    # See sql_lib_vj.pl for sql_user_info().
    if (session_id())
    {
	my $hr = main::sql_user_info(db_name => $cf{login_db}, session_id =>  session_id());
	return $hr->{us_pk};
    }

    my $userid;
    if (exists($ENV{REMOTE_USER}))
    {
        $userid = $ENV{REMOTE_USER};
    }
    else
    {
	$userid = `/usr/bin/id -un`;
	chomp($userid);
    }

    # If the username is all numeric (as with the apparent bug in OSX)
    # then try the somewhat unreliable env var LOGNAME.

    if ($userid =~ m/^\d+$/)
    {
	if (exists($ENV{LOGNAME}))
	{
	    $userid = $ENV{LOGNAME};
	}
	elsif (exists($ENV{USER}))
	{
	    $userid = $ENV{USER};
	}
	else
	{
	    die "Error: Cannot get name of user\n";
	}
    }

    # Supply a text userid such as mst3k. Not numerid uid. Not numeric
    # us_pk.

    if (! $userid)
    {
	die "Error: no userid in login()\n";
    }

    my $us_pk = main::sql_userid2us_pk(db_name => $cf{login_db}, userid => $userid);

    return $us_pk;
}


# Perform some common substitutions on templates.
#
# We have to read the file because HTML::Template doesn't grok
# URI encoded < and > which are necessarily encoded by HTML editors
# inside other tags and attribute values.

sub process_template
{
    my $template_text = read_file($_[0]);
    $template_text =~ s/\&lt\;/</g;
    $template_text =~ s/\&gt\;/>/g;
    $template_text =~ s/\%3C/</ig;
    $template_text =~ s/\%3E/>/ig;
    $template_text =~ s/\%20/ /g;
    $template_text =~ s/\%21/\!/g;
    $template_text =~ s/(\S)\-\-\>/$1 -->/g; # HTML::Template requires space before -->
    

    # Something eats " so doing the substitution here
    # may not help. The solution is to just dispense with the "" around
    # HTML::Template tmpl_var variable names.

    $template_text =~ s/(\%22)/\"/g;

    # aug 09 2008 twl. Regex excitement to support SSI includes. Use
    # a /e s/// regex to get the include file name, and replace the
    # include expression with the file. The /g assures that all
    # includes will be processed.

    $template_text =~ s/(<!--#include\s+virtual\s*=\s*\"(.*?)\"\s+-->)/read_file($2)/eg;

    return $template_text;
}


# This is called for config that is instance specific, i.e. a specific
# time that an application is run. The user config replaces the command line
# arguments. The args for omssacl can be very long, so it makes sense to 
# store them in the db or in a file.
# See clwrapper.pl

sub user_config
{
    my $file_name = $_[0];
    my $single_return = $_[1];

    my $all = read_file($file_name);
    my %cf;
    my %cf_hide;
    ac_core($all, \%cf, \%cf_hide);

    # If we have been redirected to another config file,
    # read it. Keep all the values. All kinds of things
    # could go wrong with this (overwritten values, infinite loops, etc.).
    # Users should be careful with multiple config files.

    my $xx = 0;
    while ($cf{redirect} && ($xx < 5))
    {
	$all = read_file($cf{redirect});
	$cf{app_config} .= ", $cf{redirect}"; # save visited file names for debugging.
	$cf{redirect} = "";
	ac_core($all, \%cf, \%cf_hide);
	$xx++;
    }

    if ($single_return)
    {
	foreach my $key (keys(%cf_hide))
	{
	    if ($key ne $single_return &&
		$key ne "app_config")
	    {
		delete($cf_hide{$key});
	    }
	}

	return %cf_hide;
    }
    else
    {
	return %cf;
    }
}


# Use this as a functional interface to app_config. This will return a
# single, non-hide value. If you want a single hidden value, use the
# single return feature of app_config().

sub named_config
{
    my $view_which = $_[0];
    my %cf = app_config();
    check_config(\%cf, $view_which);
    return $cf{$view_which};
}

# app_config() takes an optional single arg. This clearly separates
# sensitive values from everything else. If someone doesn't ask for a
# particular hidden value, then no hidden values are returned.

# Environment variable APP_CONFIG overrides user .app_config Always
# read $path/.app_config if it exists.  Read .app_config in program
# directory and ./ but since ./ is read last, it's values will
# overwrite. If we have been redirected to another config file, read
# it (up to 5 redirects). Keep all the values from all the
# redirects. All kinds of things could go wrong with this (overwritten
# values, infinite loops, etc.).  Users should be careful with
# multiple config files. Local user .app_config will over write
# anything in the system .app_config. Note that the presence of an
# $ENV{APP_CONFIG} will prevent the user .app_config from being used.

# Don't add db logging to any app_config subs because db logging calls app_config.

sub app_config
{
    my $single_return = $_[0];
    my %cf;
    my %cf_hide;
    my $ok_flag = 0;

    if (defined($main::ac_check_one) && $main::ac_check_one)
    {
        # 04 mar 2008 Add a mode where only one "master" .app_config is read, as
        # opposed to reading each of the available app_config files.  Up to 5
        # redirects are always read, if available.
	if (exists($ENV{APP_CONFIG}))
	{
	    $ok_flag = check_and_traverse($ENV{APP_CONFIG}, \%cf, \%cf_hide);
	}
	elsif ( -e "$path/.app_config")
	{
	    $ok_flag = check_and_traverse("$path/.app_config", \%cf, \%cf_hide);
	}
	elsif (-e "./.app_config")
	{
	    $ok_flag = check_and_traverse("./.app_config", \%cf, \%cf_hide);
	}
    }
    else
    {
	# The existing code checks the $path/.app_config with redirects
	# and then one of the ENV or ./.app_config (but not both). Redirects were
	# not checked for this second case, and that bug is fixed here even though
	# the "only one" feature is still here.
	if ( -e "$path/.app_config")
	{
	    $ok_flag = check_and_traverse("$path/.app_config", \%cf, \%cf_hide);
	}
	if (exists($ENV{APP_CONFIG}))
	{
	    $ok_flag = check_and_traverse($ENV{APP_CONFIG}, \%cf, \%cf_hide);
	}
	elsif (-e "./.app_config")
	{
	    $ok_flag = check_and_traverse("./.app_config", \%cf, \%cf_hide);
	}
    }
    if (! $ok_flag)
    {
	my $dot_slash = abs_path("./");
	print "Cannot find .app_config\n";
	print "Checked: $path\nand: $dot_slash\n";
	if (exists($ENV{APP_CONFIG}))
	{
	    print "and: $ENV{APP_CONFIG}\n";
	}
	write_log("$0 Error: Cannot find .app_config in $path and $dot_slash and $ENV{APP_CONFIG}");
	exit(1);
    }

    # If we have a single_return, get it from the hide hash,
    # clear out everything except the asked for field and "app_config"
    # and return the hide hash instead of the usual %cf.

    if ($single_return)
    {
	if (! exists($cf_hide{$single_return}))
	{
	    my $output = "$0 app_config:\"$single_return\" not in \"hide\" for\n$cf_hide{app_config}\nkeys\n";
	    foreach my $key (keys(%cf_hide))
	    {
		$output .= "$key\n";
	    }
	    $output .= "app_config: $cf_hide{app_config}\n";
	    die "$output";
	}

	foreach my $key (keys(%cf_hide))
	{
	    if ($key ne $single_return &&
		$key ne "app_config")
	    {
		delete($cf_hide{$key});
	    }
	}

	return %cf_hide;
    }
    else
    {
	return %cf;
    }
}


# Called from app_config above.
# Don't add db logging to any app_config subs because db logging calls app_config.
sub check_and_traverse
{
    my $ac_file = $_[0];
    my $cf_hr = $_[1];
    my $cf_hide_hr = $_[2];
    my $ok_flag = 0;
    
    if (-e $ac_file)
    {
	my $all = read_file($ac_file); 

	# save visited file names for debugging.
	# Get the current working directory, and substitute for ./
	# at the front of the $ac_file if ./ is there. 
	my $cwd = `/bin/pwd`;
	chomp($cwd);
	$ac_file =~ s/^\.\//$cwd\//;

	$cf_hr->{app_config} .= "$ac_file, ";

	ac_core($all, $cf_hr, $cf_hide_hr);
	$ok_flag = 1;

    }
    my $xx = 0;
    while ($cf_hr->{redirect} && ($xx < 5))
    {
	my $all = read_file($cf_hr->{redirect});
	# save visited file names for debugging.
	$cf_hr->{app_config} .= ", $cf_hr->{redirect}";
	$cf_hr->{redirect} = "";
	ac_core($all, $cf_hr, $cf_hide_hr);
	$xx++;
    }
    return $ok_flag;
}

# Note 3.
# After going through much testing for substituting variables into 
# template text for another application we created the following regex.
# The complicated looking regex with the eval flag will
# work for all variables that exist in the hash, understands beginning
# and end of lines, variables that contain numbers (and underscore),
# and it should be fast and efficient. It also supports better debugging and 
# than the alternatives (not shown here). The second regex handles octal
# character encoding, which is very handy in any template.

# Not exported. Only called from app_config() above.
# Don't add db logging to any app_config subs because db logging calls app_config.

sub ac_core
{
    my $all = $_[0];
    my $cf_ref = $_[1];
    my $cf_hide = $_[2];
    
    # Hash of things we are willing to substitute into config
    # values. We cannot use login() because now that we handle our own
    # authentication, we don't know who the user is logged in as until
    # after authentication. However, the authentication code calls
    # app_config, and this could lead to confusion.
    
    my %subs; 
    # $subs{login} = login();
    
    # Break the file into lines. This means that a value cannot contain newlines.
    # If you need newlines, you'll need a more interesting parsing regex.

    my @lines;
    while($all =~ s/^(.*?)\n//)
    {
	my $line = $1;
	# Do not convert escaped octal sequences back to characters
	# until parsing is complete. Otherwise \075 "=" breaks the parser.
	
	$line =~ s/\#(.*)//g; 	# remove comments to end of line
	$line =~ s/\s*=\s*/=/g;	# remove whitespace around = 
	$line =~ s/\s+$//g;	# remove trailing whitespace
	$line =~ s/^\s+//g;	# remove leading whitespace
	
	# If there is anything left, push it.
	if ($line)
	{
	    push(@lines, $line);
	}
    }

    # The last line (or fragment), if there is one.
    if ($all)
    {
	$all =~ s/\#(.*)//g; 	# remove comments to end of line
	$all =~ s/\s*=\s*/=/g;	# remove whitespace around = 
	$all =~ s/\s+$//g;	# remove trailing whitespace
	$all =~ s/^\s+//g;	# remove leading whitespace
	
	push(@lines, $all);
    }

    foreach my $line (@lines)
    {
	# See Note 3 above.
	$line =~ s/(?<!\\)(\$([\w\d]+))(?!=\w)(?!=\d)(?!=\z)/exists($subs{$2})?$subs{$2}:$1/eg;

	$line =~ m/^((.*)=(.*))$/;
	my $name = $2;
	my $value = $3;

	$name =~ s/\\([0-9]{3})/chr(oct($1))/eg;
	$value =~ s/\\([0-9]{3})/chr(oct($1))/eg;
	$cf_ref->{$name} = $value;
    }
    
    if (exists($cf_ref->{hide}))
    {
	my @hide_list = split('\s+', $cf_ref->{hide});
	foreach my $hide (@hide_list)
	{
	    # Only overwrite if $cf_ref has a value!
	    if (exists($cf_ref->{$hide}))
	    {
		$cf_hide->{$hide} = $cf_ref->{$hide};
		delete($cf_ref->{$hide});
	    }
	}
    }



    # Hide needs a copy of the debug info too.
    # Hide does not need, nor does it get a copy of full_text (below).

    $cf_hide->{app_config} = $cf_ref->{app_config};



    # Each .app_config can supply a list of options to include in the
    # full_text field. This field's purpose is as record keeping only
    # (audit trail).  NOTE: This code must come after the hide values
    # have been deleted so that users cannot accidentally put hide
    # values into full_text output. Normal users might see full_text
    # so don't put anything private in there.

    if ($cf_ref->{full_text})
    {
	my @full_text_keys = split('\s+', $cf_ref->{full_text});
	my $tween = "";
	foreach my $key (@full_text_keys)
	{
	    $cf_ref->{full_text} .= "$tween$cf_ref->{$key}";
	    $tween = "\n";
	}
    }
}

# Used by clwrapper.pl and other code with special needs for config files.
# This keeps the one non-null value of a group of config options and deletes the rest of
# the options from the hash reference. This is used in wrapping omssacl
# where one and only one output file arg is required. We want to clean
# up the extraneous (null) output args, but keep the single good arg (good
# because it has a non-null value).

sub keep_one
{
    my $hr = $_[0];
    my $keep_us = $_[1];
     
    my @keepers = split(",", $keep_us);
    my $signal_count = 0;
    my $value = undef;
    foreach my $item (@keepers)
    {
	if (exists($hr->{$item}) && length($hr->{$item}) > 0)
	{
	    $signal_count++;
	    $value = $hr->{$item};
	}
	else
	{
	    delete($hr->{$item});
	}
    }
    if ($signal_count > 1)
    {
	die "Too many properties are defined in list \"$keep_us\". Count:$signal_count\n";
    }
    return $value;
}


# Value is set when run_session() is called. 

my $session_id = "";

sub session_id
{
    return $session_id;
}


# This is an exciting bit of code called by any script
# that needs only high-level access to sessions.

# Note RS1. sql_check_login attempts to update the fd_last_mod for the
# current login record. It tries to update based on correct
# session_id, login_ok, and a non-expired fd_last_mod. This is
# critical since this validates sessions. sql_check_login also checks
# the site key from .app_config to see if the user is linked to a site
# key in table site_keys.

# A side effect is setting $ENV{REMOTE_USER} to the us_pk of the user's record.

sub run_session
{
    my %arg = @_;
    my $chr = $arg{chr};
    my $qq = $arg{cgi};

    # Never write the cleartext password to the db.
    # The password is only used in login.pl. Heaven help anyone
    # who tries to use a CGI parameter called "password".

    delete($chr->{password}); 

    $chr->{session_id} = $qq->cookie('Apache'); 
    $session_id = $chr->{session_id};
    
    my %cf = app_config();
    check_config(\%cf, "site_key,login_db");

    my $db_name = $cf{login_db};
    
    (my $dummy, my $http_cookie) = update_cookie($chr->{session_id});

    # See Note RS1 above.
    my $us_pk = main::sql_check_login(db_name => $db_name,
				       session_id => $chr->{session_id},
				       site_key => $cf{site_key});

    my $hr = main::sql_user_info(db_name => $cf{login_db}, 
				 us_pk => $us_pk,
				 session_id => $chr->{session_id});

    if ($us_pk)
    {
	# Icky side effect. We're changing the global %ENV hash. This
	# has already created confusion.

	$ENV{REMOTE_USER} = $hr->{email};
	# Session var names (sname) and values
	
	my %sname = main::sql_all_svar(db_name => $db_name,
				       session_id => $chr->{session_id});

	# Merge %sname and $chr, where values is $chr are preserved if
	# there is a duplicate.

	# May or may not overwrite the hash referenced by $chr
	my %temp = (%sname, %{$chr});
	%{$chr} = %temp;
    }
    commit_handle($db_name);
    clean_db_handles();

    # Put the cookie and some cache control into the http header.
    # This was a nasty side effect of the login session system.

    my $ret = "$http_cookie\n";
    $ret .= "HTTP_PRAGMA: no-cache\n";
    $ret .= "HTTP_CACHE_CONTROL: no-cache\n";

    if (! $us_pk)
    {
	my $url = index_url(0); # Rewritten! see sessionlib.pl
	$url .= "/login.pl";
	print "Location: $url\n\n";
	exit(1);
    }
    return $ret;
}



# New: Save %ch (the reference $chr) as form data. Over write what
# ever is in the form data. We assume that %ch has been updated to
# include everything we want to save, and nothing we don't want. This
# is called at the end of a user script to save state. Make sure we
# are logged in. The low level code doesn't check login status.

# Old:Only call save_session() from a 2 script (i.e. insert_gene2.pl)
# where we are collecting data, but things are not right. If we can't
# write the data into one of the real tables, call save_session() to
# save all the hash values.  It also deletes session data for
# non-existant hash keys (presumably from some other web page.)

# insert new records

# update existing records

# delete non-existant records (which might be things like checkboxes
# which are now null) Unfortunately, delete may not apply to all
# circumstances, and then we'll have to modify this sub. That has
# already happened once with 'login'.

sub save_session
{
    my %arg = @_;
    my $chr = $arg{chr};

    my %cf = app_config();
    check_config(\%cf, "site_key,login_db");

    # See Note RS1 above.
    my $us_pk = main::sql_check_login(db_name => $cf{login_db},
				       session_id => $chr->{session_id},
				       site_key => $cf{site_key});

    if ($us_pk)
    {
	main::sql_save_form_data(db_name => $cf{login_db},
				 sn_ref => $chr,
				 session_id => $chr->{session_id});
	
	commit_handle($cf{login_db});
    }
}




# Create a cookie, and set the expiration time

# Note 2.  If Apache didn't do the cookie, make one just like it.  If
# the cookie expires, or the user deletes their cookies, we will get
# an http request without a cookie. In that case we could do something
# goofy to force a page redraw (like a redirect with a counter just in
# case the cookie doesn't show up) but that's not robust.  So, just
# create a cookie that is just like the Apache cookie.  The remote
# user's IP address dot timestamp with nanoseconds (chomp backtick
# returned values as usual) The last 3 digits are always zero. Apache
# chops them off, so do we.  Incidently, using an X instead of a dot
# helps debugging, and works just fine.

sub update_cookie
{
    my $cookie_value = $_[0];

    if (length($cookie_value) == 0)
    {
	# See Note 2 above. 

	$cookie_value = $ENV{REMOTE_ADDR} . ".";
	$cookie_value .= `date +%s%N`;
	chomp($cookie_value);
	chop($cookie_value); 
	chop($cookie_value);
	chop($cookie_value);
    }

    my $cookie = CGI->cookie(-name=>'Apache',
			     -value=>"$cookie_value",
			     -expires=>$EXP_TIME # usually +1200 (seconds)
			     );

    return ($cookie_value,"Set-Cookie: $cookie");
}



# Return a unique file name, based on what is already on disk.
# For nth file create sequential name.
# i.e. turn a.dat into a_1.dat, a_2.dat, ...
# The non _n file is the zeroth file.
#
# Keep the path separate. Check it, and return a unique filename for that 
# path, but only return the file name, not path concatenated with file name.
# 
# Change all non-alphanumerics to underscore.
# Allow . and -

sub safe_file
{
    my $fn = $_[0];
    my $dir = $_[1];
    my $stem;
    my $suffix;

    # Can't pass in a full path due to the following regex,
    # do the dir is a separate arg.

    $fn =~ s/[^a-zA-Z0-9\.\-]/_/g; # change all non-alpha numerics to underscore

    if ($fn =~ m/(.*)\.(.*)/)
    {
        $stem = $1;
        $suffix = $2;
    }
    else
    {
        $stem = $fn;
        $suffix = ".dat";
    }

    # Prepend the dir, then check for duplicate names.
    # The non _n file is the zeroth file.

    my $verified_fn = "$stem\.$suffix";
    my $xx = 1;
    while(-e "$dir/$verified_fn")
    {
        $verified_fn = "$stem\_$xx\.$suffix";
        $xx++;
    }

    # Return file name with no path!

    return $verified_fn;
}


my $rand_str="thisbetterbearandomboundarystring";

sub init_progress_meter
{
    my $all = read_file("progress.html");
    print "Content-type: multipart/x-mixed-replace;boundary=$rand_str\n\n";
    print "--$rand_str\n\n";
    return $all;
}

sub progress_meter
{
    my $all = $_[0];
    my $file_bytes = $_[1];

    # progress bar graphic and string var.
    #my $p_orig = "<img src=\"7F44E1_spacer.jpg\" height=10 width=5>";
    #my $p_str;
    #$p_str = multi_string(100, $p_orig);
    #$all =~ s/\$p_str/$p_str/;
    
    my $file_size = "";
    if ($file_bytes > 1048576)
    {
	$file_size = sprintf("%d Mb", $file_bytes/1048576);
    }
    elsif ($file_bytes > 10240)
    {
	$file_size = sprintf("%d Kb", $file_bytes/1024);
    }

    $all =~ s/\$file_size/$file_size/;
    $|= 1;     # Force a flush on every print for STDOUT. 
    print "Content-type: text/html\n\n$all\n--$rand_str\n\n";
}


# What is this? Is it even used?
sub multi_string
{
    my $factor = $_[0];
    my $orig = $_[1];

    my $result;
    for(my $yy=0; $yy<$factor; $yy++)
    {
	$result .= $orig;
    }
    return $result;
}


# 2005-may-09 make the buffer size 10240 for binary files.
#
# 2004-12-13 Combines text and binary upload. By returning the correct file name
# this also fixes a bug.
#
# Strip any path info that the browser may have prepended to the file name.
# Apparently IE does this. I haven't seen it from Mozilla under Linux.
# Make all filenames lowercase. 
#
# Remove carriage returns (^M, Windows line endings) from uploaded
# text files.
#
# Mozilla won't render text/plain if there is a control character at byte 1024 or earlier.
# Consider stripping non-carriage controls from uploaded .txt files in cellmig.
# For now, change ^A to space.
#
# Note 1.
# The file name in $ch_hr->{fn_key} has to be passed in un-changed
# so we can get a filehandle from the CGI code. Therefore we can't
# prepend the distination directory until a few lines down, and therefore
# the destination directory needs to be passed in as a separate argument.

# save_upload_file($qq, \%ch, "exp_upload", $ch{dest_dir}, $ch{exp_id}, "", 0);

sub save_upload_file
{
    my $qq = $_[0]; # CGI object
    my $ch_hr = $_[1]; # The CGI object hash. 
    my $fn_key = $_[2]; # $ch_hr->{} hash key with file name.
    my $dest_dir = $_[3]; # see note 1 above.
    my $upload_type = $_[4]; # '' is just an upload. 'text' or 'pta' do special things.
    my $use_db = $_[5]; # True use the database, else ignore database.
    my $message = "";
    
    if (! exists($ch_hr->{$fn_key}) || (length($ch_hr->{$fn_key}) == 0))
    {
	# Nothing to do.
	# Used to turn a bad filename into "". 
	return;
    }

    my $fn_value = $ch_hr->{$fn_key};

    # These are temp file handles created by CGI. We can't/don't want to leave the file here so we read it in
    # an rewrite it below.

    my $filehandle = $qq->upload($fn_key);
    my $f_hr = $qq->uploadInfo($filehandle);

    $fn_value =~ s/(.*\\)//;
    $fn_value = lc($fn_value);
    
    my $fn_suffix = "";
    my $fn_prefix = "";
    if ($fn_value =~ m/(.*)\.(.*)/)
    {
        $fn_prefix = $1;
        $fn_suffix = $2;
    }

    my $new_fn = "$dest_dir/$fn_value";
    my $fh;

    if (0) # Create unique filename. Use when not saving in a unique dirctory.
    {
        # Get a unique value and use as suffix on the file name. A plus of this method is that we can insert into
        # the db and not have to run an update later. (As used to be necessary when we relied on the fi_pk as the
        # unique string in the file name.)
        
        use File::Temp qw( :POSIX tempfile);
        
        # Note the leading dot "." on the suffix.
        
        # Can't end a template with a dot.
        # Error in tempfile() using data/floHasqbmg/single_marc_XXXXXXXXXX.xml: The template must end with at least 4 'X' characters#
        
        ($fh, $new_fn) = tempfile( "$fn_prefix\_XXXXXXXXXX", DIR => $dest_dir, SUFFIX => ".$fn_suffix");
    }
    else
    {
        if (! open($fh, ">", "$dest_dir/$fn_value"))
        {
            $ch_hr->{message} .= "Can't open $dest_dir/$fn_value for output";
            return (undef, undef);
        }
    }

    my $fi_pk = 0;
    if ($use_db)
    {
        $fi_pk = main::sql_insert_file(0, $dest_dir, $fn_value, "uploaded file");
        
        if (0) # old think before using tmpnam
        {
            # Make the filename unique. tmp.txt becomes tmp_xxx.txt
            # where xxx is the $fi_pk.
            # $fn_value =~ s/(.*)\.(.*)/$1\_$fi_pk\.$2/; 
            # main::sql_update_file($fi_pk, $fn_value);
        }
        commit_handle();
        clean_db_handles();
    }

    if ($upload_type eq 'text')
    {
	# Normal text file, except that we munge it a bit.
	# open (A_OUT,">", $dest_file) || die "Cannot open $dest_file for write.\n";
	my $buffer;
	while (my $bytesread=read($filehandle,$buffer,1024))
	{
	    $buffer =~ s/\015//sg;  # remove ^M
	    $buffer =~ s/\001/ /sg; # change ^A to space.
	    print $fh $buffer;
	}
	close($fh);
    }
    elsif ($upload_type eq 'pta')
    {
	# Post translational analysis data file.
	# Check the first line of the file. It must have 'peptide' or 'sequence' as part of
	# column headers. If the text is present, we'll assume that it is a file header.

        my $buffer;
        my  $bytesread=read($filehandle,$buffer,1024);
	if ($buffer !~ m/sequence|peptide/i)
	{
	    $message = "22x";
	}
	else
	{
	    # open (A_OUT,">", $dest_file) || die "Cannot open $dest_file for write.\n";
	    print $fh $buffer; # print (save) first line we read above!
	    while (my $bytesread=read($filehandle,$buffer,1024))
	    {
		$buffer =~ s/\015//sg;  # remove ^M
		print $fh $buffer;
	    }
	    close($fh);
	}
    }
    else
    {
	# Any other file, usually binary.
	# open (A_OUT,">", $dest_file) || die "Cannot open $dest_file for write.\n";
	my $buffer;
	my $total_bytes = 0;
	while (my $bytesread=read($filehandle,$buffer,10240))
	{
	    print $fh $buffer;
	    $total_bytes += $bytesread;
	}
	close($fh);
    }
    $ch_hr->{message} .= $message;
    return ($new_fn, $fi_pk);
}

sub index_url($)
{
    my $iflag = $_[0];
    my $protocol = "http";
    if (exists($ENV{HTTPS}))
    {
	$protocol = "https";
    }
    my $url = "$protocol://$ENV{HTTP_HOST}$ENV{REQUEST_URI}";
    # 
    # 2002-01-24 Tom:
    # Fix this to return the base URL, and understand ~userid URLs
    # Return the URL without the final file name, and without the trailing /
    # 
    if ($url =~ m/\/~/)
    {
	$url =~ s/(.*\/~.*)\/.*/$1/;
    }
    else
    {
	$url =~ s/(.*)\/.*/$1/;
    }
    if ($iflag)
    {
	$url .= "/index.pl";
    }
    return $url;
}


sub email
{
    my %info;
    ($info{name}, $info{email}, $info{login}) = @_;
    my %vars = config(); # see config.pl

    $info{nextURL}  = "http://$vars{wwwhost}/$vars{wwwpath}";
    $info{fromMail} = "nobody\@$vars{wwwhost}";
    $info{ccMail}   = $vars{contact_email};

    #
    # I know it isn't an html file, but if I used anther extension,
    # I'd have to modify the makefile. Later.
    # 
    my $email = readfile("admin_email.html");
    $email =~ s/{(.*?)}/$info{$1}/g;

    open (MAIL, '|-', '/usr/lib/sendmail -t -oi');
    print MAIL "$email\n";
    close MAIL;
}


sub exists_message
{
    my $email = $_[0];
    my $temp = <<EOS;
The email: $email already exists in our contact database.\n
Maybe you already have an account with us?\n
If you believe that this is a mistake, please contact your Genex administrator
to resolve the issue.
EOS
    return $temp;
}

sub final_message
{
    my $temp = "You have enter the following information:\n";
    my $key;
    foreach $key ( @_ ) {
        $temp .= "$key\n";
    }
    
    $temp .= "An email message containing the new login and password has been\n";
    $temp .= "send to the address above.\n";
    return $temp;
}


sub read_file
{
    my @stat_array = stat($_[0]);
    if ($#stat_array < 7)
      {
        die "read_file: File $_[0] not found\n";
      }
    my $temp;

    # It is possible that someone will ask us to open a file with a leading space.
    # That requires separate args for the < and for the file name.
    # It also works for files with trailing space.

    if (! open(IN, "<", $_[0]))
    {
	die "Could not open $_[0] $!\n";
    }
    sysread(IN, $temp, 100000); # $stat_array[7]);
    close(IN);
    return $temp;
}

sub read_file_array
{
    my @stat_array = stat($_[0]);
    if ($#stat_array < 7)
      {
        die "read_file: File $_[0] not found\n";
      }
    my $temp;

    # It is possible that someone will ask us to open a file with a leading space.
    # That requires separate args for the < and for the file name.
    # It also works for files with trailing space.

    my $st;
    if (! open($st, "<", $_[0]))
    {
	die "Could not open $_[0] $!\n";
    }
    
    # Use singular var names. "The line array". There is one one per element,
    # and the array is named for the type of element.
    
    my @line;
    @line = <$st>;
    chomp(@line);
    close(IN);
    return @line;
}


sub write_log
{
    my $fn = "./error.txt";

    open(LOG_OUT, ">>", $fn) || die "Cannot open log $fn\n";
    print LOG_OUT "$_[0]\n";
    close(LOG_OUT);
    # chmod(0660, $fn);
}

sub write_log2
{
    my $log_dir = $_[0];
    my $message = $_[1];

    if (! $log_dir || ! -d $log_dir || ! $message)
    {
	print "Error: write_log2 Missing log_dir or message\n";
	exit(1);
    }

    my $fn = "$log_dir/error.txt";

    open(LOG_OUT, ">>",  $fn) || die "Cannot open log $fn\n";
    print LOG_OUT "$message\n";
    close(LOG_OUT);
    chmod(0660, $fn);
}


# twl jun 5 2009: I can't see a reason for tags or keys. Table
# logger has the user's us_pk. All daemon processes will be owned by
# the user, except in the case of www or apache running
# something. That latter case would be odd. Yet another reason for
# ExecCGI.

# Original: The owner "daemon" must be in the vela db log_key table.
# This must be called with the proper key.
# The tag is always "daemon". 

sub daemon_log
{
    my $vela_name = $_[0];
    my $msg = $_[1];
    my $use_file = $_[2];

    my $us_pk = login();

    if ($use_file)
    {
	write_log("vela db name:$vela_name us_pk:$us_pk message:$msg");
    }
    else
    {
	# Assume that the calling code has required sql_lib_vj.pl
	# and therefore sql_insert_log() is in the main:: package.
	
	my $success = main::sql_insert_log(db_name => $vela_name, us_pk => $us_pk, msg => $msg);
	commit_handle($vela_name);
	# Do not clean db handles here. Other code probably wants those handles.
    }
}


sub write_log3
{
    my $vela_name = $_[0];
    my $msg = $_[1];

    # Assume that the calling code has required sql_lib_vj.pl
    # and therefore sql_insert_log() is in the main:: package.

    my $success = main::sql_insert_log(db_name => $vela_name, us_pk => login(), msg => $msg);
    commit_handle($vela_name);
    # Do not clean db handles here. Other code probably wants those handles.
}

sub log2file
{
    my $fn = $_[0];
    my $tag = $_[1];

    my %cf = app_config();
    check_config(\%cf, "vela_name");
    
    # Get the records and append them to the specified file.

    main::sql_log2file($cf{vela_name}, $fn, login());
    commit_handle($cf{vela_name});
    # Do not clean db handles here. Other code probably wants those handles.
}
#
# Combine blast hsp_qseq hsp_hseq hsp_midline
#
#   my $qmhlines = blast_qmh_lines3(qseq   =>"$hsp_qseq",
#	 			    sseq   =>"$hsp_hseq",
#		 		    midline=>"$hsp_midline",
#				    qryfrom=>$hsp_qfrom,
#				    qryto  =>$hsp_qto,  
#				    hitfrom=>$hsp_hfrom,
#				    hitto  =>$hsp_hto,  
#				    length => 100);
#
# Requires four CSS color definitions 
# qrycolor = color for query sequence
# hitcolor = color for hit sequence
# midline  = color for midline
# mismatch = color for BP's that don't match between query and hit
#
# calls qmh_mismatch
#
sub blast_qmh_lines
{
    my %sarg      =  @_;
    my $rowcnt    =  1;
    my $combined  = "\n\n";
    my $startpos  =  1;
    my $qsub      = $sarg{qryto} - $sarg{qryfrom};
    my $hsub      = $sarg{hitto} - $sarg{hitfrom};

    $sarg{sseq} =~ s/\s//g;
    $sarg{hseq} =~ s/\s//g;

    while (my $seqleng=length($sarg{sseq}))
    {
	if ($seqleng > $sarg{length}) 
	{
	    $seqleng=$sarg{length};
	}

	my ($qseq,$hseq)=qmh_mismatch(query=>substr($sarg{qseq},0,$sarg{length}),hit=>substr($sarg{sseq},0,$sarg{length}));

	my $qleng = length(substr($sarg{qseq},0,$sarg{length}));
	my $hleng = length(substr($sarg{sseq},0,$sarg{length}));
	
	my $qeol = $sarg{qryfrom}+$qleng-1;
	my $heol = $sarg{hitfrom}+$hleng-1;
	my $meol = $startpos+$seqleng-1;

	if ($qsub<0)
	{
	    $qeol = $sarg{qryfrom}-$qleng+1;
	}

	if ($hsub<0)
	{
	    $heol = $sarg{hitfrom}-$hleng+1;
	}

	$combined  .= "<span class='qrycolor'>".sprintf("%6d:",$sarg{qryfrom}).$qseq.sprintf(":%d",$qeol)."</span>\n";
	$combined  .= "<span class='midcolor'>".sprintf("%6d:",$startpos).substr($sarg{midline},0,$sarg{length}).sprintf(":%d",$meol)."</span>\n";
	$combined  .= "<span class='hitcolor'>".sprintf("%6d:",$sarg{hitfrom}).$hseq.sprintf(":%d",$heol)."</span>\n";

	$combined  .= "\n";

	$sarg{qseq}    = substr($sarg{qseq},$sarg{length});
	$sarg{sseq}    = substr($sarg{sseq},$sarg{length});
	$sarg{midline} = substr($sarg{midline},$sarg{length});

	$startpos+=$sarg{length};

	if ($qsub>=0)
	{
	    $sarg{qryfrom}+=$sarg{length};
	    $sarg{qryto}+=$sarg{length};
	}
	else
	{
	    $sarg{qryfrom}-=$sarg{length};
	    $sarg{qryto}-=$sarg{length};
	}
	    
	if ($hsub>=0)
	{
	    $sarg{hitfrom}+=$sarg{length};
	    $sarg{hitto}+=$sarg{length};
	}
	else
	{
	    $sarg{hitfrom}-=$sarg{length};
	    $sarg{hitto}-=$sarg{length};
	}


    }

    return($combined);
}
#
# find mismatches from query and hit sequence section passed
# ( This routine is not exported, called by blast_qmh_lines )
#
sub qmh_mismatch
{
    my %sarg = @_;
    my @qryseq;
    my @hitseq;
    my $newqry;
    my $newhit;

    $sarg{query} =~ s/[A-Z]|[a-z]|\*|\-/push @qryseq,$&/eg;
    $sarg{hit}   =~ s/[A-Z]|[a-z]|\*|\-/push @hitseq,$&/eg;

    for (my $idx=0;$idx<=$#qryseq;$idx++)
    {
	if ($qryseq[$idx] eq $hitseq[$idx])
	{
	    $newqry .= $qryseq[$idx];
	    $newhit .= $hitseq[$idx];
	}
	else
	{
	    $newqry .= "<span class='miscolor'>$qryseq[$idx]</span>";
	    $newhit .= "<span class='miscolor'>$hitseq[$idx]</span>";
	}
	
    }

    return($newqry,$newhit);
    
}
#
# make the column lines for hseq hsseq midlines or anything else 
#
sub make_column_lines
{
    my %sarg  = @_;

    if (!defined($sarg{startat}))
	{
	    $sarg{startat}=1;
	}

    my $zerosuppress=$sarg{startat};
    my $baseline="|";
    my @lines;
    
    for (my $col=1;$col<=$sarg{rowlength};$col++)
    {
	if ($col>1 && $col<$sarg{rowlength})
	{
	    if ( ($col/5) != int($col/5))
	    {
		$baseline .= ".";
	    }
	    else
	    {
		$baseline .= "|";
	    }
	}

	my $nbr    =  sprintf("%03d",$sarg{startat});

	for (my $line=length($nbr);$line>0;$line--)
	{
	    $nbr  =~ s/(\d{1})/$2/;
	    $lines[$line][$col]=$1;
	}

	$sarg{startat}++;
    }
    
       $baseline.="|";

    my $poslines;

    for (my $idx=$#lines;$idx>0;$idx--)
    {
	for (my $lx=1;$lx<=$sarg{rowlength};$lx++)
	{
	    if ($idx==1)
	    {
		next;
	    }
	    elsif ($lines[$idx][$lx] > 0)
	    {
		last;
	    }
	    else
	    {
		if ($zerosuppress<100) { $lines[$idx][$lx] = " "; }  # remove 0's if on first line of column numbers only
	    }
	}
	
	for (my $lx=1;$lx<=$sarg{rowlength};$lx++)
	{
	    if ($lx>1 && $lx<$sarg{rowlength})
	    {
		if ( ($lx/5) != int($lx/5))
		{
		    $lines[$idx][$lx]=" ";
		}
	    }

	   $poslines .= $lines[$idx][$lx];
	}

	$poslines .= "\n";
    }

    $poslines .= $baseline."\n";
    return($poslines);
}


#
# format sequence for specific width / end of line format for sequence
# This will line break a sequence that has HTML tags in it ( like <font> )
#
# my $newseq=seq_line_break_with_htmltags(seq=>"atgatagatatgata",width=>60);
#
sub seq_line_break_with_htmltags
  {
    my  %sarg = @_;  
    my  $scrtext;
    my  $ii=0;
    my  $colcnt=0;
    while ($ii<=length($sarg{seq}))
      {
        if (substr($sarg{seq},$ii,1) eq '<')
          {
            while (substr($sarg{seq},$ii,1) ne ">")
              {
                $scrtext.=substr($sarg{seq},$ii,1);
                $ii++;
              }
            $colcnt--;
#           $scrtext.=substr($sarg{seq},$ii,1);
          }
        else
          {
            $colcnt++;
            if ($colcnt>$sarg{width})  { $scrtext.="\n"; $colcnt=1; }
            $scrtext.=substr($sarg{seq},$ii,1);
            $ii++;
          }
      }
    return($scrtext);
  }
#
#
# get a tag value ( there can only be one occurence of a tag for this routine
#
sub get_xml_tag
{
    my %sarg     = @_;
    my $tagvalue;

    if ($sarg{xml} =~ m/<$sarg{tag}>(.*?)<\/$sarg{tag}>/i)
    {
	$tagvalue=$1;
    }
    else
    {
	$tagvalue="could not find xml value for:$sarg{tag}";
    }

    return($tagvalue);
}


#
# give it a tag name and xml and it returns all the tag values in an array
#
sub get_all_xml_tag_values
{
    my %sarg     = @_;
    my @tagvalues;
    $sarg{xml} =~ s/<$sarg{tag}>(.*?)<\/$sarg{tag}>/push @tagvalues,$1/esg;
    return(@tagvalues);
}

#
# dump hashes to log or stdout
# supply hash,logfile,name
#
# example: dump_hash(\%hash,"$log_file_name","Environment Variables");
#
sub dump_hash
{
    my %sarg          = %{$_[0]};
       $sarg{logfile} = $_[1];
       $sarg{name}    = $_[2];
    
    if ($sarg{logfile} eq "nofile")
    {
	print "\n.HASH DUMP FOR $sarg{name}\n-----------------------------------------------\n";
	foreach my $key ( keys % sarg )
	{
	    printf ("%25s = %s\n",$key,$sarg{$key}); 
	}	
    }
    else
    {
	if (-e "$sarg{logfile}")
	{
	    open(LOG,">>", $sarg{logfile}) || die "log file open $sarg{logfile} $!";
	}
	else
	{
	    open(LOG,">" , $sarg{logfile}) || die "log file open $sarg{logfile} $!";
	}
    
	print LOG "\n.HASH DUMP FOR $sarg{name}\n-----------------------------------------------\n";
	foreach my $key ( keys % sarg )
	{
	    printf LOG ("%25s = %s\n",$key,$sarg{$key}); 
	}
    }

close(LOG);
}


1;
