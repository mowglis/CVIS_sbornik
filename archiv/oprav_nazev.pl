#!/usr/bin/perl

while ($line = <>) {
  chomp($line);
  ($_,$find_id_akce) = split(/{/,$line);
  $find_id_akce = substr($find_id_akce,0,-1);
  $id_akce = $find_id_akce;
  $id_akce =~ s/-//g;
#  print "kontrola: $find_id_akce -- $id_akce\n";
  $tex_file='data_'.substr($id_akce,0,3).'.tex'; 
  #$find_id_akce = substr($id_akce,0,1).'-'.substr($id_akce,1,2).'-'. substr($id_akce,3,1).'-'.substr($id_akce,4,2);
  $new_line = <>; chomp($new_line);
  printf("akce: %s - file: %s - replace: %s\n", $find_id_akce,$tex_file,$new_line);
  open (t_file, '<', $tex_file) or die "cannot open file $tex_file: $!";
  open (t_new_file,'>',$tex_file.".new");
  while (<t_file>) {
   chomp($_);
   if ($_ =~ /$find_id_akce/) { 
     my $line = <t_file>; 
     printf ("line for replace: %s\n",$line);
     print t_new_file "$_\n";
     print t_new_file "$new_line\n";
     break;
   } else {
     print t_new_file "$_\n";
   }
  }
  close t_file;
  close t_new_file;
  rename $tex_file, $tex_file.".bkp";
  rename $tex_file.".new", $tex_file;
}
