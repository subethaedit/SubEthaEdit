//
//  TCMMMUserSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUser.h"
#import "TCMBencodingUtilities.h"


@implementation TCMMMUser (TCMMMUserSEEAdditions) 

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData {
    NSDictionary *userDict=TCM_BdecodedObjectWithData(aData);
    TCMMMUser *user=[TCMMMUser new];
    [user setName:[userDict objectForKey:@"Name"]];
    [user setID:[userDict objectForKey:@"ID"]];
    NSData *pngData=[userDict objectForKey:@"ImageAsPNG"];
    [[user properties] setObject:pngData forKey:@"ImageAsPNG"];
    [[user properties] setObject:[[[NSImage alloc] initWithData:pngData] autorelease] forKey:@"Image"];
    NSLog(@"Created User: %@",[user description]);
    return [user autorelease];
}


- (NSData *)userBencoded {
    NSDictionary *user=[NSDictionary dictionaryWithObjectsAndKeys:[self name],@"Name",[self ID],@"ID",[I_properties objectForKey:@"ImageAsPNG"],@"ImageAsPNG",nil];
    return TCM_BencodedObject(user);
}

    
@end
