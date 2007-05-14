//
//  LoginSheetController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "LoginSheetController.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"


@implementation LoginSheetController

- (void)dealloc {
    [self setBEEPSession:nil];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"LoginSheet";
}

- (NSString *)userID {
    return [[_BEEPSession userInfo] objectForKey:@"peerUserID"];
}

- (TCMMMUser *)user {
    return [[TCMMMUserManager sharedInstance] userForUserID:[self userID]];
}

- (NSString *)peerAddressString {
    NSString *result = [[_BEEPSession userInfo] objectForKey:@"URLString"];
    if (!result) result = [NSString stringWithAddressData:[_BEEPSession peerAddressData]];
    return result;
}

- (void)updateDisplayedServerData {
    TCMMMUser *user = [self user];
    [O_textField1 setStringValue:[user name]];
    [O_textField2 setStringValue:[self peerAddressString]];
    [O_textField3 setStringValue:[[_BEEPSession userInfo] objectForKey:@"userAgent"]];
    [O_imageView setImage:[user image]];
}

- (void)windowDidLoad {
    [self updateDisplayedServerData];
}

- (void)setBEEPSession:(TCMBEEPSession *)aBEEPSession; {
    if (_BEEPSession) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_BEEPSession];
    }
    [_BEEPSession autorelease];
    _BEEPSession = [aBEEPSession retain];
    if (_BEEPSession) {
        [self updateDisplayedServerData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BEEPSessionDidEnd:) name:TCMBEEPSessionDidEndNotification object:_BEEPSession];
    }
}

- (TCMBEEPSession *)BEEPSession {
    return _BEEPSession;
}


- (void)BEEPSessionDidEnd:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    [self setBEEPSession:nil];
}

- (IBAction)login:(id)aSender {
    [O_progressIndicator startAnimation:self];
    [O_loginButton setEnabled:NO];
}
- (IBAction)cancel:(id)aSender {
    [self setBEEPSession:nil];
    [O_progressIndicator stopAnimation:self];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}


@end
