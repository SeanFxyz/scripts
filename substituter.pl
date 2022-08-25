#!/usr/bin/env perl

use utf8;
use bignum;

sub addLetter{
    $output = $output . chr($_[0]+64);
}

sub addNumber{
    $output = "$output" . (ord(uc($_[0]))-64)
}

sub substitute{
    my $cipher = $_[0];
    if(!($decode)){
        for($i=0; $i<length($cipher); $i++) {
            if(substr($cipher,$i,1) =~ /([0-9])/){
                if(substr($cipher,$i,2) =~ /([0-9][0-9])/){
                    $i++;
                    &addLetter($1);
                }
                else{
                    &addLetter($1);
                }
            }
            elsif(substr($cipher,$i,1) ne '-'){
                $output = $output . substr($cipher,$i,1);
            }
        }
    }
    else{
        for($i=0; $i<length($cipher); $i++){
            if(substr($cipher,$i,1) =~ /([a-zA-Z])/){
                &addNumber($1);
                if($i < length($cipher)-1){
                    $output = $output . '-';
                }
            }
        }
    }
    print "$output\n";
}


if($ARGV[0] eq '-d' or $ARGV[0] eq '--decode'){
    $decode=1;
    shift @ARGV;
}
$input = join(' ', @ARGV);

if($input eq ''){
    while(chomp($line=<STDIN>)){
        &substitute($line);
    }
}
else{
    &substitute($input);
}
