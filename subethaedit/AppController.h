//
//  AppController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEP/TCMBEEP.h"

@interface AppController : NSObject {
    TCMBEEPListener *I_listener;
    NSNetService    *I_netService;
    int I_listeningPort;
}

@end
