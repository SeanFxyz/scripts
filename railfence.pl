#!/usr/bin/env perl

# Decrypts/Encrypts/Brute-forces Rail Fence ciphers
# Usage:
# 	railfence [-d] rails [message]
# 	railfence -b
#
# 'rails' is essentially the cipher key, a non-negative number of 'fence rails'
#
# If the message is not provided, standard input will be encrypted or decrypted.
#
# -d
# 	Decrypt the message (default is encrypt)
#
# -b
# 	Decrypt with all possible keys for the message (between 2 and the message length)

#use warnings;
use strict;
use utf8;

my $decrypt = 0;
my $reverse = 0;
my $brute = 0;

for my $i (0..$#ARGV){
	my $arg=$ARGV[$i];
	if($arg eq '-d'){
		shift @ARGV;
		$decrypt=1;
	}
	elsif($arg eq '-b'){
		shift @ARGV;
		$brute=1;
	}
}

if($decrypt){
	if($ARGV[1]){
		print decrypt($ARGV[0], $ARGV[1]) . "\n";
	} else{
		while(<STDIN>){
			chomp;
			print decrypt($ARGV[0], $_) . "\n";
		}
	}
} elsif($brute){
	if($ARGV[0]){
		brute($ARGV[0]);
	} else{
		while(<STDIN>){
			chomp;
			brute($_);
		}
	}
} else{
	if($ARGV[1]){
		print encrypt($ARGV[0], $ARGV[1]) . "\n";
	} else{
		while(<STDIN>){
			chomp;
			print encrypt($ARGV[0], $_) . "\n";
		}
	}
}

sub encrypt{
	my ($key, $plain) = @_;
	$key = int($key);
	my @plainChars = split //, $plain;
	my @rows;
	my $row = 0;
	my $d = 1;
	my $cipher;
	for my $plainChar (@plainChars){
		$rows[$row] .= $plainChar;
		if($d){
			$row++;
			if($row >= $key){
				$row = $key-2;
				$d = 0;
			}
		} else{
			$row--;
			if($row <= 0){
				$row = 0;
				$d = 1;
			}
		}
	}
	if($reverse){
		@rows = reverse @rows;
	}
	return join('', @rows);
}

sub decrypt{
	my ($key, $cipher) = @_;
	$key = int $key;
	my @cipherChars = split //, $cipher;
	my $cycle = $key * 2 - 2;
	my $width = sprintf("%d", scalar(@cipherChars) / $cycle);
	my $spares = $cycle * (scalar(@cipherChars) / $cycle - $width);
	my @rows;
	my $ch = 0;
	my $plain;

	for my $row (0..$key-1){
		my $rowLength = $width;
		if($row != 0 && $row != $key-1){
			$rowLength *= 2;
		}
		if($spares >= $row + 1){
			$rowLength++;
			if($spares >= $key + $key - $row - 1){
				$rowLength++;
			}
		}
		my $rowEnd = $ch + $rowLength - 1;
		while($ch <= $rowEnd){
			$rows[$row] .= $cipherChars[$ch];
			$ch++;
		}
	}

	print join("\n", @rows) . "\n";

	my $plainChar;
#	while(length $plain < scalar @cipherChars){
	while(<STDIN>){
		print length($plain) . "\n";
		print "$plain\n";
		for(my $row = 0; $row <= $#rows; $row++){
			$plain .= (split(//, $rows[$row]))[$plainChar];
		}
		$plainChar++;
		for(my $row = $#rows-1; $row >= 1; $row--) {
			$plain .= (split(//, $rows[$row]))[$plainChar];
		}
		$plainChar++;
	}
	return $plain;
}

sub brute{
	print "Bruteforce not implemented.\n";
}
