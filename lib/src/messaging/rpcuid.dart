part of amf_codec;

class RPCUID {
  
  static const List<int> ALPHA_CHAR_CODES = const <int>[48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];
  static const int DASH = 45;
  
  static bool isUID(String uid) {
    if (uid != null && uid.length == 36) {
        for (int i = 0; i < 36; i++) {
            int c = uid.codeUnitAt(i);

            if (i == 8 || i == 13 || i == 18 || i == 23) {
                if (c != DASH) return false;
            }
            
            else if (c < 48 || c > 70 || (c > 57 && c < 65)) return false;
        }

        return true;
    }

    return false;
  }
  
  static String create() {
    final List<int> bytes = <int>[];
    final Random R = new Random();

    int i, j;

    for (i = 0; i < 8; i++) bytes.add(ALPHA_CHAR_CODES[R.nextInt(16)]);

    for (i = 0; i < 3; i++) {
      bytes.add(DASH);
      
      for (j = 0; j < 4; j++) bytes.add(ALPHA_CHAR_CODES[R.nextInt(16)]);
    }

    bytes.add(DASH);

    int time = new DateTime.now().millisecondsSinceEpoch;
    String timeString = time.toStringAsPrecision(16).toUpperCase();
    
    for (i = 8; i > timeString.length; i--) bytes.add(48);
    
    bytes.addAll(timeString.codeUnits);

    for (i = 0; i < 4; i++) bytes.add(ALPHA_CHAR_CODES[R.nextInt(16)]);

    return new String.fromCharCodes(bytes);
  }
  
  static ByteData toByteArray(String uid) {
    if (isUID(uid)) {
        List<int> result = <int>[];

        for (int i = 0; i < uid.length; i++) {
          String c = uid[i];
          
          if (c == "-") continue;
          
          int h1 = getDigit(c);
          
          i++;
          
          int h2 = getDigit(uid[i]);
          
          result.add(((h1 << 4) | h2) & 0xFF);
        }
        
        return new ByteData.view(new Int8List.fromList(result).buffer);
    }

    return null;
  }
  
  static int getDigit(String hex) {
    switch (hex)  {
      case "A": 
      case "a":           
          return 10;
      case "B":
      case "b":
          return 11;
      case "C":
      case "c":
          return 12;
      case "D":
      case "d":
          return 13;
      case "E":
      case "e":
          return 14;                
      case "F":
      case "f":
          return 15;
      default:
          return int.parse(hex);
    }
  }
}