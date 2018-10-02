//  SEEConnectionManager.h
//  SubEthaEdit
//
//  Original (InternetBrowserController.h) by Martin Ott on Wed Mar 03 2004.
//	Updated my Michael Ehrmann on Fri Feb 21 2014.

#import <Foundation/Foundation.h>
#import "SEEConnection.h"

@interface SEEConnectionManager : NSObject

@property (nonatomic, strong) NSMutableArray *entries; // array of SEEConnections; KVO compliant.

+ (SEEConnectionManager *)sharedInstance;
+ (NSURL *)applicationConnectionURL;

- (void)connectToURL:(NSURL *)anURL;
- (void)connectToAddress:(NSString *)address;

- (void)clear;


@end
