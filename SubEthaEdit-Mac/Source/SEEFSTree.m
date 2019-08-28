//
//  SEEFSTree.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 24.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEFSTree.h"
#import "SEEFSTreeNode.h"

@interface SEEFSTree ()
-(void)pathDidChange:(NSString *)path withFlags:(FSEventStreamEventFlags)flags;
@end

static void fsEventsCallback(ConstFSEventStreamRef streamRef,
                             void *clientCallBackInfo,
                             size_t numEvents,
                             void *eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[]){
    NSArray<NSString*>* paths = (__bridge NSArray *)eventPaths;
    SEEFSTree *tree = (__bridge SEEFSTree*)clientCallBackInfo;
    
    for (size_t i = 0; i < numEvents; i++) {
        [tree pathDidChange:paths[i] withFlags:eventFlags[i]];
    }
}

@implementation SEEFSTree {
    FSEventStreamRef fsEventStream;
}

- (instancetype)initWithURL:(NSURL *)anURL;
{
    self = [super init];
    if (self) {
        _root = [[SEEFSTreeNode alloc] initWithURL:anURL];
        
        NSArray *pathsToWatch = @[anURL.path];
        
        CFAbsoluteTime latency = 0.5; // Latency in seconds
        FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagUseCFTypes;
        
        FSEventStreamContext ctx;
        memset(&ctx, 0, sizeof(ctx));
        ctx.info = (__bridge void *)self;
        
        fsEventStream = FSEventStreamCreate(NULL,
                                            &fsEventsCallback,
                                            &ctx,
                                            (__bridge CFArrayRef)pathsToWatch,
                                            kFSEventStreamEventIdSinceNow,
                                            latency,
                                            flags);
        FSEventStreamScheduleWithRunLoop(fsEventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamStart(fsEventStream);
    }
    return self;
}

-(void)dealloc {
    if(fsEventStream) {
        FSEventStreamStop(fsEventStream);
        FSEventStreamInvalidate(fsEventStream);
        FSEventStreamRelease(fsEventStream);
        fsEventStream = NULL;
    }
}

-(void)pathDidChange:(NSString *)path withFlags:(FSEventStreamEventFlags)flags {
    [[self.root nodeForPath:path onlyIfCached:YES] reload];
}


@end
