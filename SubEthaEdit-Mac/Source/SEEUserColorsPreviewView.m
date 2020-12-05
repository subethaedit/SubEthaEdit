//  SEEUserColorsPreviewView.m
//  SubEthaEdit
//
//  Created by Lisa Brodner on 16/04/14.

#import "SEEUserColorsPreviewView.h"

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
		[self exposeBinding:@"showsChangesHighlight"];
	}
}

- (BOOL)isFlipped {
	return YES;
}

- (instancetype)initWithFrame:(NSRect)aFrame {
	aFrame.size.height = 36;
    self = [super initWithFrame:aFrame];
    if (self) {
		self.selectionLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectMake(5, 8, 40, 32)];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
            [label setStringValue:SEE_NoLocalizationNeeded(@"In the beginning")];
			[self addSubview:label];
			label;
		});
		
		self.changesLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectZero];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
            [label setStringValue:SEE_NoLocalizationNeeded(@"the Universe")];
			[self addSubview:label];
			label;
		});
		
		self.normalLabel = ({
			NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectZero];
			[label setBackgroundColor:[NSColor clearColor]];
			[label setBezeled:NO];
			[label setEditable:NO];
            [label setStringValue:SEE_NoLocalizationNeeded(@"was created. This has made a")];
			[[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];
			[self addSubview:label];
			label;
		});
		
		[self setPropertiesWithUserDefaultsValues];
		[self updateLabels];
		
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
	[self addObserver:self forKeyPath:@"showsChangesHighlight" options:0 context:SEEUserColorsPreviewUpdateObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"userColorHue" context:SEEUserColorsPreviewUpdateObservingContext];
	[self removeObserver:self forKeyPath:@"changesSaturation" context:SEEUserColorsPreviewUpdateObservingContext];
	[self removeObserver:self forKeyPath:@"selectionSaturation" context:SEEUserColorsPreviewUpdateObservingContext];
	[self removeObserver:self forKeyPath:@"showsChangesHighlight" context:SEEUserColorsPreviewUpdateObservingContext];
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
	// background
	[self.backgroundColor set];
	NSRectFill(self.bounds);
	
	// selection
	CGRect selectionRect = CGRectZero;
//	selectionRect.size = [self.selectionLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName : self.font }];
//	selectionRect = [self convertRect:selectionRect fromView:self.selectionLabel];

	selectionRect = self.selectionLabel.frame;
	selectionRect = [self centerScanRect:selectionRect];
	
	[self.selectionColor set];
	NSRectFill(selectionRect);
	
	[self.selectionBorderColor set];
	NSFrameRectWithWidth(selectionRect,1.0);
	
	// changes
	if (self.showsChangesHighlight) {
		CGRect changesRect = CGRectZero;
//		changesRect.size = [self.changesLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName : self.font }];
//		changesRect = [self convertRect:changesRect fromView:self.changesLabel];
		changesRect = self.changesLabel.frame;
		
		changesRect = [self centerScanRect:changesRect];
		[self.changesColor set];
		NSRectFill(changesRect);
	}
	
	// draw the labels
    [super drawRect:aDirtyRect];
	
	// border
    if (@available(macOS 10.14, *)) {
        [[NSColor separatorColor] set];
    } else {
        [[NSColor lightGrayColor] set];
    }
	NSFrameRectWithWidth(self.bounds, 1.0);
}

#pragma mark - Label resize
- (void)updateLabels {
	NSTextField *previousLabel = nil;
	
	CGFloat advancementOfSpace = [@" " sizeWithAttributes:@{NSFontAttributeName:self.font}].width;
	
	previousLabel = ({
		NSTextField *label = self.selectionLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
		[label sizeToFit];
		label;
	});
	
	previousLabel = ({
		NSTextField *label = self.changesLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
		[label sizeToFit];
		[label setFrameOrigin:NSMakePoint(NSMaxX(previousLabel.frame) + round(advancementOfSpace), NSMinY(previousLabel.frame))];
		label;
	});

	{
		NSTextField *label = self.normalLabel;
		[label setFont:self.font];
		[label setTextColor:self.textColor];
		[label sizeToFit];
		[label setFrameOrigin:NSMakePoint(NSMaxX(previousLabel.frame) + round(advancementOfSpace * 0.6), NSMinY(previousLabel.frame))];
	}
}

#pragma mark - Update View
- (void)updateView {
	[self updateDependentPropertiesFromBaseProperties];
	[self updateLabels];
	[self setNeedsDisplay:YES];
}

- (void)updateViewWithUserDefaultsValues {
	[self setPropertiesWithUserDefaultsValues];
	[self updateLabels];
	[self setNeedsDisplay:YES];
}

#pragma mark - Changed Origin Properties 
- (void)updateDependentPropertiesFromBaseProperties {
	self.font = [self fontFromDefaultMode];
	
	NSNumber *userColorHue = self.userColorHue;
    NSValueTransformer *hueTransformer = [NSValueTransformer valueTransformerForName:@"HueToColor"];
	NSColor *userColor = (NSColor *)[hueTransformer transformedValue:userColorHue];
	self.userColor = userColor;
	
	NSColor *backgroundColor = self.backgroundColor;
		
	float changesSaturationFloat = [self.changesSaturation floatValue]/100.;
	self.changesColor = [backgroundColor blendedColorWithFraction:changesSaturationFloat ofColor:userColor];
	
	float selectionSaturationFloat = [self.selectionSaturation floatValue]/100.;
	self.selectionColor = [backgroundColor blendedColorWithFraction:selectionSaturationFloat ofColor:userColor];
	self.selectionBorderColor = [self.selectionColor shadowWithLevel:0.3];
}

#pragma mark - User Defaults and Base Mode
- (void)setPropertiesWithUserDefaultsValues {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	self.font = [self fontFromDefaultMode];
	
	self.showsChangesHighlight = [defaults boolForKey:HighlightChangesPreferenceKey];
	
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
	self.changesSaturation = [defaults objectForKey:ChangesSaturationPreferenceKey];
		
	float changesSaturationFloat = [self.changesSaturation floatValue]/100.;
	self.changesColor = [backgroundColor blendedColorWithFraction:changesSaturationFloat ofColor:userColor];

	float selectionSaturationFloat = [self.selectionSaturation floatValue]/100.;
	self.selectionColor = [backgroundColor blendedColorWithFraction:selectionSaturationFloat ofColor:userColor];
	self.selectionBorderColor = [self.selectionColor shadowWithLevel:0.3];
}

- (NSFont *)fontFromDefaultMode {
	DocumentModeManager *modeManager = [DocumentModeManager sharedInstance];
    NSFont *font = [[NSFontManager sharedFontManager] convertFont:modeManager.baseMode.plainFontBase toSize:11.0];
	return font;
}

@end
