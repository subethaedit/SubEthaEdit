/*

File: SESendProc.m

Abstract: SendProc

Version: 1.0

(c) Copyright 2006 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple’s copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*/

#import "SESendProc.h"
#import <Carbon/Carbon.h>

static AEIdleUPP _SEIdleProc = NULL;
static AEFilterUPP _SEFilterProc = NULL;

#define kSpinRate 10
#define kForever 0x7FFFFFFF


// The Idle Proc
// =============

BOOL IdleProc(EventRecord *theEvent, long *sleepTime, RgnHandle *mouseRgn)
{
    printf("IdleProc\n");
	BOOL result = NO;
		
	// Check for command period
	if (theEvent->what == nullEvent && [NSApp isActive])
	{
		if (CheckEventQueueForUserCancel != NULL)
		{
			if (CheckEventQueueForUserCancel())
			{
				result = YES;
			}
		}
		else
		{
			WaitNextEvent(everyEvent - highLevelEventMask, theEvent, kSpinRate, NULL);
		}
	}
	else if (theEvent->what == keyDown && (theEvent->modifiers & cmdKey))
	{
		if (IsCmdChar(theEvent, '.'))
		{
			result = YES;
		}
	}
	
	// Adjust the sleep time
	if (CheckEventQueueForUserCancel == NULL)
	{
		*sleepTime = [NSApp isActive] ? kSpinRate : kForever;
	}
	
	*mouseRgn = NULL;
	
	return result;
}


// The Filter Proc
// ===============

BOOL FilterProc(EventRecord *theEvent, long returnID, long transactionID, const AEAddressDesc *sender)
{
    printf("FilterProc\n");
	return YES;
}


// The Send Proc
// =============


OSAError SendProc(const AppleEvent* event, AppleEvent *result, AESendMode sendMode, AESendPriority sendPriority, long timeOutInTicks, AEIdleUPP idleProc, AEFilterUPP filterProc, long refCon)
{
    printf("SendProc\n");
	OSAError error = noErr;
	
	if (_SEIdleProc == NULL)
	{
		_SEIdleProc = NewAEIdleUPP((AEIdleUPP)IdleProc);
		_SEFilterProc = NewAEFilterUPP((AEFilterUPP)FilterProc);
	}
	
	// Send the event
	error = AESend(event, result, sendMode, sendPriority, timeOutInTicks, _SEIdleProc, _SEFilterProc);

	return error;
}


// SESendProc
// ==========

@implementation SESendProc

// Construction
// ============

- (id)initWithComponent:(ComponentInstance)component
{
	self = [super init];
	if (self)
	{
		_component = component;
		
		// Save the old send proc
		OSAError error = OSAGetSendProc(_component, &_oldSendProc, &_oldRefCon);

		// Create the new one and set it
		_sendProc = NewOSASendUPP((OSASendProcPtr)&SendProc);
		if (_sendProc)
		{
			error = OSASetSendProc(_component, _sendProc, 0L);
		}
	}

	return self;
}

- (void)dealloc
{
	// Put back the old proc
	OSASetSendProc(_component, _oldSendProc, _oldRefCon);
	_oldSendProc = NULL;
	
	// Dispose of the one we created
	if (_sendProc)
	{
		DisposeOSASendUPP(_sendProc);
		_sendProc = NULL;
	}
	
	[super dealloc];
}

@end




