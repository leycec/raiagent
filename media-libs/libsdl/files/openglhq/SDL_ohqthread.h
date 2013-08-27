/*
 *  OpenGL-HQ rendering code Copyright (C) 2004-2005 Jörg Walter <jwalt@garni.ch>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */
/* $Id$ */
/*---------------------------------------------------------------------
  This code implements a hardware-accelerated, cross-platform OpenGL
  based scaler quite similar to the well known Hq2x..Hq4x suite of
  software scalers. The general idea is exactly the same, but nothing
  else remains: in contrast to my software-hq2x scaler for dosbox, not
  even the interpolation rules have been used. Instead, they were
  designed from scratch to look well even on high scaling factors.

  Some compromises had to be taken, and it is indeed possible that
  my choice of rules don't fit some particular game. For this reason,
  the built-in table can be overridden by placing a file called
  "openglhq_table.dat" into the working directory. It will
  be loaded instead of the shipped table. Use the tablebuilder to
  edit the table file. Likewise, you can change the fragment programs
  used by creating files called "openglhq_passN.fp" for
  N = 1..3.

  As with the software hq2x scaler, the difference calculation is
  based on the algorithm described in
  http://www.compuphase.com/cmetric.htm, and the edge threshold
  calculation has entirely been conceived by me.

  Limitations:

  - None.

  - No really, there are none.

  - Believe me, absolutely none. Even performance is great, current
    builds use about as much CPU as software normal2x scaling in dosbox,
    and that's on a low-end Mobility Radeon 9700.

  - Everything said applies to a Mobility Radeon 9700. Faster cards
    might yield the previous statement untrue, I don't own an Nvidia
    card, etc. While I tried to create a universal high-performance,
    high-quality scaler, YMMV and Send Patches(tm).

*/

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include "SDL.h"
#include "SDL_ohqvideo.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/types.h>
#include <math.h>
#include <fcntl.h>
#include <assert.h>

#include <pthread.h>
#include <sys/time.h>
#include <sys/resource.h>
#ifndef SCHED_IDLE
#define SCHED_IDLE 5
#endif

#include "SDL_opengl.h"

#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef O_BINARY
#define O_BINARY (0)
#endif

#define OHQNAME(x) x
/*SDL_OHQ_ ## x*/

typedef void * (APIENTRY * OHQ_malloc_t) (int size, float readfreq, float writefreq, float priority);
typedef void (APIENTRY * OHQ_free_t) (void *pointer);

static OHQ_malloc_t OHQ_malloc = NULL;
static OHQ_free_t OHQ_free = NULL;

static PFNGLPIXELDATARANGENVPROC OHQNAME(glPixelDataRangeNV) = NULL;

/* supported only on fairly recent video cards (somewhere around ATI Radeon 9500 or a similar NVidia card) */
static PFNGLPROGRAMSTRINGARBPROC OHQNAME(glProgramStringARB) = NULL;
static PFNGLBINDPROGRAMARBPROC OHQNAME(glBindProgramARB) = NULL;
static PFNGLGENPROGRAMSARBPROC OHQNAME(glGenProgramsARB) = NULL;
static PFNGLDELETEPROGRAMSARBPROC OHQNAME(glDeleteProgramsARB) = NULL;
static PFNGLGETPROGRAMIVARBPROC OHQNAME(glGetProgramivARB) = NULL;
static PFNGLPROGRAMLOCALPARAMETER4DARBPROC OHQNAME(glProgramLocalParameter4dARB) = NULL;
static PFNGLPROGRAMENVPARAMETER4DARBPROC OHQNAME(glProgramEnvParameter4dARB) = NULL;
static PFNGLCOLORTABLEEXTPROC OHQNAME(glColorTableEXT) = NULL;

#include "SDL_openglhq_pass1.h"
#include "SDL_openglhq_pass2.h"
#include "SDL_openglhq_pass3.h"
#include "SDL_openglhq_table.h"

/* framebuffer object extension */
#ifndef GL_EXT_framebuffer_object
#define GL_EXT_framebuffer_object 1
typedef void (APIENTRY * PFNGLGENFRAMEBUFFERSEXTPROC) (GLsizei n, GLuint *framebuffers);
typedef void (APIENTRY * PFNGLBINDFRAMEBUFFEREXTPROC) (GLenum target, GLuint framebuffer);
typedef void (APIENTRY * PFNGLFRAMEBUFFERTEXTURE2DEXTPROC) (GLenum target, GLenum attachment,
                                                           GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRY * PFNGLDELETEFRAMEBUFFERSEXTPROC) (GLsizei n, const GLuint *framebuffers);
typedef GLenum (APIENTRY * PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC) (GLenum target);

// Constants
#define GL_FRAMEBUFFER_EXT                                  0x8D40
#define GL_COLOR_ATTACHMENT0_EXT                            0x8CE0

#define GL_FRAMEBUFFER_COMPLETE_EXT                         0x8CD5
#define GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT            0x8CD6
#define GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT    0x8CD7
#define GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT            0x8CD9
#define GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT               0x8CDA
#define GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT           0x8CDB
#define GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT           0x8CDC
#define GL_FRAMEBUFFER_UNSUPPORTED_EXT                      0x8CDD
#endif

static PFNGLGENFRAMEBUFFERSEXTPROC OHQNAME(glGenFramebuffersEXT) = NULL;
static PFNGLBINDFRAMEBUFFEREXTPROC OHQNAME(glBindFramebufferEXT) = NULL;
static PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC OHQNAME(glCheckFramebufferStatusEXT) = NULL;
static PFNGLFRAMEBUFFERTEXTURE2DEXTPROC OHQNAME(glFramebufferTexture2DEXT) = NULL;
static PFNGLDELETEFRAMEBUFFERSEXTPROC OHQNAME(glDeleteFramebuffersEXT) = NULL;

#define OHQ_RESOLUTION 16
//#define OGL_DEBUG_HQ
//#define OGL_DEBUG_HQ_MAX
#define OHQ_FAST

#define fmax(x,y) ((x)>(y)?(x):(y))
#define fmin(x,y) ((x)<(y)?(x):(y))

static int safe_semwait(SDL_sem *sem) {
    while (SDL_SemWait(sem) != 0) SDL_Delay(1);
    return 0;
}
#define SDL_SemWait safe_semwait

static int int_log2 (int val) {
    int log = 0;
    while ((val >>= 1) != 0)
    log++;
    return log;
}

/* instead of a plain malloc, we try to be nice to DMA-using hardware */
#define MALLOC_ALIGN 4096
#define align_upwards(x) ((void *)((intptr_t)((x) + MALLOC_ALIGN - 1) & ~(MALLOC_ALIGN-1)))
static void * APIENTRY default_malloc(int size, float readfreq, float writefreq, float priority) {
    char *ptr = (char *)malloc(size+sizeof(void*)+MALLOC_ALIGN-1);
    char *retval = (char *)align_upwards(ptr + sizeof(void*));
    void **real_ptr = (void **)(retval-sizeof(void*));
    *real_ptr = ptr;
    return retval;
}

