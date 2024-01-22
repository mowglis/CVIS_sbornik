#!/usr/bin/perl
#
# generovani sborniku
#
# options
#   -g  - generovat sbornik pro jedn. garanty
#   -p  - pololeti
#   -s  - skolni rok
#
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Getopt::Std;

#---------------- inicializace ----------------
$dir = "./";
$imgdir = "../imgs-sbornik/";
$kapitoly = $dir."kapitoly.tex";
$dataprefix = $dir."data_";
$linksprefix = $dir."links_";
$obrazky = $dir."images.list";
$odkazy = $dir."odkazy.txt";
$appendix_file = "appendtext_";

%ImgList =();
%scaleBox =();
%links = ();
#----------------- functions -----------------------
sub NactiObrazky {
	if(open(OBR,$obrazky)){
		while($radek=<OBR>){
			chomp($radek);
			if(substr($radek,0,1) ne "#"){
				@r = split(/:/,$radek);
				$ImgList{$r[0]}=$r[1];
            if($r[2] ne "") {$scaleBox{$r[0]}=$r[2];}
               else {$scaleBox{$r[0]}="1";}
			}
		}	
		close(OBR);
	}
}
sub readLinks {
	if(open(LINKS,$odkazy)) {
		while($line=<LINKS>) {
			chomp($line);
			if(substr($line,0,1) ne "#") {
				($obor,$value) = split(/:/,$line);
				$links{$obor} = $value;
			}					
		}
		close(LINKS);
	}
}
#-------------- Odkazy -----------------
sub mkLinks {
	my ($id_obor,$linksname) = @_;
	@ln_obor = split(/,/,$links{$id_obor});
	open(ODKAZ,">$linksname");
#	print ODKAZ "\\ \\\\\\ \\\\\n";
#	print ODKAZ "\\ \\\\\\ \\\\\n";
#	print ODKAZ "\\ \\\\\\ \\\\\n";
	print ODKAZ "\\vspace{0.5mm}\n";
	print ODKAZ "\\noindent\\setfonts [Lido-cbf/12]\n";
	print ODKAZ "\\textbf{Doporuèujeme dále:}\\\\\n";
	print ODKAZ "\\noindent\\setfonts [Lido-crm/10]\n";
	foreach $id_akce ( @ln_obor ) {
		print ODKAZ "\\cisloAkce{\$\\Rightarrow\$ ".idAkce($id_akce,"2002")."}\\hspace{5mm}\\PolozkaObsah{".getAkceName($id_akce,$db,$skrok,$polo)."}\\ \\dotfill\\ \\cisloStrany{s. \\pageref{".idAkce($id_akce,"2002")."}}\\\\\n";
	}
	close (ODKAZ);
}
sub getGarant {
	my ($id_garant)=@_;
	$q_garant = $db->prepare("SELECT titul,jmeno,prijmeni FROM zam WHERE rc_zam= ?");
	$q_garant->execute($id_garant);
	@g = $q_garant->fetchrow_array;
	return @g;
}  
sub getLogos {
	my ($id_kurz)=@_;
	%logh = (
		nov => [0,"\\logoNEW" ],
		rep => [0,"\\logoREP" ],
		pok => [0,"\\logoCON" ],
		inkluze => [0,"\\logoINKLUZE" ],
		zs  => [1,"\\logoZS" ],
		ss  => [1,"\\logoSS" ],
		zs1 => [1,"\\logoZSI" ],
		zs2 => [1,"\\logoZSII" ],
		sps => [1,"\\logoSPS" ],
		zus => [1,"\\logoZUS" ],
		ms  => [1,"\\logoMS" ],
		templ  => [1,"\\logoTEMPL" ],
		hk  => [2,"\\logoHK" ],
		ji  => [2,"\\logoJI" ],
		ry  => [2,"\\logoRY" ],
		na  => [2,"\\logoNA" ],
		tu  => [2,"\\logoTU" ],
	);
	@logo = ();
	$q_logo = $db->prepare("SELECT * FROM kurz_logo WHERE id_kurz= ?");
	$q_logo->execute($id_kurz);
	if($q_logo->rows>0) {
		@l = $q_logo->fetchrow_array;
		@logos = split(/\|/,$l[1]);
		foreach $ilogo ( @logos ) {
			$logo[$logh{$ilogo}->[0]].=$logh{$ilogo}->[1]."\\ ";	
		}
	}		
#	for($i=0,$i<3,$i++) {
#		if($logo[$i] eq "") { $logo[$i] = "*"; }
#	}		
	return (@logo[0],$logo[1],@logo[2]);
}  
#
# vypis jedne vety - popis jedne akce ve sborniku
#
sub PisVetu {
	my ($id_kurz,$sk_rok,$pololeti,$id_akce,$id_akredit,$nazev,$popis,$poplatek,$id_garant,$lektor,$urceni,$spojeni,$pozn,$zruseno,$cyklus,$notiu,$notig,$last,$rozsah,$id_urceni,$id_garant1,$id_druh_studia,$tit,$prijm,$jmeno,$urceni_popis,@terminy)=@_;
#	print "id_akce -> $id_akce ($prijm $jmeno)\n";
  @terminy = TerminFmt(@terminy);
  $ter = "\\termin{".join("\\\\ ",@terminy)."}";  
  $urceni = UrceniText($id_urceni,$urceni_popis,$urceni);
	$popis = OpravChyby($popis);
	$pozn = OpravChyby($pozn);
	$lektor = OpravChyby($lektor);
	$nazev = OpravChyby($nazev);
	$urceni = OpravChyby($urceni);
	$spojeni = OpravChyby($spojeni);
	$poplatek = OpravChyby($poplatek);
        $garant = "$tit $jmeno $prijm";
	$garant =~ s/^\s*//;
	if($id_garant1) {
		$garant1 = $id_garant1;
#		@g = getGarant($id_garant1);
#		$garant1 = $g[0]." ".$g[1]." ".$g[2];
		$garant1 =~ s/^\s*//;
	} else {
		$garant1 = "*";
	}
	
	($logo1,$logo2,$logo3) = getLogos($id_kurz);
#	print "$logo1|$logo2|$logo3\n";
	print DATA "\\z{%\n";
	print DATA "\\akce{".idAkce($id_akce,"2002")."}\n";
	print DATA "\\nazev{$nazev}\n";
	print DATA "\\popis{$popis}\n";
	print DATA "\\urceno{$urceni}\n";
	print DATA "$ter\n";
	print DATA "\\lektor{$lektor}\n";
	print DATA "\\garant{$garant}\n";
	if($poplatek eq "") {$poplatek="*";}
	print DATA "\\poplatek{$poplatek}\n";
	if($pozn eq "") {$pozn="*";}
	print DATA "\\poznamka{$pozn}\n";
	print DATA "\\dalsigarant{$garant1}\n";
	if($logo1 eq "") {$logo1 = "*";}
	if($logo2 eq "") {$logo2 = "*";}
	if($logo3 eq "") {$logo3 = "*";}
	print DATA "\\logosI{$logo1}\n";
	print DATA "\\logosII{$logo2}\n";
	print DATA "\\logosIII{$logo3}\n";
	print DATA "}\n";
	$numrec++;
#	print "--> writing record (id_akce: $id_akce)\n";
}
#
# sazba zacatku kapitoly
#
sub PisKapitolu_begin {
	my ($suffix,$obor)=@_;
#	print KAP "% obor $suffix\n";
	print KAP "\\KapitolaFmt{$obor}\n";
	print KAP "\\begin{multicols}{2}\n";
	if(length($obor)>30){$obor = substr($obor,0,30)."... atd.";}
	print "==> writing CHAPTER: '$suffix -> $obor'\n";
}
#
# ukonceni kapitoly
#
sub PisKapitolu_end {
	print KAP "\\end{multicols}\n";
	# odkazy
	if(exists($links{$id_obor})){
		print "+++ odkazy na jine akce\n";
		$linksname = $linksprefix.$id_obor.".tex";
		print KAP "% odkazy na jine akce\n";
		print KAP "\\input{$linksname}\n";
		mkLinks($id_obor,$linksname);
	}
	# ---- zpracovani extra pripojeneho textu ----
	if( -e $appendix_file.$id_obor.".tex") {
		print "+++ dalsi pridany text na konci kapitoly\n";
		print KAP "% dalsi pridany text na konci kapitoly\n";
		print KAP "\\input{./$appendix_file$id_obor.tex}\n";
	}     
	#------------- obrazek ---------------
	if(exists($ImgList{$id_obor}) && $garant ne "1"){
		print "+++ obrazek na konci kapitoly\n";
		print KAP "% sazba obrazku\n";
		print KAP "\\vfill\n";
		print KAP "\\begin{center}\n\\includegraphics[scale=$scaleBox{$id_obor}]{$ImgList{$id_obor}}\n\\end{center}\n";
	}
}
#
# sazba sekce
#
sub PisPracoviste {	
	my ($id_prac,$prac,$id_obor)=@_;
	$dataname = $dataprefix.$id_prac.$id_obor.".tex";
#	print KAP "% pracovi¹tì $prac\n";
	print KAP "\\SekceFmt{$prac}\n";
	print KAP "\\def\\done{\\odstavec}\n";
	print KAP "\\input{$dataname}\n";
#	print "--> writing SECTION: :: $prac ($id_prac)\n";
	print " * writting datafile: $dataprefix$id_prac$id_obor.tex";
}

