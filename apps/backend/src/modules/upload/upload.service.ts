import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';
import { Readable } from 'stream';

@Injectable()
export class UploadService {
  private s3Client: S3Client;
  private bucket: string;
  private publicUrl: string;
  private apiBaseUrl: string;

  constructor(private configService: ConfigService) {
    const endpoint = this.configService.get<string>('s3.endpoint');
    const accessKey = this.configService.get<string>('s3.accessKey');
    const secretKey = this.configService.get<string>('s3.secretKey');
    const region = this.configService.get<string>('s3.region');

    this.bucket = this.configService.get<string>('s3.bucket') || 'tindersoiree';
    this.publicUrl = this.configService.get<string>('s3.publicUrl') || '';
    this.apiBaseUrl = this.configService.get<string>('app.baseUrl') || 'http://localhost:3000';

    this.s3Client = new S3Client({
      endpoint,
      region,
      credentials: {
        accessKeyId: accessKey || '',
        secretAccessKey: secretKey || '',
      },
      forcePathStyle: true, // Required for MinIO
    });
  }

  async generatePresignedUrl(
    userId: string,
    contentType: string,
    purpose: string,
  ) {
    const extension = this.getExtensionFromContentType(contentType);
    const filename = `${uuidv4()}${extension}`;
    const key = `uploads/${userId}/${purpose}/${filename}`;

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, {
      expiresIn: 300, // 5 minutes
    });

    const fileUrl = `${this.publicUrl}/${key}`;

    return {
      uploadUrl,
      fileUrl,
      expiresIn: 300,
    };
  }

  private getExtensionFromContentType(contentType: string): string {
    const extensions: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/jpg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
    };
    return extensions[contentType] || '.jpg';
  }

  async uploadDirect(
    userId: string,
    imageBase64: string,
    contentType: string,
    purpose: string,
  ) {
    console.log(`[Upload] Starting direct upload for user ${userId}`);
    console.log(`[Upload] Content type: ${contentType}, purpose: ${purpose}`);
    console.log(`[Upload] Base64 length: ${imageBase64.length}`);

    // Decode base64
    const buffer = Buffer.from(imageBase64, 'base64');
    console.log(`[Upload] Buffer size: ${buffer.length} bytes`);

    if (buffer.length > 10 * 1024 * 1024) {
      throw new BadRequestException('Image too large (max 10MB)');
    }

    const extension = this.getExtensionFromContentType(contentType);
    const filename = `${uuidv4()}${extension}`;
    const key = `uploads/${userId}/${purpose}/${filename}`;
    console.log(`[Upload] Key: ${key}`);
    console.log(`[Upload] Bucket: ${this.bucket}`);

    try {
      // Upload directly to S3
      const command = new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      });

      console.log(`[Upload] Sending to S3...`);
      await this.s3Client.send(command);
      console.log(`[Upload] S3 upload successful`);

      // Return URL that goes through the API (for mobile access)
      const fileUrl = `${this.apiBaseUrl}/api/v1/upload/file/${key}`;
      console.log(`[Upload] File URL: ${fileUrl}`);

      return { fileUrl };
    } catch (error) {
      console.error(`[Upload] S3 Error:`, error);
      throw error;
    }
  }

  async getFileStream(key: string): Promise<Readable> {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });

      const response = await this.s3Client.send(command);

      if (!response.Body) {
        throw new NotFoundException('File not found');
      }

      return response.Body as Readable;
    } catch (error) {
      throw new NotFoundException('File not found');
    }
  }
}
