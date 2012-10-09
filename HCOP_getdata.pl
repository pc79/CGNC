#!/local/bin/perl 


##############################################################################
# Syntax  : perl HCOP_getdata.pl
#
###############################################################################

use LWP::UserAgent;   # ::Simple;
use DBI;
use warnings;

# download the HCOP data
$urlHCOP = 'http://www.genenames.org/cgi-bin/hcop_data.cgi?species=ggal&lite=0&Search=Download';

$ua = new LWP::UserAgent;
$ua->agent("$0/0.1 " . $ua->agent);
$req = new HTTP::Request 'GET' => $urlHCOP;
$req->header('Accept' => 'text/html');
$res = $ua->request($req);
# check the outcome
if ($res->is_success) {
    $contentHCOP = $res->content;
} else {
    print "Error: " . $res->status_line . "\n";
}

open (FD_HCOP, ">hcop_data.txt") || die("could not write temp HCOP file");
print FD_HCOP $contentHCOP;
close FD_HCOP;


