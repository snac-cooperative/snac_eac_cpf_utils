#!/usr/bin/perl

# Author: Tom Laudeman
# The Institute for Advanced Technology in the Humanities

# Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
# License at

# http://www.osedu.org/licenses/ECL-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and limitations under the License.

# See readme.md

# ./exec_record.pl config=agency.cfg &
# cat agency_code.log | perl -ne 'if ($_ =~ m/040\$a: (.*)/) { print "$1\n";} ' | sort -fu > agency_unique.txt

# worldcat_code.pl also create a directory of cached results ./wc_data/ and reads agency_unique.txt and
# writes worldcat_code.xml. If the file agency_unique.txt exists, you simply run worldcat_code.pl.

# Reminder: scripts must be executable, so if you haven't already done it: chmod +x worldcat_code.pl

# ./worldcat_code.pl > tmp.log

use strict;
use URI::Escape; 
use Time::HiRes qw(usleep nanosleep);
use session_lib qw(read_file);

my $ac_file = "agency_unique.txt";

# my $ac_file = "agency_test.txt";

my $data_dir = "wc_data";
my $output_file = "worldcat_code.xml";
my $ofs; # output file stream

main();
exit();

sub main
{
    $| = 1; # unbuffer stdout

    if (! -e $data_dir)
    {
        print "Created dir $data_dir.\n";
        mkdir $data_dir
    }
    print "Using cache dir $data_dir\n";

    open($ofs, ">", $output_file) || die "Cannot open $output_file for write.\n";
    print "Ouput file is $output_file\n";

    print $ofs '<?xml version="1.0" encoding="UTF-8"?>';
    print $ofs "\n<all xmlns=\"http://www.loc.gov/MARC21/slim\">\n";

    # Read in a line of input
    my $xx = 0;

    my $good_hit = 0;
    while (defined(my $marc_code = get_marc()))
    {
        # Get the first query back from worldcat. Sleep 250 milliseconds aka 1/4 second aka 250000
        # microseconds between queries in order to be polite to the server.

        my $first;
        my @rid_list;
        if ($marc_code)
        {
            $first = first_query($marc_code, 'local.marcOrgCode');
            @rid_list = get_rid($first);
            if (@rid_list == 0)
            {
                $first = first_query($marc_code, 'local.oclcSymbol');
                @rid_list = get_rid($first);
            }
            # if (@rid_list == 0)
            # {
            #     $first = first_query($marc_code, 'srw.serverChoice');
            #     @rid_list = get_rid($first);
            # }
        }
        else
        {
            next;
        }

        # If we have a resourceID then get a second query. Sleep 250 milliseconds aka 1/4 second between
        # queries to be polite to the server.

        # Code ALM does not return a record with an exact match for ALM. In fact, that exact match is the
        # third record, so we have to check all the returned records.

        # Cache second queries. These seem more likely to repeat than first queries since each first is based
        # on a unique marc code, and first returns multiple potiential hits.

        my $second = "";
        $good_hit = 0;
        if (@rid_list > 0)
        {
            if (@rid_list > 1)
            {
                print "multi mc: $marc_code\n";
            }
            foreach my $rid (@rid_list)
            {
                # print "trying: ($marc_code) $rid\n";
                my $data = "$data_dir/$rid.xml";
                if (-e $data)
                {
                    # print "Using cache for $data\n";
                    $second = read_file($data);
                    # Reading from disk, no need to sleep here.
                }
                else
                {
                    # print "Sending requst for $data\n";
                    $second = second_query($rid);
                    open(my $dfs, ">", $data) || die "Cannot open $data for write\n";
                    print $dfs $second;
                    close($dfs);
                }
                if (parse_second($marc_code, $second))
                {
                    # Note that we don't stop at the first good hit. Some codes
                    # such as "C" produce multiple answers. The code that
                    # consumes this data must choose the best, which is probably
                    # the shortest.
                    $good_hit = 1;
                }
            }
        }
        else
        {
            # print "no rid, skipped: $marc_code\n";
        }
        
        if (! $good_hit)
        {
            # If we didn't get a hit, for any reason, output an empty record.
            print $ofs "  <container>\n";
            print $ofs "    <marc_query>$marc_code</marc_query>\n";
            print $ofs "    <marc_code/>\n";
            print $ofs "    <name/>\n";
            print $ofs "    <isil/>\n";
            print $ofs "    <matching_element/>\n";
            print $ofs "  </container>\n";
        }

        $xx++;
        # if ($xx > 10)
        # {
        #     exit();
        # }
    }
    print $ofs "</all>\n";
    close($ofs);
}

# Just use a global for our single file handle.
my $fh; 
sub get_marc
{
    if (!$fh)
    {
        open($fh, "<", $ac_file) || die "Cannot open $ac_file for read.\n";
    }
    if (my $in = <$fh>)
    {
        chomp($in);
        return $in;
    }
    else
    {
        return undef;
    }
}


