//
//  DSMainViewController.m
//  VideoGenie
//
//  Created by Benjamin Bader on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DSMainViewController.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>

#import "GData.h"
#import "GDataServiceGoogleYouTube.h"
#import "GDataEntryYouTubeUpload.h"

#define YOUTUBE_DEV_KEY @"AI39si7wCwt1cPeXsR3oSDiipkfsZo5_qoOYhFR5DzKvJmYbaRiRFMOMp70mYd9WSKSQbgv8aTXPzkcund2NvC_phTjNF0AFxQ"
#define YOUTUBE_CLIENT_ID @"reafchyou0930"
#define YOUTUBE_USERNAME @"reachoo"
#define YOUTUBE_PASSWORD @"reachyou0930"


static NSString *kDSMainWindowProgressNotification = @"DSMainWindowUploadMadeProgress";
static NSString *kDSMainWindowUploadCompleted = @"DSMainWindowUploadCompleted";

@interface DSMainViewController ()

-(void) uploadVideo:(NSString*)path;
-(void) uploadFinished:(NSNotification*)notification;
-(void) progressMade:(NSNotification*)notification;

-(GDataServiceGoogleYouTube*) youTube;

@property (retain) NSURL *uploadLocationUrl;
@property (retain) GDataServiceTicket *uploadTicket;

@end

@implementation DSMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(void) dealloc
{
    self.progressView = nil;
    self.uploadLocationUrl = nil;
    self.uploadTicket = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDSMainWindowProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDSMainWindowUploadCompleted object:nil];
    
    [super dealloc];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.buttonChooseVideo setImage:[UIImage imageNamed:@"dbutton2.png"] forState:UIControlStateHighlighted];
    
    UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:@"Upload A Video"];
    [[self.navigationController navigationBar] pushNavigationItem:title animated:NO];
    [title release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - PrivateMethods Implementation

-(void) uploadVideo:(NSString *)filePath
{
    GDataServiceGoogleYouTube *service = [self youTube];
    
    [service setUserCredentialsWithUsername:@"reachoo" password:@"reachyou0930"];
    
    NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID:kGDataServiceDefaultUser];
    
    NSError *err = nil;
    __block NSFileHandle *tempFile = [NSFileHandle fileHandleForUpdatingURL:url error:err];
    
    NSData *fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:filePath]];
    NSString *fileName = [filePath lastPathComponent];
    NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:filePath defaultMIMEType:@"video/mp4"];
    
    NSString *title = fileName;
    GDataMediaTitle *mediaTitle = [GDataMediaTitle textConstructWithString:title];
    
    GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
    
    mediaGroup.mediaTitle = mediaTitle;
    mediaGroup.mediaDescription = [GDataMediaDescription textConstructWithString:@"An Interview Video"];
    mediaGroup.mediaCategories = [NSArray arrayWithObject:[GDataMediaCategory mediaCategoryWithString:@"Entertainment"]];
    mediaGroup.mediaKeywords = [GDataMediaKeywords keywordsWithString:@"DesignThinking"];
    mediaGroup.isPrivate = NO;
    
    GDataEntryYouTubeUpload *entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                                                                   data:fileData
                                                                               MIMEType:mimeType
                                                                                   slug:fileName];
    
    service.serviceUploadProgressHandler = ^(GDataServiceTicketBase *ticket, unsigned long long bytesRead, unsigned long long bytesTotal)
    {
        float progress = (float)bytesRead / (float)bytesTotal;
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:progress] forKey:@"progress"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDSMainWindowProgressNotification object:nil userInfo:userInfo];
    };
    
    GDataServiceTicket *ticket = [service fetchEntryByInsertingEntry:entry
                                                          forFeedURL:url
                                                   completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
                                                       NSLog(@"Upload finished!");
                                                       
                                                       NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
                                                       
                                                       if (entry)
                                                       {
                                                           [userInfo setObject:entry forKey:@"entry"];
                                                       }
                                                       
                                                       if (error)
                                                       {
                                                           [userInfo setObject:error forKey:@"error"];
                                                       }
                                                       
                                                       @try {
                                                           NSError *writeError;
                                                           NSFileManager *fm = [NSFileManager defaultManager];
                                                           
                                                           if (![fm removeItemAtURL:url error:&writeError])
                                                           {
                                                               
                                                           }
                                                           else
                                                           {
                                                               NSLog(@"Couldn't clean up the temporary file: %@", [writeError localizedDescription]);
                                                           }
                                                       }
                                                       @catch (NSException *exception) {
                                                           
                                                       }
                                                       
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:kDSMainWindowUploadCompleted
                                                                                                           object:nil
                                                                                                         userInfo:userInfo];
                                                   }];
    
    self.uploadTicket = ticket;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressMade:) name:kDSMainWindowProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kDSMainWindowUploadCompleted object:nil];
}

