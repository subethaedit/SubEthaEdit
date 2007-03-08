//
//  HDCrashReporter.m
//
//  HDCrashReporter is a framework to send back to the developer the crash reports 
//  and the console log after a crash.
//  Copyright (C) 2006 Humble Daisy
//
//  A few changes specific to SubEthaEdit and BugMonkey (c) by Martin Pittenauer
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
//  For more information contact: developers@profcast.com
//

#import "crashReporter.h"
#import "NSURLRequestPostAdditions.h"
#import <AddressBook/AddressBook.h>

@implementation HDCrashReporter

+ (BOOL) newCrashLogExists {
    
    BOOL returnValue = NO;
    NSDate *crashLogModificationDate;
    SInt32 MacVersion;

    NSDate *lastCrashDate = [[NSUserDefaults standardUserDefaults] valueForKey: @"HDCrashReporter.lastCrashDate"];
	NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,FALSE);

    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        
		if (MacVersion >= 0x1050) {
            // User is using Leopard or later
			NSString *crashReportLogPath = [[[libraryDirectories objectAtIndex: 0] stringByAppendingPathComponent:@"Logs/CrashReporter/"]stringByExpandingTildeInPath];
			NSEnumerator *crashLogFiles = [[NSFileManager defaultManager] enumeratorAtPath:crashReportLogPath ];
			NSString *crashLogFile;
			crashLogModificationDate = [NSDate distantPast];
			while ((crashLogFile = [crashLogFiles nextObject])) {
				if ([[crashLogFile lastPathComponent] hasPrefix:@"SubEthaEdit"]) {
					crashLogFile = [crashReportLogPath stringByAppendingPathComponent:crashLogFile];
					NSDate *crashLogFileDate = [[[NSFileManager defaultManager] fileAttributesAtPath:crashLogFile traverseLink: YES] fileModificationDate];
					crashLogModificationDate = [crashLogModificationDate laterDate:crashLogFileDate];
				}
			}
        } else {
            // User is using Tiger or earlier
            
            NSString *crashLogPath = [[[libraryDirectories objectAtIndex: 0 ] stringByAppendingPathComponent:  @"Logs/CrashReporter/SubEthaEdit.crash.log"] stringByExpandingTildeInPath];
            
            crashLogModificationDate = [[[NSFileManager defaultManager] fileAttributesAtPath: crashLogPath traverseLink: YES] fileModificationDate];            
        }

		if (lastCrashDate && crashLogModificationDate && ([crashLogModificationDate compare: lastCrashDate] == NSOrderedDescending)) {
			//we had a new crash since last time, ask the user if wants to submit it
			returnValue = YES;
		}
			[[NSUserDefaults standardUserDefaults] setValue: crashLogModificationDate forKey: @"HDCrashReporter.lastCrashDate"];

    } else NSBeep();
    
    return returnValue;
}
  

