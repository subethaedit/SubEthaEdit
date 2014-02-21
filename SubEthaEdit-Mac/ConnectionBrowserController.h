//
//  InternetBrowserController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//           

#import <AppKit/AppKit.h>

@class PlainTextDocument;

@interface ConnectionBrowserController : NSObject

+ (ConnectionBrowserController *)sharedInstance;

+ (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard withURL:(NSURL *)aURL;
+ (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard intoDocument:(PlainTextDocument *)aDocument group:(NSString *)aGroup;

- (void)connectToURL:(NSURL *)anURL;
- (void)connectToAddress:(NSString *)address;

@end
