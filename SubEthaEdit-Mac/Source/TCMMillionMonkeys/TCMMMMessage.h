//  TCMMMMessage.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import <Foundation/Foundation.h>

@class TCMMMOperation;

@interface TCMMMMessage : NSObject {
    NSInteger I_numberOfClientMessages;
    NSInteger I_numberOfServerMessages;
    TCMMMOperation *I_operation;
}

+ (instancetype)messageWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (instancetype)initWithOperation:(TCMMMOperation *)anOperation numberOfClient:(NSInteger)aClientNumber numberOfServer:(NSInteger)aServerNumber;

- (NSDictionary *)dictionaryRepresentation;

- (void)setOperation:(TCMMMOperation *)anOperation;
- (TCMMMOperation *)operation;

- (NSInteger)numberOfClientMessages;
- (NSInteger)numberOfServerMessages;

- (void)incrementNumberOfClientMessages;
- (void)incrementNumberOfServerMessages;

@end
