/*
HMFoundationEx.h

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

#import <Foundation/Foundation.h>

static inline NSRect HMCenterSize(NSSize aSize, NSRect aRect)
{
	NSRect theRect;
	theRect.size = aSize;
	theRect.origin.x = NSMidX(aRect) - (aSize.width / 2.0);
	theRect.origin.y = NSMidY(aRect) - (aSize.height / 2.0);
	
	return theRect;
}

static inline float HMFlipY(float y, NSRect aRect)
{
	return aRect.origin.y + (NSMaxY(aRect) - y);
}

static inline NSRect HMFlipRect(NSRect aRect, NSRect bRect)
{
	NSRect theRect;
	theRect = aRect;
	theRect.origin.y = HMFlipY(NSMaxY(aRect), bRect);
	
	return theRect;
}

static inline NSRect HMMakeRect(NSPoint p, NSSize s)
{
	return NSMakeRect(p.x, p.y, s.width, s.height);
}

#pragma mark -

@interface NSAffineTransform (Extension)
+ (NSAffineTransform*)verticalFlipTransformForRect:(NSRect)rect;
- (NSRect)transformRect:(NSRect)aRect;
@end

#pragma mark -

@interface NSCharacterSet (NewLine)
+ (NSCharacterSet*)newLineCharacterSet;
@end

#pragma mark -

@interface NSDate (DateFormat)
+ (NSArray*)dateFormats;
+ (void)addDateFromatsWithContentsOfFile:(NSString*)filePath;
+ (void)addDateFormats:(NSArray*)formats;
+ (void)removeDateFormats:(NSArray*)formats;

+ (id)dateWithFormattedString:(NSString*)string;
+ (NSString*)formatForFormattedString:(NSString*)string;
@end

#pragma mark -

@interface NSFileManager (UniqueFilePath)
- (NSString*)makeUniqueFilePath:(NSString*)filePath;
@end

#pragma mark -

@interface NSString (CharacterReference)
- (NSString*)stringByReplacingCharacterReferences;
@end

#pragma mark -

@interface NSURLDownload (FileDelete)
- (void)_setDeletesFileAfterFailure:(BOOL)flag;
- (BOOL)_deletesFileAfterFailure;
@end

#pragma mark -

@interface NSXMLNode (Extension)
- (NSXMLNode*)singleNodeForXPath:(NSString*)XPath;
- (NSString*)stringValueForXPath:(NSString*)XPath;
@end
