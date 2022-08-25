#!/usr/bin/env perl

#use warnings;
use strict;
use utf8;
use List::Util ('first');

my $help="Encrypts, decrypts, or brute-forces a Vigenere cipher
Usage: vignere.pl [-s] [-h] [--help] command keyword [text]

Commandline flags can be anywhere in the command, but 'command', 'keyword', and 'text' parameters must be in order.

'command' can be either 'encrypt' or decrypt.

If the 'text' parameter is not present, standard input will be used instead.

bruteforce output appears as follows, depending on options
[match-percent:][match-count:][key:]candidate

OPTIONS

-s
	show polyalphabetic key

-h,--help
	Show help text

-a alphabet
	Set custom alphabet for cipher. Default value is the English alphabet 'abcdefghijklmnopqrstuvwxyz'

BRUTEFORCE OPTIONS:

-Dw dictionary
	Selects the dictionary file in which to search for common words that will be searched for in possible plaintexts.

-Dk dictionary
	Selects the dictionary file containing possible keys to use instead of generating brute force keys

-l length, --length length
	Specifies the maximum length of key to test. If -Dk is used, keys from the key dictionary longer than this length will be skipped. Otherwise, keys will be generated [not yet implemented] until this length is reached.

-Lr
	Line reset; Resets the key character index on each line. Use this if reading from stdin and want to treat each line as a separate cipher/plaintext. Without this option, all lines from stdin will be treated as part of the same cipher/plaintext

-Hk
	Hide key; Do not display the key used alongside plaintext candidates. Recommended for piping output into another instance of this script or another similar ciphering tool.

-Mw
	Count matching words. Separates each candidate into words, using any characters not in the alphabet as delimiters, then compares each word against the provided dictionary.

-Mp Generate match percentages. Calculates the percentage of each plaintext candidate that matches against dictionary words.
";

#Set the default hash values for numLookup and charLookup
my %numLookup;
my %charLookup;
&setAlpha('abcdefghijklmnopqrstuvwxyz');
my $alphaSize = scalar(keys %numLookup);

# brute-force-specific options
my $maxKeyLength;
my $showKey = 1;
my $Dk; # name of file to compare with plaintext candidates
my $Dw; # name of file to compare with plaintext candidates
my $Mw = 0; # calculate match counts t/f
my $Mp = 0; # calculate match percentages t/f

my @commandargs;
my @chars; # characters to encrypt or decrypt
my $keyIndex = 0;
my $lineReset = 0; # if true, each new line is treated as a new cipher

# Parsing commandline arguments
# Parsing options and gathering command and arguments into their own array
for(my $arg = 0; $arg < scalar(@ARGV); $arg++){
	if($ARGV[$arg] eq '-s' || $ARGV[$arg] eq '--show'){my $show_square=1;}
	elsif($ARGV[$arg] eq '-a'){&setAlpha($ARGV[$arg+1]); $arg++;}
	elsif($ARGV[$arg] eq '-h' || $ARGV[$arg] eq '--help'){print($help); exit;}
	elsif($ARGV[$arg] eq '-l' || $ARGV[$arg] eq '--length'){$maxKeyLength=$ARGV[$arg+1]; $arg++;}
	elsif($ARGV[$arg] eq '-Dk'){$Dk=$ARGV[$arg+1]; $arg++;}
	elsif($ARGV[$arg] eq '-Dw'){$Dw=$ARGV[$arg+1]; $arg++;}
	elsif($ARGV[$arg] eq '-Lr'){$lineReset=1;}
	elsif($ARGV[$arg] eq '-Mw'){$Mw=1;}
	elsif($ARGV[$arg] eq '-Mp'){$Mp=1;}
	elsif($ARGV[$arg] !~ /^-/){push(@commandargs,($ARGV[$arg]));}
	else{die("Error: invalid option");}
} 

