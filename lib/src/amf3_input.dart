part of amf_codec;

class AMF3Input {
  
  static const String UTF_DATA_FORMAT_EXCEPTION = "UTF Data Format Exception";
  static const String OBJECT_NOT_IEXT_EXCEPTION = "Object is not IExternalizable";
  
  final ByteData _input;
  final ReadExternalHandler _parseHandler;
  final EntitySpawnMethod _spawnHandler;
  final Transformer _transformer;
  final List<dynamic> _objectTable = <dynamic>[];
  final List<String> _stringTable = <String>[];
  final List<TraitsInfo> _traitsTable = <TraitsInfo>[];
  int _pos = 0;
  
  AMF3Input(this._input, this._spawnHandler, this._parseHandler, this._transformer);
  
  dynamic readObject() =>_readObjectValue(_input.getInt8(_pos++));
  
  dynamic _readObjectValue(int type) {
    switch (type) {
      case AMFSerializationType.UNDEFINED:  return null;
      case AMFSerializationType.NULL:       return null;
      case AMFSerializationType.FALSE:      return false;
      case AMFSerializationType.TRUE:       return true;
      case AMFSerializationType.INTEGER:    return _readUInt29();
      case AMFSerializationType.NUMBER:     return _readDouble();
      case AMFSerializationType.STRING:     return _readString();
      case AMFSerializationType.XML:        return _readXml();
      case AMFSerializationType.XML_STRING: return _readXml();
      case AMFSerializationType.DATE:       return _readDate();
      case AMFSerializationType.LIST:       return _readCollection();
      case AMFSerializationType.OBJECT:     return _readEntity();
      case AMFSerializationType.BYTE_ARRAY: return _readByteArray();
    }
    
    throw new ArgumentError('Unknown type: $type');
    
    return null;
  }
  
  int _readUInt29() {
    int value = 0;
    int n = 0;
    int byte = _input.getUint8(_pos++);
    
    while ((byte & 0x80) != 0 && n < 3) {
      value <<= 7;
      value |= (byte & 0x7F);
      byte = _input.getUint8(_pos++);
      ++n;
    }
    
    if (n < 3) {
      value <<= 7;
      value |= byte;
    } else {
      value <<= 8;
      value |= byte;
      
      if ((value & 0x10000000) != 0) value |= 0xe0000000;
    }
    
    return value;
  }
  
  double _readDouble() {
    final double res = _input.getFloat64(_pos);
    
    _pos += 8;
    
    return res;
  }
  
  String _readString() {
    final int ref = _readUInt29();
          
    if ((ref & 0x01) == 0) return _getStringReference(ref >> 1);
    else {
      final int length = (ref >> 1);
      
      if (0 == length) return '';
      
      final String str = _readUTF(length);
      
      _addStringReference(str);
      
      return str;
    }
  }
  
  String _readUTF(int length) {
    final List<int> SB = <int>[];
    int ch1, ch2, ch3, count = 0;
    
    while (count < length) {
      ch1 = _input.getInt8(_pos++) & 0xFF;
      
      switch (ch1 >> 4) {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          count++;
          
          SB.add(ch1);
          
          break;
        case 12:  case 13:
          count += 2;
          
          if (count > length) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          ch2 = _input.getInt8(_pos++);
          
          if ((ch2 & 0xC0) != 0x80) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          SB.add(((ch1 & 0x1F) << 6) | (ch2 & 0x3F));
          
          break;
        case 14:
          count += 3;
          
          if (count > length) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          ch2 = _input.getInt8(_pos++);
          ch3 = _input.getInt8(_pos++);
          
          if (((ch2 & 0xC0) != 0x80) || ((ch3 & 0xC0) != 0x80)) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          SB.add(((ch1 & 0x0F) << 12) | ((ch2 & 0x3F) << 6) | ((ch3 & 0x3F) << 0));
          
          break;
        default:  throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
      }
    }
    
    return new String.fromCharCodes(SB);
  }
  