static void APIENTRY default_free(void *pointer) {
    void **real_ptr = (void **)((char *)pointer-sizeof(void*));
    free(*real_ptr);
}

static unsigned int LoadNativeFragmentProgram(_THIS, const char *program, const char *filename) {
    GLuint name;
    int errorPos, isNative, programFd;
    char programString[65536] = "";
    const char *dir;

    OHQNAME(glGenProgramsARB)(1,&name);
    OHQNAME(glBindProgramARB)(GL_FRAGMENT_PROGRAM_ARB,name);
    if ((dir = getenv("SDL_OPENGLHQ_DATA")) != NULL) {
        strcpy(programString,dir);
        strcat(programString,filename);
        strcat(programString,".fp");

        if ((programFd = open(programString,O_RDONLY)) >= 0) {
            read(programFd,programString,sizeof(programString));
            close(programFd);
            program = programString;
        }
    }
    OHQNAME(glProgramStringARB)(GL_FRAGMENT_PROGRAM_ARB, GL_PROGRAM_FORMAT_ASCII_ARB, strlen(program), program);

    this->hidden->real_video->glGetIntegerv(GL_PROGRAM_ERROR_POSITION_ARB, &errorPos);
    OHQNAME(glGetProgramivARB)(GL_FRAGMENT_PROGRAM_ARB, GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB, &isNative);
    if (errorPos >= 0) {
        SDL_SetError("OPENGLHQ: Failed to load fragment program: %s",this->hidden->real_video->glGetString(GL_PROGRAM_ERROR_STRING_ARB));
        OHQNAME(glDeleteProgramsARB)(1,&name);
        return 0;
    } else if (!isNative) {
        SDL_SetError("OPENGLHQ: Hardware doesn't support this fragment program");
        OHQNAME(glDeleteProgramsARB)(1,&name);
        return 0;
    }
    return name;
}

static double sign(double a) {
    return (a < 0?-1:1);
}

/*
 This function calculates what percentage of a rectangle intersected by a line lies near the center of the
 cordinate system. It is mathematically exact, and well-tested for xcenter > 0 and ycenter > 0 (it's only
 used that way). It should be correct for other cases as well, but well... famous last words :)
*/
static double intersect_any(double xcenter, double ycenter, double xsize, double ysize, double yoffset, double gradient) {
    double g = fabs(gradient)*xsize/ysize;
    double o = -((yoffset-ycenter) + gradient*xcenter)/ysize*sign(ycenter)*sign(yoffset)-g*0.5+0.5;
    double yl = o, yr = o+g, xb = -o/g, xt = (1-o)/g;
    double area = 1.0;

    if (yl >= 1.0) xt = xb = area = 0.0;
    else if (yl > 0.0) {
        area = 1.0-yl;
        xb = 0.0;
    }
    else if (yr <= 0.0) yl = yr = area = 1.0;
    else yl = o+xb*g;

    if (xt <= 0.0) yr = yl = area = 0.0;
    else if (xt < 1.0) {
        area *= xt;
        yr = 1.0;
    }
    else if (xb >= 1.0) xb = xt = area = 1.0;
    else xt = (yr-o)/g;

    area -= (xt-xb)*(yr-yl)/2;

    return area;
}

static double intersect_h(double xcenter, double ycenter, double xsize, double ysize) {
    return fmax(0.0,fmin(1.0,(.55-fabs(xcenter)+xsize/2.0)/xsize));
    //return fmax(0.0,fmin(1.0,(.50-fabs(xcenter)+xsize/2.0)/xsize));
}

static double intersect_any_h(double xcenter, double ycenter, double xsize, double ysize, double yoffset, double gradient) {
    double hinside = intersect_h(xcenter,ycenter,xsize,ysize);
    return hinside*hinside*intersect_any(xcenter,ycenter,xsize,ysize,yoffset,gradient);
}

static double intersect_v(double xcenter, double ycenter, double xsize, double ysize) {
    return fmax(0.0,fmin(1.0,(.55-fabs(ycenter)+ysize/2.0)/ysize));
    //return fmax(0.0,fmin(1.0,(.50-fabs(ycenter)+ysize/2.0)/ysize));
}

static double intersect_any_v(double xcenter, double ycenter, double xsize, double ysize, double yoffset, double gradient) {
    double vinside = intersect_v(xcenter,ycenter,xsize,ysize);
    return vinside*vinside*intersect_any(xcenter,ycenter,xsize,ysize,yoffset,gradient);
}

static double intersect_hv(double xcenter, double ycenter, double xsize, double ysize) {
    double hinside = intersect_h(xcenter,ycenter,xsize,ysize);
    double vinside = intersect_v(xcenter,ycenter,xsize,ysize);
    return (1-hinside)*(1-vinside)+hinside*vinside;
}

/* FIXME: not sure if this is correct, but it is rare enough and most likely near enough. fixes welcome :) */
static double intersect_any_hv(double xcenter, double ycenter, double xsize, double ysize, double yoffset, double gradient) {
    double hvinside = intersect_hv(xcenter,ycenter,xsize,ysize);
    return hvinside*hvinside*intersect_any(xcenter,ycenter,xsize,ysize,yoffset,gradient);
}

static double intersect_hvd(double xcenter, double ycenter, double xsize, double ysize) {
    return intersect_h(xcenter,ycenter,xsize,ysize)*intersect_v(xcenter,ycenter,xsize,ysize);
}

static void setinterp(double xcenter, double ycenter, double percentage_inside, int i1, int i2, int i3, int o1, int o2, int o3, unsigned char *factors) {
    double d0, d1, d2, d3, percentage_outside, totaldistance_i, totaldistance_o;
    xcenter = fabs(xcenter);
    ycenter = fabs(ycenter);
    d0 = (1-xcenter)*(1-ycenter);
    d1 = xcenter*(1-ycenter);
    d2 = (1-xcenter)*ycenter;
    d3 = xcenter*ycenter;
    if (i1 && i2) i3 = 0;
    if (o1 && o2) o3 = 0;
    percentage_outside = 1.0-percentage_inside;
    totaldistance_i = d0+i1*d1+i2*d2+i3*d3;
    totaldistance_o = o1*d1+o2*d2+o3*d3+1e-12; /* +1e-12: prevent division by zero */

    factors[1] = (unsigned char)(((d1/totaldistance_i*percentage_inside*i1)+(d1/totaldistance_o*percentage_outside*o1))*255+.5);
    factors[2] = (unsigned char)(((d2/totaldistance_i*percentage_inside*i2)+(d2/totaldistance_o*percentage_outside*o2))*255+.5);
    factors[3] = (unsigned char)(((d3/totaldistance_i*percentage_inside*i3)+(d3/totaldistance_o*percentage_outside*o3))*255+.5);
    factors[0] = 255-factors[1]-factors[2]-factors[3];/*(unsigned char)((d0/totaldistance_i*percentage_inside)*255+.5);*/
}

/* Wanna have gcc fun? #define this as a macro, get a fast machine and go fetch a coffe or two. See how it is used to get an idea why.
   I aborted compilation after 5 minutes of CPU time on an Athlon64 3700+. */
