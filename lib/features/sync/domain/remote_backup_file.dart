class RemoteBackupFile {
  final String name;
  final String url;
  final DateTime modified;
  final int size;

  RemoteBackupFile({
    required this.name,
    required this.url,
    required this.modified,
    required this.size,
  });
}
