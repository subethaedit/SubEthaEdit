//
//  RegexSymbolDefinition.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Thu Apr 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import "DocumentMode.h"

@interface RegexSymbolDefinition : NSObject {
    OGRegularExpression *I_block;
    DocumentMode *I_mode;
    NSMutableDictionary *I_currentSymbol;
    NSMutableArray *I_currentPostprocess;
    NSMutableArray *I_symbols;
}

/*"Initizialisation"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (void)parseBlocks:(CFXMLTreeRef)aTree;
- (void)parseSymbol:(CFXMLTreeRef)aTree;
- (void)parsePostprocess:(CFXMLTreeRef)aTree;

/*"Accessors"*/
- (OGRegularExpression *)block;
- (NSArray *)symbols;
- (DocumentMode *)mode;
- (void)setMode:(DocumentMode *)aMode;

@end
