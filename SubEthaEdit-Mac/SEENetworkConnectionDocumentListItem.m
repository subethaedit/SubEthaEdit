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

#import "SEENetworkConnectionDocumentListItem.h"
#import "SEEConnection.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

void * const SEENetworkConnectionRepresentationConnectionObservingContext = (void *)&SEENetworkConnectionRepresentationConnectionObservingContext;
void * const SEENetworkConnectionRepresentationUserObservingContext = (void *)&SEENetworkConnectionRepresentationUserObservingContext;

@implementation SEENetworkConnectionDocumentListItem

@synthesize name = _name;
@synthesize image = _image;

- (id)init
{
    self = [super init];
    if (self) {
		self.name = @"Unknown";
        self.image = [NSImage imageNamed:NSImageNameUserGuest];

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
	[self addObserver:self forKeyPath:@"user" options:0 context:SEENetworkConnectionRepresentationUserObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"connection" context:SEENetworkConnectionRepresentationConnectionObservingContext];
	[self removeObserver:self forKeyPath:@"user" context:SEENetworkConnectionRepresentationUserObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkConnectionRepresentationConnectionObservingContext) {
		SEEConnection *connection = self.connection;
		self.user = connection.user;
	} else if (context == SEENetworkConnectionRepresentationUserObservingContext) {
		TCMMMUser *user = self.user;
		SEEConnection *connection = self.connection;
		if (user) {
			self.name = user.name;
			self.image = user.image;
		} else if (connection) {
			self.name = connection.URL.description;
			self.image = [NSImage imageNamed:NSImageNameNetwork];
		}
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)itemAction:(id)sender {

}

@end
