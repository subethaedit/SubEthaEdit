/*
HMFoundationEx.m

Author: Makoto Kinoshita

Copyright 2004-2006 The Shiira Project. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted 
provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE SHIIRA PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE SHIIRA PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

#import "HMFoundationEx.h"

@implementation NSAffineTransform (Extension)

+ (NSAffineTransform*)verticalFlipTransformForRect:(NSRect)rect
{
	NSAffineTransform *transform;
	transform = [NSAffineTransform transform];
	[transform translateXBy:0 yBy:NSMaxY(rect)];
	[transform scaleXBy:1.0 yBy:-1.0];
	
	return transform;
}

- (NSRect)transformRect:(NSRect)aRect
{
	NSRect theRect;
	theRect.origin = [self transformPoint:aRect.origin];
	theRect.size = [self transformSize:aRect.size];
	
	return theRect;
}
@end

#pragma mark -

@implementation NSCharacterSet (NewLine)

+ (NSCharacterSet*)newLineCharacterSet
{
    static NSCharacterSet*  _newlineCharacterSet = nil;
    if (!_newlineCharacterSet) {
        unichar     newlineChars[] = {0x000A, 0x000D, 0x0085};
        NSString*   newlineString;
        newlineString = [NSString stringWithCharacters:newlineChars 
                length:sizeof(newlineChars) / sizeof(unichar)];
        _newlineCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:newlineString] retain];
    }
    
    return _newlineCharacterSet;
}

@end

#pragma mark -

@implementation NSDate (DateFormat)

static  NSMutableArray* _formats = nil;

+ (void)load
{
    NSAutoreleasePool*  pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    if (!_formats) {
        _formats = [[NSMutableArray array] retain];
        
        // Add default formats
        [_formats addObject:@"%Y-%m-%dT%H:%M:%S%z"];
        [_formats addObject:@"%a, %d %b %Y %H:%M:%S %z"];
    }
    
    [pool release];
}

+ (NSArray*)dateFormats
{
    return [NSArray arrayWithArray:_formats];
}

+ (void)addDateFromatsWithContentsOfFile:(NSString*)filePath
{
    // Load file
    NSArray*    formats;
    formats = [NSArray arrayWithContentsOfFile:filePath];
    if (!formats) {
        // Warning
        NSLog(@"Can't load %@", filePath);
        return;
    }
    
    // Add formats
    [NSDate addDateFormats:formats];
}

+ (void)addDateFormats:(NSArray*)formats
{
    NSEnumerator*   enumerator;
    NSString*       format;
    enumerator = [formats objectEnumerator];
    while (format = [enumerator nextObject]) {
        if (![_formats containsObject:format]) {
            NSString*   copiedFormat;
            copiedFormat = [format copy];
            [_formats addObject:copiedFormat];
            [copiedFormat release];
        }
    }
}

+ (void)removeDateFormats:(NSArray*)formats
{
    [_formats removeObjectsInArray:formats];
}

+ (id)dateWithFormattedString:(NSString*)string
{
    if (!string) {
        return nil;
    }
    
    // Remove ':' between HH and MM of time zone
    int length;
    length = [string length];
    if (length > 6) {
        unichar colon, sign;
        colon = [string characterAtIndex:length - 3];
        sign = [string characterAtIndex:length - 6];
        if (colon == ':' && (sign == '-' || sign == '+')) {
            string = [NSString stringWithFormat:@"%@%@", 
                    [string substringToIndex:length - 3], 
                    [string substringFromIndex:length - 2]];
        }
    }
    
    // Apply format
    NSEnumerator*   enumerator;
    NSString*       format;
    enumerator = [_formats objectEnumerator];
    while (format = [enumerator nextObject]) {
        NSCalendarDate* date;
        date = [NSCalendarDate dateWithString:string calendarFormat:format];
        if (date) {
            return date;
        }
    }
    
    // No proper format
    return nil;
}

+ (NSString*)formatForFormattedString:(NSString*)string
{
    // Apply format
    NSEnumerator*   enumerator;
    NSString*       format;
    enumerator = [_formats objectEnumerator];
    while (format = [enumerator nextObject]) {
        NSCalendarDate* date;
        date = [NSCalendarDate dateWithString:string calendarFormat:format];
        if (date) {
            return format;
        }
    }
    
    // No proper format
    return nil;
}

@end

#pragma mark -

@implementation NSFileManager (UniqueFilePath)

static int  _maxRepeatTime = 999;

- (NSString*)makeUniqueFilePath:(NSString*)filePath
{
    if (![self fileExistsAtPath:filePath]) {
        return filePath;
    }
    
    // Get file name and extension separately
    NSRange     range;
    NSString*   fileName;
    NSString*   extension;
    range = [filePath rangeOfString:@"."];  // Find first '.'
    if (range.location != NSNotFound) {
        fileName = [filePath substringToIndex:range.location];
        extension = [filePath substringFromIndex:range.location + 1];
    }
    else {
        fileName = filePath;
        extension = nil;
    }
    
    // Make new file path
    int i;
    for (i = 1; i < _maxRepeatTime; i++) {
        NSString*   newFilePath;
        if (extension) {
            newFilePath = [NSString stringWithFormat:@"%@-%d.%@", fileName, i, extension];
        }
        else {
            newFilePath = [NSString stringWithFormat:@"%@-%d", fileName, i];
        }
        
        if (![self fileExistsAtPath:newFilePath]) {
            return newFilePath;
        }
    }
    
    return nil;
}

@end

#pragma mark -

@implementation NSString (CharacterReference)

- (NSString*)stringByReplacingCharacterReferences
{
    NSMutableString*    scanedString;
    scanedString = [NSMutableString string];
    
    NSScanner*  scanner;
    scanner = [NSScanner scannerWithString:self];
    
    // Scan '&#'
    while (![scanner isAtEnd]) {
        NSString*   string;
        if ([scanner scanUpToString:@"&#" intoString:&string]) {
            [scanedString appendString:string];
        }
        
        if ([scanner scanString:@"&#" intoString:NULL]) {
            NSString*   digit;
            if  ([scanner scanUpToString:@";" intoString:&digit] && 
                 [scanner scanString:@";" intoString:NULL])
            {
                [scanedString appendFormat:@"%C", (unichar)[digit intValue]];
            }
        }
    }
    
    return scanedString;
}

@end

#pragma mark -

@implementation NSXMLNode (Extension)

- (NSXMLNode*)singleNodeForXPath:(NSString*)XPath
{
    NSArray*    nodes;
    nodes = [self nodesForXPath:XPath error:NULL];
    if (!nodes || [nodes count] != 1) {
        return nil;
    }
    return [nodes objectAtIndex:0];
}

- (NSString*)stringValueForXPath:(NSString*)XPath
{
    NSXMLNode*  node;
    node = [self singleNodeForXPath:XPath];
    if (!node) {
        return nil;
    }
    
    //return [node stringValue];
    return [[node stringValue] stringByReplacingCharacterReferences];
}

@end
