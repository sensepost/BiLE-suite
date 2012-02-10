#!/usr/bin/perl

####
#### Usage: perl vet-IPrange.pl Input_file True_file Output_file [range]
#### Input_File: list of websites to to checked
#### True_File: list of websites to be checked against
#### Out_file: list of websites where the A record match (within range)
#### [Range: optional (defaults to 32). Range of match]
####

use Net::DNS;
$res= Net::DNS::Resolver->new();

###
#Sub Routines
###
sub uniq(@){
#	----------------------------
	my %seen = ();
	return grep { ! $seen{$_} ++ } @_;	}
#       -----------------------------
sub ip2long
{
        my @ips = split (/\./, $_[0]);
        my $binNum = "";
        foreach $tuple (@ips) {
                $binNum = $binNum.dec2bin($tuple);
        }
        $BigNum = bin2dec($binNum);
        return ($BigNum);
}
#########
sub dedupe(@){return uniq map { lc $_ } @_;}

#	----------------------------
sub dec2bin{
#	----------------------------
	my $str		= unpack( "B32", pack( "N", shift ) );
	$str		=~ s/^0+(?=\d)//;
	my $RetStr	= "";
	for ( my $i=0 ; $i < 8-length $str ; $i++ ) {
	 	$RetStr= $RetStr . "0";}
	$RetStr= $RetStr . $str;
	return $RetStr;
	}

sub bin2dec{
#	----------------------------
	return unpack "N", pack "B32", substr "0" x 32 . shift, -32;
	}

#	----------------------------

sub forward {
        ($passed,$mode)=@_;
        undef @returns;
        @nslookupout=`nslookup -timeout=$DNSTIMEOUT -retry=$DNSRETRY $passed $nameserver 2>&1;`;
        my $flag=0;
        foreach $line (@nslookupout){
                if (($line =~ /$passed/) && ($line !~ /can't find/)){$flag=1;}
                if ($line =~ /Address/){
                        ($duh,$returner,@crap)=split(/s: /,$line);
                }
        }
        $returner=~s/ //g;
        if ($flag==1){
                @ips=split(/,/,$returner);
                foreach $ips (@ips){
                        chomp $ips;
                        $ips=~s/ //g;
			$passed=~s/ //g;
                        $tosave=$ips;
                        if ($mode==0){push @returns,$tosave;}
                        if ($mode==1){
                                $work=$passed.";".$tosave;
                                push @returns,$work;
                        }
                        if ($mode==2){
                                $work=$passed.";".$tosave.";FL";
                                push @returns,$work;
                        }

                }
        }
        return @returns;
}
# --------------
###
#Main Program starts here
###

$|=1;

if ($#ARGV<2){die "vet-IPrange.pl inputfile truefile output [range]\n";}

if (@ARGV[3]==0){$range=32;} else {$range=@ARGV[3];}

open (IN,"@ARGV[0]") || die "Cant read input file\n";
open (TRUE,"@ARGV[1]") || die "Cant read true file\n";

##load files
while (<IN>){chomp; 	push @list,$_;}
close (IN);

while (<TRUE>){	chomp;	push @trues,$_;}
close (TRUE);	


#### get a list of the confirmed IPs
foreach $domain (@trues){
	@arecords=forward($domain,0);
	foreach $quick (@arecords){push @realips,$quick;}
}
@realips=dedupe(@realips);
print "All IPs are [@realips]\n";

#### now compare the others
foreach $entry (@list){

	@ips=forward($entry,0);
	print "Working on [$entry]\n";

	#check it
	$flag=0;
	foreach $quick (@realips){
		$realinbig=&ip2long($quick);
		foreach $ip (@ips){
			$ipinbig=&ip2long($ip);
			if (abs($ipinbig-$realinbig) < $range){
				$flag=1;
			}
		}
	}
	if ($flag==1){
		print "The host $entry match!\n";
		push @results,$entry;
	}
}

@results=dedupe(@results);
foreach $entry (@results){
	#logger(2,"$entry\n");
}

close (OUT);

	
