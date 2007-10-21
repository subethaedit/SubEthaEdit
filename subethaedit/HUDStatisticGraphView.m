//
//  HUDStatisticGraphView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "HUDStatisticGraphView.h"
#import "TCMMMLogStatisticsEntry.h"
#import "TCMMMLoggingState.h"
#import "TCMMMLogStatisticsDataPoint.h"
#import "TCMMMUser.h"


@implementation HUDStatisticGraphView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        relativeMode = YES;
		timeInterval = 0.;
    }
    return self;
}

+ (void)initialize {
    [self exposeBinding:@"statisticsEntry"];
}

- (NSArray *)exposedBindings {
    return [NSArray arrayWithObjects:@"statisticsEntry",nil];
}

- (void)setStatisticsEntryContainer:(id)anContainer {
    statisticsEntryContainer = anContainer;
}

- (void)setStatisticsEntryKeyPath:(NSString *)aKeyPath {
    statisticsEntryKeyPath = aKeyPath;
}

- (void)setRelativeMode:(BOOL)aFlag {
    relativeMode = aFlag;
    [self setNeedsDisplay:YES];
}

- (BOOL)relativeMode {
    return relativeMode;
}

- (void)bind:(NSString *)bindingName
    toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
     options:(NSDictionary *)options
{
    
    if ([bindingName isEqualToString:@"statisticsEntry"]) {
        [self setStatisticsEntryContainer:observableObject];
        [self setStatisticsEntryKeyPath:observableKeyPath];
        [statisticsEntryContainer addObserver:self
                            forKeyPath:statisticsEntryKeyPath
                               options:0
                               context:nil];
    } else {
        [super bind:bindingName
           toObject:observableObject
        withKeyPath:observableKeyPath
            options:options];
    }
    [self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    
    if ([bindingName isEqualToString:@"statisticsEntry"]) {
        [statisticsEntryContainer removeObserver:self forKeyPath:statisticsEntryKeyPath];
        [self setStatisticsEntryContainer:nil];
        [self setStatisticsEntryKeyPath:nil];
    } else {    
        [super unbind:bindingName];
    }
    [self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    [self setNeedsDisplay:YES];
}

- (TCMMMLogStatisticsEntry *)statisticsEntry {
    id result = [statisticsEntryContainer valueForKeyPath:statisticsEntryKeyPath];
    return [result lastObject];
}

- (BOOL)isOpaque {
    return NO;
}

#define LEGENDHEIGHT 27.5
#define XMARKERSPACE 20.
#define YMARKERSPACE 27.5
#define YTOPPADDING   8.
#define DATAPOINTS   100

#define LEGENDDOTSIZE 8.
#define LEGENDSPACING 8.
#define LEGENDDOTOFFSET 4.

- (void)drawRect:(NSRect)rect {
    static NSMutableDictionary *mLabelAttributes=nil;

    if (!mLabelAttributes) {
        mLabelAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
               [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]],NSFontAttributeName,
               [NSColor colorWithCalibratedWhite:0.9 alpha:1.0],NSForegroundColorAttributeName,
               nil] retain];
    } 

    // Drawing code here
    NSRect bounds = [self bounds];

    NSColor *deletionsColor  = [NSColor deletionsStatisticsColor];
    NSColor *insertionsColor = [NSColor insertionsStatisticsColor];
    NSColor *selectionsColor = [NSColor selectionsStatisticsColor];
    
    NSColor *colors[] = {deletionsColor,insertionsColor,selectionsColor};
    NSString *labelStrings[] = {NSLocalizedString(@"deletions",@"legend entry for deletions in statistsics hud"),NSLocalizedString(@"insertions",@"legend entry for insertions in statistsics hud"),NSLocalizedString(@"selections",@"legend entry for selections in statistsics hud")};
    NSSize labelSizes[] = {NSZeroSize,NSZeroSize,NSZeroSize};
    int i=0;
    float legendWidth = LEGENDSPACING * 2.;
    for (i=0;i<3;i++) {
        labelSizes[i] = [labelStrings[i] sizeWithAttributes:mLabelAttributes];
        legendWidth += labelSizes[i].width + LEGENDDOTSIZE + LEGENDDOTOFFSET;
    }
    NSPoint location = NSMakePoint(NSMinX(bounds)+(int)((NSWidth(bounds)-legendWidth) / 2.)-4.,NSMinY(bounds)+10.);
    
    for (i=0;i<3;i++) {
        [colors[i] set];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(location.x,location.y,LEGENDDOTSIZE,LEGENDDOTSIZE)] fill];
        location.x+= LEGENDDOTOFFSET + LEGENDDOTSIZE;
        [labelStrings[i] drawAtPoint:NSMakePoint(location.x,location.y-1.) withAttributes:mLabelAttributes];
        location.x+= labelSizes[i].width + LEGENDSPACING;
    }
    


    TCMMMLogStatisticsEntry *entry = [self statisticsEntry];
    TCMMMLoggingState *state = [entry loggingState];
    NSString *userID = [[entry user] userID];
    NSArray *dataPoints = [state statisticsData];
    NSCalendarDate *firstDate = [[dataPoints objectAtIndex:0] objectForKey:@"date"];
    NSCalendarDate *lastDate = [[dataPoints lastObject] objectForKey:@"date"];
	if (timeInterval>0.) {
		firstDate = [[[NSCalendarDate alloc] initWithTimeInterval:-1.*timeInterval sinceDate:lastDate] autorelease];
	}
