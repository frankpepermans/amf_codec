part of amf_codec;

enum WriteCommand {
  SET_INT8,
  SET_FLOAT64
}

class AMF3Output {
  
  static const int INT28_MIN_VALUE = -268435456;
  static const int INT28_MAX_VALUE =  268435455;
  static const int UINT29_MASK =      536870911;
  
  final dynamic _target;
  final WriteExternalHandler _writeHandler;
  final List<WriteCommand> _writeCommands = <WriteCommand>[];
  final List<num> _writeValues = <num>[];
  final HashMap<dynamic, int> _objectTable = new HashMap.identity();
  final HashMap<String, int> _traitsTable = new HashMap.identity();
  final HashMap<String, int> _stringTable = new HashMap.identity();
  int _pos = 0;
  
  AMF3Output(this._target, this._writeHandler);
    
  ByteData writeObject() {
    writeObjectValue(_target);
    
    return toByteData();
  }
  
  void write(WriteCommand command, num value) {
    _writeCommands.add(command);
    _writeValues.add(value);
    
    switch (command) {
      case WriteCommand.SET_INT8: _pos++; return;
      case WriteCommand.SET_FLOAT64: _pos += 8; return;
    }
  }
  
  ByteData toByteData() {
    final ByteData output = new ByteData(_pos);
    int p = 0;
    
    for (int i=0, len=_writeCommands.length; i<len; i++) {
      switch (_writeCommands[i]) {
        case WriteCommand.SET_INT8: output.setInt8(p++, _writeValues[i]); break;
        case WriteCommand.SET_FLOAT64: output.setFloat64(p, _writeValues[i]); p += 8; break;
      }
    }
    
    return output;
  }
  
  void writeObjectValue(dynamic part) {
    if (part == null)           write(WriteCommand.SET_INT8, AMF3SerializationType.NULL);
    else if (part is bool)      write(WriteCommand.SET_INT8, part ? AMF3SerializationType.TRUE : AMF3SerializationType.FALSE);
    else if (part is int)       _writeInt(part);
    else if (part is double)    _writeDouble(part);
    else if (part is String)    _writeString(part);
    else if (part is DateTime)  _writeDate(part);
    else if (part is Iterable)  _writeCollection(part);
    else if (part is Map)       _writeMap(part);
    else if (part is ByteData)  _writeByteArray(part);
    else _writeEntity(part);
  }
  
  void _writeUInt29(int ref) {
     if (ref < 0x80) write(WriteCommand.SET_INT8, ref);
     else if (ref < 0x4000) {
       write(WriteCommand.SET_INT8, (((ref >> 7) & 0x7F) | 0x80));
       write(WriteCommand.SET_INT8, ref & 0x7F);
     } else if (ref < 0x200000) {
       write(WriteCommand.SET_INT8, (((ref >> 14) & 0x7F) | 0x80));
       write(WriteCommand.SET_INT8, (((ref >> 7) & 0x7F) | 0x80));
       write(WriteCommand.SET_INT8, ref & 0x7F);
     } else if (ref < 0x40000000) {
       write(WriteCommand.SET_INT8, ((ref >> 22) & 0x7F) | 0x80);
       write(WriteCommand.SET_INT8, ((ref >> 15) & 0x7F) | 0x80);
       write(WriteCommand.SET_INT8, ((ref >> 8) & 0x7F) | 0x80);
       write(WriteCommand.SET_INT8, ref & 0xFF);
     } else throw new ArgumentError('Integer out of range: $ref');
  }
  
  void _writeInt(int value) {
    if (value.isNaN) value = 0;
    
    if (value >= INT28_MIN_VALUE && value <= INT28_MAX_VALUE) {
      write(WriteCommand.SET_INT8, AMF3SerializationType.INTEGER);
      
      _writeUInt29(value & UINT29_MASK);
    } else _writeDouble(value.toDouble());
  }
  
  void _writeDouble(double value) {
    if (value.isNaN) value = .0;
    
    write(WriteCommand.SET_INT8, AMF3SerializationType.NUMBER);
    write(WriteCommand.SET_FLOAT64, value);
  }
  
  void _writeString(String s) {
    write(WriteCommand.SET_INT8, AMF3SerializationType.STRING);

    _writeStringWithoutType(s);
  }
  
  void _writeStringWithoutType(String s) {
    if (s.isEmpty) {
        _writeUInt29(1);
        
        return;
    }

    if (!_byStringReference(s)) {
        _writeAMFUTF(s);
        
        return;
    }
  }

