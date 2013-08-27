/*
	SDL - Simple DirectMedia Layer OpenGL-HQ scaling
    Copyright (C) 2005 Jörg Walter <jwalt@garni.ch>
	SDL - Simple DirectMedia Layer
    Copyright (C) 1997-2004 Sam Lantinga

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Sam Lantinga
    slouken@libsdl.org
*/

#ifdef SAVE_RCSID
static char rcsid =
 "@(#) $Id$";
#endif

#ifndef _SDL_ohqvideo_h
#define _SDL_ohqvideo_h

#include <sys/types.h>
#include <stdint.h>

#include "SDL_mutex.h"
#include "../SDL_sysvideo.h"
#include "SDL_thread.h"

/* Hidden "this" pointer for the video functions */
#define _THIS	SDL_VideoDevice *this

enum OGL_CMD {
	OGL_NONE,
	OGL_CALL,
	OGL_INIT,
	OGL_DEINIT,
	OGL_FRAME,
	OGL_PALETTE,
	OGL_QUIT
};

enum OGL_STATUS {
	OGL_DONE,
	OGL_ERROR
};

/* Private display data */
struct SDL_PrivateVideoData {
	SDL_VideoDevice *real_video;
	volatile SDL_Surface *volatile surface;
	int screen_width, screen_height;

	volatile int width;
	volatile int height;
	volatile int pitch;
	volatile int outwidth;
	volatile int outheight;
	volatile int flags;
	volatile int bpp;
	volatile SDL_PixelFormat format;
	volatile SDL_Rect clip;

	int busy;

	struct {
	   enum {
	       OGL_CALL_P,
	       OGL_CALL_P_I,
	       OGL_CALL_PP,
	       OGL_CALL_PP_I,
	       OGL_CALL_PI_I,
	       OGL_CALL_PII,
	       OGL_CALL_PPP,
	       OGL_CALL_PPPIIII_P
	   } type;
	   intptr_t args[6];
	   union {
	       void (*p)(SDL_VideoDevice*);
	       void (*pii)(SDL_VideoDevice*, int, int);
	       void (*pp)(SDL_VideoDevice*, const void*);
	       int (*pp_i)(SDL_VideoDevice*, const void*);
	       int (*p_i)(SDL_VideoDevice *);
	       int (*pi_i)(SDL_VideoDevice *, int);
	       void (*ppp)(SDL_VideoDevice *, const void*, const void*);
	       void* (*pppiiii_p)(SDL_VideoDevice *, const void*, const void*, int, int, int, int);
	   } func;
	   intptr_t result;
	} call;

	volatile GLenum framebuf_format;
	volatile GLenum framebuf_datatype;

	GLuint texture[4];
	GLuint displaylist;
	GLint texsize, max_texsize;
	int has_pixel_data_range;
	int allow_paletted_texture;

	struct {
	    GLubyte r, g, b, a;
	} pal[256];

	GLuint program_name[3];
	GLuint fbo[2];
	GLuint pbuffer_displaylist;

	SDL_sem *render_thread_signal;
	SDL_sem *render_thread_ack;
	SDL_mutex *render_frame_lock;
	SDL_Thread *render_thread;

	void * volatile framebuf;
	int static_threshold;
	int dynamic_threshold;
	volatile int postponed;
	int nohq;
	int dirty;

	volatile enum OGL_CMD cmd;
	volatile enum OGL_STATUS status;
};

#endif /* _SDL_ohqvideo_h */
