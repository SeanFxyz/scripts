#!/usr/bin/env perl

use utf8;
use strict;

use Getopt::Long;

my @alphabet = qw( a b c d e f g h i j k l m n o p q r s t u v w x y z );
my $alphalen = scalar(@alphabet);

my %numalpha = map { $_ => $alphabet[$_] } 0..@alphabet;
my %alphanum = reverse %numalpha;

# Option variables
my $crack = 0;   # Crack the input text by trying every possible key.
my $numbers = 0; # Do we show shift values when cracking.
my $key = 13;    # key value

GetOptions (
    'n' => \$numbers,
    'numbers!' => \$numbers,
    'k=s' => \$key,
    'key=s' => \$key,
);

print "@ARGV\n";
print shiftchar('h', 13) . "\n";
print caesar("Hello", 13) . "\n";
print "$numbers\n";
print "$key\n";

sub shiftchar {
    my ($char, $key) = @_;
    my $low = lc($char);
    if (grep /$char/, @alphabet) {
        return $numalpha{ ($alphanum{$char} + $key) % $alphalen };
    } elsif (grep /$low/, @alphabet) {
        return uc shiftchar($low, $key);
    } else {
        return $char;
    }
}

sub caesar {
    my ($in, $key) = @_;
    my @inchars = split //, $in;
    my @outchars = map { shiftchar($_, $key) } @inchars;
    return join '', @outchars;
}
