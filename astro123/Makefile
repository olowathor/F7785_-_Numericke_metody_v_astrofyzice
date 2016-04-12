all: %.md %.html

%.ipynb:
	@echo "Run..."

%.md: %.ipynb
	ipython nbconvert --to=markdown --execute notebooks/$< > markdown/$@

%.html: %.ipynb
	ipython nbconvert --to=html --execute notebooks/$< > html/$@
