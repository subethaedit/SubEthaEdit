//
//  HUDStatisticPersonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 19.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "HUDStatisticPersonCell.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMLogStatisticsEntry.h"
#import "NSColorTCMAdditions.h"
#import "NSBezierPathTCMAdditions.h"


@implementation HUDStatisticPersonCell

- (NSRect)userImageRectForBounds:(NSRect)aBounds {
    NSRect result = NSMakeRect(aBounds.origin.x,aBounds.origin.y,48.,48.);
    float inset = (int)((aBounds.size.height-result.size.height) / 2.);
    result.origin.y += inset;
    result.origin.x += MIN(inset,10.);
    return result;
}

- (NSRect)labelRectForBounds:(NSRect)aBounds {
    aBounds.size.width-=48.+10.+10.+10.;
    aBounds.origin.x+=48.+10.+10.;
    return NSInsetRect(aBounds,0.,0.);
}

- (void)drawInteriorWithFrame:(NSRect)aFrame inView:(NSView *)aControlView {
    static NSMutableDictionary *mNameAttributes=nil;
    static NSMutableDictionary *mStatusAttributes=nil;
    static NSMutableDictionary *mPercentageAttributes=nil;
    static NSMutableParagraphStyle *mNoWrapParagraphStyle = nil;
    if (!mNoWrapParagraphStyle) {
        mNoWrapParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [mNoWrapParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        if ([mNoWrapParagraphStyle respondsToSelector:@selector(setTighteningFactorForTruncation:)]) {
            [mNoWrapParagraphStyle setTighteningFactorForTruncation:0.25];
        }
    }
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont boldSystemFontOfSize:[NSFont systemFontSize]],NSFontAttributeName,
            [NSColor whiteColor],NSForegroundColorAttributeName,
            mNoWrapParagraphStyle,NSParagraphStyleAttributeName,
            nil] retain];
    }
    if (!mStatusAttributes) {
        mStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			   [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]],NSFontAttributeName,
               [NSColor colorWithCalibratedWhite:0.6 alpha:1.0],NSForegroundColorAttributeName,
               mNoWrapParagraphStyle,NSParagraphStyleAttributeName,
			   nil] retain];
    } 
    if (!mPercentageAttributes) {
        mPercentageAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			   [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]],NSFontAttributeName,
               [NSColor colorWithCalibratedWhite:0.9 alpha:1.0],NSForegroundColorAttributeName,
			   nil] retain];
    } 

    TCMMMLogStatisticsEntry *entry = (TCMMMLogStatisticsEntry *)[self objectValue];
    TCMMMUser *user = [entry user];
    NSImage *userImage = [user image];
    NSRect imageRect = [self userImageRectForBounds:aFrame];
    NSSize imageSize = [userImage size];
    if (ABS(imageSize.height-imageSize.width) > 0.01) {
        if (imageSize.height > imageSize.width) {
            imageRect.size.width = imageRect.size.height/imageSize.height*imageSize.width;
            imageRect.origin.x  += ABS(imageRect.size.height-imageRect.size.width) / 2.;
        } else {
            imageRect.size.height = imageRect.size.width/imageSize.width*imageSize.height;
            //imageRect.origin.y   += ABS(imageRect.size.height-imageRect.size.width) / 2.;
        }
    }
//    if (![entry isInside]) {
//        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.25] set];
//        [NSBezierPath fillRect:imageRect];
//    }
    [userImage setFlipped:YES];
    [userImage drawInRect:imageRect fromRect:NSMakeRect(0,0,[userImage size].width,[userImage size].height) operation:NSCompositeSourceOver fraction:[entry isInside]?1.0:0.25];
    [[NSColor redColor] set];
    if ([self isHighlighted]) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle (NSFocusRingOnly);
        [userImage drawInRect:imageRect fromRect:NSMakeRect(0,0,[userImage size].width,[userImage size].height) operation:NSCompositeSourceOver fraction:[entry isInside]?1.0:0.25];
//        [NSBezierPath fillRect:imageRect];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    NSRect labelRect = [self labelRectForBounds:aFrame];
    [[NSColor greenColor] set];
    [[user name] drawInRect:labelRect withAttributes:mNameAttributes];
    
    NSString *statString = [NSString stringWithFormat:@"ins:%d dels:%d sels:%d ops:%d",[entry insertedCharacters],[entry deletedCharacters],[entry selectedCharacters],[entry operationCount]];
    NSString *lastActivityString = [NSString stringWithFormat:@"Last activity: %@\n",[[entry dateOfLastActivity] descriptionWithCalendarFormat:@"%d.%m.%y %H:%M:%S"]];
    labelRect = NSOffsetRect(NSInsetRect(labelRect,0,7.),0,8.);
    [lastActivityString drawInRect:labelRect withAttributes:mStatusAttributes];
    
//    if (![entry isInside]) {
//        NSFrameRect(labelRect);
//    }
//    
    labelRect = NSOffsetRect(NSInsetRect(labelRect,0,8.),0,7.);

    NSColor *deletionsColor  = [NSColor deletionsStatisticsColor];
    NSColor *insertionsColor = [NSColor insertionsStatisticsColor];
    NSColor *selectionsColor = [NSColor selectionsStatisticsColor];
    
    NSColor *colors[] = {deletionsColor,insertionsColor,selectionsColor};
    float absoluteValues[]={[entry deletedCharacters],[entry insertedCharacters],[entry selectedCharacters]};
    TCMMMLoggingState *loggingState = [entry loggingState];
    float sums[]={MAX(1.,[loggingState deletedCharacters]),MAX(1.,[loggingState insertedCharacters]),MAX(1.,[loggingState selectedCharacters])};
    float sumValue = MAX(1.,absoluteValues[0]+absoluteValues[1]+absoluteValues[2]);
    int i=0;
    for (i=0;i<3;i++) {
        [colors[i] set];
        float barValue = absoluteValues[i]/sums[i];
        
        NSRect barRect = NSInsetRect(labelRect,0.,1.);
        barRect.size.width -= 30.;
        NSRect percentageRect = barRect;
        barRect.size.height = 8.;
        barRect.size.width = barValue * barRect.size.width;
        barRect.size.width = MAX(1.,barRect.size.width);
        NSBezierPath *barPath = [NSBezierPath bezierPathWithRoundedRect:barRect radius:MIN(4.,barRect.size.width/2.)];
        [barPath fill];
        
        percentageRect.origin.x = NSMaxX(barRect)+4.;
        percentageRect.size.width = 26.;
        percentageRect.origin.y-=3.;
        [[NSString stringWithFormat:@"%d %%",(int)(barValue * 100)] drawInRect:percentageRect  withAttributes:mPercentageAttributes];
        
        labelRect.origin.y += 11.;
    }

}

@end
