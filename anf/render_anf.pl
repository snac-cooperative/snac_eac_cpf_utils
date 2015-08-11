#!/usr/bin/perl

# Create CPF stub files for cpfRelation entities. Read data for cpfRelations parsed out of the existing files
# created by parse_anf.pl, and saved in frozen (storable) format.

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

# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template.pm
# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template/Tutorial/Datafile.pod

use strict;
use Storable;
use session_lib qw(:all);
use XML::LibXML;
use Template;
# Not on shannon, apparently not in any centos5 package repo
# use Data::Walk;

# support utf8 strings
use utf8;

# utf encode std out because we aren't using libxml which does the encoding, so we must encode ourselves.
use open qw(:std :utf8);

use DateTime;
use Data::Dumper;
use Getopt::Long;

use av; # attribute value controlled vocabulary, directly from av.xsl
my %av = %av::av;

require 'anf.pm';

# Not currently being used, not in centos5 packages. Too bad.
# use Date::Manip;

my $render_path = 'snac_files';
my $test_render_path = 'cpf_test';

my $base_url = "resourceRelation href based URL";

$| = 1; # unbuffer stdout

# track all the ids of resources we link to, for logging purposes.
my %all_rr_ids;

main();
exit();

my $cr_ref; # parsed data from parse_anf.pl

sub main
{
    my $is_test = 0;
    my $ok = GetOptions('test!' => \$is_test);

    # hash of hash, I guess
    # $cr_ref->{href} = {cpfRelationType => "associative", relationEntry => 'Pinel, Jean-Jacques', dateRange = 'a long string...'};
    $cr_ref = retrieve('frozen_data.dat');

    foreach my $href (keys(%{$cr_ref}))
    {
        my $uidl = $href; 
        # The value is a hash ref. Perl lets us cast that into an actual hash.
        my %fch = %{$cr_ref->{$href}};

        # my $entity_type = find_entity_type($fch{relationEntry});

        print "relentry: $fch{relationEntry} et: $fch{entityType} algo: $fch{using_algo_entityType}\n";
        my $entity_type = $fch{entityType};

        my $is_active = 0; # default to false
        if ($entity_type =~ m/corp/i)
        {
            $is_active = 1;
        }

        my $was_rendered = 0;
    
        # Skip any entry that has a file, because it already has a file, and this code is creating CPF files
        # for entries that have no file. That's the whole point.
        if ($fch{has_file})
        {
            print "Already have file: $href\n";
            next;
        }

        # Empty list. We are creating CPF stubs, so we don't have a resourceRelation, I think.
        my @rrel; 
        
        my @source_files;
        my $xx = 0;
        my $stop_at = 5;

        my $now = DateTime->now->ymd;
        
        my $raw_name_from_db = $fch{relationEntry};
        
        my $date_range_hr = build_date({name => $raw_name_from_db,
                                        from_year => $fch{fromDate},
                                        to_year => $fch{toDate},
                                        is_active => $is_active
                                       });

        my $pref_name = build_pref_name({
                                         raw_name_from_db => $raw_name_from_db,
                                         date_range_hr => $date_range_hr,
                                         entityType => $entity_type
                                        });

        # cpfRelation is list of hash Jun 10 2015 Should have created $pref_name way back in parse_anf.pl, but
        # it was something of an after thought (or after-requirement), and now I don't want to move it since
        # heaven only knows what would break. So, we hack build_cpf_relation() to use it.
        my @cpf_relation = build_cpf_relation($href, $pref_name);

        # %fch:
        # key: FRAN_NP_010253
        #   entityType => corporateBody
        #   file => FRAN_NP_013470, FRAN_NP_013307
        #   xhref => FRAN_NP_010253
        #   has_file => 
        #   relationEntry => Etude notariale CXLV
        #   cpfRelationType => associative
        #   toDate => 
        #   fromDate => 2010-07-20

        # A hash reference. These are template variables.
        # cpf_record_id is used to create the file name later in render().
        my $vars =
        {
         name_entry_lang => 'fre',
         have_any_leader => 0,
         cpf_record_id  => $uidl,
         date => $now,
         agent => "SNAC render_anf.pl",
         event_description => '',
         source => "one or more files: fix me",
         entity_type => $entity_type,
         entity_name => $pref_name,
         authorized_form => 'anf',
         descriptive_note => '',
         occupations => '',
         functions => '',
         local_affilation => '',
         topical_subject => '',
         geographic_subject => '',
         language => '', # description/language element, not currently used.
         tag_54 => '',
         citation => '',
         cpf_rel => \@cpf_relation,
         rrel => \@rrel,
         date_range => $date_range_hr, # Make sure this has the right date fields (it may have additional fields as well)
         source_files => \@source_files,
        };

        # Data::Walk would have been great. Too bad Centos 5 doesn't have a package for it.
        foreach my $key (keys(%{$vars}))
        {
            $vars->{$key} = trim($vars->{$key});
        }

        # cpf_rel, not cpf_relation
        foreach my $ref (@{$vars->{cpf_rel}})
        {
            foreach my $key (keys(%{$ref}))
            {
                $ref->{$key} = trim($ref->{$key});
            }
        }

        foreach my $ref (@{$vars->{rrel}})
        {
            foreach my $key (keys(%{$ref}))
            {
                $ref->{$key} = trim($ref->{$key});
            }
        }

        render($vars);
        $was_rendered = 1;
        # logging
        print "cpf_record_id: $uidl unique_id: $uidl pref: $pref_name\n";

        if ($pref_name =~ m/\d{4}/)
        {
            print "name has date: $pref_name\n";
        }

        if ($is_test)
        {
            exit();
            # print stuff out to a log file.
            # use Data::Dumper;
            # print Dumper(\%data);
        }
    }
    # logging.
    foreach my $key (sort {$a cmp $b} keys(%all_rr_ids))
    {
        print "wwa_id: $key (count: $all_rr_ids{$key})\n";
    }
}




