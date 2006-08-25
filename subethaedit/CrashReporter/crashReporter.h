//
//  HDCrashReporter.h
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

#import <Cocoa/Cocoa.h>


@interface HDCrashReporter : NSWindowController 
{
  NSAttributedString *bugReport;
  IBOutlet NSButton *nameAndEmailButton; 
}

+ (BOOL) newCrashLogExists;
+ (void) doCrashSubmitting;

- (IBAction) sendReport: (id) sender;

- (NSAttributedString *)bugReport;
- (void)setBugReport:(NSAttributedString *)aString;

@end
