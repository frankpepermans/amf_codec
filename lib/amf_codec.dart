// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The amf_codec library.
///
/// This is an awesome library. More dartdocs go here.
library amf_codec;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

// TODO: Export any libraries intended for clients of this package.

part 'src/amf_serialization_type.dart';
part 'src/property_info.dart';
part 'src/traits_info.dart';
part 'src/amf3_input.dart';
part 'src/amf3_output.dart';

part 'src/messaging/abstract_message.dart';
part 'src/messaging/async_message.dart';
part 'src/messaging/command_message.dart';
part 'src/messaging/remoting_message.dart';
part 'src/messaging/rpcuid.dart';

part 'src/channels/amf_channel.dart';
part 'src/channels/long_poll_channel.dart';

typedef dynamic ReadExternalHandler(dynamic entity, AMF3Input input);
typedef dynamic WriteExternalHandler(dynamic entity, AMF3Output output);
typedef dynamic EntitySpawnMethod(String type);
typedef dynamic Transformer(dynamic entity);

void messageOutputPropertyWriter(AsyncMessage M, AMF3Output output) {
  if (M is CommandMessage) _CommandMessageHelper.writeProperties(output);
  else if (M is RemotingMessage) _RemotingMessageHelper.writeProperties(output);
}

void messageOutputWriter(AsyncMessage M, AMF3Output output) {
  if (M is CommandMessage) _CommandMessageHelper.writeToOutput(M, output);
  else if (M is RemotingMessage) _RemotingMessageHelper.writeToOutput(M, output);
}

const List<int> AMF0_PREFIX = const <int>[0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x04, 0x6E, 0x75, 0x6C, 0x6C, 0x00, 0x03, 0x2F, 0x31, 0x32, 0x00, 0x00, 0x01, 0xA5, 0x0A, 0x00, 0x00, 0x00, 0x01, 0x11, 0x0A, 0x81, 0x13];


Future<Map> sendAMF0Message(AsyncMessage message, String url) async {
  final List<int> AMFList = new List<int>.from(AMF0_PREFIX);
  dynamic response;
  
  final Uint8List L = new AMF3Output(message, messageOutputWriter).writeObject().buffer.asUint8List();
          
  for (int i=3, len=L.length; i<len; i++) AMFList.add(L[i]);
  
  final HttpRequest request = await HttpRequest.request(
    url,
    method: 'POST', 
    mimeType: 'application/x-amf',
    sendData: new Int8List.fromList(AMFList),
    responseType: 'arraybuffer',
    requestHeaders: <String, String>{'Content-Type': 'application/x-amf'}
  );
  
  if (request.response is ByteBuffer)
    response = new AMF3Input(new ByteData.view(request.response), null, null, null).readObject();
  
  return (response != null) ? response.first as Map : null;
}