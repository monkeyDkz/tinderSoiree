import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';

class RegisterTokenDto {
  token: string;
  platform: string;
}

class UnregisterTokenDto {
  token: string;
}

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register device token for push notifications' })
  async registerToken(
    @CurrentUser('id') userId: string,
    @Body() dto: RegisterTokenDto,
  ) {
    await this.notificationsService.registerToken(
      userId,
      dto.token,
      dto.platform,
    );
    return { success: true };
  }

  @Post('unregister')
  @ApiOperation({ summary: 'Unregister device token' })
  async unregisterToken(
    @CurrentUser('id') userId: string,
    @Body() dto: UnregisterTokenDto,
  ) {
    await this.notificationsService.unregisterToken(userId, dto.token);
    return { success: true };
  }
}
