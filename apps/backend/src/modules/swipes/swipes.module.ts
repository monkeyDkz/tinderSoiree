import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Swipe } from './entities/swipe.entity';
import { Match } from '../matches/entities/match.entity';
import { Checkin } from '../events/entities/checkin.entity';
import { User } from '../users/entities/user.entity';
import { SwipesService } from './swipes.service';
import { StackService } from './stack.service';
import { SwipesController } from './swipes.controller';
import { EventsModule } from '../events/events.module';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Swipe, Match, Checkin, User]),
    EventsModule,
    UsersModule,
    NotificationsModule,
  ],
  controllers: [SwipesController],
  providers: [SwipesService, StackService],
  exports: [SwipesService],
})
export class SwipesModule {}