  dynamic _readCollection() {
    final int ref = _readUInt29();
    String name;
    dynamic value;
    LinkedHashMap<dynamic, dynamic> map;
    bool hasMapEntry = false;
          
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      final int length = (ref >> 1);
      final List<dynamic> list = <dynamic>[];
      
      _addObjectReference(list);
      
      while (true) {
        name = _readString();
        
        if (name == null || name.isEmpty) break;
        
        value = readObject();
        
        if (map == null) map = new LinkedHashMap<dynamic, dynamic>();
        
        map[name] = value;
        
        hasMapEntry = true;
      }
      
      for (int i = 0; i < length; ++i) hasMapEntry ? map[i] = readObject() : list.add(readObject());
      
      return hasMapEntry ? map : list;
    }
  }
  
  DateTime _readDate() {
    final int ref = _readUInt29();
    
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      final DateTime date = new DateTime.fromMillisecondsSinceEpoch(_input.getFloat64(_pos).toInt());
      
      _pos += 8;
      
      _addObjectReference(date);
      
      return date;
    }
  }
  
  List<int> _readByteArray() {
    final int ref = _readUInt29();
    int baPos = 0;
    
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      final int length = (ref >> 1);
      
      final List<int> BA = new List<int>(length);
      
      while (baPos < length) {
        BA.add(_input.getInt8(_pos++));
        
        baPos++;
      }
      
      _addObjectReference(BA);
      
      return BA;
    }
    
    return null;
  }
  
  String _readXml() {
    final int ref = _readUInt29();
    String xml;
    
    if ((ref & 0x01) == 0) xml = _getObjectReference(ref >> 1);
    else {
      final int length = (ref >> 1);
      xml = _readUTF(length);
      
      _addObjectReference(xml);
    }
    
    return xml;
  }
  
  dynamic _readEntity() {
    final int ref = _readUInt29();
    String property;
          
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      final TraitsInfo traitsInfo = _readTraits(ref);
      dynamic entity = traitsInfo.isExternalizable ? _spawnHandler(traitsInfo.type) : <String, dynamic>{};
      
      _addObjectReference(entity);
      
      if (traitsInfo.isExternalizable) entity = _readExternalizable(entity);
      else {
        traitsInfo.properties.forEach((PropertyInfo I) => entity[I.name] = readObject());
              
        if (traitsInfo.isDynamic) {
          while (true) {
            property = _readString();
            
            if (property == null || property.isEmpty) break;
            
            entity[property] = readObject();
          }
        }
      }
      
      return (_transformer != null) ? _transformer(entity) : entity;
    }
    
    return null;
  }
  
  dynamic _readExternalizable(dynamic entity) => _parseHandler(entity, this);
  
  TraitsInfo _readTraits(int ref) {
    TraitsInfo traitsInfo;
    int propertyCount;
    int index;
          
    if ((ref & 0x03) == 1) return _getTraitsReference(ref >> 2);
    else {
      traitsInfo = new TraitsInfo(_readString(), isDynamic: ((ref & 0x08) == 8), isExternalizable: ((ref & 0x04) == 4));
      
      _addTraitsReference(traitsInfo);

      propertyCount = (ref >> 4); /* uint29 */
      
      for (index = 0; index < propertyCount; ++index) traitsInfo.addProperty(_readString());
      
      return traitsInfo;
    }
  }
  
  dynamic _getObjectReference(int index) => _objectTable[index];
  
  void _addObjectReference(dynamic value) => _objectTable.add(value);
  
  String _getStringReference(int index) => _stringTable[index];
  
  void _addStringReference(String value) => _stringTable.add(value);
  
  TraitsInfo _getTraitsReference(int index) => _traitsTable[index];
  
  void _addTraitsReference(TraitsInfo value) => _traitsTable.add(value);
}