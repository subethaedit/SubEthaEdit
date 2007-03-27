//
//  SDAppController.h
//  seed
//
//  Created by Martin Ott on 3/14/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDDocument;

extern int fd;
extern BOOL endRunLoop;


@interface SDAppController : NSObject {
    @private
    NSPipe *_signalPipe;
    SDDocument *_document;
}

@end
