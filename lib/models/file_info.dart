import 'package:flutter/material.dart';

class FileInfo {
  final String name;
  final String path;
  final FileType type;

  FileInfo({
    required this.name,
    required this.path,
    required this.type,
  });

  IconData get icon {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.description;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.unknown:
        return Icons.insert_drive_file;
    }
  }
}

enum FileType {
  image,
  pdf,
  document,
  video,
  audio,
  unknown,
}

FileType getFileType(String path) {
  final String extension = path.split('.').last.toLowerCase();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
      return FileType.image;
    case 'pdf':
      return FileType.pdf;
    case 'doc':
    case 'docx':
    case 'txt':
    case 'rtf':
    case 'odt':
      return FileType.document;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
      return FileType.video;
    case 'mp3':
    case 'wav':
    case 'aac':
      return FileType.audio;
    default:
      return FileType.unknown;
  }
}