static int swap_bits(int num, int bit1, int bit2) {
    return ((num & ~(bit1|bit2))|((num&bit1)?bit2:0)|((num&bit2)?bit1:0));
}

/*
static void WaitCommand(_THIS) {
    if (this->hidden->busy) SDL_SemWait(this->hidden->render_thread_ack);
    this->hidden->busy = 0;
}
*/

static void SendAsyncCommand(_THIS, enum OGL_CMD command) {
    if (this->hidden->busy) SDL_SemWait(this->hidden->render_thread_ack);
    this->hidden->busy = 1;
    this->hidden->cmd = command;
    SDL_SemPost(this->hidden->render_thread_signal);
}
static int TryWaitCommand(_THIS) {
    if (this->hidden->busy && SDL_SemTryWait(this->hidden->render_thread_ack) != 0) return 0;
    this->hidden->busy = 0;
    return 1;
}

static int SendSyncCommand(_THIS, enum OGL_CMD command) {
    int result;

    if (this->hidden->busy) SDL_SemWait(this->hidden->render_thread_ack);
    this->hidden->busy = 1;
    this->hidden->cmd = command;
    SDL_SemPost(this->hidden->render_thread_signal);
    SDL_SemWait(this->hidden->render_thread_ack);

    result = (this->hidden->status != OGL_ERROR);
    this->hidden->busy = 0;
    return result;
}

static void Finish(_THIS, GLuint fbo) {
    if (fbo) OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, fbo);
    this->hidden->real_video->glFinish();
    
    OHQNAME(glBindProgramARB)(GL_FRAGMENT_PROGRAM_ARB,0);
    this->hidden->real_video->glDisable(GL_FRAGMENT_PROGRAM_ARB);
    
    this->hidden->real_video->glActiveTexture(GL_TEXTURE2);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_3D,0);
    this->hidden->real_video->glActiveTexture(GL_TEXTURE1);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_3D,0);
    this->hidden->real_video->glActiveTexture(GL_TEXTURE0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_3D,0);

    this->hidden->real_video->glDisable(GL_TEXTURE_2D);
    this->hidden->real_video->glDisable(GL_TEXTURE_3D);

    this->hidden->real_video->glFinish();
    if (fbo) OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, 0);
}

static void DeinitOpenGL(_THIS) {
    int i;

    if (this->hidden->real_video->glFinish != NULL) {
        Finish(this,0);
		if (this->hidden->fbo[0]) {
			Finish(this,this->hidden->fbo[0]);
			Finish(this,this->hidden->fbo[1]);
		}
    }

    for (i = 0; i < sizeof(this->hidden->program_name)/sizeof(this->hidden->program_name[0]); i++) {
        if (this->hidden->program_name[i] != 0) {
            OHQNAME(glDeleteProgramsARB)(1,&this->hidden->program_name[i]);
            this->hidden->program_name[i] = 0;
        }
    }
    if (this->hidden->texture[0] != 0) {
        this->hidden->real_video->glDeleteTextures(4,this->hidden->texture);
        this->hidden->real_video->glDeleteLists(this->hidden->pbuffer_displaylist, 1);
        this->hidden->real_video->glDeleteLists(this->hidden->displaylist, 1);
        this->hidden->texture[0] = 0;
    }

    if (this->hidden->fbo[0] != 0) {
        OHQNAME(glDeleteFramebuffersEXT)(2, this->hidden->fbo);
        this->hidden->fbo[0] = this->hidden->fbo[1] = 0;
    }

    if (this->hidden->framebuf != NULL) {
        OHQ_free(this->hidden->framebuf);
    }
}

static int showfps = 0;
static int RenderFrame(_THIS, int ack) {
    static time_t lasttime = 0;
    static int framecnt = 0;
#ifdef OHQ_FAST
	static int lastx = 0, lasty = 0, lastex = 0, lastey = 0;
	static int tmpx = 0, tmpy = 0, tmpex = 0, tmpey = 0;
	int x = this->hidden->clip.x-1, y = this->hidden->clip.y-1, cw = this->hidden->clip.w+2, ch = this->hidden->clip.h+2, tw = this->hidden->width, th = this->hidden->height;
	int dbuf = (this->hidden->flags&SDL_DOUBLEBUF) != 0;

	if (dbuf) {
		tmpx = fmin(x, lastx);
		tmpy = fmin(y, lasty);
		tmpex = fmax(x+cw, lastex);
		tmpey = fmax(y+ch, lastey);
		lastx = x;
		lasty = y;
		lastex = x+cw;
		lastey = y+ch;
		x = tmpx;
		y = tmpy;
		cw = tmpex-x;
		ch = tmpey-y;
	}

    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x+cw > this->hidden->width) cw = this->hidden->width-x;
    if (y+ch > this->hidden->height) ch = this->hidden->height-y;

#else
	int dbuf = (this->hidden->flags&SDL_DOUBLEBUF) != 0;
	int x = 0, y = 0, cw = this->hidden->width, ch = this->hidden->height, tw = cw, th = ch;
#endif

    this->hidden->real_video->glActiveTexture(GL_TEXTURE0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D, this->hidden->texture[0]);
    this->hidden->postponed = 0;
    this->hidden->real_video->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y,
            tw, ch, this->hidden->framebuf_format,
        this->hidden->framebuf_datatype, this->hidden->framebuf+y*this->hidden->pitch);

    if (ack) SDL_SemPost(this->hidden->render_thread_ack);

#ifdef OGL_DEBUG_HQ_MAX
    GLubyte buffer[this->hidden->width*this->hidden->height*4];
    int fd = open("framebuf.pam",O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,0666);
    sprintf((char *)buffer,"P7\nWIDTH %i\nHEIGHT %i\nMAXVAL 255\nDEPTH 4\nTUPLTYPE RGB_ALPHA\nENDHDR\n",this->hidden->width,this->hidden->height);
    write(fd,buffer,strlen((char *)buffer));
    write(fd,this->hidden->framebuf,this->hidden->pitch*this->hidden->height*2);
    close(fd);
#endif

    /* align clip rectangle to reduce render errors due to rounding of coordinates, and add some padding */
    // seems not neccessary anymore
