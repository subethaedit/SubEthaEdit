/* $Id: natpmpc.c,v 1.3 2007/12/02 00:12:48 nanard Exp $ */
/* libnatpmp
 * Copyright (c) 2007, Thomas BERNARD <miniupnp@free.fr>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. */
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "natpmp.h"

/* sample code for using libnatpmp */
int main(int argc, char * * argv)
{
	natpmp_t natpmp;
	natpmpresp_t response;
	int r;
	//int sav_errno;
	struct timeval timeout;
	fd_set fds;

	r = initnatpmp(&natpmp);
	printf("initnatpmp() returned %d\n", r);
	if(r<0)
		return 1;

	r = sendpublicaddressrequest(&natpmp);
	printf("sendpublicaddressrequest returned %d\n", r);
	if(r<0)
		return 1;

	do {
		FD_ZERO(&fds);
		FD_SET(natpmp.s, &fds);
		getnatpmprequesttimeout(&natpmp, &timeout);
		select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
		r = readnatpmpresponseorretry(&natpmp, &response);
		/*sav_errno = errno;*/
		printf("readnatpmpresponseorretry returned %d\n", r);
		/*if(r<0 && r!=NATPMP_TRYAGAIN)
			printf("errno=%d '%s'\n",
			       sav_errno, strerror(sav_errno));*/
	} while(r==NATPMP_TRYAGAIN);
	if(r<0)
		return 1;

	/* TODO : check that response.type == 0 */
	printf("Public IP address : %s\n", inet_ntoa(response.publicaddress.addr));
	printf("epoch = %u\n", response.epoch);

	r = sendnewportmappingrequest(&natpmp, NATPMP_PROTOCOL_TCP,
                              12345/* private port */, 54321/*publicport*/,
							  3600/*lifetime in seconds*/);
	printf("sendnewportmappingrequest returned %d\n", r);
	if(r < 0)
		return 1;

	do {
		FD_ZERO(&fds);
		FD_SET(natpmp.s, &fds);
		getnatpmprequesttimeout(&natpmp, &timeout);
		select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
		r = readnatpmpresponseorretry(&natpmp, &response);
		printf("readnatpmpresponseorretry returned %d\n", r);
	} while(r==NATPMP_TRYAGAIN);
	if(r<0)
		return 1;
	
	/* TODO : check response.type ! */
	printf("Mapped public port %hu to localport %hu liftime %u\n",
	       response.newportmapping.mappedpublicport,
		   response.newportmapping.privateport,
		   response.newportmapping.lifetime);
	printf("epoch = %u\n", response.epoch);

	r = closenatpmp(&natpmp);
	printf("closenatpmp() returned %d\n", r);
	if(r<0)
		return 1;

	return 0;
}

