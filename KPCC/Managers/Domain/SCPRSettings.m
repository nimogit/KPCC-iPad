//
//  SCPRSettings.m
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSettings.h"

@implementation SCPRSettings


- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeFloat:self.playerVolume
               forKey:@"playerVolume"];
  [aCoder encodeBool:self.playerMinimized
              forKey:@"playerMinimized"];
  [aCoder encodeObject:self.lastCacheCleanDate
                forKey:@"lastCacheCleanDate"];
  [aCoder encodeObject:self.deviceID
                forKey:@"deviceID"];
  [aCoder encodeObject:self.lastKnownConnectionType
                forKey:@"lastKnownConnectionType"];
  [aCoder encodeObject:self.currentlyPlaying
                forKey:@"currentlyPlaying"];
  [aCoder encodeObject:self.userFacebookInformation
                forKey:@"userFacebookInformation" ];
  [aCoder encodeObject:self.profileImageURL
                forKey:@"profileImageURL"];
  [aCoder encodeObject:self.twitterInformation
                forKey:@"twitterInformation"];
  [aCoder encodeObject:self.linkedInToken
                forKey:@"linkedInToken"];
  [aCoder encodeObject:self.linkedInTokenExpire
                forKey:@"linkedInTokenExpire"];
  [aCoder encodeObject:self.linkedInInformation
                forKey:@"linkedInInformation"];
  [aCoder encodeBool:self.singleSignOnWithLinkedIn
                forKey:@"singleSignOnWithLinkedIn"];
  [aCoder encodeDouble:self.totalListeningTime
                forKey:@"totalListeningTime"];
  [aCoder encodeBool:self.parseInitiated
              forKey:@"parseInitiated"];
  [aCoder encodeObject:self.parseId
                forKey:@"parseId"];
  [aCoder encodeObject:self.parseDeviceId
                forKey:@"parseDeviceId"];
  [aCoder encodeObject:self.pushToken
                forKey:@"pushToken"];
  [aCoder encodeObject:self.favoriteProgramsAsJson
                forKey:@"favoriteProgramsAsJson"];
  [aCoder encodeObject:self.remindersString
                forKey:@"remindersString"];
  [aCoder encodeObject:self.lastReminderSync
                forKey:@"lastReminderSync"];
  [aCoder encodeObject:self.lastProgramSync
                forKey:@"lastProgramSync"];
  [aCoder encodeObject:self.deskToken
                forKey:@"deskToken"];
  [aCoder encodeObject:self.lastCompositeNewsSync
                forKey:@"lastCompositeNewsSync"];
  [aCoder encodeObject:self.leftAppAt
                forKey:@"leftAppAt"];
  [aCoder encodeObject:self.editionsJson
                forKey:@"editionsJson"];
  [aCoder encodeObject:self.lastEditionsSync
                forKey:@"lastEditionsSync"];
  [aCoder encodeObject:self.lastAlertPayload
                forKey:@"lastAlertPayload"];
  [aCoder encodeBool:self.onboardingShown
                forKey:@"onboardingShown"];
  [aCoder encodeObject:self.memberInformation
                forKey:@"memberInformation"];
  [aCoder encodeObject:self.lastAlertPayloadReceived
                forKey:@"lastAlertPayloadReceived"];
  [aCoder encodeObject:self.rom
                forKey:@"rom"];
  [aCoder encodeObject:self.twitterBearerToken
                forKey:@"twitterBearerToken"];
  [aCoder encodeObject:self.lastLatestEpisodesSync
                forKey:@"lastLatestEpisodesSync"];
  [aCoder encodeObject:self.promotionalContent
                forKey:@"promotionalContent"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  
  self.playerVolume = [aDecoder decodeFloatForKey:@"playerVolume"];
  self.playerMinimized = [aDecoder decodeBoolForKey:@"playerMinimized"];
  self.lastCacheCleanDate = [aDecoder decodeObjectForKey:@"lastCacheCleanDate"];
  self.deviceID = [aDecoder decodeObjectForKey:@"deviceID"];
  self.lastKnownConnectionType = [aDecoder decodeObjectForKey:@"lastKnownConnectionType"];
  self.currentlyPlaying = [aDecoder decodeObjectForKey:@"currentlyPlaying"];
  self.userFacebookInformation = [aDecoder decodeObjectForKey:@"userFacebookInformation"];
  self.profileImageURL = [aDecoder decodeObjectForKey:@"profileImageURL"];
  self.twitterInformation = [aDecoder decodeObjectForKey:@"twitterInformation"];
  self.linkedInToken = [aDecoder decodeObjectForKey:@"linkedInToken"];
  self.linkedInTokenExpire = [aDecoder decodeObjectForKey:@"linkedInTokenExpire"];
  self.linkedInInformation = [aDecoder decodeObjectForKey:@"linkedInInformation"];
  self.singleSignOnWithLinkedIn = [aDecoder decodeBoolForKey:@"singleSignOnWithLinkedIn"];
  self.totalListeningTime = [aDecoder decodeDoubleForKey:@"totalListeningTime"];
  self.parseInitiated = [aDecoder decodeBoolForKey:@"parseInitiated"];
  self.parseId = [aDecoder decodeObjectForKey:@"parseId"];
  self.parseDeviceId = [aDecoder decodeObjectForKey:@"parseDeviceId"];
  self.pushToken = [aDecoder decodeObjectForKey:@"pushToken"];
  self.favoriteProgramsAsJson = [aDecoder decodeObjectForKey:@"favoriteProgramsAsJson"];
  self.remindersString = [aDecoder decodeObjectForKey:@"remindersString"];
  self.lastReminderSync = [aDecoder decodeObjectForKey:@"lastReminderSync"];
  self.lastProgramSync = [aDecoder decodeObjectForKey:@"lastProgramSync"];
  self.deskToken = [aDecoder decodeObjectForKey:@"deskToken"];
  self.lastCompositeNewsSync = [aDecoder decodeObjectForKey:@"lastCompositeNewsSync"];
  self.leftAppAt = [aDecoder decodeObjectForKey:@"leftAppAt"];
  self.editionsJson = [aDecoder decodeObjectForKey:@"editionsJson"];
  self.lastEditionsSync = [aDecoder decodeObjectForKey:@"lastEditionsSync"];
  self.lastAlertPayload = [aDecoder decodeObjectForKey:@"lastAlertPayload"];
  self.onboardingShown = [aDecoder decodeBoolForKey:@"onboardingShown"];
  self.memberInformation = [aDecoder decodeObjectForKey:@"memberInformation"];
  self.lastAlertPayloadReceived = [aDecoder decodeObjectForKey:@"lastAlertPayloadReceived"];
  self.rom = [aDecoder decodeObjectForKey:@"rom"];
  self.twitterBearerToken = [aDecoder decodeObjectForKey:@"twitterBearerToken"];
  self.lastLatestEpisodesSync = [aDecoder decodeObjectForKey:@"lastLatestEpisodesSync"];
  self.promotionalContent = [aDecoder decodeObjectForKey:@"promotionalContent"];
  return self;
}

@end
