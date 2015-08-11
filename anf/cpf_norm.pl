#!/usr/bin/perl

# Perform certain normalizations on existing CPF files from AnF.

# Start the local copy of Postgres before running this script.

# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data -l ~/pg9.4.1/logfile start
# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data stop

# The password is in ~/.dbpass
# ~/pg9.4.1/bin/psql anf

# sudo yum -y install perl-XML-LibXML

# One time initialialization of the SQL database, just a single CSV file that we could have read via Perl's Text::CSV. Oh well.

# COPY file_list FROM '/data/source/anfra/List-of-ANF-EAC-files-for-SNAC-project.csv' DELIMITER ',' CSV header

# Might need to use c-v c-i to get a literal \t in the delimiter string '\t' didn't work. Or E'\t'
# COPY file_list FROM '/data/source/anfra/List-of-ANF-EAC-files-for-SNAC-project.csv' DELIMITER '	' CSV header

# run parse_anf.pl before running cpf_norm.pl.

# ./cpf_norm.pl [--info|--noinfo] [--debug|--nodebug] > cpf_role.log 2>&1 &
# ./cpf_norm.pl --debug > cpf_role.log 2>&1 &

# Send all the logging to a single file. With this script, is it good for stdout and stderr to be in the same
# file.

# ./cpf_norm.pl > cpf_role.log 2>&1 &

# Historically derived from henry_dates.pl

# note 1

# parse_file() returns a XML::LibXML::Document object.

# http://search.cpan.org/~shlomif/XML-LibXML-2.0118/lib/XML/LibXML/Document.pod

# However, due to OOP obfuscating available (inherited) methods, the documentation for XML::LibXML::Document
# doesn't mention method findnodes(). That is because Document inherits all functions of XML::LibXML::Node (or
# the other way around), forcing us to navigate the documentation hierarchy which doesn't have hyperlinks.

# http://search.cpan.org/~shlomif/XML-LibXML-2.0118/lib/XML/LibXML/Node.pod

# Since we have a namespace, we must parse with $xpc, and that means we need to use $doc as the second arg
# to findnodes(). Confusing. It seems like there would be a way to construct an $xpc specifically for the
# parsed file, and thus not need the second arg to findnodes().


use strict;
use DateTime;
use Storable;
use DBI;
use Getopt::Long;
use XML::LibXML;

# support utf8 strings
use utf8;

use av; # attribute value controlled vocabulary, directly from av.xsl

require 'anf.pm';

my %av = %av::av;

# http://stackoverflow.com/questions/21096900/how-do-i-avoid-double-utf-8-encoding-in-xmllibxml

# When doing output via libxml, do not utf8 double encode stdout. XML libxml output is already utf8
# encoded. However, normal print statements are not utf8.

# (apr 20 2015 disabled, see note above) enable utf8 for stdin, stdout (and presumably stderr)
# use open qw(:std :utf8);

my $dbh;
my $debug = 0;
my $info = 0;
my %name_role;
my $outdir = "snac_files";

my $cpf_rel_href = 'https://www.siv.archives-nationales.culture.gouv.fr/siv/rechercheconsultation/consultation/producteur/consultationProducteur.action?notProdId=';

# When using an XML modules, the & is auto-converted into &amp; so we don't have to worry about it.
# aug 11 2015 the correct URL, explicitly from Florence via email.
my $res_rel_href = 'https://www.siv.archives-nationales.culture.gouv.fr/siv/rechercheconsultation/consultation/ir/consultationIR.action?irId=';



# Execution starts here. main() is traditional. 
$|=1; # unbuffer stdout
main();
exit();

my $cr_ref; # parsed data from parse_anf.pl


