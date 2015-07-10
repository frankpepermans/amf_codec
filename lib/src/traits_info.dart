part of amf_codec;

class TraitsInfo {
  
  final String type;
  final List<PropertyInfo> properties = <PropertyInfo>[];
  
  TraitsInfo(this.type);
                  
  void addProperty(String name, {TraitsInfo traits:null}) => properties.add(new PropertyInfo(name, traits));
  
}