//
//  ParticipantsView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 12 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ParticipantsView.h"


@implementation ParticipantsView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        I_categories = [[NSArray arrayWithObjects:@"Read/Write", @"Read-Only", nil] retain];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_categories release];
    [super dealloc];
}

- (void)setDelegate:(id)delegate {
    I_delegate = delegate;
}

- (id)delegate {
    return I_delegate;
}

- (void)setDataSource:(id)dataSource {
    I_dataSource = dataSource;
}

- (id)dataSource {
    return I_dataSource;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawCategoryAtIndex:(int)index {
    
    static NSMutableDictionary *labelAttributes = nil;
    if (!labelAttributes) {
        labelAttributes = [[NSMutableDictionary dictionaryWithObject:
            [NSFont systemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName] retain];
    }
    
    NSRect bounds = [self bounds];
    NSRect categoryRect = NSMakeRect(0, 0, bounds.size.width, 19);
    [[NSColor lightGrayColor] set];
    NSRectFill(categoryRect);
    
    [[NSColor blackColor] set];
    NSString *label = [I_categories objectAtIndex:index];
    NSSize labelSize = [label sizeWithAttributes:labelAttributes];
    [label drawAtPoint:NSMakePoint((bounds.size.width - labelSize.width) / 2, 1.0)
        withAttributes:labelAttributes];
}

- (void)drawRect:(NSRect)rect {
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    
    [NSGraphicsContext saveGraphicsState];
    
    NSAffineTransform *categoryStep = [NSAffineTransform transform];
    [categoryStep translateXBy:0 yBy:20];
    
    int numberOfCategories = [I_categories count];
    int i;
    
    for (i = 0; i < numberOfCategories; i++) {
        [self drawCategoryAtIndex:i];
        [categoryStep concat];
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)noteEnclosingScrollView {
    NSScrollView *scrollView = nil;
    if ((scrollView = [self enclosingScrollView])) {
        [[NSNotificationCenter defaultCenter] 
                addObserver:self 
                   selector:@selector(enclosingScrollViewFrameDidChange:) 
                       name:NSViewFrameDidChangeNotification object:scrollView];
    }
    [self resizeToFit];
}

- (void)resizeToFit {
    NSScrollView *scrollView = [self enclosingScrollView];
    if (scrollView) {
        NSRect frame = [[scrollView contentView] frame];
        int numberOfItems = [I_categories count];
        float desiredHeight = numberOfItems * 20;
         if (frame.size.height < desiredHeight) {
            frame.size.height = desiredHeight;
        }
        [self setFrameSize:frame.size];
    }
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)enclosingScrollViewFrameDidChange:(NSNotification *)notification {
    [self resizeToFit];
}

@end
