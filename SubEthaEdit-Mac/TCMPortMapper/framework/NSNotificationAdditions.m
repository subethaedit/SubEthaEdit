#import "NSNotificationAdditions.h"
#import <pthread.h>

@implementation NSNotificationCenter (NSNotificationCenterAdditions)
- (void) postNotificationOnMainThread:(NSNotification *) notification {
	if( pthread_main_np() ) return [self postNotification:notification];
	[self postNotificationOnMainThread:notification waitUntilDone:NO];
}

- (void) postNotificationOnMainThread:(NSNotification *) notification waitUntilDone:(BOOL) wait {
	if( pthread_main_np() ) return [self postNotification:notification];
	[[self class] performSelectorOnMainThread:@selector( _postNotification: ) withObject:notification waitUntilDone:wait];
}

+ (void) _postNotification:(NSNotification *) notification {
	[[self defaultCenter] postNotification:notification];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object {
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:nil];
	[self postNotificationOnMainThreadWithName:name object:object userInfo:nil waitUntilDone:NO];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo {
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:userInfo];
	[self postNotificationOnMainThreadWithName:name object:object userInfo:userInfo waitUntilDone:NO];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo waitUntilDone:(BOOL) wait {
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:userInfo];

	NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:3];
	if( name ) [info setObject:name forKey:@"name"];
	if( object ) [info setObject:object forKey:@"object"];
	if( userInfo ) [info setObject:userInfo forKey:@"userInfo"];

	[[self class] performSelectorOnMainThread:@selector( _postNotificationName: ) withObject:info waitUntilDone:wait];
}

+ (void) _postNotificationName:(NSDictionary *) info {
	NSString *name = [info objectForKey:@"name"];
	id object = [info objectForKey:@"object"];
	NSDictionary *userInfo = [info objectForKey:@"userInfo"];

	[[self defaultCenter] postNotificationName:name object:object userInfo:userInfo];

	[info release];
}
@end

@implementation NSNotificationQueue (NSNotificationQueueAdditions)
- (void) enqueueNotificationOnMainThread:(NSNotification *) notification postingStyle:(NSPostingStyle) postingStyle {
	if( pthread_main_np() ) return [self enqueueNotification:notification postingStyle:postingStyle coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender ) forModes:nil];
	[self enqueueNotificationOnMainThread:notification postingStyle:postingStyle coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender ) forModes:nil];
}

- (void) enqueueNotificationOnMainThread:(NSNotification *) notification postingStyle:(NSPostingStyle) postingStyle coalesceMask:(unsigned) coalesceMask forModes:(NSArray *) modes {
	if( pthread_main_np() ) return [self enqueueNotification:notification postingStyle:postingStyle coalesceMask:coalesceMask forModes:modes];

	NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:4];
	if( notification ) [info setObject:notification forKey:@"notification"];
	[info setObject:[NSNumber numberWithUnsignedInt:postingStyle] forKey:@"postingStyle"];
	[info setObject:[NSNumber numberWithUnsignedInt:coalesceMask] forKey:@"coalesceMask"];
	if( modes ) [info setObject:modes forKey:@"modes"];

	[[self class] performSelectorOnMainThread:@selector( _enqueueNotification: ) withObject:info waitUntilDone:NO];
}

+ (void) _enqueueNotification:(NSDictionary *) info {
	NSNotification *notification = [info objectForKey:@"notification"];
	NSPostingStyle postingStyle = [[info objectForKey:@"postingStyle"] unsignedIntValue];
	unsigned coalesceMask = [[info objectForKey:@"coalesceMask"] unsignedIntValue];
	NSArray *modes = [info objectForKey:@"modes"];

	[[self defaultQueue] enqueueNotification:notification postingStyle:postingStyle coalesceMask:coalesceMask forModes:modes];

	[info release];
}
@end
