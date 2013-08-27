#include <stdlib.h>
#include "SDL.h"

#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

int main(int argc, char *argv[])
{
	int w = 0, h = 0;
	int c1 = 0x00ffffff, c2 = 0x00000000, c3 = 0x00ff0000;
	int once = 0;

	if (argc > 1 && !strcmp(argv[0], "--once")) {
		once = 1;
		argv++;
		argc--;
	}
	if (argc > 1) w = atoi(argv[1]);
	if (argc > 2) h = atoi(argv[2]);
	if (argc > 3) c1 = atoi(argv[3]);
	if (argc > 4) c2 = atoi(argv[4]);
	if (w <= 0) w = 160;
	if (h <= 0) h = 120;

	if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_NOPARACHUTE) < 0) {
		fprintf(stderr, "SDL error:  %s\n", SDL_GetError());
		exit(1);
	}
	atexit(SDL_Quit);

	SDL_Surface *display;
#define SET(x,y,c) do { uint32_t *line = display->pixels+(y)*display->pitch; line[(x)] = (c); } while (0)

	display = SDL_SetVideoMode(w, h, 0,0);//32, SDL_SWSURFACE);
	if (display == NULL) {
		fprintf(stderr, "SDL error: %s\n", SDL_GetError());
		exit(1);
	}

	SDL_Event event;
	int end = 0;
	int mx = 0, my = 0, i;

	while (!end) {
		SDL_FillRect(display, NULL, c2);

		SDL_Rect r = { 3, 0, w-3, 1 };
		for (; r.y < h; r.y += 2, r.x += 2, r.w -= 2) SDL_FillRect(display, &r, c1);
		r.x = 0;
		r.y = 3;
		r.w = 1;
		r.h = h-3;
		for (; r.x < w; r.x += 2, r.y += 2, r.h -= 2) SDL_FillRect(display, &r, c1);

		for (i = 0; i < w && i < h; i++) SET(i, i, c1);

		SET(mx, my, c3);
		SDL_UpdateRect(display, max(0,mx-10), max(0,my-10), min(w-mx+10,20), min(h-my+10,20));

		end = !SDL_WaitEvent(&event) || once;
		switch (event.type) {
		case SDL_QUIT:
			end = 1;
			break;
		case SDL_MOUSEMOTION:
			SET(mx, my, (mx&1 && my&1?c2:c1));
			SDL_UpdateRect(display, max(0,mx-10), max(0,my-10), min(w-mx+10,20), min(h-my+10,20));
			mx = event.motion.x;
			my = event.motion.y;
			break;
		default:
			break;
		}
	}

	return 0;
}
