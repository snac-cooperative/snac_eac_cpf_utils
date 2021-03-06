#!/usr/bin/perl

# Author: Tom Laudeman
# The Institute for Advanced Technology in the Humanities

# Copyright 2014 University of Virginia. Licensed under the Educational Community License, Version 2.0
# (the "License"); you may not use this file except in compliance with the License. You may obtain a
# copy of the License at

# http://www.osedu.org/licenses/ECL-2.0
# http://opensource.org/licenses/ECL-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing permissions and limitations under the
# License.

# find_empty_elements.pl dir=nysa_cpf > nysa_empty.log 2>&1 &

# todo: if redirected, consider capturing the final redirect URL

# Find empty elements in all the XML files in a directory tree. This is a QA tool to get a quick survey of
# elements that are empty, but maybe shouldn't be empty.

# Check for missing /eac-cpf/cpfDescription/relations/resourceRelation

# If resourceRelation/@xlink:href then check the URL with wget. Run from a special, empty subdir because
# sometimes wget downloads a real file. (Maybe after redirecting.)

# > ./find_empty_elements.pl > empty.log
# grep empty: empty.log| sort -u | less
# > grep empty: empty.log| sort -u       
# empty: <abstract />
# empty: <description> </description>
# empty: <empty />
# empty: <eventDescription />
# empty: <fromDate />
# empty: <origination />
# empty: <relations />
# empty: <toDate />

# # Look for <description> </description> in empty.log

# less qa_cpf/Names0/047-001771080.xml
# grep 047-001771080 ./british_library/file_target.xml
# less ./british_library/Names0/047-001771080.xml
# less empty.log
# xlf ./british_library/Names0/047-001771080.xml
# xlf qa_cpf/Names4/047-002259994.xml

use strict;
use session_lib qw(:all);
use XML::XPath;
use CGI; # Handles command line name=value pairs.
use Time::HiRes qw(usleep nanosleep);

my $delay_microsecs = 2000000; # 100000 is 1/10 second, 250000 is 1/4 second

# %re_hash serves two purposes. First, it has the regex that matches error pages for a given repo. Second, it is
# used to determine which repos have to do a regex text vs just looking at the https header from wget
# --spider.

# WorldCat note: the normal regex will not work because the initial file "exists" even
# for a missing URL. We must have for a Location: redirect in the http header for the
# file to be ok.

# Use (?:pattern) for clustering alternatives because it is non-capturing and therefore
# faster.

# Some repositories don't have consistent URLs, or have a mixture, and some have errors in the host name. As a
# result of all that, we need a list of host names that identify a given repository. Since there is no
# "correct" text to test against leaving us to check bad text, we must be certain that we're looking for the
# bad text in a host name that will return the expected. In other words, we won't find the bad text at the
# wrong host name, and having not found the bad text we would (incorrectly) return ok.

# 'rave.ohiolink.edu' => 'ohlink',
# 'archives.library.illinois.edu', => 'uil',
# 'www.amphilsoc.org' => 'aps',
# 'amphilsoc.org' => 'aps',
# 'hdl.loc.gov' => 'lc',
# 'archives.nypl.org' => 'nypl',
# 'www.lib.ncsu.edu' => 'ncsu',
# 'lib.ncsu.edu' => 'ncsu',

# Except for worldcat, these were generated by running a keyboard macro on the output of:
# find url_xml/ -type f -exec head -n 3 {} \; | grep "<file" > tmp.txt

# Manually delete nwda_missing. Or try this:
# find url_xml/ -type f -exec head -n 3 {} \; | grep "<file"  | grep -v nwda_missing > tmp.txt

# hostname alone is not enough. Both yale and uks are using hdl.handle.net. uks is hdl.handle.net/10407 and
# yale is hdl.handle.net/10079. There may be other duplicate hosts as well.

