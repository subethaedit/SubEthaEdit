//
//  SyntaxHighlighter.m
//  HTMLEditorX
//
//  Created by Dominik Wagner on Tue Jan 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#define chunkSize              		5000

#import "DOMSyntaxHighlighter.h"
#import "time.h"

@implementation DOMSyntaxHighlighter

-(id)initWithFile:(NSString *)aFile {
    self=[super init];
    if (self) {
        I_keyWords=[NSMutableDictionary new];
        I_keyWordCharacterSet=[NSMutableCharacterSet new];
        NSDictionary *dictionary=[NSDictionary dictionaryWithContentsOfFile:aFile];
        //NSLog(@"blah: %@",[dictionary description]);
        NSString *validCharacters=[[dictionary objectForKey:@"Header"] objectForKey:@"Valid Characters for Variables"];
        if (validCharacters) {
            [I_keyWordCharacterSet addCharactersInString:validCharacters];
        }
        NSArray *styles=[dictionary objectForKey:@"Styles"];
        int i;
        for (i=0;i<[styles count];i++) {
            if ([[styles objectAtIndex:i] objectForKey:@"Plain Strings"]) {
                NSArray *storedColor=[[styles objectAtIndex:i] objectForKey:@"Color"];
                if (storedColor) {
                    NSColor *color=[NSColor colorWithCalibratedRed:[[storedColor objectAtIndex:0]floatValue]
                          green:[[storedColor objectAtIndex:1]floatValue]
                          blue:[[storedColor objectAtIndex:2]floatValue] alpha:1.0];
                    NSEnumerator *strings=[[[styles objectAtIndex:i] objectForKey:@"Plain Strings"] objectEnumerator];
                    NSString *string;
                    while ((string=[strings nextObject])) {
                        //[I_keyWordCharacterSet addCharactersInString:string];
                        [I_keyWords setObject:color forKey:string];
                    }
                }
            }
        }
        //NSLog(@"%@,%@",[I_keyWordCharacterSet description],[I_keyWords description]);
    }
    return self;
}

-(void)colorize:(NSMutableAttributedString *)aString inRange:(NSRange)aLineRange {
    NSScanner *scanner=[NSScanner scannerWithString:[aString string]];
    [scanner setCharactersToBeSkipped:[I_keyWordCharacterSet invertedSet]];
    [scanner setScanLocation:aLineRange.location];
    NSString *foundString=nil;
    NSRange lastFoundRange=NSMakeRange(aLineRange.location,0);
    NSRange ignoreRange;
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSFont *font=[aString attribute:NSFontAttributeName atIndex:aLineRange.location effectiveRange:&ignoreRange];
    NSFont *boldFont=[fontManager convertFont:font toHaveTrait:NSBoldFontMask];
    do {
        if ([scanner scanCharactersFromSet:I_keyWordCharacterSet intoString:&foundString]) {
            //NSLog(@"FoundString: %@ at location:%d",foundString,[scanner scanLocation]);
            if (foundString) {
                NSRange foundRange=NSMakeRange([scanner scanLocation]-[foundString length],[foundString length]);
                if (foundRange.location<aLineRange.location) {
                    NSLog(@"wtf?");
                } else if (NSMaxRange(foundRange)>NSMaxRange(aLineRange)) {
                    // NSLog(@"range to long: %@, %@",NSStringFromRange(foundRange),NSStringFromRange(aLineRange));
                    break;
                } else {
                    NSColor *color=[I_keyWords objectForKey:foundString];
                    if (color) {    
                        [aString addAttribute:NSForegroundColorAttributeName value:color range:foundRange];
                        if (boldFont) {
                            [aString addAttribute:NSFontAttributeName value:boldFont range:foundRange];
                        } 
                    } else {
                        [aString removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(NSMaxRange(lastFoundRange),NSMaxRange(aLineRange)-NSMaxRange(lastFoundRange))];
                    }
                }
                lastFoundRange=foundRange;
            }
        } else {
            break;
        }
    } while ([scanner scanLocation]< NSMaxRange(aLineRange));
    //NSLog(@"tried my best");
}

-(BOOL)colorizeDirtyRanges:(NSMutableAttributedString*)aString {
    NSRange textRange=NSMakeRange(0,[aString length]);
    NSRange changedRange;
    id dirty;
    unsigned int position;
    double return_after = 0.2;
    BOOL returnvalue = NO;
    int chunks=0;
    
    clock_t start_time = clock();
    
    [aString beginEditing];
    
    position=0;
    while (position<NSMaxRange(textRange)) {
        dirty=[aString attribute:kSyntaxColoringIsDirtyAttribute atIndex:position
                longestEffectiveRange:&changedRange inRange:textRange];
        if (dirty) {
            NSRange chunkRange,lineRange;
            // NSLog(@"changedRange: %@",NSStringFromRange(changedRange));
            while(YES) {
                chunks++;
                chunkRange=changedRange;
                if (chunkRange.length>chunkSize) chunkRange.length=chunkSize;
                // NSLog(@"handling Chunk: %@",NSStringFromRange(chunkRange));

                lineRange=[[aString string] lineRangeForRange:chunkRange];
                
                // [aString addAttribute:NSBackgroundColorAttributeName value:[[NSColor redColor] highlightWithLevel:0.3]  range:lineRange]; // Debug
                
                [self colorize:aString inRange:lineRange];
//                [aString removeAttribute:kCommentAttribute range:lineRange];

//                [self doMultilines:aString inRange:lineRange];
                
                
                [aString removeAttribute:kSyntaxColoringIsDirtyAttribute range:lineRange];
                if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) break;
                
                // adjust ranges
                unsigned int lastChanged=NSMaxRange(changedRange);
                if (NSMaxRange(lineRange)<lastChanged) {
                    changedRange.location=NSMaxRange(lineRange);
                    changedRange.length=lastChanged-changedRange.location;
                } else {
                    break;
                }
            }
            position=NSMaxRange(lineRange);
        } else {
            position=NSMaxRange(changedRange);
            if (position>=[aString length]) {
                returnvalue = YES;
                break;
            }
        }
        if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) break;
        // adjust Range
        textRange.length=NSMaxRange(textRange);
        textRange.location=position;
        textRange.length  =textRange.length-position;
    }
    
    [aString endEditing];
//    if (LOGLEVEL(6)) 
    //NSLog(@"Time elapsed: %f, %d chunks",((double)(clock()-start_time))/CLOCKS_PER_SEC, chunks);
    return returnvalue;
}

- (NSArray*)symbolsInAttributedString:(NSAttributedString*)aString {
    return [NSArray array];
}
- (BOOL) hasSymbols {
    return NO;
}
- (void) cleanup:(NSMutableAttributedString*)aString {
    
}


@end
