import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import * as crypto from 'crypto';

interface JoinTokenPayload {
  eventId: string;
  iat: number;
  exp: number;
}

@Injectable()
export class TokenService {
  constructor(private configService: ConfigService) {}

  generateJoinToken(
    eventId: string,
    eventSecret: string,
    expiresInHours: number = 2,
  ): string {
    const payload = { eventId };

    const token = jwt.sign(payload, eventSecret, {
      algorithm: 'HS256',
      expiresIn: `${expiresInHours}h`,
      issuer: 'tindersoiree',
      audience: 'join-event',
    });

    return token;
  }

  validateJoinToken(
    token: string,
    eventId: string,
    eventSecret: string,
  ): { valid: true } | { valid: false; error: string } {
    try {
      const decoded = jwt.verify(token, eventSecret, {
        algorithms: ['HS256'],
        issuer: 'tindersoiree',
        audience: 'join-event',
      }) as JoinTokenPayload;

      if (decoded.eventId !== eventId) {
        return { valid: false, error: 'EVENT_MISMATCH' };
      }

      return { valid: true };
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        return { valid: false, error: 'TOKEN_EXPIRED' };
      }
      if (error instanceof jwt.JsonWebTokenError) {
        return { valid: false, error: 'INVALID_TOKEN' };
      }
      return { valid: false, error: 'UNKNOWN_ERROR' };
    }
  }

  generateEventSecret(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  buildJoinUrl(eventId: string, token: string): string {
    const baseUrl = this.configService.get<string>('app.baseUrl');
    return `${baseUrl}/e/${eventId}?token=${encodeURIComponent(token)}`;
  }

  buildDeepLinkUrl(eventId: string, token: string): string {
    return `tindersoiree://join?eventId=${eventId}&token=${encodeURIComponent(token)}`;
  }
}
