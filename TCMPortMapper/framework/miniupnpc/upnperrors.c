/* $Id: upnperrors.c,v 1.2 2008/02/05 12:50:22 nanard Exp $ */
/* Project : miniupnp
 * Author : Thomas BERNARD
 * copyright (c) 2007 Thomas Bernard
 * All Right reserved.
 * This software is subjet to the conditions detailed in the
 * provided LICENCE file. */
#include <string.h>
#include "upnperrors.h"

const char * strupnperror(int err)
{
	const char * s = NULL;
	switch(err) {
	case 401:
		s = "Invalid Action";
		break;
	case 402:
		s = "Invalid Args";
		break;
	case 501:
		s = "Action Failed";
		break;
	case 713:
		s = "SpecifiedArrayIndexInvalid";
		break;
	case 714:
		s = "NoSuchEntryInArray";
		break;
	case 715:
		s = "WildCardNotPermittedInSrcIP";
		break;
	case 716:
		s = "WildCardNotPermittedInExtPort";
		break;
	case 718:
		s = "ConflictInMappingEntry";
		break;
	case 724:
		s = "SamePortValuesRequired";
		break;
	case 725:
		s = "OnlyPermanentLeasesSupported";
		break;
	case 726:
		s = "RemoteHostOnlySupportsWildcard";
		break;
	case 727:
		s = "ExternalPortOnlySupportsWildcard";
		break;
	default:
		s = NULL;
	}
	return s;
}
