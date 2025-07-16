import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_app/models/file_info.dart';
import 'package:gallery_app/models/folder_info.dart';
import 'package:gallery_app/screens/file_view_page.dart';
import 'package:gallery_app/screens/notes_page.dart';
import 'package:gallery_app/screens/pdf_preview_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FolderImagesPage extends StatefulWidget {
  final FolderInfo folder;

  const FolderImagesPage({super.key, required this.folder});

  @override
  State<FolderImagesPage> createState() => _FolderImagesPageState();
}

enum FileSortOption {
  dateAscending,
  dateDescending,
  sizeAscending,
  sizeDescending,
}

class _FolderImagesPageState extends State<FolderImagesPage> {
  final ImagePicker _picker = ImagePicker();
  List<FileInfo> _files = [];
  bool _isLoading = true;
  bool _multiSelectMode = false;
  final List<FileInfo> _selectedFiles = [];
  FileSortOption _currentSortOption = FileSortOption.dateAscending;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Directory folderDir = Directory(widget.folder.path);
      final List<FileSystemEntity> entities = await folderDir.list().toList();
      final List<FileInfo> files = [];

      for (var entity in entities) {
        if (entity is File) {
          files.add(FileInfo(
            name: entity.path.split(Platform.pathSeparator).last,
            path: entity.path,
            type: getFileType(entity.path),
          ));
        }
      }

      setState(() {
        _files = files;
        _sortFiles(); // Sort files after loading
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Error loading files: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _sortFiles() {
    _files.sort((a, b) {
      switch (_currentSortOption) {
        case FileSortOption.dateAscending:
          return File(a.path)
              .lastModifiedSync()
              .compareTo(File(b.path).lastModifiedSync());
        case FileSortOption.dateDescending:
          return File(b.path)
              .lastModifiedSync()
              .compareTo(File(a.path).lastModifiedSync());
        case FileSortOption.sizeAscending:
          return File(a.path).lengthSync().compareTo(File(b.path).lengthSync());
        case FileSortOption.sizeDescending:
          return File(b.path).lengthSync().compareTo(File(a.path).lengthSync());
      }
    });
  }

  Future<void> _pickFiles() async {
    try {
      fp.FilePickerResult? result =
          await fp.FilePicker.platform.pickFiles(allowMultiple: true);

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isLoading = true;
      });

      for (var platformFile in result.files) {
        if (platformFile.path == null) continue;

        final String fileName = platformFile.name;
        final File newFile = File(
          '${widget.folder.path}${Platform.pathSeparator}$fileName',
        );
        await File(platformFile.path!).copy(newFile.path);

        _files.add(FileInfo(
          name: fileName,
          path: newFile.path,
          type: getFileType(newFile.path),
        ));
      }

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "${result.files.length} files added",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Error adding files: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;

      final String fileName = pickedFile.path.split(Platform.pathSeparator).last;
      final File newFile = File(
        '${widget.folder.path}${Platform.pathSeparator}$fileName',
      );
      await File(pickedFile.path).copy(newFile.path);

      setState(() {
        _files.add(FileInfo(
          name: fileName,
          path: newFile.path,
          type: getFileType(newFile.path),
        ));
      });

      Fluttertoast.showToast(
        msg: "Image added from camera",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error adding image from camera: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => NotesPage(folderPath: widget.folder.path),
      ),
    );
  }

