import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Event } from './entities/event.entity';
import { Checkin } from './entities/checkin.entity';
import { EventsService } from './events.service';
import { EventsController } from './events.controller';
import { TokenService } from './token.service';

@Module({
  imports: [TypeOrmModule.forFeature([Event, Checkin])],
  controllers: [EventsController],
  providers: [EventsService, TokenService],
  exports: [EventsService, TokenService],
})
export class EventsModule {}
