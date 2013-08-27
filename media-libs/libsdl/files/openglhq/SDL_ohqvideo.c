/*
        SDL - Simple DirectMedia Layer OpenGL-HQ scaling
    Copyright (C) 1997-2004 Sam Lantinga
    Copyright (C) 2005 Jörg Walter <jwalt@garni.ch>

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

/* SDL video driver implementation which outputs onto a scaled OpenGL-surface
   with high quality scaling optimized for framebuffer based games
*/

#define TRACE //do { fprintf(stderr,"%s:%i: %p->%s(...)\n",__FILE__,__LINE__,SDL_ThreadID(),__FUNCTION__); } while (0)
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#include "SDL.h"
#include "SDL_error.h"
#include "SDL_video.h"
#include "SDL_opengl.h"
#include "../SDL_pixels_c.h"
#include "../SDL_cursor_c.h"
#include "../SDL_sysvideo.h"
#include "../../events/SDL_events_c.h"
#include "SDL_ohqvideo.h"

#include "SDL_ohqthread.h"

#ifndef SDL_memcpy
#define SDL_memcpy memcpy
#endif

static void OHQ_MouseFilter(int relative, Sint16 *x, Sint16 *y);
extern void (*SDL_MouseFilter)(int relative, Sint16 *x, Sint16 *y);
static void (*OHQ_NextMouseFilter)(int relative, Sint16 *x, Sint16 *y) = (void *)-1;
static SDL_VideoDevice* filter_video = NULL;
static int OHQ_VideoInit(_THIS, SDL_PixelFormat *vformat);

/* OHQ driver bootstrap functions */

static int OHQ_Available(void)
{
    return 1;
}

static void OHQ_DeleteDevice(SDL_VideoDevice *device)
{
    free(device->hidden);
    free(device);
}

static void OHQ_Call(_THIS, void (*func)(SDL_VideoDevice*))
{
    if (this->VideoInit != OHQ_VideoInit) {
        func(this);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        func(this->hidden->real_video);
    } else {
        this->hidden->call.type = OGL_CALL_P;
        this->hidden->call.func.p = func;
        SendSyncCommand(this,OGL_CALL);
    }
}

static void OHQ_Call_ii(_THIS, void (*func)(SDL_VideoDevice*,int,int), int arg1, int arg2)
{
    if (this->VideoInit != OHQ_VideoInit) {
        func(this,arg1,arg2);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        func(this->hidden->real_video,arg1,arg2);
    } else {
        this->hidden->call.type = OGL_CALL_PII;
        this->hidden->call.func.pii = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        this->hidden->call.args[1] = (intptr_t)arg2;
        SendSyncCommand(this,OGL_CALL);
    }
}

static void OHQ_Call_pp(_THIS, void (*func)(SDL_VideoDevice*,const void*,const void*), const void* arg1, const void* arg2)
{
    if (this->VideoInit != OHQ_VideoInit) {
        func(this,arg1,arg2);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        func(this->hidden->real_video,arg1,arg2);
    } else {
        this->hidden->call.type = OGL_CALL_PPP;
        this->hidden->call.func.ppp = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        this->hidden->call.args[1] = (intptr_t)arg2;
        SendSyncCommand(this,OGL_CALL);
    }
}

static void OHQ_Call_p(_THIS, void (*func)(SDL_VideoDevice*,const void*), const void* arg1)
{
    if (this->VideoInit != OHQ_VideoInit) {
        func(this,arg1);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        func(this->hidden->real_video,arg1);
    } else {
        this->hidden->call.type = OGL_CALL_PP;
        this->hidden->call.func.pp = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        SendSyncCommand(this,OGL_CALL);
    }
}

static int OHQ_Call_p_i(_THIS, int (*func)(SDL_VideoDevice*,const void*), const void* arg1)
{
    if (this->VideoInit != OHQ_VideoInit) {
        return func(this,arg1);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        return func(this->hidden->real_video,arg1);
    } else {
        this->hidden->call.type = OGL_CALL_PP_I;
        this->hidden->call.func.pp_i = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        SendSyncCommand(this,OGL_CALL);
        return (int)this->hidden->call.result;
    }
}

static int OHQ_Call__i(_THIS, int (*func)(SDL_VideoDevice*))
{
    if (this->VideoInit != OHQ_VideoInit) {
        return func(this);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        return func(this->hidden->real_video);
    } else {
        this->hidden->call.type = OGL_CALL_P_I;
        this->hidden->call.func.p_i = func;
        SendSyncCommand(this,OGL_CALL);
        return (int)this->hidden->call.result;
    }
}

