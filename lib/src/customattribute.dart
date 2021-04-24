// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'scope.dart';
import 'type_aliases.dart';
import 'utils/string.dart';

/// A custom (named) attribute.
class CustomAttribute extends TokenObject {
  final int attributeType;
  final int modifiedObjectToken;
  final Uint8List signatureBlob;

  CustomAttribute(Scope scope, int token, this.modifiedObjectToken,
      this.attributeType, this.signatureBlob)
      : super(scope, token);

  /// Creates a custom attribute object from its given token.
  factory CustomAttribute.fromToken(Scope scope, int token) {
    final ptkObj = calloc<mdToken>();
    final ptkType = calloc<mdToken>();
    final ppBlob = calloc<UVCP_CONSTANT>();
    final pcbBlob = calloc<ULONG>();

    try {
      final reader = scope.reader;
      final hr = reader.GetCustomAttributeProps(
          token, ptkObj, ptkType, ppBlob, pcbBlob);
      if (SUCCEEDED(hr)) {
        return CustomAttribute(scope, token, ptkObj.value, ptkType.value,
            ppBlob.value.asTypedList(pcbBlob.value));
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(ptkObj);
      free(ptkType);
      free(ppBlob);
      free(pcbBlob);
    }
  }

  String get name {
    final ptk = calloc<mdToken>();
    final szMember = stralloc(MAX_STRING_SIZE);
    final pchMember = calloc<ULONG>();
    final ppvSigBlob = calloc<PCCOR_SIGNATURE>();
    final pcbSigBlob = calloc<ULONG>();

    try {
      print('Token: ${token.toHexString(32)}');
      print('Token type: ${tokenType.toString()}');

      final hr = reader.GetMemberRefProps(token, ptk, szMember, MAX_STRING_SIZE,
          pchMember, ppvSigBlob, pcbSigBlob);

      if (SUCCEEDED(hr)) {
        print('success');
        print(pchMember.value);
        return szMember.toDartString();
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(szMember);
      free(pchMember);
      free(ppvSigBlob);
      free(pcbSigBlob);
    }
  }
}
