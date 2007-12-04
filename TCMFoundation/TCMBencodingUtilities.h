//
//  TCMBencodingUtilities.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


// bencoded data can be stored and put into corresponding dictionaryrepresentations
@interface TCMMutableBencodedData : NSObject {
    NSMutableData *I_mutableData;
}
- (id)initWithData:(NSData *)aData;
- (id)initWithObject:(id)anObject;
- (NSData*)data;
- (void)appendObjectToBencodedArray:(id)anObject;
- (id)decodedObject;
- (void)appendObjectsFromArrayToBencodedArray:(NSArray *)anArray;
- (id)mutableBencodedDataByAppendingObjectsFromArrayToBencodedArray:(NSArray *)anArray;
@end

NSData *TCM_BencodedObject(id aObject);

id TCM_BdecodedObjectWithData(NSData *data);
id TCM_BdecodedObject(uint8_t *aBytes, unsigned *aPosition, unsigned aLength);

