#import "TCMCALayerAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static CGColorRef createRandomDebugColor();
static CGColorRef createRandomDebugColor() {
	CGFloat r,g,b,a;
	a = 1.0;
	r = arc4random_uniform(256)/255. * 1.0;
	g = arc4random_uniform(256)/255. * 1.0;
	b = arc4random_uniform(256)/255. * 1.0;
	
	if (r+g+b < 1.0) {
		if (r+g < 1.0) {
			if (arc4random_uniform(2) == 0) {
				r = 1.0;
			} else {
				g = 1.0;
			}
		} else if (b+g < 1.0) {
			if (arc4random_uniform(2) == 0) {
				b = 1.0;
			} else {
				g = 1.0;
			}
		} else if (r+b < 1.0) {
			if (arc4random_uniform(2) == 0) {
				r = 1.0;
			} else {
				b = 1.0;
			}
		}
	}
	
	CGFloat colorArray[4];
	colorArray[0] = r;
	colorArray[1] = g;
	colorArray[2] = b;
	colorArray[3] = a;
	static CGColorSpaceRef colorSpace = NULL;
	if (!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef result = CGColorCreate(colorSpace, colorArray);
	return result;
}

@implementation CATransaction (TCMCATransactionAdditions)
+ (void)TCM_wrapInTransactionWithDisabledActions:(void (^)())aTransactionBlock {
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	aTransactionBlock();
	[CATransaction commit];
}
@end

inline CGPoint TCMCGPointEnsuredToPixelBoundaries(CGPoint aPoint) {
	CGFloat screenScale = TCM_DEFAULT_SCREEN_SCALE;
	
	CGPoint result = CGPointMake(round(aPoint.x * screenScale) / screenScale,
															 round(aPoint.y * screenScale) / screenScale);
	return result;
}


@implementation CALayer (CALayerTCMAdditions)

#if TARGET_OS_IPHONE
- (UIImage *)TCMImageRepresentation {
	UIImage *result = [self TCMImageRepresentationWithMaskPath:nil];
	return result;
}


- (UIImage *)TCMImageRepresentationWithMaskPath:(UIBezierPath *)aMaskPath {
	BOOL opaque = NO;
	CGFloat contentsScale = [[UIScreen mainScreen] scale];
	UIGraphicsBeginImageContextWithOptions(self.bounds.size,opaque,contentsScale);

	[aMaskPath addClip];
	
	[self renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}
#endif

static const void *DEBUG_LAYER_ARRAY_ASSOC_KEY = &DEBUG_LAYER_ARRAY_ASSOC_KEY;
static NSString * const kTCMDebugBorderPreviousValues = @"previousBorderValues";
static NSString * const kTCMDebugBorderAnchorPointLayers = @"anchorPointLayers";

// store any layers in there you temporaryly added so we can remove them later
- (NSMutableDictionary *)TCM_visualDebugDictionary {
	NSMutableDictionary *result = objc_getAssociatedObject(self,DEBUG_LAYER_ARRAY_ASSOC_KEY);
	if (!result) {
		result = [NSMutableDictionary new];
		objc_setAssociatedObject(self, DEBUG_LAYER_ARRAY_ASSOC_KEY, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}


+ (CGColorRef)TCM_createRandomDebugColor  {
    return createRandomDebugColor();
}

- (CGPoint)TCM_anchorPointInBounds {
	CGPoint anchorPoint = self.anchorPoint;
	CGRect bounds = self.bounds;
	CGPoint result = CGPointMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * anchorPoint.x,
								 CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * anchorPoint.y);
	return result;
}

- (void)TCM_setAnchorPointInBounds:(CGPoint)aBoundsAnchorPoint {
	CGRect bounds = self.bounds;
	CGPoint normalizedPoint = CGPointMake(aBoundsAnchorPoint.x - CGRectGetMinX(bounds),
										  aBoundsAnchorPoint.y - CGRectGetMinY(bounds));
	normalizedPoint.x /= CGRectGetWidth(bounds);
	normalizedPoint.y /= CGRectGetHeight(bounds);
	
	self.anchorPoint = normalizedPoint;
}

- (void)TCM_adjustAnchorPointToBeOnPixelGridBoundaries {
	CGFloat screenScale = TCM_DEFAULT_SCREEN_SCALE;
	CGSize boundsSize = CGRectStandardize(self.bounds).size;
	CGPoint anchorPoint = self.anchorPoint;
	CGFloat factorX = screenScale * boundsSize.width;
	CGFloat factorY = screenScale * boundsSize.height;
	CGPoint adjustedAnchorPoint = CGPointMake(round(anchorPoint.x * factorX) / factorX,
	                                          round(anchorPoint.y * factorY) / factorY);
	if (CGPointEqualToPoint(anchorPoint, adjustedAnchorPoint)) {
		// do nothing
	} else {
		self.anchorPoint = adjustedAnchorPoint;
	}
}

- (void)TCM_adjustPositionToBeOnPixelGridBoundaries {
	CGPoint positionPoint = self.position;
	CGPoint adjustedPositionPoint = TCMCGPointEnsuredToPixelBoundaries(positionPoint);
	if (CGPointEqualToPoint(positionPoint, adjustedPositionPoint)) {
		// do nothing
	} else {
		self.position = adjustedPositionPoint;
	}
}

- (void)TCM_colorBorderWithColor:(CGColorRef)aBorderColor {
	[self TCM_colorBorderWithColor:aBorderColor backgroundAlpha:0.0];
}

- (void)TCM_colorBorderWithColor:(CGColorRef)aBorderColor backgroundAlpha:(CGFloat)aBackgroundAlpha{
	BOOL hadColor = aBorderColor != NULL;
	if (!hadColor) {
		aBorderColor = createRandomDebugColor();
	}

	if (!self.TCM_visualDebugDictionary[kTCMDebugBorderPreviousValues]) {
		NSMutableDictionary *values = [@{
										 @"borderWidth" : @(self.borderWidth),
										 } mutableCopy];
		if (self.borderColor) values[@"borderColor"] = (__bridge id)self.borderColor;
		if (aBackgroundAlpha > 0) {
			if (self.backgroundColor) values[@"backgroundColor"] = (__bridge id)self.backgroundColor;
			else values[@"backgroundColor"] = [NSNull null];
		}
		self.TCM_visualDebugDictionary[kTCMDebugBorderPreviousValues] = [values copy];
	}
	
	self.borderWidth = 1.0;
	self.borderColor = aBorderColor;
	
	if (aBackgroundAlpha > 0.0) {
		CGColorRef alphaedBorderColor = CGColorCreateCopyWithAlpha(aBorderColor, 0.2);
		self.backgroundColor = alphaedBorderColor;
		CGColorRelease(alphaedBorderColor);
	}
	
	if (!hadColor) CGColorRelease(aBorderColor);
}

- (void)TCM_resetBorderColor {
	NSDictionary *previousValues = self.TCM_visualDebugDictionary[kTCMDebugBorderPreviousValues];
	self.borderWidth = [previousValues[@"borderWidth"] floatValue];
	{
		id colorRef = previousValues[@"borderColor"];
		if (colorRef) {
			self.borderColor = (__bridge CGColorRef)colorRef;
		}
	}
	{
		id colorRef = previousValues[@"backgroundColor"];
		if ([colorRef isKindOfClass:[NSNull class]]) {
			self.backgroundColor = nil;
		} else if (colorRef) {
			self.backgroundColor = (__bridge CGColorRef)colorRef;
		}
	}
	[self.TCM_visualDebugDictionary removeObjectForKey:kTCMDebugBorderPreviousValues];
}

- (void)TCM_addDebugAnchorPointVisualisationWithColor:(CGColorRef)aLineColor {
	CGPoint position = self.anchorPoint;
	position.x = CGRectGetMinX(self.bounds) + CGRectGetWidth(self.bounds) * position.x;
	position.y = CGRectGetMinY(self.bounds) + CGRectGetHeight(self.bounds) * position.y;
	NSMutableArray *anchorDebugLayers = [NSMutableArray new];
	for (int i = 0; i<2; i++) {
		CALayer *layer = [CALayer layer];
		layer.borderColor = aLineColor;
		layer.borderWidth = 1.0;
		layer.bounds = CGRectMake(0,0,i == 1 ? 8.0 : 1.0, i == 0 ? 8.0 : 1.0);
		layer.position = position;
		layer.transform = CATransform3DMakeTranslation(0, 0, 10);
		[self addSublayer:layer];
		[anchorDebugLayers addObject:layer];
	}
	self.TCM_visualDebugDictionary[kTCMDebugBorderAnchorPointLayers] = [anchorDebugLayers copy];
}

- (void)TCM_recursiveColorSublayerBordersColorBackground:(BOOL)shouldColorBackground showAnchorPoint:(BOOL)shouldShowAnchorPoint colorByDepth:(BOOL)shouldColorByDepth {
	NSMutableArray *collectedSublayers = [self.sublayers mutableCopy];
	
	while (collectedSublayers.count > 0) {
		NSArray *layersToEnumerate = [collectedSublayers copy];
		[collectedSublayers removeAllObjects];
		__block CGColorRef borderColor = createRandomDebugColor();
		[layersToEnumerate enumerateObjectsWithOptions:0 usingBlock:^(CALayer *aLayer, NSUInteger idx, BOOL *stop) {
			if (!shouldColorByDepth) {
				CGColorRelease(borderColor);
				borderColor = createRandomDebugColor();
			}
			
			[aLayer TCM_colorBorderWithColor:borderColor backgroundAlpha:shouldColorBackground ? 0.2 : 0.0];
			
			[collectedSublayers addObjectsFromArray:aLayer.sublayers];

			NSArray *layersToIgnore = aLayer.TCM_visualDebugDictionary[kTCMDebugBorderAnchorPointLayers];
			if (layersToIgnore) {
				[collectedSublayers removeObjectsInArray:layersToIgnore];
			}
			
			if (shouldShowAnchorPoint) {
				if (layersToIgnore) {
					[aLayer TCM_removeAnchorPointLayers];
				}
				[aLayer TCM_addDebugAnchorPointVisualisationWithColor:borderColor];
			}
		}];
		CGColorRelease(borderColor);
	}
}

- (void)TCM_recursiveColorSublayerBorders {
	[self TCM_recursiveColorSublayerBordersColorBackground:YES showAnchorPoint:YES colorByDepth:YES];
}

- (void)TCM_removeAnchorPointLayers {
	if (self.TCM_visualDebugDictionary[kTCMDebugBorderAnchorPointLayers]) {
		for (CALayer *layer in self.TCM_visualDebugDictionary[kTCMDebugBorderAnchorPointLayers]) {
			[layer removeFromSuperlayer];
		}
		[self.TCM_visualDebugDictionary removeObjectForKey:kTCMDebugBorderAnchorPointLayers];
	}
}

- (void)TCM_recursiveRemoveDebugDisplay {
	__block __weak void(^weakRecursiveRemove)(CALayer *);
	void(^recursiveRemove)(CALayer *) = ^(CALayer *aLayer) {
		[aLayer TCM_resetBorderColor];
		[aLayer TCM_removeAnchorPointLayers];
		[aLayer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			weakRecursiveRemove(obj);
		}];
	};
	weakRecursiveRemove = recursiveRemove;
	recursiveRemove(self);
}

- (void)TCM_setPositionByMovingSuperLayer:(CGPoint)aPosition {
	CALayer *superlayer = self.superlayer;
	
	CGPoint superPosition = [superlayer convertPoint:self.position toLayer:superlayer.superlayer];
	NSAssert(!isnan(superPosition.x), @"superposition is not allowed to be NaN");
	if (!isnan(superPosition.x)) { 
		self.position = aPosition;
		CGPoint changedSuperPosition = [superlayer convertPoint:self.position toLayer:superlayer.superlayer];
		
		// adjusting the position for the layout change
		CGAffineTransform positionMovement = CGAffineTransformMakeTranslation(superPosition.x - changedSuperPosition.x,
																			  superPosition.y - changedSuperPosition.y);
		superlayer.position = CGPointApplyAffineTransform(superlayer.position, positionMovement);
	} else {
	}
}

- (void)TCM_takeStateFromPresentationLayer {
	CALayer *presentationLayer = self.presentationLayer;
	if (presentationLayer) { // will return nil if doesn't exist
		self.transform = presentationLayer.transform;
		self.position = presentationLayer.position;
	}
}


@end
