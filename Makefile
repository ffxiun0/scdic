DIC=scdic-main.txt scdic-main+pet.txt scdic-nochain.txt	\
    scdic-nochain+pet.txt

DIC_UTF8=$(DIC:.txt=.tsv)

DIST_ZIP=scdic.zip

RUBY=ruby
SCDICGEN=$(RUBY) scdicgen.rb
ICONV=uconv -f utf-8 -t utf-16le --add-signature
ZIP=zip -9

all: $(DIC)

dist: $(DIST_ZIP)

clean:
	$(RM) $(DIC) $(DIC_UTF8) $(DIST_ZIP)

scdic-main.tsv: ws.txt
	$(SCDICGEN) -o $@ $<

scdic-main+pet.tsv: ws.txt ps.txt
	$(SCDICGEN) -o $@ $^

scdic-nochain.tsv: ws.txt
	$(SCDICGEN) -g nochain -o $@ $<

scdic-nochain+pet.tsv: ws.txt ps.txt
	$(SCDICGEN) -g nochain -o $@ $^

%.txt: %.tsv
	$(ICONV) -o $@ $<

$(DIST_ZIP): LICENSE $(DIC)
	$(ZIP) $@ $^
