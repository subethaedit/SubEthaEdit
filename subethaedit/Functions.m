//
//  Functions.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "Functions.h"

BOOL DisjointRanges(NSRange range1, NSRange range2) {
    if (range1.location < NSMaxRange(range2)
        && NSMaxRange(range1) > range2.location) {
        return NO;
    } else {
        return YES;
    }
}

BOOL TouchingRanges(NSRange range1, NSRange range2) {
    if (range1.location <= NSMaxRange(range2)
        && NSMaxRange(range1) >= range2.location) {
        return YES;
    } else {
        return NO;
    }
}

NSString *extractStringWithEntitiesFromTree(CFXMLTreeRef aTree) {
    static NSDictionary *sEntities;
    if (!sEntities) sEntities=[[NSDictionary dictionaryWithObjectsAndKeys:@"<",@"lt",@">",@"gt",@"\"",@"quot",@"'",@"apos",@"&",@"amp",nil] retain];
    NSMutableString *result=[NSMutableString string];
    int childCount=CFTreeGetChildCount(aTree);
    int i;
    for (i=0;i<childCount;i++) {
        CFXMLTreeRef tree;
        CFXMLNodeRef node;
        tree=CFTreeGetChildAtIndex(aTree,i);
        node=CFXMLTreeGetNode(tree);
        int typeCode=CFXMLNodeGetTypeCode(node);
        if ((typeCode == kCFXMLNodeTypeText)||(typeCode == kCFXMLNodeTypeWhitespace)) {
            [result appendString:(NSString*)CFXMLNodeGetString(node)];
        } else if (typeCode == kCFXMLNodeTypeEntityReference) {
            NSString *string=[sEntities objectForKey:(NSString*)CFXMLNodeGetString(node)];
            if (string) [result appendString:string];
        }
    }
    return result;
}

