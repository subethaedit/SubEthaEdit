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
#import <OgreKit/OgreKit.h>

#import <asl.h>

extern aslmsg asl_new(uint32_t type) __attribute__((weak_import));
extern int asl_set_query(aslmsg msg, const char *key, const char *value, uint32_t op) __attribute__((weak_import));
extern aslresponse asl_search(aslclient asl, aslmsg msg) __attribute__((weak_import));
extern aslmsg aslresponse_next(aslresponse r) __attribute__((weak_import));
extern const char * asl_key(aslmsg msg, uint32_t n) __attribute__((weak_import));
extern const char * asl_get(aslmsg msg, const char *key) __attribute__((weak_import));
extern void aslresponse_free(aslresponse a) __attribute__((weak_import));


@implementation HDCrashReporter

+ (BOOL) newCrashLogExists {
    
    BOOL returnValue = NO;
    NSDate *crashLogModificationDate;
    SInt32 MacVersion;

    NSDate *lastCrashDate = [[NSUserDefaults standardUserDefaults] valueForKey: @"HDCrashReporter.lastCrashDate"];
	if (!lastCrashDate) lastCrashDate = [NSDate distantPast];
	
	NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,FALSE);

    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        
		if (MacVersion >= 0x1050) {
            // User is using Leopard or later
			NSString *crashReportLogPath = [[[libraryDirectories objectAtIndex: 0] stringByAppendingPathComponent:@"Logs/CrashReporter/"]stringByExpandingTildeInPath];
			NSEnumerator *crashLogFiles = [[NSFileManager defaultManager] enumeratorAtPath:crashReportLogPath ];
			NSString *crashLogFile;
			crashLogModificationDate = [NSDate distantPast];
			while ((crashLogFile = [crashLogFiles nextObject])) {
				if ([[crashLogFile lastPathComponent] hasPrefix:bundleName]) {
					crashLogFile = [crashReportLogPath stringByAppendingPathComponent:crashLogFile];
					NSDate *crashLogFileDate = [[[NSFileManager defaultManager] fileAttributesAtPath:crashLogFile traverseLink: YES] fileModificationDate];
					crashLogModificationDate = [crashLogModificationDate laterDate:crashLogFileDate];
				}
			}
        } else {
            // User is using Tiger or earlier
            
            NSString *crashLogPath = [[[libraryDirectories objectAtIndex: 0 ] stringByAppendingPathComponent:[NSString stringWithFormat:@"Logs/CrashReporter/%@.crash.log", bundleName]] stringByExpandingTildeInPath];
            
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
  
- (NSString *)parseTitleFromCrashReport:(NSString *)crashReport {
	NSArray *lines = [crashReport componentsSeparatedByString:@"\n"];
	NSEnumerator *enumerator = [lines objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        if ([object rangeOfString:@" Crashed:"].location != NSNotFound) break;
    }
	
	NSString *line = [enumerator nextObject];
	OGRegularExpression *crashComponentRegex = [[OGRegularExpression alloc] initWithString:@"(\\S+)\\s+(?<place>\\S+)\\s+(\\S+)\\s+(?<method>.*)" options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
	OGRegularExpressionMatch *match = [crashComponentRegex matchInString:line];
	
	NSString *title = [NSString stringWithFormat:@"Crash in %@ of [%@]",[match substringNamed:@"method"],[match substringNamed:@"place"]];
	
	return title;
}

+ (void) doCrashSubmitting
{ 
  //instantiate our object
  //
  HDCrashReporter *crashReporterController = [[HDCrashReporter alloc] initWithWindowNibName: @"crashReporter"];
    
  NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,FALSE);
  
  NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

  NSString *logFilePathAndname = [NSString stringWithFormat:@"Logs/CrashReporter/%@.crash.log", bundleName];
  NSString *crashLogPath = [[[libraryDirectories objectAtIndex: 0 ] stringByAppendingPathComponent: logFilePathAndname] stringByExpandingTildeInPath];
  
  //get the crash
  //
	NSString *lastCrash = @"";
    NSString *consoleLog = @"";

	SInt32 MacVersion;

    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        
		if (MacVersion >= 0x1050) {
            // User is using Leopard or later
			NSString *crashReportLogPath = [[[libraryDirectories objectAtIndex: 0] stringByAppendingPathComponent:@"Logs/CrashReporter/"]stringByExpandingTildeInPath];
			NSEnumerator *crashLogFiles = [[NSFileManager defaultManager] enumeratorAtPath:crashReportLogPath ];
			NSString *crashLogFile;
			NSDate *crashLogModificationDate = [NSDate distantPast];
			while ((crashLogFile = [crashLogFiles nextObject])) {
				if ([[crashLogFile lastPathComponent] hasPrefix:bundleName]) {
					crashLogFile = [crashReportLogPath stringByAppendingPathComponent:crashLogFile];
					NSDate *crashLogFileDate = [[[NSFileManager defaultManager] fileAttributesAtPath:crashLogFile traverseLink: YES] fileModificationDate];
					if ( [crashLogFileDate isGreaterThan:crashLogModificationDate]) {
						crashLogModificationDate = crashLogFileDate;
						crashLogPath = crashLogFile;
					}
				}
			}
			
			lastCrash = [NSString stringWithContentsOfFile:crashLogPath];
            
            NSMutableArray *consoleStrings = [NSMutableArray array];
            aslmsg q, m;
            aslresponse r;
            int i;
            const char *key, *val;
            q = asl_new(ASL_TYPE_QUERY);
            asl_set_query(q, ASL_KEY_SENDER, [bundleName UTF8String], ASL_QUERY_OP_EQUAL);
            r = asl_search(NULL, q);
            while (NULL != (m = aslresponse_next(r))) {
                const char *pid = NULL;
                const char *sender = NULL;
                const char *message = NULL;
                const char *timestamp = NULL;
                for (i = 0; (NULL != (key = asl_key(m, i))); i++) {
                    val = asl_get(m, key);
                    if (!strcmp(key, ASL_KEY_TIME)) {
                        NSTimeInterval secs = atof(val);
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:secs];
                        timestamp = [[date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S.%F" timeZone:nil locale:nil] UTF8String];
                    } else if (!strcmp(key, ASL_KEY_SENDER)) {
                        sender = val;
                    } else if (!strcmp(key, ASL_KEY_PID)) {
                        pid = val;
                    } else if (!strcmp(key, ASL_KEY_MSG)) {
                        message = val;
                    }
                }
                NSMutableString *msg = [[NSMutableString alloc] init];
                if (timestamp) [msg appendFormat:@"%s ", timestamp];
                if (sender) [msg appendFormat:@"%s", sender];
                if (pid) [msg appendFormat:@"[%s] ", pid];
                else [msg appendString:@"[] "];
                if (message) [msg appendFormat:@"%s", message];
                [consoleStrings addObject:msg];
                [msg release];
            }
            aslresponse_free(r);
            consoleLog = [consoleStrings componentsJoinedByString: @"\n"];
            
        } else {
            // User is using Tiger or earlier
            
			NSString *crashLogs = [NSString stringWithContentsOfFile: crashLogPath];
			lastCrash = [[crashLogs componentsSeparatedByString: @"**********\n\n"] lastObject];
            
            NSString *consolelogPath;
            if (MacVersion < 0x1040) {
                consolelogPath = [NSString stringWithFormat:@"/Library/Logs/Console/%@/console.log", NSUserName()];
            } else {
                consolelogPath = [NSString stringWithFormat:@"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt:getuid()]];
            }
            
            NSString *console = [NSString stringWithContentsOfFile: consolelogPath];
            NSEnumerator *theEnum = [[console componentsSeparatedByString: @"\n"] objectEnumerator];
            NSString* currentObject;
            NSMutableArray *consoleStrings = [NSMutableArray array];

            while (currentObject = [theEnum nextObject]) {
                if ([currentObject rangeOfString:bundleName].location != NSNotFound) {
                    [consoleStrings addObject: currentObject];
                }
            }  

            consoleLog = [consoleStrings componentsJoinedByString: @"\n"];
          }
    } else {
        NSBeep();
    }
  
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
	NSString *bugText = [[self bugReportTextView] string];

    NSMutableDictionary *bugInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @"Bug", @"issue[issue_type]",
                            @"I Didn't Try", @"issue[issue_reproducibility]",
                            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"issue[affects_project_version]",
                            [self parseTitleFromCrashReport:bugText], @"issue[title]",
                            @"crash", @"issue[tag_string]",
                            bugText, @"issue[details]",
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
