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
#import "NSImageTCMAdditions.h"

@implementation TCMMMUser (TCMMMUserSEEAdditions) 

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData {
    NSDictionary *userDict=TCM_BdecodedObjectWithData(aData);
    TCMMMUser *user=[TCMMMUser new];
    [user setName:[userDict objectForKey:@"Name"]];
    [user setID:[userDict objectForKey:@"ID"]];
    NSData *pngData=[userDict objectForKey:@"ImageAsPNG"];
    [[user properties] setObject:pngData forKey:@"ImageAsPNG"];
    [[user properties] setObject:[[[NSImage alloc] initWithData:[[user properties] objectForKey:@"ImageAsPNG"]] autorelease] forKey:@"Image"];
    [user prepareImages];
    //NSLog(@"Created User: %@",[user description]);
    return [user autorelease];
}

- (void)prepareImages {
    NSImage *image=[[self properties] objectForKey:@"Image"];
    NSMutableDictionary *properties=[self properties];
    [properties setObject:[image resizedImageWithSize:NSMakeSize(32.,32.)] forKey:@"Image32"];
    [properties setObject:[image resizedImageWithSize:NSMakeSize(16.,16.)] forKey:@"Image16"];
}


- (NSData *)userBencoded {
    NSDictionary *user=[NSDictionary dictionaryWithObjectsAndKeys:[self name],@"Name",[self ID],@"ID",[I_properties objectForKey:@"ImageAsPNG"],@"ImageAsPNG",nil];
    return TCM_BencodedObject(user);
}

    
@end
