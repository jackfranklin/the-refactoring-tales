
all: epub pdf mobi html

dir:
	mkdir -p books/html

epub: dir
	pandoc -s -o books/book.epub title.txt introduction.md 1-tabs.md

pdf: dir
	pandoc -s -o books/book.pdf title.txt introduction.md 1-tabs.md

mobi: epub
	cd books && kindlegen book.epub

html: dir
	pandoc -s -c style.css -o books/html/index.html title.txt introduction.md 1-tabs.md

