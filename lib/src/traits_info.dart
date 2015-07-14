part of amf_codec;

class TraitsInfo {
  
  final String type;
  final bool isDynamic;
  final bool isExternalizable;
  final List<PropertyInfo> properties = <PropertyInfo>[];
  
  TraitsInfo(this.type, {this.isDynamic:false, this.isExternalizable:false});
                  
  void addProperty(String name, {TraitsInfo traits:null}) => properties.add(new PropertyInfo(name, traits));
  
}