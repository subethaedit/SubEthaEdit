#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#define TCM_DEFAULT_SCREEN_SCALE [[UIScreen mainScreen] scale]
#else
#define TCM_DEFAULT_SCREEN_SCALE 1.0
#endif

#define TCMRadiansFromDegrees(Degrees) ((Degrees) / 180.0 * M_PI)
#define TCMDegreesFromRadians(Radians) ((Radians) / M_PI  * 180.0)

@interface CATransaction (TCMCATransactionAdditions)
+ (void)TCM_wrapInTransactionWithDisabledActions:(void (^)())aTransactionBlock;
@end

CGPoint TCMCGPointEnsuredToPixelBoundaries(CGPoint aPoint);

@interface CALayer (CALayerTCMAdditions)
+ (CGColorRef)TCM_createRandomDebugColor CF_RETURNS_RETAINED;
#if TARGET_OS_IPHONE
- (UIImage *)TCMImageRepresentation;
- (UIImage *)TCMImageRepresentationWithMaskPath:(UIBezierPath *)aMaskPath;
#endif
// if both are used, we are asured the layer is as adjusted to the pixel grid as possible
- (void)TCM_adjustPositionToBeOnPixelGridBoundaries;
- (void)TCM_adjustAnchorPointToBeOnPixelGridBoundaries;
- (CGPoint)TCM_anchorPointInBounds;
- (void)TCM_setAnchorPointInBounds:(CGPoint)aBoundsAnchorPoint;


// debugging helpers
- (void)TCM_colorBorderWithColor:(CGColorRef)aBorderColor;
// color all borders of sublayers corresponding to the layer depth
- (void)TCM_recursiveColorSublayerBorders;
// method with all the options
- (void)TCM_recursiveColorSublayerBordersColorBackground:(BOOL)shouldColorBackground showAnchorPoint:(BOOL)shouldShowAnchorPoint colorByDepth:(BOOL)shouldColorByDepth ;
/** removes the added subviews and styles added by the color sublayer methods*/
- (void)TCM_recursiveRemoveDebugDisplay;

- (void)TCM_setPositionByMovingSuperLayer:(CGPoint)aPosition;
// takes position and transform from presentationLayer
- (void)TCM_takeStateFromPresentationLayer;


@end
