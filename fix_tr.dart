import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  final regex = RegExp(r"\(defaultValue:\s*'[^']+'\)");
  
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('defaultValue:')) {
      final newContent = content.replaceAll(regex, '');
      file.writeAsStringSync(newContent);
      print('Updated: ${file.path}');
    }
  }
}
