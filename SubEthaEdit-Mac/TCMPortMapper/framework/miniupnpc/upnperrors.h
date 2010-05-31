/* $Id: upnperrors.h,v 1.1 2007/12/22 11:28:04 nanard Exp $ */
/* (c) 2007 Thomas Bernard
 * All rights reserved.
 * MiniUPnP Project.
 * http://miniupnp.free.fr/ or http://miniupnp.tuxfamily.org/
 * This software is subjet to the conditions detailed in the
 * provided LICENCE file. */
#ifndef __UPNPERRORS_H__
#define __UPNPERRORS_H__

/* strupnperror()
 * Return a string description of the UPnP error code 
 * or NULL for undefinded errors */
const char * strupnperror(int err);

#endif
