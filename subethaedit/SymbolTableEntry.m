//
//  SymbolTableEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SymbolTableEntry.h"


@implementation SymbolTableEntry
- (void)setIsSeparator:(BOOL)aFlag {
    I_isSeparator=aFlag;  
}

+ (SymbolTableEntry *)symbolTableEntryWithName:(NSString *)aName fontTraitMask:(int)aMask image:(NSImage *)anImage type:(NSString *)aType jumpRange:(NSRange)aJumpRange range:(NSRange)aRange {
    SymbolTableEntry *result=[[SymbolTableEntry new] autorelease];
    [result setName:aName];
    [result setFontTraitMask:aMask];
    [result setImage:anImage];
    [result setType:aType];
    [result setJumpRange:aJumpRange];
    [result setRange:aRange];
    [result setIsSeparator:NO];
    return result;
}

+ (SymbolTableEntry *)symbolTableEntrySeparator {
    SymbolTableEntry *result=[[SymbolTableEntry new] autorelease];
    [result setIsSeparator:YES];
    return result;
}

- (void)dealloc {
    [I_name release];
    [I_image release];
    [I_type release];
    [super dealloc];
}

- (NSString *)name {
    return I_name;
}
- (void)setName:(NSString *)aName {
    [I_name autorelease];
    I_name = [aName copy];
}
- (int)fontTraitMask {
    return I_fontTraitMask;
}
- (void)setFontTraitMask:(int)aMask {
    I_fontTraitMask = aMask;
}
- (NSImage *)image {
    return I_image;
}
- (void)setImage:(NSImage *)anImage {
    [I_image autorelease];
    I_image = [anImage retain];
}

- (NSString *)type {
    return I_type;
}
- (void)setType:(NSString *)aType {
    [I_type autorelease];
    I_type = [aType copy];
}
- (NSRange)jumpRange {
    return I_jumpRange;
}
- (void)setJumpRange:(NSRange)aJumpRange {
    I_jumpRange=aJumpRange;
}
- (NSRange)range {
    return I_range;
}
- (void)setRange:(NSRange)aRange {
    I_range=aRange;
}

- (BOOL)isSeparator {
    return I_isSeparator;
}

@end
