import 'package:gallery_app/models/file_info.dart';

class FolderInfo {
  final String name;
  final String path;
  final List<FileInfo> files;
  final String? customThumbnailPath;

  FolderInfo({
    required this.name,
    required this.path,
    this.files = const [],
    this.customThumbnailPath,
  });

  int get fileCount => files.length;

  String? get thumbnailPath {
    if (customThumbnailPath != null) {
      return customThumbnailPath;
    }
    final imageFiles = files.where((file) => file.type == FileType.image).toList();
    return imageFiles.isNotEmpty ? imageFiles.first.path : null;
  }
}
