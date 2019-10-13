TARGET=scdic-main-google.txt scdic-main-win7.txt		\
       scdic-main-win8_win10.txt scdic-nochain-google.txt	\
       scdic-nochain-win7.txt scdic-nochain-win8_win10.txt
ZIP=scdic.zip

all: $(TARGET)

zip: $(ZIP)

clean:
	$(RM) $(TARGET) $(ZIP)

scdic-main-google.txt: ws.txt
	ruby scdicgen -o $@ $<

scdic-nochain-google.txt: ws.txt
	ruby scdicgen -g nochain -o $@ $<

%-win7.txt: %-google.txt
	sed 's/短縮よみ/独立語/' $< | iconv -f utf-8 -t ms932 -o $@

%-win8_win10.txt: %-google.txt
	iconv -f utf-8 -t ms932 -o $@ $<

$(ZIP): LICENSE $(TARGET)
	zip -9 $@ LICENSE $(TARGET)
