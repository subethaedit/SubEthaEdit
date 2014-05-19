//
//  main.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef BETA
#define MAC_APP_STORE_RECEIPT_VALIDATION
#import "SEEMacAppStoreReceiptValidation.h"
#endif

int main(int argc, char *argv[])
{
#ifdef MAC_APP_STORE_RECEIPT_VALIDATION
	return CheckReceiptAndRun(argc, argv);
#else
	return NSApplicationMain(argc,  (const char **) argv);
#endif
}
