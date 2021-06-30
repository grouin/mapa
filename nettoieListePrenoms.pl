# Nettoie la liste de prénoms
# - supprime les happax
# - conserve l'initiale en majuscule et le reste en minuscule
# - essaie de réintroduire les diacritiques

# perl nettoieListePrenoms.pl data/prenom.csv data/prenom-fr.csv 200
# perl nettoieListePrenoms.pl data/patronymes.csv data/patronymes-fr.csv 200

use utf8;
use strict;
binmode STDOUT, ":encoding(utf8)";

my ($in,$out,$seuil)=@ARGV;
if (!$seuil) { $seuil=400; }
my %liste=();


###
# Récupération des prénoms

open(E,'<:utf8',"$in");
while (my $ligne=<E>) {
    chomp $ligne; my @cols=split(/\,/,$ligne);
    if ($cols[1]>=$seuil) {
	# my $t="";
	# if ($cols[0]!~/ /) { $t=substr($cols[0],0,1).lc(substr($cols[0],1));}
	# else { my @c=split(/ /,$cols[0]); foreach my $e (@c) { $t.=substr($e,0,1).lc(substr($e,1))." "; } chop $t; }
	my $t=$cols[0];
	my $initiale=substr($t,0,1);
	$liste{$t}=$cols[1];
    }
}
close(E);


###
# Traitement

open(S,'>:utf8',$out);
foreach my $ligne (sort keys %liste) {
    my $freq=$liste{$ligne};

    $ligne=&introduitAccent($ligne);
    my $genre=&attribueGenre($ligne);

    # Noms de famille
    $ligne=~s/ De / de /;
    $ligne=~s/ Du / du /;
    $ligne=~s/ D / d\'/;
    $ligne=~s/^D /D\'/;
    $ligne=~s/ Le / le /;
    $ligne=~s/ La / la /;
    $ligne=~s/ Les / les /;
    # $ligne=~s/ /\-/g; $ligne=~s/(Le|La|De|Du|Da|El|Ben)\-/$1 /;  # Désormais géré par traite.pl

    my $ligne=&correctionNoms($ligne);
    my $origine=&attribueOrigine($ligne);

    # Correction genre (-ane sur les prénoms arabes semble masculin)
    if ($ligne=~/ane$/ && $origine eq "ar") { $genre="M"; }
    if ($in=~/patronyme/) { $genre="NUL"; }

    # Affichage (éléments d'au-moins 3 caractères)
    if (length($ligne)>2) {
	print S "$freq\t$ligne\t$genre\t$origine\n" if ($ligne!~/Mme/);
	#print S "$ligne\,$freq\n";
    }
}
close(S);


###
# Sous-programmes