sub main
{
    # Interesting args. Is that an anonymous hash without {}?
    GetOptions( 'info!' => \$info, 'debug!' => \$debug);

    # get the data describing all files/entities/cpfRelations which was created by parse_anf.pl
    $cr_ref = retrieve('frozen_data.dat');

    # Initializes the global $dbh
    db_connect();

    %name_role = sql_name_role();

    my @files;
    if ($debug)
    {
        # testing only
        # FRAN_NP_050367.xml has biogHist, cpfRelation
        # FRAN_NP_000080.xml has resourceRelation, biogHist
        # FRAN_NP_010172.xml has cpf role record not found, which we now assume exists, having been created by render_anf.pl

        @files = ("working_files/FRAN_NP_050367.xml", "working_files/FRAN_NP_000080.xml", "working_files/FRAN_NP_010172.xml");
    }
    else
    {
        # Note: find on a symlink requires the trailing / to find any files.
        @files = `find working_files/ -type f`;
        chomp(@files);
    }

    # stderr
    print  "date: " . scalar(localtime()) . "\ndebug: $debug\ninfo: $info\noutdir: $outdir\n";

    my $parser = XML::LibXML->new();
    my $xpc = XML::LibXML::XPathContext->new(); # No argument here!
    reg_namespaces($xpc);

    if (! -d $outdir)
    {
        mkdir $outdir;
    }


    foreach my $filename (@files)
    {
        # We might create a <relations> element once per transformed file. Reset the flag before each file.
        reset_rc();

        my $change_flag = 0; # Nothing changed yet.

        print  "\nparsing: $filename\n";

        # See note 1 above about xml doc and parsing trivia.
        my $doc = $parser->parse_file($filename);
        my $record_id = get_rid({xpc => $xpc, doc =>$doc});
        
        if ($info)
        {
            get_info({xpc => $xpc, doc => $doc});
        }
        else
        {
            # One sub does all the transformations in the correct order. Args are pass-by-reference so the doc
            # is changed in place.
            transform({xpc => $xpc, doc => $doc});
        }


        # format 0 is dump as originally parsed. See docs for toString().
        # Could use: $state = $doc->toFile($filename, $format);
        if ($debug || $info)
        {
            my $tmpname = 'tmp.xml';
            if ($info)
            {
                # stderr
                print  "Would have written: $filename, info mode no file written\n";
            }
            else
            {
                # stderr
                print  "Would have written: $filename, instead writing: $tmpname\n";

                if (! open(my $xml, '>', $tmpname))
                {
                    # stderr
                    print  "Cannot open $tmpname for write.\n";
                }
                else
                {
                    printf $xml $doc->serialize(0);
                }
            }
        }
        else
        {
            my $outfile = $filename;
            $outfile =~ s/^.*\/(.*)$/$outdir\/$1/;
            if (! open(my $xml, '>', $outfile))
            {
                # stderr
                print  "Error: Cannot open $outfile for write.\n";
                exit(1);
            }
            else
            {
                printf $xml $doc->serialize(0);
            }
        }
    }
} # end main

# http://search.cpan.org/~shlomif/XML-LibXML-2.0121/lib/XML/LibXML/XPathContext.pod
# my $uri = $xpc->lookupNs('xlink');

sub reg_namespaces
{
    my $xpc = $_[0];

    $xpc->registerNs('eac',
                     'urn:isbn:1-931666-33-4');

    $xpc->registerNs('xlink',
                     'http://www.w3.org/1999/xlink');

    $xpc->registerNs('xsi',
                     'http://www.w3.org/2001/XMLSchema-instance');
}
 
# The transformations are short enough to be put together in a single function. See comments. At least one of
# these is order dependent.

