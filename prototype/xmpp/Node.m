//
//  Node.m
//  xmpp
//
//  Created by Martin Ott on Wed Nov 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "Node.h"


@implementation Node

- (id)init
{
    self = [super init];
    if (self) {
        I_children = [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [I_name release];
    [I_namespaceURI release];
    [I_attributes release];
    [I_children release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nname: %@\nnamespaceURI: %@\nattributes: %@\nchildren: %@", I_name, I_namespaceURI, [I_attributes descriptionInStringsFileFormat], I_children];
}

- (void)setName:(NSString *)name
{
    [I_name autorelease];
    I_name = [name copy];
}

- (NSString *)name
{
    return I_name;
}

- (void)setNamespaceURI:(NSString *)namespaceURI
{
    [I_namespaceURI autorelease];
    I_namespaceURI = [namespaceURI copy];
}

- (NSString *)namespaceURI
{
    return I_namespaceURI;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    [I_attributes autorelease];
    I_attributes = [attributes copy];
}

- (NSDictionary *)attributes
{
    return I_attributes;
}

- (void)setParent:(Node *)parent
{
    I_parent = parent;
}

- (Node *)parent
{
    return I_parent;
}

- (void)addChild:(Node *)child
{
    [I_children addObject:child];
}

@end
