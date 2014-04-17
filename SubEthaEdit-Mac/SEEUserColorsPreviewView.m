//
//  SEEUserColorsPreviewView.m
//  SubEthaEdit
//
//  Created by Lisa Brodner on 16/04/14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEUserColorsPreviewView.h"

#import "SaturationToColorValueTransformer.h"

#import "PreferenceKeys.h"
#import "DocumentModeManager.h"
#import "SEEStyleSheet.h"

@interface SEEUserColorsPreviewView ()

@property (nonatomic, strong) NSFont *font;

@property (nonatomic, strong) NSColor *userColor;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *backgroundColor;

@property (nonatomic, strong) NSColor *changesColor;
@property (nonatomic, strong) NSColor *selectionColor;
@property (nonatomic, strong) NSColor *selectionBorderColor;

@property (nonatomic, strong) NSTextField *changesLabel;
@property (nonatomic, strong) NSTextField *selectionLabel;
@property (nonatomic, strong) NSTextField *normalLabel;

@end

void * const SEEUserColorsPreviewUpdateObservingContext = (void *)&SEEUserColorsPreviewUpdateObservingContext;

@implementation SEEUserColorsPreviewView

+ (void)initialize {
	if (self == [SEEUserColorsPreviewView class]) {
		[self exposeBinding:@"userColorHue"];
		[self exposeBinding:@"changesSaturation"];
		[self exposeBinding:@"selectionSaturation"];
	}
}

- (instancetype)initWithFrame:(NSRect)aFrame {
	aFrame.size = CGSizeMake(122, 40);
    self = [super initWithFrame:aFrame];
    if (self) {
		self.changesLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectMake(2, 8, 40, 32)];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
			[label setStringValue:@"Lorem"];
			[self addSubview:label];
			label;
		});
		
		self.selectionLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectMake(42, 8, 40, 32)];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
			[label setStringValue:@"ipsum"];
			[self addSubview:label];
			label;
		});
		
		self.normalLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectMake(82, 8, 40, 32)];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
			[label setStringValue:@"dolor"];
			[self addSubview:label];
			label;
		});
		
		[self setPropertiesWithUserDefaultsValues];
		[self updateLabels];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWithUserDefaultsValues) name:GeneralViewPreferencesDidChangeNotificiation object:nil];
		[self installKVO];
	}
    return self;
}

- (void)dealloc {
	[self removeKVO];
}

#pragma mark - KVO
- (void)installKVO {
	[self addObserver:self forKeyPath:@"userColorHue" options:0 context:SEEUserColorsPreviewUpdateObservingContext];
	[self addObserver:self forKeyPath:@"changesSaturation" options:0 context:SEEUserColorsPreviewUpdateObservingContext];
	[self addObserver:self forKeyPath:@"selectionSaturation" options:0 context:SEEUserColorsPreviewUpdateObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"userColorHue" context:SEEUserColorsPreviewUpdateObservingContext];
	[self removeObserver:self forKeyPath:@"changesSaturation" context:SEEUserColorsPreviewUpdateObservingContext];
	[self removeObserver:self forKeyPath:@"selectionSaturation" context:SEEUserColorsPreviewUpdateObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChangeDict context:(void *)aContext {
    if (aContext == SEEUserColorsPreviewUpdateObservingContext) {
		[self updateView];
		
    } else {
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChangeDict context:aContext];
    }
}

#pragma mark - Drawing
- (void)drawRect:(NSRect)aDirtyRect {
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRect:self.bounds];
	[self.backgroundColor set];
	[backgroundPath fill];

	[self.textColor set];
	[backgroundPath stroke];

	// selection
	CGRect selectionRect = CGRectZero;
	selectionRect.size = [self.selectionLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName : self.font }];
	selectionRect = [self convertRect:selectionRect fromView:self.selectionLabel];
	selectionRect = NSInsetRect(selectionRect, 1.0, 1.0);
	selectionRect.origin.x += 1.0; // how to do this nicely?
	selectionRect.origin.y -= 1.0; // how to do this nicely?
	selectionRect.size.width += 3.0; // how to do this nicely?

	NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionRect];
	[self.selectionColor set];
	[selectionPath fill];
	
	[self.selectionBorderColor set];
	[selectionPath stroke];
	
	// changes
	CGRect changesRect = CGRectZero;
	changesRect.size = [self.changesLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName : self.font }];
	changesRect = [self convertRect:changesRect fromView:self.changesLabel];
	changesRect.origin.x += 2.0; // how to do this nicely?
	changesRect.origin.y -= 1.0; // how to do this nicely?
	changesRect.size.width += 1.0; // how to do this nicely?
	[self.changesColor set];
	NSRectFill(changesRect);
	
	// draw the labels
    [super drawRect:aDirtyRect];
}

#pragma mark - Label resize
- (void)updateLabels {
	{
		NSTextField *label = self.changesLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
//		[label setBackgroundColor:self.changesColor];
		[label sizeToFit];
	}
	
	{
		NSTextField *label = self.selectionLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
//		[label setBackgroundColor:self.selectionColor];
		[label setBackgroundColor:[NSColor clearColor]];
		[label sizeToFit];
	}
	
	{
		NSTextField *label = self.normalLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
//		[label setBackgroundColor:self.backgroundColor];
		[label sizeToFit];
	}
}
#pragma mark - Update View
- (void)updateView {
	[self updateLabels];
	[self setNeedsDisplay:YES];
}

- (void)updateWithUserDefaultsValues {
	[self setPropertiesWithUserDefaultsValues];
	[self updateLabels];
	[self setNeedsDisplay:YES];
}

#pragma mark - User Defaults and Base Mode
- (void)setPropertiesWithUserDefaultsValues {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	self.font = [self fontFromDefaultMode];
	
	NSNumber *userColorHue = [defaults objectForKey:MyColorHuePreferenceKey];
	self.userColorHue = userColorHue;
    NSValueTransformer *hueTransformer = [NSValueTransformer valueTransformerForName:@"HueToColor"];
	NSColor *userColor = (NSColor *)[hueTransformer transformedValue:userColorHue];
	self.userColor = userColor;
	
	SEEStyleSheetSettings *styleSheetSettings = [[[DocumentModeManager sharedInstance] baseMode] styleSheetSettings];
	self.textColor = [styleSheetSettings documentForegroundColor];
	NSColor *backgroundColor = [styleSheetSettings documentBackgroundColor];
	self.backgroundColor = backgroundColor;
	
	self.selectionSaturation = [defaults objectForKey:SelectionSaturationPreferenceKey];
	self.changesSaturation = [defaults objectForKey:ChangesSaturationPreferenceKey]; // changable
		
	float changesSaturationFloat = [self.changesSaturation floatValue]/100.;
	self.changesColor = [backgroundColor blendedColorWithFraction:changesSaturationFloat ofColor:userColor];

	float selectionSaturationFloat = [self.selectionSaturation floatValue]/100.;
	self.selectionColor = [backgroundColor blendedColorWithFraction:selectionSaturationFloat ofColor:userColor];
	self.selectionBorderColor = [self.selectionColor shadowWithLevel:0.3];
}

- (NSFont *)fontFromDefaultMode {
	DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
	NSDictionary *fontAttributes = [[modeManager baseMode] defaultForKey:DocumentModeFontAttributesPreferenceKey];
	NSFont *font = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
	if (!font) {
		font = [NSFont userFixedPitchFontOfSize:11.];
	}
	return font;
}

@end
