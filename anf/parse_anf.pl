#!/usr/bin/perl

# Run this script first.

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

# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template.pm
# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template/Tutorial/Datafile.pod

use strict;
use Storable;
use session_lib qw(:all);
use XML::LibXML;
use Template;
use DateTime;
use Data::Dumper;
require 'anf.pm';

use av; # attribute value controlled vocabulary, directly from av.xsl
my %av = %av::av;

# support utf8 strings
use utf8;

# Added apr 28 2015 due to Wide character in print at ./parse_whitman.pl line 54.  Seems to have fixed the
# problem. Note that when using libxml to serialize XML which is already utf8, this would double encode the
# output.

# apr 30 2015. When using normal stdout and normal strings (even strings from libxml), the output is identical
# regardless of stdout being utf8 or not. So, it might as well stay commented out.
# use open qw(:std :utf8);

my $dbh; # simplest to just make the database handle global
my $db_name = "catalog.db"; # global db name so we can have sql logging, if we want it.
$| = 1; # unbuffer stdout


main();
exit();

sub main
{
    # $dbh = sqlite_db_handle($db_name);

    my $parser = XML::LibXML->new();
    my $xpc = XML::LibXML::XPathContext->new(); # No argument here!
    reg_namespaces($xpc);

    my @files = `find working_files/ -type f`;
    chomp(@files);
    my $xx = 0;

    my %flookup;
    foreach my $file (@files)
    {
        print "Adding " . basename($file) . "\n";
        $flookup{basename($file)} = 1;
    }

    my %data; # put all the cpf relevant data into this hash, and later write to the db, or save to disk.
    my %fileinfo; # hash of all info about all files, necessary to fill in gaps for some ark id values

    foreach my $file (@files)
    {
        my $doc = $parser->parse_file($file);

        # <cpfRelation xmlns:xlink="http://www.w3.org/1999/xlink"
        #              cpfRelationType="associative"
        #              xlink:href="FRAN_NP_010938"
        #              xlink:type="simple">
        #    <relationEntry>Pinel, Jean-Jacques</relationEntry>
        #    <dateRange>
        #       <fromDate standardDate="1998-09-02">2 septembre 1998</fromDate>
        #    </dateRange>
        # </cpfRelation>

        # We need the orig entityType because we have unknown cpfRelations can sometimes be determined based
        # on the original entityType and the cpfRelationType. This includes: hierarchical-child,
        # hierarchical-parent, temporal-later, temporal-earlier.

        my %relh;
        $relh{entityType}
        = trim(
               $xpc->findvalue(
                               '/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:entityType',
                               $doc));

        $relh{file} = basename($file);

        # existDates could have a single date, which uses a different xpath. 
        $relh{fromDate}
        = trim(
               $xpc->findvalue(
                               '/eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates/eac:dateRange/eac:fromDate/@standardDate',
                               $doc));
        $relh{toDate}
        = trim(
               $xpc->findvalue(
                               '/eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates/eac:dateRange/eac:toDate/@standardDate',
                               $doc));
        $relh{part}
        = trim(
               $xpc->findvalue(
                               '/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:nameEntry[1]/eac:part',
                               $doc));

        if (! exists($fileinfo{$relh{file}}))
        {
            my %fi_copy = %relh;
            $fileinfo{$relh{file}} = \%fi_copy;
        }
        
        my $href = '';
        foreach my $node ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:cpfRelation', $doc))
        {
            $relh{cpfRelationType} = $node->findvalue('@cpfRelationType');

            my %fch;
            $fch{relationEntry} = $xpc->findvalue('eac:relationEntry', $node);
            $fch{fromDate} = $xpc->findvalue('eac:dateRange/eac:fromDate/@standardDate', $node);
            $fch{toDate} = $xpc->findvalue('eac:dateRange/eac:toDate/@standardDate', $node);
            $href = $node->findvalue('@xlink:href');
            $fch{xhref} = $href; # sort of a duplicate key, but probably simplifies access later.
            $fch{has_file} = 0;
            if (exists($flookup{$href}))
            {
                $fch{has_file} = 1;
            }
            $fch{using_algo_entityType} = 'yes'; # just a reminder to anyone looking at the log files
            $fch{entityType} = '';

            # normalize-space on everything.
            foreach my $key (keys(%fch))
            {
                # Don't trim list of hash. Intestingly, triming the list seemed to have done no harm.
                if ($key ne 'fc_identity')
                {
                    $fch{$key} = trim($fch{$key});
                }
            }

            if (! exists($data{$href}))
            {
                # push(@{$fch{cpfRelationType}}, $node->findvalue('@cpfRelationType'));

                # Copy the hash so we have separate hash references for each iteration otherwise future
                # iterations overwrite previous iterations keys in the hash reference.
                my %hcopy = %relh;
                push(@{$fch{orig}}, \%hcopy);
                $data{$href} = \%fch;
            }
            else
            {
                # push(@{$fch{cpfRelationType}}, $node->findvalue('@cpfRelationType'));

                # Copy the hash so we have separate hash references for each iteration otherwise future
                # iterations overwrite previous iterations keys in the hash reference.
                my %hcopy = %relh;
                push(@{$data{$href}{orig}}, \%hcopy);
                print "Additional $href in file $file\n";
            }
            
            # print stuff out to a log file.
            # print "$href\n" . Dumper(\%{$data{$href}});
        }


        # # Also a trim on the names (and other values) in the fc_identity list of hashes.
        # foreach my $fci (@{$data{fc_identity}})
        # {
        #     foreach my $key (keys(%{$fci}))
        #     {
        #         $fci->{$key} = trim($fci->{$key});
        #     }
        # }

        # saving data does lots of things, but all SQL related

        # sql_save_data(\%data);

        $xx++;
    }

    print "Parsed $xx files\n";

    # To find the known corp type, we have to wait until all files have been examined. We set the known corp
    # types here is possible, and if not, we simply set the entityType to the best guess from
    # find_entity_type(); Both functions are in anf.pm.
    
    foreach my $fkey (keys(%data))
    {
        # $fkey is both the key and the href/ark. "href" being a link, not a hashref. Non-obvious key and
        # variable name.

        my $href = $fkey;
        my $is_known_type = known_entity_type($href, \%fileinfo);
        print "fi: $fkey is_known_type: $is_known_type\n";
        if ($is_known_type)
        {
            $data{$fkey}{entityType} = $is_known_type;
            $data{$fkey}{using_algo_entityType} = 'is_known_type';
        }
        else
        {
            # The first check for entityType failed, so check being a corporation via relation.
            foreach my $hr (@{$data{$fkey}{orig}})
            {
                if ($hr->{entityType} eq 'corporateBody' &&
                    is_corp_rel($hr->{cpfRelationType}))
                {
                    $is_known_type = 'corporateBody';
                    $data{$fkey}{entityType} = 'corporateBody';
                    $data{$fkey}{using_algo_entityType} = 'corp_by_relation';
                    last;
                }
            }
        }

        # If we still don't have a known type, then call find_entity_type();
        if( ! $is_known_type)
        {
            $data{$fkey}{entityType} = find_entity_type($href, $data{$fkey}{relationEntry});
        }
    }

    # Fix entries in %data, which has all the cpfRelation entites. Find entities for which there is an id
    # value in anf-20150617-entityTypesForSNAC.csv, and update the {entityType} and
    # {using_algo_entityType}. The hash %data is used by all downstream code to look up and create CPF files
    # and fix cpfRelation elements.

    my $extra_info_fn = "anf-20150617-entityTypesForSNAC.csv";
    my $extra;
    if (! open($extra, "<", $extra_info_fn))
    {
        print "Error: can't open $extra_info_fn for reading\n";
        exit(1);
    }
    my $discard_header = <$extra>;
    while(my $temp = <$extra>)
    {
        chomp($temp);
        $temp =~ s/\s+$//smg; # Remove any stuff like trailing ^M. Bummer that chomp() doesn't do this.
        my ($file_id, $en_type) = split("\t", $temp);
        if (exists($data{$file_id}))
        {
            my $tmp_en = $data{$file_id}->{entityType};
            $data{$file_id}->{entityType} = $en_type;
            $data{$file_id}->{using_algo_entityType} = 'anf-csv-file'; 
            if ($tmp_en ne $en_type)
            {
                print "setting: updated: $file_id name: $data{$file_id}->{relationEntry} entityType: old: $tmp_en (" . length($tmp_en) .")new: $en_type (" . length($tmp_en) . ")\n";
            }
            else
            {
                print "setting: unchanged: $file_id entityType: old: $tmp_en new: $en_type\n";
            }
        }
        else
        {
            print "warning: ndata: no key $file_id in hash \%data\n";
            # $data{$file_id}->{entityType} = $en_type;
            # $data{$file_id}->{using_algo_entityType} = 'anf-csv-file'; 
            # print "Adding: data added key: $file_id entityType: $en_type\n";
        }
    }

    my $out_file = 'frozen_data.dat';
    # my $frozen = freeze(\%data);
    # if (! open(OUT, ">", $out_file))
    # {
    #     print STDERR ("runt_compile.pl compile(): $@\ncan't open $out_file for output\n");
    #     exit(1);
    # }
    # print OUT $frozen;
    # close(OUT);
    # my %data_new = %{thaw(read_file($out_file))};

    store \%data, $out_file;
    print "Done storing\n";
    
    my $data_ref = retrieve($out_file);
    my %data_new = %{$data_ref};

    print "Done retrieving\n";

    $Data::Dumper::Terse = 1;
    {
        use open qw(:std :utf8);
        foreach my $key (keys(%data_new))
        {
            print "\nkey: $key\n";
            my $href = $data_new{$key};
            foreach my $hkey (keys(%{$href}))
            {
                if ($hkey eq 'orig')
                {
                    # do nothing now, but output {orig} later.
                }
                # elsif ($hkey eq 'cpfRelationType')
                # {
                #     print "  $hkey => " . join(', ', @{$href->{$hkey}}) . "\n";
                # }
                else
                {
                    print "  $hkey => $href->{$hkey}\n";
                }
            }
            # orig is a list of hash
            foreach my $hr (@{$href->{orig}})
            {
                foreach my $key (keys(%{$hr}))
                {
                    print "  orig $hr->{file} => $key => $hr->{$key}\n";
                }
            }
        }
        foreach my $key (keys(%fileinfo))
        {
            print "fileinfo: $key\n";
            
            foreach my $ikey (keys(%{$fileinfo{$key}}))
            {
                print "  $ikey => $fileinfo{$key}{$ikey}\n";
            }
        }
    }

    # my $single = $data_new{'FRAN_NP_050368'};
    # foreach my $key (keys(%{$single}))
    # {
    #     print "$key: $single->{$key}\n";
    # }
} # end main

