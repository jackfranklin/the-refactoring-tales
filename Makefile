source=chapters/*.md
title='The Refactoring Tales'

all: epub pdf mobi html

sale: epub pdf mobi

dir:
	mkdir -p books

epub: dir
	pandoc -s -o books/book.epub --normalize --smart -t epub $(source) \
		--toc \
		--title-prefix $(title) \
		--epub-metadata build/metadata.xml \
		--epub-stylesheet epub.css

pdf: dir
	pandoc -s -o books/book.pdf $(source) \
		--title-prefix $(title) \
		--normalize \
		--toc \
		--smart


mobi: epub
	cd books && kindlegen book.epub

html: dir
	pandoc -s -c style.css -t html5 --normalize --smart --toc -o refactoring-tales.html $(source) \
		--include-before-body build/author.html \
		--title-prefix $(title)

