TARGET=scdic-main-google.txt scdic-main-win10.txt		\
       scdic-main+pet-google.txt scdic-main+pet-win10.txt	\
       scdic-nochain-google.txt scdic-nochain-win10.txt		\
       scdic-nochain+pet-google.txt scdic-nochain+pet-win10.txt

DIST_ZIP=scdic.zip

RUBY=ruby
SCDICGEN=$(RUBY) scdicgen.rb
ICONV=iconv
ZIP=zip -9

all: $(TARGET)

dist: $(DIST_ZIP)

clean:
	$(RM) $(TARGET) $(DIST_ZIP)

scdic-main-google.txt: ws.txt
	$(SCDICGEN) -o $@ $<

scdic-main+pet-google.txt: ws.txt ps.txt
	$(SCDICGEN) -o $@ $^

scdic-nochain-google.txt: ws.txt
	$(SCDICGEN) -g nochain -o $@ $<

scdic-nochain+pet-google.txt: ws.txt ps.txt
	$(SCDICGEN) -g nochain -o $@ $^

%-win10.txt: %-google.txt
	$(ICONV) -f utf-8 -t ms932 -o $@ $<

$(DIST_ZIP): LICENSE $(TARGET)
	$(ZIP) $@ $^
