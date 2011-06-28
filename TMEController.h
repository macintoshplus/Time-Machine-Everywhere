//
//  TMEController.h
//
//  Created by Jean-Baptiste Nahan on 17/01/11.
//  Copyright 2011 Jean-Baptiste Nahan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TMEController : NSObject {

	NSString * macAddress;
	NSString * hostName;
	NSString * backupName;
	NSString * bundleName;
	NSString * bundleStatus;
	int sizeBundle;
	
	IBOutlet NSImageView * activate;
	IBOutlet NSProgressIndicator * activateSP;
	IBOutlet NSImageView * createSparse;
	IBOutlet NSProgressIndicator * createSparseSP;
	IBOutlet NSTextView * log;
	IBOutlet NSWindow * winLog;
	IBOutlet NSWindow * winMain;
	
	
    AuthorizationRef                _authRef;
    AuthorizationItem               _authItem;
    AuthorizationRights             _authRights;
	
	NSFileHandle *outputFileHandle;
	NSFileHandle *errorFileHandle;
	
}

@property (retain) NSString * macAddress;
@property (retain) NSString * hostName;
@property (retain) NSString * backupName;
@property (retain) NSString * bundleName;
@property (retain) NSString * bundleStatus;
@property (assign) int sizeBundle;


- (int) preAuthorize;
- (int) launchAuthPrgm;

- (IBAction) applyChange:(id)sender;
- (void)writeTaskInfo:(NSNotification*) notification;
- (void)taskDidStop:(NSNotification*) notification;
- (void)addToLog:(NSString*) add;


@end
