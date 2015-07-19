part of amf_codec;

class CommandMessage extends AsyncMessage {
  
  @override
  String get refClassName => 'flex.messaging.messages.CommandMessage';
  
  static const int SUBSCRIBE_OPERATION = 0;
  static const int UNSUBSCRIBE_OPERATION = 1;
  static const int POLL_OPERATION = 2;
  static const int CLIENT_SYNC_OPERATION = 4;
  static const int CLIENT_PING_OPERATION = 5;
  static const int CLUSTER_REQUEST_OPERATION = 7;
  static const int LOGIN_OPERATION = 8;
  static const int LOGOUT_OPERATION = 9;
  static const int SUBSCRIPTION_INVALIDATE_OPERATION = 10;
  static const int MULTI_SUBSCRIBE_OPERATION = 11;
  static const int DISCONNECT_OPERATION = 12;
  static const int TRIGGER_CONNECT_OPERATION = 13;
  static const int UNKNOWN_OPERATION = 10000;
  
  static const String MESSAGING_VERSION = 'DSMessagingVersion';
  static const String AUTHENTICATION_MESSAGE_REF_TYPE = 'flex.messaging.messages.AuthenticationMessage';
  static const String SELECTOR_HEADER = 'DSSelector';
  static const String PRESERVE_DURABLE_HEADER = 'DSPreserveDurable';    
  static const String NEEDS_CONFIG_HEADER = 'DSNeedsConfig';
  static const String ADD_SUBSCRIPTIONS = 'DSAddSub';
  static const String REMOVE_SUBSCRIPTIONS = 'DSRemSub';
  static const String SUBTOPIC_SEPARATOR = '_;_';
  static const String POLL_WAIT_HEADER = 'DSPollWait'; 
  static const String NO_OP_POLL_HEADER = 'DSNoOpPoll';
  static const String CREDENTIALS_CHARSET_HEADER = 'DSCredentialsCharset';  
  static const String MAX_FREQUENCY_HEADER = 'DSMaxFrequency';
  static const String HEARTBEAT_HEADER = 'DS<3';
  
  static const int _OPERATION_FLAG = 1;
  
  static dynamic operationTexts = null;
  
  int operation;
  
  CommandMessage() : super() {
    operation = UNKNOWN_OPERATION;
  }
  
  @override
  void writeExternal(AMF3Output BA) {
    super.writeExternal(BA);

    int flags = 0;

    if (operation != 0) flags |= _OPERATION_FLAG;

    BA.write(WriteCommand.SET_INT8, flags);

    if (operation != 0) BA.writeObjectValue(operation);
  }
}

class _CommandMessageHelper {
  
  static void writeProperties(AMF3Output output) {
    output._writeStringWithoutType('operation');
    output._writeStringWithoutType('correlationId');
    output._writeStringWithoutType('headers');
    output._writeStringWithoutType('timestamp');
    output._writeStringWithoutType('destination');
    output._writeStringWithoutType('clientId');
    output._writeStringWithoutType('body');
    output._writeStringWithoutType('messageId');
    output._writeStringWithoutType('timeToLive');
  }
  
  static void writeToOutput(CommandMessage M, AMF3Output output) {
    output.writeObjectValue(M.operation);
    output.writeObjectValue(M.correlationId);
    output.writeObjectValue(M.headers);
    output.writeObjectValue(M.timestamp);
    output.writeObjectValue(M.destination);
    output.writeObjectValue(M.clientId);
    output.writeObjectValue(M.body);
    output.writeObjectValue(M.messageId);
    output.writeObjectValue(M.timeToLive);
  }
  
}