#define ALIGN 1
    int xe = x+cw+ALIGN+2, ye = y+ch+ALIGN+2;
    int ox = x-2, oy = y-2;
    ox = ((int)(x/ALIGN))*ALIGN;
    oy = ((int)(y/ALIGN))*ALIGN;
    xe = ((int)(xe/ALIGN))*ALIGN;
    ye = ((int)(ye/ALIGN))*ALIGN;
    if (ox < 0) ox = 0;
    if (oy < 0) oy = 0;
    if (xe > tw) xe = tw;
    if (ye > th) ye = th;
    int ocw = xe-ox;
    int och = ye-oy;

    int otw = this->hidden->outwidth;
    int oth = this->hidden->outheight;
    ox = floor(ox*otw/(double)tw);
    oy = floor((th-oy-och)*oth/(double)th);
    //oy = floor(oy*oth/(double)th);
    ocw = ceil(ocw*otw/(double)tw);
    och = ceil(och*oth/(double)th);

    if (!this->hidden->nohq) {
        this->hidden->real_video->glPushMatrix();
        if (this->hidden->fbo[0]) {
			OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, this->hidden->fbo[0]);
			this->hidden->real_video->glViewport(x,y,cw,ch);
		} else {
			// "failsafe" fallback for drivers without EXT_framebuffer_object, also see below
			// Performance and visual experience is degraded, but still enjoyable.
			if (!dbuf) {
				this->hidden->real_video->glDrawBuffer(GL_BACK);
				this->hidden->real_video->glReadBuffer(GL_BACK);
			}
			this->hidden->real_video->glViewport(ox,oy,cw,ch);
		}

        this->hidden->real_video->glTranslated(-1,-1,0);
        this->hidden->real_video->glScaled(tw/(double)cw,th/(double)ch,1);
        this->hidden->real_video->glTranslated(1.0-(x/(double)tw*2),1.0-(y/(double)th*2),0);

        OHQNAME(glBindProgramARB)(GL_FRAGMENT_PROGRAM_ARB,this->hidden->program_name[0]);
        OHQNAME(glProgramLocalParameter4dARB)(GL_FRAGMENT_PROGRAM_ARB, 0,
            ((double)this->hidden->static_threshold)/255.0, 0.0,
            0.0, ((double)this->hidden->dynamic_threshold)/100.0);
        OHQNAME(glProgramEnvParameter4dARB)(GL_FRAGMENT_PROGRAM_ARB, 0,
            1.0d/this->hidden->texsize-1.0d/4096, 1.0d/this->hidden->texsize-1.0d/4096,
            this->hidden->texsize, this->hidden->texsize);
        
        this->hidden->real_video->glCallList(this->hidden->pbuffer_displaylist);
        this->hidden->real_video->glFinish();

        this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,this->hidden->texture[1]);
        if (this->hidden->fbo[0]) OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, this->hidden->fbo[1]);
		else this->hidden->real_video->glCopyTexSubImage2D(GL_TEXTURE_2D, 0, x, y, ox, oy, cw, ch);

#ifdef OGL_DEBUG_HQ_MAX
        fd = open("diff1.pam",O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,0666);
        sprintf((char *)buffer,"P7\nWIDTH %i\nHEIGHT %i\nMAXVAL 255\nDEPTH 4\nTUPLTYPE RGB_ALPHA\nENDHDR\n",this->hidden->width,this->hidden->height);
        write(fd,buffer,strlen((char *)buffer));
        this->hidden->real_video->glReadPixels(0,0,this->hidden->width,this->hidden->height,GL_RGBA,GL_UNSIGNED_BYTE,buffer);
        write(fd,buffer,sizeof(buffer));
        close(fd);
#endif

        OHQNAME(glBindProgramARB)(GL_FRAGMENT_PROGRAM_ARB,this->hidden->program_name[1]);
        OHQNAME(glProgramLocalParameter4dARB)(GL_FRAGMENT_PROGRAM_ARB, 0,
            ((double)this->hidden->static_threshold)/255.0, 0.0,
            0.0, ((double)this->hidden->dynamic_threshold)/100.0);

        this->hidden->real_video->glCallList(this->hidden->pbuffer_displaylist);
        this->hidden->real_video->glFinish();

        this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,this->hidden->texture[0]);

        this->hidden->real_video->glActiveTexture(GL_TEXTURE1);
        this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,this->hidden->texture[2]);

        if (this->hidden->fbo[0]) OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, 0);
		else {
			this->hidden->real_video->glCopyTexSubImage2D(GL_TEXTURE_2D, 0, x, y, ox, oy, cw, ch);
			if (!dbuf) {
				this->hidden->real_video->glDrawBuffer(GL_FRONT);
				this->hidden->real_video->glReadBuffer(GL_FRONT);
			}
		}

#ifdef OGL_DEBUG_HQ_MAX
        fd = open("diff2.pam",O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,0666);
        sprintf((char *)buffer,"P7\nWIDTH %i\nHEIGHT %i\nMAXVAL 255\nDEPTH 4\nTUPLTYPE RGB_ALPHA\nENDHDR\n",this->hidden->width,this->hidden->height);
        write(fd,buffer,strlen((char *)buffer));
        this->hidden->real_video->glReadPixels(0,0,this->hidden->width,this->hidden->height,GL_RGBA,GL_UNSIGNED_BYTE,buffer);
        write(fd,buffer,sizeof(buffer));
        close(fd);
#endif

        this->hidden->real_video->glActiveTexture(GL_TEXTURE0);

        OHQNAME(glBindProgramARB)(GL_FRAGMENT_PROGRAM_ARB,this->hidden->program_name[2]);
        OHQNAME(glProgramEnvParameter4dARB)(GL_FRAGMENT_PROGRAM_ARB, 0,
            1.0d/this->hidden->texsize, 1.0d/this->hidden->texsize,
            this->hidden->texsize, this->hidden->texsize);

        this->hidden->real_video->glPopMatrix();
    }

    this->hidden->real_video->glViewport(ox,oy,ocw,och);
    this->hidden->real_video->glPushMatrix();
    this->hidden->real_video->glTranslated(-1,-1,0);
    this->hidden->real_video->glScaled(otw/(double)ocw,oth/(double)och,1);
    this->hidden->real_video->glTranslated(1.0-(ox/(double)otw*2),1.0-(oy/(double)oth*2),0);
    this->hidden->real_video->glCallList(this->hidden->displaylist);
    this->hidden->real_video->glPopMatrix();

    if (dbuf) this->hidden->real_video->GL_SwapBuffers(this->hidden->real_video);

    if (showfps) {
        time_t now = time(NULL);
        framecnt++;

        if (lasttime == 0) {
            lasttime = now;
        } else if (now > lasttime+10) {
            fprintf(stderr, "SDL OpenGL-HQ FPS: %li\n", framecnt/(now-lasttime));
            lasttime = now;
            framecnt = 0;
        }
    }
    this->hidden->real_video->glFlush();

    return 1;
}

