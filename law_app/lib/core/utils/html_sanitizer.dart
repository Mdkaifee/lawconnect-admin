class HtmlSanitizer {
  /// Strips all HTML tags and decodes common HTML entities
  static String stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    
    // Replace breaks & paragraphs with newlines
    String text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');

    // Remove any remaining tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Replace common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');

    // Clean up excessive blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Truncates text cleanly at a sentence or word boundary
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final sub = text.substring(0, maxLength);
    final lastSpace = sub.lastIndexOf(' ');
    if (lastSpace > 0) {
      return '${sub.substring(0, lastSpace)}...';
    }
    return '$sub...';
  }
}
