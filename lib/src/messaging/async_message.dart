part of amf_codec;

class AsyncMessage extends AbstractMessage {
  
  String get refClassName => 'flex.messaging.messages.AsyncMessage';
  
  static const String SUBTOPIC_HEADER = 'DSSubtopic';

  static const int _CORRELATION_ID_FLAG = 1;
  static const int _CORRELATION_ID_BYTES_FLAG = 2;
  
  String _correlationId;
  ByteData _correlationIdBytes;
  
  String get correlationId => _correlationId;
  void set correlationId(String value) {
    if (value != _correlationId) {
      _correlationId = value;
      _correlationIdBytes = null;
    }
  }
  
  AsyncMessage([Map body, Map headers]) {
    _correlationId = '';
    
    if (body != null) this.body = body;
        
    if (headers != null) this.headers = headers;
  }
  
  @override
  void writeExternal(AMF3Output BA) {
    super.writeExternal(BA);

    if (_correlationIdBytes == null) _correlationIdBytes = RPCUID.toByteArray(_correlationId);

    int flags = 0;

    if (_correlationId != null && _correlationIdBytes == null) flags |= _CORRELATION_ID_FLAG;

    if (_correlationIdBytes != null) flags |= _CORRELATION_ID_BYTES_FLAG;

    BA.write(WriteCommand.SET_INT8, flags);

    if (correlationId != null && _correlationIdBytes == null) BA.writeObjectValue(correlationId);

    if (_correlationIdBytes != null) BA.writeObjectValue(_correlationIdBytes);
  }
}