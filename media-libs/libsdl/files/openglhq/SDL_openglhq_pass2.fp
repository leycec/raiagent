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
TEMP max;
ALIAS coord0 = pixel0;
ALIAS coord1 = pixel1;
ALIAS coord2 = pixel2;
TEMP min;
TEMP current_trigger;

PARAM pixel_size = program.env[0];
PARAM trigger = program.local[0];
ATTRIB coord3 = fragment.texcoord[0];

PARAM coordmask = { 0, -1, 0, .0625 };
PARAM factors = {  0.0627450980392157,  0.125490196078431,  0.250980392156863,   0.501960784313725 };
PARAM const = { 65536, 0.1666666666666666, 1, 0 };
ALIAS one_sixteenth = coordmask;

SUB coord0.xy, coord3, pixel_size;
MAD coord1.xy, pixel_size.y, coordmask, coord3;
MAD coord2.xy, pixel_size.x, coordmask.gbra, coord3;

TEX pixel0, coord0, texture[0], 2D;
TEX pixel1, coord1, texture[0], 2D;
TEX pixel2, coord2, texture[0], 2D;
TEX pixel3, coord3, texture[0], 2D;

MOV pixel1.r, pixel0.b;
MOV pixel2.g, pixel0.a;

ADD min, pixel1, pixel2;
ADD min, min, pixel3;
DP3 current_trigger.a, min, const.g;
MUL_SAT current_trigger.a, current_trigger.a, trigger.a;
MAX current_trigger.a, current_trigger.a, trigger.r;

MUL current_trigger.a, current_trigger.a, const.r;
MAD_SAT pixel1, pixel1, const.r, -current_trigger.a;
MAD_SAT pixel2, pixel2, const.r, -current_trigger.a;
MAD_SAT pixel3, pixel3, const.r, -current_trigger.a;

# on a Radeon 9500, these three expand to 6 native insns
#SLT pixel1, current_trigger.a, pixel1;
#SLT pixel2, current_trigger.a, pixel2;
#SLT pixel3, current_trigger.a, pixel3;

DP4 result.color.a, pixel3, factors;
MAD pixel2, pixel2, one_sixteenth.a, pixel1;
DP4 result.color.rgb, pixel2, factors;

END
