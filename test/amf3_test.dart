library test.amf3_test;

import 'dart:async';
import 'dart:typed_data';

import 'package:amf_codec/amf_codec.dart';

final String flexClientId = RPCUID.create();

Future main() async {
  _test('test');
}

void _test(dynamic value) {
  final ByteData BA = new AMF3Output(value, messageOutputWriter).writeObject();
  final dynamic S = new AMF3Input(BA, null, null, null).readObject();
  
  //if (value != S && !(value is Iterable) && !(value is Map)) throw new CodecError('Codec failed. in[$value] out[S]');
  
  print('Successfully coded :$value: into :$S:, resulting byte size is ${BA.buffer.lengthInBytes}');
}

class CodecError extends AssertionError {
  
  final String message;
  
  CodecError(this.message) : super();
  
}