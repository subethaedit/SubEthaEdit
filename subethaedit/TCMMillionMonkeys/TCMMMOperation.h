//
//  TCMMMOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const TCMMMOperationTypeKey;


@interface TCMMMOperation : NSObject {

}

+ (void)registerClass:(Class)aClass forOperationType:(NSString *)aType;

+ (id)operationWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