-(void) progressMade:(NSNotification *)notification
{
    NSLog(@"Received progress notification.");
    
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *progressNumber = [userInfo objectForKey:@"progress"];
    
    [self.progressView setProgress:[progressNumber floatValue] animated:YES];
}

-(void) uploadFinished:(NSNotification *)notification
{
    
    NSDictionary *userInfo = [notification userInfo];
    NSError *error = [userInfo objectForKey:@"error"];
    GDataEntryYouTubeVideo *entry = [userInfo objectForKey:@"entry"];
    
    if (error)
    {
        // report error
        NSString *message = [error localizedDescription];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        [alert release];
    }
    else
    {
        
        // TODO: DO NOT IGNORE THIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // TODO: Post to app!
        
        NSString *videoId = [[entry identifier] substringFromIndex:[[entry identifier] rangeOfString:@"video:"].location+6];
        NSURL *postUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://smooth-moon-1796.herokuapp.com/interviews/upload_video?email=alexle@marrily.com&video_id=%@", videoId]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postUrl];
        [request setHTTPMethod:@"POST"];
        
        NSURLResponse *response = nil;
        NSError *responseError = nil;
        
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
        
        if (responseError)
        {
            NSLog(@"Error posting uploaded video to DSchool: %@", [responseError localizedDescription]);
        }
        else
        {
            NSLog(@"Successfully posted video to DSchool.");
            NSLog(@"%@", [NSString stringWithUTF8String:[returnData bytes]]);
            
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDSMainWindowProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDSMainWindowUploadCompleted object:nil];
}

-(GDataServiceGoogleYouTube*) youTube
{
    static GDataServiceGoogleYouTube *service = nil;
    
    if (!service)
    {
        service = [[GDataServiceGoogleYouTube alloc] init];
        
        service.shouldCacheResponseData = YES;
        service.serviceShouldFollowNextLinks = YES;
        service.isServiceRetryEnabled = YES;
    }
    
    [service setYouTubeDeveloperKey:YOUTUBE_DEV_KEY];
    [service setUserCredentialsWithUsername:YOUTUBE_USERNAME password:YOUTUBE_PASSWORD];
    
    return service;
}

-(void) chooseVideo
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString*)kUTTypeMovie];
    
    NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
    
    if (![sourceTypes containsObject:(NSString*)kUTTypeMovie])
    {
        NSLog(@"No video!");
    }
    else
    {
        [self presentModalViewController:picker animated:YES];
    }
    
    [picker release];
}

#pragma mark - UIImagePickerControllerDelegate Implementation

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"Image picker did select some media.");
    
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    
    NSLog(@"Media type: %@", type);
    
    if ([type isEqualToString:(NSString*)kUTTypeMovie] || [type isEqualToString:(NSString*)kUTTypeVideo])
    {
        NSLog(@"Selected media is a video; uploading it now.");
        
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        [self uploadVideo:videoUrl.absoluteString];
    }
    
    [picker dismissModalViewControllerAnimated:YES];
}

@synthesize uploadLocationUrl;
@synthesize uploadTicket;
@synthesize progressView;
@synthesize buttonChooseVideo;

@end