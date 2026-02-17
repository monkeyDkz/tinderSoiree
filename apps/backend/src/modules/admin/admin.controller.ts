import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import * as QRCode from 'qrcode';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { EventsService } from '../events/events.service';
import { TokenService } from '../events/token.service';
import { CreateEventDto } from '../events/dto/create-event.dto';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'super_admin')
@Controller('admin')
export class AdminController {
  constructor(
    private readonly eventsService: EventsService,
    private readonly tokenService: TokenService,
  ) {}

  @Post('events')
  @ApiOperation({ summary: 'Create a new event' })
  async createEvent(
    @Body() dto: CreateEventDto,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.create(dto, userId);
    return { event };
  }

  @Get('events')
  @ApiOperation({ summary: 'Get all events for organizer' })
  async getEvents(@CurrentUser('id') userId: string) {
    const events = await this.eventsService.findByOrganizer(userId);
    return { events };
  }

  @Get('events/:id')
  @ApiOperation({ summary: 'Get event details with stats' })
  async getEvent(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.findById(id);
    if (!event || event.organizerId !== userId) {
      return null;
    }

    const participantCount = await this.eventsService.getParticipantCount(id);
    const joinUrl = await this.eventsService.getJoinUrl(id, userId);

    return {
      ...event,
      participantCount,
      joinUrl,
    };
  }

  @Post('events/:id/publish')
  @ApiOperation({ summary: 'Publish an event (draft -> live)' })
  async publishEvent(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.publish(id, userId);
    const joinToken = await this.eventsService.getJoinToken(id, userId);
    const joinUrl = this.tokenService.buildJoinUrl(id, joinToken);

    return {
      event,
      joinToken,
      joinUrl,
    };
  }

  @Post('events/:id/close')
  @ApiOperation({ summary: 'Close an event (live -> closed)' })
  async closeEvent(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.close(id, userId);
    const participantCount = await this.eventsService.getParticipantCount(id);

    return {
      event,
      summary: {
        totalParticipants: participantCount,
      },
    };
  }

  @Delete('events/:id')
  @ApiOperation({ summary: 'Delete an event (only draft events)' })
  async deleteEvent(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    await this.eventsService.delete(id, userId);
    return { success: true };
  }

  @Get('events/:id/qr')
  @ApiOperation({ summary: 'Generate QR code for event' })
  async getQRCode(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const joinUrl = await this.eventsService.getJoinUrl(id, userId);
    const deepLinkUrl = await this.eventsService.getDeepLinkUrl(id, userId);

    const qrCodeDataUrl = await QRCode.toDataURL(deepLinkUrl, {
      width: 400,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    return {
      qrCodeUrl: qrCodeDataUrl,
      joinUrl,
      deepLinkUrl,
      nfcPayload: deepLinkUrl,
    };
  }

  @Get('events/:id/stats')
  @ApiOperation({ summary: 'Get real-time event stats' })
  async getStats(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.findById(id);
    if (!event || event.organizerId !== userId) {
      return null;
    }

    const participantCount = await this.eventsService.getParticipantCount(id);

    // TODO: Add more detailed stats (swipes, matches, demographics)
    return {
      checkins: {
        total: participantCount,
        active: participantCount,
        left: 0,
      },
      activity: {
        totalSwipes: 0,
        totalLikes: 0,
        totalMatches: 0,
        matchRate: 0,
      },
    };
  }
}