static int OHQ_Call_i_i(_THIS, int (*func)(SDL_VideoDevice*,int), int arg1)
{
    if (this->VideoInit != OHQ_VideoInit) {
        return func(this,arg1);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        return func(this->hidden->real_video,arg1);
    } else {
        this->hidden->call.type = OGL_CALL_PI_I;
        this->hidden->call.func.pi_i = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        SendSyncCommand(this,OGL_CALL);
        return (int)this->hidden->call.result;
    }
}

static void* OHQ_Call_ppiiii_p(_THIS, void* (*func)(SDL_VideoDevice*,const void*,const void*,int,int,int,int), const void* arg1, const void* arg2, int arg3, int arg4, int arg5, int arg6)
{
    if (this->VideoInit != OHQ_VideoInit) {
        return func(this,arg1,arg2,arg3,arg4,arg5,arg6);
    } else if (SDL_ThreadID() == SDL_GetThreadID(this->hidden->render_thread)) {
        return func(this->hidden->real_video,arg1,arg2,arg3,arg4,arg5,arg6);
    } else {
        this->hidden->call.type = OGL_CALL_PPPIIII_P;
        this->hidden->call.func.pppiiii_p = func;
        this->hidden->call.args[0] = (intptr_t)arg1;
        this->hidden->call.args[1] = (intptr_t)arg2;
        this->hidden->call.args[2] = (intptr_t)arg3;
        this->hidden->call.args[3] = (intptr_t)arg4;
        this->hidden->call.args[4] = (intptr_t)arg5;
        this->hidden->call.args[5] = (intptr_t)arg6;
        SendSyncCommand(this,OGL_CALL);
        return (void*)this->hidden->call.result;
    }
}

#define SAVE_VIDEO { SDL_VideoDevice *saved_video = current_video; current_video = this->hidden->real_video;
#define RESTORE_VIDEO current_video = saved_video; }
#define SAVE_SCREEN { SDL_Surface *saved_screen = this->hidden->real_video->screen; this->hidden->real_video->screen = this->screen;
#define RESTORE_SCREEN this->hidden->real_video->screen = saved_screen; }

static int OHQ_VideoInit(_THIS, SDL_PixelFormat *vformat)
{
    const SDL_VideoInfo *vinfo;

    SAVE_VIDEO;

    StartRenderThread(this);
    this->hidden->real_video = current_video;
    vinfo = SDL_GetVideoInfo();
    SDL_memcpy(vformat,(SDL_PixelFormat*)vinfo->vfmt,sizeof(*vinfo->vfmt));
    SDL_memcpy((void *)&this->hidden->format,(SDL_PixelFormat*)vinfo->vfmt,sizeof(*vinfo->vfmt));

    RESTORE_VIDEO;

    return(0);
}

static void OHQ_SwitchOff(_THIS) {
    static char env[1024] = "SDL_VIDEODRIVER=";
    SendSyncCommand(this,OGL_NONE);
    current_video = this->hidden->real_video;
    strcat(env,current_video->name);
    ShutdownRenderThread(this);
    putenv(env);
    SDL_VideoInit(NULL,0);
    free(this->hidden);
    SDL_memcpy(this, current_video, sizeof(*current_video));
    current_video = this;
    if (OHQ_NextMouseFilter != (void *)-1) {
        SDL_MouseFilter = OHQ_NextMouseFilter;
        OHQ_NextMouseFilter = (void *)-1;
    }
}

static SDL_Rect **OHQ_ListModes(_THIS, SDL_PixelFormat *format, Uint32 flags) {
    if (flags & SDL_OPENGL) {
        OHQ_SwitchOff(this);
        return current_video->ListModes(current_video, format, flags);
    }
    return (SDL_Rect **)(intptr_t)(format->BitsPerPixel == 8 && !this->hidden->allow_paletted_texture?0:-1);
}

