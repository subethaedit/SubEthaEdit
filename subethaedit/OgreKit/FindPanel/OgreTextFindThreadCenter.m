/*
 * Name: OgreTextFindThreadCenter.m
 * Project: OgreKit
 *
 * Creation Date: Oct 02 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindThreadCenter.h>
#import <OgreKit/OgreTextFindProgressSheet.h>

typedef enum _OgreTextFindResultQueueState {
	OgreTextFindResultQueueEmpty = 0, 
	OgreTextFindResultQueueHasData
} OgreTextFindResultQueueState;

@implementation OgreTextFindThreadCenter

- (id)initWithTextFinder:(OgreTextFinder*)textFinder
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithTextFinder: of OgreTextFindThreadCenter");
#endif
	self = [super init];
	if (self) {
		_resultQueue = [[NSMutableArray alloc] initWithCapacity:1];
		_producerLock = [[NSConditionLock alloc] initWithCondition:OgreTextFindResultQueueEmpty];
		_queueLock = [[NSLock alloc] init];
		_numberOfResults = 0;
		[self connectToTextFinder:textFinder];
	}
	
	return self;
}

- (void)connectToTextFinder:(OgreTextFinder*)textFinder
{
	NSPort			*port1;
	NSPort			*port2;
	NSArray			*portArray;
	NSConnection	*connection;
	
	port1 = [NSPort port];
	port2 = [NSPort port];
	connection = [NSConnection connectionWithReceivePort:port1 sendPort:port2];
	[connection setRootObject:textFinder];
	
	portArray = [NSArray arrayWithObjects:port2, port1, connection, nil];
	// Threadが終了するときにconnectionも解放される。
	
	// キュー監視用スレッドの生成
	[NSThread detachNewThreadSelector:@selector(connectWithPorts:) 
		toTarget:self 
		withObject:portArray];	// portArrayはretainされる
}

- (void)connectWithPorts:(NSArray*)ports
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"begin +connectWithPorts: of OgreTextFindThreadCenter");
#endif
	
	/* TextFinderのproxyを得る。 */
	NSConnection	*connection;
	connection = [NSConnection connectionWithReceivePort:[ports objectAtIndex:0] sendPort:[ports objectAtIndex:1]];
	_proxy = [connection rootProxy];
	[_proxy setProtocolForProxy:@protocol(OgreTextFinderProtocol)];
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-start of OgreTextFindThreadCenter");
#endif
	// キューを監視する。
	while (TRUE /* 停止できるようにするかも */ ) {
		[self watchOnQueue];	// keep watch it on
		[(id <OgreTextFinderProtocol>)_proxy didEndThread];
	}
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"end +connectWithPorts: of OgreTextFindThreadCenter");
#endif
	[pool release];
	[NSThread exit];
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of OgreTextFindThreadCenter");
#endif
	[_queueLock release];
	[_producerLock release];
	[_resultQueue release];
	[super dealloc];
}

- (void)watchOnQueue
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-watchOnQueue of OgreTextFindThreadCenter");
#endif
	OgreTextFindResultQueueState	newState;
	
	[_producerLock lockWhenCondition:OgreTextFindResultQueueHasData];
	
	_numberOfResults--;
	
	newState = ((_numberOfResults > 0)? OgreTextFindResultQueueHasData : OgreTextFindResultQueueEmpty);
	[_producerLock unlockWithCondition:newState];
}

- (void)getResult:(id*)result command:(OgreTextFindThreadType*)command target:(id*)target progressSheet:(OgreTextFindProgressSheet**)sheet
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-getResult: of OgreTextFindThreadCenter");
#endif
	[_queueLock lock];
	
	*result	 = [[[[_resultQueue objectAtIndex:0] objectAtIndex:0] retain] autorelease];
	*command = [[[[[_resultQueue objectAtIndex:0] objectAtIndex:1] retain] autorelease] intValue];
	*target	 = [[[[_resultQueue objectAtIndex:0] objectAtIndex:2] retain] autorelease];
	*sheet 	 = [[[[_resultQueue objectAtIndex:0] objectAtIndex:3] retain] autorelease];
	[_resultQueue removeObjectAtIndex:0];
	
	[_queueLock unlock];
}

- (void)putResult:(id)result command:(OgreTextFindThreadType)command target:(id)target progressSheet:(OgreTextFindProgressSheet*)sheet
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-putResult: of OgreTextFindThreadCenter");
#endif
	[_producerLock lock];
	[_queueLock lock];
	
	_numberOfResults++;
	[_resultQueue addObject:[NSArray arrayWithObjects:
		result, [NSNumber numberWithInt:command], target, sheet, nil]];
	
	[_producerLock unlockWithCondition:OgreTextFindResultQueueHasData];
	[_queueLock unlock];
}

@end
