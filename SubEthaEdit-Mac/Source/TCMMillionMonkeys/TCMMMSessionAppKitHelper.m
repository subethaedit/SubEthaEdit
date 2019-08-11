//  TCMMMSessionAppKitHelper.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/27/07.

#import "TCMMMSessionAppKitHelper.h"
#import "SEEDocumentController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


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
