/**
 * This module contains functions related to cairo's Windows
 * functionality.
 *
 * This file is automatically generated; do not directly modify.
 *
 * Authors: Daniel Keep
 * Copyright: 2006, Daniel Keep
 * License: BSD v2 (http://www.opensource.org/licenses/bsd-license.php).
 */
/*
 * Copyright © 2006 Daniel Keep
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of this software, nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module cairo.win32.cairofuncs_win32;

private
{
    import cairo.loader;
    import cairo.win32.cairotypes_win32;
}

package void cairo_win32_loadprocs(SharedLib lib)
{
    // cairo functions
    cairo_win32_scaled_font_get_metrics_factor = cast(pf_cairo_win32_scaled_font_get_metrics_factor)getProc(lib, "cairo_win32_scaled_font_get_metrics_factor");
    cairo_win32_surface_create = cast(pf_cairo_win32_surface_create)getProc(lib, "cairo_win32_surface_create");
    cairo_win32_font_face_create_for_logfontw = cast(pf_cairo_win32_font_face_create_for_logfontw)getProc(lib, "cairo_win32_font_face_create_for_logfontw");
    cairo_win32_scaled_font_select_font = cast(pf_cairo_win32_scaled_font_select_font)getProc(lib, "cairo_win32_scaled_font_select_font");
    cairo_win32_scaled_font_done_font = cast(pf_cairo_win32_scaled_font_done_font)getProc(lib, "cairo_win32_scaled_font_done_font");
}

// C calling convention for BOTH linux and Windows
extern(C):

typedef double function(cairo_scaled_font_t* scaled_font) pf_cairo_win32_scaled_font_get_metrics_factor;
typedef cairo_surface_t* function(HDC hdc) pf_cairo_win32_surface_create;
typedef cairo_font_face_t* function(LOGFONTW* logfont) pf_cairo_win32_font_face_create_for_logfontw;
typedef cairo_status_t function(cairo_scaled_font_t* scaled_font, HDC hdc) pf_cairo_win32_scaled_font_select_font;
typedef void function(cairo_scaled_font_t* scaled_font) pf_cairo_win32_scaled_font_done_font;

pf_cairo_win32_scaled_font_get_metrics_factor cairo_win32_scaled_font_get_metrics_factor;
pf_cairo_win32_surface_create cairo_win32_surface_create;
pf_cairo_win32_font_face_create_for_logfontw cairo_win32_font_face_create_for_logfontw;
pf_cairo_win32_scaled_font_select_font cairo_win32_scaled_font_select_font;
pf_cairo_win32_scaled_font_done_font cairo_win32_scaled_font_done_font;
