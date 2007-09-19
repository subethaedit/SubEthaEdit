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


@implementation HUDStatisticPersonCell

- (NSRect)userImageRectForBounds:(NSRect)aBounds {
    NSRect result = NSMakeRect(aBounds.origin.x,aBounds.origin.y,64.,64.);
    float inset = (int)((aBounds.size.height-result.size.height) / 2.);
    result.origin.y += inset;
    result.origin.x += MIN(inset,10.);
    return result;
}

- (NSRect)labelRectForBounds:(NSRect)aBounds {
    aBounds.size.width-=64.+10.+10.+10.;
    aBounds.origin.x+=64.+10.+10.;
    return NSInsetRect(aBounds,0.,0.);
}

- (void)drawInteriorWithFrame:(NSRect)aFrame inView:(NSView *)aControlView {
    static NSMutableDictionary *mNameAttributes=nil;
    static NSMutableDictionary *mStatusAttributes=nil;
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont boldSystemFontOfSize:[NSFont systemFontSize]],NSFontAttributeName,
            [NSColor whiteColor],NSForegroundColorAttributeName,
            nil] retain];
    }
    if (!mStatusAttributes) {
        mStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			   [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
               [NSColor colorWithCalibratedWhite:0.8 alpha:1.0],NSForegroundColorAttributeName,
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
    [userImage setFlipped:YES];
    [userImage drawInRect:imageRect fromRect:NSMakeRect(0,0,[userImage size].width,[userImage size].height) operation:NSCompositeSourceOver fraction:1.0];
    [[NSColor redColor] set];
    //NSFrameRect(aFrame);
    
    NSRect labelRect = [self labelRectForBounds:aFrame];
    [[NSColor greenColor] set];
    [[user name] drawInRect:labelRect withAttributes:mNameAttributes];
    
    NSString *statString = [NSString stringWithFormat:@"ins:%d dels:%d sels:%d ops:%d",[entry insertedCharacters],[entry deletedCharacters],[entry selectedCharacters],[entry operationCount]];
    NSString *lastActivityString = [NSString stringWithFormat:@"Last activity: %@\n%@",[[entry dateOfLastActivity] descriptionWithCalendarFormat:@"%d.%m.%y %H:%M:%S"],statString];
    [lastActivityString drawInRect:NSOffsetRect(NSInsetRect(labelRect,0,10.),0,10.) withAttributes:mStatusAttributes];
    // NSFrameRect(labelRect);
}

@end
