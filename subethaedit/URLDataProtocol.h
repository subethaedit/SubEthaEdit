//
//  URLDataProtocol.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Oct 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface URLDataProtocol : NSURLProtocol {
    NSCachedURLResponse *I_cachedURLResponse;
}

@end
