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

@interface RegexSymbolDefinition : NSObject <NSXMLParserDelegate>

@property (atomic, readonly, strong) DocumentMode *mode;
@property (atomic, readonly, strong) OGRegularExpression *block;
@property (atomic, readonly, copy) NSArray *symbols;
@property (atomic, readonly, strong) NSError *xmlStructureError;

- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

@end
