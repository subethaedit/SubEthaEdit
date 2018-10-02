//  SyntaxStyle.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"

extern NSString * const SyntaxStyleBaseIdentifier;


@interface SyntaxStyle : NSObject {
    NSMutableDictionary *I_styleDictionary;
    DocumentMode *I_documentMode;
    NSMutableArray *I_keyArray;
}

+ (NSIndexSet *)indexesWhereStyle:(SyntaxStyle *)aStyle isNotEqualToStyle:(SyntaxStyle *)aStyle;
+ (BOOL)style:(NSDictionary *)aStyle isEqualToStyle:(NSDictionary *)anotherStyle;
//+ (NSArray *)syntaxStylesWithXMLFile:(NSString *)aPath;

- (id)initWithSyntaxStyle:(SyntaxStyle *)aStyle;

- (NSArray *)allKeys;
- (void)addKey:(NSString *)aKey;
- (NSMutableDictionary *)styleForKey:(NSString *)aKey;
- (NSMutableDictionary *)styleForScope:(NSString *)aScope;
- (void)setStyle:(NSDictionary *)aDictionary forKey:(NSString *)aKey;
- (void)takeStylesFromDefaultsDictionary:(NSDictionary *)aDictionary;
- (void)takeValuesFromDictionary:(NSDictionary *)aDictionary;
- (NSString *)localizedStringForKey:(NSString *)aKey;
- (void)setDocumentMode:(DocumentMode *)aMode;
- (DocumentMode *)documentMode;
- (NSDictionary *)defaultsDictionary;
- (NSString *)xmlRepresentation;
- (NSString *)xmlFileRepresentation;


@end
