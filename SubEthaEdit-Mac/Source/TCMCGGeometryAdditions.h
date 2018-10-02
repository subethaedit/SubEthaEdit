//  TCMCGGeometryAdditions.h
//  Boardgame Construction Kit
//
//  Created by Dominik Wagner on 09.08.13.

#import <Foundation/Foundation.h>

#define TCMPointOffset(Point,X,Y) ({ typeof(Point) __p = (Point); __p.x += (X); __p.y += (Y); __p;})
#define TCMPointDifference(Point1, Point2) ({ typeof(Point1) __p1 = (Point1);  typeof(Point2) __p2 = (Point2); CGPointMake(__p1.x - __p2.x, __p1.y - __p2.y);})
#define TCMPointDistance(Point1,Point2) ({ typeof(Point1) __pd1 = (Point1);  typeof(Point2) __pd2 = (Point2); TCMVectorLength(TCMPointDifference(__pd1,__pd2)); })
#define TCMVectorLength(Point) ({ typeof(Point) __p = (Point); (sqrt(pow(__p.x,2) + pow(__p.y,2)));})
#define TCMVectorDotProduct(Point1,Point2) ({ typeof(Point1) __p1 = (Point1);  typeof(Point2) __p2 = (Point2); (__p1.x * __p2.x + __p1.y * __p2.y);})

#if !defined(TCM_SCALAR_COMPARE)
#define TCM_SCALAR_COMPARE(A,B)	({ typeof(A) __a = (A); typeof(B) __b = (B); __a < __b ? NSOrderedAscending : (__a > __b ? NSOrderedDescending : NSOrderedSame); })
#endif


/** aPosition 0.0 => aStartPoint, aPosition 1.0 => anEndPoint */
CGPoint TCMCGPointLinearInterpolation(CGPoint aStartPoint, CGPoint anEndPoint, CGFloat aPosition);

@interface TCMOrientedPoint : NSObject <NSCopying>
@property (nonatomic) CGPoint point;
@property (nonatomic) CGFloat angleInDegrees;
@property (nonatomic) CGFloat angleInRadians;

+ (instancetype)orientedPointWithCGPoint:(CGPoint)aPoint angleInDegrees:(CGFloat)aDegreeAngle;
+ (instancetype)orientedPointWithJSONRepresentation:(id)aJSONRepresentation;
- (id)JSONRepresentation;
- (void)takeValuesFromOrientedPoint:(TCMOrientedPoint *)anotherPoint;

// rounds the values;
- (id)normalizedCopy;

@end
