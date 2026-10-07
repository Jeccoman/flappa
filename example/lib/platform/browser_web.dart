import 'dart:js_interop';
import 'dart:convert';

@JS('window.localStorage.getItem')
external JSString? _read(JSString key);
@JS('window.localStorage.setItem')
external void _write(JSString key, JSString value);
@JS('document.createElement')
external _Anchor _element(JSString tag);

extension type _Anchor(JSObject _) implements JSObject {
  external set href(JSString value);
  external set download(JSString value);
  external void click();
}

String? readDraft() => readStorage('flappa.playground.v1');

String? readStorage(String key) {
  try {
    return _read(key.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

bool saveDraft(String value) => saveStorage('flappa.playground.v1', value);

bool saveStorage(String key, String value) {
  try {
    _write(key.toJS, value.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

bool downloadText(String filename, String content) {
  try {
    final anchor = _element('a'.toJS);
    anchor.href = Uri.dataFromString(
      content,
      mimeType: 'text/plain',
      encoding: utf8,
    ).toString().toJS;
    anchor.download = filename.toJS;
    anchor.click();
    return true;
  } catch (_) {
    return false;
  }
}

bool downloadBytes(String filename, List<int> bytes, String mimeType) {
  try {
    final anchor = _element('a'.toJS);
    anchor.href = Uri.dataFromBytes(bytes, mimeType: mimeType).toString().toJS;
    anchor.download = filename.toJS;
    anchor.click();
    return true;
  } catch (_) {
    return false;
  }
}
