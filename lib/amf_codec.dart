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