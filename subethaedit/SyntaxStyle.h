//
//  SyntaxStyle.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"

@interface SyntaxStyle : NSObject {
    NSMutableDictionary *I_styleDictionary;
    DocumentMode *I_documentMode;
    NSMutableArray *I_keyArray;
}

- (NSArray *)allKeys;
- (void)addKey:(NSString *)aKey;
- (NSMutableDictionary *)styleForKey:(NSString *)aKey;
- (void)setStyle:(NSDictionary *)aDictionary forKey:(NSString *)aKey;
- (NSString *)localizedStringForKey:(NSString *)aKey;
- (void)setDocumentMode:(DocumentMode *)aMode;
- (DocumentMode *)documentMode;

@end
