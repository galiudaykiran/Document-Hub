import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_app/models/file_info.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfPreviewScreen extends StatefulWidget {
  final List<FileInfo> initialImages;
  final String folderPath;

  const PdfPreviewScreen({
    super.key,
    required this.initialImages,
    required this.folderPath,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late List<PdfImageInfo> _pdfImages;
  int _currentPageIndex = 0;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _pdfImages = widget.initialImages
        .map((fileInfo) => PdfImageInfo(fileInfo: fileInfo))
        .toList();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        final bool wasEmpty = _pdfImages.isEmpty;
        for (var xFile in pickedFiles) {
          _pdfImages.add(
            PdfImageInfo(
              fileInfo: FileInfo(
                name: xFile.name,
                path: xFile.path,
                type: FileType.image,
              ),
            ),
          );
        }
        if (wasEmpty) {
          _currentPageIndex = 0;
        }
      });
      Fluttertoast.showToast(msg: "${pickedFiles.length} images added.");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pdfImages.removeAt(index);
      if (_currentPageIndex >= _pdfImages.length && _pdfImages.isNotEmpty) {
        _currentPageIndex = _pdfImages.length - 1;
      } else if (_pdfImages.isEmpty) {
        _currentPageIndex = 0;
      }
    });
    Fluttertoast.showToast(msg: "Image removed.");
  }

  void _rotateImage(int index, double angle) {
    setState(() {
      _pdfImages[index].rotationAngle += angle;
    });
  }

  Future<void> _editImage(int index) async {
    final currentImage = _pdfImages[index];
    final imageBytes = await File(currentImage.fileInfo.path).readAsBytes();

    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: imageBytes,
        ),
      ),
    );

    if (editedImageBytes != null) {
      // Save the edited image to a temporary file or overwrite the original
      // For simplicity, let's overwrite the original for now.
      await File(currentImage.fileInfo.path).writeAsBytes(editedImageBytes);
      setState(() {
        // Trigger a rebuild to show the updated image
        _pdfImages[index] = PdfImageInfo(
          fileInfo: currentImage.fileInfo,
          rotationAngle: currentImage.rotationAngle,
        );
      });
      Fluttertoast.showToast(msg: "Image edited.");
    }
  }

  Future<void> _generateAndSavePdf() async {
    if (_pdfImages.isEmpty) {
      Fluttertoast.showToast(msg: "No images to create PDF.");
      return;
    }

    String? fileName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller =
            TextEditingController(text: "document_${DateTime.now().millisecondsSinceEpoch}");
        return AlertDialog(
          title: const Text('Name your PDF'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter PDF file name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    if (fileName == null || fileName.isEmpty) {
      Fluttertoast.showToast(msg: "PDF save cancelled.");
      return;
    }

    Fluttertoast.showToast(msg: "Creating PDF...");
    try {
      final pdf = pw.Document();

      for (var pdfImage in _pdfImages) {
        final image = pw.MemoryImage(
          File(pdfImage.fileInfo.path).readAsBytesSync(),
        );
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Transform.rotate(
                  angle: pdfImage.rotationAngle,
                  child: pw.Image(image),
                ),
              );
            },
          ),
        );
      }

      final String path =
          '${widget.folderPath}${Platform.pathSeparator}$fileName.pdf';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      Fluttertoast.showToast(msg: "PDF created successfully!");
      Navigator.pop(context, true); // Pop with true to indicate success
      OpenFilex.open(path); // Open the generated PDF
    } catch (e) {
      Fluttertoast.showToast(msg: "Error creating PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _pickImages,
            tooltip: 'Add Images',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _generateAndSavePdf,
            tooltip: 'Generate and Save PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _pdfImages.isEmpty
                ? const Center(
                    child: Text('No images selected for PDF. Add some!'),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: _currentPageIndex < _pdfImages.length
                              ? InteractiveViewer(
                                  transformationController: _transformationController,
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: AspectRatio(
                                    aspectRatio: 9 / 16, // 9:16 aspect ratio
                                    child: Transform.rotate(
                                      angle: _pdfImages[_currentPageIndex].rotationAngle,
                                      child: Image.file(
                                        File(_pdfImages[_currentPageIndex].fileInfo.path),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.rotate_left_outlined),
                              onPressed: _pdfImages.isNotEmpty
                                  ? () => _rotateImage(_currentPageIndex, -0.5 * 3.1415926535)
                                  : null,
                              tooltip: 'Rotate Left',
                            ),
                            IconButton(
                              icon: const Icon(Icons.rotate_right_outlined),
                              onPressed: _pdfImages.isNotEmpty
                                  ? () => _rotateImage(_currentPageIndex, 0.5 * 3.1415926535)
                                  : null,
                              tooltip: 'Rotate Right',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _pdfImages.isNotEmpty
                                  ? () => _editImage(_currentPageIndex)
                                  : null,
                              tooltip: 'Edit Image',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _pdfImages.isNotEmpty
                                  ? () => _removeImage(_currentPageIndex)
                                  : null,
                              tooltip: 'Remove Image',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pdfImages.length,
                          onReorder: (int oldIndex, int newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final PdfImageInfo item = _pdfImages.removeAt(oldIndex);
                              _pdfImages.insert(newIndex, item);
                              if (_currentPageIndex == oldIndex) {
                                _currentPageIndex = newIndex;
                              } else if (_currentPageIndex > oldIndex && _currentPageIndex <= newIndex) {
                                _currentPageIndex--;
                              } else if (_currentPageIndex < oldIndex && _currentPageIndex >= newIndex) {
                                _currentPageIndex++;
                              }
                            });
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final content = _pdfImages[index];
                            return GestureDetector(
                              key: ValueKey(content.hashCode),
                              onTap: () {
                                setState(() {
                                  _currentPageIndex = index;
                                });
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _currentPageIndex == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(content.fileInfo.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                        child: Text(
                          '${_currentPageIndex + 1} / ${_pdfImages.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class PdfImageInfo {
  final FileInfo fileInfo;
  double rotationAngle;

  PdfImageInfo({required this.fileInfo, this.rotationAngle = 0.0});
}