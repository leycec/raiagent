## Makefile.am for SDL using OpenGL hardware HQ scaling

all: SDL_openglhq_pass1.h SDL_openglhq_pass2.h SDL_openglhq_pass3.h SDL_openglhq_table.h

patch:
	( cd ../../..; patch -sp1 < src/video/openglhq/SDL-1.2.diff && ./autogen.sh; )
	touch patch

clean:
	-rm tablebuilder SDL_openglhq_pass1.h SDL_openglhq_pass2.h SDL_openglhq_pass3.h SDL_openglhq_table.h hexdump asciidump

zip: clean
	(cd ..; zip -9 ~/SDL-1.2-openglhq-`date +%Y-%m-%d`.zip openglhq/{Makefile,README,*.diff,*.c,*.h,*.ui,*.fp,*.dat,*.DLL})

tablebuilder: tablebuilder.ui tablebuilder.ui.h
	{ echo '#!/usr/bin/python'; echo 'from qtcanvas import *'; pyuic -x $<; } > tablebuilder
	chmod 755 tablebuilder

HOSTCC=gcc

asciidump: asciidump.c
	$(HOSTCC) -o $(@F) $<

hexdump: hexdump.c
	$(HOSTCC) -o $(@F) $<

test: test.c
	gcc -o test test.c `sdl-config --cflags` `sdl-config --libs`

%.h: %.fp asciidump
	./asciidump $< $@

%.h: %.dat hexdump
	./hexdump $< $@

