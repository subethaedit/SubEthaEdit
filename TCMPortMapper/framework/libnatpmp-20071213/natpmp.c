/* $Id: natpmp.c,v 1.4 2007/12/02 00:12:47 nanard Exp $ */
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
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include "natpmp.h"
#include "getgateway.h"

int initnatpmp(natpmp_t * p)
{
	int flags; 
	struct sockaddr_in addr;
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
	memset(p, 0, sizeof(natpmp_t));
	p->s = socket(PF_INET, SOCK_DGRAM, 0);
	if(p->s < 0)
		return NATPMP_ERR_SOCKETERROR;
	if((flags = fcntl(p->s, F_GETFL, 0)) < 0)
		return NATPMP_ERR_FCNTLERROR;
	if(fcntl(p->s, F_SETFL, flags | O_NONBLOCK) < 0)
		return NATPMP_ERR_FCNTLERROR;

	if(getdefaultgateway(&(p->gateway)) < 0)
		return NATPMP_ERR_CANNOTGETGATEWAY;
	
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons(NATPMP_PORT);
	addr.sin_addr.s_addr = p->gateway;
	if(connect(p->s, (struct sockaddr *)&addr, sizeof(addr)) < 0)
		return NATPMP_ERR_CONNECTERR;
	return 0;
}

int closenatpmp(natpmp_t * p)
{
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
	if(close(p->s) < 0)
		return NATPMP_ERR_CLOSEERR;
	return 0;
}

int sendpendingrequest(natpmp_t * p)
{
	int r;
/*	struct sockaddr_in addr;*/
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
/*	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons(NATPMP_PORT);
	addr.sin_addr.s_addr = p->gateway;
	r = (int)sendto(p->s, p->pending_request, p->pending_request_len, 0,
	                   (struct sockaddr *)&addr, sizeof(addr));*/
	r = (int)send(p->s, p->pending_request, p->pending_request_len, 0);
	return (r<0) ? NATPMP_ERR_SENDERR : r;
}

int sendnatpmprequest(natpmp_t * p)
{
	int n;
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
	/* TODO : check if no request is allready pending */
	p->has_pending_request = 1;
	p->try_number = 1;
	n = sendpendingrequest(p);
	gettimeofday(&p->retry_time, NULL);	// check errors !
	p->retry_time.tv_usec += 250000;	/* add 250ms */
	if(p->retry_time.tv_usec >= 1000000) {
		p->retry_time.tv_usec -= 1000000;
		p->retry_time.tv_sec++;
	}
	return n;
}

int getnatpmprequesttimeout(natpmp_t * p, struct timeval * timeout)
{
	struct timeval now;
	if(!p || !timeout)
		return NATPMP_ERR_INVALIDARGS;
	if(!p->has_pending_request)
		return NATPMP_ERR_NOPENDINGREQ;
	if(gettimeofday(&now, NULL) < 0)
		return NATPMP_ERR_GETTIMEOFDAYERR;
	timeout->tv_sec = p->retry_time.tv_sec - now.tv_sec;
	timeout->tv_usec = p->retry_time.tv_usec - now.tv_usec;
	if(timeout->tv_usec < 0) {
		timeout->tv_usec += 1000000;
		timeout->tv_sec--;
	}
	return 0;
}

int sendpublicaddressrequest(natpmp_t * p)
{
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
	//static const unsigned char request[] = { 0, 0 };
	p->pending_request[0] = 0;
	p->pending_request[1] = 0;
	p->pending_request_len = 2;
	// TODO: return 0 instead of sizeof(request) ??
	return sendnatpmprequest(p);
}

int sendnewportmappingrequest(natpmp_t * p, int protocol,
                              uint16_t privateport, uint16_t publicport,
							  uint32_t lifetime)
{
	if(!p || (protocol!=NATPMP_PROTOCOL_TCP && protocol!=NATPMP_PROTOCOL_UDP))
		return NATPMP_ERR_INVALIDARGS;
	p->pending_request[0] = 0;
	p->pending_request[1] = protocol;
	p->pending_request[2] = 0;
	p->pending_request[3] = 0;
	*((uint16_t *)(p->pending_request + 4)) = htons(privateport);
	*((uint16_t *)(p->pending_request + 6)) = htons(publicport);
	*((uint32_t *)(p->pending_request + 8)) = htonl(lifetime);
	p->pending_request_len = 12;
	return sendnatpmprequest(p);
}

