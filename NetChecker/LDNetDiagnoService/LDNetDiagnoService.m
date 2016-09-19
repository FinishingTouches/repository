//
//  LDNetDiagnoService.m
//  LDNetDiagnoServieDemo
//
//  Created by 庞辉 on 14-10-29.
//  Copyright (c) 2014年 庞辉. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "LDNetDiagnoService.h"
#import "LDNetPing.h"
#import "LDNetTraceRoute.h"
#import "LDNetGetAddress.h"
#import "LDNetTimer.h"
#import "LDNetConnect.h"

static NSString *const kPingOpenServerIP = @"";
static NSString *const kCheckOutIPURL = @"";

@interface LDNetDiagnoService () <LDNetPingDelegate, LDNetTraceRouteDelegate,
                                  LDNetConnectDelegate> {
    NSString *_appCode;  //客户端标记
    NSString *_appName;
    NSString *_appVersion;
    NSString *_UID;       //用户ID
    NSString *_deviceID;  //客户端机器ID，如果不传入会默认取API提供的机器ID
    NSString *_carrierName;
    NSString *_ISOCountryCode;
    NSString *_MobileCountryCode;
    NSString *_MobileNetCode;

    NETWORK_TYPE _curNetType;
    NSString *_localIp;
    NSString *_gatewayIp;
    NSArray *_dnsServers;
    NSArray *_hostAddress;

    NSMutableString *_logInfo;  //记录网络诊断log日志
    BOOL _isRunning;
    BOOL _connectSuccess;  //记录连接是否成功
    LDNetPing *_netPinger;
    LDNetTraceRoute *_traceRouter;
    LDNetConnect *_netConnect;
}

@end

@implementation LDNetDiagnoService
#pragma mark - public method
/**
 * 初始化网络诊断服务
 */
- (id)initWithAppCode:(NSString *)theAppCode
              appName:(NSString *)theAppName
           appVersion:(NSString *)theAppVersion
               userID:(NSString *)theUID
             deviceID:(NSString *)theDeviceID
              dormain:(NSString *)theDormain
          carrierName:(NSString *)theCarrierName
       ISOCountryCode:(NSString *)theISOCountryCode
    MobileCountryCode:(NSString *)theMobileCountryCode
        MobileNetCode:(NSString *)theMobileNetCode
{
    self = [super init];
    if (self) {
        _appCode = theAppCode;
        _appName = theAppName;
        _appVersion = theAppVersion;
        _UID = theUID;
        _deviceID = theDeviceID;
        _dormain = theDormain;
        _carrierName = theCarrierName;
        _ISOCountryCode = theISOCountryCode;
        _MobileCountryCode = theMobileCountryCode;
        _MobileNetCode = theMobileNetCode;

        _logInfo = [[NSMutableString alloc] initWithCapacity:20];
        _isRunning = NO;
    }

    return self;
}

- (void)traceroute {
    _curNetType = [LDNetGetAddress getNetworkTypeFromStatusBar];
    if (_curNetType == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"\n\tNot networking"]];
        return;
    }
    
    if (_traceRouter && _traceRouter.isRunning) {
        [_traceRouter stopTrace];
        return;
    }
    
    //开始诊断traceRoute
    [self recordStepInfo:[NSString stringWithFormat:@"\n\nDomain: %@...\n", _dormain]];
    _traceRouter = [[LDNetTraceRoute alloc] initWithMaxTTL:TRACEROUTE_MAX_TTL
                                                   timeout:TRACEROUTE_TIMEOUT
                                               maxAttempts:TRACEROUTE_ATTEMPTS
                                                      port:TRACEROUTE_PORT];
    _traceRouter.delegate = self;
    if (_traceRouter) {
        [NSThread detachNewThreadSelector:@selector(doTraceRoute:)
                                 toTarget:_traceRouter
                               withObject:_dormain];
    }
}

- (void)DNSAnalysis {
    _curNetType = [LDNetGetAddress getNetworkTypeFromStatusBar];
    if (_curNetType == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"\n\tNot networking"]];
        return;
    }
    
    [self recordStepInfo:[NSString stringWithFormat:@"\n\nDomain: %@...\n", _dormain]];
    
    // host地址IP列表
    long time_start = [LDNetTimer getMicroSeconds];
    _hostAddress = [NSArray arrayWithArray:[LDNetGetAddress getDNSsWithDormain:_dormain]];
    long time_duration = [LDNetTimer computeDurationSince:time_start] / 1000;
    if ([_hostAddress count] == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"DNS Analysis: Analysis Defeat"]];
    } else {
        [self
         recordStepInfo:[NSString stringWithFormat:@"DNS Analysis: %@ (%ldms)",
                         [_hostAddress componentsJoinedByString:@", "],
                         time_duration]];
    }
}

- (void)localAnalysis {
    [self recordLocalNetEnvironment];
}

/**
 * 打印整体loginInfo；
 */
- (void)printLogInfo
{
    NSLog(@"\n%@\n", _logInfo);
}


#pragma mark -
#pragma mark - private method

/*!
 *  @brief  获取本地网络环境信息
 */
