import 'package:markdown/markdown.dart' as md;

void main() {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
  );
  try {
    print('Testing reference link [text][2]');
    final nodes = document.parseLines(['[text][2]']);
    print('Parsed successfully: \ nodes');
  } catch (e, s) {
    print('Caught error: \');
    print(s);
  }
}