sub build_resource_relation
{
    # Unused. Die if called.
    die "build_resource_relation() should be unused in render_anf.pl because this script only builds cpf stubs";
    my @rr_related = @_;
    my @rrel;
    foreach my $rh (@rr_related)
    {
        $all_rr_ids{$rh->{wwa_id}}++;   

        # hash ref
        my $rr = { role => $av{av_DigitalArchivalResource},
                    href => "$base_url$rh->{wwa_id}\.html",
                    rel_entry => $rh->{bibl_title},
                    object_xml => "From the $rh->{org_name}"
                  };

        if ($rh->{type} eq 'sender')
        {
            $rr->{arc_role} = $av{av_creatorOf};
        }
        else
        {
            $rr->{arc_role} = $av{av_associatedWith};
        }
        push(@rrel, $rr);
    }
    return @rrel;
}


sub cpfr_entity_type
{
    my @recips = @_;
    foreach my $recip (@recips)
    {
        $recip->{entity_type} = determine_entity_type($recip->{match}, 'uri');
    }
    return @recips;
}

# AnF stub files have a cpfRelation to the SNAC CPF originator, and to the AnF self record as sameAs.
# Originator(s) in {file} list, check for filename (more or less a .c equivalent) based on the file and create
# cpfRelation to that {key}

# key: FRAN_NP_010253
#   entityType => corporateBody
#   using_algo_entityType => yes
#   xhref => FRAN_NP_010253
#   has_file => 0
#   relationEntry => Etude notariale CXLV
#   fromDate => 2010-07-20
#   toDate => 
#   orig FRAN_NP_013470 => entityType => person
#   orig FRAN_NP_013470 => part => Pourrier, François
#   orig FRAN_NP_013470 => file => FRAN_NP_013470
#   orig FRAN_NP_013470 => cpfRelationType => associative
#   orig FRAN_NP_013470 => toDate => 
#   orig FRAN_NP_013470 => fromDate => 2010-07-20
#   orig FRAN_NP_013307 => entityType => person
#   orig FRAN_NP_013307 => part => Hayé, Thierry
#   orig FRAN_NP_013307 => file => FRAN_NP_013307
#   orig FRAN_NP_013307 => cpfRelationType => associative
#   orig FRAN_NP_013307 => toDate => 2009-07-21
#   orig FRAN_NP_013307 => fromDate => 2007-02-05