  void _writeAMFUTF(String s) {
    final List<int> units = s.codeUnits;
    int strlen = s.length, utflen = 0, c;

    for (int i = 0; i < strlen; i++) {
      c = units[i];
      
      if (c <= 0x007F) utflen++;
      else if (c > 0x07FF) utflen += 3;
      else utflen += 2;
    }
    
    _writeUInt29((utflen << 1) | 1);

    for (int i = 0; i < strlen; i++) {
      c = units[i];
      
      if (c <= 0x007F) write(WriteCommand.SET_INT8, c);
      else if (c > 0x07FF) {
        write(WriteCommand.SET_INT8, (0xE0 | ((c >> 12) & 0x0F)));
        write(WriteCommand.SET_INT8, (0x80 | ((c >> 6) & 0x3F)));
        write(WriteCommand.SET_INT8, (0x80 | ((c >> 0) & 0x3F)));
      }
      else {
        write(WriteCommand.SET_INT8, (0xC0 | ((c >> 6) & 0x1F)));
        write(WriteCommand.SET_INT8, (0x80 | ((c >> 0) & 0x3F)));
      }
    }
  }
  
  void _writeDate(DateTime value) {
    write(WriteCommand.SET_INT8, AMF3SerializationType.DATE);

    if (!_byObjectReference(value)) {
        _writeUInt29(1);

        write(WriteCommand.SET_FLOAT64, value.millisecondsSinceEpoch.toDouble());
    }
  }
  
  void _writeCollection(Iterable col) {
    write(WriteCommand.SET_INT8, AMF3SerializationType.LIST);
    write(WriteCommand.SET_INT8, ((col.length << 1) | 1));
    
    _writeStringWithoutType('');
    
    for (dynamic value in col) writeObjectValue(value);
  }
  
  void _writeMap(Map<String, dynamic> map) {
    write(WriteCommand.SET_INT8, AMF3SerializationType.LIST);

    if (!_byObjectReference(map)) {
      write(WriteCommand.SET_INT8, ((0 << 1) | 1));
      
      map.forEach((String K, dynamic V) {
        _writeStringWithoutType(K);
        
        writeObjectValue(V);
      });
      
      _writeStringWithoutType('');
    }
  }
  
  void _writeTraitsInfo(dynamic e) {
    if (!_byTraitsReference(e.refClassName)) {
      bool isExternalizable, isDynamic;
      int count;
      
      if (e is AbstractMessage) {
        isExternalizable = false;
        isDynamic = false;
        count = 9;
      } else {
        isExternalizable = true;
        isDynamic = false;
        count = 0;
      }
      
      _writeUInt29(3 | (isExternalizable ? 4 : 0) | (isDynamic ? 8 : 0) | (count << 4));
      _writeStringWithoutType(e.refClassName);
      
      messageOutputPropertyWriter(e, this);
    }
  }
  
  void _writeEntity(dynamic e) {
    write(WriteCommand.SET_INT8, AMF3SerializationType.OBJECT);
    
    if (!_byObjectReference(e)) {
      _writeTraitsInfo(e);
      _writeHandler(e, this);
    }
  }
  
  void _writeByteArray(ByteData value) {}
  
  bool _byObjectReference(dynamic o) {
    if (_objectTable != null && _objectTable.containsKey(o)) {
      try {
          final int refNum = _objectTable[o];

          _writeUInt29(refNum << 1);

          return true;
      } catch (error) {
          throw new ArgumentError("Object reference is not an Integer");
      }
    }
    
    _objectTable[o] = _objectTable.values.length;
    
    return false;
  }
  
  bool _byStringReference(dynamic o) {
    if (_stringTable != null && _stringTable.containsKey(o)) {
      try {
          final int refNum = _stringTable[o];

          _writeUInt29(refNum << 1);

          return true;
      } catch (error) {
          throw new ArgumentError("String reference is not an Integer");
      }
    }
    
    _stringTable[o] = _stringTable.values.length;
    
    return false;
  }
  
  bool _byTraitsReference(String refClassName) {
    if (_traitsTable != null && _traitsTable.containsKey(refClassName)) {
      try {
          final int refNum = _traitsTable[refClassName];

          _writeUInt29(refNum << 1);

          return true;
      } catch (error) {
          throw new ArgumentError("Object reference is not a Trait");
      }
    }
    
    _traitsTable[refClassName] = _traitsTable.values.length;
    
    return false;
  }

}