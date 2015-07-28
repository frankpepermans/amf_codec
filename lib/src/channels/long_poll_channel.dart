part of amf_codec;

class LongPollChannel extends AMFChannel {
  
  static const List<String> _LONG_POLLING = const <String>['long-polling'];
  
  final String endPoint;
  final String url;
  final String selector;
  final String destination;
  final StreamController _dataStreamController = new StreamController();
  
  ReadExternalHandler _parseHandler;
  EntitySpawnMethod _spawnHandler;
  Transformer _transformer;
  
  String clientId;
  String dstClientId;
  int reconnectInterval;
  int reconnectMaxAttempts;
  bool encodeMessageBody;
  Stream stream;
  
  LongPollChannel(this.url, this.endPoint, this.destination, this.selector, [EntitySpawnMethod spawnHandler=null, ReadExternalHandler parseHandler=null, Transformer transformer=null]) {
    this._spawnHandler = spawnHandler;
    this._parseHandler = parseHandler;
    this._transformer = transformer;
    
    stream = _dataStreamController.stream.asBroadcastStream();
  }
  
  @override
  Future<bool> initialize() async {
    final Map<String, dynamic> pingResponse = await _ping();
    
    clientId = pingResponse['clientId'];
    reconnectInterval = (pingResponse['body']['reconnect-interval-ms'] as double).toInt();
    reconnectMaxAttempts = (pingResponse['body']['reconnect-max-attempts'] as double).toInt();
    encodeMessageBody = pingResponse['body']['encode-message-body'];
    
    return true;
  }
  
  Future<bool> beginPolling() async {
    final Map<String, dynamic> subscribeResponse = await _subscribe();
    
    clientId = subscribeResponse['clientId'];
    dstClientId = subscribeResponse['headers']['DSDstClientId'];
    
    return await _poll();
  }
  
  Future<Map> _ping() async {
    final CommandMessage CM = new CommandMessage();
    dynamic response;
      
    CM.operation = CommandMessage.CLIENT_PING_OPERATION;
    CM.messageId = RPCUID.create();
    CM.timestamp = new DateTime.now().millisecondsSinceEpoch;
    CM.timeToLive = 0;
    CM.headers = {AbstractMessage.ENDPOINT_HEADER: endPoint, 'DSSupportedConnectionType': _LONG_POLLING};
    
    final HttpRequest request = await HttpRequest.request(
      '${url}?m=${new DateTime.now().millisecondsSinceEpoch}',
      method: 'POST', 
      withCredentials: true,
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject(),
      responseType: 'arraybuffer',
      requestHeaders: <String, String>{'Content-Type': 'application/x-amf'}
    );
    
    if (request.response is ByteBuffer) {
      response = new AMF3Input(new ByteData.view(request.response), null, null, null).readObject();
    }
    
    return (response != null) ? response.first as Map : null;
  }
  
  Future<Map> _subscribe() async {
    final CommandMessage CM = new CommandMessage();
    dynamic response;
      
    CM.operation = CommandMessage.SUBSCRIBE_OPERATION;
    CM.clientId = clientId;
    CM.messageId = RPCUID.create();
    CM.timestamp = new DateTime.now().millisecondsSinceEpoch;
    CM.destination = destination;
    CM.timeToLive = 0;
    CM.headers = {AbstractMessage.ENDPOINT_HEADER: endPoint, CommandMessage.SELECTOR_HEADER: selector};
    
    final HttpRequest request = await HttpRequest.request(
      '${url}?m=${new DateTime.now().millisecondsSinceEpoch}', 
      method: 'POST', 
      withCredentials: true,
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject(),
      responseType: 'arraybuffer',
      requestHeaders: <String, String>{'Content-Type': 'application/x-amf'}
    );
    
    if (request.response is ByteBuffer)
      response = new AMF3Input(new ByteData.view(request.response), null, null, null).readObject();
    
    return (response != null) ? response.first as Map : null;
  }
  
  Future<bool> _poll() async {
    final CommandMessage CM = new CommandMessage();
    dynamic response;
      
    CM.operation = 20;
    CM.clientId = clientId;
    CM.messageId = RPCUID.create();
    CM.timestamp = new DateTime.now().millisecondsSinceEpoch;
    CM.timeToLive = 0;
    CM.headers = {AbstractMessage.ENDPOINT_HEADER: endPoint};
    
    final HttpRequest request = await HttpRequest.request(
      '${url}?m=${new DateTime.now().millisecondsSinceEpoch}', 
      method: 'POST', 
      withCredentials: true,
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject(),
      responseType: 'arraybuffer',
      requestHeaders: <String, String>{'Content-Type': 'application/x-amf'}
    );
    
    if (request.response is ByteBuffer) {
      try {
        response = new AMF3Input(new ByteData.view(request.response), _spawnHandler, _parseHandler, _transformer).readObject();
      } catch (error) {
        response = null;
        
        print(error);
      }
    }
    
    if (response is Iterable) {
      response.forEach(_decodeBody);
      
      _poll();
    } else if (response is Map) {
      _decodeBody(response);
      
      _poll();
    } else new Timer(const Duration(seconds: 3), _poll);
          
    return true;
  }
  
  bool _decodeBody(Map<String, dynamic> entry) {
    if (entry != null) {
      final Map<String, dynamic> body = entry['body'];
      
      if (body != null) {
        final bool endOfSequence = body['endOfSequence'];
        final Map<String, dynamic> viewItems = body['viewItems'];
        final dynamic viewEntity = body['viewEntity'];
        
        if (viewItems != null) viewItems.forEach((_, dynamic V) => _dataStreamController.add(V));
        if (viewEntity != null) _dataStreamController.add(viewEntity);
        
        return endOfSequence;
      }
    }
    
    return false;
  }
  
}