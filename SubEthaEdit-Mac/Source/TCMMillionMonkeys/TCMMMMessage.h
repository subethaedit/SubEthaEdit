//  TCMMMMessage.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import <Foundation/Foundation.h>


@class TCMMMOperation;


@interface TCMMMMessage : NSObject {
    long long I_numberOfClientMessages;
    long long I_numberOfServerMessages;
    TCMMMOperation *I_operation;
}

+ (id)messageWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (id)initWithOperation:(TCMMMOperation *)anOperation numberOfClient:(long long)aClientNumber numberOfServer:(long long)aServerNumber;

- (NSDictionary *)dictionaryRepresentation;

- (void)setOperation:(TCMMMOperation *)anOperation;
- (TCMMMOperation *)operation;

- (long long)numberOfClientMessages;
- (long long)numberOfServerMessages;

- (void)incrementNumberOfClientMessages;
- (void)incrementNumberOfServerMessages;

@end
