// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '_base.dart';

/// An attribute.
class Attribute extends TokenObject {
  final int modifiedObjectToken;
  final int tokenType;
  final Uint8List signatureBlob;

  Attribute(IMetaDataImport2 reader, int token, this.modifiedObjectToken,
      this.tokenType, this.signatureBlob)
      : super(reader, token);

  factory Attribute.fromToken(IMetaDataImport2 reader, int token) {
    final ptkObj = calloc<Uint32>();
    final ptkType = calloc<Uint32>();
    final ppBlob = calloc<Uint8>(1024);
    final pcbBlob = calloc<Uint32>();

    try {
      final hr = reader.GetCustomAttributeProps(
          token, ptkObj, ptkType, Pointer.fromAddress(ppBlob.address), pcbBlob);
      if (SUCCEEDED(hr)) {
        return Attribute(reader, token, ptkObj.value, ptkType.value,
            ppBlob.asTypedList(pcbBlob.value));
      } else {
        throw WindowsException(hr);
      }
    } finally {
      calloc.free(pcbBlob);
      calloc.free(ppBlob);
      calloc.free(ptkType);
      calloc.free(ptkObj);
    }
  }
}