#!/usr/bin/perl

# Error messages are easier (possible) to find when stderr is in a separate file.

# Read frozen data from parse_anf.pl, create a list of cpf roles that can't be determined from the data we
# have. You must run parse_anf.pl before this.

# Add a feature to log the known corporateBody entities to stderr.

# ./get_missing_role.pl > cpf_role_not_found.txt 
# ./get_missing_role.pl > cpf_role_not_found.txt 2> corp_roles.txt


# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template.pm
# http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template/Tutorial/Datafile.pod

use strict;
use Storable;

require 'anf.pm';

# support utf8 strings
use utf8;

# Must use utf8 when not creating output via libxml
use open qw(:std :utf8);

main();

sub main
{
    my $out_file = 'frozen_data.dat';
    my $data_ref = retrieve($out_file);
    my %data_new = %{$data_ref};

    {
        foreach my $key (keys(%data_new))
        {
            my $href = $data_new{$key};

            if (! $href->{has_file})
            {
                # As for Jun 8 2015 we could check using_algo_entityType => yes. The corporateBody entityType
                # via the cpfRelationType is now done in parse_anf.pl

                my $is_known_corp = 0;
                # orig is a list of hash
                foreach my $hr (@{$href->{orig}})
                {
                    if ($hr->{entityType} eq 'corporateBody' &&
                        is_corp_rel($hr->{cpfRelationType}))
                    {
                        $is_known_corp = 1;
                        last;
                    }
                }
                if (! $is_known_corp)
                {
                    print "\n\nkey: $key\n";
                    print "  entityType(guess) => $href->{entityType}\n";
                    print "  relationEntry => $href->{relationEntry}\n";
                    print "  fromDate => $href->{fromDate}\n";
                    print "  toDate => $href->{toDate}\n";
                    print "  found_in => ";
                    my $tween = '';
                    foreach my $hr (@{$href->{orig}})
                    {
                        print "$tween$hr->{file}";
                        $tween = ', ';
                    }
                    
                    # foreach my $hkey (keys(%{$href}))
                    # {
                    #     if ($hkey eq 'orig')
                    #     {
                    #         # do nothing now, but output {orig} later.
                    #     }
                    #     else
                    #     {
                    #         print "  $hkey => $href->{$hkey}\n";
                    #     }
                    # }
                }
                else
                {
                    # is_known_corp true, so hard code the entityType!
                    print STDERR "\n\nkey: $key\n";
                    print STDERR "  entityType(algo relation) => corporateBody\n";
                    print STDERR "  relationEntry => $href->{relationEntry}\n";
                    print STDERR "  fromDate => $href->{fromDate}\n";
                    print STDERR "  toDate => $href->{toDate}\n";
                    # print STDERR "  found_in => ";
                    foreach my $hr (@{$href->{orig}})
                    {
                        foreach my $key (keys(%{$hr}))
                        {
                            print STDERR "    orig $key => $hr->{$key}\n";
                        }
                    }
                }
            }
        }
    }
}

