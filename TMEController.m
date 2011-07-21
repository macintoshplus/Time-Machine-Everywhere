//
//  TMEController.m
//
//  Created by Jean-Baptiste Nahan on 17/01/11.
//  Copyright 2011 Jean-Baptiste Nahan. All rights reserved.
//

#include <Security/Authorization.h>
#include <Security/AuthorizationDB.h>
#include <Security/AuthorizationTags.h>

#include <sys/types.h>
#include <unistd.h>

#import "TMEController.h"


@implementation TMEController

@synthesize macAddress, hostName, backupName, sizeBundle, bundleName, bundleStatus;

- (id)init{
	self = [super init];
	if(self){
		//NSLog(@"getuid = %i ; getgid = %i ; geteuid = %i",getuid(),getgid(),geteuid());
		//setuid(0);
		
		if(geteuid()!=0){
			if([self launchAuthPrgm]!=0) [NSApp terminate:self];
		}
	}
	
	return self;
}


- (void) awakeFromNib{
	
	[winMain center];
	
	NSArray * args = [[NSArray alloc] initWithObjects:@"en0", NULL];
	
	NSTask * getName = [[NSTask alloc] init];
	[getName setCurrentDirectoryPath:@"/sbin/"];
	//[getName setEnvironment:env];
	[getName setLaunchPath:@"/sbin/ifconfig"];
	[getName setArguments:args];
	
	[getName setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	NSPipe* outputPipe=[NSPipe pipe] ;
	[getName setStandardOutput:outputPipe];
	NSFileHandle *file;
    file = [outputPipe fileHandleForReading];

	[getName launch];
    [getName waitUntilExit];
	
    NSData *data;
    data = [file readDataToEndOfFile];
	
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	NSRange loc = [string rangeOfString:@"ether "];
	
	NSRange locAddress = NSMakeRange(loc.location+loc.length, 17);
	
	string=[string substringWithRange:locAddress];
	
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@""];
	
	[self setMacAddress:string];
	
	//NSLog(@"%@",string);
	
	
	NSProcessInfo *pi = [NSProcessInfo processInfo];
	NSString * localName = [pi hostName];
	//Si la fin du nom est .local il le retire
	if([[localName substringWithRange:NSMakeRange([localName length]-6, 6)] isEqualToString:@".local"])
		localName=[localName substringWithRange:NSMakeRange(0, [localName length]-6)];
    
	if([[localName substringWithRange:NSMakeRange([localName length]-5, 5)] isEqualToString:@".home"])
		localName=[localName substringWithRange:NSMakeRange(0, [localName length]-5)];
	
	[self setHostName:localName];
	
	[self setSizeBundle:70];
	
	[self setBackupName:[NSString stringWithFormat:@"TM_%@",localName]];
	
	
	[self setBundleName:[[NSString stringWithFormat:@"~/Desktop/%@_%@.sparsebundle", localName, string] stringByExpandingTildeInPath]];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeTaskInfo:) name:NSFileHandleReadCompletionNotification object:nil];
	
}

- (int) preAuthorize
{
	int						err;
    AuthorizationFlags      authFlags;
	
	
	//NSLog (@"MyWindowController: preAuthorize");
	
	if (_authRef)
		return errAuthorizationSuccess;
	
	//NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCreate...**\n");
    
	authFlags = kAuthorizationFlagDefaults;
	err = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, authFlags, &_authRef);
	if (err != errAuthorizationSuccess)
		return err;
	
	//NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCopyRights...**\n");
	
	_authItem.name = kAuthorizationRightExecute;
	_authItem.valueLength = 0;
	_authItem.value = NULL;
	_authItem.flags = 0;
	_authRights.count = 1;
	_authRights.items = (AuthorizationItem*) malloc (sizeof (_authItem));
	memcpy (&_authRights.items[0], &_authItem, sizeof (_authItem));
	authFlags = kAuthorizationFlagDefaults
	| kAuthorizationFlagExtendRights
	| kAuthorizationFlagInteractionAllowed
	| kAuthorizationFlagPreAuthorize;
	err = AuthorizationCopyRights (_authRef, &_authRights, kAuthorizationEmptyEnvironment, authFlags, NULL);
	
	return err;
}