+ (void) doCrashSubmitting
{ 
  //instantiate our object
  //
  HDCrashReporter *crashReporterController = [[HDCrashReporter alloc] initWithWindowNibName: @"crashReporter"];
    
  NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,FALSE);
  
  NSString *logFilePathAndname = @"Logs/CrashReporter/SubEthaEdit.crash.log";
  NSString *crashLogPath = [[[libraryDirectories objectAtIndex: 0 ] stringByAppendingPathComponent: logFilePathAndname] stringByExpandingTildeInPath];
  
  //get the crash
  //
	NSString *lastCrash;

	SInt32 MacVersion;

    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        
		if (MacVersion >= 0x1050) {
            // User is using Leopard or later
			NSString *crashReportLogPath = [[[libraryDirectories objectAtIndex: 0] stringByAppendingPathComponent:@"Logs/CrashReporter/"]stringByExpandingTildeInPath];
			NSEnumerator *crashLogFiles = [[NSFileManager defaultManager] enumeratorAtPath:crashReportLogPath ];
			NSString *crashLogFile;
			NSDate *crashLogModificationDate = [NSDate distantPast];
			while ((crashLogFile = [crashLogFiles nextObject])) {
				if ([[crashLogFile lastPathComponent] hasPrefix:@"SubEthaEdit"]) {
					crashLogFile = [crashReportLogPath stringByAppendingPathComponent:crashLogFile];
					NSDate *crashLogFileDate = [[[NSFileManager defaultManager] fileAttributesAtPath:crashLogFile traverseLink: YES] fileModificationDate];
					if ( [crashLogFileDate isGreaterThan:crashLogModificationDate]) {
						crashLogModificationDate = crashLogFileDate;
						crashLogPath = crashLogFile;
					}
				}
			}
			
			lastCrash = [NSString stringWithContentsOfFile:crashLogPath];
        } else {
            // User is using Tiger or earlier
            
			NSString *crashLogs = [NSString stringWithContentsOfFile: crashLogPath];
			lastCrash = [[crashLogs componentsSeparatedByString: @"**********\n\n"] lastObject];
        }
    } else NSBeep();

    
  //now get the console log
  //
  NSString *consolelogPath = [NSString stringWithFormat: @"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt: getuid()]];
  NSString *console = [NSString stringWithContentsOfFile: consolelogPath];
  NSEnumerator *theEnum = [[console componentsSeparatedByString: @"\n"] objectEnumerator];
  NSString* currentObject;
  NSMutableArray *consoleStrings = [NSMutableArray array];
  
  while (currentObject = [theEnum nextObject]) {
    if ([currentObject rangeOfString: @"SubEthaEdit"].location != NSNotFound) {
      [consoleStrings addObject: currentObject];
	}
  }  
  
  NSString *consoleLog = [consoleStrings componentsJoinedByString: @"\n"];
  
  NSString *userReportString = [[NSBundle bundleWithIdentifier:@"com.HumbleDaisy.HDCrashReporter"] localizedStringForKey:@"UserReportHeadline" value:@"UserReportHeadline" table:nil];

  NSString *bugReport = [NSString stringWithFormat: @"-------------------------------------------------------------------\n%@:\n-------------------------------------------------------------------\n\n...\n\n-------------------------------------------------------------------\nCrash Log:\n-------------------------------------------------------------------\n\n%@\n-------------------------------------------------------------------\nConsole Log:\n-------------------------------------------------------------------\n\n%@\n\n", userReportString, lastCrash, consoleLog];
   
  [[crashReporterController window] center];
  [crashReporterController showWindow: self];

  [[crashReporterController window] makeFirstResponder:[crashReporterController bugReportTextView]];
  [[crashReporterController bugReportTextView] setString:bugReport];
  [[crashReporterController bugReportTextView] setSelectedRange:NSMakeRange(139+[userReportString length],3)]; // Select "..."
}

- (IBAction) sendReport: (id) sender
{   
    NSMutableDictionary *bugInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @"Bug", @"issue[issue_type]",
                            @"I Didn't Try", @"issue[issue_reproducibility]",
                            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"issue[affects_project_version]",
                            @"Automatic Crash Report", @"issue[title]",
                            @"crash", @"issue[tag_string]",
                            [[self bugReportTextView] string], @"issue[details]",
                            @"", @"configuration_information",
                            @"", @"enclosure",
                            nil];
     
    NSMutableDictionary *contactDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"", @"user[email]",
                        @"", @"user[firstname]",
                        @"", @"user[surname]",
                        nil];
                        
    if ([nameAndEmailButton state]==NSOnState) {
        ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];
        
        if (meCard) {
            NSString *firstName = [meCard valueForProperty:kABFirstNameProperty];
            NSString *lastName  = [meCard valueForProperty:kABLastNameProperty];            
            NSString *email=nil;

            ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
            NSString *primaryIdentifier=[emails primaryIdentifier];
            if (primaryIdentifier) {
                email=[emails valueAtIndex:[emails indexForIdentifier:primaryIdentifier]];
            }
        
            if (firstName) [contactDict setObject:firstName forKey:@"user[firstname]"];
            if (lastName) [contactDict setObject:lastName forKey:@"user[surname]"];
            if (email) [contactDict setObject:email forKey:@"user[email]"];
        }                
    }
    
    [bugInfo addEntriesFromDictionary:contactDict];
    
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.codingmonkeys.de/bugs/public/automated_report/SEE"] postDictionary:bugInfo];
    
    [aRequest setValue:[NSString stringWithFormat:@"SubEthaEdit %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] forHTTPHeaderField:@"User-Agent"];

    NSURLConnection* theConnection = [NSURLConnection connectionWithRequest:aRequest delegate: self];
    [theConnection retain];
    
    [self close];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [connection autorelease];
}

- (NSTextView *)bugReportTextView
{  
  return bugReportTextView; 
}

- (void)dealloc
{
  [super dealloc];
}

@end
