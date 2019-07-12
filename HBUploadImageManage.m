//
//  HBUploadImageManage.m
//  HBTreasureMaterial
//
//  Created by 胡明波 on 2018/12/10.
//  Copyright © 2018年 humingbo. All rights reserved.
//

#import "HBUploadImageManage.h"
#import <AliyunOSSiOS/OSSService.h>
@implementation HBUploadImageManage
//需要的一些基本信息
static NSString *const AccessKey = @"";
static NSString *const SecretKey = @"";
static NSString *const BucketName = @"";
static NSString *const AliYunHost = @"";
static NSString *kTempFolder = @"";
static NSString *rootUrl = @"";


+ (void)asyncUploadImage:(UIImage *)image progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names,UploadImageState state))complete
{
    [self uploadImages:@[image] isAsync:YES progress:progressBlock complete:complete];
}

+ (void)syncUploadImage:(UIImage *)image progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names,UploadImageState state))complete
{
    [self uploadImages:@[image] isAsync:NO progress:progressBlock complete:complete];
}

+ (void)asyncUploadImages:(NSArray<UIImage *> *)images progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete
{
    [self uploadImages:images isAsync:YES progress:progressBlock complete:complete];
}

+ (void)syncUploadImages:(NSArray<UIImage *> *)images progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete
{
    [self uploadImages:images isAsync:NO progress:progressBlock complete:complete];
}

+ (void)uploadImages:(NSArray<UIImage *> *)images isAsync:(BOOL)isAsync  progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete
{
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey                                                                                                            secretKey:SecretKey];
    
    OSSClient *client = [[OSSClient alloc] initWithEndpoint:AliYunHost credentialProvider:credential];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = images.count;
    
    NSMutableArray *callBackNames = [NSMutableArray array];
    int i = 0;
    for (UIImage *image in images) {
        if (image) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                //任务执行
                OSSPutObjectRequest * put = [OSSPutObjectRequest new];
                put.bucketName = BucketName;
                put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
                    // 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
                    NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
                    if (progressBlock) {
                        progressBlock(bytesSent,totalByteSent,totalBytesExpectedToSend);
                    }
                };
                //文件路径及名称拼接
                NSString *imageName = [kTempFolder stringByAppendingPathComponent:[[NSUUID UUID].UUIDString stringByAppendingString:@".jpg"]];
                put.objectKey = imageName;
                put.contentType = @"image/jpeg";
                //拼接URL
                NSString *urlStr = [NSString stringWithFormat:@"%@%@",rootUrl,imageName];
                //添加到数组回传
                [callBackNames addObject:urlStr];
                
                //上传date
                //NSData *data = UIImageJPEGRepresentation(image, 0.3);
                NSData *data = [self imageData:image];
                put.uploadingData = data;
                // 阻塞直到上传完成
                OSSTask * putTask = [client putObject:put];
                [putTask waitUntilFinished];
                
                if (!putTask.error) {
                    NSLog(@"upload object success!");
                    NSLog(@"打印图片地址:%@",urlStr);
                } else {
                    [callBackNames removeAllObjects];
                    if (complete) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //返回主线程
                            complete([NSArray arrayWithArray:callBackNames], UploadImageFailed);
                        });
                    }
                }
                if (isAsync) {
                    if (image == images.lastObject) {
                        NSLog(@"upload object finished!");
                        if (complete) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //返回主线程
                                complete([NSArray arrayWithArray:callBackNames], UploadImageSuccess);
                            });
                        }
                    }
                }
            }];
            if (queue.operations.count != 0) {
                [operation addDependency:queue.operations.lastObject];
            }
            [queue addOperation:operation];
        }
        i++;
    }
    if (!isAsync) {
        [queue waitUntilAllOperationsAreFinished];
        NSLog(@"haha");
        if (complete) {
            if (complete) {
                //返回主线程
                dispatch_async(dispatch_get_main_queue(), ^{
                    //返回主线程
                    complete([NSArray arrayWithArray:callBackNames], UploadImageSuccess);
                });
                
            }
        }
    }
}

