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
#ifdef BETA
#ifdef BETA_EXPIRE_DATE

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define BETA_EXPIRE_DATE_LITERAL @ STRINGIZE2(BETA_EXPIRE_DATE)

	NSString *expireDateString = BETA_EXPIRE_DATE_LITERAL;
	NSDate *expireDate = [NSCalendarDate dateWithString:expireDateString];
	NSDate *today = [NSDate date];
	if ([today compare:expireDate] == NSOrderedDescending) {
		NSLog(@"THIS BETA IS EXPIRED!");

		NSAlert *alert = [NSAlert alertWithMessageText:@"This beta version of SubEthaEdit has expired." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please visit http://subethaedit.net/ to download a new version.", nil];
		[alert runModal];
		return 0;
	}

#endif
#endif

#ifdef MAC_APP_STORE_RECEIPT_VALIDATION
	return CheckReceiptAndRun(argc, (const char **) argv);
#else
	return NSApplicationMain(argc, (const char **) argv);
#endif
}
