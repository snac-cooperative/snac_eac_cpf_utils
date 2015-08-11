
use strict;

# Support utf8 strings. This must be here even though this file is required in a file that is using utf8.
# > file -i anf.pm      
# anf.pm: text/plain; charset=utf-8
use utf8;

use av; # attribute value controlled vocabulary, directly from av.xsl
my %av = %av::av;


# jun 19 2015, move here from cpf_norm.pl because we need to call it from render_anf.pl also
sub normalized_role
{
    my $anf_role = $_[0];

    # Ideally, this would have all the controlled vocab values from av.xsl

    # jun 11 2015 add 'corporateBody' which comes from parse_anf.pl additional entityType data. Which makes me
    # wonder where 'corporate body' ever came from. That's not a conventional usage.

    my %role_conf = ('corporateBody' => $av{av_CorporateBody},
                     'corporate body' => $av{av_CorporateBody},
                     'person' => $av{av_Person},
                     'family' => $av{av_Family});
    if (exists($role_conf{$anf_role}))
    {
        return $role_conf{$anf_role};
    }
    else
    {
        # Maybe should die here, or write a message to stderr?
        # stderr
        print  "anf role not found: $anf_role\n";
        return undef;
    }
}


# Used in render_anf.pl, but not used in cpf_norm.pl
sub cpf_rel_href 
{
    return 'https://www.siv.archives-nationales.culture.gouv.fr/siv/rechercheconsultation/consultation/producteur/consultationProducteur.action?notProdId=';
}

# When using an XML modules, the & is auto-converted into &amp; so we don't have to worry about it.
# Not used, but should be used. See global var of the same name in cpf_norm.pl
sub res_rel_href
{
    return 'https://www.siv.archives-nationales.culture.gouv.fr/siv/rechercheconsultation/consultation/ir/consultationIR.action?irId=';
}


# Copied from cpf_norm.pl
# AnF cpfRelationType to SNAC cpfRelation xlink:arcrole
sub snac_cpf_arcrole
{
    my $anf_type = $_[0];
    my %role = (associative => $av{av_associatedWith},
                family => $av{av_hasFamilyRelationTo},
                'hierarchical-child' => $av{av_hasChild},
                'hierarchical-parent' => $av{av_hasParent},
                'temporal-earlier' => $av{av_isSuccessorOf},
                'temporal-later' => $av{av_isSucceededBy});

    if (exists($role{$anf_type}))
    {
        print "anf_type: $anf_type resulting arcrole: $role{$anf_type}\n";
        return $role{$anf_type};
    }
    else
    {
        # Maybe should die here, or write a message to stderr?
        print "warning: no cpf arcrole: for cpfRelationType: $anf_type\n";
        return undef;
    }
}

sub is_corp_rel
{
    my @ctype = @_;
    my @tlist = ('hierarchical-child', 'hierarchical-parent', 'temporal-later', 'temporal-earlier');

    foreach my $ctype (@ctype)
    {
        if (grep /$ctype/, @tlist)
        {
            return 1;
        }        
    }
    return 0;
}

# When a cpfRelation has a file, then we use the <entityType> as a certain entityType. No need to guess when
# there is a file.

sub known_entity_type
{
    my $ark = $_[0];
    my $dfi = $_[1]; # hash ref of hashes

    if (exists($dfi->{$ark}))
    {
        return $dfi->{$ark}{entityType};
    }
    else
    {
        return '';
    }
}

sub find_entity_type
{
    my $ark = $_[0];
    my $name_str = $_[1];

    print "find_entity_type: ark: $ark name_str: $name_str\n";

    # Check France "Hoang, France"

    # > grep relationEntry pa.log | perl -ne 's/\s*relationEntry\s+=>\s+//; print ;' | grep ',' | grep -i 'france'
    # Hoang, France
    # Bureau des musées nationaux, affaires générales, de la planification et des travaux d'équipement (direction des musées de France)

    # Présidence is corp?
    # FRAN_NP_009872
    # Présidence de Nicolas Sarkozy

    # Make these word matches, not substring.
    # corporateBody is probably not ", $word"

    my @corp_words = ('etude', 'Agence', 'Administration', 'Archives', 'Association', 'Assemblée', 'nationale', 'Autorité', 'Bureau', 'Caisse', 'Internet', 'Centre', 'Cercle', 'Collectif', 'Collège', 'Commissaire', 'Comité', 'Confédération', 'Conseil', 'Conservatoire', 'Cour ', 'Délégation', 'Directeur', 'Direction', 'École', 'École', 'France', 'Fédération', 'Inspection', 'Institut', 'Laboratoire', 'Ligue', 'Ministère', 'national', 'Mouvement', 'international', 'Musée', 'Office', 'Organisation', 'Radio', 'Secrétariat', 'Service', 'Sous-direction', 'direction', 'Union');

    # perl -e '$xx="Musée du Louvre"; $word="Musée"; if ($xx =~ m/\b$word\b/i && $xx !~ m/, $word$/) { print "yes\n";} else { print "no\n";}'

    my $is_corp = 0;
    foreach my $word (@corp_words)
    {
        if ($name_str =~ m/\b$word\b/i && $name_str !~ m/, $word$/)
        {
            $is_corp = 1;
            last;
        }
    }            
    if ($is_corp)
    {
        return "corporateBody";
    }
    else
    {
        return "person";
    }
}


# This is old(er), and came from a repo with English records. Won't work for anf.

# Determine corporateBody or not. Given a name (also name_key, or match name) return our best guess at the entity type. List gleaned by
# scrolling through all names.

