//
//  PlainTextLoadProgress.h
//  SubEthaEdit
//
//  Created by Martin Ott on 1/17/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMSession;

@interface PlainTextLoadProgress : NSObject {
    IBOutlet NSView *_loadProgressView;
    IBOutlet NSProgressIndicator *_progressIndicator;
    IBOutlet NSTextField *_loadStatusField;
}

- (void)startAnimation;
- (void)stopAnimation;
- (void)setStatusText:(NSString *)string;
- (NSView *)loadProgressView;
- (void)registerForSession:(TCMMMSession *)session;

@end