+(NSData *)imageData:(UIImage *)myimage
{
    NSData *data=UIImageJPEGRepresentation(myimage, 1.0);
    if (data.length>100*1024) {
        if (data.length>1024*1024) {//1M以及以上
            //            data = [self compressImage:myimage toMaxFileSize:512*1024/5];
            data=[self resetSizeOfImageData:myimage maxSize:512*1024/5];
            //            data=UIImageJPEGRepresentation(myimage, 0.1);
        }else if (data.length>512*1024) {//0.5M-1M
            data=UIImageJPEGRepresentation(myimage, 0.5);
        }else if (data.length>200*1024) {//0.25M-0.5M
            data=UIImageJPEGRepresentation(myimage, 0.9);
        }
    }
    
    return data;
}
//压缩图片处理（先调整分辨率）
+(NSData*)resetSizeOfImageData:(UIImage*)sourceImage maxSize:(NSInteger)maxSize
{
    //优先调整分辨率
    
    CGSize newSize=CGSizeMake(sourceImage.size.width, sourceImage.size.height);
    
    CGFloat tempHeight=newSize.height/1024;
    
    CGFloat tempWidth=newSize.width/1024;
    
    //    if (tempWidth>1.0&&tempWidth>tempHeight) {
    
    newSize=CGSizeMake(sourceImage.size.width/tempWidth, sourceImage.size.height/tempHeight);
    
    //    }
    
    UIGraphicsBeginImageContext(newSize);
    
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    //再调整大小
    
    NSData *imageData=UIImageJPEGRepresentation(newImage, 0.4);
    
    NSUInteger sizeOrigin=[imageData length];
    
    NSUInteger sizeOriginKB=sizeOrigin/1024;
    
    if (sizeOriginKB>maxSize) {
        
        NSData *finalImageData=UIImageJPEGRepresentation(newImage, 0.5);
        
        return finalImageData;
    }
    //NSLog(@"#####***%lu",(unsigned long)imageData.length);
    return imageData;
}
+ (void)asyncUploadVideo:(NSData *)data progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete{
    [self uploadVideo:data isAsync:YES progress:progressBlock complete:complete];
}
+ (void)syncUploadVideo:(NSData *)data progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete{
    [self uploadVideo:data isAsync:NO progress:progressBlock complete:complete];
}
/// 上传视频
+ (void)uploadVideo:(NSData *)data isAsync:(BOOL)isAsync progress:(HBUploadImageManageProgressBlock)progressBlock complete:(void(^)(NSArray<NSString *> *names, UploadImageState state))complete{
    
        // 2
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey                                                                                                            secretKey:SecretKey];
        //id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:AccessKey secretKeyId:SecretKey securityToken:OSSAuth.securityToken];
        
        OSSClient *client = [[OSSClient alloc] initWithEndpoint:AliYunHost credentialProvider:credential];
        
        //任务执行
        OSSPutObjectRequest * put = [OSSPutObjectRequest new];
        put.bucketName = BucketName;
        put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        // 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
        //NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
            if (progressBlock) {
                progressBlock(bytesSent,totalByteSent,totalBytesExpectedToSend);
            }
    };
    
        NSString *imageName = [NSString stringWithFormat:@"%@%@.mp4", kTempFolder,[NSUUID UUID].UUIDString];
        put.objectKey = imageName;
        
        // 3
        // 传出url
       NSMutableArray *callBackNames = [NSMutableArray array];
        NSString *imageUrl = [NSString stringWithFormat:@"%@/%@", rootUrl,imageName];
        NSLog(@"打印视频URL:%@",imageUrl);
        //添加到数组回传
        [callBackNames addObject:imageUrl];
        put.uploadingData = data;
        
    
        OSSTask * putTask = [client putObject:put];
        [putTask continueWithBlock:^id(OSSTask *task) {
        task = [client presignPublicURLWithBucketName:BucketName
                                        withObjectKey:imageName];
        
            //返回主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                //返回主线程
                if (!task.error) {
                    NSLog(@"upload object success!");
                    if (complete) {
                        complete([NSArray arrayWithArray:callBackNames], UploadImageSuccess);
                    }
                } else {
                    NSLog(@"upload object failed, error: %@" , putTask.error);
                    if (complete) {
                        complete([NSArray arrayWithArray:callBackNames], UploadImageFailed);
                    }
                }
            });
        return nil;
    }];
   
    
}
@end
