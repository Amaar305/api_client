class DrfErrorParser {
  static String parse(dynamic data) {
    if (data == null) return '';

    if (data is String) return data.trim();

    if (data is List) {
      final parts = data.map(parse).where((e) => e.trim().isNotEmpty).toList();
      return parts.join('\n');
    }

    if (data is Map) {
      if (data.containsKey('detail')) {
        final v = data['detail'];
        final msg = parse(v);
        if (msg.isNotEmpty) return msg;
      }
      if (data.containsKey('non_field_errors')) {
        final v = data['non_field_errors'];
        final msg = parse(v);
        if (msg.isNotEmpty) return msg;
      }

      final lines = <String>[];
      void walk(String path, dynamic node) {
        if (node == null) return;

        if (node is String) {
          final key = _prettyKey(path);
          lines.add(key.isEmpty ? node.trim() : '$key: ${node.trim()}');
          return;
        }

        if (node is List) {
          if (node.isEmpty) return;
          for (var i = 0; i < node.length; i++) {
            final item = node[i];
            final nextPath = path.isEmpty ? '[$i]' : '$path[$i]';
            walk(nextPath, item);
          }
          return;
        }

        if (node is Map) {
          if (node.isEmpty) return;
          node.forEach((k, v) {
            final nextPath = path.isEmpty ? '$k' : '$path.$k';
            walk(nextPath, v);
          });
          return;
        }
      }

      walk('', data);
      final unique = lines.where((e) => e.trim().isNotEmpty).toSet().toList();
      return unique.join('\n');
    }

    return data.toString();
  }

  static String _prettyKey(String key) {
    if (key.isEmpty) return '';
    final parts = key.split('.');
    return parts
        .map((p) => p.replaceAll('_', ' '))
        .map((p) => p.startsWith('[') ? p : _capitalize(p))
        .join('.');
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}