sub transform
{
    my ($args) = @_;
    my $xpc = $args->{xpc};
    my $doc = $args->{doc};

    # the main record id. Other record id values occur in cpfRelation and resourceRelation.
    my $eac_record_id = get_rid({xpc => $xpc, doc => $doc});

    # remove_xsi_schema
    foreach my $elem ($xpc->findnodes('/eac:eac-cpf', $doc))
    {
        $elem->removeAttribute( 'xsi:schemaLocation');
    }

    # bioghist_citation
    foreach my $bioghist ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:description/eac:biogHist', $doc))
    {
        my $citation = $doc->createElement("citation");
        $bioghist->addChild($citation);
        my $text_node = XML::LibXML::Text->new("Information extraite de la notice des Archives nationals de France ($eac_record_id)");
        $citation->addChild($text_node);
    }

    # resource_relation_href
    foreach my $resrel ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:resourceRelation', $doc))
    {
        # Works to select the attribute. Apparently using the registered namespace shortcut name.
        my $href_value = $resrel->getAttribute('xlink:href');
        if ($href_value)
        {
            $resrel->setAttribute('xlink:href', "$res_rel_href$href_value" );
        }
        else
        {
            # Do not create empty xlink:href.
            # xlink:href is optional, and when empty it creates broken links in the XTF search results page.
            # findnodes() returns a node list, so assign the first (and only element) via list context, so we have a single node.

            my ($relentry) = $xpc->findnodes('eac:relationEntry/text()', $resrel);
            my $relvalue = 'null';
            if ($relentry)
            {
                $relvalue = $relentry->getData();
            }
            printf ("empty/missing xlink:href for resourceRelation/relationEntry: %s\n", $relvalue);
        }
    }

    # add resourceRelation arcrole
    # And add xlink:type while working on the resourceRelation
    foreach my $elem ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:resourceRelation', $doc))
    {
        my $type = $elem->getAttribute('resourceRelationType');
        $elem->setAttribute( 'xlink:arcrole', snac_resrel_arcrole($type));
        $elem->setAttribute( 'xlink:type', 'simple');
    }

    # Loop through the cpfRelation elements only once, and do several related tasks.
    # add_cpf_arcrole, add descriptiveNote, cpf_relation_href add_cpf_role
    foreach my $elem ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:cpfRelation', $doc))
    {
        # The record id that the cpfRelation is relating to is in the xlink:href. Some of these record id
        # values are not in the the set of CPF records we have, although we create CPF files for the
        # cpfRelations that we know about but which don't have a file. That is handled by render_anf.pl.
        
        # Jun 22 2015 Remove xlink:href below.
        my $cpfrel_record_id = $elem->getAttribute('xlink:href');
        
        my $cr_type = $elem->getAttribute('cpfRelationType');
        $elem->setAttribute( 'xlink:arcrole', snac_cpf_arcrole($cr_type));

        my $xpath = '/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:cpfRelation/eac:descriptiveNote';
        my ($descriptiveNote_el) =  ($xpc->findnodes($xpath, $elem));
        
        # if not descriptiveNote, add descriptiveNote/p/span/@localType ExtractedRecordId createElement()
        # seems to create elements in the namespace of the existing node. Or does the namespace get fixed in
        # appendChild()?
        if (! $descriptiveNote_el)
        {
            $descriptiveNote_el  = $doc->createElement("descriptiveNote");
            $elem->appendChild($descriptiveNote_el);
        }

        # Add p/span to existing descriptiveNote
        {
            my $p_el = $doc->createElement("p");
            my $span_el  = $doc->createElement("span");
            $span_el->setAttribute('localType', $av{av_extractRecordId} );

            $span_el->appendChild(XML::LibXML::Text->new($cpfrel_record_id));
            $p_el->appendChild($span_el);
            $descriptiveNote_el->appendChild($p_el);
        }

        # Non-sameAs do not have xlink:href, so remove it. A non-sameAs cpfRelation links back into SNAC, thus
        # an xlink:href to the original repository/collection is wrong.
        $elem->removeAttribute('xlink:href');
        
        # # cpf_relation_href
        # {
        #     # Apparently the registered namespace shortcut name works because we registered it.
        #     my $href = "$cpf_rel_href$cpfrel_record_id";
        #     if ($href)
        #     {
        #         $elem->setAttribute('xlink:href', $href );
        #         # stderr
        #         print  "setting cpfRelation xlink:href to: $href\n";
        #     }
        #     else
        #     {
        #         # stderr
        #         print  "cpfRelation xlink:href empty\n";
        #     }
        # }
        
        # add_cpf_role
        {
            if (exists($name_role{$cpfrel_record_id}))
            {
                $elem->setAttribute( 'xlink:role', normalized_role($name_role{$cpfrel_record_id}) );
                # stderr
                print  "add_cpf_role xlink:role: $cpfrel_record_id\n";
            }
            else
            {
                $elem->setAttribute( 'xlink:role', '');
                
                # May 28 2015. This loggin message is older, before Florence returned us a list of all the unknown
                # cpfRelations and their xlink:role (corp, pers, family).
                
                # findnodes() returns a node list, so assign the first (and only element) via list context, so we
                # have a single node.
                
                my ($relentry) = $xpc->findnodes('eac:relationEntry/text()', $elem);
                # stderr
                print  "cpf role record not found: $cpfrel_record_id relationEntry: " . $relentry->getData(). "\n";
            }
        }
    }
    
    # add_res_role
    foreach my $elem ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:resourceRelation', $doc))
    {
        # Yes, lowercase a in 'archival' of av_archivalResource.
        $elem->setAttribute( 'xlink:role', $av{av_archivalResource});
        # Seems lik we should not have to do this, but it seems to work
        $elem->setNamespace("http://www.w3.org/1999/xlink", "xlink",0)
    }

    # add sameAs cpfRelation, start by checking for <relations>. If <relations> doesn't exist, create it. 
    # Jun 10 2015, Must only use part[1] or must concat with space and/or normalize space.

    add_sameas({xpc => $xpc, doc => $doc, href => "$cpf_rel_href$eac_record_id"});

    # Use () to cast list context to only the first returned value, aka list[0], and then when we have a
    # single node, call textContent() on that node.
    my ($entityId) = $xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:entityId', $doc);
    my $isni = '';
    if ($entityId)
    {
        $isni = $entityId->textContent();
    }
    if ($isni)
    {
        $isni =~ s/^ISNI//; # remove leading 'ISNI' text.
        $isni =~ s/\s+//g; # remove all the spaces
        add_sameas({xpc => $xpc, doc => $doc, href => "http://isni.org/isni/$isni"});
        print "Adding: sameas for isni: $isni\n";
    }


    # add a maintenance event
    my ($maintenanceHistory) = $xpc->findnodes('/eac:eac-cpf/eac:control/eac:maintenanceHistory', $doc);
    my $maintenanceEvent = $doc->createElement('maintenanceEvent');
    
    $maintenanceEvent->appendTextChild( 'eventType' , 'revised' );
    $maintenanceEvent->appendTextChild( 'eventDateTime' , DateTime->now->ymd );
    $maintenanceEvent->appendTextChild( 'agentType' , 'machine' );
    $maintenanceEvent->appendTextChild( 'agent' , 'cpf_norm.pl' );
    
    $maintenanceHistory->appendChild($maintenanceEvent);

} # end sub transform