static int InitOpenGL(_THIS) {
    int w, h, bpp;
    int border, x, y, texsize;
    SDL_Surface *surface;
    GLfloat tex_width, tex_height;
    GLubyte *texture;
    double xsize, ysize;
    unsigned char table[4096] = SDL_openglhq_table_dat;
	int has_fbo = 1;
//	double adjust = 0;

    showfps = getenv("SDL_OPENGLHQ_SHOWFPS") != NULL;

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);//(this->hidden->flags&SDL_DOUBLEBUF)!=0);
    if (this->hidden->flags & SDL_FULLSCREEN) {
       const char *res, *res2;
       if ((res = getenv("SDL_OPENGLHQ_FULLRES")) != NULL) {
           w = atoi(res);
           res2 = strchr(res,'x');
           if (res2 == NULL) {
               double scale = strtod(res,NULL);
               w = (int)(this->hidden->width*scale);
               h = (int)(this->hidden->height*scale);
               bpp = this->hidden->format.BitsPerPixel;
           } else {
               h = atoi(res2+1);
               res = strchr(res,'-');
               if (res != NULL) {
                   bpp = atoi(res+1);
               } else {
                   bpp = this->hidden->format.BitsPerPixel;
                   }
           }
       } else {
           w = this->hidden->screen_width;
           h = this->hidden->screen_height;
           bpp = this->hidden->format.BitsPerPixel;
       }
    } else {
       const char *res, *res2;
       if ((res = getenv("SDL_OPENGLHQ_WINRES")) != NULL) {
           w = atoi(res);
           res2 = strchr(res,'x');
           if (res2 == NULL) {
               double scale = strtod(res,NULL);
               w = (int)(this->hidden->width*scale);
               h = (int)(this->hidden->height*scale);
               bpp = this->hidden->format.BitsPerPixel;
           } else {
               h = atoi(res2+1);
               res = strchr(res,'-');
               if (res != NULL) {
                   bpp = atoi(res+1);
               } else {
                   bpp = this->hidden->format.BitsPerPixel;
           }
               }
       } else {
           w = this->hidden->width;
           h = this->hidden->height;
           bpp = this->hidden->format.BitsPerPixel;
       }
    }

    if (w <= 0 || h <= 0) {
       SDL_SetError("Invalid mode specification in SDL_OPENGLHQ_WINRES/SDL_OPENGLHQ_FULLRES");
       return 0;
    }
    if (w > this->hidden->screen_width || h > this->hidden->screen_height) {
       w = this->hidden->screen_width;
       h = this->hidden->screen_height;
    }

    surface = SDL_SetVideoMode(w,h,bpp,SDL_OPENGL|(this->hidden->flags&SDL_FULLSCREEN));
    if (surface == NULL) {
        SDL_SetError("OPENGLHQ: Can't open drawing surface, are you running in 16bpp (or higher) mode?");
        return 0;
    }
    this->hidden->outwidth = surface->w;
    this->hidden->outheight = surface->h;

    if (this->hidden->max_texsize == 0) {
        const char * gl_ext = (const char *)this->hidden->real_video->glGetString(GL_EXTENSIONS);

        if (getenv("SDL_OPENGLHQ_STATIC") != NULL) this->hidden->static_threshold = atoi(getenv("SDL_OPENGLHQ_STATIC"));
        else this->hidden->static_threshold = 10;
        if (this->hidden->static_threshold > 255) this->hidden->static_threshold = 255;
        if (this->hidden->static_threshold < 0) this->hidden->static_threshold = 0;
        if (getenv("SDL_OPENGLHQ_DYNAMIC") != NULL) this->hidden->dynamic_threshold = atoi(getenv("SDL_OPENGLHQ_DYNAMIC"));
        else this->hidden->dynamic_threshold = 33;
        if (this->hidden->dynamic_threshold > 100) this->hidden->dynamic_threshold = 100;
        if (this->hidden->dynamic_threshold < 0) this->hidden->dynamic_threshold = 0;

        this->hidden->real_video->glGetIntegerv(GL_MAX_TEXTURE_SIZE, &this->hidden->max_texsize);
        OHQNAME(glPixelDataRangeNV) = (PFNGLPIXELDATARANGENVPROC)SDL_GL_GetProcAddress("glPixelDataRangeNV");
        OHQNAME(glColorTableEXT) = (PFNGLCOLORTABLEEXTPROC)SDL_GL_GetProcAddress("glColorTableEXT");

        if (gl_ext != NULL && *gl_ext) {
            this->hidden->has_pixel_data_range=(strstr(gl_ext,"GL_NV_pixel_data_range") != NULL) && OHQNAME(glPixelDataRangeNV) != NULL;
            this->hidden->allow_paletted_texture=(strstr(gl_ext,"EXT_paletted_texture") != NULL) && OHQNAME(glColorTableEXT) != NULL;

        }

        if (this->hidden->has_pixel_data_range) {
            OHQ_malloc = (OHQ_malloc_t)SDL_GL_GetProcAddress("wglAllocateMemoryNV");
            if (OHQ_malloc == NULL) OHQ_malloc = (OHQ_malloc_t)SDL_GL_GetProcAddress("glXAllocateMemoryNV");
            OHQ_free = (OHQ_free_t)SDL_GL_GetProcAddress("wglFreeMemoryNV");
            if (OHQ_free == NULL) OHQ_free = (OHQ_free_t)SDL_GL_GetProcAddress("glXFreeMemoryNV");
        }
        if (OHQ_malloc == NULL) OHQ_malloc = (OHQ_malloc_t)default_malloc;
        if (OHQ_free == NULL) OHQ_free = (OHQ_free_t)default_free;

        OHQNAME(glProgramStringARB) = (PFNGLPROGRAMSTRINGARBPROC)SDL_GL_GetProcAddress("glProgramStringARB");
        OHQNAME(glBindProgramARB) = (PFNGLBINDPROGRAMARBPROC)SDL_GL_GetProcAddress("glBindProgramARB");
        OHQNAME(glGenProgramsARB) = (PFNGLGENPROGRAMSARBPROC)SDL_GL_GetProcAddress("glGenProgramsARB");
        OHQNAME(glDeleteProgramsARB) = (PFNGLDELETEPROGRAMSARBPROC)SDL_GL_GetProcAddress("glDeleteProgramsARB");
        OHQNAME(glGetProgramivARB) = (PFNGLGETPROGRAMIVARBPROC)SDL_GL_GetProcAddress("glGetProgramivARB");
        OHQNAME(glProgramLocalParameter4dARB) = (PFNGLPROGRAMLOCALPARAMETER4DARBPROC)SDL_GL_GetProcAddress("glProgramLocalParameter4dARB");
        OHQNAME(glProgramEnvParameter4dARB) = (PFNGLPROGRAMENVPARAMETER4DARBPROC)SDL_GL_GetProcAddress("glProgramEnvParameter4dARB");

        if (!gl_ext || !*gl_ext || !((strstr(gl_ext,"ARB_fragment_program") != NULL) &&
                OHQNAME(glProgramStringARB) && OHQNAME(glBindProgramARB) && OHQNAME(glGenProgramsARB) && OHQNAME(glDeleteProgramsARB) &&
                OHQNAME(glGetProgramivARB) && OHQNAME(glProgramLocalParameter4dARB) && OHQNAME(glProgramEnvParameter4dARB))) {
            SDL_SetError("OPENGLHQ: Video driver doesn't support fragment programs");
            return 0;
        }

        OHQNAME(glGenFramebuffersEXT) = (PFNGLGENFRAMEBUFFERSEXTPROC)SDL_GL_GetProcAddress("glGenFramebuffersEXT");
        OHQNAME(glBindFramebufferEXT) = (PFNGLBINDFRAMEBUFFEREXTPROC)SDL_GL_GetProcAddress("glBindFramebufferEXT");
        OHQNAME(glCheckFramebufferStatusEXT) = (PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC)SDL_GL_GetProcAddress("glCheckFramebufferStatusEXT");
        OHQNAME(glFramebufferTexture2DEXT) = (PFNGLFRAMEBUFFERTEXTURE2DEXTPROC)SDL_GL_GetProcAddress("glFramebufferTexture2DEXT");
        OHQNAME(glDeleteFramebuffersEXT) = (PFNGLDELETEFRAMEBUFFERSEXTPROC)SDL_GL_GetProcAddress("glDeleteFramebuffersEXT");

        if(!OHQNAME(glGenFramebuffersEXT) || !OHQNAME(glBindFramebufferEXT) ||
            !OHQNAME(glFramebufferTexture2DEXT) || !OHQNAME(glDeleteFramebuffersEXT) ||
			(strstr(gl_ext,"GL_EXT_framebuffer_object") == NULL)) {
			has_fbo = 0;
			fprintf(stderr, "OPENGLHQ: Video driver doesn't support framebuffer objects. Using slow fallback renderer.\n");
        }

    }

    this->hidden->framebuf_format = GL_BGRA_EXT;
    this->hidden->framebuf_datatype = GL_UNSIGNED_BYTE;
    if (this->hidden->bpp == 8 && !this->hidden->allow_paletted_texture) {
        this->hidden->bpp = this->hidden->format.BitsPerPixel;
    }
    if (this->hidden->bpp == 8) {
        this->hidden->framebuf_format = GL_COLOR_INDEX8_EXT;
        OHQNAME(glColorTableEXT)(GL_TEXTURE_2D,GL_RGBA8,256,GL_RGBA,GL_UNSIGNED_BYTE,this->hidden->pal);
    } else if (this->hidden->bpp == 15) {
        this->hidden->framebuf_format = GL_BGRA_EXT;
        this->hidden->framebuf_datatype = GL_UNSIGNED_SHORT_1_5_5_5_REV;
    } else if (this->hidden->bpp == 16) {
        this->hidden->framebuf_format = GL_RGB;
        this->hidden->framebuf_datatype = GL_UNSIGNED_SHORT_5_6_5;
    } else {
        this->hidden->bpp = 32;
    }

    texsize=this->hidden->texsize=2 << int_log2(this->hidden->width > this->hidden->height ? this->hidden->width : this->hidden->height);
    texsize=this->hidden->texsize=2 << int_log2(this->hidden->width > this->hidden->height ? this->hidden->width : this->hidden->height);
    tex_width=((GLfloat)(this->hidden->width)/(GLfloat)texsize);
    tex_height=((GLfloat)(this->hidden->height)/(GLfloat)texsize);

    if (texsize>this->hidden->max_texsize) {
        SDL_SetError("OPENGLHQ: No support for texturesize of %d, falling back to surface",texsize);
        return 0;
    }

    /* Create the texture and display list */
    this->hidden->real_video->glMatrixMode(GL_PROJECTION);
    this->hidden->real_video->glGenTextures(4,this->hidden->texture);

    this->hidden->pitch=this->hidden->width*((this->hidden->bpp+7)/8);
    this->hidden->framebuf = OHQ_malloc(this->hidden->pitch*this->hidden->height+MALLOC_ALIGN,0.0,1.0,1.0);;

    if (this->hidden->has_pixel_data_range) {
        OHQNAME(glPixelDataRangeNV)(GL_WRITE_PIXEL_DATA_RANGE_NV,this->hidden->width*this->hidden->height*4,this->hidden->framebuf);
        this->hidden->real_video->glEnableClientState(GL_WRITE_PIXEL_DATA_RANGE_NV);
    }

    if ((this->hidden->program_name[0] = LoadNativeFragmentProgram(this, SDL_openglhq_pass1_fp,"SDL_openglhq_pass1")) == 0 ||
        (this->hidden->program_name[1] = LoadNativeFragmentProgram(this, SDL_openglhq_pass2_fp,"SDL_openglhq_pass2")) == 0 ||
        (this->hidden->program_name[2] = LoadNativeFragmentProgram(this, SDL_openglhq_pass3_fp,"SDL_openglhq_pass3")) == 0) {
        SDL_SetError("OPENGLHQ: Hardware doesn't support this output");
        return 0;
    }

    this->hidden->nohq = 1;
    this->hidden->fbo[0] = this->hidden->fbo[1] = 0;
    if (this->hidden->width < this->hidden->outwidth && this->hidden->height < this->hidden->outheight) {
        this->hidden->nohq = 0;

        this->hidden->real_video->glBindTexture(GL_TEXTURE_2D, this->hidden->texture[1]);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        this->hidden->real_video->glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, texsize, texsize, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

        this->hidden->real_video->glBindTexture(GL_TEXTURE_2D, this->hidden->texture[2]);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        this->hidden->real_video->glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, texsize, texsize, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

        if (has_fbo) {
			OHQNAME(glGenFramebuffersEXT)(2, this->hidden->fbo);

			OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, this->hidden->fbo[0]);
			OHQNAME(glFramebufferTexture2DEXT)(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, this->hidden->texture[1], 0);

			OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, this->hidden->fbo[1]);
			OHQNAME(glFramebufferTexture2DEXT)(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, this->hidden->texture[2], 0);

			OHQNAME(glBindFramebufferEXT)(GL_FRAMEBUFFER_EXT, 0);
		}
    }

	if ((this->hidden->flags&SDL_DOUBLEBUF) == 0) {
		this->hidden->real_video->glDrawBuffer(GL_FRONT);
		this->hidden->real_video->glReadBuffer(GL_FRONT);
	}
	this->hidden->real_video->glActiveTexture(GL_TEXTURE2);
    this->hidden->real_video->glEnable(GL_TEXTURE_3D);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_3D, this->hidden->texture[3]);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_COMBINE);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_COMBINE_RGB,GL_REPLACE);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_COMBINE_ALPHA,GL_REPLACE);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_SRC0_RGB,GL_TEXTURE0);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_OPERAND0_RGB,GL_SRC_COLOR);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_SRC0_ALPHA,GL_TEXTURE0);
    this->hidden->real_video->glTexEnvi(GL_TEXTURE_ENV,GL_OPERAND0_ALPHA,GL_SRC_ALPHA);

    texture = (GLubyte *)malloc(OHQ_RESOLUTION*OHQ_RESOLUTION*4096*4);
    xsize = (double)this->hidden->width/(double)this->hidden->outwidth;
    ysize = (double)this->hidden->height/(double)this->hidden->outheight;

    /*
    Table layout is a bit convoluted to be better processable in
    fragment programs and to save space. Use the table builder
    to modify it. If you are interested in details, read its source.
    */
    if (getenv("SDL_OPENGLHQ_DATA")) {
        char file[4096];
        int tablefd;
        strcpy(file,getenv("SDL_OPENGLHQ_DATA"));
        strcat(file,"openglhq_table.dat");
        if ((tablefd = open(file,O_RDONLY|O_BINARY)) >= 0) {
            read(tablefd,table,sizeof(table));
            close(tablefd);
        }
    }

