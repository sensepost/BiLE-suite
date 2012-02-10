#!/usr/bin/perl

####
#### Usage: perl vet-mx.pl -v -i inputfile1 -i inputtruefile2 -o outputfile
#### Input_File: list of domains to be checked
#### True_File: list of domains to be checked against
#### Out_file: list of domains where the record matched
####

#	----------------------------
#	Modules
#	----------------------------
use File::Basename;			
use strict;			
use Net::DNS;
my $res= Net::DNS::Resolver->new();

if ($#ARGV<2){die "Usage vet-mx.pl input.file1 input.true.file2 output.file\n";}


###
#Sub Routines
###

#	----------------------------
sub uniq(@)		{
#	----------------------------
	my %seen		= ();
	return grep { ! $seen{$_}++ } @_ }

#	----------------------------
sub dedupe(@)		{
#	----------------------------
	return uniq map { lc $_ } @_;	}


#######################
sub get_array_from_filename($;$) {      
		my ($filename, $comment_char,) = @_;
               	open FILE, $filename or die "Cannot open file $filename";
                my @file_array          = ();
   while (<FILE>)  {
                    chomp;
                    next if ( $comment_char && $_ =~ /^\s*$comment_char/ );
                    last if ( $_ eq "exit" );
 		    push @file_array, $_;   }
   close FILE;
                    chomp @file_array;
         return @file_array;
	           }           

########################
#	----------------------------
sub mxlookup($;$)	{my( $domain,$mode, )= @_;
	$mode	||= 0;
#	----------------------------
	my $res			= Net::DNS::Resolver->new();
	my @results		= ();
	my @mxs			= mx($res, $domain);
	my $timeout		= 0;
	foreach my $mx (@mxs)	{
		next unless ( $timeout < 10);
		my $exchange		= $mx->{"exchange"};
		my @addresses		= getHostIP($exchange);
		my $address		= $addresses[0];
		my $data		= $address;
		$data			= "$exchange;$data"	if ( $mode >= 1 );
		$data			= "$data;MX"		if ( $mode >= 2 );
		$data			= "$data;$domain"	if ( $mode >= 3 );
		push @results, $data;	}
	return uniq sort grep $_, @results;
	}

#########
sub getHostIP($;$$)	{my(	$host,$timeout,$server, )= @_;
	$timeout||= 3;

	my $maxcount	= 3;
	$maxcount	= $timeout if ($timeout > 0 && $timeout < 11);
#Here we do the actual lookup.
	my $count	= 0;
	my @results;
	my $result;
#Continue looping untill we get a result or exceed the retry count
	while ($count < $timeout && !$result) {
		my $query	= $res->search($host);
		if ($query) {
			foreach my $rr ($query->answer()) {
				next unless $rr->type() eq "A";
#Return the address.
				$result		= $rr->address();
				push @results, $result;	}
		return @results;	}
		$count ++;
		}
#If we haven't found anything yet, return an error.
	return undef;
	}

#	----------------------------
sub loadsubTLDS()	{
#	----------------------------
	return ( "", "com", "co", "ac", "org", "net", "gov", "mil", "mod" );
	}

#	----------------------------
sub loadTLDS()	{
	return dedupe(qw(	com	org net edu	mil	gov uk	af	al	dz	as
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
						vi	wf	eh	ye	yu	za	zr	zm	zw	int gs
						info biz su	name coop aero ));
	}		# end sub loadTLDS

#	----------------------------
#	Getting domain back 2
#	----------------------------
sub realdomain($) {		my(	$passed, )	= @_;
#	----------------------------
	#find what TLD we are in and remove it
	my @parts		= split /\./, $passed;
	my $lastpart		= $parts[$#parts];
	my $yeah;
	foreach my $tld (loadTLDS()){
		if ( $tld eq $lastpart ){
			( $yeah, undef )= split /\.$tld\z/, $passed;
			last;	}}		
        # end foreach my $tld (@TLDS)

	# check if theres a CO or COM in
	@parts			= split /\./, $yeah;
	$lastpart		= $parts[$#parts];
	foreach my $sub_tld (loadsubTLDS()){
		if ( $sub_tld eq $lastpart ){
			( $yeah, undef )= split /\.$sub_tld\z/, $yeah;
			last;	}}		
	# end foreach my $sub_tld (@OTHERS)

	# ok - now if there are two or more things left - we chop the last
	# else we just take it
	@parts	= split /\./, $yeah;
	$lastpart = $parts[$#parts];
	# we add the stuff we chopped off
	( undef, $yeah )= split /$lastpart\./, $passed;
	return "$lastpart.$yeah";
	}		
	# end sub realdomain


my $input_files0 = @ARGV[0];
my $input_files1 = @ARGV[1];
my $output_file    = $ARGV[2];

		my @good	= get_array_from_filename($input_files0);
		my @vet	        = get_array_from_filename($input_files1);

#	Establish Output
open OUT, ">$output_file" or die "Cant read output file '$output_file'\n";
	select OUT; $| = 1;

#	======================>
#	Stuff happens here
#	======================>
	@good			= map realdomain($_), @good;

	my @realmxes		= dedupe( map mxlookup($_, 0), @good );

	my @results		= ();

	foreach my $entry (@vet) {
		my $romain	= realdomain($entry);
		my @mxes	= mxlookup($romain, 0);

		my $flag = 0;
		foreach my $quick (@realmxes) {
			foreach my $mx (@mxes) {
				$flag = 1 if ( $mx eq $quick );	}}
				push @results, $romain if $flag;
		}		# next $entry (@list)
	@results	= dedupe(@results);
	print OUT join("\n", @results), "\n";
	close OUT;
