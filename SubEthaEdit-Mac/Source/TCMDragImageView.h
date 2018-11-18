//  TCMDragImageView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.03.14.

#import <Cocoa/Cocoa.h>
@class TCMDragImageView;

@protocol TCMDragImageDelegate <NSObject>
@optional;
- (void)dragImage:(TCMDragImageView *)aDragImageView mouseDown:(NSEvent *)anEvent;
- (void)dragImage:(TCMDragImageView *)aDragImageView mouseDragged:(NSEvent *)anEvent;
- (void)dragImage:(TCMDragImageView *)aDragImageView mouseUp:(NSEvent *)anEvent;
@end

@interface TCMDragImageView : NSImageView
@property (nonatomic) NSPoint dragDelta;
@property (nonatomic, weak) IBOutlet id<TCMDragImageDelegate> dragDelegate;
@end