my $relations_created = 0;
sub reset_rc
{
    $relations_created = 0;
}

sub add_sameas
{
    my ($args) = @_;
    my $xpc = $args->{xpc};
    my $doc = $args->{doc};
    my $href = $args->{href};

    # Get data from our own record
    my $entityType = $xpc->findvalue('/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:entityType/text()', $doc);

    # Use () to cast list context to only the first returned value, aka list[0], and then when we have a
    # single node, call textContent() on that node.
    my ($part_node) = $xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:nameEntry/eac:part', $doc);
    my $part = $part_node->textContent();

    my ($dateRange_e)
    = $xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates/eac:dateRange', $doc);
    my ($date_e)
    = $xpc->findvalue('/eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates/eac:date', $doc);

    my $fromDate = '';
    my $toDate = '';

    # We only use fromDate and toDate. If there is only a single date, it goes into fromDate. 
    if ($dateRange_e)
    {
        $fromDate = trim($xpc->findvalue('eac:fromDate/@standardDate', $dateRange_e));
        $toDate = trim($xpc->findvalue('eac:toDate/@standardDate', $dateRange_e));
    }
    elsif ($date_e)
    {
        $fromDate = trim($date_e->findvalue('@standardDate'));
    }


    # Create new elements
    # $node->setAttributeNS( $nsURI, $aname, $avalue );
    my $cpfRelation = $doc->createElement("cpfRelation");
        
    # I thought in other places I simply call setAttribute() and use the namespace prefix. In any case,
    # setAttributeNS() requires the actual uri of the namespace, not the namespace prefix alias. So, we look
    # it up...
    my $uri = $xpc->lookupNs('xlink');

    # $cpfRelation->setAttributeNS($uri, 'xlink:href', "$cpf_rel_href$eac_record_id"); 

    # jun 25 2015 Switch over to using the $href arg so we can built sameAs for multiple outside
    # URI/ARK/ID/URL values. This was created specifically to support entityId ISNI values.

    $cpfRelation->setAttributeNS($uri, 'xlink:href', $href);
    $cpfRelation->setAttributeNS($uri, 'xlink:role', normalized_role($entityType));
    $cpfRelation->setAttributeNS($uri, 'xlink:arcrole', $av{av_sameAs} );
    $cpfRelation->setAttributeNS($uri, 'xlink:type', 'simple' );

    my $relationEntry = $doc->createElement("relationEntry");

    # $fromDate and/or $toDate will or will not be defined. If neither, $date_range_hr comes back empty.
    my $is_active = 0;
    if ($entityType =~ m/corp/i)
    {
        $is_active = 1;
    }
    my $date_range_hr = build_date({name => $part, from_year => $fromDate, to_year => $toDate, is_active => $is_active});

    # corporate body preferred name is simply the <part>, but we can add life dates to person names.

    my $pref_name = $part;
    if ($entityType =~ m/person/i)
    {
        $pref_name = build_pref_name({
                                      raw_name_from_db => $part,
                                      date_range_hr => $date_range_hr
                                     });
    }

    # Append the elements to each other and the containing cpfRelation append to <relations>
    $relationEntry->appendChild(XML::LibXML::Text->new($pref_name));

    $cpfRelation->appendChild($relationEntry);
    if ($dateRange_e)
    {
        my $new_dateRange =$dateRange_e->cloneNode(1); # clone deep
        $cpfRelation->appendChild($new_dateRange);
    }
    elsif ($date_e)
    {
        my $new_date =$date_e->cloneNode(1); # clone deep
        $cpfRelation->appendChild($new_date);
    }

    # Some records have no relations, in which case we need to create one as a container for the sameAs
    # cpfRelation that we are creating. (Or have created, above.)

    my ($relations) = $xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations', $doc);

    # jul 7 2015. New: if we successfully create an eac:relations, then we go into the else clause. If we are
    # not successful, then we create duplicate <relations> element, apparently only possible by not using the
    # namespace when creating the element. The intention is that appending the element causes it to inherit
    # the namespace of the parent, but oddly, that doesn't seem to work.

    # In otherwords, using createElement() results in a <relations> element, not <eac:relations>. Even after
    # appendChild() that is still (oddly) a <relations> element. When serialized the XML document is fine, so
    # apparently the namespaces are resolved when serialized, not during appendChild(). Solve the problem by
    # always using the namespace when adding an element that we will be testing for later. If we only add, and
    # don't care until the doc is serialized, then things are fine.

    # In the case of <relations> we do care, and as seen above, we check for <eac:relations>, therefore we
    # must use the namespace-aware version createElementNS().

    # old: Unclear why <relations> being created when one was created. $doc is the only doc, and should
    # be updated in place. Hack this by using the $relations_created flag. 

    if (! $relations)
    {
        print "creating relations: relations_created: $relations_created\n";
        $relations_created = 1;
        my ($cpfDescription) = $xpc->findnodes('/eac:eac-cpf/eac:cpfDescription', $doc);
        
        # $element = $dom->createElementNS( $namespaceURI, $qname );
        my $uri = $xpc->lookupNs('eac');
        $relations = $doc->createElementNS($uri, "relations");
        # $relations = $doc->createElement("relations");
        $cpfDescription->appendChild($relations);
        $relations->appendChild($cpfRelation);
    }
    else
    {
        # list context returned to single value, therefore $resourceRelation is the first resourceRelation node.
            
        # fails:
        # XPath error : Undefined namespace prefix
        # error : xmlXPathCompiledEval: evaluation failed
        # my ($resourceRelation) = $relations->findnodes('eac:resourceRelation');

        my ($resourceRelation) = $xpc->findnodes('eac:resourceRelation', $relations);

        # We can be lazy about our insert because if the reference nod is missing, it behaves properly.
        # $parent_node->insertBefore( $newNode, $refNode );
        # http://search.cpan.org/~shlomif/XML-LibXML/lib/XML/LibXML/Node.pod
        # The method inserts $newNode before $refNode. If $refNode is undefined, the newNode will be set
        # as the new last child of the parent node. This function differs from the DOM L2 specification,
        # in the case, if the new node is not part of the document, the node will be imported first,
        # automatically.

        $relations->insertBefore($cpfRelation, $resourceRelation);
    }
}