#define R 1
#define T 2
#define RT 4
#define RT2 8
#define L 16
#define LB2 32
#define LT2 64
#define LT 128
#define LB 256
#define B 512
#define RB2 1024
#define RB 2048

#define NODIAG 0x90
#define H 1
#define V 2
#define D 4

#define hmirror(p) swap_bits(swap_bits(swap_bits(swap_bits(swap_bits(p,R,L),RT,LT),RT2,LT2),RB,LB),RB2,LB2)
#define vmirror(p) swap_bits(swap_bits(swap_bits(swap_bits(swap_bits(p,T,B),RT,RB),RT2,RB2),LT,LB),LT2,LB2)
#define NO_BORDER(x) ((b&(x)) == 0)
#define IS_BORDER(x) ((b&(x)) == (x))
#define SETINTERP(percentage_inside) setinterp(xcenter,ycenter,percentage_inside, \
                        NO_BORDER(R),NO_BORDER(T),NO_BORDER(RT), \
                        IS_BORDER(R),IS_BORDER(T),IS_BORDER(RT), \
                        texture+((x+(border%16)*OHQ_RESOLUTION+y*16*OHQ_RESOLUTION+(border&~15)*OHQ_RESOLUTION*OHQ_RESOLUTION)*4))

/*	if (getenv("SDL_OPENGLHQ_ADJUST"))
		adjust = atof(getenv("SDL_OPENGLHQ_ADJUST"));
	if (adjust == 0) adjust = 1.025; //1.0438 = ATI fglrx; 1.025 = generic
*/
#define adjust 1
	OHQNAME(glProgramEnvParameter4dARB)(GL_FRAGMENT_PROGRAM_ARB, 1, 1.0d/.875d, -(1.0d/.875d-1.0d)/2, .875/adjust, (1-.875/adjust)/2);

    for (border = 0; border < 4096; border++) {
        for (y = 0; y < OHQ_RESOLUTION; y++) {
            for (x = 0; x < OHQ_RESOLUTION; x++) {
                double xcenter = fabs((((double)x)+.5)/(double)(OHQ_RESOLUTION)-.5)*adjust;
                double ycenter = fabs((((double)y)+.5)/(double)(OHQ_RESOLUTION)-.5)*adjust;
                int sx = (x < OHQ_RESOLUTION/2?-1:1);
                int sy = (y < OHQ_RESOLUTION/2?-1:1);
                int b = (sy > 0?(sx > 0?border:hmirror(border)):(sx > 0?vmirror(border):vmirror(hmirror(border))));

                if ((table[b] & NODIAG) == NODIAG) {
                    if (table[b] & H) {
                        if (table[b] & V) {
                            if (table[b] & D) SETINTERP(intersect_hvd(xcenter,ycenter,xsize,ysize));
                            else SETINTERP(intersect_hv(xcenter,ycenter,xsize,ysize));
                        } else {
                            SETINTERP(intersect_h(xcenter,ycenter,xsize,ysize));
                        }
                    } else if (table[b] & V) {
                        SETINTERP(intersect_v(xcenter,ycenter,xsize,ysize));
                    } else {
                        SETINTERP(1.0);
                    }
                } else {
                    double yoff = (table[b]&4?1:-1)*(((table[b] >> 3) & 3) + 1)/4.0;
                    double grad = (table[b]&32?1:-1)*(((table[b] >> 6) & 3) + 1)/2.0;
                    if (table[b] & H) {
                        if (table[b] & V) {
                            SETINTERP(intersect_any_hv(xcenter,ycenter,xsize,ysize,yoff,grad));
                        } else {
                            SETINTERP(intersect_any_h(xcenter,ycenter,xsize,ysize,yoff,grad));
                        }
                    } else if (table[b] & V) {
                        SETINTERP(intersect_any_v(xcenter,ycenter,xsize,ysize,yoff,grad));
                    } else {
                        SETINTERP(intersect_any(xcenter,ycenter,xsize,ysize,yoff,grad));
                    }
                }

            }
        }
    }
