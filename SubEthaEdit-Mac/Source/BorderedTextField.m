//  BorderedTextField.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.12.05.

#import "BorderedTextField.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface BorderedTextField ()
@property (nonatomic) NSSize cachedIntrinsicContentSize;
@end

@implementation BorderedTextField

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setHasRightBorder: YES];
        [self setHasLeftBorder:   NO];
        [self setBorderColor:[NSColor grayColor]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    [self setHasRightBorder: YES];
    [self setHasLeftBorder:   NO];
    [self setBorderColor:[NSColor grayColor]];
    return self;
}

- (void)setHasRightBorder:(BOOL)aFlag {
    if (_hasRightBorder!=aFlag) {
        _hasRightBorder =aFlag;
        [self setNeedsDisplay:YES];
    }
}
- (void)setHasLeftBorder:(BOOL)aFlag {
    if (_hasLeftBorder!=aFlag) {
        _hasLeftBorder =aFlag;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)anEvent {
    if ([self action]) {
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)__updateIntrinsicContentSize {
    _cachedIntrinsicContentSize = ({
        NSSize positionTextSize = [self.stringValue sizeWithAttributes:@{NSFontAttributeName:self.font}];
        positionTextSize.width  = ceil((positionTextSize.width + 9.) / 3.0) * 3.0; // make it raster at 4 points
        positionTextSize.height = round(positionTextSize.height + 2.);
        positionTextSize;
    });
}

- (void)__invalidateIntrinsicContentSize {
    _cachedIntrinsicContentSize = NSZeroSize;
}

- (NSSize)intrinsicContentSize {
    if (_cachedIntrinsicContentSize.height == 0.0) {
        [self __updateIntrinsicContentSize];
    }
    return _cachedIntrinsicContentSize;
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue {
    [super setAttributedStringValue:attributedStringValue];
    [self __invalidateIntrinsicContentSize];
}

- (void)setStringValue:(NSString *)stringValue {
    [super setStringValue:stringValue];
    [self __invalidateIntrinsicContentSize];
}

- (void)drawRect:(NSRect)aRect {
	[[NSColor clearColor] set];
	NSRectFill(self.bounds);
	
	// to make things line up with our popover
	NSRect adjustedBounds = NSOffsetRect(NSInsetRect(self.bounds, 0, 1),0,1);
	[[self cell] drawInteriorWithFrame:adjustedBounds inView:self];
	
    [_borderColor set];
    NSRect bounds=NSIntegralRect([self bounds]);
	bounds = NSInsetRect(bounds, 0.5, 0);
    if (_hasRightBorder) {
        [NSBezierPath setDefaultLineWidth:1.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds))
                                  toPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];
    }
    if (_hasLeftBorder) {
        [NSBezierPath setDefaultLineWidth:1.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMinY(bounds))
                                  toPoint:NSMakePoint(NSMinX(bounds),NSMaxY(bounds))];
    }
}

@end