# AnF resourceRelationType to SNAC resourceRelation xlink:arcrole
sub snac_resrel_arcrole
{
    my $anf_type = $_[0];
    my %role = (creatorOf => $av{av_creatorOf},
                other => $av{av_associatedWith},
                subjectOf => $av{av_referencedIn});

    if (exists($role{$anf_type}))
    {
        return $role{$anf_type};
    }
    else
    {
        # Maybe should die here, or write a message to stderr?
        # stderr
        print  "warning: no resource arcrole: for resourceRelationType: $anf_type\n";
        return undef;
    }
}

sub get_info
{
    my ($args) = @_;
    my $xpc = $args->{xpc};
    my $doc = $args->{doc};

    my $rid = get_rid({xpc => $xpc, doc => $doc});
    # stderr
    print  "recordId: $rid\n";

    foreach my $elem ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:resourceRelation', $doc))
    {
        my $av = $elem->getAttribute('resourceRelationType');
        # stderr
        print  "resrel resourceRelationType: $av\n";
        $av = $elem->getAttribute('xlink:href');
        # stderr
        print  "resrel xlink:href: $av\n";
    }

    foreach my $elem ($xpc->findnodes('/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:cpfRelation', $doc))
    {
        my $av = $elem->getAttribute('cpfRelationType');
        # stderr
        print  "cpfrel cpfRelationType: $av\n";
        $av = $elem->getAttribute('xlink:href');
        # stderr
        print  "cpfrel xlink:href: $av\n";
    }
}

