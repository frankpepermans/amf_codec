part of amf_codec;

class AMF3Input {
  
  static const String UTF_DATA_FORMAT_EXCEPTION = "UTF Data Format Exception";
  static const String OBJECT_NOT_IEXT_EXCEPTION = "Object is not IExternalizable";
  
  final ByteData _input;
  final List<Object> _objectTable = <Object>[];
  final List<String> _stringTable = <String>[];
  final List<TraitsInfo> _traitsTable = <TraitsInfo>[];
  int _pos = 35;
  
  AMF3Input(this._input);
  
  dynamic readObject() => _readObjectValue(_input.getInt8(_pos++));
  
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
    final double res = _input.getFloat32(_pos);
    
    _pos += 4;
    
    return res;
  }
  
  String _readString() {
    int ref = _readUInt29();
    String str;
    int length;
          
    if ((ref & 0x01) == 0) return _getStringReference(ref >> 1);
    else {
      length = (ref >> 1);
      
      if (0 == length) return '';
      
      str = _readUTF(length);
      
      _addStringReference(str);
      
      return str;
    }
  }
  
  String _readUTF(int length) {
    StringBuffer SB = new StringBuffer();
    int ch1, ch2, ch3, count = 0, ch = 0;
    
    while (count < length) {
      ch1 = _input.getInt8(_pos++) & 0xFF;
      
      switch (ch1 >> 4) {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          count++;
          
          SB.writeCharCode(ch1);
          
          break;
        case 12:  case 13:
          count += 2;
          
          if (count > length) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          ch2 = _input.getInt8(_pos++);
          
          if ((ch2 & 0xC0) != 0x80) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          SB.writeCharCode(((ch1 & 0x1F) << 6) | (ch2 & 0x3F));
          
          break;
        case 14:
          count += 3;
          
          if (count > length) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          ch2 = _input.getInt8(_pos++);
          ch3 = _input.getInt8(_pos++);
          
          if (((ch2 & 0xC0) != 0x80) || ((ch3 & 0xC0) != 0x80)) throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
          
          SB.writeCharCode(((ch1 & 0x0F) << 12) | ((ch2 & 0x3F) << 6) | ((ch3 & 0x3F) << 0));
          
          break;
        default:  throw new ArgumentError(UTF_DATA_FORMAT_EXCEPTION);
      }
      
      ch++;
    }
    
    return SB.toString();
  }
  
  dynamic _readCollection() {
    final int ref = _readUInt29();
    String name;
    dynamic value;
    List<dynamic> list;
    LinkedHashMap<dynamic, dynamic> map;
    int length;
    bool hasMapEntry = false;
          
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      length = (ref >> 1);
      list = <dynamic>[];
      _addObjectReference(list);
      
      while (true) {
        name = _readString();
        
        if (name == null || name.length == 0) break;
        
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
    int ref = _readUInt29();
    DateTime date;
    
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      date = new DateTime.fromMillisecondsSinceEpoch(_input.getFloat32(_pos).toInt());
      
      _pos += 4;
      
      _addObjectReference(date);
      
      return date;
    }
  }
  
  List<int> _readByteArray() {
    final int ref = _readUInt29();
    int length, baPos = 0;
    
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      length = (ref >> 1);
      
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
    int length;
    String xml;
    
    if ((ref & 0x01) == 0) xml = _getObjectReference(ref >> 1);
    else {
      length = (ref >> 1);
      
      xml = _readUTF(length);
      
      _addObjectReference(xml);
    }
    
    return xml;
  }
  
  Map<String, dynamic> _readEntity() {
    final int ref = _readUInt29();
    Map<String, dynamic> entity;
    TraitsInfo traitsInfo;
    String property;
    String type;
          
    if ((ref & 0x01) == 0) return _getObjectReference(ref >> 1);
    else {
      traitsInfo = _readTraits(ref);
      
      type = traitsInfo.type;
      
      entity = <String, dynamic>{};
      
      _addObjectReference(entity);
      
      traitsInfo.properties.forEach((PropertyInfo I) => entity[I.name] = readObject());
      
      while (true) {
        property = _readString();
        
        if (property == null || property == '') break;
        
        entity[property] = readObject();
      }
      
      return entity;
    }
    
    return null;
  }
  
  TraitsInfo _readTraits(int ref) {
    TraitsInfo traitsInfo;
    int propertyCount;
    String type;
    int index;
    String property;
          
    if ((ref & 0x03) == 1) return _getTraitsReference(ref >> 2);
    else {
      type = _readString();
      
      traitsInfo = new TraitsInfo(type);
      
      _addTraitsReference(traitsInfo);

      propertyCount = (ref >> 4); /* uint29 */
      
      for (index = 0; index < propertyCount; ++index) {
              property = _readString();
              
              traitsInfo.addProperty(property);
      }
      
      return traitsInfo;
    }
  }
  
  dynamic _getObjectReference(int index) => _objectTable[index];
  
  void _addObjectReference(dynamic value) => _objectTable.add(value);
  
  dynamic _getStringReference(int index) => _stringTable[index];
  
  void _addStringReference(String value) => _stringTable.add(value);
  
  TraitsInfo _getTraitsReference(int index) => _traitsTable[index];
  
  void _addTraitsReference(TraitsInfo value) => _traitsTable.add(value);
}