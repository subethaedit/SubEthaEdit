//
//  WebPreviewWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Jul 07 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>


extern int const kWebPreviewRefreshAutomatic;
extern int const kWebPreviewRefreshOnSave   ;
extern int const kWebPreviewRefreshManually ;
extern int const kWebPreviewRefreshDelayed  ;

@class PlainTextDocument;

@interface WebPreviewWindowController : NSWindowController

- (id)initWithPlainTextDocument:(PlainTextDocument *)aDocument;

- (void)setPlainTextDocument:(PlainTextDocument *)aDocument;
- (PlainTextDocument *)plainTextDocument;

- (int)refreshType;
- (void)setRefreshType:(int)aRefreshType;

- (void)updateBaseURL;

- (NSURL *)baseURL;
- (void)setBaseURL:(NSURL *)aBaseURL;


-(IBAction)refreshAndEmptyCache:(id)aSender;
-(IBAction)refresh:(id)aSender;
-(IBAction)changeRefreshType:(id)aSender;

@end