sub introduitAccent() {
    my $l=shift;

    # Accents
    $l=~s/Andre/André/;
    $l=~s/Anais/Anaïs/;
    $l=~s/Eleonore/Eléonore/;
    $l=~s/Herve/Hervé/;
    $l=~s/Desire/Désiré/;
    $l=~s/Honore/Honoré/;
    $l=~s/Jose/José/;
    $l=~s/Rene/René/;
    $l=~s/Stepha/Stépha/;
    $l=~s/Therese/Thérèse/;
    $l=~s/Zoe/Zoé/;
    $l=~s/aide/aïde/;            # Adelaïde
    $l=~s/^Ai([^m])/Aï$1/;       # Aïcha, Aïda, Aïssa ; pas Aimé
    $l=~s/nes$/nès/;             # Agnès, Inès, Younès
    $l=~s/ee$/ée/;               # Aimée, Andrée, Dorothée, Timothée
    $l=~s/^Ame([dl])/Amé$1/ if (length($l)>4); # Amélie ; pas Amel
    $l=~s/([rgh])eli([^en])/$1éli$2/; # Aurélie, Ophélie ; pas Micheline, Bachelier (nom)
    $l=~s/Aureli/Auréli/;
    $l=~s/Opheli/Ophéli/;
    $l=~s/^Feli([^x])/Féli$1/;   # Félicien
    $l=~s/Be(.)e([^l][^e])/Bé$1é$2/; # Bénédicte, Bérénice ; pas Bédel (nom), ni Benedetti
    $l=~s/^Ce([^n])/Cé$1/;       # Cécile, Cédric, Céline ; pas Cendrine
    $l=~s/^Clem/Clém/;           # Clémence, Clément, Clémentine
    $l=~s/eder/édér/;            # Frédéric, Médéric ; pas Mercedes
    $l=~s/([A-Z])e([glmsv])i/$1é$2i/; # Désiré, Félix, Kévin, Rémi
    $l=~s/([lM])oise/$1oïse/;    # Eloïse, Moïse ; pas Ambroise, Françoise
    $l=~s/enie$/énie/;           # Eugénie
    $l=~s/reg/rég/;              # Grégoire
    $l=~s/^Hel(.*)e$/Hél$1e/;    # Hélène, Héloïse ; pas Helen, Helena
    $l=~s/enee/énée/;            # Irénée
    $l=~s/enel(.)/énél$1/;       # Pénélope ; pas Avénel (nom)
    $l=~s/mail/maïl/;            # Ismaïl
    $l=~s/oel([^i]|$)/oël$1/;    # Joël, Noëlle ; pas Noélie
    $l=~s/oel/oél/;              # Noélie
    $l=~s/ephi/éphi/;            # Joséphine
    $l=~s/([ae])ila/$1ïla/;      # Laïla, Leïla
    $l=~s/^Lea/Léa/;             # Léa, Léandre
    $l=~s/oic/oïc/;              # Loïc
    $l=~s/ceane/céane/;            # Océane
    $l=~s/([hm])eo/$1éo/;        # Roméo, Théodore ; pas Georges, Matteo
    $l=~s/erie/érie/;            # Mériem, Valérie
    $l=~s/oem/oém/;              # Noémie
    $l=~s/e(.)emy/é$1émy/;       # Barthélémy
    $l=~s/emy$/émy/;             # Rémy
 
    $l=~s/^([BDV])e([^ln][aeo])/$1é$2/; # Béatrice, Bérengère ; pas Benoit
    $l=~s/Bea/Béa/;
    $l=~s/^Jere/Jéré/;           # Jérémie
    $l=~s/^Jero/Jérô/;           # Jérôme
    $l=~s/^Leo(\w)/Léo$1/;       # Léon, Léonard
    $l=~s/^Mel/Mél/;             # Mélanie, Mélodie
    $l=~s/^Se(.[^g])/Sé$1/;      # Sébastien, Séverine ; pas Serge
    $l=~s/ae([lt])/aë$1/;        # Anaëlle, Gaël, Gaëtan, Mickaël, Raphaël
    $l=~s/([^e])e(.)e$/$1è$2e/;  # Adèle, Angèle, Irène, Nadège
    $l=~s/([^e])e(.)es$/$1è$2es/; # Blaquières
    $l=~s/cois/çois/;            # François
    $l=~s/Lée/Lee/;
    $l=~s/Félicite/Félicité/;
    $l=~s/Chloe/Chloé/;
    $l=~s/Noe/Noé/;

    return $l;
}

sub attribueGenre() {
    my $l=shift;

    # Attribution automatique du genre des prénoms d'après leurs
    # désinences
    my $g="n";  # neutre
    if ($l=~/(a|ce|che|de|ée|ie|ite|lle|le|ne|que|[^d]re|sse|se|the|tte|[abcdeghlnstz]y)$/) { $g="F"; }
    elsif ($l=~/(ae|b|c|d|é|f|g|h|i|j|k|ke|l|m|n|o|p|r|s|t|u|w|[kmrv]y|z|ge|ghe|me|phe|pe|dre|ste|ue|ve|ye|yte)$/) { $g="M"; }
    else { $g="F"; }

    # Correction des cas particuliers
    if ($l=~/(Achille|Alex|Aloyse|Alphonse|Ambroise|Améd(e|é)|Anatole|Aristide|Aurèle|Barnabé|Basile|Blaise|Brice|Bruce|Calixte|Charlemagne|Clotaire|Corneille|Cyrille|Davide|Emile|Enrique|Eusèbe|Fabrice|Felix|Francisque|Geoffroy|Grégoire|Guy|Henrique|Hilaire|Ignace|Isidore|Jacque|Jacquy|Jérémie|Jerzy|Joe|Jordy|Lazare|Lee|Léonce|Maurice|Max|Noé|Nouredine|Pasquale|Patrice|Pierre|Placide|Radouane|Raffaële|Roy|Salvatore|S[iy]dney|Sosthène|Sylvère|Sylvestre|Tanguy|Terence|Théodore|Théophile|Thimot|Ulysse|Valère|Vasile|Vicente|Vincente|Virgile|Zacharie)/) { $g="M"; }
    elsif ($l=~/(Aïssatou|Alexa|Alin|Anaël|Anick|Astrid|Beatriz|Carmen|Conception|Edith|Edwige|Elisabeth|Elizabeth|Esther|Eve|Fatou|Félicité|Fleur|Fran|Geneviève|Gladys|Hannah|Hayat|Jennyfer|Jill|Judith|Karel|Katell|Kathryn|Kristel|Laureen|Léonor|Lourdes|Madi|Mai|Margaret|Mariam|Marylin|Maylis|Mériem|Meryem|Meryl|Myriam|Nadège|Najat|Nawel|Oleg|Olympe|Pénélope|Raquel|Romy|Rosemary|Ruth|Sékou|Sharon|Sigrid|Soazig|Solange|Soledad|Solenn|Vicky|Yoland|Zoé)/) { $g="F"; }

    return $g;
}

