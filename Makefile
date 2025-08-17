TARGET=scdic-main-google.txt scdic-main-win10.txt	\
       scdic-nochain-google.txt scdic-nochain-win10.txt

ZIP=scdic.zip

RUBY=ruby
SCDICGEN=$(RUBY) scdicgen.rb

all: $(TARGET)

zip: $(ZIP)

clean:
	$(RM) $(TARGET) $(ZIP)

scdic-main-google.txt: ws.txt
	$(SCDICGEN) -o $@ $<

scdic-nochain-google.txt: ws.txt
	$(SCDICGEN) -g nochain -o $@ $<

%-win10.txt: %-google.txt
	iconv -f utf-8 -t ms932 -o $@ $<

$(ZIP): LICENSE $(TARGET)
	zip -9 $@ LICENSE $(TARGET)
