//
//  URLImageView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "URLImageView.h"
#import "PlainTextDocument.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@implementation URLImageView

- (void)awakeFromNib
{
    I_trackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)dealloc
{
    [self removeTrackingRect:I_trackingRectTag];
    [super dealloc];
}

- (void)setFrame:(NSRect)frameRect
{
    [self removeTrackingRect:I_trackingRectTag];
    [super setFrame:frameRect];
    I_trackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)setBounds:(NSRect)boundsRect
{
    [self removeTrackingRect:I_trackingRectTag];
    [super setBounds:boundsRect];
    I_trackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)event
{
    return YES;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationGeneric;
}

- (void)setDelegate:(id)aDelegate {
    I_delegate = aDelegate;
}
- (id)delegate {
    return I_delegate;
}

- (NSURL *)URLFromDelegate {
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(URLForURLImageView:)]) {
        return [delegate URLForURLImageView:self];
    } else {
        return nil;
    }
}

- (void)mouseDown:(NSEvent *)event
{
    NSURL *url = [self URLFromDelegate];
    if (url) {
        
        NSImage *urlImage = [self image];
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        
        NSArray *pbTypes = [NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, @"CorePasteboardFlavorType 0x75726C20", @"CorePasteboardFlavorType 0x75726C6E", nil];
        [pboard declareTypes:pbTypes owner:self];
        
        const char *dataUTF8=[[url absoluteString] UTF8String];
        [pboard setData:[NSData dataWithBytes:dataUTF8 length:strlen(dataUTF8)] forType:@"CorePasteboardFlavorType 0x75726C20"];
        [pboard setData:[NSData dataWithBytes:dataUTF8 length:strlen(dataUTF8)] forType:@"CorePasteboardFlavorType 0x75726C6E"];
        [pboard setString:[url absoluteString] forType:NSStringPboardType];
        [url writeToPasteboard:pboard];
        
        [NSApp preventWindowOrdering];
        
        NSPoint at = [self bounds].origin;
        at.x += 0;
        at.y += 0;
        [urlImage setSize:[self bounds].size];
        [self dragImage:urlImage
                     at:at
                 offset:NSMakeSize(0,0)
                  event:event
             pasteboard:pboard
                 source:self
              slideBack:YES];
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    NSURL *url = [self URLFromDelegate];
    [self setToolTip:[url absoluteString]];
}

@end
