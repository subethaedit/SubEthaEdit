//
//  SDDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/23/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMMSession.h"


@interface SDDocument : NSObject <SEEDocument> {
    @private
    NSMutableAttributedString *_attributedString;
    TCMMMSession *_session;
    struct {
        BOOL isAnnounced;
    } _flags;
}

- (TCMMMSession *)session;
- (void)setSession:(TCMMMSession *)session;

- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)flag;

@end
