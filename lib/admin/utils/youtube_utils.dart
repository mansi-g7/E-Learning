String? extractYoutubeVideoId(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final plainIdPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  if (plainIdPattern.hasMatch(trimmed)) {
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return null;
  }

  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }

  if (uri.queryParameters['v']?.isNotEmpty ?? false) {
    return uri.queryParameters['v'];
  }

  if (uri.pathSegments.length >= 2) {
    final firstSegment = uri.pathSegments.first;
    if (firstSegment == 'embed' ||
        firstSegment == 'shorts' ||
        firstSegment == 'v') {
      return uri.pathSegments[1];
    }
  }

  return null;
}

String normalizeYoutubeWatchUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final videoId = extractYoutubeVideoId(trimmed);
  if (videoId != null) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return trimmed;
  }

  if (uri.scheme == 'http') {
    return uri.replace(scheme: 'https').toString();
  }

  return trimmed;
}
