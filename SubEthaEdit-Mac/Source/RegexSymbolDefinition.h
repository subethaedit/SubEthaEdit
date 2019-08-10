//  RegexSymbolDefinition.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Thu Apr 22 2004.
//  Updated by Michael Ehrmann on Fri Oct 11 2013.

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import "DocumentMode.h"

@interface RegexSymbolDefinition : NSObject <NSXMLParserDelegate>

@property (atomic, readonly, strong) DocumentMode *mode;
@property (atomic, readonly, strong) OGRegularExpression *block;
@property (atomic, readonly, copy) NSArray *symbols;
@property (atomic, readonly, strong) NSError *xmlStructureError;

- (instancetype)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

@end
