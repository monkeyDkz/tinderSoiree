import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Message } from './entities/message.entity';
import { Match } from '../matches/entities/match.entity';
import { User } from '../users/entities/user.entity';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { MatchesModule } from '../matches/matches.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Message, Match, User]),
    MatchesModule,
    NotificationsModule,
  ],
  controllers: [ChatController],
  providers: [ChatService],
  exports: [ChatService],
})
export class ChatModule {}
