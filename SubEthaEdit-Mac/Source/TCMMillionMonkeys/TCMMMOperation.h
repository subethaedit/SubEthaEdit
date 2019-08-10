//  TCMMMOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import <Foundation/Foundation.h>


extern NSString * const TCMMMOperationTypeKey;


@interface TCMMMOperation : NSObject <NSCopying> {
    NSString *I_userID;
}

+ (void)registerClass:(Class)aClass forOperationType:(NSString *)aType;

+ (id)operationWithDictionaryRepresentation:(NSDictionary *)aDictionary;
+ (NSString *)operationID;

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSString *)operationID;
- (void)setUserID:(NSString *)aUserID;
- (NSString *)userID;

@end