sub build_cpf_relation
{
    my $unique_id = $_[0];
    my $pref_name = $_[1];
    
    # Jun 8 2015 @recips has become a list of hash of fields about the entity we are creating a cpfRelation
    # for. Previously, @recips was simply a list of ARK/href/id strings.
    my @recips = @{${$cr_ref->{$unique_id}}{orig}};
    my @cpf_relation;
    
    # $recip is:

    # $VAR1 = {
    #           'entityType' => 'corporateBody',
    #           'part' => 'Etude LIV',
    #           'file' => 'FRAN_NP_010181',
    #           'cpfRelationType' => 'associative',
    #           'toDate' => '',
    #           'fromDate' => '1518-01-01'
    #         };


    foreach my $recip (@recips)
    {
        # local hash ref
        # my $fch = $cr_ref->{$recip};
        
        # (Really? Is there a has_file test somewhere? Or some other self-excluding logic?) I'm pretty sure
        # this can't accidentally make a cpfRelation to ourself. We wouldn't be here if a file already existed
        # with our unique id.
        
        my $is_active = 0; # default to false
        if ($recip->{entityType} =~ m/corp/i)
        {
            $is_active = 1;
        }

        if (! -e "$render_path/$recip->{file}\.xml")
        {
            print "Error: file not found: $render_path/$recip->{file}\.xml for unique_id: $unique_id\n";
        }
        # hash ref
        my $date_range_hr = build_date({name => $recip->{part},
                                        from_year => $recip->{fromDate},
                                        to_year => $recip->{toDate},
                                        is_active => $is_active
                                       });
        my $pref_name = build_pref_name({
                                         raw_name_from_db => $recip->{part},
                                         date_range_hr => $date_range_hr,
                                         entityType => $recip->{entityType}
                                        });

        # Jun 22 2015 Only use href in sameAs cpfRelations.
        # href => cpf_rel_href() . $recip->{file}, # correct, the id (ARK) of the cpfRelation, not the orig, not $unique_id

        # Note: SNAC cpfRelation never has xlink:href, always has SNAC descriptiveNote.

        my $cpf = { role => normalized_role($recip->{entityType}),
                    arc_role => snac_cpf_arcrole($recip->{cpfRelationType}),
                    relation_entry => $pref_name,
                    av_extractRecordId => $av{av_extractRecordId},
                    record_id => $recip->{file},
                    date_range => $date_range_hr
                  };
        push(@cpf_relation, $cpf);
        print "cpfrel recordId: $recip->{file} cpfRelationType: $recip->{cpfRelationType}\n";
    }
    
    {
        # Create a sameAs for ourself.

        # jun 22 2015 sameAs has xlink:href, but never has SNAC descriptiveNote.
        # no_descriptiveNote => 1,

        # jun 10 2015 Was relation_entry => $fch->{relationEntry}, which was wrong because we often add dates to the name. 
        my $fch = $cr_ref->{$unique_id};

        my $is_active = 0; # default to false
        if ($fch->{entityType} =~ m/corp/i)
        {
            $is_active = 1;
        }


        # build_date() can return undef (?). Seems like a bad idea.
        my $date_range_hr = build_date({name => $pref_name,
                                        from_year => $fch->{fromDate},
                                        to_year => $fch->{toDate},
                                        is_active => $is_active
                                       });

        my $cpf = { role => normalized_role($fch->{entityType}),
                    arc_role => $av{av_sameAs},
                    relation_entry => $pref_name,
                    href => cpf_rel_href() . $unique_id, # unique_id correct because this is sameAs (ourself)
                    av_extractRecordId => $av{av_extractRecordId},
                    record_id => "$unique_id",
                    date_range => $date_range_hr
                  };
        push(@cpf_relation, $cpf);
    }
    
    print "uid $unique_id has ".  scalar(@cpf_relation) . " cpfRelation(s)\n";
    return @cpf_relation;
}



sub render
{
    my $vars = $_[0];

    # some useful options (see below for full list)

    # not doing any whitespace cleanup in POST_CHOMP leaves blanks for template directives, but preserves the
    # indentation.

    my $config = {
                  TRIM => 1, 			# trim leading and trailing whitespace
                  INCLUDE_PATH => './',  	# or list ref
                  INTERPOLATE  => 0,            # expand "$var" in plain text
                  POST_CHOMP   => 0,            # do not cleanup whitespace
                  PRE_PROCESS  => '',        	# prefix each template
                  EVAL_PERL    => 0,            # evaluate Perl code blocks
                  ANYCASE => 1,         	# Allow directive keywords in lower case (default: 0 - UPPER only)
                  ENCODING => 'utf8'            # Force utf8 encoding
                 };

    # create Template object
    my $template = Template->new($config);

    # specify input filename, or file handle, text reference, etc.
    my $input = 'cpf_template.xml';

    # process input template, substituting variables

    my $fn = "$render_path/$vars->{cpf_record_id}\.xml";
    open(my $out, '>', $fn) || die "Can't open $fn for output\n";

    # http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template.pm#process%28$template,_\%vars,_$output,_%options%29
    # Third arg can be a GLOB ready for output.
    $template->process($input, $vars, $out) || die $template->error();
    close($out);
    print "Created: $fn\n";
}



