/*
        PrintPanelAccessoryController.m
        Copyright (c) 2007 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer
	
	PrintPanelAccessoryController is a subclass of NSViewController demonstrating how to add an accessory view to the print panel.
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PrintPanelAccessoryController.h"
#import "Preferences.h"


@implementation PrintPanelAccessoryController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    // We override the designated initializer, ignoring the nib since we need our own
    return [super initWithNibName:@"PrintPanelAccessory" bundle:nibBundleOrNil];
}

/* The first time the printInfo is supplied, initialize the value of the pageNumbering setting from defaults
*/
- (void)setRepresentedObject:(id)printInfo {
    [super setRepresentedObject:printInfo];
    [self setPageNumbering:[[[NSUserDefaults standardUserDefaults] objectForKey:NumberPagesWhenPrinting] boolValue]];
}

- (void)setPageNumbering:(BOOL)flag {
    NSPrintInfo *printInfo = [self representedObject];
    [[printInfo dictionary] setObject:[NSNumber numberWithBool:flag] forKey:NSPrintHeaderAndFooter];
}

- (BOOL)pageNumbering {
    NSPrintInfo *printInfo = [self representedObject];
    return [[[printInfo dictionary] objectForKey:NSPrintHeaderAndFooter] boolValue];
}

- (IBAction)changePageNumbering:(id)sender {
    [self setPageNumbering:[sender state] ? YES : NO];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObject:@"pageNumbering"];
}

/* This enables TextEdit-specific settings to be displayed in the Summary pane of the print panel
*/
- (NSArray *)localizedSummaryItems {
    return [NSArray arrayWithObject:
	    [NSDictionary dictionaryWithObjectsAndKeys:
		NSLocalizedStringFromTable(@"Header and Footer", @"PrintPanelAccessory", @"Print panel summary item title for whether header and footer (page number, date, document title) should be printed"), NSPrintPanelAccessorySummaryItemNameKey,
		[self pageNumbering] ? NSLocalizedStringFromTable(@"On", @"PrintPanelAccessory", @"Print panel summary value when header and footer printing is on") : NSLocalizedStringFromTable(@"Off", @"PrintPanelAccessory", @"Print panel summary value when header and footer printing is off"), NSPrintPanelAccessorySummaryItemDescriptionKey,
		nil]];
}

@end