#ifdef OGL_DEBUG_HQ_MAX
    int fd = open("texture.pam",O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,0666);
    sprintf((char *)table,"P7\nWIDTH %i\nHEIGHT %i\nMAXVAL 255\nDEPTH 4\nTUPLTYPE RGB_ALPHA\nENDHDR\n",16*OHQ_RESOLUTION,4096/16*OHQ_RESOLUTION);
    write(fd,table,strlen((char *)table));
    write(fd,texture,OHQ_RESOLUTION*OHQ_RESOLUTION*4096*4);
    close(fd);
#endif

    this->hidden->real_video->glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA8, 16*OHQ_RESOLUTION, OHQ_RESOLUTION, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture);
    free(texture);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

    this->hidden->real_video->glActiveTexture(GL_TEXTURE0);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D,this->hidden->texture[0]);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    GLenum filter = (this->hidden->nohq?GL_LINEAR:GL_NEAREST);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
    this->hidden->real_video->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);

    this->hidden->real_video->glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, texsize, texsize, 0, this->hidden->framebuf_format, GL_UNSIGNED_BYTE, NULL);
    this->hidden->real_video->glFinish();

    this->hidden->real_video->glShadeModel(GL_FLAT);
    this->hidden->real_video->glDisable(GL_DEPTH_TEST);
    this->hidden->real_video->glDisable(GL_ALPHA_TEST);
    this->hidden->real_video->glDisable(GL_STENCIL_TEST);
    this->hidden->real_video->glDisable(GL_SCISSOR_TEST);
    this->hidden->real_video->glDisable(GL_BLEND);
    this->hidden->real_video->glDisable(GL_DITHER);
    this->hidden->real_video->glDisable(GL_INDEX_LOGIC_OP);
    this->hidden->real_video->glDisable(GL_COLOR_LOGIC_OP);
    this->hidden->real_video->glDisable(GL_LIGHTING);
    this->hidden->real_video->glDisable(GL_CULL_FACE);
    this->hidden->real_video->glDisable(GL_FOG);
    this->hidden->real_video->glEnable(GL_TEXTURE_2D);
    if (this->hidden->nohq) {
        this->hidden->real_video->glDisable(GL_FRAGMENT_PROGRAM_ARB);
    } else {
        this->hidden->real_video->glEnable(GL_FRAGMENT_PROGRAM_ARB);
    }
    this->hidden->real_video->glMatrixMode(GL_MODELVIEW);
    this->hidden->real_video->glLoadIdentity();

    this->hidden->pbuffer_displaylist = this->hidden->real_video->glGenLists(1);
    this->hidden->real_video->glNewList(this->hidden->pbuffer_displaylist, GL_COMPILE);
    this->hidden->real_video->glBegin(GL_QUADS);
    this->hidden->real_video->glTexCoord2f(0,0); this->hidden->real_video->glVertex2f(-1.0f,-1.0f);
    this->hidden->real_video->glTexCoord2f(tex_width,0); this->hidden->real_video->glVertex2f(1.0f, -1.0f);
    this->hidden->real_video->glTexCoord2f(tex_width,tex_height); this->hidden->real_video->glVertex2f(1.0f, 1.0f);
    this->hidden->real_video->glTexCoord2f(0,tex_height); this->hidden->real_video->glVertex2f(-1.0f, 1.0f);
    this->hidden->real_video->glEnd();
    this->hidden->real_video->glEndList();

    this->hidden->displaylist = this->hidden->real_video->glGenLists(1);
    this->hidden->real_video->glNewList(this->hidden->displaylist, GL_COMPILE);
    this->hidden->real_video->glBindTexture(GL_TEXTURE_2D, this->hidden->texture[0]);
    this->hidden->real_video->glBegin(GL_QUADS);
    this->hidden->real_video->glTexCoord2f(0,tex_height); this->hidden->real_video->glVertex2f(-1.0f,-1.0f);
    this->hidden->real_video->glTexCoord2f(tex_width,tex_height); this->hidden->real_video->glVertex2f(1.0f, -1.0f);
    this->hidden->real_video->glTexCoord2f(tex_width,0); this->hidden->real_video->glVertex2f(1.0f, 1.0f);
    this->hidden->real_video->glTexCoord2f(0,0); this->hidden->real_video->glVertex2f(-1.0f, 1.0f);
    this->hidden->real_video->glEnd();
    this->hidden->real_video->glEndList();
    this->hidden->real_video->glFinish();
    return 1;
}

