//
//  Node.h
//  xmpp
//
//  Created by Martin Ott on Wed Nov 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Node : NSObject {

    NSString *I_name;
    NSString *I_namespaceURI;
    NSDictionary *I_attributes;
    NSMutableString *I_characters;
    Node *I_parent;
    NSMutableArray *I_children;
}

- (void)setName:(NSString *)name;
- (NSString *)name;
- (void)setNamespaceURI:(NSString *)namespaceURI;
- (NSString *)namespaceURI;
- (void)setAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributes;
- (void)appendString:(NSString *)string;
- (void)setParent:(Node *)parent;
- (Node *)parent;
- (void)addChild:(Node *)child;
- (NSString *)characters;
- (NSArray *)children;

@end
