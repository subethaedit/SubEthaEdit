//
//  NSNotificationCenterThreadingAdditions
//  Enable NSNotification being sent from threads
//
//  Copyright (c) 2007-2008 TheCodingMonkeys: <http://codingmonkeys.de>
//  Some rights reserved: <http://opensource.org/licenses/mit-license.php> 
//

@interface NSNotificationCenter (NSNotificationCenterThreadingAdditions)
- (void) postNotificationOnMainThread:(NSNotification *) notification;
- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object;
@end