static int RenderThread(void *data) {
    SDL_VideoDevice *this = (SDL_VideoDevice *)data;
    SDL_Rect **modes;
    const char *driver;
    this->hidden->status = OGL_DONE;
    current_video = NULL;
    if ((driver = getenv("SDL_OPENGLHQ_VIDEODRIVER")) != NULL && !strcmp(driver,"openglhq")) driver = NULL;
    SDL_VideoInit(driver, 0);
    if (current_video == NULL) {
        SDL_SetError("Unable to initialize backend video device, check SDL_OPENGLHQ_VIDEODRIVER");
        this->hidden->status = OGL_ERROR;
    } else {
        current_video->GL_LoadLibrary(current_video,NULL);
        if (current_video->GetDesktopMode != NULL) {
            current_video->GetDesktopMode(current_video,&this->hidden->screen_width,&this->hidden->screen_height);
        } else {
            modes = SDL_ListModes(NULL,SDL_OPENGL|SDL_FULLSCREEN);
            if (((intptr_t)modes) != -1 && modes && *modes) {
                this->hidden->screen_width = modes[0]->w;
                this->hidden->screen_height = modes[0]->h;
            }
        }
    }
    SDL_SemPost(this->hidden->render_thread_ack);

    while (SDL_SemWait(this->hidden->render_thread_signal) >= 0) {
        if (this->hidden->postponed && this->hidden->cmd != OGL_FRAME) {
                RenderFrame(this, 0);
        }

        this->hidden->status = OGL_DONE;

        if (this->hidden->cmd == OGL_CALL) {
            switch (this->hidden->call.type) {
            case OGL_CALL_P:
                this->hidden->call.func.p(this->hidden->real_video);
                break;
            case OGL_CALL_PII:
                this->hidden->call.func.pii(this->hidden->real_video,(int)this->hidden->call.args[0],(int)this->hidden->call.args[1]);
                break;
            case OGL_CALL_PPP:
                this->hidden->call.func.ppp(this->hidden->real_video,(const void*)this->hidden->call.args[0],(const void*)this->hidden->call.args[1]);
                break;
            case OGL_CALL_PP:
                this->hidden->call.func.pp(this->hidden->real_video,(const void*)this->hidden->call.args[0]);
                break;
            case OGL_CALL_PPPIIII_P:
                this->hidden->call.result = (intptr_t)this->hidden->call.func.pppiiii_p(this->hidden->real_video,(const void*)this->hidden->call.args[0],(const void*)this->hidden->call.args[1],
                                    (int)this->hidden->call.args[2],(int)this->hidden->call.args[3],(int)this->hidden->call.args[4],(int)this->hidden->call.args[5]);
                break;
            case OGL_CALL_PP_I:
                this->hidden->call.result = (intptr_t)this->hidden->call.func.pp_i(this->hidden->real_video,(const void*)this->hidden->call.args[0]);
                break;
            case OGL_CALL_P_I:
                this->hidden->call.result = (intptr_t)this->hidden->call.func.p_i(this->hidden->real_video);
                break;
            case OGL_CALL_PI_I:
                this->hidden->call.result = (intptr_t)this->hidden->call.func.pi_i(this->hidden->real_video,(int)this->hidden->call.args[0]);
                break;
            default:
                this->hidden->status = OGL_ERROR;
            }

        } else if (this->hidden->cmd == OGL_INIT) {
            if (!InitOpenGL(this)) {
                this->hidden->status = OGL_ERROR;
                DeinitOpenGL(this);
            }

			// FIXME: ugly hack that probably only works on Linux, improves app responsiveness
			setpriority(PRIO_PROCESS, getpid()+1, 19);
			{  // This is a bit more portable (should work on any POSIX/pthreads system), but SCHED_IDLE is ineffective on unpatched Linux
				struct sched_param param = { 0 };
				pthread_setschedparam(pthread_self(), SCHED_IDLE, &param);
			}

        } else if (this->hidden->cmd == OGL_DEINIT) {
            DeinitOpenGL(this);

        } else if (this->hidden->cmd == OGL_FRAME) {
            if (!RenderFrame(this, 1)) this->hidden->status = OGL_ERROR;

        } else if (this->hidden->cmd == OGL_PALETTE && this->hidden->allow_paletted_texture) {
			this->hidden->real_video->glActiveTexture(GL_TEXTURE0);
            OHQNAME(glColorTableEXT)(GL_TEXTURE_2D, GL_RGBA8, 256, GL_RGBA, GL_UNSIGNED_BYTE, this->hidden->pal);

        } else if (this->hidden->cmd == OGL_NONE) {

        } else if (this->hidden->cmd == OGL_QUIT) {
            break;

        } else {
            this->hidden->status = OGL_ERROR;
        }
        SDL_SemPost(this->hidden->render_thread_ack);
	}
    SDL_VideoQuit();
    SDL_SemPost(this->hidden->render_thread_ack);
    return 0;
}

static void StartRenderThread(_THIS) {
    this->hidden->cmd = OGL_DONE;
    this->hidden->render_thread_signal = SDL_CreateSemaphore(0);
    this->hidden->render_thread_ack = SDL_CreateSemaphore(0);
    this->hidden->render_thread = SDL_CreateThread(&RenderThread,this);
    SDL_SemWait(this->hidden->render_thread_ack);
}

static void ShutdownRenderThread(_THIS) {
    if (this->hidden->render_thread != NULL) {
        SendSyncCommand(this,OGL_DEINIT);
        SendSyncCommand(this,OGL_QUIT);
        SDL_WaitThread(this->hidden->render_thread, NULL);
        SDL_DestroySemaphore(this->hidden->render_thread_signal);
        SDL_DestroySemaphore(this->hidden->render_thread_ack);
        this->hidden->render_thread = NULL;
    }
}

