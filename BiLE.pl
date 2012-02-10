#!/usr/bin/perl

### perl BiLE.pl web.site.com output.name
### BiLE will out put two files *.mine and *.walrus
### *.walrus can be ignored for now

use Socket;
$|=1;

if ($#ARGV<1){die "Usage BiLE.pl <site> <outfile>\n";}
$tocheck=@ARGV[0];

@links=getlinks($tocheck,4,0);
push @links,&linkto($tocheck,0);

undef @lotsoflinks;

foreach $link (@links){
        if ($link ne $tocheck){
                push @lotsoflinks,&linkto($link,1);
                push @lotsoflinks,&getlinks($link,3,1);
        }
}

  

###
##SubRoutines
###

sub linkto{
	my ($tocheck,$cellid)=@_;
	if (length($tocheck<3)){return "";}
	my @returns=("");

	undef @global;

	@global=dedupe(returngoogle("link:$tocheck","web")); 
	foreach $taa (@global){print "[$taa]\n";}

	open (OUT,">>@ARGV[1].mine") || die "cant open out file\n";
	open (OUTT,">>@ARGV[1].walrus") || die "cant open walrus file\n";
	print OUT "----> Links to: [$tocheck]\n";
	foreach $site (@global){
		($site,$crap)=split(/[\`\!\@\#\$\%\^\&\*\(\)\=\\\|\+\[\]\'\>\<\/\?\,\"\' ]/,$site);
		if (($site =~ /\./) && (length($site)>2) && ($site !~ /shdocvw/)) {
			print OUT "$site:$tocheck\n";
			print OUTT "$tocheck:$site\n";
			push @returns,$site;
		}
	}  
	close (OUT);
	close(OUTT);
	return (@returns);
}

#################################
sub getlinks{
	
	my @return=("");
	my @global=("");

	($site,$depth,$cellid)=@_;
	if (length($site)<3){return "";}
	print "mirroring $tocheck\n";
	$rc=system("rm -Rf work");
        $mc="httrack $site --max-size=350000 --max-time=600 -I0 --quiet --do-not-log -O work.$site --depth=$depth -%v-K -*.gif -*.jpg -*.pdf -*.zip -*.dat -*.exe -*.doc -*.avi -*.pps -*.ppt 2>&1";
        $rc=system ($mc);
	

	#HTTP hrefs
	@res=`grep -ri "://" work.$site/*`;
	
	foreach $line (@res){
	        ($file,$crap,$stuff)=split(/:/,$line);
        	($crap,$getit,$crap)=split(/\//,$file);
		($crap,$want)=split(/\/\//,$stuff);

		($want,$crap)=split(/\//,$want);
		($want,$crap)=split(/\"/,$want);
		($want,$crap)=split(/\>/,$want);
		($want,$crap)=split(/\</,$want);
		($want,$crap)=split(/[\`\!\@\#\$\%\^\&\*\(\)\=\\\|\+\[\]\'\>\<\/\?\,\"\']/,$want);
		$want =~ s/\[\]\;//g;
		 if ((length($want)>0) && ($getit ne $want)) {
			if (($want =~ /\./) && (length($want)>2) && ($want !~/shdocvw/) &&
			    ($want !~ /[\`!\@\#\$\%\^\&\*\(\)\=\\\|\+\[\]\'\>\<\/\?\,\"]/)) {
				$store="$site:$want";
			        push @global,$store;
				push @return,$want;
			}
		 }
	}

	 ## To get mailtos:
        @res=`grep -ri "\@" work.$site/*`;
        foreach $line (@res){
                ($crap,$want)=split(/\@/,$line);
                ($want,$crap)=split(/[ ">\n?<']/,$want);
                ($left,$right)=split(/\./,$want);
                if ( ($want =~ /\./) && (length($want)>3) && (length($right)> 1) && ($want !~/shdocvw/)){
			($want,$crap)=split(/[\`\!\@\#\$\%\^\&\*\(\)\=\\\|\+\[\]\'\>\<\/\?\,\"\']/,$want);
                        $store="$site:$want";
                        push @global,$store;
                        push @return,$want;
                }
        }


	@global=dedupe(@global);

	open (OUT,">>@ARGV[1].mine") || die "cant open out file\n";
        open (OUTT,">>@ARGV[1].walrus") || die "cant open walrus file\n";
	print OUT "====> Link from: [$site]\n";
	foreach $site (@global){
			print OUT "$site\n";
			print OUTT "$site\n";
	}
	close (OUT);
	close(OUTT);

#	$rc=system("rm -Rf work");
	return (dedupe(@return));
}



#############Putting it together.
sub returngoogle{
 ($term,$type)=@_;
 if ($type eq "web") {$gtype="search"; $host="www.google.com";}
 if ($type eq "news") {$gtype="groups"; $host="groups.google.com";};
 if ($term !~ /link\:/){
  $term="%2b".$term;
  $term=~s/\./\.\%2b/g;
  $term=~s/ /+/g;
 }
 $port=80; $target = inet_aton($host);
 $enough=numg($term,$gtype);
 print "The number is $enough\n";
 undef @rglobal;
 for ($i=0; $i<=$enough; $i=$i+100){
 	print "tick $i\n";
	@response=sendraw("GET /$gtype?q=$term&num=100&hl=en&safe=off&start=$i&sa=N&filter=0 HTTP/1.0\r\n\r\n");

	undef @collect;

	@collect=googleparseweb(@response);
	foreach (@collect){
		print "[$_]\n";
		push @rglobal,$_;
	}
 }
 return @rglobal;
}

############find out how many request we must do
sub numg{
 ($theterm,$gtype)=@_;
 @response=sendraw("GET /$gtype?q=$theterm&num=10&hl=en&safe=off&start=10&sa=N&filter=0 HTTP/1.0\r\n\r\n");
 $flag=0;
 foreach $line (@response){
  if ($line =~ /of about/){
   ($duh,$one)=split(/of about \<b\>/,$line);
   ($two,$duh)=split(/\</,$one);
   $flag=1;
   last;
  }
  #single reply
  if ($line =~ /of \<b\>/){
   ($duh,$one)=split(/of \<b\>/,$line);
   ($two,$duh)=split(/\</,$one);
   $flag=1;
   last;
  }
 }
 if ($flag==0){return 0;}
 for ($r=0; $r<=1000; $r=$r+100){
  if (($two>$r) && ($two<100+$r)) {$top=$r+100;}
 }
 if (($two>1000) || ($two =~ /\,/)) {
  $top=1000;
  print "Over 1000 hits..\n";
 }

 print "Received $two Hits - Google for $top returns\n";  
 return $top;
}

###########Parse for web stuff
sub googleparseweb{

 my @googles;

 foreach $line (@_){
  if ($line =~ /http/){
   (@stuffs)=split(/\/\//,$line);
   foreach $stuff (@stuffs){
	($want,$crap)=split(/\//,$stuff);
	if (($want !~ /</) && ($want !~ /google/)){push @googles,$want;}
   }
  }
 }
 return dedupe(@googles);
}


###########Good old old sendraw
sub sendraw { 
 my ($pstr)=@_;
 socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp')||0) || return "";
 if(connect(S,pack "SnA4x8",2,$port,$target)){
  my @in="";
  select(S); $|=1; print $pstr;
  while(<S>) { 
   push @in,$_; last if ($line=~ /^[\n\r]+$/ );
  }
  select(STDOUT); 
  return @in;
 } else { return ""; }
}


#########################-- dedupe
sub dedupe
{
        (@keywords) = @_;
        my %hash = ();
        foreach (@keywords) {
                $_ =~ tr/[A-Z]/[a-z]/;
                chomp;
                if (length($_)>1){$hash{$_} = $_;}
        }
        return keys %hash;
} #dedupe



