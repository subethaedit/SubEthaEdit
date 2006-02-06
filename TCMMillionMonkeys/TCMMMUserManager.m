//
//  TCMMMUserManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMStatusProfile.h"
#import "TCMMMPresenceManager.h"
#ifndef TCM_NO_DEBUG
    #import "TCMMMUserSEEAdditions.h"
#endif

NSString * const TCMMMUserManagerUserDidChangeNotification = @"TCMMMUserManagerUserDidChangeNotification";

static TCMMMUserManager *sharedInstance=nil;

@implementation TCMMMUserManager

+ (TCMMMUserManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (TCMMMUser *)me {
    return [[self sharedInstance] me];
}

+ (NSString *)myUserID {
    return [[self sharedInstance] myUserID];
}

+ (void)didChangeMe {
    [[self sharedInstance] didChangeMe];
}

- (void)didChangeMe {
    // alter change count
    TCMMMUser *me=[self me];
    [me updateChangeCount];
    // announce change via notification
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:me forKey:@"User"]];
    // announce change via status channels
    [[TCMMMPresenceManager sharedInstance] propagateChangeOfMyself];
}

- (id)init {
    if ((self=[super init])) {
        I_usersByID=[NSMutableDictionary new];
        I_userRequestsByID=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_userRequestsByID release];
    [I_usersByID release];
    [I_me release];
    [super dealloc];
}

- (void)setMe:(TCMMMUser *)aUser {
    [I_me autorelease];
     I_me = [aUser retain];
    [self setUser:I_me forUserID:[I_me userID]];
}
- (TCMMMUser *)me {
    return I_me;
}
- (NSString *)myUserID {
    return [[self me] userID];
}
- (TCMMMUser *)userForUserID:(NSString *)aID {
    return [I_usersByID objectForKey:aID];
}
- (void)setUser:(TCMMMUser *)aUser forUserID:(NSString *)aID {
    DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"Set user:%@ forID:%@",aUser,aID);
    [I_usersByID setObject:aUser forKey:aID];
}

- (void)addUser:(TCMMMUser *)aUser {
    DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"AddUser: %@",aUser);
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    BOOL userDidChange=NO;
    if (user) {
        if ([aUser changeCount] > [user changeCount]) {
            userDidChange=YES;
            [user updateWithUser:aUser];
            aUser=user;
        }
    } else {
        userDidChange=YES;
        [I_usersByID setObject:aUser forKey:userID];
        DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"new user set");
    }
    if (userDidChange) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] >= [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [I_userRequestsByID removeObjectForKey:userID];
            }
        }
#ifndef TCM_NO_DEBUG
        NSString *saveName=[NSString stringWithFormat:@"%@ - %@",[aUser name],[aUser userID]];
        NSData *vcard=[[aUser vcfRepresentation] dataUsingEncoding:NSUnicodeStringEncoding];
        [vcard writeToFile:[[NSString stringWithFormat:@"~/Library/Caches/SubEthaEdit/%@.vcf",saveName] stringByExpandingTildeInPath] atomically:YES];
        NSData *image=[[aUser properties] objectForKey:@"ImageAsPNG"];
        if (image) {
            [image writeToFile:[[NSString stringWithFormat:@"~/Library/Caches/SubEthaEdit/%@.png",saveName] stringByExpandingTildeInPath] atomically:YES];
        }
#endif
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:aUser forKey:@"User"]];
    }
}

- (BOOL)sender:(id)aSender shouldRequestUser:(TCMMMUser *)aUser {
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    if (!user) {
        user=[TCMMMUser new];
        [user setChangeCount:0];
        [user setUserID:userID];
        [user setName:[aUser name]];
        [self setUser:[user autorelease] forUserID:userID];
    } 
    if ([user changeCount]<[aUser changeCount]) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] > [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [request setObject:aUser forKey:@"User"];
                TCMMMStatusProfile *statusProfile=[[TCMMMPresenceManager sharedInstance] statusProfileForUserID:userID];
                if (statusProfile && statusProfile!=aSender) {
                    [request setObject:[NSValue valueWithPointer:(const void *)statusProfile] forKey:@"Sender"];
                    [statusProfile requestUser];
                    return NO;
                } else {
                    [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
                    return YES;
                }
            } else {
                return NO;
            }
        } else {
            request=[NSMutableDictionary dictionary];
            [I_userRequestsByID setObject:request forKey:userID];
            [request setObject:aUser forKey:@"User"];
            TCMMMStatusProfile *statusProfile=[[TCMMMPresenceManager sharedInstance] statusProfileForUserID:userID];
            if (statusProfile && statusProfile!=aSender) {
                [request setObject:[NSValue valueWithPointer:(const void *)statusProfile] forKey:@"Sender"];
                [statusProfile requestUser];
                return NO;
            } else {
                [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
                return YES;
            }
        }
    } else {
        return NO;
    }
}

- (NSArray *)allUsers {
    return [I_usersByID allValues];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector = [anItem action];
    
    if (selector == @selector(sendEmail:)) {
    
        BOOL isValid = NO;
        NSEnumerator *enumerator = [[anItem representedObject] objectEnumerator];
        NSString *userID;
        while ((userID = [enumerator nextObject])) {
            TCMMMUser *user = [self userForUserID:userID];
            if ([(NSString *)[[user properties] objectForKey:@"Email"] length] > 0) {
                isValid = YES;
            } else {
                isValid = NO;
                break;
            }
        }
        return isValid;
        
    } else if (selector == @selector(initiateAIMChat:)) {

        BOOL isValid = NO;
        NSEnumerator *enumerator = [[anItem representedObject] objectEnumerator];
        NSString *userID;
        while ((userID = [enumerator nextObject])) {
            TCMMMUser *user = [self userForUserID:userID];
            if ([(NSString *)[[user properties] objectForKey:@"AIM"] length] > 0) {
                if ([userID isEqualToString:[TCMMMUserManager myUserID]]) {
                    isValid = NO;
                    break;
                } else {
                    isValid = YES;
                }
            } else {
                isValid = NO;
                break;
            }
        }
        return isValid;    
    }
    
    return YES;
}

- (IBAction)sendEmail:(id)sender {
    NSMutableString *URLString = [NSMutableString stringWithString:@"mailto:"];
    NSEnumerator *enumerator = [[sender representedObject] objectEnumerator];
    NSString *userID;
    BOOL hasRecipient = NO;
    while ((userID = [enumerator nextObject])) {
        TCMMMUser *user = [self userForUserID:userID];
        NSString *email = [[user properties] objectForKey:@"Email"];
        [URLString appendFormat:@"%@,", email];
        hasRecipient = YES;
    }
    
    if (hasRecipient) {
        [URLString deleteCharactersInRange:NSMakeRange([URLString length] - 1, 1)];
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"URLString: %@", URLString);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
    }
}

- (IBAction)initiateAIMChat:(id)sender {
    NSEnumerator *enumerator = [[sender representedObject] objectEnumerator];
    NSString *userID;
    while ((userID = [enumerator nextObject])) {
        TCMMMUser *user = [self userForUserID:userID];
        NSString *screenname = [[user properties] objectForKey:@"AIM"];
        NSString *URLString = [NSString stringWithFormat:@"aim:goim?screenname=%@", screenname];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
    }
}

@end
