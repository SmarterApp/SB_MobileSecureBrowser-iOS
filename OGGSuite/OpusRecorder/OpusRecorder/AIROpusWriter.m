//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  OGGZWriter.m
//  OpusTesting
//
//  Created by Kenny Roethel on 4/16/13.
//

#import "AIROpusWriter.h"
#import <oggz/oggz.h>
#import "opus_header.h"
#import "opus_comment.h"

static const char *kOpusSpecificationVersion = "1";

@interface AIROpusWriter ()

@property (nonatomic) FILE *tempFile;
@property (assign) OGGZ *oggz;
@property (nonatomic, strong) AIROpusHeader *fileHeader;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *encoderName;
@property (nonatomic, assign) BOOL isPrepared;
@property (nonatomic, assign) int encodedGranulePosition;
@property (nonatomic, assign) int currentPacket;
@property (nonatomic, strong) NSMutableDictionary *serialIndexes;
@property (nonatomic, strong) NSOperationQueue *writerQueue;

@end

@implementation AIROpusWriter

- (id)initWithFileHeader:(AIROpusHeader*)header fileName:(NSString*)fileName encoderName:(NSString*)encoderName
{
    self = [super init];
    
    if(self)
    {
        self.fileName = fileName;
        self.sampleRate = 48000;
        self.serialIndexes = [[NSMutableDictionary alloc] init];
        
        [self configureTemporaryFile];
        [self removeFile];
        [self configureWriteQueue];
        
        self.encoderName = encoderName;
        self.fileHeader = header;
        self.currentPacket = -1;
        
        self.oggz = oggz_open_stdio(self.tempFile, OGGZ_WRITE);
    }
    
    return self;
}

- (void)configureWriteQueue
{
    self.writerQueue = [[NSOperationQueue alloc] init];
    self.writerQueue.maxConcurrentOperationCount = 1;
}

- (void)dealloc
{
    if(self.oggz)
        free(self.oggz);
}

- (void)prepare
{
    [self writeHeader];
    [self addDefaultComments];
    self.encodedGranulePosition = self.fileHeader.preskip;
    
    self.isPrepared = YES;
}

- (void)writeHeader
{
    NSAssert(self.isPrepared == NO, @"Attempting to write a header to an opus file more than once. Shame on you!");
    
    ogg_packet *op = [self.fileHeader newOGGPacket];
    
    oggz_write_feed(self.oggz, op, [self serialForStreamAtIndex:0], OGGZ_FLUSH_AFTER, NULL);
    
    oggz_packet_destroy(op);
}

- (void)addDefaultComments
{
    char *comments;
    int comments_length;
    
    comment_init(&comments, &comments_length, kOpusSpecificationVersion);
    comment_add(&comments, &comments_length, "ENCODER=", "AIRMobileiOS");
    
    ogg_packet op;
    op.packet=(unsigned char *)comments;
    op.bytes=comments_length;
    op.b_o_s=0;
    op.e_o_s=0;
    op.granulepos=0;
    op.packetno=1;
    
    oggz_write_feed(self.oggz, &op, [self serialForStreamAtIndex:0], OGGZ_FLUSH_AFTER, NULL);
    
    free(comments);
}

- (BOOL)configureTemporaryFile
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[self filePath:YES]];
    
    char const *path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:url.path];
    
    FILE *file = fopen(path, "wb");
    
    if(!file) NSLog(@"failed to open file %s",  path);
    
    self.tempFile = file;
    
    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
    
    NSError *error = nil;
    if(![[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:url.path error:&error])
    {
        NSLog(@"%@", error);
    }
    
    return file != nil;
}

- (void)writeEncodedData:(NSData *)encodedSamples encodedSampleCount:(int)sampleCount streamIndex:(int)streamIndex lastFrame:(BOOL)isLastFrame
{
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        
        NSError *error = nil;
        
        [self writeEncodedDataInternal:encodedSamples
                    encodedSampleCount:sampleCount
                           streamIndex:streamIndex
                             lastFrame:isLastFrame
                                 error:&error];
        
        if(error)
        {
            NSLog(@"Error Encoding %@", error);
        }
        
    }];
    
    [op setCompletionBlock:^{
        
        if(isLastFrame) [self finish];
        
    }];
    
    [self.writerQueue addOperation:op];
}