sub first_query
{
    my $marc_code = $_[0];
    my $qfield = $_[1];
    
    # worldcat.org might return a zillion records, but I think the default is
    # 10. In practice it seems to return no more than 10, and if there are more
    # than 10 records, we probably don't want to check each one for our hit.
    
    my $safe_code = $marc_code;
    $safe_code =~ s/[^A-Za-z0-9]/_/g; # All non-alphanum to underscore to be safe in a file name.

    my $data = "$data_dir/mc_$safe_code\_$qfield.html";
    my $first = '';
    if (-e $data)
    {
        # print "First uses $data\n";
        $first = read_file($data);
    }
    else
    {
        # local.marcOrgCode or local.oclcSymbol. We are not using
        # srw.serverChoice, although it produces a result.

        # query=local.marcOrgCode="Y%24E"+not+local.logicalDelete%3D%221%22

        # Perl string interpolation understands $uri_query. The char "&" is not
        # special for interpolation. Use single quote ' around the URL arg to
        # curl because double quote " interpolates in the shell, and the shell
        # gets upset about things like ( which are fine (apparently) in a URL.
        
        my $uri_query = "$qfield=\"" .  uri_escape($marc_code) . '"+not+local.logicalDelete="1"';
        
        my $cmd = "curl -s \'http://worldcat.org/webservices/registry/search/Institutions?query=$uri_query&operation=searchRetrieve&recordSchema=info:rfa/rfaRegistry/schemaInfos/adminData&recordPacking=xml\'";
        
        $first = `$cmd`;
        usleep(250000);
        open(my $dfs, ">", $data) || die "Cannot open $data for write\n";
        print $dfs $first;
        close($dfs);
   }
    # print "first: $first\n";
    return $first;
}

sub get_rid
{
    my $first = $_[0];

    # Initially I thought that the exact match was the first record, but I found cases where that is not
    # true. Use a /g regex so we check all the possible matches. I think later code checks for exact matches
    # as the "best" choice.

    # <adminData:resourceID>info:rfa/localhost/Institutions/50042</adminData:resourceID>

    my @inst_list;
    while($first =~ m/Institutions\/(\d+)<\/adminData/g)
    {
        push(@inst_list, $1);
    }
    return @inst_list;
}

sub second_query
{
    my $rid = $_[0];

    my $second = "";
    if ($rid)
    {
        $second = `curl -s "http://worldcat.org/webservices/registry/enhancedContent/Institutions/$rid"`;
        usleep(250000);
    }
    return $second;
} 

        
sub parse_second
{
    my $marc_query = $_[0];
    my $second = $_[1];

    # <institutionName>Huntington Library, Art Collections &amp; Botanical Gardens</institutionName>

    # <identifiers xmlns="info:rfa/rfaRegistry/xmlSchemas/institutions/identifiers" 
    #     xsi:schemaLocation="info:rfa/rfaRegistry/xmlSchemas/institutions/identifiers http://worldcat.org/registry/xsd/collections/Institutions/identifiers.xsd">
    #     <lastUpdated>2012-02-16</lastUpdated>
    #     <ISIL>Oclc-HUV</ISIL>
    #     <OCLCInstitutionNumber>8385</OCLCInstitutionNumber>
    #     <oclcSymbol>HUV</oclcSymbol>
    #     <oclcAccountName>HUNTINGTON LIBR ART GALLERY &amp; GARDENS</oclcAccountName>
    #     <oclcAccountName>HUNTINGTON LIBR ART &amp; BOTANICAL GARDEN</oclcAccountName>
    #     <marcOrgCode>CSmH</marcOrgCode>
    # </identifiers>

    my %res;
    my $exact = 0;

    # <oclcSymbol status="inactive">AEM</oclcSymbol>

    # Look for an exact match as any element value, case insensitive. In addition to the example above, a
    # match could (theoretically) be <cobissLettersCode>BMSNS</cobissLettersCode> although that seems to
    # stretch credibility. One record I checked seemed rational in that 040$a BMSNS was with a record that
    # could be Serbian, and 040$b is srp.

    if ($second =~ m/(<marcOrgCode>\Q$marc_query\E<\/marcOrgCode>)/i ||
        $second =~ m/(<oclcSymbol.*?>\Q$marc_query\E<\/oclcSymbol>)/i)
    {
        $exact = 1;
        my $matching_element = $1;
        if ($second =~ m/<institutionName>(.+?)<\/institutionName>/i)
        {
            # <institutionName> with no attributes only occurs once per file.
            $res{iname} = $1;
        }
        else
        {
            $res{iname} = "";
        }

        if ($second =~ m/<ISIL>(.*?\Q$marc_query\E.*?)<\/ISIL>/i ||
            $second =~ m/<ISIL>(.+?)<\/ISIL>/i)
        {
            # May have more than one isil, so get the one that matches the marc
            # query. Else try to find any isil since they often do not contain
            # a string that matches the original query.

            # <ISIL>OCLC-AEM</ISIL>
            # <ISIL>OCLC-AFM</ISIL>
            $res{isil} = $1;
        }
        else
        {
            $res{isil} = '';
        }

        if ($second =~ m/<marcOrgCode>(.+?)<\/marcOrgCode>/i)
        {
            $res{marc} = $1;
        }
        else
        {
            $res{marc} = "";
        }
        print $ofs "  <container>\n";
        print $ofs "    <marc_query>$marc_query</marc_query>\n";
        print $ofs "    <marc_code>$res{marc}</marc_code>\n";
        print $ofs "    <name>$res{iname}</name>\n";
        print $ofs "    <isil>$res{isil}</isil>\n";
        print $ofs "    <matching_element>$matching_element</matching_element>\n";
        print $ofs "  </container>\n";
    }
    return $exact;
}
