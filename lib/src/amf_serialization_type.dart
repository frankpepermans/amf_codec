part of amf_codec;

class AMF3SerializationType {
  
  static const int UNDEFINED = 0;
  static const int NULL = 1;
  static const int FALSE = 2;
  static const int TRUE = 3;
  static const int INTEGER = 4;
  static const int NUMBER = 5;
  static const int STRING = 6;
  static const int XML = 7;
  static const int DATE = 8;
  static const int LIST = 9;
  static const int OBJECT = 10;
  static const int XML_STRING = 11;
  static const int BYTE_ARRAY = 12;
  static const int VECTOR_INT = 13;
  static const int VECTOR_UINT = 14;
  static const int VECTOR_DOUBLE = 15;
  static const int VECTOR_OBJECT = 16;
  static const int DICTIONARY = 17;
  
}

class AMF0SerializationType {
  static const int UNKNOWN = -1;
  static const int NUMBER = 0;
  static const int BOOLEAN = 1;
  static const int STRING = 2;
  static const int OBJECT = 3;
  static const int MOVIECLIP = 4;
  static const int NULL = 5;
  static const int UNDEFINED = 6;
  static const int REFERENCE = 7;
  static const int ECMA_ARRAY = 8;
  static const int OBJECT_END = 9;
  static const int STRICT_ARRAY = 10;
  static const int DATE = 11;
  static const int LONG_STRING = 12;
  static const int UNSUPPORTED = 13;
  static const int RECORDSET = 14;
  static const int XML_OBJECT = 15;
  static const int TYPED_OBJECT = 16;
  static const int AMF3_OBJECT = 17;
}