- (void)writeEncodedDataInternal:(NSData*)encodedSamples encodedSampleCount:(int)sampleCount streamIndex:(int)streamIndex lastFrame:(BOOL)isLastFrame error:(NSError**)writerError
{
    //NSAssert(self.isPrepared, @"You can not write audio data to disk until the file has been prepared. Make sure you call prepare before writeFrame", nil);
    
    if(self.isPrepared)
    {
        self.encodedGranulePosition += (sampleCount * 48000 / self.sampleRate);
        
        ogg_packet packet;
        
        [self configurePacket:&packet
                     withData:encodedSamples
                      granule:self.encodedGranulePosition
                 packetNumber: ++self.currentPacket + 2];
        
        packet.e_o_s = isLastFrame ? 1 : 0;
        
        long serial = [self serialForStreamAtIndex:streamIndex];
        
        int error = oggz_write_feed(self.oggz, &packet, serial, self.currentPacket == 0 ? OGGZ_FLUSH_BEFORE : OGGZ_FLUSH_AFTER, NULL);
        
        if(error != 0)
        {
            *writerError = [[NSError alloc] initWithDomain:@"AIROpusWriter" code:error userInfo:nil];
        }
        else
        {
            oggz_run(self.oggz);
        }
    }
}

- (void)endStream:(int)index
{
    ogg_packet packet;
    
    [self configurePacket:&packet
                 withData:nil
                  granule:self.encodedGranulePosition
             packetNumber: ++self.currentPacket + 2];
    
    packet.e_o_s = 1;
    
    long serial = [self serialForStreamAtIndex:index];
    
    int error = oggz_write_feed(self.oggz, &packet, serial, self.currentPacket == 0 ? OGGZ_FLUSH_BEFORE : OGGZ_FLUSH_AFTER, NULL);
    
    if(error != 0)
    {}
    else
    {
        oggz_run(self.oggz);
    }
    [self finish];

}
- (void)configurePacket:(ogg_packet*)packet
               withData:(NSData*)encodedSamples
                granule:(long)granulePos
           packetNumber:(long)packetNo
{
    packet->b_o_s = 0;
    packet->packet = (unsigned char*)encodedSamples.bytes;
    packet->bytes = encodedSamples.length;
    packet->granulepos = granulePos;
    packet->packetno = packetNo;
}

- (long)serialForStreamAtIndex:(int)index
{
    @synchronized(self)
    {
        NSNumber *serial = [self.serialIndexes objectForKey:@(index)];
        
        if(!serial)
        {
            long value = [self createNewSerial];
            
            serial = [[NSNumber alloc] initWithLong:value];
            
            [self.serialIndexes setObject:serial forKey:@(index)];
        }
        
        return [serial longValue];
    }
}

- (void)finish
{
    self.isPrepared = NO;
    
    int n = oggz_run(self.oggz);
    
    if(n < 0) NSLog(@"OGGZ Run Error Occured: %i", n);
    
    oggz_close(self.oggz);
    fclose(self.tempFile);
    
    self.oggz = nil;
    
    [self copyTempFile];
    [self removeTempFile];
}

#pragma mark - File Managing

- (void)copyTempFile
{
    NSError *error = nil;
    
    NSString *tempPath = [self filePath:YES];
    NSString *truePath = [self filePath:NO];
    
    [[NSFileManager defaultManager] copyItemAtPath:tempPath toPath:truePath error:&error];
   
    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];

    if(![[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:truePath error:&error])
    {
        NSLog(@"%@", error);
    }
    
    if(error)
    {
        NSLog(@"Error Copying File %@", error);
    }
}

- (void)removeTempFile
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self filePath:YES] error:&error];
    
    if(error)
    {
        NSLog(@"Error Removing Temp File %@", error);
    }
}

- (void)removeFile
{
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:[self filePath:NO] error:&error];
    
    if(error)
    {
        NSLog(@"Error Removing File %@", error);
    }
}

- (NSString*)filePath:(BOOL)isTemp
{
    NSString *path = [AIROpusWriter fileStoragePath];
    NSString *filename = [NSString stringWithFormat:@"%@%@", self.fileName, isTemp ? @".temp" : @""];
   
    return [path stringByAppendingPathComponent:filename];
    
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:filename];
    
    return url.path;
}

+ (NSString*)fileStoragePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [paths objectAtIndex:0];
    NSString *bundlePath = [libraryPath stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    bundlePath = [bundlePath stringByAppendingPathComponent:@"audio"];
   
    if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:bundlePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return bundlePath;
}

- (long)createNewSerial
{
    return oggz_serialno_new(self.oggz);
}

@end