my %repo_id = ('www.worldcat.org' => 'worldcat',
               'ead.lib.virginia.edu' => 'vah',
               'www.lib.utexas.edu' => 'taro',
               'oasis.lib.harvard.edu' => 'harvard', 
               'iarchives.nysed.gov' => 'nysa', 
               'hdl.handle.net' => 'yale', 
               'archives.nypl.org' => 'nypl', 
               'www.aaa.si.edu' => 'aar',
               'ead.lib.virginia.edu' => 'vah', 
               'hdl.handle.net' => 'uks', 
               'findingaids.library.northwestern.edu' => 'nwu', 
               'archivespec.unl.edu' => 'unl',
               'hdl.loc.gov' => 'lc', 
               'www.mnhs.org' => 'mhs', 
               'digital.lib.umd.edu' => 'umd', 
               'rmoa.unm.edu' => 'rmoa', 
               'library.duke.edu' => 'duke', 
               'rmc.library.cornell.edu' => 'crnlu', 
               'quod.lib.umich.edu' => 'umi', 
               'www.lib.ncsu.edu' => 'ncsu', 
               'uda-db.orbiscascade.org' => 'utsu', 
               'digitool.fcla.edu' => 'afl', 
               'findingaids.cjh.org' => 'cjh', 
               'oculus.nlm.nih.gov' => 'nlm', 
               'special.lib.umn.edu' => 'umn', 
               'library.syr.edu' => 'syru', 
               'webapp1.dlib.indiana.edu' => 'inu',
               'lib.udel.edu' => 'ude', 
               'archivesetmanuscrits.bnf.fr' => 'bnf', 
               'asteria.fivecolleges.edu' => 'fivecol', 
               'acumen.lib.ua.edu' => 'ual', 
               'libraries.mit.edu' => 'mit', 
               'doddcenter.uconn.edu' => 'uct', 
               'arks.princeton.edu' => 'pu', 
               'www.lib.uchicago.edu' => 'uchic',
               'dlib.nyu.edu' => 'html', 
               'dla.library.upenn.edu' => 'pacscl', 
               'nmai.si.edu' => 'nmaia', 
               'nwda.orbiscascade.org' => 'nwda', 
               'ccfr.bnf.fr' => 'ccfr', 
               'rave.ohiolink.edu' => 'ohlink', 
               'www.azarchivesonline.org' => 'aao', 
               'archives.library.illinois.edu' => 'uil', 
               'www.library.ufl.edu' => 'afl-ufl', 
               'nwda.orbiscascade.org' => 'uut', 
               'findingaids.cul.columbia.edu' => 'colu', 
               'archiveshub.ac.uk' => 'ahub', 
               'findingaid.lib.byu.edu' => 'byu', 
               'www.oac.cdlib.org' => 'oac', 
               'archives.utah.gov' => 'utsa', 
               'library.brown.edu' => 'riamco', 
               'www2.scc.rutgers.edu' => 'rutu');

# regex hash
# Yale and UKS use handle.net which properly returns a 404.

# NYPL now returns 200 on good requests, and 302 on bad requests. See multi_ok(). There is improved behavior
# for sites that don't use a regex to determine success.  Old NYPL: 'nypl' => '<title>.*?servlet
# error.*?<\/title>',

