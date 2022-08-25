#!/usr/bin/env perl

use utf8;

@alpha=qw( z y x w v u t s r q p o n m l k j i h g f e d c b a );

sub atbash{
    my $cipher=$_[0];
    for($i=0; $i<length($cipher); $i++){
        if(substr($cipher, $i, 1) =~ /[a-zA-Z]/){
            substr($cipher, $i, 1) = $alpha[ord(substr((uc $cipher), $i, 1))-65];
        }
    }
    print "$cipher\n";
}

$args = join(' ', @ARGV);
if($args eq ''){
    while($line=<STDIN>){
        chomp $line;
        &atbash($line);
    }
}
else{
    &atbash($args);
}
