dev-notes.html: dev-notes.md
	pandoc -o $@ -c style.css   \
		--toc --smart           \
		--base-header-level=2   \
		--highlight-style=tango \
		$^