sub correctionNoms() {
    my $l=shift;

    $l=~s/réng/reng/;          # Bérénger
    $l=~s/Bésancon/Besançon/;  # Bésancon
    $l=~s/Céll/Cell/;          # Céllier
    $l=~s/Césb/Cesb/;          # Césbron
    $l=~s/hène/hêne/;          # Chène, Duchène
    $l=~s/vérie/verie/;        # Clavérie
    $l=~s/Dém/Dem/;            # Démange, Démaret, Démay, Démoulin
    $l=~s/Dér/Der/;            # Derouet
    $l=~s/Dév/Dev/;            # Dévaux, Déville, Dévillers, Dévos
    $l=~s/séph$/seph/;         # Joséph
    $l=~s/Jonès/Jones/;        # Jonès
    $l=~s/Le\-/Le /;           # Le-Bail, Le-Bars, Le-Berre, etc.
    $l=~s/Lé([^o])/Le$1/;      # Lélièvre, Lémière ; pas Léon, Léonard
    $l=~s/Sé([^nv])([^aeiou])/Se$1$2/; # Sébban, Séck, Séllam ; pas Séverin

    $l=~s/egre$/ègre/g;        # Allègre, Nègre
    $l=~s/Bec([hq])/Béc$1/;    # Béchet, Bécquet
    $l=~s/egue$/ègue/g;        # Bègue ; pas Béguin, ni Guéguen
    $l=~s/([^L])egu/$1égu/;    # Béguin, Gueguen ; pas Legay
    $l=~s/aich/aïch/;          # Bellaïche
    $l=~s/aissa/aïssa/;        # Benaïssa ; pas Fraisse
    $l=~s/said/saïd/;          # Bensaïd
    $l=~s/Ben([ai])([cr])/Bén$1$2/; # Bénard, Bénichou ; pas Benaïssa, Benoit, Bensaïd
    $l=~s/oit$/oît/;           # Benoît ; pas Poitevin
    $l=~s/([CF][ae])rre$/$1rré/; # Carré, Ferré ; pas Barre, Corre
    $l=~s/Chat/Chât/;          # Châtain, Château, Châtelain, Châtelet
    $l=~s/Cher([^r])/Chér$1/;  # Chéreau, Chérel, Chérier... ; pas Cherrier
    $l=~s/Cre([^s])/Cré$1/;    # Crépin, Crétin ; pas Crespin
    $l=~s/Derouet/Derouët/;
    $l=~s/pres$/prés/;         # Després
    $l=~s/onne$/onné/;         # Dieudonné
    $l=~s/Fer([aeio])/Fér$1/;  # Féraud, Féret, Féron ; pas Fernandez, Ferron...
    $l=~s/Fevre/Fèvre/;
    $l=~s/Fevrier/Février/;
    $l=~s/Fou(ch|qu)e/Fou$1é/; # Fouché, Fouqué
    $l=~s/Frem/Frém/;          # Frémont
    $l=~s/oncal/onçal/;        # Gonçalves
    $l=~s/Greco/Gréco/;
    $l=~s/Gue(.[aeiou])/Gué$1/; # Guédon, Guégan, Guénot, Guéret, Guérin, Guérineau
    $l=~s/oet$/oët/;           # Hascoët
    $l=~s/Heb/Héb/;            # Hébert, Hébrard
    $l=~s/Hem/Hém/;            # Hémery
    $l=~s/He([nr])([aeiou])/Hé$1$2/; # Hénault, Hénon, Héraud, Héritier ; pas Hennequin, Henri, Herbert, Hervé...
    $l=~s/r(.)ouet/r$1ouët/;   # Hervouët
    $l=~s/Je([^aeious])/Jé$1/; # Jégo, Jégou, Jézéquel ; pas Jesus
    $l=~s/equel$/équel/;       # Jézéquel
    $l=~s/Lecu/Lécu/;          # Lécuyer
    $l=~s/(^L|.l)eg([el][reiou])/$1ég$2/; # Léger, Deléger, Léglise ; pas Legendre, Legeay
    $l=~s/epi/épi/;            # Delépine, Lépinay, Lépine, Pépin
    $l=~s/etre$/être/;         # Leprêtre
    $l=~s/eque$/êque/;         # Lévêque
    $l=~s/Lev([eéêèy])([^a]|$)/Lév$1$2/; # Léveille, Lévêque, Lévesque, Lévy ; pas Leveau
    $l=~s/evre$/èvre/;         # Lefèvre, Lelièvre, Lièvre
    $l=~s/ien([aeiou])/ién$1/; # Liénard
    $l=~s/Ma(c|h|ss|z)e$/Ma$1é/; # Macé, Mahé, Massé, Mazé
    $l=~s/Mena([^n])/Ména$1/;  # Ménager, Ménard ; pas Menant (?)
    $l=~s/Nedelec/Nédélec/;
    $l=~s/Nedellec/Nédellec/;
    $l=~s/Pen([ao])/Pén$1/;    # Pénaud, Pénot
    $l=~s/Per([aio])/Pér$1/;   # Pérard, Périn, Péron, Pérot
    $l=~s/Romero/Roméro/;
    $l=~s/laun$/laün/;         # Salaün
    $l=~s/S(.)ne$/S$1né/;      # Séné
    $l=~s/ulie$/ulié/;         # Soulié
    $l=~s/echer$/écher/;       # Técher
    $l=~s/The/Thé/;            # Thébault, Théry, Thévenet, Thévenin, Thévenon, Thévenot
    $l=~s/Theron/Théron/;
    $l=~s/Thiery/Thiéry/;
    $l=~s/ou([rz])e$/ou$1é/;   # Rouré, Touré, Touzé
    $l=~s/([uHMSl])ery/$1éry/; # Guéry, Héry, Méry, Séry (?), Valéry
    $l=~s/echal$/échal/;       # Sénéchal
    $l=~s/éani$/eani/;         # Andréani

    # Sous le seuil des 400 :
    $l=~s/Ferte/Ferté/;
    $l=~s/linie$/linié/;       # Molinié
    $l=~s/Déparis/Deparis/;
    $l=~s/éll/ell/;            # Mellet, Thellier
    $l=~s/Hervét/Hervet/;
    $l=~s/Verbèke/Verbeke/;
    $l=~s/Gerau/Gérau/;        # Gérault
    $l=~s/Cler/Clér/;          # Cléret
    $l=~s/Défosse/Defosse/;
    $l=~s/Letang/Létang/;
    $l=~s/Prevel/Prével/;
    $l=~s/Pincon/Pinçon/;
    $l=~s/Tetu/Têtu/;
    $l=~s/énn/enn/;            # Crenn
    $l=~s/Déligny/Deligny/;
    $l=~s/Zaid/Zaïd/;          # Zaïdi
    $l=~s/Bezi/Bézi/;          # Béziat
    $l=~s/Décam/Decam/;        # Decamps
    $l=~s/Délisle/Delisle/;
    $l=~s/Teta/Têta/;          # Têtard
    $l=~s/Verges/Vergès/;
    $l=~s/Meresse/Méresse/;
    $l=~s/Fourre/Fourré/;
    $l=~s/Cérdan/Cerdan/;
    $l=~s/Sérin/Serin/;
    $l=~s/Liegeois/Liégeois/;
    $l=~s/laid$/laïd/;         # Belaïd
    $l=~s/Délille/Delille/;
    $l=~s/Décaux/Decaux/;
    $l=~s/écc/ecc/;            # Ceccaldi
    $l=~s/Défontaine/Defontaine/;
    $l=~s/Labonné/Labonne/;
    $l=~s/Pedron/Pédron/;
    $l=~s/Louet/Louët/;
    $l=~s/Mejean/Méjean/;
    $l=~s/Mebarki/Mébarki/;
    $l=~s/Meziane/Méziane/;
    $l=~s/Séntenac/Senténac/;
    $l=~s/Andréu/Andreu/;
    $l=~s/Medard/Médard/;
    $l=~s/Viguie/Viguié/;
    $l=~s/Khél/Khel/;          # Khelifi
    $l=~s/Verite/Vérité/;
    $l=~s/thoît$/thoit/;       # Duthoit
    $l=~s/Deveau/Déveau/;      # Déveaux
    $l=~s/Pezet/Pézet/;
    $l=~s/Jéhannot/Jehannot/;
    # Sous le seuil des 300 :
    $l=~s/eche$/èche/;         # Latrèche
    $l=~s/Escudie/Escudié/;
    $l=~s/Peret/Péret/;
    $l=~s/Débo([ru])/Debo$1/;  # Deborde, Debout
    $l=~s/Negri/Négri/;        # Négrier
    $l=~s/écqua/ecqua/;        # Bécquart
    $l=~s/Défer/Defer/;
    $l=~s/Lemetay/Lemétay/;    # Lemétayer
    $l=~s/Sagnès/Sagnes/;      # (?)
    $l=~s/ssedre$/ssèdre/;     # Teyssèdre, Teissèdre
    $l=~s/Tournie$/Tournié/;
    $l=~s/Séban/Seban/;
    $l=~s/Quenet/Quénet/;
    $l=~s/Pech/Pêch/;          # Pêcheux
    $l=~s/Mélchior/Melchior/;
    $l=~s/Tète/Tête/;
    $l=~s/Julié$/Julie/;
    $l=~s/Vedrine/Védrine/;
    $l=~s/Cérvantes/Cervantes/;
    $l=~s/mencon$/mençon/;     # Clémençon
    $l=~s/Hedin/Hédin/;
    $l=~s/Azemar/Azémar/;
    $l=~s/febure$/fébure/;     # Lefébure
    $l=~s/Neron/Néron/;
    $l=~s/Chede/Chéde/;        # Chédeville
    $l=~s/toît$/toit/;         # Dutoit
    $l=~s/Délion/Delion/;
    $l=~s/Meheust/Méheust/;
    $l=~s/Sénecal/Sénécal/;
    $l=~s/Cavalie$/Cavalié/;
    $l=~s/Héredia/Heredia/;
    $l=~s/Décoster/Decoster/;
    $l=~s/Délis/Delis/;
    $l=~s/Dépierre/Depierre/;
    $l=~s/ancon$/ançon/;       # Plançon
    $l=~s/Arrive$/Arrivé/;
    $l=~s/Megret/Mégret/;
    $l=~s/Ségond/Segond/;
    $l=~s/Dumenil/Duménil/;
    $l=~s/Mélon/Melon/;
    $l=~s/Cérve/Cerve/;        # Cervera
    $l=~s/Darre$/Darré/;
    $l=~s/llouet$/llouët/;     # Guillouët
    $l=~s/Rougérie/Rougerie/;
    $l=~s/Petillon/Pétillon/;
    $l=~s/Petry/Pétry/;
    $l=~s/Débarre/Debarre/;
    $l=~s/maïlly$/mailly/;
    $l=~s/Débono/Debono/;
    $l=~s/Schroédér/Schroeder/;
    $l=~s/Clérget/Clerget/;
    $l=~s/Leger$/Léger/;
    $l=~s/Le Metay/Le Métay/;  # Le Métayer
    $l=~s/Lievin/Liévin/;
    $l=~s/Bernabe$/Bernabé/;
    $l=~s/éges$/èges/;         # Courrèges
    $l=~s/Ferrie/Ferrié/;
    $l=~s/Dégand/Degand/;
    $l=~s/Kiéner/Kiener/;
    $l=~s/Lévert/Levert/;
    $l=~s/Lheritier/Lhéritier/;
    $l=~s/Mezi/Mézi/;          # Mézière
    $l=~s/Biénaime/Bienaimé/;
    $l=~s/Bédos/Bedos/;
    $l=~s/Déconinck/Deconinck/;
    $l=~s/Déhais/Dehais/;
    $l=~s/Clérgue/Clergue/;
    $l=~s/Ple$/Plé/;
    $l=~s/Hedouin/Hédouin/;
    $l=~s/Bouchérie/Boucherie/;
    $l=~s/Aïll/Aill/;          # Aillaud
    $l=~s/Cérisier/Cerisier/;
    $l=~s/Lacote/Lacôte/;
    $l=~s/Quère/Quéré/;        # Le Quéré
    $l=~s/Brechet/Bréchet/;
    $l=~s/Dembèle/Dembélé/;
    $l=~s/Regent/Régent/;
    $l=~s/Sénegas/Sénégas/;
    $l=~s/Béyer/Beyer/;
    $l=~s/Blouet/Blouët/;
    $l=~s/Deletang/Delétang/;
    $l=~s/Séve$/Sève/;
    $l=~s/Cérf$/Cerf/;
    $l=~s/Déwa/Dewa/;          # Dewaële
    $l=~s/Bordérie/Borderie/;
    $l=~s/Cérutti/Cerutti/;
    $l=~s/Chérgui/Chergui/;
    $l=~s/Bénéch/Benech/;
    $l=~s/Fouchét/Fouchet/;
    $l=~s/Jéhl/Jehl/;
    $l=~s/Lével/Level/;

    $l=~s/Jéhan/Jehan/;
    $l=~s/Gerome/Gérôme/;
    $l=~s/Naim$/Naïm/;
    $l=~s/Barnabe$/Barnabé/;
    $l=~s/Joséf$/Josef/;
    $l=~s/Clelia/Clélia/;
    $l=~s/Cloe/Cloé/;
    $l=~s/Lois$/Loïs/;
    $l=~s/Jéffrey/Jeffrey/;
    $l=~s/Cornelie/Cornélie/;
    $l=~s/Taieb/Taïeb/;
    $l=~s/Faiza/Faïza/;
    $l=~s/Alois/Aloïs/;
    $l=~s/Théresa/Theresa/;
    $l=~s/Valeria/Valérie/;
    $l=~s/Faical/Faiçal/;
    $l=~s/Faycal/Fayçal/;
    $l=~s/Jérzy/Jerzy/;
    $l=~s/Thimote/Thimoté/;
    $l=~s/Esperance/Espérance/;
    $l=~s/Smain/Smaïn/;
    $l=~s/Méryem/Meryem/;
    $l=~s/Camelia/Camélia/;
    $l=~s/Conceicao/Conceiçao/;
    $l=~s/Josélyne/Joselyne/;
    $l=~s/Léonné/Léonne/;
    $l=~s/Jéff/Jeff/;
    $l=~s/Améde/Amédé/;
    $l=~s/Gunter/Günter/;
    $l=~s/Ghunter/Ghünter/;
    $l=~s/Joséline/Joseline/;
    $l=~s/Sérena/Séréna/;
    $l=~s/Méryl/Meryl/;
    $l=~s/Mélvin/Melvin/;

    $l=~s/Josétte/Josette/;
    $l=~s/Josép/Josep/;
    $l=~s/Jérry/Jerry/;
    $l=~s/Said/Saïd/;
    $l=~s/Saida/Saïda/;
    $l=~s/Andréw/Andrew/;
    $l=~s/Naima/Naïma/;
    $l=~s/Ghéorghe/Gheorghe/;
    $l=~s/Yvonné/Yvonne/;
    $l=~s/Thé/The/;
    $l=~s/Kèbe/Kébé/;
    $l=~s/Séjourne/Séjourné/;
    $l=~s/Taibi/Taïbi/;
    $l=~s/Béau/Beau/; # Beaudouin
    $l=~s/Défois/Defois/;
    $l=~s/ac H/ac\'h/;
    $l=~s/ec H/ec\'h/;
    $l=~s/rc H/rc\'h/;
    $l=~s/Beno T/Benoît/;
    $l=~s/Sénrens/Senrens/;
    $l=~s/clérc/clerc/i;
    $l=~s/Fouquét/Fouquet/;
    $l=~s/Désailly/Desailly/;
    $l=~s/Salome/Salomé/;

    return $l;
}