if($commandargs[0] eq 'e' || $commandargs[0] eq 'encrypt'){
	# check number of command arguments
	if(scalar(@commandargs) > 3){die("Error: too many command arguments.\n");}
	if(scalar(@commandargs) < 2){die("Error: too few command arguments.\n");}
	
	if(&keyIsValid($commandargs[1])){
		if($commandargs[2]){
			@chars = split(//, $commandargs[2]);
			print &encrypt($commandargs[1]) . "\n";
		} else{
			while(<STDIN>){
				@chars = split(//, $_);
				print &encrypt($commandargs[1]);
			}
		}
	} else{die "Error: key contains character(s) not in alphabet";}
} elsif($commandargs[0] eq 'd' || $commandargs[0] eq 'decrypt'){
	# check number of command arguments
	if(scalar(@commandargs) > 3){die("Error: too many command arguments.\n");}
	if(scalar(@commandargs) < 2){die("Error: too few command arguments.\n");}
	
	if(&keyIsValid($commandargs[1])){
		if($commandargs[2]){
			@chars = split(//, $commandargs[2]);
			print &decrypt($commandargs[1]) . "\n";
		} else{
			while(<STDIN>){
				@chars = split(//, $_);
				print &decrypt($commandargs[1]);
			}
		}
	} else{die "Error: key contains character(s) not in alphabet";}
} elsif($commandargs[0] eq 'b' || $commandargs[0] eq 'brute' || $commandargs[0] eq 'bruteforce'){
	# check number of command arguments
	if(scalar(@commandargs) > 2){die("Error: too many command arguments.\n");}
	if(($Mw || $Mp) && !$Dw){
		die("Error: a matching option was selected, but no dictionary was provided");
	}

	if($commandargs[1]){
		@chars = split(//, $commandargs[1]);
		&brute();
	} else{
		while(@chars = split(//, <STDIN>)){
			&brute();
		}
	}
} elsif($commandargs[0] eq 'w' || $commandargs[0] eq 'word' || $commandargs[0] eq 'words'){
	if(scalar(@commandargs) > 2){die("Error: too many command arguments.\n");}
	
	if($commandargs[1]){
		print join(' ', &words($commandargs[1])) . "\n";
	} else{
		while(<STDIN>){
			chomp;
			print join(' ', &words($_)) . "\n";
		}
	}
} else{
	die("Error: invalid command argument");
}



sub setAlpha{
	# Check for duplicate characters in the provided alphabet string
	my @alphaChars = split(//, $_[0]);
	my @dupChar; # list of duplicate characters
	for my $alphaChar (@alphaChars){
		if(scalar(grep(/$alphaChar/, @alphaChars)) != 1){
			push(@dupChar,($alphaChar));
		}
	}
	if(scalar(@dupChar) > 0){
		die('Error: Duplicate characters in custom alphabet.
\	\	\	Alphabet: ' . join(' ', (keys(%numLookup))) . "\nDuplicates: @dupChar\n");
	}

	# map the alphabet characters to a hash so we can look up
	# a given character's index in the alphabet
	%numLookup = map { $alphaChars[$_] => $_ } 0..$#alphaChars;

	# create a reverse lookup hash so we can identify a character
	# by its index in the alphabet
	%charLookup = reverse %numLookup;
}

# verify that the keyword contains no characters not in the alphabet
sub keyIsValid{
	my @keyChars = split(//, $_[0]);
	for my $keyChar (@keyChars){
		if(!exists $numLookup{$keyChar}){
			return 0;
		}
	}
	return 1;
}

sub encrypt{
	my $keyLength = length($_[0]); # length of key
	my @keyChars = split(//, $_[0]); # characters of the key
	my @cipherChars; # characters of the output ciphertext
	my $num;
	for my $char (@chars){
		# check if current ciphertext character is in the alphabet
		if(length($num = $numLookup{$char})){
			# find the character that corresponds to the alphabetical index of the plaintext 
			# character minus the alphabetical index of the key character and add it to the 
			# ciphetext
			push(@cipherChars, $charLookup{ ( $num + $numLookup{$keyChars[$keyIndex % $keyLength]} ) % $alphaSize });

			# make sure we're using the next character in the key to
			# decrypt the next ciphertext character
			$keyIndex++;
		} else{
			push(@cipherChars, $char);
			# no need to increment keyIndex, the ciphertext character 
			# cannot be translated
		}
	}
	if(defined $lineReset){$keyIndex = 0;} # if line reset option enable, treat next line as a separate cipher
	return(join('', @cipherChars));
}

sub decrypt{
	my $keyLength = length($_[0]); # length of key
	my @keyChars = split(//, $_[0]); # characters of the key
	my @plainChars; # characters of the output plaintext
	my $num;
	for my $char (@chars){
		# check if current ciphertext character is in the alphabet
		if(length($num = $numLookup{$char})){
			# find the character that corresponds to the alphabetical index of the ciphertext 
			# character minus the alphabetical index of the key character and add it to the 
			# plaintext
			push(@plainChars, $charLookup{ ( $num - $numLookup{$keyChars[$keyIndex % $keyLength]} ) % $alphaSize });
			# make sure we're using the next character in the key to
			# decrypt the next ciphertext character
			$keyIndex++;
		} else{
			push(@plainChars, $char);
			# no need to increment keyIndex, the ciphertext character 
			# cannot be translated
		}
	}
	if($lineReset){$keyIndex = 0;}
	return(join('', @plainChars));
}

sub brute{
	my @keys;
	my $candidate;
	$lineReset = 1;
	if($Dk){
		open(my $Dkh, '<:encoding(UTF8)', $Dk) or die("Could not open key dictionary");
		while(<$Dkh>){
			chomp;
			push(@keys, $_);
		}
		if($Mp && $Mw){
			for my $key (@keys){
				if(&keyIsValid($key)){
					$candidate = &decrypt($key);
					my $pm = &percentMatched($candidate);
					my ($matchCount, $wordCount) = &matchCount($candidate);
					print(sprintf("%013.9f", $pm) . ":");
					print(sprintf("%0" . length($wordCount) . "d", $matchCount) . ":");
					print("$key:$candidate\n");
				}
			}
		} elsif($Mp){
			for my $key (@keys){
				if(&keyIsValid($key)){
					$candidate = &decrypt($key);
					my $pm = &percentMatched($candidate);
					print(sprintf("%013.9f", $pm) . ":$key:$candidate\n");
				}
			}
		} elsif($Mw){
			for my $key (@keys){
				if(&keyIsValid($key)){
					$candidate = &decrypt($key);
					my ($matchCount, $wordCount) = &matchCount($candidate);
					print(sprintf("%0" . length($wordCount) . "d", $matchCount) . ":$key:$candidate\n");
				}
			}
		} else{
			for my $key (@keys){
				if(&keyIsValid($key)){
					$candidate = &decrypt($key);
					print("$key:$candidate\n");
				}
			}
		}
	}
}

# Divides string into words, returns number of words matching the dictionary
# and total words in the string.
sub matchCount{
	my $string = $_[0];
	my @dwords;
	my $matchCount = 0;
	my @words = &words($string);
	for my $word (@words){
		open(my $Dwh, '<', $Dw) or die("Could not open word dictionary");
		while(<Dwh>){
			chomp;
			push(@dwords, $_);
		}
		for my $dword (@dwords){
			if($dword eq $word){
				$matchCount++;
				last;
			}
		}
	}
	return $matchCount, scalar(@words);
}

# Divides string into words, using characters not in the assigned
# alphabet as delimiters.
sub words{
	my $string = $_[0];
	my $alpha = join(//, keys(%numLookup));
	return split(/[^$alpha]+/, $string);
}

sub ordered_combinations
{
	my ($data, $k) = @_;

	return if $k < 1;

	my $results = $data;

	while (--$k) {
		my @new;
		for my $letter (@$data) {
			push @new, map { $letter . $_ } @$results;
		} # end for $letter in @$data

		$results = \@new;
	} # end while --$k is not 0
	return @$results;
}

# find percent of a string that matches against words from word dictionary
# (pretty useless and stupid once you think about it)
sub percentMatched{
	my $string = $_[0];
	my $stringLen = length($string);
	my $dword;
	my $dwordLen;
	my $matchedChars = 0;
	open(my $Dwh, '<', $Dw) or die("Could not open word dictionary");
	while($dword = <$Dwh>){
		chomp $dword;

		$dwordLen = length($dword);
		my @matches;
		for my $i (0..$dwordLen-1){@matches[$i]=0;}

		for(my $i = 0; $i < $stringLen - $dwordLen; $i++){
			if(substr($string, $i, $i+$dwordLen) eq $dword){
				for(my $j = $i; $j < $i + $dwordLen; $j++){
					$matches[$j] = 1;
				}
			}
		}

		for my $i (@matches){
			if($i){
				$matchedChars++;
			}
		}
	}
	return ($matchedChars/$stringLen)*100;
}
