//
//  SEENetworkConnectionRepresentation.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENetworkConnectionRepresentation.h"
#import "SEEConnection.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

void * const SEENetworkConnectionRepresentationConnectionObservingContext = (void *)&SEENetworkConnectionRepresentationConnectionObservingContext;

@interface SEENetworkConnectionRepresentation ()
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSImage *image;
@end

@implementation SEENetworkConnectionRepresentation

- (id)init
{
    self = [super init];
    if (self) {
		self.name = @"Unknown";
        self.image = [[NSWorkspace sharedWorkspace] iconForFileType:@"public.item"];

		[self installKVO];
    }
    return self;
}

- (void)dealloc
{
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"connection" options:0 context:SEENetworkConnectionRepresentationConnectionObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"connection" context:SEENetworkConnectionRepresentationConnectionObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkConnectionRepresentationConnectionObservingContext) {
		SEEConnection *connection = self.connection;
		self.name = connection.user.name;
		self.image = connection.user.image;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
