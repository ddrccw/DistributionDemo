//
//  ViewController.m
//  DistributionDemo
//
//  Created by ddrccw on 14-4-13.
//  Copyright (c) 2014年 ddrccw. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>

@interface ViewController ()<UIAlertViewDelegate>
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (copy, nonatomic) NSString *fakeVersion;
@property (strong, nonatomic) NSNumber *fakeBuildNumber;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
#warning replace your own url
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://192.168.0.109:8881/DistributionDemo"]];
    NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:[self.manager.responseSerializer acceptableContentTypes]];
    [acceptableContentTypes addObject:@"text/plain"];
    self.manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    
    self.fakeVersion = @"0.9.0";
    self.fakeBuildNumber = @1;
    [self.manager POST:@"check" parameters:@{@"v": self.fakeVersion,
                                             @"b": self.fakeBuildNumber}
               success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"有新发布的测试版app哟：）~~"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
        [alert show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        NSString *deployServer = @"192.168.0.109:8881";
        NSString *reqUrl = nil;
//        reqUrl = [NSString stringWithFormat:@"http://%@/DistributionDemo?v=%@&b=%@", deployServer, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        reqUrl = [NSString stringWithFormat:@"http://%@/DistributionDemo?v=%@&b=%@", deployServer, self.fakeVersion, self.fakeBuildNumber];
        NSString *serviceUrl = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [self urlEncodeOfUrl:reqUrl]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:serviceUrl]];
    }

}

- (NSString *)urlEncodeOfUrl:(NSString *)url {
    NSString *newString = (__bridge_transfer NSString *)(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                (__bridge CFStringRef)url,
                                                                                NULL,
                                                                                CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                                                CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
	if (newString) {
		return newString;
	}
	return @"";
}


@end
