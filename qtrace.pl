#!/usr/bin/perl

## REQUIREMENTS:
## NB! NB! NB!	hping-1s (must be recompiled hping with setuid support,1sec timeout - setuid)
## Note: remember to allow icmp type 11 into your network!
##

###
#Sub Routines
###

###############
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
######################
sub dec2bin
{
        my $str = unpack("B32", pack("N", shift));
        $str =~ s/^0+(?=\d)//;
        my $RetStr = "";
        for ($i=0; $i< 8 - length($str); $i++) {
                $RetStr=$RetStr."0";    
        }
        $RetStr = $RetStr.$str;
        return $RetStr;
}
########################
sub bin2dec
{
        return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}
########################
sub findnet
{
        $classc = "";
        ($iptouse) = @_; 
        if (!($iptouse =~ /127.0.0.1/))
        {
                @splitter=split(/\./,$iptouse);
                $classc=@splitter[0].".".@splitter[1].".".@splitter[2];
        }
        return ($classc);
} # findnet
########################
sub rampup{
        ($passed,$ttl,$top)=@_;
        my $flag=0;
        my $i=$ttl;
        if ($ttl==0){$i=$top;}
        while (($flag==0) || ($i<1)){
                my @res=`hping-1s -2 -t $i $passed -n -c 2 -p 53 2>&1`;
                foreach my $line (@res){
                        if ($line =~ /TTL/){
                               ($crap,$want)=split(/=/,$line);
                                $want =~ s/ //g; chomp $want;
                                if ($want ne $passed) {
                                        return ($i,$want);
                                }
                        }
                }
                $i--;
        }
return 0;
}
# ------------------------

###
#Main Program starts here
###
$|=1;

	if($#ARGV<1){die "qtrace.pl <inputfile_with_ips> <outputfile>\n"; }
	$file  = @ARGV[0];
	$deel="32";
	$acc="2";
	$outfile = @ARGV[1];

open (IN,"$file") || die "Cant open input file please check\n";

	##command line mode
	open (IN,"$file") || die "Cant open the IP file\n";
	while (<IN>){
		chomp;
		if ($_ !~ /\./){print "$_ Not an IP number $_\n";}
		else {push @IPS,$_;}
	}
close (IN);

##ok rest is pretty generic..

#check for usage problems
if (($deel !=4 ) && ($deel != 8) && ($deel != 16) && ($deel != 32) && ($deel != 64)){
	die "Duh - i said 4,8,16,32 or 64!!\n";
}
if (($acc > 4) || ($acc<0)) {
	die "Duh - accuracy is 0-4! Go away! LEave! Shoo!!\n";
}
	
#first ramp up...
foreach $ip (@IPS){
	#defaults
	$lowerbound=&findnet($ip).".0";
	$upperbound=&findnet($ip).".255";

	#check the file if our IP falls within a range we already had
	if (open (NETS,"$outfile")){
		$exitflag=0;
		while (<NETS>){
			chomp;
			#for wrapper..
			$_ =~ s/[\>\<\#]//g;
			($startip,$endip)=split(/\-/,$_);
			$startiplong = ip2long($startip);
			$endiplong = ip2long($endip);
			$ouriplong= ip2long($ip);
                      
		if (($startiplong <= $ouriplong) && ($endiplong >= $ouriplong)){
				$exitflag=1;
			}

		}
	}

	##it doesn't..we have to test..
	if ($exitflag==0){

		$thing=&findnet($ip);
		($rampup,$duh)=rampup("$thing.1",0,25);
		print "Done ramping - [$rampup]\n";	
		#### go down from here.
		my ($crap,$crap,$crap,$want)=split(/\./,$ip);
		
		$count=0;
		for ($i = $deel*int($want/$deel); $i >= 0; $i=$i-$deel){
	
			$value=$i+1;
			$totrace=&findnet($ip).".".$value;
		
			$pieceres="";
			for (1..3){
				($duh,$lh)=rampup($totrace,$rampup+$acc,0);
				chomp $lh;
				$pieceres=$pieceres.$lh." ";
			}
	
			@allres[$count]=$pieceres;
	
			if ($count > 0){
				@one=sort(split(/ /,@allres[$count]));
				@two=sort(split(/ /,@allres[$count-1]));
	
				$neqsum=0;
		        	for (0..2){
	        	        	if (@one[$_] ne @two[$_]) {$neqsum++;}
			        }
		        	if ($neqsum >= 3){
			                $boundary=&findnet($ip).".".($i+$deel);
					$lowerbound=$boundary;
					last;
			        }
			}
			$count++;
		}
		
		print "$ip - lower boundary is $lowerbound\n";
			
		## find upper boundary
	
		$count=1;
		for ($i = $deel*(1+(int($want/$deel))); $i < 256; $i=$i+$deel){
	
			$value=$i+1;
			$totrace=&findnet($ip).".".$value;
		
			$pieceres="";
			for (1..3){
				($duh,$lh)=rampup($totrace,$rampup+$acc,25);
				chomp $lh;
				$pieceres=$pieceres.$lh." ";
			}
	
			@allres[$count]=$pieceres;
	
			#we can test anyhow..we have boundary from previous step
			@one=sort(split(/ /,@allres[$count]));
			@two=sort(split(/ /,@allres[$count-1]));
	
			$neqsum=0;
	        	for (0..2){
	       	        	if (@one[$_] ne @two[$_]) {$neqsum++;}
		        }
	        	if ($neqsum >= 3){
		                $boundary=&findnet($ip).".".($i);
				$upperbound=$boundary;
				last;
		        }
			$count++;
		}
	
		print "$ip - upper bound is $upperbound\n\n";
		
	open (OUT,"+>>$outfile") || die "Cant create output file\n";		
			print OUT "$lowerbound\-$upperbound\n";
		close (OUT);
	}
}
close (OUT);
print("Sleeping 10\n");
print("close 2\n");
