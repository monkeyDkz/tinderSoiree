import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SendMessageDto, MarkReadDto } from './dto/send-message.dto';

@ApiTags('Chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('matches/:matchId/messages')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  @ApiOperation({ summary: 'Get messages for a match' })
  async getMessages(
    @Param('matchId') matchId: string,
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
    @Query('before') before?: string,
  ) {
    return this.chatService.getMessages(
      matchId,
      userId,
      Math.min(limit || 50, 100),
      before,
    );
  }

  @Post()
  @ApiOperation({ summary: 'Send a message' })
  async sendMessage(
    @Param('matchId') matchId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(matchId, userId, dto.content);
  }

  @Patch('read')
  @ApiOperation({ summary: 'Mark messages as read' })
  async markAsRead(
    @Param('matchId') matchId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: MarkReadDto,
  ) {
    return this.chatService.markAsRead(matchId, userId, dto.upToMessageId);
  }
}
