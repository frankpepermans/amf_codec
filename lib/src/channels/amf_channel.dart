part of amf_codec;

abstract class AMFChannel {
  
  Stream stream;
  
  Future<bool> initialize() async => null;
  
}