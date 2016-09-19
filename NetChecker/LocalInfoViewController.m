//
//  LocalInfoViewController.m
//  NetChecker
//
//  Created by 徐凌峰 on 16/9/14.
//  Copyright © 2016年 wangmi. All rights reserved.
//

#import "LocalInfoViewController.h"

@interface LocalInfoViewController () <UITextViewDelegate, LDNetDiagnoServiceDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) LDNetDiagnoService *netDiagnoService;

@property (nonatomic, copy) NSString *logInfo;

@end

@implementation LocalInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _textView.editable = NO;
    
    _netDiagnoService = [[LDNetDiagnoService alloc] initWithAppCode:@"test"
                                                            appName:@"NetChecker"
                                                         appVersion:nil
                                                             userID:nil
                                                           deviceID:nil
                                                            dormain:nil
                                                        carrierName:nil
                                                     ISOCountryCode:nil
                                                  MobileCountryCode:nil
                                                      MobileNetCode:nil];
    _logInfo = @"";
    _netDiagnoService.delegate = self;
    [_netDiagnoService localAnalysis];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark NetDiagnosisDelegate

- (void)netDiagnosisStepInfo:(NSString *)stepInfo
{
    NSLog(@"%@", stepInfo);
    self.logInfo = [self.logInfo stringByAppendingString:stepInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = self.logInfo;
    });
}

- (void)netDiagnosisDidEnd:(NSString *)allLogInfo;
{
    NSLog(@"logInfo>>>>>\n%@", allLogInfo);
    //可以保存到文件，也可以通过邮件发送回来
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

#pragma mark -- textViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
}

@end
