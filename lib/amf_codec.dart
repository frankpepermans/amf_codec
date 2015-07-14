// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The amf_codec library.
///
/// This is an awesome library. More dartdocs go here.
library amf_codec;

import 'dart:collection';
import 'dart:typed_data';

import 'package:dorm/dorm.dart';

// TODO: Export any libraries intended for clients of this package.

part 'src/amf_serialization_type.dart';
part 'src/property_info.dart';
part 'src/traits_info.dart';
part 'src/amf3_input.dart';

typedef dynamic ReadExternalHandler(dynamic entity, AMF3Input input);
typedef dynamic EntitySpawnMethod(String type);
typedef dynamic Transformer(dynamic entity);