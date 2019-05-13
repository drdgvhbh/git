import 'dart:collection';

import 'bot.dart';
import 'util.dart';

final _headerRegExp = RegExp(r'^(commit|tree|parent|author|committer) (.+)$');
final _mergeTagRegExp = RegExp(r'^mergetag .*$');
final _mergeTagBodyRegExp = RegExp(r'^ [^\s].*$|^ $');
final _authorHeader =
    RegExp(r'^(author) (.+?(?= <)) <(.+?(?=>))> ([0-9]+) (-[0-9]{4})$');

class Commit {
  final String treeSha;
  final String author;
  final String committer;
  final String message;
  final String content;
  final List<String> parents;

  Commit._(this.treeSha, this.author, this.committer, this.message,
      this.content, List<String> parents)
      : parents = UnmodifiableListView<String>(parents) {
    requireArgumentValidSha1(treeSha, 'treeSha');
    for (final parent in parents) {
      requireArgumentValidSha1(parent, 'parents');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    final stringLineReader = StringLineReader(content);
    final tuple = _CommitParser(stringLineReader, false).parse();
    assert(tuple.item1 == null);
    return tuple.item2;
  }

  static Map<String, Commit> parseRawRevList(String content) {
    final slr = StringLineReader(content);

    final commits = <String, Commit>{};

    while (slr.position != null && slr.position < content.length) {
      final tuple = _CommitParser(slr, true).parse();
      commits[tuple.item1] = tuple.item2;
    }

    return commits;
  }
}

class _CommitParser {
  String _commitSha;
  String _treeSha;
  final _parents = <String>[];
  String _author;
  String _committer;
  String _message;

  final StringLineReader _slr;
  final bool _isRevParse;

  _CommitParser(this._slr, this._isRevParse);

  Tuple<String, Commit> parse() {
    assert(_slr != null);
    assert(_slr.position != null);

    final startSpot = _slr.position;

    _parseHeaderBlock();
    _consumeMergeTag();
    // consumeSpaceBetweenHeaderAndMessageBlock();
    _parseMessage();

    final endSpot = _slr.position;

    final content = _slr.source.substring(startSpot, endSpot);

    return Tuple(_commitSha,
        Commit._(_treeSha, _author, _committer, _message, content, _parents));
  }

  void _parseHeaderBlock() {
    var nextLine = _slr.peekNextLine();

    while (_headerRegExp.hasMatch(nextLine)) {
      final match = _headerRegExp.allMatches(nextLine).single;
      final headerKey = match.group(1);
      final headerValue = match.group(2);

      switch (headerKey) {
        case 'commit':
          _commitSha = headerValue;
          break;
        case 'tree':
          _treeSha = headerValue;
          break;
        case 'parent':
          _parents.add(headerValue);
          break;
        case 'author':
          _author = headerValue;
          break;
        case 'committer':
          _committer = headerValue;
          break;
        default:
          break;
      }

      nextLine = _slr.readNextLine();
    }
  }

  void _consumeMergeTag() {
    var nextLine = _slr.peekNextLine();
    if (_mergeTagRegExp.hasMatch(nextLine)) {
      _slr.readNextLine();
    }

    nextLine = _slr.peekNextLine();
    while (_mergeTagBodyRegExp.hasMatch(nextLine)) {
      nextLine = _slr.readNextLine();
    }
  }

  void consumeSpaceBetweenHeaderAndMessageBlock() {
    _slr.readNextLine();
  }

  void _parseMessage() {
    String nextLine;
    if (_isRevParse) {
      final msgLines = <String>[];
      nextLine = _slr.readNextLine();

      const revParseMessagePrefix = '    ';
      while (nextLine != null && nextLine.startsWith(revParseMessagePrefix)) {
        msgLines.add(nextLine.substring(revParseMessagePrefix.length));
        nextLine = _slr.readNextLine();
      }

      _message = msgLines.join('\n');
    } else {
      _message = _slr.readToEnd();
      assert(_message.endsWith('\n'));
      final originalMessageLength = _message.length;
      _message = _message.trim();
      // message should be trimmed by git, so the only diff after trim
      // should be 1 character - the removed new line
      assert(_message.length + 1 == originalMessageLength);
    }
  }
}