- (int) launchAuthPrgm
{
    AuthorizationFlags      authFlags;
    int						err;
	
	// path
	NSString * path = [[NSBundle mainBundle] executablePath];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath: path])
		return -1;
	
    // auth
    
	if (!_authRef)
	{
		err = [self preAuthorize];
		if (err != errAuthorizationSuccess)
			return err;
	}
	
    // launch
    
	// NSLog (@"MyWindowController: launchWithPath: ** calling AuthorizationExecuteWithPrivileges...**\n");
    authFlags = kAuthorizationFlagDefaults;
    err = AuthorizationExecuteWithPrivileges (_authRef, [path cString], authFlags, NULL, NULL);  
    if(err==0) [NSApp terminate:self];
	
    return err;
}

- (IBAction) applyChange:(id)sender
{
	NSNotificationCenter * defaultCenter=[NSNotificationCenter defaultCenter];
	
    [activateOldSP startAnimation:self];
    NSArray * argsOld1 = [[NSArray alloc] initWithObjects:@"write",@"/Library/Preferences/com.apple.AppleShareClient",@"afp_host_prefs_version", @"-int", @"1", NULL];
	NSTask * setOldOption1 = [[NSTask alloc] init];
	[setOldOption1 setCurrentDirectoryPath:@"/usr/bin/"];
	//[getName setEnvironment:env];
	[setOldOption1 setLaunchPath:@"/usr/bin/defaults"];
	[setOldOption1 setArguments:argsOld1];
	
	[setOldOption1 setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	/*NSPipe* outputPipe=[NSPipe pipe] ;
	 [getName setStandardOutput:outputPipe];
	 NSFileHandle *file;
	 file = [outputPipe fileHandleForReading];
	 */
	[setOldOption1 launch];
    [setOldOption1 waitUntilExit];
    
    NSArray * argsOld2 = [[NSArray alloc] initWithObjects:@"write",@"/Library/Preferences/com.apple.AppleShareClient",@"afp_disabled_uams", @"-array", @"Cleartxt Passwrd", @"MS2.0", @"2-Way Randnum exchange", NULL];
	NSTask * setOldOption2 = [[NSTask alloc] init];
	[setOldOption2 setCurrentDirectoryPath:@"/usr/bin/"];
	//[getName setEnvironment:env];
	[setOldOption2 setLaunchPath:@"/usr/bin/defaults"];
	[setOldOption2 setArguments:argsOld2];
	
	[setOldOption2 setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	/*NSPipe* outputPipe=[NSPipe pipe] ;
	 [getName setStandardOutput:outputPipe];
	 NSFileHandle *file;
	 file = [outputPipe fileHandleForReading];
	 */
	[setOldOption2 launch];
    [setOldOption2 waitUntilExit];
    
	[activateOldSP stopAnimation:self];
	[activateOld setImage:[NSImage imageNamed:@"ok16"]];
    
	[activateSP startAnimation:self];
	
	NSArray * args = [[NSArray alloc] initWithObjects:@"write",@"com.apple.systempreferences",@"TMShowUnsupportedNetworkVolumes", @"1", NULL];
	NSTask * setUnsupported = [[NSTask alloc] init];
	[setUnsupported setCurrentDirectoryPath:@"/usr/bin/"];
	//[getName setEnvironment:env];
	[setUnsupported setLaunchPath:@"/usr/bin/defaults"];
	[setUnsupported setArguments:args];
	
	[setUnsupported setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	/*NSPipe* outputPipe=[NSPipe pipe] ;
	 [getName setStandardOutput:outputPipe];
	 NSFileHandle *file;
	 file = [outputPipe fileHandleForReading];
	 */
	[setUnsupported launch];
    [setUnsupported waitUntilExit];
	
	[activateSP stopAnimation:self];
	[activate setImage:[NSImage imageNamed:@"ok16"]];
	[createSparseSP startAnimation:self];
	
	
	
	args = [[NSArray alloc] initWithObjects:@"create",@"-size",[NSString stringWithFormat:@"%i", sizeBundle], @"-type", @"SPARSEBUNDLE", @"-nospotlight", @"-volname", backupName, @"-fs", @"Case-sensitive Journaled HFS+", @"-verbose", bundleName, NULL];
	NSTask * createBundle = [[NSTask alloc] init];
	[createBundle setCurrentDirectoryPath:@"/usr/bin/"];
	//[getName setEnvironment:env];
	[createBundle setLaunchPath:@"/usr/bin/hdiutil"];
	[createBundle setArguments:args];
	
	[createBundle setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	NSPipe* outputPipe=[NSPipe pipe] ;
	[createBundle setStandardOutput:outputPipe];
	outputFileHandle=[[outputPipe fileHandleForReading] retain]; 
	
	
	NSPipe* errorPipe=[NSPipe pipe] ;
	[createBundle setStandardError:errorPipe];
	errorFileHandle=[[errorPipe fileHandleForReading] retain]; 
	
	[defaultCenter addObserver:self selector:@selector(taskDidStop:) name:NSTaskDidTerminateNotification object:createBundle];
	[createBundle launch];
	[outputFileHandle readInBackgroundAndNotify];
	//[createBundle waitUntilExit];
	
	/*NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSLog(@"%@",string);
	*/
}
	 

- (void)writeTaskInfo:(NSNotification*) notification {
	// The object of the notification is outputFilehandleNotification, so it is not necessary to retain it in runTask.
	NSData * data=[[notification userInfo] valueForKey:NSFileHandleNotificationDataItem];
	NSString * str=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSFileHandle * fileHandle=[notification object];
	if(fileHandle==outputFileHandle) {
		// append to outputTextView   
		//NSTextStorage * textStorage=[outputTextView textStorage];
		//[textStorage replaceCharactersInRange:NSMakeRange([textStorage length],0) withString:str];
		//NSLog(@"log = %@",standardLog);
		
		[self addToLog:str];
		
		
		[outputFileHandle readInBackgroundAndNotify];
		
	}
	if(fileHandle==errorFileHandle) {
		// append to outputTextView   
		//NSTextStorage * textStorage=[outputTextView textStorage];
		//[textStorage replaceCharactersInRange:NSMakeRange([textStorage length],0) withString:str];
		//NSLog(@"log = %@",standardLog);
		
		[self addToLog:str];
		
		
		[errorFileHandle readInBackgroundAndNotify];
		
	}
}

- (void)taskDidStop:(NSNotification*) notification{
	
	
	NSArray * args = [[NSArray alloc] initWithObjects:@"-R",@"777",bundleName, NULL];
	NSTask * setMod = [[NSTask alloc] init];
	[setMod setCurrentDirectoryPath:@"/bin/"];
	//[getName setEnvironment:env];
	[setMod setLaunchPath:@"/bin/chmod"];
	[setMod setArguments:args];
	
	[setMod setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	
	/*NSPipe* outputPipe=[NSPipe pipe] ;
	 [getName setStandardOutput:outputPipe];
	 NSFileHandle *file;
	 file = [outputPipe fileHandleForReading];
	 */
	[setMod launch];
    [setMod waitUntilExit];
	
	[createSparse setImage:[NSImage imageNamed:@"ok16"]];
	[createSparseSP stopAnimation:self];
	[self setBundleStatus:@""];
}

- (void)addToLog:(NSString*) add{
	[log setString:[[log string] stringByAppendingString:add]];
	NSArray * a = [add componentsSeparatedByString:@"\n"];
	NSString * s = [a objectAtIndex:[a count]-1];
	if([s length]<2 && [a count]>1) s = [a objectAtIndex:[a count]-2];
	[self setBundleStatus:s];
}

@end
