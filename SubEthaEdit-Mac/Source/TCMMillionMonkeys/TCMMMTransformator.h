//  TCMMMTransformator.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.

#import <Foundation/Foundation.h>


@class TCMMMOperation;


@interface TCMMMTransformator : NSObject {
    NSMutableDictionary *I_registeredTransformations;
}

+ (TCMMMTransformator *)sharedInstance;

- (void)registerTransformationTarget:(id)aTarget selector:(SEL)aSelector forOperationId:(NSString *)anOperationID andOperationID:(NSString *)anotherOperationID;

- (void)transformOperation:(TCMMMOperation *)anOperation serverOperation:(TCMMMOperation *)aServerOperation;

@end
