MAIN = paper
TEXPARTS = BIB/gridanom.bib

$(MAIN).pdf: $(MAIN).tex $(TEXPARTS)
	pdflatex $(MAIN).tex
	bibtex $(MAIN)
	pdflatex $(MAIN).tex
	pdflatex $(MAIN).tex
	open $(MAIN).pdf

clean:
	\rm -f *.aux *.bbl *.blg *.log *.thm *.out 

spotless: clean
	\rm -f $(MAIN).pdf
