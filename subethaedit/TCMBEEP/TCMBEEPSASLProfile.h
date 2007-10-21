//
//  TCMBEEPSASLProfile.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"

@interface TCMBEEPSASLProfile : TCMBEEPProfile {

}

- (void)startSecondRoundtripWithBlob:(NSData *)inData;

@end
