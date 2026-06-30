import 'package:logging/logging.dart';

final log = Logger('ExampleLogger');

void initLog() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  recordStackTraceAtLevel = Level.ALL;
  Logger.root.onRecord.listen((record) {
    String location = '';
    if (record.stackTrace != null) {
      location = _extractLocation(record.stackTrace!);
    }
    print(
      '${record.level.name}: ${record.time}: ${record.message}  \n ${location}',
    );
  });
}

String _extractLocation(StackTrace stackTrace) {
  try {
    // 转换为字符串并按行切分
    final lines = stackTrace.toString().split('\n');

    // 寻找第一条包含当前项目/文件路径的堆栈（跳过 logging 包自身的内部堆栈）
    // 通常在 logging 包装器下，第 1 或第 2 行就是实际调用位置
    for (var line in lines) {
      if (line.contains('.dart') && !line.contains('package:logging/')) {
        // 匹配括号中的路径，例如 (package:example/main.dart:25:5) 或 (file:///xxx/main.dart:25:5)
        final match = RegExp(r'\(([^)]+)\)').firstMatch(line);
        if (match != null) {
          return '(${match.group(1)})'; // 返回如 (package:my_project/main.dart:30:5)
        }
      }
    }
  } catch (_) {
    // 容错处理
  }
  return '';
}
