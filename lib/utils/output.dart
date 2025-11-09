import 'dart:convert';
import 'dart:io';

import 'package:tint/tint.dart';

void printInfo(String message, {IOSink? sink}) {
  (sink ?? stdout).writeln(message.cyan());
}

void printSuccess(String message, {IOSink? sink}) {
  (sink ?? stdout).writeln(message.green());
}

void printError(String message, {IOSink? sink}) {
  (sink ?? stderr).writeln(message.red());
}

void printObject(Object? data, {IOSink? sink}) {
  final target = sink ?? stdout;
  if (data == null) {
    target.writeln('null'.yellow());
    return;
  }

  if (data is String) {
    target.writeln(data.brightBlue());
    return;
  }

  if (data is List) {
    if (data.isEmpty) {
      target.writeln('[]'.yellow());
      return;
    }
    final allMaps = data.every((element) => element is Map);
    if (allMaps) {
      printTable(data, sink: target);
      return;
    }
  }

  if (data is Map) {
    printTable([data], sink: target);
    return;
  }

  final encoder = JsonEncoder.withIndent('  ');
  try {
    target.writeln(encoder.convert(data).brightBlue());
  } catch (_) {
    target.writeln(data.toString().brightBlue());
  }
}

void printTable(List<dynamic> items, {IOSink? sink, List<String>? columns}) {
  final target = sink ?? stdout;
  if (items.isEmpty) {
    target.writeln('No data.'.yellow());
    return;
  }

  final normalizedRows = items.map<Map<String, String>>(_normalizeRow).toList();
  final headers = columns ?? _collectHeaders(normalizedRows);
  final widths = <String, int>{};

  for (final header in headers) {
    widths[header] = header.length;
  }

  for (final row in normalizedRows) {
    for (final header in headers) {
      final value = row[header] ?? '';
      widths[header] = value.length > (widths[header] ?? 0)
          ? value.length
          : widths[header] ?? 0;
    }
  }

  final top = _buildBorder(headers, widths, '┌', '┬', '┐');
  final mid = _buildBorder(headers, widths, '├', '┼', '┤');
  final bottom = _buildBorder(headers, widths, '└', '┴', '┘');

  target.writeln(top);
  target.writeln(
    _buildRow(headers.map((h) => h.toUpperCase()), headers, widths).bold(),
  );
  target.writeln(mid);
  for (final row in normalizedRows) {
    target.writeln(
      _buildRow(headers.map((h) => row[h] ?? ''), headers, widths),
    );
  }
  target.writeln(bottom);
}

void printPaginatedResponse(Map<String, dynamic> payload, {IOSink? sink}) {
  final target = sink ?? stdout;
  final items = payload['items'];
  if (items is List) {
    printTable(items, sink: target);
  } else {
    target.writeln('items'.bold());
    printObject(items, sink: target);
  }

  final meta = payload['meta'];
  if (meta is Map) {
    final previous = meta['previous'];
    final next = meta['next'];
    target.writeln('\nPagination'.bold());
    target.writeln('  previous: ${_stringifyCell(previous)}');
    target.writeln('  next     : ${_stringifyCell(next)}');
  }

  final sort = payload['sort'];
  if (sort is Map) {
    target.writeln('Sort'.bold());
    target.writeln('  by   : ${_stringifyCell(sort['by'])}');
    target.writeln('  order: ${_stringifyCell(sort['order'])}');
  }
}

List<String> _collectHeaders(List<Map<String, String>> rows) {
  final ordered = <String>[];
  final seen = <String>{};
  for (final row in rows) {
    for (final entry in row.entries) {
      if (seen.add(entry.key)) {
        ordered.add(entry.key);
      }
    }
  }
  return ordered;
}

Map<String, String> _normalizeRow(dynamic item) {
  if (item is Map) {
    return item.map(
      (key, value) => MapEntry(key.toString(), _stringifyCell(value)),
    );
  }
  if (item == null) {
    return {'value': 'null'};
  }
  return {'value': _stringifyCell(item)};
}

String _stringifyCell(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return '"$value"';
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

String _buildBorder(
  List<String> headers,
  Map<String, int> widths,
  String left,
  String mid,
  String right,
) {
  final segments = headers
      .map((header) {
        final width = (widths[header] ?? header.length) + 2;
        return '─' * width;
      })
      .join(mid);
  return '$left$segments$right';
}

String _buildRow(
  Iterable<String> displayValues,
  List<String> headers,
  Map<String, int> widths,
) {
  final values = displayValues.toList();
  final buffer = StringBuffer('│');
  for (var index = 0; index < headers.length; index++) {
    final header = headers[index];
    final width = widths[header] ?? header.length;
    final cellValue = index < values.length ? values[index] : '';
    final padded = cellValue.padRight(width);
    buffer.write(' $padded │');
  }
  return buffer.toString();
}
