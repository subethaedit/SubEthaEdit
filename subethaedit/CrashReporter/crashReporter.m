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

@implementation HDCrashReporter

+ (BOOL) newCrashLogExists
{
  BOOL returnValue = NO;
  
  //do crash recovery
  //
  NSDate *lastCrashDate = [[NSUserDefaults standardUserDefaults] valueForKey: @"HDCrashReporter.lastCrashDate"];
  NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,FALSE);
  
  NSString *logFilePathAndname = @"Logs/CrashReporter/SubEthaEdit.crash.log";
  NSString *crashLogPath = [[[libraryDirectories objectAtIndex: 0 ] stringByAppendingPathComponent: logFilePathAndname] stringByExpandingTildeInPath];
  
  NSDate *crashLogModificationDate = [[[NSFileManager defaultManager] fileAttributesAtPath: crashLogPath traverseLink: YES] fileModificationDate];
  if (lastCrashDate && 
      crashLogModificationDate && 
      ([crashLogModificationDate compare: lastCrashDate] == NSOrderedDescending))
  {
    //we had a new crash since last time, ask the user ih wants to submit it
    //
    returnValue = YES;
  }
  
  [[NSUserDefaults standardUserDefaults] setValue: crashLogModificationDate
                                           forKey: @"HDCrashReporter.lastCrashDate"];
  
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
  NSString *crashLogs = [NSString stringWithContentsOfFile: crashLogPath];
  NSString *lastCrash = [[crashLogs componentsSeparatedByString: @"**********\n\n"] lastObject];
    
  //now get the console log
  //
  NSString *consolelogPath = [NSString stringWithFormat: @"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt: getuid()]];
  NSString *console = [NSString stringWithContentsOfFile: consolelogPath];
  NSEnumerator *theEnum = [[console componentsSeparatedByString: @"\n"] objectEnumerator];
  NSString* currentObject;
  NSMutableArray *consoleStrings = [NSMutableArray array];
  
  while (currentObject = [theEnum nextObject])
  {
    if ([currentObject rangeOfString: @"SubEthaEdit["].location != NSNotFound)
      [consoleStrings addObject: currentObject];
  }  
  
  NSString *consoleLog = [consoleStrings componentsJoinedByString: @"\n"];
  
  NSString *bugReport = [NSString stringWithFormat:@"Feedback:\n\n\nCrash Log:\n%@\n\nConsole Log:\n%@\n\n", lastCrash, consoleLog];
    
  [crashReporterController setBugReport: [[[NSAttributedString alloc] initWithString:bugReport attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName, [NSFont fontWithName:@"Monaco" size:9.0], NSFontAttributeName,nil]]autorelease]];
  
  [crashReporterController showWindow: self];
}

- (IBAction) sendReport: (id) sender
{   
    #warning "Crash Reporter version set to 2.5.1"
    NSMutableDictionary *bugInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @"Report Issue", @"requestReportIssue",
                            @"1", @"issue[project_id]",
                            @"1", @"issue[issue_type_id]",
                            @"4", @"issue[issue_reproducibility_id]",
                            @"56", @"issue[affects_project_version_id]", // 56 == 2.5.1
                            @"Automatic Crash Report", @"issue[title]",
                            @"crash", @"issue[tag_string]",
                            [[self bugReport] string], @"issue[details]",
                            @"", @"configuration_information",
                            @"", @"enclosure",
                            nil];
     
    NSDictionary *contactDict;                       
    if ([nameAndEmailButton state]==NSOffState) {
        contactDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"", @"user[email]",
                        @"", @"user[firstname]",
                        @"", @"user[surname]",
                        nil];
    } else {
        #warning FIXME: Add name and mail stuff here
        contactDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"", @"user[email]",
                        @"", @"user[firstname]",
                        @"", @"user[surname]",
                        nil];    
    }
    
    [bugInfo addEntriesFromDictionary:contactDict];
    
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.codingmonkeys.de/bugs/public/report/SEE"] postDictionary:bugInfo];
    
    [aRequest setValue:[NSString stringWithFormat:@"SubEthaEdit %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] forHTTPHeaderField:@"User-Agent"];

//    [NSURLConnection sendSynchronousRequest:aRequest returningResponse:nil error:nil];
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

- (NSAttributedString *)bugReport
{  
  return [[bugReport retain] autorelease]; 
}

- (void)setBugReport:(NSAttributedString *)aString
{  
  if (bugReport != aString) {
    [bugReport release];
    bugReport = [aString retain];
  }
}

- (void)dealloc
{
  [self setBugReport:nil];
  [super dealloc];
}

@end
