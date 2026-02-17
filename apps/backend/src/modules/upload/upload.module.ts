import { Module } from '@nestjs/common';
import { UploadService } from './upload.service';
import { UploadController, UploadFilesController } from './upload.controller';

@Module({
  controllers: [UploadFilesController, UploadController],
  providers: [UploadService],
  exports: [UploadService],
})
export class UploadModule {}
