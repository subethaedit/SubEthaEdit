//  TCMMMSessionAppKitHelper.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/27/07.

#import "TCMMMSessionAppKitHelper.h"
#import "SEEDocumentController.h"


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
    [[SEEDocumentController sharedInstance] addProxyDocumentWithSession:session];
}

@end
