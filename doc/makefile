dev-notes.html: dev-notes.md style.css
	pandoc -o $@ -c style.css   \
		--toc --smart           \
		--base-header-level=2   \
		dev-notes.md
