//
//  DialogBackgroundView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 06.12.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "DialogBackgroundView.h"

static CGFunctionRef sLinearFunctionRef = nil;
static CGColorSpaceRef sColorSpace;

typedef struct {
  CGFloat red1, green1, blue1, alpha1;
  CGFloat red2, green2, blue2, alpha2;
} _twoColorsType;

static void _linearColorBlendFunction(void *info, const CGFloat *in, CGFloat *out)
{
  _twoColorsType *twoColors = info;
  
  out[0] = (1.0 - *in) * twoColors->red1 + *in * twoColors->red2;
  out[1] = (1.0 - *in) * twoColors->green1 + *in * twoColors->green2;
  out[2] = (1.0 - *in) * twoColors->blue1 + *in * twoColors->blue2;
  out[3] = (1.0 - *in) * twoColors->alpha1 + *in * twoColors->alpha2;
}

static void _linearBounceColorBlendFunction(void *info, const CGFloat *in, CGFloat *out)
{
  _twoColorsType *twoColors = info;
  CGFloat realIn;
//  realIn=1.-sin(*in*M_PI); // sin doesn't look the way i wanted it
  realIn=ABS(*in*2.-1.);
  realIn=sqrt(realIn);
  out[0] = realIn * twoColors->red1   + (1.0 - realIn) * twoColors->red2;
  out[1] = realIn * twoColors->green1 + (1.0 - realIn) * twoColors->green2;
  out[2] = realIn * twoColors->blue1  + (1.0 - realIn) * twoColors->blue2;
  out[3] = realIn * twoColors->alpha1 + (1.0 - realIn) * twoColors->alpha2;
}


static void _linearColorReleaseInfoFunction(void *info)
{
  free(info);
}

static const CGFunctionCallbacks linearFunctionCallbacks = {0,
  &_linearColorBlendFunction, &_linearColorReleaseInfoFunction};

@implementation DialogBackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    if (!sLinearFunctionRef)  {
        _twoColorsType *twoColors=malloc(sizeof(_twoColorsType));
        twoColors->red1 = twoColors->green1 = twoColors->blue1 = 0.83;
        twoColors->alpha1 = twoColors->alpha2 = 1.0;
        twoColors->red2 = twoColors->green2 = twoColors->blue2 = 0.91;
        static const CGFloat domainAndRange[8] = {0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0};
        sLinearFunctionRef=CGFunctionCreate(twoColors, 1,
        domainAndRange, 4, domainAndRange, &linearFunctionCallbacks);
        sColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    // with fancy CGShading
    NSRect bounds=[self bounds];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context); {
      CGContextClipToRect(context, (CGRect){{NSMinX(bounds),
          NSMinY(bounds)}, {NSWidth(bounds),
          NSHeight(bounds)}});
      CGShadingRef cgShading = CGShadingCreateAxial(sColorSpace,
          CGPointMake(0, NSMinY(bounds)), CGPointMake(0,
          NSMaxY(bounds)), sLinearFunctionRef, NO, NO);
      CGContextDrawShading(context, cgShading);
      CGShadingRelease(cgShading);
    } CGContextRestoreGState(context);
}

- (BOOL)isOpaque {
  return YES;
}
@end
