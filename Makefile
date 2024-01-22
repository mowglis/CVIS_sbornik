#
# generating sbornik for CvKHK
#
# TYP - vstupni parametr (-g -> sbornik pro garanty)

SKROK = 2023
POLO = 2
CVKHK = amos.cvkhk.cz
FILE = katalog
OBALKA = obalka

KATALOG_PDF = $(FILE)_$(SKROK)_$(POLO).pdf
KATALOG_KOMPLET = $(FILE)_komplet_$(SKROK)_$(POLO).pdf
OBALKA_PDF = $(OBALKA)_$(SKROK)_$(POLO).pdf

DIR = ~/dokumenty/$(FILE)
TARFILE = $(FILE).tar.gz
DIRPRINT = /home/rusek/tisk/sbornik
DIRPRINT_SERVER = /home/samba/public/katalog
DIRWEBBASE = /var/www/cvkhk/public_html/sbornik
DIRWEB=$(DIRWEBBASE)/$(SKROK)-$(POLO)
DATA = kapitoly.tex $(FILE).tex odkazy.txt 
PAGES=8-10
PODMINKY=podminky_prihlasovani.pdf

default:
	@echo
	@echo "Vytvoøení sborníku:"
	@echo 
	@echo "make clean					- vymazání vygenerovaných dat"
	@echo "make num						- èíslování jednotlivých akcí (bez zápisu)"
	@echo "make num-wr					- -\"- (se zápisem do db)"
	@echo "make data					- data z db"
	@echo "make data TYP=-g 			- data øazená po jednotlivých garantech"
	@echo "make pdf						- vytvoøení pdf formátu"
	@echo "make print       			- kopírování souborù pro tisk -> canon"
	@echo "make web						- kopírování do webového potálu"
	@echo "make obalka					- vytvoøení obálky"
	@echo "make podminky				- kopírovní pøihla¹ovacích podmínek pro web"
	@echo "make mail MAILTO=mail_addr	- mail sborník na adresu"
	@echo "make komplet					- zkompletování sborníku s obálkou"
	@echo

num:
	./akcenum.pl -s $(SKROK) -p $(POLO)

num-wr:
	./akcenum.pl -s $(SKROK) -p $(POLO) -w

delnum:
	./akcenum.pl -s $(SKROK) -p $(POLO) -d 

delnum-wr:
	./akcenum.pl -s $(SKROK) -p $(POLO) -dw

dvi: 
	vlna -s -r -l data_*.tex kapitoly.tex
	cslatex $(FILE).tex; cslatex $(FILE).tex

data: kapitoly.tex
	./gensbor.pl -s $(SKROK) -p $(POLO) $(TYP) 
#ps: dvi
#	dvips $(FILE)
#	dvips -f $(FILE) | psbook | psnup -pa4 -Pa4 -2 > \
#	$(FILE)_a4_$(POLO)_$(SKROK).ps
#	dvips -f $(FILE) | psbook | psnup -pa3 -Pa4 -2 > \
#	$(FILE)_a3_$(POLO)_$(SKROK).ps
#	mv $(FILE).ps $(FILE)_$(POLO)_$(SKROK).ps

pdf: 
	vlna -s -r -l data_*.tex kapitoly.tex
	pdfcslatex $(FILE).tex
	mv $(FILE).pdf $(KATALOG_PDF)

clean:
	- rm -f data_* *.toc *.mt* *.log *.aux \
*.bmt *.ps *.pdf *.dvi *.log *.zip links_* *.te~ > /dev/null 2> /dev/null 

tar:
	tar czvf $(TARFILE) -C .. --exclude $(TARFILE) $(FILE)

zip:	
	zip sbor_ps $(FILE).ps
	zip sbor_ps_a3 $(FILE)_a3.ps
	zip $(OBALKA) $(OBALKA).ps
	zip $(OBALKA)_a3 $(OBALKA)_a3.ps

get: 
	rsync -Cavuz $(OPTIONS) -e ssh $(CVKHK):$(DIR)/ .

put:
	rsync -Cavuz $(OPTIONS) -e ssh . $(CVKHK):$(DIR)

rclean:
	ssh $(CVKHK) "cd $(DIR); make clean"

sync: clean rclean get put	

obalka:
	pdfcslatex $(OBALKA).tex 
	- mv $(OBALKA).pdf $(OBALKA_PDF)

samba: pdf obalka
	- cp $(KATALOG_PDF) $(DIRPRINT_SERVER)
	- cp $(KATALOG_KOMPLET) $(DIRPRINT_SERVER)
	- cp $(OBALKA_PDF)  $(DIRPRINT_SERVER)

web: pdf obalka
	- sudo mkdir -p $(DIRWEB)
	- sudo cp $(KATALOG_PDF) $(DIRWEB)
	- sudo cp $(KATALOG_KOMPLET) $(DIRWEB)
	- sudo cp $(OBALKA_PDF) $(DIRWEB)

links:
	./mklinks.pl -s$(SKROK) -p$(POLO)

links-wr:
	./mklinks.pl -s$(SKROK) -p$(POLO) -w

podminky:
	pdftk $(KATALOG_PDF) cat $(PAGES) output $(PODMINKY)
	sudo cp $(PODMINKY) /var/www/cvkhk/public_html/filemgmt_data/files

mail:
	echo "Katalog $(KATALOG_KOMPLET) v pøíloze." | mutt -s "$(KATALOG_KOMPLET)" $(MAILTO) -a $(KATALOG_KOMPLET)

komplet: pdf obalka
	pdftk $(OBALKA_PDF) burst output $(OBALKA)_%02d.pdf compress
	pdftk $(OBALKA)_01.pdf $(KATALOG_PDF) $(OBALKA)_02.pdf cat output $(KATALOG_KOMPLET)
	- rm $(OBALKA)_0?.pdf

print:
	cp $(KATALOG_KOMPLET) $(DIRPRINT_SERVER)
	cp $(OBALKA_PDF) $(DIRPRINT_SERVER)

