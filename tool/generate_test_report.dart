import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/generate_test_report.dart <output.html> <input1.json> [<input2.json> ...]');
    exit(1);
  }

  final outputPath = args[0];
  final inputPaths = args.sublist(1);

  final allTests = <ParsedTest>[];
  var overallSuccess = true;

  for (final inputPath in inputPaths) {
    final file = File(inputPath);
    if (!file.existsSync()) {
      stderr.writeln('Input file not found: $inputPath');
      exit(2);
    }

    final content = file.readAsStringSync();
    final lines = const LineSplitter().convert(content);
    final tests = <int, ParsedTest>{};
    final suiteNames = <int, String>{};

    for (final raw in lines) {
      if (raw.trim().isEmpty) continue;
      final event = _tryParseJson(raw);
      if (event == null) continue;
      if (event is! Map<String, dynamic>) continue;
      final type = event['type'] as String?;

      if (type == 'suite') {
        final suite = event['suite'] as Map<String, dynamic>?;
        if (suite != null) {
          final id = suite['id'] as int?;
          final path = suite['path'] as String?;
          if (id != null && path != null) {
            suiteNames[id] = path;
          }
        }
      }

      if (type == 'testStart') {
        final test = event['test'] as Map<String, dynamic>;
        final id = test['id'] as int;
        final suiteID = test['suiteID'] as int?;
        final suiteName = suiteID != null ? suiteNames[suiteID] ?? 'unknown' : 'unknown';

        tests[id] = ParsedTest(
          name: test['name'] as String,
          result: 'running',
          hidden: test['hidden'] as bool? ?? false,
          skipped: (test['metadata'] as Map<String, dynamic>)['skip'] as bool? ?? false,
          time: null,
          suite: suiteName,
          source: inputPath,
        );
      } else if (type == 'testDone') {
        final id = event['testID'] as int;
        final result = event['result'] as String? ?? 'unknown';
        final skipped = event['skipped'] as bool? ?? false;
        final hidden = event['hidden'] as bool? ?? false;
        final time = event['time'] as num?;

        final test = tests[id];
        if (test != null) {
          test.result = result;
          test.skipped = skipped;
          test.hidden = hidden;
          test.time = time;
        }
      } else if (type == 'done') {
        overallSuccess = overallSuccess && (event['success'] as bool? ?? overallSuccess);
      }
    }

    allTests.addAll(tests.values);
  }

  final visibleTests = allTests.where((test) => !test.hidden).toList();
  final totalTests = visibleTests.length;
  final passed = visibleTests.where((test) => test.result == 'success').length;
  final failed = visibleTests.where((test) => test.result == 'failure').length;
  final skipped = visibleTests.where((test) => test.skipped).length;
  final hiddenTests = allTests.where((test) => test.hidden).length;

  final html = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<title>Flutter Test Report</title>')
    ..writeln('<style>body{font-family:Arial,Helvetica,sans-serif;margin:24px;}table{border-collapse:collapse;width:100%;}th,td{border:1px solid #ddd;padding:8px;text-align:left;}th{background:#f4f4f4;}tr:nth-child(even){background:#fafafa;} .passed{color:green;font-weight:bold;} .failed{color:red;font-weight:bold;} .skipped{color:orange;font-weight:bold;}</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<h1>Flutter Test Report</h1>')
    ..writeln('<p><strong>Overall success:</strong> ${overallSuccess ? 'yes' : 'no'}</p>')
    ..writeln('<p><strong>Total tests:</strong> $totalTests</p>')
    ..writeln('<p><strong>Passed:</strong> $passed</p>')
    ..writeln('<p><strong>Failed:</strong> $failed</p>')
    ..writeln('<p><strong>Skipped:</strong> $skipped</p>')
    ..writeln('<p><strong>Hidden tests:</strong> $hiddenTests</p>')
    ..writeln('<table>')
    ..writeln('<thead><tr><th>Suite</th><th>Test name</th><th>Status</th><th>Skipped</th><th>Duration (ms)</th><th>Source</th></tr></thead>')
    ..writeln('<tbody>');

  for (final test in visibleTests) {
    final name = htmlEscape(test.name);
    final result = test.result;
    final skippedFlag = test.skipped;
    final duration = test.time?.toString() ?? '-';
    final css = result == 'success'
        ? 'passed'
        : result == 'failure'
            ? 'failed'
            : 'skipped';
    final suite = htmlEscape(test.suite);
    final source = htmlEscape(test.source);

    html.writeln('<tr>');
    html.writeln('<td>$suite</td>');
    html.writeln('<td>$name</td>');
    html.writeln('<td class="$css">$result</td>');
    html.writeln('<td>${skippedFlag ? 'yes' : 'no'}</td>');
    html.writeln('<td>$duration</td>');
    html.writeln('<td>$source</td>');
    html.writeln('</tr>');
  }

  html.writeln('</tbody></table>');
  html.writeln('</body></html>');

  File(outputPath).writeAsStringSync(html.toString());
  stdout.writeln('Report generated: $outputPath');
}

class ParsedTest {
  ParsedTest({
    required this.name,
    required this.result,
    required this.hidden,
    required this.skipped,
    required this.time,
    required this.suite,
    required this.source,
  });

  final String name;
  String result;
  bool hidden;
  bool skipped;
  num? time;
  final String suite;
  final String source;
}

String htmlEscape(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

dynamic _tryParseJson(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}