static SDL_Surface *OHQ_SetVideoMode(_THIS, SDL_Surface *current, int width, int height, int bpp, Uint32 flags) {
    if (flags & SDL_OPENGL) {
        OHQ_SwitchOff(this);
        return current_video->SetVideoMode(current_video,current,width,height,bpp,flags);
    }

    SDL_UnlockCursor();

    SendSyncCommand(this,OGL_NONE);
    filter_video = current_video;
    SAVE_VIDEO;
    if (!SendSyncCommand(this,OGL_DEINIT)) return NULL;
    if (this->hidden->surface == NULL) {
        this->hidden->surface = malloc(sizeof(*current));
        SDL_memcpy((SDL_Surface *)this->hidden->surface,current,sizeof(*current));
    }
	flags &= ~(SDL_HWPALETTE|SDL_HWSURFACE|SDL_ASYNCBLIT);

    // some video drivers can't handle odd widths properly
    width = (width+1)&~1;

    this->hidden->width = width;
    this->hidden->height = height;
    this->hidden->flags = flags;
    if (getenv("SDL_OPENGLHQ_DOUBLEBUF")) {
		if (getenv("SDL_OPENGLHQ_DOUBLEBUF")[0] == '1') this->hidden->flags |= SDL_DOUBLEBUF;
    	else this->hidden->flags &= ~(SDL_DOUBLEBUF);
	}
    this->hidden->bpp = bpp;
    this->hidden->postponed = 0;
    if (!SendSyncCommand(this,OGL_INIT)) return NULL;
    if (OHQ_NextMouseFilter == (void *)-1) {
        OHQ_NextMouseFilter = SDL_MouseFilter;
        SDL_MouseFilter = OHQ_MouseFilter;
    }
    bpp = this->hidden->bpp;

    if (!SDL_ReallocFormat(current, bpp, (bpp==32?0xff0000:bpp==16?0xf800:0x7c00), (bpp==32?0xff00:bpp==16?0x7e0:0x3e0), (bpp==32?0xff:0x1f), 0)) {
        return NULL;
    }

    current->w = this->hidden->width;
    current->h = this->hidden->height;
    current->pitch = this->hidden->pitch;
    current->flags = flags|SDL_PREALLOC;
    if (bpp == 8) current->flags |= SDL_HWPALETTE;
    current->pixels = this->hidden->framebuf;
    this->input_grab = this->hidden->real_video->input_grab;

    this->hidden->clip.x = 0;
    this->hidden->clip.y = 0;
    this->hidden->clip.w = current->w;
    this->hidden->clip.h = current->h;

    RESTORE_VIDEO;

    return current;
}

static void OHQ_UpdateMouse(_THIS) {
    SAVE_VIDEO;
    //SAVE_SCREEN;
    OHQ_Call(this,this->hidden->real_video->UpdateMouse);
    //RESTORE_SCREEN;
    RESTORE_VIDEO;
}

static int OHQ_SetColors(_THIS, int firstcolor, int ncolors, SDL_Color *colors) {
    int i, end = firstcolor+ncolors;
    if (end > 256) return 0;
    for (i = firstcolor; i < end; i++) {
        this->hidden->pal[i].r = colors[i].r;
        this->hidden->pal[i].g = colors[i].g;
        this->hidden->pal[i].b = colors[i].b;
        this->hidden->pal[i].a = 255;
    }
    SendSyncCommand(this,OGL_PALETTE);
    return 1;
}

static int OHQ_FlipHWSurface(_THIS, SDL_Surface *surface)
{
TRACE;
	if (!this->hidden->dirty) {
		if (surface->flags&SDL_DOUBLEBUF) SDL_UpdateRect(surface, 0, 0, 0, 0);
		return 0;
	}
	this->hidden->dirty = 0;
    if (!TryWaitCommand(this)) {
        this->hidden->postponed = 1;
        return 0;
    }

    SAVE_VIDEO;
    SendAsyncCommand(this,OGL_FRAME);
    SDL_SemWait(this->hidden->render_thread_ack);
    RESTORE_VIDEO;
    return 0;
}

static void OHQ_UpdateRects(_THIS, int numrects, SDL_Rect *rects) {
TRACE;
    int i, minx = this->hidden->width, miny = this->hidden->height, maxx = 0, maxy = 0;
    if (!numrects) return;

    if (this->hidden->postponed) {
        minx = this->hidden->clip.x;
        miny = this->hidden->clip.y;
        maxx = minx+this->hidden->clip.w;
        maxy = miny+this->hidden->clip.h;
    }

    for (i = 0; i < numrects; i++) {
        if (rects[i].x < minx) minx = rects[i].x;
        if (rects[i].y < miny) miny = rects[i].y;
        if (rects[i].x+rects[i].w > maxx) maxx = rects[i].x+rects[i].w;
        if (rects[i].y+rects[i].h > maxy) maxy = rects[i].y+rects[i].h;
    }

    this->hidden->clip.x = minx;
    this->hidden->clip.y = miny;
    this->hidden->clip.w = maxx-minx;
    this->hidden->clip.h = maxy-miny;
    this->hidden->dirty = 1;

    if (!(this->screen->flags&SDL_DOUBLEBUF)) OHQ_FlipHWSurface(this, this->screen);
    return;
}

