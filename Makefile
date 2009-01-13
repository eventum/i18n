# Makefile for Eventum po files.
# (c) 2007 Elan Ruusamäe <glen@delfi.ee>

SVN_URL := svn://eventum.mysql.org/eventum-gpl/trunk/eventum
ALL_LINGUAS := de en es fi fr it nl pl ru sv pt_BR
DOMAIN := eventum
POFILES := $(patsubst %,%.po,$(ALL_LINGUAS))

all:
	@set -e; \
	umask 002; \
	for lang in $(ALL_LINGUAS); do \
		echo -n "$$lang: "; \
		[ -f $$lang.po ] || { echo Missing; continue; }; \
		msgfmt --statistics --output=t.mo $$lang.po && mv t.mo $$lang/LC_MESSAGES/$(DOMAIN).mo; \
	done

tools-check:
	@TOOLS='svn find sort xargs tsmarty2c xgettext sed mv rm'; \
	for t in $$TOOLS; do \
		p=`which $$t 2>/dev/null`; \
		[ "$$p" -a -x "$$p" ] || { echo "ERROR: Can't find $$t"; exit 1; }; \
	done

# generate .pot file from Eventum svn trunk
pot: tools-check
	@set -x -e; \
	umask 002; \
	rm -rf export; \
	svn export $(SVN_URL) export; \
	cd export; \
		find templates -name '*.tpl.html' -o -name '*.tpl.text' | LC_ALL=C sort | xargs tsmarty2c > misc/localization/eventum.c; \
		(echo misc/localization/eventum.c; find -name '*.php' | LC_ALL=C sort) | xgettext --files-from=- --keyword=gettext --keyword=ev_gettext --output=misc/localization/eventum.pot; \
		sed -i -e 's,misc/localization/eventum.c:[0-9]\+,misc/localization/eventum.c,g' misc/localization/eventum.pot; \
		mv misc/localization/eventum.pot ..; \
	cd -; \
	rm -rf export

update-po:
	@set -x -e; \
	umask 002; \
	for lang in $(ALL_LINGUAS); do \
		[ -f $$lang.po ] || continue; \
		if msgmerge $$lang.po $(DOMAIN).pot -o new.po; then \
			if cmp -s $$lang.po new.po; then \
				rm -f new.po; \
			else \
				mv -f new.po $$lang.po; \
			fi \
		fi \
	done
