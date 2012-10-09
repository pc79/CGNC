#!/local/bin/perl 


##############################################################################
# Syntax  : perl HCOP_Update.pl -i input_19_column_HCOP_file
#
###############################################################################

use Getopt::Std;
use DBI;

getopt ('i');

use vars qw ($database_name $user  $pw);
$database_name="db_biocurate";

#delete old data
$dbargs = {AutoCommit => 0, PrintError => 1};
$dbh = DBI->connect("DBI:mysql:database=$database_name;host=localhost","$user","$pw", $dbargs)
      || die "Couldn't connect to database: " . DBI->errstr;
$dbh->do("delete from tblHCOP"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->do("delete from tblHCOP_humanN"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->do("delete from tblHCOP_chickenN"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->do("delete from tblChick_entrez_1_n"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->do("delete from tblChick_entrez_n_1"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->do("delete from tblChick_entrez_n_n"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->commit();

#format HCOP data
open (FD_IN, "$opt_i") || die "Error opening $opt_i";
open (FD_OUT, ">/tmp/HCOP.txt") || die("could not write temp file");

@w = ();

while($line = <FD_IN>) 
{
	if($line =~ /^Chicken_assert_ids/){next;}
	chomp $line;
	@w = split(/\t/, $line);
	
	print FD_OUT "$w[0]\t$w[2]\t$w[4]\t$w[7]\t$w[8]\t$w[11]\t$w[13]\t$w[16]\t$w[17]\t$w[18]\t1:1\n"; 
	
}

close(FD_OUT);
close(FD_IN);

#bulk upload HCOP
$dbh->do("LOAD DATA INFILE '/tmp/HCOP.txt' INTO TABLE db_biocurate.tblHCOP"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->commit();

#populate count tables
$dbh->do("insert into db_biocurate.tblHCOP_humanN (EntrezID) select human_entrez from db_biocurate.tblHCOP group by human_entrez having count(human_entrez)>1"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }

$dbh->do("insert into db_biocurate.tblHCOP_chickenN (EntrezID) select chicken_entrez from db_biocurate.tblHCOP group by chicken_entrez having count(chicken_entrez)>1"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->commit();


$dbh->do("insert into db_biocurate.tblChick_entrez_1_n (Chick_Entrez, Human_Entrez) select chicken_entrez, human_entrez from db_biocurate.tblHCOP where chicken_entrez in (select EntrezID from db_biocurate.tblHCOP_chickenN) and human_entrez not in (select EntrezID from db_biocurate.tblHCOP_humanN)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }

$dbh->do("insert into db_biocurate.tblChick_entrez_n_1 (Chick_Entrez, Human_Entrez) select distinct chicken_entrez, human_entrez from db_biocurate.tblHCOP where chicken_entrez not in (select EntrezID from db_biocurate.tblHCOP_chickenN) and human_entrez in (select EntrezID from db_biocurate.tblHCOP_humanN)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }

$dbh->do("insert into db_biocurate.tblChick_entrez_n_n (Chick_Entrez, Human_Entrez) select distinct chicken_entrez, human_entrez from db_biocurate.tblHCOP where chicken_entrez in (select EntrezID from db_biocurate.tblHCOP_chickenN) and human_entrez in (select EntrezID from db_biocurate.tblHCOP_humanN)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->commit();

#update ortholog_type
$dbh->do("update db_biocurate.tblHCOP set ortholog_type = '1:n' where chicken_entrez in (select Chick_Entrez from db_biocurate.tblChick_entrez_1_n) and human_entrez in (select Human_Entrez from db_biocurate.tblChick_entrez_1_n)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }

$dbh->do("update db_biocurate.tblHCOP set ortholog_type = 'n:1' where chicken_entrez in (select Chick_Entrez from db_biocurate.tblChick_entrez_n_1) and human_entrez in (select Human_Entrez from db_biocurate.tblChick_entrez_n_1)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }

$dbh->do("update db_biocurate.tblHCOP set ortholog_type = 'n:n' where chicken_entrez in (select Chick_Entrez from db_biocurate.tblChick_entrez_n_n) and human_entrez in (select Human_Entrez from db_biocurate.tblChick_entrez_n_n)"); 
if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->commit();

#the end

