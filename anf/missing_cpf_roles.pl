#!/usr/bin/perl

use strict;
# support utf8 strings
use utf8;
use open qw(:std :utf8);

my $pip = 0;


my $saved = "";
while(my $temp = <>)
{
    chomp($temp);
    if ($temp =~ m/^parsing/)
    {
        $saved = $temp;
    }
    if ($temp =~ m/^cpf role/)
    {
        # If we have a "cpf role" line, then print our saved parsed line, and clear it.
        # We don't want to print 'parsed' lines that aren't followed by a 'cpf role' line.
        if ($saved)
        {
            print "\n$saved\n";
            $saved = '';
        }
        print "$temp\n";
    }
    # else don't print the other lines
}
