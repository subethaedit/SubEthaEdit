//  TCMCGGeometryAdditions.m
//  Boardgame Construction Kit
//
//  Created by Dominik Wagner on 09.08.13.

#import "TCMCGGeometryAdditions.h"

#import "TCMCALayerAdditions.h"


inline CGPoint TCMCGPointLinearInterpolation(CGPoint aStartPoint, CGPoint anEndPoint, CGFloat aPosition) {
	CGPoint targetPoint = CGPointMake((anEndPoint.x - aStartPoint.x) * aPosition + aStartPoint.x,
									  (anEndPoint.y - aStartPoint.y) * aPosition + aStartPoint.y);
	return targetPoint;
}

@implementation TCMOrientedPoint

@dynamic angleInRadians;

- (instancetype)init {
	self = [super init];
	if (self) {
		_point = CGPointZero;
		_angleInDegrees = 0.0;
	}
	return self;
}

+ (instancetype)orientedPointWithCGPoint:(CGPoint)aPoint angleInDegrees:(CGFloat)aDegreeAngle {
	TCMOrientedPoint *result = [[TCMOrientedPoint alloc] init];
	result.point = aPoint;
	result.angleInDegrees = aDegreeAngle;
	return result;
}


+ (TCMOrientedPoint *)orientedPointWithJSONRepresentation:(id)aJSONRepresentation {
	TCMOrientedPoint *result;
	if ([aJSONRepresentation isKindOfClass:[NSArray class]]) {
		NSArray *jsonRepresentationArray = (NSArray *)aJSONRepresentation;
		if ([jsonRepresentationArray count] > 1) {
			result = [TCMOrientedPoint new];
			result.point = CGPointMake([[jsonRepresentationArray objectAtIndex:0] doubleValue],[[jsonRepresentationArray objectAtIndex:1] doubleValue]);
			if ([jsonRepresentationArray count] > 2) {
				result.angleInDegrees = [[jsonRepresentationArray objectAtIndex:2] doubleValue];
			}
		}
	}
	return result;
}


- (NSString *)description {
	NSString *result = [NSString stringWithFormat:@"<%@: %p; point: %@; angle: %0.3f>",NSStringFromClass([self class]),self,NSStringFromPoint(_point),_angleInDegrees];
	return result;
}

- (id)JSONRepresentation {
	if (_angleInDegrees == 0.0) {
		return @[@(_point.x),@(_point.y)];
	} else {
		return @[@(_point.x),@(_point.y),@(_angleInDegrees)];
	}
}


- (BOOL)isEqual:(id)anObject {
	if ([anObject isKindOfClass:[self class]]) {
		TCMOrientedPoint *otherPoint = (TCMOrientedPoint *)anObject;
		if (CGPointEqualToPoint(self.point, otherPoint.point) &&
			self.angleInDegrees == otherPoint.angleInDegrees) {
			return YES;
		} else {
			return NO;
		}
	} else {
		return [super isEqual:anObject];
	}
}

- (void)setAngleInRadians:(CGFloat)angleInRadians {
	_angleInDegrees = TCMDegreesFromRadians(angleInRadians);
}

- (CGFloat)angleInRadians {
	return TCMRadiansFromDegrees(_angleInDegrees);
}

- (void)takeValuesFromOrientedPoint:(TCMOrientedPoint *)anotherPoint {
	self.point = anotherPoint.point;
	self.angleInDegrees = anotherPoint.angleInDegrees;
}


- (instancetype)copyWithZone:(NSZone *)zone {
	TCMOrientedPoint *result = [TCMOrientedPoint new];
	result.point = self.point;
	result.angleInDegrees = self.angleInDegrees;
	return result;
}

#define ROUND_DECIMAL(aDouble,decimalPlaces) (round((aDouble)*pow(10.0,(decimalPlaces))) / pow(10.0,(decimalPlaces)))
#define RETINA_ROUND(aDouble) (round((aDouble) * 2.0) / 2.0)

- (instancetype)normalizedCopy {
	TCMOrientedPoint *result = self.copy;
	result.point = CGPointMake(RETINA_ROUND(_point.x),RETINA_ROUND(_point.y));
	result.angleInDegrees = ROUND_DECIMAL(_angleInDegrees,2);
	return result;
}


@end
