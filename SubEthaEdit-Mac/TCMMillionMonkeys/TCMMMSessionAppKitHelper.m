//
//  TCMMMSessionAppKitHelper.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/27/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMSessionAppKitHelper.h"
#import "DocumentController.h"


@implementation TCMMMSessionAppKitHelper

- (void)playSoundNamed:(NSString *)name
{
    [(NSSound *)[NSSound soundNamed:name] play];
}

- (void)playBeep
{
    NSBeep();
}

- (void)addProxyDocumentWithSession:(TCMMMSession *)session
{
    [[DocumentController sharedInstance] addProxyDocumentWithSession:session];
}

@end
