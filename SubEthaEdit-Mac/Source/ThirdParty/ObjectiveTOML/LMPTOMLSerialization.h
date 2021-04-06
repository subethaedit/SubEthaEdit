//  LMPTOMLSerialization.h
//
//  Created by dom on 10/20/18.
//  Copyright © 2018 Lone Monkey Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const LMPTOMLErrorDomain;


@interface LMPTOMLSerialization : NSObject

/**
 Generate a Foundation Dictionary from TOML data.

 @param data NSData representing a TOML file
 @param error helpful information if the parsing fails
 @return NSDictionary representing the contents of the TOML file. Note that given dates will be represented as NSDateComponents, use +serializationObjectWtihTOMLObject: to convert those to RFC3339 strings that can be used in JSON or PropertyList serializations.
 */
+ (NSDictionary <NSString *, id>*)TOMLObjectWithData:(NSData *)data error:(NSError **)error;

/**
 Generates NSData representation of the TOMLObject. The representation is UTF8 and can be stored directly as a TOML file.
 
 Note that roundtripping is a lossy opreation, as all comments are stripped, the allowed number formats are reduced to canonical ones and doubles might lose or gain unwanted precision.
 
 @param tomlObject Foundation Object consisting of TOML serializable objects. In addition to plist objects this contains NSDateComponent objects with y-m-d filled, h-m-s-[nanoseconds] filled, all fields filled, or all fields + timezone filled.
 @param error helpful information if generation fails
 @return NSData representing the object.
 */
+ (NSData *)dataWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject error:(NSError **)error;

/**
 Takes a Dictionary representing a TOML file and translates the NSDateComponents into RFC339 strings to be able to be serialized in JSON or PropertyLists

 @param tomlObject foundation dictionary consisting of TOML serializable objects.
 @return NSDictionary containing property list serializable objects.
 */
+ (NSDictionary<NSString *, id> *)serializableObjectWithTOMLObject:(NSDictionary<NSString *, id> *)tomlObject;

@end
