//  TCMBencodingUtilities.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.

#import <Foundation/Foundation.h>


// bencoded data can be stored and put into corresponding dictionaryrepresentations
@interface TCMMutableBencodedData : NSObject

@property (nonatomic, readonly) NSMutableData *data;

- (instancetype)initWithData:(NSData *)aData;
- (instancetype)initWithObject:(id)anObject;
- (void)appendObjectToBencodedArray:(id)anObject;
- (id)decodedObject;
- (void)appendObjectsFromArrayToBencodedArray:(NSArray *)anArray;
- (id)mutableBencodedDataByAppendingObjectsFromArrayToBencodedArray:(NSArray *)anArray;
@end

NSData *TCM_BencodedObject(id aObject);

// returns the count of appended bytes
CFIndex TCM_AppendStringToMutableData(NSString *inString, NSMutableData *inData);
id TCM_BdecodedObjectWithData(NSData *data);
id TCM_CopyBdecodedObject(uint8_t *aBytes, unsigned *aPosition, unsigned aLength) NS_RETURNS_RETAINED;

