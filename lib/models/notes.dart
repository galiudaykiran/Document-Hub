class FolderNotes {
  final String folderPath;
  String notesContent;
  DateTime? lastEdited;

  FolderNotes({
    required this.folderPath,
    this.notesContent = '',
    this.lastEdited,
  });

  // Convert a FolderNotes object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'folderPath': folderPath,
      'notesContent': notesContent,
      'lastEdited': lastEdited?.toIso8601String(),
    };
  }

  // Extract a FolderNotes object from a Map object
  factory FolderNotes.fromMap(Map<String, dynamic> map) {
    return FolderNotes(
      folderPath: map['folderPath'],
      notesContent: map['notesContent'],
      lastEdited: map['lastEdited'] != null ? DateTime.parse(map['lastEdited']) : null,
    );
  }
}