//    NSLog(@"%s %@-%@",__FUNCTION__,firstDate,lastDate);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *firstDateString = [firstDate descriptionWithCalendarFormat:[defaults objectForKey:NSShortTimeDateFormatString]];
    NSString *lastDateString  = [lastDate  descriptionWithCalendarFormat:[defaults objectForKey:NSShortTimeDateFormatString]];
    NSTimeInterval timeRange = [lastDate timeIntervalSinceDate:firstDate];
    if (timeRange<60*60*12) {
        NSMutableString *timeFormatString = [defaults objectForKey:NSTimeFormatString];

        firstDateString = [firstDate descriptionWithCalendarFormat:timeFormatString];
        lastDateString  = [lastDate  descriptionWithCalendarFormat:timeFormatString];
    }

    
    [[[NSColor redColor] colorWithAlphaComponent:0.2] set];
//    [NSBezierPath fillRect:bounds];
//    NSFrameRect(bounds);
    [[NSColor whiteColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMinY(bounds)+LEGENDHEIGHT)
                  toPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds)+LEGENDHEIGHT)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMaxY(bounds))
                  toPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];
    
    
    NSBezierPath *deletionsPath   = [NSBezierPath bezierPath];
    NSBezierPath *insertionsPath  = [NSBezierPath bezierPath];
    NSBezierPath *selectionsPath  = [NSBezierPath bezierPath];
    
    NSBezierPath *paths[]={deletionsPath,insertionsPath,selectionsPath};
	float unitOfOnePixel = ([self convertPoint:NSMakePoint(1.0,1.0) fromView:nil].x) - ([self convertPoint:NSMakePoint(0.0,1.0) fromView:nil].x);
    float values[]={0.,0.,0.};
    double maxValue = relativeMode ? 0.1 : 1.0;
    NSPoint lastPoints[] = {NSMakePoint(-1.,-1.),NSMakePoint(-1.,-1.),NSMakePoint(-1.,-1.)};
    double valueThreshold = unitOfOnePixel/(NSWidth(bounds)*2.);
    int count = [dataPoints count];
    int step = 1.;//MAX(1,(int)(count/(NSWidth(bounds)*20.)));
	BOOL didMove=NO;
	float lastX=-1.;
    for (i=0;i<count;i+=step) {
        NSDictionary *entryDict = [dataPoints objectAtIndex:i];
        if (i+step>count) {
            entryDict = [dataPoints lastObject];
        }
        NSTimeInterval interval = [[entryDict objectForKey:@"date"] timeIntervalSinceDate:firstDate];
        NSPoint point = NSMakePoint((interval/timeRange),0.);
		if (interval<0.) {
			if (i+1<count && [[[dataPoints objectAtIndex:i+1] objectForKey:@"date"] timeIntervalSinceDate:firstDate]>=0.) {
				point.x=0.;
			} else {
				continue;
			}
		}
        TCMMMLogStatisticsDataPoint *dataPoint = [entryDict objectForKey:userID];
        TCMMMLogStatisticsDataPoint *overallPoint = [entryDict objectForKey:@"document"];
        if (relativeMode) {
            values[0]=[dataPoint deletedCharacters] /(float)MAX(1.,[overallPoint deletedCharacters]) ;
            values[1]=[dataPoint insertedCharacters]/(float)MAX(1.,[overallPoint insertedCharacters]);
            values[2]=[dataPoint selectedCharacters]/(float)MAX(1.,[overallPoint selectedCharacters]);
        } else {
            values[0]=[dataPoint deletedCharacters] ;
            values[1]=[dataPoint insertedCharacters];
            values[2]=[dataPoint selectedCharacters];
        }
        int j=0;
        for (j=0;j<3;j++) {
            point.y=values[j];
            maxValue = MAX(point.y,maxValue);
            if (point.y == lastPoints[j].y && 
                point.x-lastPoints[j].x <= valueThreshold && 
                i+1 != count && didMove) {
                continue;
            }
            if (!didMove) {
                [paths[j] moveToPoint:point];
            } else {
                [paths[j] lineToPoint:point];
            }
            lastPoints[j]=point;
            lastX = point.x;
        }
		didMove = YES;
    }
    
    
    NSString *maxDataString = [NSString stringByAddingThousandSeparatorsToNumber:[NSNumber numberWithFloat:maxValue]];
    if (relativeMode) maxDataString = [NSString stringWithFormat:@"%.0f %%",maxValue*100];
    NSSize dataSize = [maxDataString sizeWithAttributes:mLabelAttributes];

    float leftMargin = ceil(MAX(YMARKERSPACE,dataSize.width+6.));
	float rightMargin = 4.;

    NSRect graphRect = NSOffsetRect(bounds,leftMargin,XMARKERSPACE+LEGENDHEIGHT);
    graphRect.size.width -= leftMargin+rightMargin;
    graphRect.size.height -= XMARKERSPACE+LEGENDHEIGHT+YTOPPADDING;
    graphRect = [self convertRect:NSOffsetRect(NSIntegralRect([self convertRect:graphRect toView:nil]),0.5,0.5) fromView:nil];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(graphRect),NSMinY(graphRect))
                  toPoint:NSMakePoint(NSMaxX(graphRect),NSMinY(graphRect))];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(graphRect),NSMinY(graphRect))
                  toPoint:NSMakePoint(NSMinX(graphRect),NSMaxY(graphRect))];
    [[NSColor colorWithCalibratedRed:69./255. green:80./255. blue:81./255. alpha:0.4] set];
    [NSBezierPath fillRect:graphRect];

    NSAffineTransform *at = [NSAffineTransform transform];
    [at translateXBy:graphRect.origin.x yBy:graphRect.origin.y+1.];
    [at scaleXBy:NSWidth(graphRect) yBy:(NSHeight(graphRect)-2.)/maxValue];
    
    i=3;
    while (i--) {
        [colors[i] set];
        [paths[i] transformUsingAffineTransform:at];
        [paths[i] setLineWidth:1.5];
        [paths[i] stroke];
    }
    if (entry) {
        NSSize dateSize = [firstDateString sizeWithAttributes:mLabelAttributes];
		[firstDateString drawAtPoint:NSMakePoint(NSMinX(graphRect),NSMinY(graphRect)-dateSize.height) withAttributes:mLabelAttributes];
		dateSize = [firstDateString sizeWithAttributes:mLabelAttributes];
		[lastDateString drawAtPoint:NSMakePoint(NSMaxX(graphRect)-dateSize.width,NSMinY(graphRect)-dateSize.height) withAttributes:mLabelAttributes];
		[maxDataString  drawAtPoint:NSMakePoint(NSMinX(graphRect)-dataSize.width-2.,NSMaxY(graphRect)-dataSize.height+2.) withAttributes:mLabelAttributes];
	}
	NSString *modeString = NSLocalizedString(@"All",@"string for display of all data in statistic window");
	if (timeInterval > 0.) {
	   if (timeInterval < 60.*60.) {
	       modeString = [NSString stringWithFormat:@"%.0fm",round(timeInterval / 60.)];
	   } else if (timeInterval < 60. * 60. * 24.){
	       modeString = [NSString stringWithFormat:@"%.0fh",round(timeInterval / (60.*60.))];
	   } else if (timeInterval < 60. * 60. * 24. * 7.){
	       modeString = [NSString stringWithFormat:@"%.0fd",round(timeInterval / (60.*60.*24.))];
	   } else {
	       modeString = [NSString stringWithFormat:@"%.0fw",round(timeInterval / (60.*60.*24.*7.))];
	   }
	}
    NSSize modeSize = [modeString sizeWithAttributes:mLabelAttributes];
    [modeString drawAtPoint:NSMakePoint(NSMinX(graphRect)+ (NSWidth(graphRect) - modeSize.width)/2.,NSMinY(graphRect)-modeSize.height) withAttributes:mLabelAttributes];
	
}

- (void)toggleInterval {
	if (timeInterval <= 0.) {
		timeInterval = 60.*10.;
	} else if (timeInterval <= 60.*10.) {
		timeInterval = 60.*60.;
	} else if (timeInterval <= 60.*60.) {
		timeInterval = 60.*60.*12;
	} else if (timeInterval <= 60.*60.*12) {
		timeInterval = 60.*60.*24*7;
	} else {
		timeInterval = 0.;
	}
	[self setNeedsDisplay:YES];
}


- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject {
	NSLog(@"%s selector:%@ object:%@",__FUNCTION__,NSStringFromSelector(anAction),anObject);
	return [super tryToPerform:anAction with:anObject];
}

- (void)mouseUp:(NSEvent *)anEvent {
	NSPoint point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	if (NSPointInRect(point,NSOffsetRect(NSInsetRect([self bounds],0,LEGENDHEIGHT/2.),0,LEGENDHEIGHT/2.))) {
		[self toggleInterval];
	}
}

@end