static void OHQ_VideoQuit(_THIS) {
    SAVE_VIDEO;
    ShutdownRenderThread(this);
    if (OHQ_NextMouseFilter != (void *)-1) {
        SDL_MouseFilter = OHQ_NextMouseFilter;
        OHQ_NextMouseFilter = (void *)-1;
    }
    RESTORE_VIDEO;
}

static int OHQ_AllocHWSurface(_THIS, SDL_Surface *surface)
{
    return -1;
}

static void OHQ_FreeHWSurface(_THIS, SDL_Surface *surface)
{
    return;
}

static int OHQ_LockHWSurface(_THIS, SDL_Surface *surface)
{
TRACE;
    return 0;
}

static void OHQ_UnlockHWSurface(_THIS, SDL_Surface *surface)
{
TRACE;
    if (surface->flags&SDL_DOUBLEBUF) SDL_UpdateRect(surface, 0, 0, 0, 0);
    return;
}


static void OHQ_SetCaption(_THIS, const char *title, const char *icon) {
    SAVE_VIDEO;
    OHQ_Call_pp(this, (void (*)(SDL_VideoDevice*,const void*,const void*))this->hidden->real_video->SetCaption, title, icon);
    RESTORE_VIDEO;
}

static void OHQ_SetIcon(_THIS, SDL_Surface *icon, Uint8 *mask) {
    SAVE_VIDEO;
    OHQ_Call_pp(this, (void (*)(SDL_VideoDevice*,const void*,const void*))this->hidden->real_video->SetIcon, icon, mask);
    RESTORE_VIDEO;
}

static int OHQ_IconifyWindow(_THIS) {
    int result;
    SAVE_VIDEO;
    result = OHQ_Call__i(this, this->hidden->real_video->IconifyWindow);
    RESTORE_VIDEO;
    return result;
}

static SDL_GrabMode OHQ_GrabInput(_THIS, SDL_GrabMode mode) {
    int result;
    SAVE_VIDEO;
    result = OHQ_Call_i_i(this, this->hidden->real_video->GrabInput,mode);
    current_video->input_grab = result;
    RESTORE_VIDEO;
    return result;
}

static int OHQ_GetWMInfo(_THIS, SDL_SysWMinfo *info) {
    int result;
    SAVE_VIDEO;
    result = OHQ_Call_p_i(this, (int (*)(SDL_VideoDevice*,const void*))this->hidden->real_video->GetWMInfo, info);
    RESTORE_VIDEO;
    return result;
}

static void OHQ_FreeWMCursor(_THIS, WMcursor *cursor) {
    SAVE_VIDEO;
    OHQ_Call_p(this, (void (*)(SDL_VideoDevice*,const void*))this->hidden->real_video->FreeWMCursor, cursor);
    RESTORE_VIDEO;
}

static WMcursor *OHQ_CreateWMCursor(_THIS, Uint8 *data, Uint8 *mask, int w, int h, int hot_x, int hot_y) {
    void *result;
    SAVE_VIDEO;
    result = OHQ_Call_ppiiii_p(this, (void* (*)(SDL_VideoDevice*,const void*,const void*,int,int,int,int))this->hidden->real_video->CreateWMCursor, data, mask, w, h, hot_x, hot_y);
    RESTORE_VIDEO;
    return result;
}

static int OHQ_ShowWMCursor(_THIS, WMcursor *cursor) {
    int result;
    SAVE_VIDEO;
    result = OHQ_Call_p_i(this, (int (*)(SDL_VideoDevice*,const void*))this->hidden->real_video->ShowWMCursor, cursor);
    RESTORE_VIDEO;
    return result;
}

static void OHQ_WarpWMCursor(_THIS, Uint16 x, Uint16 y) {
    SAVE_VIDEO;
    OHQ_Call_ii(this, (void (*)(SDL_VideoDevice*,int,int))this->hidden->real_video->WarpWMCursor, x*this->hidden->outwidth/this->hidden->width, y*this->hidden->outheight/this->hidden->height);
    RESTORE_VIDEO;
}

static void OHQ_MoveWMCursor(_THIS, int x, int y) {
    if (!this->hidden->real_video->MoveWMCursor) return;
    SAVE_VIDEO;
    OHQ_Call_ii(this, this->hidden->real_video->MoveWMCursor, x*this->hidden->outwidth/this->hidden->width, y*this->hidden->outheight/this->hidden->height);
    RESTORE_VIDEO;
}

