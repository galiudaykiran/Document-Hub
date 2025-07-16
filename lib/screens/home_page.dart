import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_app/models/file_info.dart';
import 'package:gallery_app/models/folder_info.dart';
import 'package:gallery_app/screens/file_view_page.dart';
import 'package:gallery_app/screens/folder_images_page.dart';
import 'package:gallery_app/screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const HomePage({super.key, required this.setThemeMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<FolderInfo> _folders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      final Directory folderDir = Directory(
        '$appDocPath${Platform.pathSeparator}document_folders',
      );

      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      final List<FileSystemEntity> entities = await folderDir.list().toList();
      final List<FolderInfo> folders = [];

      for (var entity in entities) {
        if (entity is Directory) {
          final String folderName = entity.path.split(Platform.pathSeparator).last;
          final Directory folderContentDir = Directory(entity.path);
          final List<FileSystemEntity> filesInFolder =
              await folderContentDir.list().toList();
          final List<FileInfo> files = [];

          for (var fileEntity in filesInFolder) {
            if (fileEntity is File) {
              files.add(
                FileInfo(
                  name: fileEntity.path.split(Platform.pathSeparator).last,
                  path: fileEntity.path,
                  type: getFileType(fileEntity.path),
                ),
              );
            }
          }
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? customThumbnailPath = prefs.getString('folder_thumbnail_${entity.path}');

          folders.add(
            FolderInfo(
              name: folderName,
              path: entity.path,
              files: files,
              customThumbnailPath: customThumbnailPath,
            ),
          );
        }
      }

      setState(() {
        _folders.clear();
        _folders.addAll(folders);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Error loading folders: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _createNewFolder() async {
    final TextEditingController folderNameController = TextEditingController();
    bool isCreating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Create New Folder', style: Theme.of(context).textTheme.titleMedium),
            content: TextField(
              controller: folderNameController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Folder Name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final String folderName = folderNameController.text.trim();
                        if (folderName.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Please enter a folder name",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          return;
                        }

                        setDialogState(() {
                          isCreating = true;
                        });

                        try {
                          final Directory appDocDir =
                              await getApplicationDocumentsDirectory();
                          final String appDocPath = appDocDir.path;
                          final Directory newFolder = Directory(
                            '$appDocPath${Platform.pathSeparator}document_folders${Platform.pathSeparator}$folderName',
                          );

                          if (await newFolder.exists()) {
                            Fluttertoast.showToast(
                              msg: "Folder already exists",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                            setDialogState(() {
                              isCreating = false;
                            });
                            return;
                          }

                          await newFolder.create(recursive: true);

                          setState(() {
                            _folders.add(
                              FolderInfo(
                                name: folderName,
                                path: newFolder.path,
                                files: [],
                                customThumbnailPath: null,
                              ),
                            );
                          });

                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Folder created successfully",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "Error creating folder: $e",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          setDialogState(() {
                            isCreating = false;
                          });
                        }
                      },
                child: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFolderOptions(FolderInfo folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Folder'),
              onTap: () {
                Navigator.pop(context);
                _deleteFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(context);
                _renameFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Folder'),
              onTap: () {
                Navigator.pop(context);
                _shareFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Set Cover Image'),
              onTap: () {
                Navigator.pop(context);
                _setFolderCover(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFolderCover(FolderInfo folder) async {
    try {
      final Directory folderDir = Directory(folder.path);
      final List<FileSystemEntity> entities = await folderDir.list().toList();
      final List<FileInfo> imageFiles = entities
          .where((entity) =>
              entity is File &&
              (entity.path.toLowerCase().endsWith('.jpg') ||
                  entity.path.toLowerCase().endsWith('.jpeg') ||
                  entity.path.toLowerCase().endsWith('.png')))
          .map((entity) => FileInfo(
                name: entity.path.split(Platform.pathSeparator).last,
                path: entity.path,
                type: FileType.image,
              ))
          .toList();

      if (imageFiles.isEmpty) {
        Fluttertoast.showToast(
          msg: "No images found in this folder.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final String? selectedImagePath = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Cover Image'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                final file = imageFiles[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, file.path),
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedImagePath == null) return;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('folder_thumbnail_${folder.path}', selectedImagePath);

      setState(() {
        final int index = _folders.indexOf(folder);
        if (index != -1) {
          _folders[index] = FolderInfo(
            name: folder.name,
            path: folder.path,
            files: folder.files,
            customThumbnailPath: selectedImagePath,
          );
        }
      });

      Fluttertoast.showToast(
        msg: "Folder cover updated",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error setting cover image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _renameFolder(FolderInfo folder) async {
    final TextEditingController nameController =
        TextEditingController(text: folder.name);
    bool isRenaming = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Rename Folder', style: Theme.of(context).textTheme.titleMedium),
            content: TextField(
              controller: nameController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'New Folder Name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: isRenaming
                    ? null
                    : () async {
                        final String newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Please enter a folder name",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          return;
                        }
                        if (newName == folder.name) {
                          Navigator.pop(context);
                          return;
                        }

                        setDialogState(() {
                          isRenaming = true;
                        });

                        try {
                          final Directory oldFolderDir = Directory(folder.path);
                          final String parentPath =
                              oldFolderDir.parent.path;
                          final Directory newFolderDir = Directory(
                            '$parentPath${Platform.pathSeparator}$newName',
                          );

                          if (await newFolderDir.exists()) {
                            Fluttertoast.showToast(
                              msg: "Folder with this name already exists",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                            setDialogState(() {
                              isRenaming = false;
                            });
                            return;
                          }

                          await oldFolderDir.rename(newFolderDir.path);

                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                          final String? oldThumbnailPath = prefs.getString('folder_thumbnail_${folder.path}');
                          if (oldThumbnailPath != null) {
                            await prefs.remove('folder_thumbnail_${folder.path}');
                            await prefs.setString('folder_thumbnail_${newFolderDir.path}', oldThumbnailPath);
                          }

                          setState(() {
                            final int index = _folders.indexOf(folder);
                            if (index != -1) {
                              _folders[index] = FolderInfo(
                                name: newName,
                                path: newFolderDir.path,
                                files: folder.files,
                                customThumbnailPath: oldThumbnailPath,
                              );
                            }
                          });

                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Folder renamed successfully",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "Error renaming folder: $e",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          setDialogState(() {
                            isRenaming = false;
                          });
                        }
                      },
                child: isRenaming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Rename'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareFolder(FolderInfo folder) async {
    try {
      final Directory folderDir = Directory(folder.path);
      if (await folderDir.exists()) {
        final List<String> imagePaths = [];
        await for (var entity in folderDir.list()) {
          if (entity is File && (entity.path.toLowerCase().endsWith('.jpg') ||
              entity.path.toLowerCase().endsWith('.jpeg') ||
              entity.path.toLowerCase().endsWith('.png'))) {
            imagePaths.add(entity.path);
          }
        }

        final List<String> filePaths = folder.files.map((e) => e.path).toList();
        if (filePaths.isNotEmpty) {
          await Share.shareXFiles(
              filePaths.map((path) => XFile(path)).toList(),
              text: 'Check out this folder: ${folder.name}');
        } else {
          Fluttertoast.showToast(
            msg: "Folder is empty, cannot share.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error sharing folder: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _deleteFolder(FolderInfo folder) async {
    try {
      final Directory folderDir = Directory(folder.path);
      if (await folderDir.exists()) {
        await folderDir.delete(recursive: true);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('folder_thumbnail_${folder.path}');
        setState(() {
          _folders.remove(folder);
        });
        Fluttertoast.showToast(
          msg: "Folder deleted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting folder: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  List<FolderInfo> get _filteredFolders {
    if (_searchQuery.isEmpty) {
      return _folders;
    }
    return _folders
        .where(
          (folder) =>
              folder.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Hub',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 28, // Increased font size for elegance
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(setThemeMode: widget.setThemeMode),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search folders...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFolders.isEmpty
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
                              _searchQuery.isEmpty
                                  ? 'No folders yet'
                                  : 'No folders match "$_searchQuery"',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _createNewFolder,
                                icon: const Icon(Icons.create_new_folder_outlined),
                                label: const Text('Create a folder'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initFolders,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _filteredFolders.length,
                          itemBuilder: (context, index) {
                            final folder = _filteredFolders[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FolderImagesPage(folder: folder),
                                  ),
                                ).then((_) => _initFolders());
                              },
                              onLongPress: () => _showFolderOptions(folder),
                              borderRadius: BorderRadius.circular(16.0),
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16.0),
                                          topRight: Radius.circular(16.0),
                                        ),
                                        child: folder.thumbnailPath != null
                                            ? Image.file(
                                                File(folder.thumbnailPath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                                    child: Icon(
                                                      Icons.error_outline,
                                                      size: 60,
                                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Theme.of(context).colorScheme.secondaryContainer,
                                                child: Icon(
                                                  Icons.folder_outlined,
                                                  size: 60,
                                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            folder.name,
                                            style: Theme.of(context).textTheme.titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${folder.fileCount} ${folder.fileCount == 1 ? 'file' : 'files'}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFolder,
        child: const Icon(Icons.add),
      ),
    );
  }
}