//  PlainTextLoadProgress.h
//  SubEthaEdit
//
//  Created by Martin Ott on 1/17/07.

#import <Cocoa/Cocoa.h>

@class TCMMMSession;

@interface PlainTextLoadProgress : NSViewController {
}

@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressIndicatorOutlet;
@property (nonatomic, assign) IBOutlet NSTextField *loadStatusFieldOutlet;

- (void)startAnimation;
- (void)stopAnimation;
- (void)setStatusText:(NSString *)string;
- (NSView *)loadProgressView;
- (void)registerForSession:(TCMMMSession *)session;

@end