int readnatpmpresponse(natpmp_t * p, natpmpresp_t * response)
{
	unsigned char buf[16];
	struct sockaddr_in addr;
	socklen_t addrlen = sizeof(addr);
	int n;
	if(!p)
		return NATPMP_ERR_INVALIDARGS;
	n = recvfrom(p->s, buf, sizeof(buf), 0,
	             (struct sockaddr *)&addr, &addrlen);
	if(n<0)
		switch(errno) {
		case EAGAIN:
			n = NATPMP_TRYAGAIN;
			break;
		case ECONNREFUSED:
			n = NATPMP_ERR_NOGATEWAYSUPPORT;
			break;
		default:
			n = NATPMP_ERR_RECVFROM;
		}
	/* check that addr is correct (= gateway) */
	else if(addr.sin_addr.s_addr != p->gateway)
		n = NATPMP_ERR_WRONGPACKETSOURCE;
	else {
		response->resultcode = ntohs(*((uint16_t *)(buf + 2)));
		response->epoch = ntohl(*((uint32_t *)(buf + 4)));
		if(buf[0] != 0)
			n = NATPMP_ERR_UNSUPPORTEDVERSION;
		else if(buf[1] < 128 || buf[1] > 130)
			n = NATPMP_ERR_UNSUPPORTEDOPCODE;
		else if(response->resultcode != 0) {
			switch(response->resultcode) {
			case 1:
				n = NATPMP_ERR_UNSUPPORTEDVERSION;
				break;
			case 2:
				n = NATPMP_ERR_NOTAUTHORIZED;
				break;
			case 3:
				n = NATPMP_ERR_NETWORKFAILURE;
				break;
			case 4:
				n = NATPMP_ERR_OUTOFRESOURCES;
				break;
			case 5:
				n = NATPMP_ERR_UNSUPPORTEDOPCODE;
				break;
			default:
				n = NATPMP_ERR_UNDEFINEDERROR;
			}
		} else {
			response->type = buf[1] & 0x7f;
			if(buf[1] == 128)
				//response->publicaddress.addr = *((uint32_t *)(buf + 8));
				response->publicaddress.addr.s_addr = *((uint32_t *)(buf + 8));
			else {
				response->newportmapping.privateport = ntohs(*((uint16_t *)(buf + 8)));
				response->newportmapping.mappedpublicport = ntohs(*((uint16_t *)(buf + 10)));
				response->newportmapping.lifetime = ntohl(*((uint32_t *)(buf + 12)));
			}
			n = 0;
		}
	}
	return n;
}

int readnatpmpresponseorretry(natpmp_t * p, natpmpresp_t * response)
{
	int n;
	if(!p || !response)
		return NATPMP_ERR_INVALIDARGS;
	if(!p->has_pending_request)
		return NATPMP_ERR_NOPENDINGREQ;
	n = readnatpmpresponse(p, response);
	if(n<0) {
		if(n==NATPMP_TRYAGAIN) {
			struct timeval now;
			gettimeofday(&now, NULL);	// check errors !
			if(timercmp(&now, &p->retry_time, >=)) {
				int delay, r;
				if(p->try_number >= 7) { 
					return NATPMP_ERR_NOGATEWAYSUPPORT;
				}
				/*printf("retry! %d\n", p->try_number);*/
				delay = 250 * (1<<p->try_number);	// ms
				/*for(i=0; i<p->try_number; i++)
					delay += delay;*/
				p->retry_time.tv_sec += (delay / 1000);
				p->retry_time.tv_usec += (delay % 1000) * 1000;
				if(p->retry_time.tv_usec >= 1000000) {
					p->retry_time.tv_usec -= 1000000;
					p->retry_time.tv_sec++;
				}
				p->try_number++;
				r = sendpendingrequest(p);
				if(r<0)
					return r;
			}
		}
	} else {
		p->has_pending_request = 0;
	}
	return n;
}

