part of amf_codec;

class RemotingMessage extends AsyncMessage {
  
  @override
  String get refClassName => 'flex.messaging.messages.RemotingMessage';
  
  static const String SUBSCRIBE_OPERATION = 'subscribe';
  
  String operation;
  String source;
  
  RemotingMessage() : super();
}

class _RemotingMessageHelper {
  
  static void writeProperties(AMF3Output output) {
    output._writeStringWithoutType('operation');
    output._writeStringWithoutType('source');
    output._writeStringWithoutType('headers');
    output._writeStringWithoutType('timestamp');
    output._writeStringWithoutType('destination');
    output._writeStringWithoutType('clientId');
    output._writeStringWithoutType('body');
    output._writeStringWithoutType('messageId');
    output._writeStringWithoutType('timeToLive');
  }
  
  static void writeToOutput(RemotingMessage M, AMF3Output output) {
    output.writeObjectValue(M.operation);
    output.writeObjectValue(M.source);
    output.writeObjectValue(M.headers);
    output.writeObjectValue(M.timestamp);
    output.writeObjectValue(M.destination);
    output.writeObjectValue(M.clientId);
    output.writeObjectValue(M.body);
    output.writeObjectValue(M.messageId);
    output.writeObjectValue(M.timeToLive);
  }
  
}