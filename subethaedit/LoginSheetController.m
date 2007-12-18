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

- (void)resetDisplayedData {
    TCMMMUser *user = [self user];
    [O_textField1 setStringValue:[user name]];
    [O_textField2 setStringValue:[self peerAddressString]];
    [O_textField3 setStringValue:[[_BEEPSession userInfo] objectForKey:@"userAgent"]];
    [O_imageView setImage:[user image]];
    
    [O_progressIndicator stopAnimation:self];
    [O_statusTextField setStringValue:@""];
    [O_loginButton setEnabled:YES];
    [O_usernameTextField setEnabled:YES];
    [O_passwordTextField setEnabled:YES];
}

- (void)windowDidLoad {
    [self resetDisplayedData];
}

- (void)setBEEPSession:(TCMBEEPSession *)aBEEPSession; {
    if (_BEEPSession) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_BEEPSession];
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[_BEEPSession authenticationClient]];
    }
    [_BEEPSession autorelease];
    _BEEPSession = [aBEEPSession retain];
    if (_BEEPSession) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BEEPSessionDidEnd:) name:TCMBEEPSessionDidEndNotification object:_BEEPSession];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAuthenticate:) name:TCMBEEPAuthenticationClientDidAuthenticateNotification object:[_BEEPSession authenticationClient]];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didNotAuthenticate:) name:TCMBEEPAuthenticationClientDidNotAuthenticateNotification object:[_BEEPSession authenticationClient]];
        [self resetDisplayedData];
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
    [O_statusTextField setStringValue:NSLocalizedString(@"Logging in ...",@"LoginSheet text for logging in...")];
    [O_usernameTextField setEnabled:NO];
    [O_passwordTextField setEnabled:NO];
    [_BEEPSession startAuthenticationWithUserName:[O_usernameTextField stringValue] password:[O_passwordTextField stringValue] profileURI:TCMBEEPSASLPLAINProfileURI];
}

- (IBAction)cancel:(id)aSender {
    [self setBEEPSession:nil];
    [O_loginButton setEnabled:YES];
    [O_progressIndicator stopAnimation:self];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}

- (void)didAuthenticate:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_progressIndicator stopAnimation:self];
    [O_statusTextField setStringValue:NSLocalizedString(@"Successfully logged in.",@"LoginSheet text for Successfully logged in")];
    [self setBEEPSession:nil];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}

- (void)didNotAuthenticate:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_progressIndicator stopAnimation:self];
    [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Error: %@",@"LoginSheet text for Error: %@"),[[[aNotification userInfo] objectForKey:@"NSError"] localizedDescription]]];
    [O_loginButton setEnabled:YES];
    [O_usernameTextField setEnabled:YES];
    [O_passwordTextField setEnabled:YES];
}

@end
