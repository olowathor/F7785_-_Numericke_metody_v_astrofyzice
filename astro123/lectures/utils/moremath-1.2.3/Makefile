# BASEDIR points to the root of texmf tree to which the bundle will be
# installed.
# Change it to value which make sense on your system (of course you need
# write permissions for the directiories).
# The default is current directory, first because it does the least harm
# in case you forgot to change it and second because it's useful for testing.
# Some more (maybe better) suggestions follow:
BASEDIR=/usr/share/texmf
# possible user's own texmf tree
#BASEDIR=$(HOME)/texmf
# various system-local or system trees
#BASEDIR=/usr/local/share/texmf
#BASEDIR=/usr/local/TeX/texmf
#BASEDIR=/var/lib/texmf
#BASEDIR=/usr/share/texmf
#BASEDIR=/var/TeX-local/texmf
#BASEDIR=/usr/TeX/texmf
##################################################################
# don't change anything below unless you know what you are doing
# and/or something goes wrong
PACKAGELIST=binbreak.sty binbreak.tex bracketsym.sty mathabbr.sty mathabbr.tex moremath.sty newvec.sty valform.sty valform.tex ot1cmvec.fd
FONTLIST=cmvec10.mf
DOCLIST=moremath.dvi moremath.ps
DISTLIST=moremath.dtx moremath.ins COPYING README.htm Makefile make.bat 
DISTNAME=moremath-1.2.3

.PHONY: all install doc clean dist
all: $(PACKAGELIST) $(FONTLIST)

# following is probably quite stupid...
$(PACKAGELIST) $(FONTLIST): moremath.dtx moremath.ins
	tex moremath.ins

install: all
	mkdir -m 755 -p $(BASEDIR)/tex/latex/trific
	install -m 644 $(PACKAGELIST) $(BASEDIR)/tex/latex/trific/
	mkdir -m 755 -p $(BASEDIR)/fonts/source/public/trific
	mkdir -m 755 -p $(BASEDIR)/fonts/tfm/public/trific
	install -m 644 $(FONTLIST) $(BASEDIR)/fonts/source/public/trific
	if [ -f moremath.ps ]; then mkdir -m 755 -p $(BASEDIR)/doc/latex/trific; install -m 644 $(DOCLIST) $(BASEDIR)/doc/latex/trific; install -m 644 COPYING README.htm $(BASEDIR)/doc/latex/trific; fi
	mktexlsr

doc: moremath.ps

moremath.ps: moremath.dvi
	dvips moremath

moremath.dvi: moremath.dtx
	latex moremath.dtx
	latex moremath.dtx
	makeindex -s gind.ist -o moremath.ind moremath.idx
	makeindex -s gglo.ist -o moremath.gls moremath.glo
	latex moremath.dtx

clean:
	-rm -f $(PACKAGELIST)
	-rm -f $(FONTLIST)
	-rm -f $(DOCLIST)
	-rm -f moremath.log moremath.dlg moremath.ilg moremath.aux moremath.idx moremath.toc moremath.ind moremath.glo moremath.gls
	-rm -f *~

dist: $(DISTNAME).tar.gz

$(DISTNAME).tar.gz: $(DISTLIST)
	-rm -rf $(DISTNAME)
	mkdir $(DISTNAME)
	cp $(DISTLIST) $(DISTNAME)
	tar zcvf $(DISTNAME).tar.gz $(DISTNAME)
	rm -rf $(DISTNAME)
