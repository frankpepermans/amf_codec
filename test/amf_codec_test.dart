import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:amf_codec/amf_codec.dart';

void main() {
  final File file = new File('E:\\work\\production\\igindo\\dart\\amf_codec\\bin\\test.amf3');
  final List<int> bytes = file.readAsBytesSync();
  final ByteData BA = new ByteData.view(new Uint8List.fromList(bytes).buffer);
  final List list = new AMF3Input(BA).readObject();
  final Stream stream = new Stream.fromIterable(list);
  
  StreamTransformer transformer = new StreamTransformer.fromHandlers(handleData: (value, sink) {
    sink.add(new Entry(value['text'], value['language']));
  });
  
  stream.transform(transformer).listen((dynamic data) => print(data));
}

class Entry {
  
  final String text, language;
  
  Entry(this.text, this.language);
  
  String toString() => '$language => $text';
  
}