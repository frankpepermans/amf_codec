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
    
    final Map<String, dynamic> subscribeResponse = await _subscribe();
    
    dstClientId = subscribeResponse['headers']['DSDstClientId'];
    
    _poll();
    
    return true;
  }
  
  void beginPolling() {
    _poll();
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
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject().buffer.asUint8List(),
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
    CM.destination = 'com.capxd.view.instrument.data.bond.event';
    CM.timeToLive = 0;
    CM.headers = {AbstractMessage.ENDPOINT_HEADER: endPoint, CommandMessage.SELECTOR_HEADER: selector};
    
    final HttpRequest request = await HttpRequest.request(
      '${url}?m=${new DateTime.now().millisecondsSinceEpoch}', 
      method: 'POST', 
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject().buffer.asUint8List(),
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
      mimeType: 'application/x-amf',
      sendData: new AMF3Output([CM], messageOutputWriter).writeObject().buffer.asUint8List(),
      responseType: 'arraybuffer',
      requestHeaders: <String, String>{'Content-Type': 'application/x-amf'}
    );
    
    if (request.response is ByteBuffer) {
      try {
        response = new AMF3Input(new ByteData.view(request.response), _spawnHandler, _parseHandler, _transformer).readObject();
      } catch (error) {
        response = null;
      }
    }
    
    Map<String, dynamic> body;
    Map<String, dynamic> viewItems;
    
    if (response is Iterable) {
      response.forEach((Map<String, dynamic> entry) {
        body = entry['body'];
        viewItems = body['viewItems'];
        
        if (viewItems != null) viewItems.forEach((dynamic K, dynamic V) => _dataStreamController.add(V));
      });
      
      _poll();
    } else new Timer(const Duration(seconds: 3), _poll);
          
    return true;
  }
  
}