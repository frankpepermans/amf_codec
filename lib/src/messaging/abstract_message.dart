part of amf_codec;

abstract class AbstractMessage {
  
  static const String DESTINATION_CLIENT_ID_HEADER = 'DSDstClientId';
  static const String ENDPOINT_HEADER = 'DSEndpoint';
  static const String FLEX_CLIENT_ID_HEADER = 'DSId';
  static const String PRIORITY_HEADER = 'DSPriority';
  static const String REMOTE_CREDENTIALS_HEADER = 'DSRemoteCredentials';
  static const String REMOTE_CREDENTIALS_CHARSET_HEADER = 'DSRemoteCredentialsCharset';
  static const String REQUEST_TIMEOUT_HEADER = 'DSRequestTimeout';
  static const String STATUS_CODE_HEADER = 'DSStatusCode';
  
  static const int _HAS_NEXT_FLAG = 128;
  static const int _BODY_FLAG = 1;
  static const int _CLIENT_ID_FLAG = 2;
  static const int _DESTINATION_FLAG = 4;
  static const int _HEADERS_FLAG = 8;
  static const int _MESSAGE_ID_FLAG = 16;
  static const int _TIMESTAMP_FLAG = 32;
  static const int _TIME_TO_LIVE_FLAG = 64;
  static const int _CLIENT_ID_BYTES_FLAG = 1;
  static const int _MESSAGE_ID_BYTES_FLAG = 2;
  
  String _clientId;
  ByteData _clientIdBytes;
  
  String _messageId;
  ByteData _messageIdBytes;
  
  String destination;
  Map _headers;
  dynamic body;
  
  int timeToLive;
  int timestamp;
  
  String get clientId => _clientId;
  void set clientId(String value) {
    if (value != _clientId) {
      _clientId = value;
      _clientIdBytes = null;
    }
  }
  
  String get messageId {
    if (_messageId == null) _messageId = RPCUID.create();
    
    return _messageId;
  }
  
  void set messageId(String value) {
    if (value != _messageId) {
      _messageId = value;
      _messageIdBytes = null;
    }
  }
  
  Map get headers {
    if (_headers == null) return {};
    
    return _headers;
  }
  
  void set headers(Map value) {
    _headers = value;
  }
  
  ByteData toByteArray() => new AMF3Output(this, (AbstractMessage M, AMF3Output output) => M.writeExternal(output)).writeObject();
  
  List<int> _readFlags(ByteData input) {
    bool hasNextFlag = true;
    int pos = 0;
    List<int> L = <int>[];
  
    while (hasNextFlag && input.lengthInBytes < pos) {
      int flags = input.getInt8(pos);
      
      L.add(flags);
    
      if ((flags & _HAS_NEXT_FLAG) != 0) hasNextFlag = true;
      else hasNextFlag = false;
    }
  
    return L;
  }
  
  void writeExternalBody(AMF3Output BA) => BA.writeObjectValue(body);
  
  void writeExternal(AMF3Output BA) {
      int flags = 0;
      final String checkForMessageId = messageId;

      if (_clientIdBytes == null) _clientIdBytes = RPCUID.toByteArray(_clientId);
      if (_messageIdBytes == null) _messageIdBytes = RPCUID.toByteArray(_messageId);

      if (body != null) flags |= _BODY_FLAG;

      if (clientId != null && _clientIdBytes == null) flags |= _CLIENT_ID_FLAG;

      if (destination != null) flags |= _DESTINATION_FLAG;

      if (headers != null) flags |= _HEADERS_FLAG;

      if (messageId != null && _messageIdBytes == null) flags |= _MESSAGE_ID_FLAG;

      if (timestamp != 0) flags |= _TIMESTAMP_FLAG;

      if (timeToLive != 0) flags |= _TIME_TO_LIVE_FLAG;

      if (_clientIdBytes != null || _messageIdBytes != null) flags |= _HAS_NEXT_FLAG;

      BA.write(WriteCommand.SET_INT8, flags);

      flags = 0;

      if (_clientIdBytes != null) flags |= _CLIENT_ID_BYTES_FLAG;

      if (_messageIdBytes != null) flags |= _MESSAGE_ID_BYTES_FLAG;

      if (flags != 0) BA.write(WriteCommand.SET_INT8, flags);

      if (body != null) writeExternalBody(BA);

      if (clientId != null && _clientIdBytes == null) BA.writeObjectValue(clientId);

      if (destination != null) BA.writeObjectValue(destination);

      if (headers != null) BA.writeObjectValue(headers);

      if (messageId != null && _messageIdBytes == null) BA.writeObjectValue(messageId);

      if (timestamp != 0) BA.writeObjectValue(timestamp);

      if (timeToLive != 0) BA.writeObjectValue(timeToLive);

      if (_clientIdBytes != null) BA.writeObjectValue(_clientIdBytes);

      if (_messageIdBytes != null) BA.writeObjectValue(_messageIdBytes);
  }
}