  Future<void> _makePdf() async {
    List<FileInfo> selectedImages = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Select Images for PDF',
                  style: Theme.of(context).textTheme.titleMedium),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _files
                      .where((file) => file.type == FileType.image)
                      .length,
                  itemBuilder: (BuildContext context, int index) {
                    final imageFile = _files
                        .where((file) => file.type == FileType.image)
                        .toList()[index];
                    final isSelected = selectedImages.contains(imageFile);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedImages.remove(imageFile);
                          } else {
                            selectedImages.add(imageFile);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Image.file(
                            File(imageFile.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                              );
                            },
                          ),
                          if (isSelected)
                            Positioned.fill(
                              child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                                child: Icon(
                                  Icons.check_circle,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ),
                ElevatedButton(
                  onPressed: selectedImages.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfPreviewScreen(
                                initialImages: selectedImages,
                                folderPath: widget.folder.path,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadFiles(); // Refresh file list if PDF was created
                          }
                        },
                  child: const Text('Create PDF'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFileOptions(FileInfo file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _showFileDetails(file);
              },
            ),
            if (file.type == FileType.pdf)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _renameFile(file);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFileDetails(FileInfo file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
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
              builder: (BuildContext context, AsyncSnapshot<FileStat> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Size: ${(snapshot.data!.size / 1024).toStringAsFixed(2)} KB',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text('Last Modified: ${snapshot.data!.modified}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('Error loading file details: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium);
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
      await _loadFiles(); // Reload files to ensure UI reflects changes immediately
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

  Future<void> _renameFile(FileInfo file) async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController(text: file.name);
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new file name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Rename'),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != file.name) {
      try {
        final String oldPath = file.path;
        final String newPath =
            '${widget.folder.path}${Platform.pathSeparator}$newName';
        final File oldFile = File(oldPath);
        await oldFile.rename(newPath);

        setState(() {
          final index = _files.indexOf(file);
          if (index != -1) {
            _files[index] = FileInfo(
              name: newName,
              path: newPath,
              type: getFileType(newPath),
            );
          }
        });
        Fluttertoast.showToast(msg: "File renamed successfully!");
      } catch (e) {
        Fluttertoast.showToast(msg: "Error renaming file: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _multiSelectMode
            ? Text('${_selectedFiles.length} selected')
            : Text(widget.folder.name),
        actions: _multiSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    if (_selectedFiles.isNotEmpty) {
                      await Share.shareXFiles(
                          _selectedFiles.map((e) => XFile(e.path)).toList());
                      setState(() {
                        _selectedFiles.clear();
                        _multiSelectMode = false;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (_selectedFiles.isNotEmpty) {
                      for (var file in _selectedFiles) {
                        await _deleteFile(file);
                      }
                      setState(() {
                        _selectedFiles.clear();
                        _multiSelectMode = false;
                      });
                    }
                  },
                ),
              ]
            : [
                PopupMenuButton<FileSortOption>(
                  icon: const Icon(Icons.sort),
                  onSelected: (FileSortOption result) {
                    setState(() {
                      _currentSortOption = result;
                      _sortFiles();
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<FileSortOption>>[
                    const PopupMenuItem<FileSortOption>(
                      value: FileSortOption.dateAscending,
                      child: Text('Date (Oldest first)'),
                    ),
                    const PopupMenuItem<FileSortOption>(
                      value: FileSortOption.dateDescending,
                      child: Text('Date (Newest first)'),
                    ),
                    const PopupMenuItem<FileSortOption>(
                      value: FileSortOption.sizeAscending,
                      child: Text('Size (Smallest first)'),
                    ),
                    const PopupMenuItem<FileSortOption>(
                      value: FileSortOption.sizeDescending,
                      child: Text('Size (Largest first)'),
                    ),
                  ],
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_off_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No files in this folder',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add files'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    itemCount: FileType.values.length,
                    itemBuilder: (BuildContext context, int typeIndex) {
                      final fileType = FileType.values[typeIndex];
                      final filesOfType =
                          _files.where((file) => file.type == fileType).toList();

                      if (filesOfType.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '${fileType.toString().split('.').last.toUpperCase()}S',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: filesOfType.length,
                            itemBuilder: (BuildContext context, int index) {
                              final file = filesOfType[index];
                              final isSelected = _selectedFiles.contains(file);
                              return GestureDetector(
                                onTap: () async {
                                  if (_multiSelectMode) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedFiles.remove(file);
                                      } else {
                                        _selectedFiles.add(file);
                                      }
                                    });
                                  } else {
                                    if (file.type == FileType.image) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              FileViewPage(
                                            files: filesOfType
                                                .where((f) =>
                                                    f.type == FileType.image)
                                                .toList(),
                                            initialIndex: filesOfType
                                                .where((f) =>
                                                    f.type == FileType.image)
                                                .toList()
                                                .indexOf(file),
                                          ),
                                        ),
                                      );
                                    } else {
                                      OpenFilex.open(file.path);
                                    }
                                  }
                                },
                                onLongPress: () {
                                  if (file.type == FileType.pdf) {
                                    _showFileOptions(file);
                                  } else {
                                    setState(() {
                                      if (!_multiSelectMode) {
                                        _multiSelectMode = true;
                                        _selectedFiles.add(file);
                                      } else {
                                        if (isSelected) {
                                          _selectedFiles.remove(file);
                                        } else {
                                          _selectedFiles.add(file);
                                        }
                                      }
                                    });
                                  }
                                },
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12.0),
                                        child: file.type == FileType.image
                                            ? Image.file(
                                                File(file.path),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                                                  );
                                                },
                                              )
                                            : SizedBox.expand(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      file.icon,
                                                      size: 50,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                      child: Text(
                                                        file.name,
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                      if (isSelected)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 10,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 10,
        dialRoot: null,
        buttonSize: const Size(56, 56),
        label: _multiSelectMode ? const Text("Options") : null,
        activeLabel: _multiSelectMode ? const Text("Close Options") : null,
        direction: SpeedDialDirection.up,
        
        renderOverlay: true,
        
        animationCurve: Curves.elasticOut,
        isOpenOnStart: false,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.picture_as_pdf_outlined),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            label: 'PDF Maker',
            onTap: _makePdf,
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit_outlined),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            label: 'Notes',
            onTap: _showNotes,
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera_alt_outlined),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            label: 'Camera',
            onTap: _takePicture,
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_photo_alternate_outlined),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            label: 'Upload File',
            onTap: _pickFiles,
          ),
        ],
      ),
    );
  }
}
