!!ARBfp1.0

#
# Copyright (C) 2004 Jörg Walter <jwalt@garni.ch>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

TEMP pixel0, pixel1, pixel2, pixel3;
ALIAS coord1 = pixel1;
ALIAS coord2 = pixel2;
ALIAS coord3 = pixel3;
ALIAS rmean = pixel3;
TEMP diff;

PARAM pixel_size = program.env[0];
ATTRIB coord0 = fragment.texcoord[0];
OUTPUT res = result.color;

PARAM coordmask = { 1, 0, 1, 0 };
PARAM weight = { 1.884313725490196078431372549, 3.768627450980392156862745098, 2.822790287990196078431372548, 0 };
PARAM mask = { 0.4710784313725490196078431372, 0, -0.4710784313725490196078431372, 0 };

MAD coord1.xy, pixel_size, coordmask, coord0;
MAD coord2.xy, pixel_size, coordmask.gbra, coord0;
ADD coord3.xy, pixel_size, coord0;

TEX pixel0.rgb, coord0, texture[0], 2D;
TEX pixel1.rgb, coord1, texture[0], 2D;
TEX pixel2.rgb, coord2, texture[0], 2D;
TEX pixel3.rgb, coord3, texture[0], 2D;

#
#  Original formula, [0;255] per component, result range [0;764.83]:
#  sqrt( (2+rmean/256)*r*r + 4*g*g + (2.99609375-rmean/256)*b*b )
#  (see http://www.compuphase.com/cmetric.htm)
#
#  Formula used in software hq2x scaler, range [0;31] per component, result range [0;2161.31] clamped to [0;255]:
#  (0.5+(2*rmean/2048))*r*r + g*g + (0.7490234375-(2*rmean/2048))*b*b
#
#  This code uses this formula, range [0;1] per component, result range [0;2161.31/255] clamped to [0;1]:
#  (1.884313725490196078431372549+(2*rmean*0.4710784313725490196078431372))*r*r + 3.768627450980392156862745098*g*g + (2.822790287990196078431372548-(2*rmean*0.4710784313725490196078431372))*b*b
#  (which means that the same trigger values can be used for both)
#

SUB diff.rgb, pixel0, pixel3;
ADD rmean.a, pixel0.r, pixel3.r;
MAD rmean.rgb, rmean.a, mask, weight;
MUL diff.rgb, diff, diff;
DP3_SAT res.b, rmean, diff;

SUB diff.rgb, pixel0, pixel1;
ADD rmean.a, pixel0.r, pixel1.r;
MAD rmean.rgb, rmean.a, mask, weight;
MUL diff.rgb, diff, diff;
DP3_SAT res.r, rmean, diff;

SUB diff.rgb, pixel0, pixel2;
ADD rmean.a, pixel0.r, pixel2.r;
MAD rmean.rgb, rmean.a, mask, weight;
MUL diff.rgb, diff, diff;
DP3_SAT res.g, rmean, diff;

SUB diff.rgb, pixel1, pixel2;
ADD rmean.a, pixel1.r, pixel2.r;
MAD rmean.rgb, rmean.a, mask, weight;
MUL diff.rgb, diff, diff;
DP3_SAT res.a, rmean, diff;

END