sub check_date_range
{
    my $xpc = $_[0];
    my $exist = $_[1];
    my $change_flag = 0;
    my($range) = $xpc->findnodes('./eac:dateRange', $exist);

    if ($range && $range->hasChildNodes())
    {
        foreach my $node ($xpc->findnodes('./*', $range))
        {
            if ($node->textContent() =~ m/\D+\d{3}(\D+|$)/)
            {
                # stderr
                print  "modify: " . $node->textContent() . "\n";
                my($text) = $xpc->findnodes('./text()', $node);                
                $text->setData( '' );
                $node->removeAttribute( 'localType' );
                # stderr
                # print  "remove: " . $node->textContent() . "\n";
                # $range->removeChild($node);
                $change_flag = 1;
            }
        }
    }
    return $change_flag;
}

sub get_rid
{
    my ($args) = @_;
    my $xpc = $args->{xpc};
    my $doc = $args->{doc};
    my @rid_list =  $xpc->findnodes('/eac:eac-cpf/eac:control/eac:recordId', $doc);
    if (scalar(@rid_list) > 1)
    {
        use Data::Dumper;
        printf ("Too many rids: %s\n",  Dumper(\@rid_list));
    }
    return $rid_list[0]->textContent();
}


sub example
{
    # http://www.perlmonks.org/?node_id=1003089
    
    my $file = '1832.tcx';
    
    my $parser = XML::LibXML->new->parse_file($file);
    my $xml    = XML::LibXML::XPathContext->new;                # No argument here!
    $xml->registerNs('x',
                     'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2');
    
    for my $key ($xml->findnodes('//x:Lap', $parser)) {         # Provide the $parser here.
        my $string = $key->findvalue('@StartTime');             # No $parser needed, since attributes are namespaceless.
        print "1\t$string\n";
    }
}

