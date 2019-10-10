TARGET=scdic-google.txt scdic-win7.txt scdic-win8_win10.txt

all: $(TARGET)

clean:
	$(RM) $(TARGET)

scdic-google.txt: ws.txt
	ruby scdicgen < $< > $@ || ($(RM) $@; exit 1)

scdic-win7.txt: scdic-google.txt
	sed 's/短縮よみ/独立語/' $< | iconv -f utf-8 -t ms932 -o $@

scdic-win8_win10.txt: scdic-google.txt
	iconv -f utf-8 -t ms932 -o $@ $<
