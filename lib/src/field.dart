// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'com/IMetaDataImport2.dart';
import 'constants.dart';
import 'mixins/customattributes_mixin.dart';
import 'pinvokemap.dart';
import 'type_aliases.dart';
import 'typedef.dart';
import 'typeidentifier.dart';
import 'utils.dart';

enum FieldAccess {
  privateScope,
  private,
  familyAndAssembly,
  assembly,
  family,
  familyOrAssembly,
  public
}

class Field extends TokenObject with CustomAttributesMixin {
  final int _parentToken;
  final String name;
  final int value;
  final TypeIdentifier typeIdentifier;
  final CorElementType fieldType;
  final int _attributes;
  final Uint8List signatureBlob;

  /// Returns the [TypeDef] representing the class that the field belongs to.
  TypeDef get parent => TypeDef.fromToken(reader, _parentToken);

  /// Returns the visibility of the field (public, private, etc.)
  FieldAccess get fieldAccess =>
      FieldAccess.values[_attributes & CorFieldAttr.fdFieldAccessMask];

  /// Returns true if the field is a member of its type rather than an instance member.
  bool get isStatic =>
      _attributes & CorFieldAttr.fdStatic == CorFieldAttr.fdStatic;

  /// Returns true if the field cannot be changed after it is initialized.
  bool get isInitOnly =>
      _attributes & CorFieldAttr.fdInitOnly == CorFieldAttr.fdInitOnly;

  /// Returns true if the field value is a compile-time constant.
  bool get isLiteral =>
      _attributes & CorFieldAttr.fdLiteral == CorFieldAttr.fdLiteral;

  /// Returns true if the field is not serialized when its type is remoted.
  bool get isNotSerialized =>
      _attributes & CorFieldAttr.fdNotSerialized ==
      CorFieldAttr.fdNotSerialized;

  /// Returns true if the field is special; its name describes how.
  bool get isSpecialName =>
      _attributes & CorFieldAttr.fdSpecialName == CorFieldAttr.fdSpecialName;

  /// Returns true if the field implementation is forwarded through PInvoke.
  bool get isPinvokeImpl =>
      _attributes & CorFieldAttr.fdPinvokeImpl == CorFieldAttr.fdPinvokeImpl;

  /// Returns true if the common language runtime metadata internal APIs should
  /// check the encoding of the name.
  bool get isRTSpecialName =>
      _attributes & CorFieldAttr.fdRTSpecialName ==
      CorFieldAttr.fdRTSpecialName;

  /// Returns true if the field contains marshaling information.
  bool get hasFieldMarshal =>
      _attributes & CorFieldAttr.fdHasFieldMarshal ==
      CorFieldAttr.fdHasFieldMarshal;

  /// Returns true if the field has a default value.
  bool get hasDefault =>
      _attributes & CorFieldAttr.fdHasDefault == CorFieldAttr.fdHasDefault;

  /// Returns true if the field has a relative virtual address.
  bool get hasFieldRVA =>
      _attributes & CorFieldAttr.fdHasFieldRVA == CorFieldAttr.fdHasFieldRVA;

  PinvokeMap get pinvokeMap => PinvokeMap.fromToken(reader, token);

  Field(
      IMetaDataImport2 reader,
      int token,
      this._parentToken,
      this.name,
      this.value,
      this.typeIdentifier,
      this.fieldType,
      this._attributes,
      this.signatureBlob)
      : super(reader, token);

  /// Creates a field object from its given token.
  factory Field.fromToken(IMetaDataImport2 reader, int token) {
    final ptkTypeDef = calloc<mdTypeDef>();
    final szField = stralloc(MAX_STRING_SIZE);
    final pchField = calloc<ULONG>();
    final pdwAttr = calloc<DWORD>();
    final ppvSigBlob = calloc<PCCOR_SIGNATURE>();
    final pcbSigBlob = calloc<ULONG>();
    final pdwCPlusTypeFlag = calloc<DWORD>();
    final ppValue = calloc<Pointer<Uint32>>();
    final pcchValue = calloc<ULONG>();

    try {
      final hr = reader.GetFieldProps(
          token,
          ptkTypeDef,
          szField,
          MAX_STRING_SIZE,
          pchField,
          pdwAttr,
          ppvSigBlob.cast(),
          pcbSigBlob,
          pdwCPlusTypeFlag,
          ppValue.cast(),
          pcchValue);

      if (SUCCEEDED(hr)) {
        final fieldName = szField.toDartString();
        final cPlusTypeFlag = pdwCPlusTypeFlag.value;

        // The first entry of the signature is its FieldAttribute (compare
        // against the CorFieldAttr enumeration), and then follows a type
        // identifier.
        final signature = ppvSigBlob.value.asTypedList(pcbSigBlob.value);
        final typeTuple = parseTypeFromSignature(signature.sublist(1), reader);

        return Field(
            reader,
            token,
            ptkTypeDef.value,
            fieldName,
            ppValue.value != nullptr ? ppValue.value.value : 0,
            typeTuple.typeIdentifier,
            CorElementType.values[cPlusTypeFlag],
            pdwAttr.value,
            signature);
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(ptkTypeDef);
      free(szField);
      free(pchField);
      free(pdwAttr);
      free(ppvSigBlob);
      free(pcbSigBlob);
      free(pdwCPlusTypeFlag);
      free(ppValue);
      free(pcchValue);
    }
  }

  @override
  String toString() => 'Field: $name';
}

extension ListField on List<Field> {
  int operator [](String type) => firstWhere((f) => f.name == type).value;
}
