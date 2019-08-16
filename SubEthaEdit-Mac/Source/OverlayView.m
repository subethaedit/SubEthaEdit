//  OverlayView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.10.04.

#import "OverlayView.h"

@implementation OverlayView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    if (I_isDragTarget) {
        [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] set];
        rect=NSInsetRect([self bounds],2,2);
        rect.origin.x-=.5;
        rect.origin.y-=.5;
        NSBezierPath *path=[NSBezierPath bezierPathWithRect:rect];
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [path fill];
        [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.7] set];
        [path stroke];
    }
}

- (void)setDelegate:(id)aSender {
    I_delegate=aSender;
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject {
    return [[self nextResponder] tryToPerform:anAction with:anObject];
}

- (void)setIsDragTarget:(BOOL)aFlag {
    if (aFlag != I_isDragTarget) {
        I_isDragTarget=aFlag;
        [self setNeedsDisplay:YES];
    }
}

- (NSString *)draggingSuitable:(NSPasteboard *)pboard {
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSString *filename=[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
        if ([[filename pathExtension] isEqualToString:@"seestyle"]) {
            return filename;
        }
    }
    return nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL suitable=[self draggingSuitable:pboard]!=nil;
    [self setIsDragTarget:suitable];
    return suitable?NSDragOperationGeneric:NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self setIsDragTarget:NO];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL suitable=[self draggingSuitable:pboard]!=nil;
    [self setIsDragTarget:suitable];
    return suitable?NSDragOperationGeneric:NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL suitable=[self draggingSuitable:pboard]!=nil;
    [self setIsDragTarget:suitable];
    return suitable;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *filename=[self draggingSuitable:pboard];
    [I_delegate performSelector:@selector(importStyleFile:) withObject:filename];
    [self setIsDragTarget:NO];
    return filename!=nil;
}

@end
