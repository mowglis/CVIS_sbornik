#!/usr/bin/perl
#
#	Generovani cisel akci pro sbornik (Inet)
#	
#	options:
#	
#	s - skolni rok
#	p - pololeti
#	w - zapis do DB
# 
use DBI;
use Getopt::Std;
#$skrok = "2002";
#$polo = "1";
#$wr = 0;
sub NumOK{
	my($id_kurz)=@_;
	if(exists($vety{$id_kurz})){$res = 0;}
	else {
		$res=1;
		$vety{$id_kurz}=1;
	}
	return $res;
}
sub UpdateRec{
	my($id_kurz,$id_akce)=@_;
	if($id_akce < 10){$id_akce = "0".$id_akce;}
	$old_id = $pol[1];
	if(length($old_id)<6){$tx = "!!! NOVÉ";} else {$tx = "";}
	$id_akce = substr($pol[1],0,4).$id_akce;
	if($wr) {
		$db->do("UPDATE kurz SET id_akce='$id_akce' WHERE id_kurz=$id_kurz AND sk_rok=$skrok AND pololeti=$polo");
		print "...updating record: $id_akce ($old_id) ($id_kurz) $tx\n";
	} else {
		print "...checking record: $id_akce ($old_id) ($id_kurz) $tx\n";
	}
}
sub delNumRec{
	my($id_kurz,$id_akce)=@_;
	$old_id = $pol[1];
	$id_akce = substr($old_id,0,4);
	if($wr) {
		$db->do("UPDATE kurz SET id_akce='$id_akce' WHERE id_kurz=$id_kurz AND sk_rok=$skrok AND pololeti=$polo");
		print "...updating record (DELETE id_akce): $id_akce ($old_id) ($id_kurz) $tx\n";
	} else {
		print "...checking record for delete id_akce: $id_akce ($old_id) ($id_kurz) $tx\n";
	}
}
#
# hlavni program
#
# inicializace
getopts("s:p:wd");
$wr				= $opt_w;
$skrok    = $opt_s;
$polo     = $opt_p;
$del      = $opt_d;
$numrec = 0;
$allrec = 0;
print "Hello, I'm generating numbers of akce!\n";
if($wr) {print "===> WRITING MODE <===\n";}
$db = DBI->connect("DBI:mysql:pgc:localhost:3306;mysql_socket=/var/lib/mysql/mysql.sock","writer","zapisovac") or die "Nelze otevøít databázi: ".DBI->errstr."\n";
#
$q_obor = $db->prepare("SELECT * FROM program");
$q_prac = $db->prepare("SELECT * FROM pracoviste ORDER BY id_pracoviste");
$q_rec = $db->prepare("SELECT kurz.id_kurz,kurz.id_akce,kurz.nazev,kurz_termin.den_od FROM kurz,kurz_termin WHERE kurz.id_kurz=kurz_termin.id_kurz AND SUBSTRING(id_akce,2,2)=? AND SUBSTRING(id_akce,1,1)=? AND kurz.sk_rok=$skrok AND pololeti=$polo ORDER BY kurz_termin.den_od,prihlas_do");
$q_obor->execute();
#  cyklus pres obory
while (@obor = $q_obor->fetchrow_array) {
	print "===> OBOR: $obor[1]\n";
	$q_prac->execute();
	while (@prac = $q_prac->fetchrow_array) {		
		$id_prac = $prac[0];
		$id_obor = $obor[0];
		$q_rec->execute($id_obor,$id_prac);
		if($q_rec->rows>0)
		{
			# cyklus pres vsechny vybrane zaznamy
			%vety=(); $id_akce=0;
			print "===> PRACOVI©TÌ: $prac[1]\n";
			while (@pol = $q_rec->fetchrow_array){
				if(&NumOK("$pol[0]")){
					$id_akce++;
					if($del) {
						delNumRec($pol[0],$id_akce);
					} else {
						UpdateRec($pol[0],$id_akce);
					}
				} else {
					print "$pol[0] -- duplicita\n";
				}
			}
		}
	}
}
