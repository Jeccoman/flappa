final _storage = <String, String>{};
String? readDraft() => readStorage('flappa.playground.v1');
bool saveDraft(String value) => saveStorage('flappa.playground.v1', value);
String? readStorage(String key) => _storage[key];
bool saveStorage(String key, String value) {
  _storage[key] = value;
  return false;
}

bool downloadText(String filename, String content) => false;
bool downloadBytes(String filename, List<int> bytes, String mimeType) => false;
