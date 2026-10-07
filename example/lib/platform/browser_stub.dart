String? _draft;
String? readDraft() => _draft;
bool saveDraft(String value) {
  _draft = value;
  return false;
}

bool downloadText(String filename, String content) => false;
