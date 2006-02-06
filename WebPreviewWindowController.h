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

@interface WebPreviewWindowController : NSWindowController {
    IBOutlet WebView       *oWebView;
    IBOutlet NSTextField   *oBaseUrlTextField;
    IBOutlet NSPopUpButton *oRefreshButton;
    IBOutlet NSTextField   *oStatusTextField;
    PlainTextDocument *_plainTextDocument;
    NSRect _documentVisibleRect;
    BOOL   _hasSavedVisibleRect;
    int    _refreshType;
    BOOL   _shallCache;
}

- (id)initWithPlainTextDocument:(PlainTextDocument *)aDocument;

- (PlainTextDocument *)plainTextDocument;
- (int)refreshType;
- (void)setRefreshType:(int)aRefreshType;
- (void)updateBaseURL;

-(IBAction)refreshAndEmptyCache:(id)aSender;
-(IBAction)refresh:(id)aSender;
-(IBAction)changeRefreshType:(id)aSender;

@end
