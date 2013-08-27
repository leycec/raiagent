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

TEMP coord1, coord2, coord3, pixel0;
ALIAS pixel1 = coord1;
ALIAS pixel2 = coord2;
ALIAS pixel3 = coord3;
TEMP diff;
TEMP center_offset;
TEMP factors;
TEMP coord0;

PARAM pixel_size = program.env[0];

# 1/16, 1/2, 1-1/256, 1/512
PARAM const = { .0625, .5, .99609375, .001953125 };

ATTRIB coord0hw = fragment.texcoord[0];

# 1/.875, (1/.875-1)/2, .875/adjust, (1-.875/adjust)/2
#PARAM cap = { 1.142857142857142857127368540393064222371, -0.07142857142857143002735720305196309709572, .83825, .080875 };
#PARAM cap = { 1.142857142857142857127368540393064222371, -0.07142857142857143002735720305196309709572, .875, .0625 };
PARAM cap = program.env[1];

# normalize coordinates to eliminate FP precision errors
MUL center_offset.xy, coord0hw, pixel_size.abgr;
FLR coord0.xy, center_offset;
ADD coord0.xy, coord0, const.g;
MUL coord0.xy, coord0, pixel_size;

# sub-pixel offset
FRC center_offset.xy, center_offset;

# fetch interpolation mask coordinates
TEX diff, coord0, texture[1], 2D;

# calculate neighbour pixel coordinates
SUB coord3.xy, center_offset, const.g;
CMP coord3.xy, coord3, -pixel_size, pixel_size;
ADD coord3.xy, coord0, coord3;
MOV coord1.x, coord3;
MOV coord1.y, coord0;
MOV coord2.x, coord0;
MOV coord2.y, coord3;

# The interpolation mask 3D texture is arranged
# as 16x1x256 masks like this:
#
#     +--+--+--+--                --+--+       +-> x
#     |  |  |  |  ... 16 masks ...  |  |+      |\
#     +--+--+--+--                --+--+|+     V \|
#      +--+--+--+--                --+--+|     y   z
#       +--+--+--+--                --+--+
#              .
#               . 256 masks
#                .
#
# This is more robust across GPUs than an 1x1x4096 arrangement.

# Clamp x offset to a reduced interval. This is required since
# otherwise precision errors will make the final coordinate wrap
# into the opposite end of the next mask.
MAD_SAT center_offset.x, center_offset, cap.r, cap.g;
MAD center_offset.x, center_offset, cap.b, cap.a;

# This could be used if wrapping occurs on the z coordinate, which
# should not happen. 
#MAD center_offset.z, diff, const.b, const.a;

# final coordinate calculation:
# x = x_offset/16 + mask_x; y = y_offset; z = mask_z;
MAD center_offset.x, center_offset, const, diff.a;
MOV center_offset.z, diff;

# fetch color values
TEX pixel0, coord0, texture[0], 2D;
TEX pixel1, coord1, texture[0], 2D;
TEX pixel2, coord2, texture[0], 2D;
TEX pixel3, coord3, texture[0], 2D;

# fetch pixel weights from mask
TEX factors, center_offset, texture[2], 3D;

# apply mask factors
MUL pixel0, pixel0, factors.r;
MAD pixel0, pixel1, factors.g, pixel0;
MAD pixel0, pixel2, factors.b, pixel0;
MAD result.color, pixel3, factors.a, pixel0;

# debugging
#MOV result.color, pixel0;
#MOV result.color, diff;
#MOV result.color, factors;
#MOV result.color.g, test.y;
#MOV result.color.r, test.z;
#SUB test.z, test, const.b;
#CMP result.color.r, test.z, const.r, const.b;

END