- (void)recordLocalNetEnvironment
{
    //输出应用版本信息和用户ID
    //    [self recordStepInfo:[NSString stringWithFormat:@"应用code: %@", _appCode]];
    NSDictionary *dicBundle = [[NSBundle mainBundle] infoDictionary];
    
    if (!_appName || [_appName isEqualToString:@""]) {
        _appName = [dicBundle objectForKey:@"CFBundleDisplayName"];
    }
    [self recordStepInfo:[NSString stringWithFormat:@"\nAppName: \n\t%@\n", _appName]];
    
    if (!_appVersion || [_appVersion isEqualToString:@""]) {
        _appVersion = [dicBundle objectForKey:@"CFBundleShortVersionString"];
    }
    //    [self recordStepInfo:[NSString stringWithFormat:@"应用版本: %@", _appVersion]];
    //    [self recordStepInfo:[NSString stringWithFormat:@"用户id: %@", _UID]];
    
    //输出机器信息
    UIDevice *device = [UIDevice currentDevice];
    [self recordStepInfo:[NSString stringWithFormat:@"SystemName: \n\t%@\n", [device systemName]]];
    [self recordStepInfo:[NSString stringWithFormat:@"SystemVersion: \n\t%@\n", [device systemVersion]]];
    if (!_deviceID || [_deviceID isEqualToString:@""]) {
        _deviceID = [self uniqueAppInstanceIdentifier];
    }
    [self recordStepInfo:[NSString stringWithFormat:@"Device_ID: \n\t%@\n", _deviceID]];
    
    
    //运营商信息
    if (!_carrierName || [_carrierName isEqualToString:@""]) {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        if (carrier != NULL) {
            _carrierName = [carrier carrierName];
            _ISOCountryCode = [carrier isoCountryCode];
            _MobileCountryCode = [carrier mobileCountryCode];
            _MobileNetCode = [carrier mobileNetworkCode];
            
            [self recordStepInfo:[NSString stringWithFormat:@"CarrierName: \n\t%@\n", _carrierName]];
            [self recordStepInfo:[NSString stringWithFormat:@"ISOCountryCode: \n\t%@\n", _ISOCountryCode]];
            [self recordStepInfo:[NSString stringWithFormat:@"MobileCountryCode: \n\t%@\n", _MobileCountryCode]];
            [self recordStepInfo:[NSString stringWithFormat:@"MobileNetworkCode: \n\t%@\n", _MobileNetCode]];
        }
    }
    
    NSArray *typeArr = [NSArray arrayWithObjects:@"2G", @"3G", @"4G", @"5G", @"wifi", nil];
    _curNetType = [LDNetGetAddress getNetworkTypeFromStatusBar];
    if (_curNetType == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"HasNet: \n\tNO\n"]];
    } else {
        [self recordStepInfo:[NSString stringWithFormat:@"HasNet: \n\tYES\n"]];
        if (_curNetType > 0 && _curNetType < 6) {
            [self
                recordStepInfo:[NSString stringWithFormat:@"NetType: \n\t%@\n",
                                                          [typeArr objectAtIndex:_curNetType - 1]]];
        }
    }

    //本地ip信息
    _localIp = [LDNetGetAddress deviceIPAdress];
    [self recordStepInfo:[NSString stringWithFormat:@"Local_IP: \n\t%@\n", _localIp]];

    if (_curNetType == NETWORK_TYPE_WIFI) {
        _gatewayIp = [LDNetGetAddress getGatewayIPAddress];
        [self recordStepInfo:[NSString stringWithFormat:@"Gateway_IP: \n\t%@\n", _gatewayIp]];
    } else {
        _gatewayIp = @"";
    }
    
    _dnsServers = [NSArray arrayWithArray:[LDNetGetAddress outPutDNSServers]];
    [self recordStepInfo:[NSString stringWithFormat:@"Local_DNS: \n\t%@\n",
                          [_dnsServers componentsJoinedByString:@", "]]];
}


#pragma mark -
#pragma mark - netPingDelegate

- (void)appendPingLog:(NSString *)pingLog
{
    [self recordStepInfo:pingLog];
}

- (void)netPingDidEnd
{
    // net
}

#pragma mark - traceRouteDelegate
- (void)appendRouteLog:(NSString *)routeLog
{
    [self recordStepInfo:routeLog];
}

- (void)traceRouteDidEnd
{
    _isRunning = NO;
    [self recordStepInfo:@"\nEnd\n"];
    if (self.delegate && [self.delegate respondsToSelector:@selector(netDiagnosisDidEnd:)]) {
        [self.delegate netDiagnosisDidEnd:_logInfo];
    }
}

#pragma mark - connectDelegate
- (void)appendSocketLog:(NSString *)socketLog
{
    [self recordStepInfo:socketLog];
}

- (void)connectDidEnd:(BOOL)success
{
    if (success) {
        _connectSuccess = YES;
    }
}


#pragma mark - common method
/**
 * 如果调用者实现了stepInfo接口，输出信息
 */
- (void)recordStepInfo:(NSString *)stepInfo
{
    if (stepInfo == nil) stepInfo = @"";
    [_logInfo appendString:stepInfo];
    [_logInfo appendString:@"\n"];

    if (self.delegate && [self.delegate respondsToSelector:@selector(netDiagnosisStepInfo:)]) {
        [self.delegate netDiagnosisStepInfo:[NSString stringWithFormat:@"%@\n", stepInfo]];
    }
}


/**
 * 获取deviceID
 */
- (NSString *)uniqueAppInstanceIdentifier
{
    NSString *app_uuid = @"";
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    app_uuid = [NSString stringWithString:(__bridge NSString *)uuidString];
    CFRelease(uuidString);
    CFRelease(uuidRef);
    return app_uuid;
}


@end
