#!/usr/bin/perl

#use diagnostics;		
#use Data::Dumper;				# Data struct debugging
#use Getopt::Long qw( HelpMessage VersionMessage :config default no_ignore_case );	
use File::Basename;				
use Net::DNS;

if ($#ARGV<1){die "Usage tld-expand.pl input.file output.file\n";}

#	----------------------------
#	Load TLDS
#
#	DNS/whois manupilations
#	----------------------------
sub loadTLDS()	{
	return dedupe(qw(	com	org     net     edu	mil	gov     uk	af	al	dz	as
				ad	ao	ai	aq	ag	ar	am	aw	ac	au	at
				az	bs	bh	bd	bb	by	be	bz	bj	bm	bt
				bo	ba	bw	bv	br	io	bn	bg	bf	bi	kh
				cm	ca	cv	ky	cf	td	cl	cn	cx	cc	co
				km	cd	cg	ck	cr	ci	hr	cu	cy	cz	dk
				dj	dm	do	tp	ec	eg	sv	gq	er	ee	et
				fk	fo	fj	fi	fr	gf	pf	tf	ga	gm	ge
				de	gh	gi	gr	gl	gd	gp	gu	gt	gg	gn
				gw	gy	ht	hm	va	hn	hk	hu	is	in	id
				ir	iq	ie	im	il	it	jm	jp	je	jo	kz
				ke	ki	kp	kr	kw	kg	la	lv	lb	ls	lr
				ly	li	lt	lu	mo	mk	mg	mw	my	mv	ml
				mt	mh	mq	mr	mu	yt	mx	fm	md	mc	mn
				ms	ma	mz	mm	na	nr	np	nl	an	nc	nz
				ni	ne	ng	nu	nf	mp	no	om	pk	pw	pa
				pg	py	pe	ph	pn	pl	pt	pr	qa	re	ro
				ru	rw	kn	lc	vc	ws	sm	st	sa	sn	sc
				sl	sg	sk	si	sb	so	za	gz	es	lk	sh
				pm	sd	sr	sj	sz	se	ch	sy	tw	tj	tz
				th	tg	tk	to	tt	tn	tr	tm	tc	tv	ug
				ua	ae	gb	us	um	uy	uz	vu	ve	vn	vg
				vi	wf	eh	ye	yu	za	zr	zm	zw	int     gs
				info    biz     su	name    coop    aero ));
	}		# end sub loadTLDS



#	----------------------------
sub loadsubTLDS()	{
#	----------------------------
	return ( "", "com", "co", "ac", "org", "net", "gov", "mil", "mod" );
	}



#	----------------------------
#	Unique
#
#	Returns the unique elements from the passed list.
#	----------------------------
sub uniq(@)		{
#	----------------------------
	my %seen		= ();
	return grep { ! $seen{$_} ++ } @_;	}



#	----------------------------
#	De-Duplicate
#
#		Returns the (case insensitive) unique elements from the passed list.
#	---------------------------
sub dedupe(@)		{
#	----------------------------
	return uniq map { lc $_ } @_;	}
#	----------------------------
sub getHostIP($;$$){my($host,$timeout,$server, )	= @_;
	$timeout	||= 3;
	my $maxcount		= 3;
	$maxcount		= $timeout if ($timeout > 0 && $timeout < 11);

	my $count					= 0;
	my @results;
	my $result;

	while ($count < $timeout && !$result) { my $query = $res->search($host);
		if ($query) {
			foreach my $rr ($query->answer()) {
				next unless $rr->type() eq "A";
				$result	= $rr->address();
				push @results, $result;	}
		return @results;	}
		$count ++;
		}
	return undef;
	}


#	----------------------------
sub mxlookup($;$)	{my( $domain, $mode, )	= @_;
			$mode ||= 0;
#	----------------------------
	my @results				= ();
	my @mxs					= mx($res, $domain);
	my $timeout				= 0;
	foreach my $mx (@mxs)	{
		next unless ( $timeout < 10);
		my $exchange			= $mx->{"exchange"};
		my @addresses			= getHostIP($exchange);
		my $address			= $addresses[0];
		my $data			= $address;
		$data				= "$exchange;$data"	if ( $mode >= 1 );
		$data				= "$data;MX"		if ( $mode >= 2 );
		$data				= "$data;$domain"	if ( $mode >= 3 );
		push @results, $data;	}
	return uniq sort grep $_, @results;
	}



#	----------------------------
#	getting domain back 1
#	----------------------------
sub piecedomain($)	{		my(	$passed, )	= @_;
#	----------------------------
	#find what TLD we are in and remove it
	my @parts				= split /\./, $passed;
	my $lastpart				= $parts[$#parts];
	my $yeah;
	
	foreach my $tld (loadTLDS())	{
		if ( $tld eq $lastpart )	{
			( $yeah, undef )	= split /\.$tld/, $passed;
			last;	}}		# end foreach my $tld (@TLDS)
	@parts					= split /\./, $yeah;
	$lastpart				= $parts[$#parts];
	foreach my $sub_tld (loadsubTLDS())	{
		if ( $sub_tld eq $lastpart )	{
			( $yeah, undef )	= split /\.$sub_tld/, $yeah;
			last;	}}		# end foreach my $sub_tld (@OTHERS)
	return "$yeah";
	}		# end sub piecedomain



#	----------------------------
#	find_net
#	----------------------------
sub findnet($)	{my($iptouse, )	= @_;
#	----------------------------
	my @splitter	= split /\./, $iptouse;
	return join ".", @splitter[0..2];
	}	# findnet

#	----------------------------
sub forward($;$){my( $host,$mode, )= @_;
	$mode		||= 0;
#	----------------------------
	my @results			= ();
	my $query			= $res->search($host);
	return () unless $query;
	foreach my $rr ($query->answer)	{
		next unless ( $rr->type eq "A" );
		my $address			= $rr->{"address"};
		my $data			= $address;
		$data				= "$host;$data"		if ( $mode >= 1 );
		$data				= "$data;FL"		if ( $mode >= 2 );
		$data				= "$data;$host"		if ( $mode >= 3 );
		push @results, $data;	}
	return uniq sort grep $_, @results;
	}

#	----------------------------
sub get_array_from_filename($;$)	{	my ($filename, $comment_char,	) = @_;
	$comment_char	||= "#";
#	----------------------------
	open FILE, $filename or die "Cannot open file $filename";
	my @file_array		= <FILE>;
	close FILE;
	chomp @file_array;
	return grep !/^\s*$comment_char/, @file_array;
	}

#	----------------------------
sub exp_tld($$$)		{	my(	$fh, $wrapper_mode, $domains_ref, ) = @_;
#	----------------------------
	my $baselinedomain			= "bigred-control-sp";
	my $baselinedomain2			= "redbig-control-sp";
	my @TLDS				= loadTLDS();
	#my @TLDS				= qw(cc br fr za nz cz);
	my @SUB_TLDS				= loadsubTLDS();
	my @domains				= map piecedomain($_), @$domains_ref;
	foreach my $tld (sort @TLDS) {
		foreach my $domain (@domains) {
			foreach my $sub (@SUB_TLDS) {
				my $workdomain;
				my $fwork;
				my $fwork2;
				if ( $sub ) {
					$workdomain	= "$domain.$sub.$tld";
					$fwork		= "$baselinedomain.$sub.$tld";
					$fwork2		= "$baselinedomain2.$sub.$tld";	}
				else {
					$workdomain	= "$domain.$tld";
					$fwork		= "$baselinedomain.$tld";
					$fwork2		= "$baselinedomain2.$tld";	}


		my $result	= `nslookup -timeout=3 -retry=2 -query=ANY $workdomain 2>&1`;
				
			if (($result =~ /answer/i) || ($result =~ /internet address/ )) {

					my @mxes		= mxlookup($fwork, 0 );
					push @mxes, mxlookup($fwork2, 0 );
					@mxes			= dedupe(@mxes);
					my @fakemxnet	= map findnet($_), @mxes;

#					Determine the real MX records
					my @realmxes	= mxlookup($workdomain);
					my @realmxnet	= map findnet($_), @realmxes;

#					Check if there's a match
					my $mxflag		= 0;
					foreach my $rmxnet (@realmxnet) {
						foreach my $fmxnet (@fakemxnet) {
							if ( $rmxnet eq $fmxnet ) {
								$mxflag = 1;
								last;	
							}
						}
						last if $mxflag;	}

#					Determine the networks of the fake A records
					my @aaes		= forward("www.$fwork", 0);
					push @aaes, &forward( $fwork2, 0 );
					@aaes			= dedupe(@aaes);
					my @fakeaanet	= map findnet($_), @aaes;

#					Determine the real A records
					my @realaaes	= forward("www.$workdomain");
					my @realaanet	= map findnet($_), @realaaes;

#					Check if there's a match
					my $aflag		= 0;
					foreach my $ranet (@realaanet) {
						foreach my $fanet (@fakeaanet) {
							if ( $ranet eq $fanet ) {
								$aflag = 1;
								last;	}}
						last if $aflag;	}

					if ( ( $aflag == 0 ) && ( $mxflag == 0 ) ) {
						my $output	= $workdomain;
						print $fh $output, "\n";
						print $workdomain, "\n"; }}
				}		# mext $sub
			}		# next $domain
		}		# next $tld
	}



#	============================================================================



my $input_file             = @ARGV[0];
my $output_file            = $ARGV[1];
$res                       = Net::DNS::Resolver->new();

@input                     = get_array_from_filename($input_file);
$wrapper_mode =1;
open OUT, ">$output_file" or die "Cant read output file '$output_file'\n";

  select OUT; $| = 1;
  exp_tld(*OUT, 0, \@input);
  close OUT;
