//
//  TCMBencodingUtilities.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

NSData *TCM_BencodedObject(id aObject);

id TCM_BdecodedObjectWithData(NSData *data);
id TCM_BdecodedObject(uint8_t *aBytes, unsigned *aPosition, unsigned aLength);