# Get the unique id from a file name.
sub basename
{
    my $basename = $_[0];
    $basename =~ s/^.*\/(.*?)\.xml$/$1/;
    return $basename;

}

sub reg_namespaces
{
    my $xpc = $_[0];

    $xpc->registerNs('eac',
                     'urn:isbn:1-931666-33-4');

    $xpc->registerNs('xlink',
                     'http://www.w3.org/1999/xlink');

    $xpc->registerNs('xsi',
                     'http://www.w3.org/2001/XMLSchema-instance');

    $xpc->registerNs('wwa',
                     'http://www.whitmanarchive.org/namespace');
}


# Leave utf8 chars, but strip anything punctuation-like except space.
# perl -ne 'm/name_key = (.*)$/; print "$1";' unique_names.txt | grep -Po '[^a-zA-Z]' | sort -u 
# -
# ,
# ?
# .
# '
# [
# ]
# &
# ü

sub normal_for_match
{
    my $str = $_[0];
    $str = lc($str);
    $str =~ s/[\,\.\&\-\[\]\?\']/ /g;
    return trim($str);
}

# Leave utf8 chars, but strip anything punctuation-like except space.
# perl -ne 'm/name_key = (.*)$/; print "$1";' unique_names.txt | grep -Po '[^a-zA-Z]' | sort -u 
# -
# ,
# ?
# .
# '
# [
# ]
# &
# ü

sub trim
{
    $_[0] =~ s/^\s+//smg;
    $_[0] =~ s/\s+$//smg;
    $_[0] =~ s/\s+/ /smg;

    # Replace unicode hex 2014 em dash, and hex 2013 en dash with a hyphen.
    $_ =~ s/—|–/-/smg;

    return $_[0];
}

