# A partir de l'export de la base Sirène, produit des listes de noms
# et prénoms féminins et masculins ; les hapax correspondent à des
# prénoms rares, mais certaines entrées ressemblent à une combinaison
# des différents prénoms de la personne

my $fichier=$ARGV[0];
my (%noms,%prenomsF,%prenomsM);
my $compte=();

open(E,'<:utf8',$fichier);
while (my $ligne=<E>) {
    chomp $ligne;
    #if (length($ligne)>7 && !exists $deja{$ligne}) {
    if ($ligne!~/^siren/ && !exists $deja{$ligne}) {
	my @cols=split(/\,/,$ligne);
	#my ($sexe,$nom,$pre1)=($cols[0],$cols[1],$cols[3]); # Si après nettoyage manuel
	my ($sexe,$nom,$pre1)=($cols[20],$cols[21],$cols[23]);
	if ($nom ne "" && $pre1 ne "") {
	    #warn "$sexe\t$pre1\t$nom\n";
	    #if ($pre4 ne "") { warn "PRENOM $ligne\n"; }
	    $noms{$nom}++;
	    if ($sexe eq "F") { $prenomsF{$pre1}++; } else { $prenomsM{$pre1}++; }
	}
    }
}
close(E);


warn "Produit liste-noms-brut.csv\n";
open(S,'>:utf8',"liste-noms-brut.csv");
foreach my $ligne (sort keys %noms) {
    # print S "$ligne\,$noms{$ligne}\n";
    my $t="";
    if ($ligne=~/ /) {
    	my @cols=split(/ /,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))." "; }
    	$t=~s/\s*$//;
    	print S "$t\,$noms{$ligne}\n";
    } elsif ($ligne=~/\-/) {
    	my @cols=split(/\-/,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))."\-"; }
    	$t=~s/\-*$//;
    	print S "$t\,$noms{$ligne}\n";
    } else {
    	$t=substr($ligne,0,1).lc(substr($ligne,1));
    	print S "$t\,$noms{$ligne}\n";
    }
}
close(S);

warn "Produit liste-prenoms-fem-brut.csv\n";
open(S,'>:utf8',"liste-prenoms-fem-brut.csv");
foreach my $ligne (sort keys %prenomsF) {
    # print S "$ligne\,$prenomsF{$ligne}\n";
    my $t="";
    if ($ligne=~/ /) {
    	my @cols=split(/ /,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))." "; }
    	$t=~s/\s*$//;
    	print S "$t\,$prenomsF{$ligne}\n";
    } elsif ($ligne=~/\-/) {
    	my @cols=split(/\-/,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))."\-"; }
    	$t=~s/\-*$//;
    	print S "$t\,$prenomsF{$ligne}\n";
    } else {
    	$t=substr($ligne,0,1).lc(substr($ligne,1));
    	print S "$t\,$prenomsF{$ligne}\n";
    }
}
close(S);

warn "Produit liste-prenoms-masc-brut.csv\n";
open(S,'>:utf8',"liste-prenoms-masc-brut.csv");
foreach my $ligne (sort keys %prenomsM) {
    # print S "$ligne\,$prenomsM{$ligne}\n";
    my $t="";
    if ($ligne=~/ /) {
    	my @cols=split(/ /,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))." "; }
    	$t=~s/\s*$//;
    	print S "$t\,$prenomsM{$ligne}\n";
    } elsif ($ligne=~/\-/) {
    	my @cols=split(/\-/,$ligne);
    	for (my $i=0;$i<=$#cols;$i++) { $t.=substr($cols[$i],0,1).lc(substr($cols[$i],1))."\-"; }
    	$t=~s/\-*$//;
    	print S "$t\,$prenomsM{$ligne}\n";
    } else {
    	$t=substr($ligne,0,1).lc(substr($ligne,1));
    	print S "$t\,$prenomsM{$ligne}\n";
    }
}
close(S);
