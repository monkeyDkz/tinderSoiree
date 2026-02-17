import { Controller, Post, Body, UseGuards, Get, Param, Res } from '@nestjs/common';
import { Response } from 'express';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { IsString, IsIn } from 'class-validator';
import { UploadService } from './upload.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

class PresignDto {
  @IsString()
  @IsIn(['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'])
  contentType: string;

  @IsString()
  @IsIn(['profile_photo', 'event_cover'])
  purpose: string;
}

class DirectUploadDto {
  @IsString()
  imageBase64: string;

  @IsString()
  @IsIn(['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'])
  contentType: string;

  @IsString()
  @IsIn(['profile_photo', 'event_cover'])
  purpose: string;
}

// Public controller for serving files (no auth required)
@ApiTags('Files')
@Controller('upload')
export class UploadFilesController {
  constructor(private readonly uploadService: UploadService) {}

  @Get('file/*')
  @ApiOperation({ summary: 'Serve uploaded file (proxy to S3) - Public' })
  async serveFile(
    @Param() params: { '0': string },
    @Res() res: Response,
  ) {
    const key = params['0'];
    const stream = await this.uploadService.getFileStream(key);

    // Set content type based on extension
    const ext = key.split('.').pop()?.toLowerCase();
    const contentTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };

    res.setHeader('Content-Type', contentTypes[ext || ''] || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=31536000');

    stream.pipe(res);
  }
}

@ApiTags('Upload')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('presign')
  @ApiOperation({ summary: 'Get presigned URL for file upload' })
  async getPresignedUrl(
    @Body() dto: PresignDto,
    @CurrentUser('id') userId: string,
  ) {
    return this.uploadService.generatePresignedUrl(
      userId,
      dto.contentType,
      dto.purpose,
    );
  }

  @Post('direct')
  @ApiOperation({ summary: 'Upload image directly via backend (base64)' })
  async uploadDirect(
    @Body() dto: DirectUploadDto,
    @CurrentUser('id') userId: string,
  ) {
    return this.uploadService.uploadDirect(
      userId,
      dto.imageBase64,
      dto.contentType,
      dto.purpose,
    );
  }

  @Get('file/*')
  @ApiOperation({ summary: 'Serve uploaded file (proxy to S3)' })
  async serveFile(
    @Param() params: { '0': string },
    @Res() res: Response,
  ) {
    const key = params['0'];
    const stream = await this.uploadService.getFileStream(key);

    // Set content type based on extension
    const ext = key.split('.').pop()?.toLowerCase();
    const contentTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };

    res.setHeader('Content-Type', contentTypes[ext || ''] || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=31536000');

    stream.pipe(res);
  }
}
