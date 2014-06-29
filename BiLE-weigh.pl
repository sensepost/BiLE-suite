#!/usr/bin/perl

## perl BiLE-weigh.pl domain.com outputfile.mine
## Takes output file *.mine from BiLE.pl
## domain.com is the website domain

$|=1;

@exceptionlist=("microsoft.com","216.239.5","yahoo.com",
		"ultraseek.com","ananzi.co.za","macromedia.com",
		"clickstream","w3.org","adobe.com","google.com");

if ($#ARGV < 1){die "perl BiLE-weigh.pl domain.com output.file.from.bile.mine\n";}

#load and init 
`cat @ARGV[1] | sort | uniq > @ARGV[1].2`;
`mv @ARGV[1].2 @ARGV[1]`;
open (IN,"@ARGV[1]") || die "Cant open data file\n";
while (<IN>){
	chomp;
	($src,$dst,$cellid)=split(/:/,$_);
	if ($src ne $dst){
		$flag=0;
		foreach $except (@exceptionlist){
			if (($src =~ /$except/) || ($dst =~ /$except/)) {$flag=1;}
		}
		if ($flag == 0){push @structure,$_;}
	}
}
close(IN);


$sites{@ARGV[0]}=300;


####################compute first cell node values
print "compute nodes\n";
print "Nodes alone\n";
$ws=weight(@ARGV[0],"s");
$wd=weight(@ARGV[0],"d");
print "src $ws dst $wd\n";
foreach $piece (@structure){

	
	($src,$dst,$cellid)=split(/:/,$piece);

	## link -from- X to node 
	if ($src eq @ARGV[0]){
		$newsites{$dst}=$newsites{$dst}+($sites{$src}*(1/$ws));
	}

	## link -to- X from node 
	if ($dst eq @ARGV[0]){
		$newsites{$src}=$newsites{$src}+($sites{$dst}*(0.6/$wd));
	}
}

&writenodes;


undef $sites;
undef %sites;
&loadnodes;

#between nodes
foreach $blah (keys %sites){
	print "\n[Testing with node $blah]\n";
	$ws=weight($blah,"s");
	$wd=weight($blah,"d");
	print "src $ws dst $wd\n";	
	foreach $piece (@structure){

		($src,$dst,$cellid)=split(/:/,$piece);
		
		## link -from- node to other node (2/3)	
		if ($src eq $blah){
			$newsites{$dst}=$newsites{$dst}+($sites{$src}*(1/$ws));
			$add=($sites{$src}*(1/$ws));
			$orig=$sites{$src};
		}

		## link -to- node from nodes (1/3)
		if ($dst eq $blah){
			$newsites{$src}=$newsites{$src}+($sites{$dst}*(0.6/$wd));

                        $add=($sites{$dst}*(0.6/$wd));
                        $orig=$sites{$dst};
		}
	}

}

&writenodes;

`cat temp | sort -n -r -t: -k2 > @ARGV[1].sorted`;


sub loadnodes{
	$sites="";
	open (IN,"temp") || die "cant open temp file\n";
	while (<IN>){
		chomp;
		($node,$value)=split(/:/,$_);
		$sites{$node}=$value;
	}
	close (IN);
}

sub writenodes{
	open (OUT,">temp") || die "Cant write\n";
	foreach $blah (keys %newsites){
		print OUT "$blah:$newsites{$blah}\n";
	}
	close OUT;
}

sub weight{
	($site,$mode)=@_;
	$from=0; $to=0;
	foreach $piece (@structure){
		($src,$dst,$cellid)=split(/:/,$piece);
		if ($dst eq $site){$from++};
		if ($src eq $site){$to++;}
	}
	if ($mode eq "s"){return $to;}
	if ($mode eq "d"){return $from;}
}
