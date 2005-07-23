//
//  AppController.m
//  CreateStringByUnicharTest
//
//  Created by Dominik Wagner on 21.07.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "sys/time.h"

#define REPORT(format, args...) \
do { \
    [[[S_textView textStorage] mutableString] appendFormat:format, ##args]; \
} while (0)

NSTimeInterval inline TimeIntervalSince1970() {
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec + tv.tv_usec / (NSTimeInterval)1000000.;
}

int loopCount;

static NSTextView *S_textView = nil;

unichar testChar = 0x21cb;
unichar testCharArray[] = {0x21cb,0xfffd,0x2192,0x2192,0x204b,0x2014,0x00b6,0x2761,0x21ab,0x2038};


NSString *prettyStringForTimeInterval(NSTimeInterval aTimeInterval) {
    return [NSString stringWithFormat:@"%2.6fs",aTimeInterval];
}

@implementation AppController

- (void)applicationDidFinishLaunching:(id)aIgnore {
    S_textView = O_outputTextView;
    [self testIt:self];
}

- (IBAction)testIt:(id)aSender {
    loopCount = [O_numberOfStringsTextField intValue];
    int loop=0;
    NSTimeInterval start_time = 0;

    REPORT(@"================================================\n");


    REPORT(@"Alloc/initWithCharactersNoCopy: length: freeWhenDone:\n");
    start_time = TimeIntervalSince1970();

    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        NSString *string=[[NSString alloc] initWithCharactersNoCopy:&testChar length:1 freeWhenDone:NO];
        [string release];
    }
    REPORT(@"Time taken: %@\n\n",prettyStringForTimeInterval(TimeIntervalSince1970()-start_time));

    REPORT(@"NSMutableString appendWithFormat:\n");
    start_time = TimeIntervalSince1970();

    NSMutableString *mutableString = [NSMutableString new];
    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        [mutableString setString:@""];
        [mutableString appendFormat:@"%C",testChar];
    }
    [mutableString release];
    REPORT(@"Time taken: %@\n\n",prettyStringForTimeInterval(TimeIntervalSince1970()-start_time));

    REPORT(@"alloc/initWithFormat:\n");
    start_time = TimeIntervalSince1970();

    for (loop=0;loop<loopCount;loop++) {
        testChar = testCharArray[loop % 10];
        NSString *string=[[NSString alloc] initWithFormat:@"%C",testChar];
        [string release];
    }
    REPORT(@"Time taken: %@\n\n",prettyStringForTimeInterval(TimeIntervalSince1970()-start_time));

    REPORT(@"================================================\n");

    [O_testView testIt:aSender];
}

@end

@implementation TestView

- (id)initWithFrame:(NSRect)aFrame {
    if ((self=[super initWithFrame:aFrame])) {
        I_shouldDraw = NO;
        I_attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [NSColor grayColor],NSForegroundColorAttributeName,
            [NSFont fontWithName:@"Monaco" size:12.],NSFontAttributeName,
            nil];
        I_textStorage =   [NSTextStorage new];
        I_layoutManager = [NSLayoutManager new];
        I_textContainer = [NSTextContainer new];
        [I_layoutManager addTextContainer:I_textContainer];
        [I_textContainer release];	// The layoutManager will retain the textContainer
        [I_textStorage addLayoutManager:I_layoutManager];
        [I_layoutManager release];	// The textStorage will retain the layoutManager
    
        // Screen fonts are not suitable for scaled or rotated drawing.
        // Views that use NSLayoutManager directly for text drawing should
        // set this parameter appropriately.
        [I_layoutManager setUsesScreenFonts:NO]; 
        NSMutableString *string = [I_textStorage mutableString];
        int i=0;
        for (i=0;i<10;i++) {
            [string appendFormat:@"%C",testCharArray[i]];
        }
        [I_textStorage addAttributes:I_attributes range:NSMakeRange(0,[string length])];
    }
    return self;
}

- (IBAction)testIt:(id)aSender {
    I_shouldDraw = YES;
    [self display];
    I_shouldDraw = NO;
}

- (void)drawRect:(NSRect)aRect {
    [[NSColor whiteColor] set];
    NSRectFill(aRect);
    int myLoopCount=I_shouldDraw?loopCount:1;
    int loop=0;
    int innerLoop=0;
    NSTimeInterval start_time = 0;

    [[NSColor grayColor] set];


    REPORT(@"================================================\n");
    REPORT(@"Alloc/initWithCharactersNoCopy: length: freeWhenDone:\n");
    REPORT(@"drawAtPoint: withAttributes:\n");
    start_time = TimeIntervalSince1970();
    
    NSRectFill(NSMakeRect(10.,20.,100.,1.));
    for (loop=0;loop<myLoopCount;loop++) {
        NSPoint startPoint=NSMakePoint(10.,20.);
        for (innerLoop = 0; innerLoop <10; innerLoop++) {
            testChar = testCharArray[innerLoop % 10];
            NSString *string=[[NSString alloc] initWithCharactersNoCopy:&testChar length:1 freeWhenDone:NO];
            NSSize glyphSize=[string sizeWithAttributes:I_attributes];
            [string drawAtPoint:startPoint withAttributes:I_attributes];
            startPoint.x+=glyphSize.width;
            [string release];
        }
    }
    NSTimeInterval drawAtPointTime=TimeIntervalSince1970()-start_time;
    REPORT(@"Time taken: %@\n\n",prettyStringForTimeInterval(drawAtPointTime));


    REPORT(@"================================================\n");
    REPORT(@"Draw by TextStorage and LayoutManager:\n");
    start_time = TimeIntervalSince1970();

    unsigned glyphIndex;
    NSRange glyphRange;
    NSRect usedRect;

    glyphRange = [I_layoutManager glyphRangeForTextContainer:I_textContainer];

    NSRectFill(NSMakeRect(10.,60.,100.,1.));
    for (loop=0;loop<myLoopCount;loop++) {
        float factor=((loop/(float)myLoopCount)+.5);
        NSPoint startPoint=NSMakePoint(10.,60.);
        for (glyphIndex = glyphRange.location; glyphIndex < NSMaxRange(glyphRange); glyphIndex++) {
            NSPoint layoutLocation = [I_layoutManager locationForGlyphAtIndex:0];
            NSRect lineFragmentRect = [I_layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];

            layoutLocation.x += lineFragmentRect.origin.x;
            layoutLocation.y += lineFragmentRect.origin.y;

            [I_layoutManager drawGlyphsForGlyphRange:NSMakeRange(glyphIndex, 1) atPoint:NSMakePoint(startPoint.x-layoutLocation.x,startPoint.y)];
        }
    }
    REPORT(@"GlyphRange: %@",NSStringFromRange(glyphRange));
    NSTimeInterval drawWithLayoutManagerTime=TimeIntervalSince1970()-start_time;
    REPORT(@"Time taken: %@\n\n",prettyStringForTimeInterval(drawWithLayoutManagerTime));
    REPORT(@"\nHow much better performs the layoutmanager? %2.5f times\n\n",drawAtPointTime / drawWithLayoutManagerTime);
    
}

- (BOOL)isFlipped {
    return YES;
}

@end