sub db_connect
{
    # There is a reason for session_lib.pm and using app_config() and get_db_handle(), but this is a close
    # approximation for Postgres. SQLite only takes 1 line to connect.
    
    my @passlocs = ("/home/twl8n/.dbpass", "/Users/twl/.dbpass");

    my $passw;
    foreach  my $passloc (@passlocs)
    {
        if (open(my $fh, "<", $passloc))
        {
            $passw = <$fh>;
            chomp($passw);
            last;
        }
        else
        {
            printf("Can't open file %s\n", $passloc)
        }
    }
    if (! $passw)
    {
        die();
    }

    my $dbargs = {AutoCommit => 0, PrintError => 1};
	
    my $connect_string = sprintf("dbi:%s:dbname=%s;host=%s;port=%s;",
                                 'Pg',
                                 'anf',
                                 'localhost',
                                 '5433');
    
    $dbh = DBI->connect($connect_string,
                        'twl8n',
                        $passw,
                        $dbargs);
    if ($DBI::err)
    {
        my $str = sprintf("%s Couldn't connect using connect_string: $connect_string\n", (caller(0))[3]);
        # stderr
        print  "$str\n";
        # stderr
        print  "Is the database running?\n";
        exit(1); # exit/die with non-zero status
    }
}

# $name_role{recordid} = entitytype 
# anf=# select distinct(entitytype) from file_list;
#    entitytype   
# ----------------
#  corporate body
#  person
#  family

# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data -l ~/pg9.4.1/logfile start
# ~/pg9.4.1/bin/pg_ctl -D /home/twl8n/pg9.4.1/data stop

# If you want err_stuff() error checking and logging then you'll need to use session_lib.pm;
sub sql_name_role
{ 
    my $sql = "select recordIdentifier, entityType from file_list";
    my $sth = $dbh->prepare($sql);
    # err_stuff($dbh, $sql, "prep", $db_name, (caller(0))[3]);
    $sth->execute();
    # err_stuff($dbh, $sql, "exec", $db_name, (caller(0))[3]);

    my %name_role;
    while(my $hr = $sth->fetchrow_hashref())
    {
        $name_role{$hr->{recordidentifier}} = $hr->{entitytype};
    }
    
    # jun 11 2015 parse_anf.pl has code that does things cpf_norm.pl doesn't do (but in retrospect should have done)
    # so we can supplement these entity types with additional type determined by either the corp role or corp keywords.

    foreach my $base_id (keys(%{$cr_ref}))
    {
        if (! exists($name_role{$base_id}))
        {
            $name_role{$base_id} = $cr_ref->{$base_id}{entityType};
            print "Adding: $base_id entityType: $cr_ref->{$base_id}{entityType} ($cr_ref->{$base_id}{using_algo_entityType})\n";
        }
    }

    return %name_role;
}