my %re_hash = (
               'aps' => '<title>.*?Invalid Document.*?<\/title>',
               'lc' => '<title>.*?Handle Problem Report.*?<\/title>',
               'ncsu' => '<div.*?>Collection not found\.</div>', # <div class="alert-box alert">Collection not found.</div>
               'ohlink' => '<title>dynaXML Error: Servlet Error</title>',
               'uil', => 'Could not load Collection',
               'worldcat' => '^Location:',
               'rmoa' => '<description>The document does not exist.<\/description>',
               'aar' => 'Location: /collections//more',
               'aao' => '<title>dynaXML Error: Servlet Error</title>',
               'afl' => '<title>DigiTool Stream Gateway Error</title>',
               'afl-ufl' => '<title>Page Not Found</title>',
               'fivecol' => 'Length: 0 \[text\/html\]',
               'mhs' => '404 Not Found',
               'inu' => '<title>dynaXML Error: Invalid Document</title>',
               'nlm' => '404 Not Found',
               'nmaia' => '<title>Page not Found',
               'nysa' => '<title>dynaXML Error: Servlet Error</title>',
               'crnlu' => 'Location: http://rmc.library.cornell.edu/404.html',
               'crnlu_missing' => 'Location: http://rmc.library.cornell.edu/404.html',
               'pu' => '404 Not Found',
               'pacscl' => '<title>,\s+</title>',
               'uchic' => 'No document with the given EADID.', # '<title></title>'
               'riamco' => 'Length: 2328 \(2.3K\) \[text\/html\]',
               'uks' => 'HTTP request sent, awaiting response... 404 Not Found',
               'umd' => 'Length: 0 \[text\/html\]',
               'utsu' => 'HTTP request sent, awaiting response... 404 Not Found',
               'uut' => 'HTTP request sent, awaiting response... 404 Not Found',
               'uct' => 'HTTP request sent, awaiting response... 404 Not Found',
               'cjh' => 'Undefined variable',
               'colu' => '\-\->\s+<table',
               'ude' => 'Location: http://www.lib.udel.edu \[following\]'
               );

# For any given run it is fairly easy to forget to add an exception to %re_hash, therefore we need to munge
# the first URL and confirm that the munged version fails to resolve. This is the global flag for that once-per-run test.

my $missing_confirmed = 0;
my $check_missing = 1;
my $use_cookie = 0;

main();
exit();

my $usage = "Usage $0 dir=somedirectory {url|empty}\nWhere somedirectory is repo_whatever.\n";

