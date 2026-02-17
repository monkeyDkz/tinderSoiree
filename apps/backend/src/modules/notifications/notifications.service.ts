import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { DeviceToken, Platform } from './entities/device-token.entity';

export enum NotificationType {
  NEW_MATCH = 'NEW_MATCH',
  NEW_MESSAGE = 'NEW_MESSAGE',
  EVENT_UPDATE = 'EVENT_UPDATE',
  EVENT_REMINDER = 'EVENT_REMINDER',
}

export interface NotificationPayload {
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(DeviceToken)
    private deviceTokenRepository: Repository<DeviceToken>,
  ) {}

  // MARK: - Device Token Management

  async registerToken(
    userId: string,
    token: string,
    platform: string,
  ): Promise<DeviceToken> {
    const platformEnum = platform.toLowerCase() as Platform;

    // Check if token already exists for this user
    let deviceToken = await this.deviceTokenRepository.findOne({
      where: { userId, token },
    });

    if (deviceToken) {
      // Update existing token
      deviceToken.isActive = true;
      deviceToken.lastUsedAt = new Date();
      return this.deviceTokenRepository.save(deviceToken);
    }

    // Check if token exists for another user (device changed hands)
    const existingToken = await this.deviceTokenRepository.findOne({
      where: { token },
    });

    if (existingToken) {
      // Deactivate old token
      existingToken.isActive = false;
      await this.deviceTokenRepository.save(existingToken);
    }

    // Create new token
    deviceToken = this.deviceTokenRepository.create({
      userId,
      token,
      platform: platformEnum,
      isActive: true,
      lastUsedAt: new Date(),
    });

    return this.deviceTokenRepository.save(deviceToken);
  }

  async unregisterToken(userId: string, token: string): Promise<void> {
    await this.deviceTokenRepository.update(
      { userId, token },
      { isActive: false },
    );
  }

  async unregisterAllTokens(userId: string): Promise<void> {
    await this.deviceTokenRepository.update({ userId }, { isActive: false });
  }

  async getActiveTokens(userId: string): Promise<DeviceToken[]> {
    return this.deviceTokenRepository.find({
      where: { userId, isActive: true },
    });
  }

  async getActiveTokensForUsers(userIds: string[]): Promise<DeviceToken[]> {
    return this.deviceTokenRepository.find({
      where: { userId: In(userIds), isActive: true },
    });
  }

  // MARK: - Send Notifications

  async sendToUser(
    userId: string,
    payload: NotificationPayload,
  ): Promise<void> {
    const tokens = await this.getActiveTokens(userId);

    if (tokens.length === 0) {
      this.logger.debug(`No active tokens for user ${userId}`);
      return;
    }

    await this.sendToTokens(tokens, payload);
  }

  async sendToUsers(
    userIds: string[],
    payload: NotificationPayload,
  ): Promise<void> {
    const tokens = await this.getActiveTokensForUsers(userIds);

    if (tokens.length === 0) {
      this.logger.debug('No active tokens for users');
      return;
    }

    await this.sendToTokens(tokens, payload);
  }

  private async sendToTokens(
    tokens: DeviceToken[],
    payload: NotificationPayload,
  ): Promise<void> {
    // Group tokens by platform
    const iosTokens = tokens.filter((t) => t.platform === Platform.IOS);
    const androidTokens = tokens.filter((t) => t.platform === Platform.ANDROID);

    // Send to iOS via APNs
    if (iosTokens.length > 0) {
      await this.sendAPNS(iosTokens, payload);
    }

    // Send to Android via FCM
    if (androidTokens.length > 0) {
      await this.sendFCM(androidTokens, payload);
    }
  }

  private async sendAPNS(
    tokens: DeviceToken[],
    payload: NotificationPayload,
  ): Promise<void> {
    // TODO: Implement APNs sending
    // This requires:
    // 1. Apple Developer Program membership
    // 2. APNs authentication key or certificate
    // 3. @parse/node-apn or similar library

    this.logger.log(
      `[APNs] Would send notification to ${tokens.length} devices: ${payload.title}`,
    );

    // For now, just log the notification
    tokens.forEach((token) => {
      this.logger.debug(`[APNs] Token: ${token.token.substring(0, 20)}...`);
    });
  }

  private async sendFCM(
    tokens: DeviceToken[],
    payload: NotificationPayload,
  ): Promise<void> {
    // TODO: Implement FCM sending
    // This requires:
    // 1. Firebase project
    // 2. Firebase Admin SDK
    // 3. Service account credentials

    this.logger.log(
      `[FCM] Would send notification to ${tokens.length} devices: ${payload.title}`,
    );

    tokens.forEach((token) => {
      this.logger.debug(`[FCM] Token: ${token.token.substring(0, 20)}...`);
    });
  }

  // MARK: - Convenience Methods

  async sendNewMatchNotification(
    userId: string,
    matchedUserName: string,
    matchId: string,
  ): Promise<void> {
    await this.sendToUser(userId, {
      type: NotificationType.NEW_MATCH,
      title: "C'est un Match ! 🎉",
      body: `${matchedUserName} et toi vous êtes likés`,
      data: { matchId },
    });
  }

  async sendNewMessageNotification(
    userId: string,
    senderName: string,
    messagePreview: string,
    matchId: string,
  ): Promise<void> {
    await this.sendToUser(userId, {
      type: NotificationType.NEW_MESSAGE,
      title: senderName,
      body: messagePreview.length > 50 ? `${messagePreview.substring(0, 47)}...` : messagePreview,
      data: { matchId },
    });
  }

  async sendEventUpdateNotification(
    userIds: string[],
    eventName: string,
    message: string,
    eventId: string,
  ): Promise<void> {
    await this.sendToUsers(userIds, {
      type: NotificationType.EVENT_UPDATE,
      title: eventName,
      body: message,
      data: { eventId },
    });
  }

  async sendEventReminderNotification(
    userId: string,
    eventName: string,
    timeUntil: string,
    eventId: string,
  ): Promise<void> {
    await this.sendToUser(userId, {
      type: NotificationType.EVENT_REMINDER,
      title: `${eventName} commence bientôt !`,
      body: `La soirée commence dans ${timeUntil}`,
      data: { eventId },
    });
  }
}
