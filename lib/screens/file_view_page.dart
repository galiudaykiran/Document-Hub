import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_app/models/file_info.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class FileViewPage extends StatefulWidget {
  final List<FileInfo> files;
  final int initialIndex;

  const FileViewPage({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<FileViewPage> createState() => _FileViewPageState();
}

class _FileViewPageState extends State<FileViewPage> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();
  double _rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _showFileDetails(FileInfo file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Path: ${file.path}', style: Theme.of(context).textTheme.bodyMedium),
            FutureBuilder<FileStat>(
              future: File(file.path).stat(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Size: ${(snapshot.data!.size / 1024).toStringAsFixed(2)} KB', style: Theme.of(context).textTheme.bodyMedium),
                      Text('Last Modified: ${snapshot.data!.modified}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('Error loading file details: ${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium);
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(FileInfo file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Check out this file!');
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error sharing file: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _deleteFile(FileInfo file) async {
    try {
      await File(file.path).delete();
      Navigator.pop(context); // Pop the file view page after deletion
      Fluttertoast.showToast(
        msg: "File deleted",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting file: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.files[_currentIndex].name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showFileDetails(widget.files[_currentIndex]),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareFile(widget.files[_currentIndex]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteFile(widget.files[_currentIndex]),
          ),
          if (widget.files[_currentIndex].type == FileType.image)
            IconButton(
              icon: const Icon(Icons.rotate_left),
              onPressed: _rotateLeft,
            ),
          if (widget.files[_currentIndex].type == FileType.image)
            IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: _rotateRight,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _rotationAngle = 0.0; // Reset rotation when page changes
          });
        },
        itemBuilder: (context, index) {
          final file = widget.files[index];
          return GestureDetector(
            onDoubleTapDown: (details) {
              if (_transformationController.value != Matrix4.identity()) {
                _transformationController.value = Matrix4.identity();
              } else {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset localPosition = box.globalToLocal(details.globalPosition);
                final double zoomFactor = 2.0;
                final Matrix4 matrix = Matrix4.identity()
                  ..translate(-localPosition.dx * (zoomFactor - 1), -localPosition.dy * (zoomFactor - 1))
                  ..scale(zoomFactor, zoomFactor);
                _transformationController.value = matrix;
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.none,
              child: Center(
                child: file.type == FileType.image
                    ? Transform.rotate(
                        angle: _rotationAngle,
                        child: Image.file(
                        File(file.path),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 50),
                                SizedBox(height: 8),
                                Text('Error loading image', textAlign: TextAlign.center),
                              ],
                            ),
                          );
                        },
                      ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            file.icon,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            file.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => OpenFilex.open(file.path),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open File'),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle -= (90 * 3.1415926535 / 180); // Rotate by -90 degrees
      _transformationController.value = Matrix4.identity(); // Reset zoom/pan
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle += (90 * 3.1415926535 / 180); // Rotate by 90 degrees
      _transformationController.value = Matrix4.identity(); // Reset zoom/pan
    });
  }
}