static void OHQ_CheckMouseMode(_THIS) {
    SAVE_VIDEO;
    OHQ_Call(this, this->hidden->real_video->CheckMouseMode);
    RESTORE_VIDEO;
}

static void OHQ_InitOSKeymap(_THIS) {
    SAVE_VIDEO;
    OHQ_Call(this, this->hidden->real_video->InitOSKeymap);
    RESTORE_VIDEO;
}

static void OHQ_MouseFilter(int relative, Sint16 *x, Sint16 *y)
{
    if (!relative) {
        *x = (*x*filter_video->hidden->width)/filter_video->hidden->outwidth;
        *y = (*y*filter_video->hidden->height)/filter_video->hidden->outheight;
    }
	if (OHQ_NextMouseFilter != NULL) OHQ_NextMouseFilter(relative,x,y);
}

static void OHQ_PumpEvents(_THIS) {
    SAVE_VIDEO;

#ifdef WIN32
    OHQ_Call(this, this->hidden->real_video->PumpEvents);
#else
    this->hidden->real_video->PumpEvents(this->hidden->real_video);
	if (this->hidden->postponed && !(this->hidden->postponed++ & 255) && TryWaitCommand(this)) SendSyncCommand(this,OGL_NONE);
#endif

    RESTORE_VIDEO;
}

static SDL_VideoDevice *OHQ_CreateDevice(int devindex)
{
    SDL_VideoDevice *this;

    /* Initialize all variables that we clean on shutdown */
    this = (SDL_VideoDevice *)malloc(sizeof(SDL_VideoDevice));
    if (this) {
        memset(this, 0, (sizeof *this));
        this->hidden = (struct SDL_PrivateVideoData *)malloc((sizeof *this->hidden));
    }
    if ( (this == NULL) || (this->hidden == NULL) ) {
        SDL_OutOfMemory();
        if (this) free(this);
        return(0);
    }
    memset(this->hidden, 0, (sizeof *this->hidden));

    /* Set the function pointers */
    this->VideoInit = OHQ_VideoInit;
    this->ListModes = OHQ_ListModes;
    this->SetVideoMode = OHQ_SetVideoMode;
    this->ToggleFullScreen = NULL;
    this->UpdateMouse = OHQ_UpdateMouse;
    this->CreateYUVOverlay = NULL;
    this->SetColors = OHQ_SetColors;
    this->UpdateRects = OHQ_UpdateRects;
    this->VideoQuit = OHQ_VideoQuit;
    this->AllocHWSurface = OHQ_AllocHWSurface;
    this->CheckHWBlit = NULL;
    this->FillHWRect = NULL;
    this->SetHWColorKey = NULL;
    this->SetHWAlpha = NULL;
    this->LockHWSurface = OHQ_LockHWSurface;
    this->UnlockHWSurface = OHQ_UnlockHWSurface;
    this->FlipHWSurface = OHQ_FlipHWSurface;
    this->FreeHWSurface = OHQ_FreeHWSurface;
    this->SetGamma = NULL;
    this->GetGamma = NULL;
    this->SetGammaRamp = NULL;
    this->GetGammaRamp = NULL;
    this->GL_LoadLibrary = NULL;
    this->GL_GetProcAddress = NULL;
    this->GL_GetAttribute = NULL;
    this->GL_MakeCurrent = NULL;
    this->GL_SwapBuffers = NULL;
    this->SetCaption = OHQ_SetCaption;
    this->SetIcon = OHQ_SetIcon;
    this->IconifyWindow = OHQ_IconifyWindow;
    this->GrabInput = OHQ_GrabInput;
    this->GetWMInfo = OHQ_GetWMInfo;
    this->FreeWMCursor = OHQ_FreeWMCursor;
    this->CreateWMCursor = OHQ_CreateWMCursor;
    this->ShowWMCursor = OHQ_ShowWMCursor;
    this->WarpWMCursor = OHQ_WarpWMCursor;
    this->MoveWMCursor = OHQ_MoveWMCursor;
    this->CheckMouseMode = OHQ_CheckMouseMode;
    this->InitOSKeymap = OHQ_InitOSKeymap;
    this->PumpEvents = OHQ_PumpEvents;
    this->free = OHQ_DeleteDevice;

    this->info.wm_available = 1;

    return this;
}

VideoBootStrap OPENGLHQ_bootstrap = {
    "openglhq", "OpenGL-HQ scaling",
    OHQ_Available, OHQ_CreateDevice
};