sub attribueOrigine() {
    my $l=shift;

    # Attribution automatique de l'origine culturelle des prénoms
    my $g="eu";  # européen
    if ($l=~/^(Adama|Aïssatou|Alassane|Aliou|Amad|Aomar|Assia|Awa|Demba|Fatou|Issa|Mahamadou|Mamad|Moussa|Omar|Ornella|Sékou)$/) { $g="af"; }
    elsif ($l=~/^(Chi|Duc|Dung|Hoa|Hoang|Hung|Ken|Kim|Lan|Lee|Lin|Long|Lou|Mai|Minh|Ngoc|Phuong|Quang|Tan|Thanh|The|Thi|Thu|Thuy|Tuan|Van|Wei|Xuan|Ying)$/) { $g="as"; }
    elsif ($l=~/^(Bulent|Cengiz|Ehret|Ismet|Mehmet|Ozturk|Recep|Sadek|Sélim|Sellem|Sihem|Ugur|Vadim|Yildirim|Yilmaz)$/) { $g="tu"; }
    elsif ($l=~/^(Ab[bd]|Abidi|Abou|Achour|Adil|Ah|Aïcha|Aïssa|Ak|Alla|Aloui|Amal|Am(m)ar|Ameur|Ami|Arab|Are|Arif|Asma|Ayad|Ayari|Aymen|Ayoub|Az|Bachir|Badaoui|Badr|Bayram|Béchir|Bel[aghk]|Ben Ali|Ben Moussa|Ben Salah|Benaïssa|Benamar|Benguigui|Benitah|Bens|Berdah|Berkane|Bilal|Bilel|Bou|Brahim|Brahmi|Chafik|Chakib|Chaoui|Cheikh|Chérif|Chokri|Daoud|Dj|Dounia|Driss|El |Fa[diïorty]|Ferhat|Fethi|Fou[^cgqr]|Ghan|Ha|Hich|Ho[cu]|Hus|Ib|Idir|Idr|Im|Islam|Issam|Jalal|Jam|Jaou|Jaw|Ka|Kemal|Kenza|Kh|Labidi|La[hiïk]|Laloum|Lamia|Lamine|Larbi|Larissa|Latifa|Leïla|Lina|Loubna|Lounès|Lyes|Madj|Ma[hjk]|Malek|Malik|Mansour|Marek|Mariam|Marouane|Medhi|Meh|Mejri|Merat|Mériem|Meryem|Messaoud|Méziane|Miloud|Mimoun|Mo[hks]|Monia|Morad|Mou|Mu[hs]|Na[bcïjsw]|Nadia|Nadir|Nadj|Nordine|Nour|Ou|Ra[bdhï]|Rachid|Rafik|Ramazan|Ramzi|Rayan|Ri[ad]|Sa[adf]|Saïd|Salah|Salem|Saliha|Salim|Sami|Samy|Sayah|Sid|Sidi|Sih|Slama|Sli|Sma|So(u)fian|Soraya|Sou|Ta[hïory][^bdl]|Tichit|Touati|Toufik|Touitou|Touria|Wahid|Walid|Ya[chmsyz]|You|Yu|Za[hk]|Zaïdi|Zaoui|Zi|Zo[hru])/) { $g="ar"; }
    elsif ($l=~/^(Ali)$/) { $g="ar"; }
    else { $g="eu"; }

    # Corrections
    if ($l=~/^(Hadrian|Hanna|Hannah|Hans|Har|James|Kare|Karin|Karl|Kat|Youri)/) { $g="eu"; }
    # Corrections patronymes
    if ($l=~/^(Am[ai][^r]|Are|Az[^iz]|Belair|Belaud|Bou[^adz]|Haag|Mehl|Mosca|Moura)/) { $g="eu"; }
    if ($l=~/(ann|aud|ault|aut|eau|ek|el|er|ert|et|eu|ez|in|nd|nt|o|ol|on|ot|our|rd|rt|s|st|u|x|y)$/) { $g="eu"; }
    if ($l=~/^(Dia[bklw]|Diouf|Kébé|Koffi|Mbaye|N\'diaye|N\-Diaye|Sissoko)/) { $g="af"; }
    if ($l=~/^Dia$/) { $g="af"; }
    if ($l=~/^(Abad|Abbas|Hussain|Saïdani|Soussan|Younès)$/) { $g="ar"; }
    if ($l=~/^(Bui|Cam|Can|Cao|Chen|Cheng|Dao|Duc|Han|Huc|Huynh|Kane|Khan|Kone|Lai|Lam|Lee|Lin|Liu|Ngo|N\'guyen|Pham|Phan|Singh|Suc|Sun|Tan|Tang|Thiam|Tran|Trinh|Tual|Vang|Wang|Wong|Xiong|Yao|Yang|Yao|You|Yung)$/) { $g="as"; }
    if ($l=~/^Zh/) { $g="as"; }

    return $g;
}
