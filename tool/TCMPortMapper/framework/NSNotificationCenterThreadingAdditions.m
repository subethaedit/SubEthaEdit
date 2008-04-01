#import "NSNotificationCenterThreadingAdditions.h"
#import <pthread.h>

@implementation NSNotificationCenter (NSNotificationCenterThreadingAdditions)
- (void) postNotificationOnMainThread:(NSNotification *) notification {
	if( pthread_main_np() ) return [self postNotification:notification];
	[[self class] performSelectorOnMainThread:@selector( _postNotification: ) withObject:notification waitUntilDone:NO];
}

+ (void) _postNotification:(NSNotification *) notification {
	[[self defaultCenter] postNotification:notification];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object {
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:nil];
	NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:2];
	if( name ) [info setObject:name forKey:@"name"];
	if( object ) [info setObject:object forKey:@"object"];
	[[self class] performSelectorOnMainThread:@selector( _postNotificationName: ) withObject:info waitUntilDone:NO];
}

+ (void) _postNotificationName:(NSDictionary *) info {
	NSString *name = [info objectForKey:@"name"];
	id object = [info objectForKey:@"object"];
	[[self defaultCenter] postNotificationName:name object:object userInfo:nil];
	[info release];
}
@end