#-----------------------------------------------
#				       hlavni program
#-----------------------------------------------
getopts("p:s:g");
$garant   = $opt_g;
$skrok    = $opt_s;
$polo     = $opt_p;

$numrec = 0;
$allrec = 0;

print "Hello, I'm generating LaTex source!\n";
NactiObrazky;
readLinks;
open(KAP,">$kapitoly") or die "Nelze zalo¾it soubor: '$kapitoly'\n"; 
$db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";

if($garant==1) {
	$q_garant = $db->prepare("SELECT * FROM zam ORDER BY prijmeni");
	$q_obor = $db->prepare("SELECT * FROM program");
	$q_rec = $db->prepare("SELECT kurz.*,zam.titul,zam.prijmeni,zam.jmeno,urceni.popis FROM kurz,zam,urceni WHERE kurz.id_garant=zam.rc_zam AND kurz.id_urceni=urceni.id_urceni AND kurz.id_garant=? AND SUBSTRING(id_akce,2,2)= ? AND sk_rok=$skrok AND pololeti=$polo AND kurz.zruseno='0' ORDER BY id_akce");
	$q_garant->execute();
	#
	#  cyklus pres garanty
	#
	while (@gar = $q_garant->fetchrow_array) {
		$pis_kapitola = 0;
		$garant = "$gar[3] $gar[2] $gar[1]";
		$garant =~ s/^\s*//;
		$id_garant = $gar[0];
		$q_obor->execute();
		#
		# cyklus pres obory
		#
		while (@obor = $q_obor->fetchrow_array) {		
			$id_obor = $obor[0];
			$q_rec->execute($id_garant,$id_obor);
			if($q_rec->rows>0){
				if($pis_kapitola == 0){
					PisKapitolu_begin ($gar[0],$garant);
					$pis_kapitola = 1;
				}
				PisPracoviste ($id_obor,"obor: $obor[1]",$id_garant);
				open(DATA,">$dataname") or die "Nelze zalo¾it soubor: '$dataname'\n";
				# cyklus pres vsechny vybrane zaznamy
				while (@pol = $q_rec->fetchrow_array){
					@terminy = GetTermin ($pol[0],0);
					PisVetu (@pol,@terminy);
				}
				close(DATA);
				print "--> zapsano $numrec zaznamu\n";
				$allrec += $numrec;
				$numrec = 0;
			} else { 
#				print "### no data: obor - $id_obor :: $obor[1]\n";
			}
		}
		if($pis_kapitola == 1){&PisKapitolu_end;}
	}
} else {
#
# klasika -> cely sbornik, tak jak se bude tisknout
#
  print "cely sbornik...\n";
  print "skolni rok: $skrok, pololeti: $polo\n";
	$q_obor = $db->prepare("SELECT * FROM program");
	$q_prac = $db->prepare("SELECT * FROM pracoviste ORDER BY id_pracoviste");
	$q_rec = $db->prepare("SELECT kurz.*,zam.titul,zam.prijmeni,zam.jmeno,urceni.popis FROM kurz,zam,urceni WHERE kurz.id_garant=zam.rc_zam AND kurz.id_urceni=urceni.id_urceni AND SUBSTRING(id_akce,2,2)= ? AND SUBSTRING(id_akce,1,1)= ? AND sk_rok=$skrok AND pololeti=$polo AND kurz.zruseno='0' ORDER BY SUBSTRING(id_akce,1,1), SUBSTRING(id_akce,5,2)");
   $q_test = $db->prepare("SELECT * FROM kurz WHERE sk_rok=$skrok AND pololeti=$polo AND SUBSTRING(id_akce,2,2)= ?"); 
	$q_obor->execute();
	#
	#  cyklus pres vsechny obory
	#
	while (@prog = $q_obor->fetchrow_array) {
      $id_obor = $prog[0];
      $q_test->execute($id_obor);
      if($q_test->rows > 0) {
		   PisKapitolu_begin ($id_obor,$prog[1]);
   		 $q_prac->execute();
	   	 # cyklus pres vsechna pracoviste
		   while (@prac = $q_prac->fetchrow_array) {		
			   $id_prac = $prac[0];
   			 $q_rec->execute($id_obor,$id_prac);
	   		 if($q_rec->rows>0) {
		   		 PisPracoviste ($id_prac,"pracovi¹tì $prac[1]",$id_obor);
			   	open(DATA,">$dataname") or die "Nelze zalo¾it soubor: '$dataname'\n";
				   # cyklus pres vsechny vybrane zaznamy
   				while (@pol = $q_rec->fetchrow_array){
	   				@terminy = GetTermin ($pol[0],0);
		      		PisVetu (@pol,@terminy);
				   }
   				close(DATA);
	   			print " - $numrec items\n";
		   		$allrec += $numrec;
   		   	$numrec = 0;
	   		} else {
#			 print "### no data: obor - $id_obor :: $prac[1]\n";
			}
		   }
   		PisKapitolu_end;
      }         
	}
}

######### zaverecne prace ##########
close(KAP);
print "***> celkem zapsano $allrec zaznamu\n";
# projedeme programem 'vlna'
print "... running 'vlna' for '$kapitoly'\n";
$status = system("vlna -r -s $kapitoly");
if($status!=0) {print "### Error: nelze spustit program 'vlna'\n";}
print "... running 'vlna' for '$dataprefix*.tex'\n";
$status = system("vlna -s -r -v KkSsVvZzOoUuIiA $dataprefix*.tex");
if($status!=0) {print "### Error: nelze spustit program 'vlna'\n";}
#$db->disconnect;

