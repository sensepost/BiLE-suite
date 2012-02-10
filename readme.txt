!!!Please read carefully through this readme file, as there are various changes one will have 
!!!to make as to get the scripts  as to make them work correctly for your operating system.


#########
#BiLE.pl#
#########

The Bi-directional Link Extractor. BiLE leans on Google and HTTrack to
automate the collections to and from the target site, and then applies a
simple statistical weighing algorithm to deduce which Web sites have the
strongest .relationships. with the target site.

We run BiLE.pl against the target Web site by simply specifying the Website
address and a name for the output file.

How to use:
###########

>perl BiLE.pl www.sensepost.com sp_bile_out.txt

Two output files are produced, *.mine and *.walrus, for now *.mine is the
important file we will use later.

This command will run for some time. BiLE will use HTTrack to download and
analyze the entire site, extracting links to other sites that will also be
downloaded, analyzed, and so forth. BiLE will also run a series of Google
searches using the link: directive to see what external sites have HTTP
links toward our target site.

The output of this a file containing all the link pairs in the format:

Source_site:Destination_site

BiLE produces output that only contains the source and destination sites for
each link, but tells us nothing about the relevance of each site. Once you
have a list of all the .relationships. (links to and from your chosen target
Web site), you want to sort them according to relevance. The tool we use
here, bile-weigh.pl, uses a complex formula to sort the relationships so you
can easily see which are most important.

Requirements:
#############

In order for BiLE.pl to run correctly httrack needs to be installed on the
operating system. Line 67 of BiLE.pl can be modified to point to the httrack
executable:

 $mc="httrack $site......
 
 to
  
 $mc="/home/sensepost/tools/httrack $site......




###############
#BiLE-weigh.pl#
###############

The next tool used in the collection is BiLE-weigh, which takes the output
of BiLE and calculates the significance of each site found. The weighing
algorithm is complex and the details will not be discussed; what should be
noted is:

   The target site that was given as an input parameter does not need to end
   up with the highest weight. This is a good sign that the provided target
   site is not the central site of the organization.

   A link to a site with many links to the site weighs less than a link to a
   site with fewer links to the site.
   
   A link from a site with many links weighs less than a link from a site
   with fewer links.
   
   A link from a site weighs more than a link to a site.


How to use:
###########

>perl bile-weigh.pl www.sensepost.com sp_bile_out.txt.mine out.txt

Input fields:
<website> is a Web site name; for example, www.sensepost.com
input file typically output from BiLE 

Output:
Creates a file called <input file name>.sorted, sorted by weight with lower
weights first. 

Output format:
Site name:weight

The list you get should look something like:

www.sensepost.com:378.69
www.redpay.com:91.15
www.hackrack.com:65.71
www.condyn.net:76.15
www.nmrc.org:38.08
www.nanoteq.co.za:38.08
www.2computerguys.com:38.08
www.securityfocus.com:35.10
www.marcusevans.com:30.00
www.convmgmt.com:24.00
www.sqlsecurity.com:23.08
www.scmagazine.com:23.08
www.osvdb.org:23.08

The number you see next to each site is the .weight. that BiLE has assigned.
The weight in itself is an arbitrary value and of no real use to us. What is
interesting, however, is the relationship between the values of the sites.
The rate at which the sites discovered become less relevant is referred to
as the .rate of decay.. A slow rate of decay means there are many sites with
a high relevance.an indication of widespread cross-linking. A steep decent
shows us that the site is fairly unknown and unconnected.a stand-alone site.
It is in the latter case that HTML Link Analysis becomes interesting to us,
as these links are likely to reflect actual business relationships.

Requirements:
#############

There are no real requirements, except that the script requires the *.bile
output file from the BiLE.pl script




###############
#tld-expand.pl#
###############

The tld-expand.pl script is used to find domains in any other TLDs.  

How to use:
###########
>perl exp-tld.pl [input file] [output file]

Input fields:
Input file, is the file containing a list of domains 

Output:
Output file, is the output file containing domains expanded by TLD


Note: 
#####
tld-expand will run for awhile depending on how many domains are listed in
the input file.  One can monitor the output by; tail -f outputfilename




################
#vet-IPrange.pl#
################

The output of BiLE-weigh now lists a number of domains with a relevance
number. The sites with a lower relevance number that are situated much lower
down the list are not as important as the top sites.The results from the
BiLE-weigh have listed a number of domains with their relevance to our
target Web site. Sites that rank much further down the list are not as
important as the top sites. The next step is to take the list of sites and
match their domain names to IPs.

For this, we use vet-IPrange.The vet-IPrange tool performs DNS lookups for a
supplied list of DNS names. It will then write the IP address of each lookup
into a file, and then perform a lookup on a second set of names. If the IP
address matches any of the IP addresses obtained from the first step, the
tool will add the DNS name to the file.

How to use:
###########
>perl vet-IPrange.pl [input file] [true domain file] [output file] <range>

Input fields:
Input file, file containing list of domains 
True domain file contains list of domains to be compared to

Output:
Output file a file containing matched domains




###########
#qtrace.pl#
###########

qtrace is used to plot the boundaries of networks. It uses a heavily
modified traceroute using a #custom compiled hping# to perform multiple
traceroutes to boundary sections of a class C network. qtrace uses a list of
single IP addresses to test the network size. Output is written to a
specified file.

How to use:
###########
>perl qtrace.pl [ip_address_file] [output_file]

Input fields:
Full IP addresses one per line
Output results to file

Typical use:
perl qtrace.pl ip_list.txt outputfile.txt

Output format:
Network range 10.10.1.1-10.10.28

Requirements:
#############

NB! hping-1s is a recompiled hping with setuid support,1sec timeout - setuid 
Note: remember to allow icmp type 11 into your network!

Line 59 of qtrace.pl can be modified to point to the hping-1s executable:

  my @res=`hping-1s -2...... 
 
 to
  
  my @res=`/home/sensepost/tools/modified/hping-1s -2..... 



###########
#vet-mx.pl#
###########

Looking at the MX records of a company can also be used to group domains
together. For this process, we use the vet-mx tool.  The tool performs MX
lookups for a list of domains, and stores each IP it gets in a file. vet-mx
performs a second run of lookups on a list of domains, and if any of the IPs
of the MX records matches any of the first phase IPs found, the domain is
added to the output file.

How to use:
###########
>perl vet-mx.pl [input file] [true domain file] [output file]

Input fields:
Input file, is the file containing a list of domains 
True domain file contains list of domains to be compared to 

Output:
Output file, is an output file containing matched domains



##########
#jarf-rev#
##########

jarf-rev is used to perform a reverse DNS lookup on an IP range. All reverse
entries that match the filter file are displayed to screen (STDOUT). The
output displayed is the DNS name followed by IP address.

How to use:
###########
>perl jarf-rev [subnetblock]

Input fields:
Subnetblock specified is the first three octets of network address


Typical use:
>perl jarf-rev 192.168.37.1-192.168.37.118

Output format:
DNS name ; IP number
DNS name is blank if no reverse entry could be discovered.




###############
#jarf-dnsbrute# 
###############

The jarf-dnsbrute script is a DNS brute forcer, for when DNS zone transfers
are not allowed. jarf-dnsbrute will perform forward DNS lookups using a
specified domain name with a list of names for hosts. The script is
multithreaded, setting off up to 10 threads at a time.

How to use:
###########
>perl jarf-dnsbrute [domain_name] [file_with_names]

Input fields:
Domain name the domain name
File_with_name the full path the file containing common DNS names

Typical use:
>perl jarf-dnsbrute syngress.com common

Output format:
DNS name ; IP number

                                                   
                                                        