sub main
{
    my $do_empty = 0;
    my $do_url = 0;

    $| = 1; # unbuffer stdout.    
    
    # Cache each URL that we have already checked. No reason to re-check them.
    my %check_url;

    # Cache each file name with a missing host
    my %missing_host;

    # Yes, I know we are a commandline app, but Perl's CGI allows us
    # to use named args which is kind of nice, and as simple as it gets.

    my $qq = new CGI; 
    my %ch = $qq->Vars();

    if (! exists($ch{dir}))
    {
        die "No directory specified.\n$usage\n";
    }

    if (! -e $ch{dir} || ! -d $ch{dir})
    {
        die "Specified does not exist or is not a directory.\n$usage\n";
    }

    # Nov 19 2014 Slightly exciting (?:) non capturing expression in order to the * zero or more occurances of _missing so
    # that foo and foo_missing are both repositories.

    # Mar 30 2015 Do not make trailing / required on $ch{dir}. The convention is to not have a trailing slash.

    my $repo;
    if ($ch{dir} =~ m/^(.*?(?:_missing)*)_/)
    {
        $repo = $1;
        print "Repository: $repo\n";
    }
    elsif ($ch{dir} =~ m/^\/data\/extract\/(.*?)\/*/)
    {
        $repo = $1;
        print "Repository: $repo\n";
    }
    else
    {
        die "Can't determine repository name from dir: $ch{dir}\n$usage\n";
    }

    if (exists($ch{use_cookie}))
    {
        $use_cookie = 1;
        print "Using cookie\n";
        # Always write the fe_cookies.txt file so we know it exists in the local directory. wget needs this.
        open(my $out, ">", "fe_cookies.txt");
        print $out "www.worldcat.org	FALSE	/	FALSE	0	owcLocRedirectPersistent	_nr.selected\n";
        close($out);
    }
    else
    {
        print "Not using cookie\n";
    }

    if (exists($ch{empty}))
    {
        $do_empty = 1;
        print "Checking empty\n";
    }
    else
    {
        print "Not checking empty\n";
    }

    if (exists($ch{url}))
    {
        print "Checking url\n";
        $do_url = 1;
        printf("Delay between URL fetch: %d microseconds (%f seconds)\n", $delay_microsecs, ($delay_microsecs / 1000000));
    }
    else
    {
        print "Not checking url\n";
    }

    if (! $do_empty && ! $do_url)
    {
        die "No check specified. Must check empty or url\n$usage\n"
    }

    # Some of the URLs required special algos to create the 'bad' URL. We don't care enough to waste time on
    # that, so when we have crafted a regex to check for bad URLs, we might not want to bother with the
    # test. Partly because we did the test manually. Of course, this is disabling QA, but we've wasted too
    # much time on these bad URLs already. An example URL where we would have to munge the pid param would be
    # http://example.com/foo?pid=11150&custom_att_2=direct I'm sure we could write a custom URL munger, but we
    # are not going down that rabbit hole.

    if (exists($ch{noc}))
    {
        $check_missing = 0;
        $missing_confirmed = 1;
        print "Disabled testing missing URLs\n";
    }

    # The linux find command will not work on a symlinked dir that doesn't have a trailing / so check and add one.

    if ($ch{dir} !~ m/\/$/)
    {
        $ch{dir} = "$ch{dir}/";
    }

    print "Scanning: $ch{dir}\n";

    $XML::XPath::Namespaces = 0;
    my @files = `find $ch{dir} -type f`;
    chomp(@files);
    print "Find done. File count: ". scalar(@files) . "\n";
    my $xx = 0;

    my $first_host = "";
    foreach my $file (@files)
    {
        print "file: $file\n";
        my $xpath = XML::XPath->new(filename => $file);

        # Checking CPF for missing resourceRelation is not redundant because <relations> won't be empty if
        # there is a <cpfRelation> which is the case with .c and .r files. When both <cpfRelation> and
        # <resourceRelation> are empty, we will have an empty <relations> below.

        my $rrel = $xpath->find('/eac-cpf/cpfDescription/relations/resourceRelation');
        if ($do_url)
        {
            if (! $rrel)
            {
                print "missing rrel:\n";
            } else
            {
                # Apparently something about using the xpath function causes the &amp; entity to be translated
                # to a ascii & (decimal 38, \046). If the entity was not translated, the wget call would fail.

                my $url = $xpath->find('/eac-cpf/cpfDescription/relations/resourceRelation/@xlink:href');
                if ($url && $do_url)
                {
                    # Find the repository identity, and deal with changing and unknown host names. Anything
                    # unexpected is an error. All the expected values should be in %repo_id, and %re_hash.
                    my $host = "";
                    if ($url =~ m/https*:\/\/(.*?)\//)
                    {
                        $host = $1;
                    }
                    if (! $first_host)
                    {
                        print "Host name: $host\n";
                        $first_host = $host;
                    }
                    elsif ($first_host ne $host)
                    {
                        my $basef = '';
                        if ($file =~ m/$repo\_cpf_final\/(.+)\.[cr]\d+\.xml/)
                        {
                            $basef = $1;
                            if (exists($missing_host{$basef}))
                            {
                                print "error: (probably missing-dup:) bad host: $host\n";
                            }
                            else
                            {
                                print "error: (probably missing:) bad host: $host\n";
                                $missing_host{$basef} = 1;
                            }
                        }
                        else
                        {
                            print "error: (probably missing:) bad host: $host\n";
                        }
                        next();
                    }
                    if (exists($check_url{$url}) and $host)
                    {
                        # If we already checked the URL, just print the result, marked with dup: for easy grep'ing.
                        print "dup: $check_url{$url} $url\n";
                    } else
                    {
                        # Sleep 100 (or 250) milliseconds in an attempt to be nice to their web server.
                        usleep($delay_microsecs);

                        my $url_ok = 0;
                        if (! $missing_confirmed && $check_missing)
                        {
                            # Use digits to munge the URL. At least one server script likes digits in the id
                            # CGI param and treats non-digits specially. We just want to make a non-resolving
                            # URL, or bad CGI parameter. ("Bad" being broadly defined.) Prior to this test,
                            # confirming that the code would properly classify missing URLs was a time
                            # consuming process.

                            # Nov 5 2014 Some servers that use a url with file.xml will server the correct
                            # page if you send a url file.xml1234, so to test the bad url we have to create file1234.xml.
                            # This is bad: http://www.aaa.si.edu/collections/findingaids/bishisab1234.xml

                            my $new_url = "";
                            if ($url =~ m/\.[A-Za-z]+$/)
                            {
                                $new_url = $url;
                                $new_url =~ s/(\.[A-Za-z]+)$/1234$1/;
                            }
                            elsif ($url =~ m/(?:\?eadid=)|(?:\?source=)/)
                            {
                                # riamco has params ?eadid, umd has params ?source
                                $new_url = $url;
                                $new_url =~ s/((?:\?eadid=)|(?:\?source=))/$1x1234/;
                            }
                            else
                            {
                                $new_url = $url . '1234';
                            }

                            my $check_url_ok = url_check($repo, $new_url);
                            if ($check_url_ok)
                            {
                                die "Error: Bad URL returns ok: $new_url\nOriginal URL: $url\n";
                            }
                            else
                            {
                                print("Missing test confirmed (tested: $new_url)\n");
                                $missing_confirmed = 1;
                            }
                        }
                        $url_ok = url_check($repo, $url);
                        
                        if ($url_ok)
                        {
                            # We have a hit. The "ok" value in the check_url hash must be unique for grep'ing
                            # the results. Dups have the text "ok-prev:" and are detected way back at the top
                            # of the URL checking code, so they'll never reach this point.
                            print "ok: $url\n";
                            $check_url{$url} = "ok-prev:";
                        }
                        else
                        {
                            # The "missing" value in the check_url hash must be unique for grep'ing the results.
                            print "missing: $url\n";
                            $check_url{$url} = "missing-prev:";
                        }
                    }
                }
            }
        }

        if ($do_empty)
        {
            # Sep 23 2014 Add test for not ancestor::objectXMLWrap since we only care about empty elements in
            # the CPF itself.

            # xpath cpf_qa/howard/Coll._113-ead.c01.xml '//*[not(ancestor::objectXMLWrap)]/attribute::*[.=""]' 2> /dev/null | less
            # xpath cpf_qa/howard/Coll._113-ead.c01.xml '//*[@*="" and not(ancestor::objectXMLWrap)]' 2> /dev/null | less
            # xpath cpf_qa/howard/Coll._113-ead.c01.xml 'local-name(//*[@*="" and not(ancestor::objectXMLWrap)])' 2> /dev/null | less

            # my $empty_nodes = $xpath->find('//*[((not(*) and not(normalize-space())) or not(@*)) and not(ancestor::objectXMLWrap)]');
            my $empty_nodes = $xpath->find('//*[(not(normalize-space()) or @*="") and not(ancestor::objectXMLWrap)]');
            if ($empty_nodes)
            {
                foreach my $node ($empty_nodes->get_nodelist())
                {
                    # my $val = $node->toString();
                    my $val = $node->getName();
                    print "empty: $val";
                    my $empty_attr = $xpath->find('attribute::*[.=""]', $node);
                    if ($empty_attr)
                    {
                        foreach my $node ($empty_attr->get_nodelist())
                        {
                            my $val = $node->getName();
                            print " attr: $val";
                        }
                    }
                    print "\n";
                }
            }
        }
        $xx++;
    }
}

sub url_check
{
    my $host = $_[0];
    my $url = $_[1];

    # Rather than returning a 404, most sites returns a 200 http header for missing
    # pages. In other words, even a bad URL returns a 200 web page. Instead of using the
    # http header result, we have to actually retrieve the entire web page and check it
    # with a regex.

    # Good URL examples:
    # http://iarchives.nysed.gov/xtf/view?docId=14610-88F.xml
    # http://www.amphilsoc.org/mole/view?docId=ead/Mss.B.W76a-ead.xml
    # http://archives.library.illinois.edu/archon/?p=collections/controlcard&id=995

    my $cookie_suffix = "";
    if ($use_cookie)
    {
        my $cookie_suffix = " --load-cookies fe_cookies.txt";
    }
    my $cmd = "wget -O - \"$url\" $cookie_suffix";
    if ($host eq 'www.worldcat.org' || ! exists($re_hash{$host}))
    {
        # Why did url checking on pu create files? Must use -O - even with --spider because some combination
        # of server responses causes wget to save the file after all. --delete-after without the -O - works
        # too. It could be the 302 followed by a 500 followed by a 200. Note the "(try: 2)"

        # wget --delete-after --spider "http://arks.princeton.edu/ark:/88435/0k225b05z" 2>&1
        # wget --spider -O - "http://arks.princeton.edu/ark:/88435/0k225b05z" 2>&1 | less

        # Remember, every command has 2>&1 when executed below. Don't add it twice.

        $cmd = "wget --spider -O - \"$url\" $cookie_suffix"
    }

    my $res = `$cmd 2>&1`;

    my $url_ok = 0;
    if (multi_ok('host' => $host, 'text' => "$res"))
    {
        $url_ok = 1;
    }
    return $url_ok;
}

sub multi_ok
{
    my %args = @_;
    my $host = $args{host};
    my $text = $args{text};

    # Add new repo/regex pairs to this hash.

    # Worldcat at least uses ^ for start of line in the regex, and to support that we need /sm switches. It
    # should be fine for all the others which are mid-line matches.

    # The two cases here with inverse logic is somewhat disturbing. 
    
    # print "host: $host test: " . substr($text, 0, 40) . "...\n";

    # If we have a test regex, then don't worry about doing the normal http 200 test. It will always be true.

    if (! exists($re_hash{$host}))
    {
        # print "No regex: $host\n";

        # Nov 1 2014. Which server returned "Remote file exists" but not with a 200 http response? That seems odd/wrong
        # becase "Remote file exists" is also returned for 302 and other redirects.
        
        # if (($text =~ m/^(?:Remote file exists)|(?:awaiting response\.\.\. 200 OK$)/sm))

        # Lacking the previous examples, what seems to make sense is to only accept a 200 response as good,
        # and anything else is bad. I seem to recollect that WorldCat returns a redirect, but the new logic
        # here is that WorldCat will test the response with a regex, and look for "Location:". Having a regex,
        # WorldCat won't come into this code branch.

        my $ret_val = 0;
        while ($text =~ m/^HTTP request sent, awaiting response\.\.\. (\d+) ([A-Za-z ]+)$/smg)
        {
            if ($1 eq 200)
            {
                # If this is the only http response code, then the request was successful, and we keep looking
                # for response codes.
                $ret_val = 1;
            }
            if ($1 ne 200)
            {
                # However, any other response code means there was something fishy, at least for the non-regex
                # hosts. Yes, I know we're returning from inside a loop.
                # Well behaved servers will return 404, although in at least one case only after trying a redirect.
                # It seems like a good idea to return a zero (url not ok) if any http response is a 404.
                return 0;
            }
        }
        return $ret_val;
    }        
    elsif (exists($re_hash{$host}))
    {
        # print "matching host: $host matching: $re_hash{$host}\n";
        # print "\n$text\n";
        if ($text =~ m/$re_hash{$host}/sm)
        {
            return 0;
        }
        # This is dangerous. Basically, we assume that since didn't find the error text, the URL must be
        # ok. That assumption is weak. Much better would be to search for text that only occurs in the good
        # URLs. We try to make up for this by having an explicit list of host names that will behave as
        # expected.

        return 1;
    }
    else
    {
        die "Error: No matching regex for: $host\n";
    }
    return 0;
}