sub determine_entity_type
{
    my $str = $_[0];
    my $flag = $_[1];

    # The only value for $flag that matters is 'uri', and anything else returns plain old text for
    # <entityType>.

    # Must be whole word, that is have a word boundary on both sides.
    # Can't do word boundary on & so it goes into a second regex.
    if ($str =~ m/\b(?:committee|association|tribune|company|sons|magazine|weekly|bankers|courier|co)\b/i ||
        $str =~ m/\&/)
    {
        if ($flag eq 'uri')
        {
            return $av{av_CorporateBody};
        }
        else
        {
            return 'corporateBody';
        }
    }
    else
    {
        # Includes librarian of congress, editor of abc, etc.
        if ($flag eq 'uri')
        {
            return $av{av_Person};
        }
        else
        {
            return 'person';
        }
    }

}

sub build_pref_name
{
    my ($args) = @_;
    my $raw_name_from_db = $args->{raw_name_from_db};
    my $date_range_hr = $args->{date_range_hr};
    my $entityType = $args->{entityType};

    my $pref_name = $raw_name_from_db;
    
    # If the name doesn't have any dates, add them. The date test is very simple checking for 4 digits.
    # Note that !~ is the "not matches" regex binding operator.
    
    # Only add dates to person names, not corporateBody or family.

    if ($entityType =~ m/pers/ && $pref_name !~ m/\d{4}/)
    {
        # As is typical constructing name strings, we can end up with extra whitespace, and maybe a trailing
        # comma. Clean up. Cleaning up is easier and more reliable than trying to construct the perfect name.
        # Build the formatted date that might go into the name string. Same date testing is done above. Here
        # we either have a single from date or both from and to.
        my $date_use = '';
        if ($date_range_hr->{from_date} && $date_range_hr->{to_date})
        {
            $date_use = "$date_range_hr->{from_date}-$date_range_hr->{to_date}";
        }
        else
        {
            $date_use = "$date_range_hr->{from_date}";
        }
        $pref_name= sprintf("%s, %s",
                            $raw_name_from_db,
                            $date_use);
    }

    # Regardless of where the name string came from, do some cleaning on it.
    # We clean (order dependent): trailing whitespace, trailing comma, multi whitespace.
        
    $pref_name =~ s/[\[\]()?]//g;
    $pref_name =~ s/\s*$//;
    $pref_name =~ s/,$//;
    $pref_name =~ s/\s{2,}/ /g;
    return $pref_name;
}

# Simple extraction of 1 or 2 years (4 digits) from the name string. Most dates have a hyphen, but not
# all. There seem to be no instances of 4 digits that are not dates, so just do the simple 4 digit match.

# The template deals with missing, so do not create empty date parts (although empty would probably behave the
# same as not existing in the hash).

# jul 7 2015 bring over named-args from chaco/cpf_utils.pm

sub build_date
{
    my ($args) = @_;
    my $name = $args->{name};
    my $is_active = $args->{is_active};
    my $en_from = $args->{from_year};
    my $en_to = $args->{to_year};


    # old standard style args
    # my $name = $_[0];
    # my $en_from = $_[1]; # entity from date
    # my $en_to = $_[2];   # entitye to date
    my $date_range_hr;
    
    # Unless there is $en_from or $en_to, we are going to check the name for 4 digit dates.
    my $check_name = 1;

    if ($en_from)
    {
        $date_range_hr->{std_from} = $en_from;
        $date_range_hr->{from_date} = $en_from;
        $date_range_hr->{from_date} =~ s/(\d{4}).*/$1/; # keep year only
        $check_name = 0;
    }

    if ($en_to)
    {
        $date_range_hr->{std_to} = $en_to;
        $date_range_hr->{to_date} = $en_to;
        $date_range_hr->{to_date} =~ s/(\d{4}).*/$1/; # keep year only
        $check_name = 0;
    }

    if ($check_name)
    {
        # We must have at least one date. The second date is optional and ? is 0 or 1
        $name =~ m/(\d{4})\D*(\d{4})?/;
        my $from_date = $1;
        my $to_date = $2;
        if ($from_date)
        {
            $date_range_hr->{std_from} = $from_date;
            $date_range_hr->{from_date} = $from_date;
        }
        if ($to_date)
        {
            $date_range_hr->{std_to} = $to_date;
            $date_range_hr->{to_date} = $to_date;
        }
    }

    # $is_active can be true or false (1 or 0). Set the hash fields to whatever value $is_active has, and do
    # that consistently, even in the else clause below where we know $is_active is 0 (false).

    $date_range_hr->{from_is_active} = $is_active;
    $date_range_hr->{to_is_active} = $is_active;
    if ($is_active)
    {
        $date_range_hr->{from_type} = $av{av_active};
        $date_range_hr->{to_type} = $av{av_active};
        $date_range_hr->{from_is_active} = $is_active;
        $date_range_hr->{to_is_active} = $is_active;
    }
    else
    {
        $date_range_hr->{from_type} = $av{av_born};
        $date_range_hr->{to_type} = $av{av_died};
        $date_range_hr->{from_is_active} = $is_active;
        $date_range_hr->{to_is_active} = $is_active;
    }

    return $date_range_hr;
}

sub trim
{
    my $str = $_[0];

    if (ref($str))
    {
        return $str;
    }
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/\s+/ /smg;

    # Replace unicode hex 2014 em dash, and hex 2013 en dash with a hyphen.
    $str =~ s/—|–/-/smg;

    # results in a bizarre error, apparently some kind of double encoding.
    # pre: Trübner & Company post:Tr&Atilde;&frac14;bner &amp; Company

    # my $encoded = encode_entities($str);

    $str =~ s/\&/&amp;/g;
    return $str;

    # if ($str =~ m/bner/)
    # {
    #     print "pre: $str post:$encoded\n";
    # }

    # return $encoded;
}



1;


