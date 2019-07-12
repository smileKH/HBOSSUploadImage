//
//  HBUploadImageManage.h
//  HBTreasureMaterial
//
//  Created by 胡明波 on 2018/12/10.
//  Copyright © 2018年 humingbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UploadImageState) {
    UploadImageFailed   = 0,
    UploadImageSuccess  = 1
};
// 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
typedef void(^HBUploadImageManageProgressBlock)(int64_t bytesSent, int64_t totalByteSent ,int64_t totalBytesExpectedToSend);

@interface HBUploadImageManage : NSObject
//异步上传单张图片
+ (void)asyncUploadImage:(UIImage *)image progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names,UploadImageState state))complete;
//同步上传单张图片
+ (void)syncUploadImage:(UIImage *)image progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names,UploadImageState state))complete;
//异步上传多张图片
+ (void)asyncUploadImages:(NSArray<UIImage *> *)images progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete;
//同步上传多张图片
+ (void)syncUploadImages:(NSArray<UIImage *> *)images  progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete;
//异步单个上传视频
+ (void)asyncUploadVideo:(NSData *)data progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete;
//同步单个上传视频
+ (void)syncUploadVideo:(NSData *)data progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete;
@end
