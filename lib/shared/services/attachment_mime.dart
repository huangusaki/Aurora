class AttachmentMime {
  const AttachmentMime._();

  static String fromPath(String path) {
    final normalized = path.toLowerCase();

    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.webp')) return 'image/webp';
    if (normalized.endsWith('.gif')) return 'image/gif';
    if (normalized.endsWith('.bmp')) return 'image/bmp';

    if (normalized.endsWith('.mp3')) return 'audio/mpeg';
    if (normalized.endsWith('.wav')) return 'audio/wav';
    if (normalized.endsWith('.m4a')) return 'audio/x-m4a';
    if (normalized.endsWith('.flac')) return 'audio/flac';
    if (normalized.endsWith('.ogg')) return 'audio/ogg';
    if (normalized.endsWith('.opus')) return 'audio/opus';
    if (normalized.endsWith('.aac')) return 'audio/aac';

    if (normalized.endsWith('.mp4')) return 'video/mp4';
    if (normalized.endsWith('.mov')) return 'video/quicktime';
    if (normalized.endsWith('.avi')) return 'video/x-msvideo';
    if (normalized.endsWith('.webm')) return 'video/webm';
    if (normalized.endsWith('.mkv')) return 'video/x-matroska';
    if (normalized.endsWith('.flv')) return 'video/x-flv';
    if (normalized.endsWith('.3gp')) return 'video/3gpp';
    if (normalized.endsWith('.mpg') || normalized.endsWith('.mpeg')) {
      return 'video/mpeg';
    }

    if (normalized.endsWith('.pdf')) return 'application/pdf';
    if (normalized.endsWith('.txt')) return 'text/plain';
    if (normalized.endsWith('.md')) return 'text/markdown';
    if (normalized.endsWith('.csv')) return 'text/csv';
    if (normalized.endsWith('.json')) return 'application/json';
    if (normalized.endsWith('.xml')) return 'application/xml';
    if (normalized.endsWith('.yaml') || normalized.endsWith('.yml')) {
      return 'text/yaml';
    }
    if (normalized.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (normalized.endsWith('.doc')) return 'application/msword';
    if (normalized.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (normalized.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (normalized.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (normalized.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';

    return 'application/octet-stream';
  }

  static String guessImageFromUrl(String url) {
    final normalized = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.webp')) return 'image/webp';
    if (normalized.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  static bool isTextLike(String mimeType) {
    return mimeType.startsWith('text/') ||
        mimeType == 'application/json' ||
        mimeType == 'application/xml';
  }

  static bool shouldInlineBinary(String mimeType) {
    return mimeType.startsWith('image/') ||
        mimeType.startsWith('audio/') ||
        mimeType.startsWith('video/') ||
        mimeType == 'application/pdf';
  }

  static bool isWordDocument(String mimeType) {
    return mimeType.endsWith('officedocument.wordprocessingml.document') ||
        mimeType == 'application/msword';
  }

  static bool isOfficeDocument(String mimeType) {
    return mimeType.contains('officedocument') ||
        mimeType == 'application/vnd.ms-excel' ||
        mimeType == 'application/vnd.ms-powerpoint';
  }
}
