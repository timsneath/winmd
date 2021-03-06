import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'com/constants.dart';
import 'method.dart';
import 'mixins/customattributes_mixin.dart';
import 'scope.dart';
import 'type_aliases.dart';
import 'typedef.dart';

/// An event.
///
/// Events are way to associated a collection of methods defined on a given
/// class. There are two required methods (`add_` and `remove_`), plus an
/// optional one (`raise_`). Events are described in §II.22.13 of the ECMA-335
/// spec.
class Event extends TokenObject with CustomAttributesMixin {
  final int eventType;
  final String name;
  final List<int> otherMethodTokens;

  final int _addOnToken;
  final int _attributes;
  final int _fireToken;
  final int _parentToken;
  final int _removeOnToken;

  Event(
      Scope scope,
      int token,
      this._parentToken,
      this.name,
      this._attributes,
      this.eventType,
      this._addOnToken,
      this._removeOnToken,
      this._fireToken,
      this.otherMethodTokens)
      : super(scope, token);

  /// Creates an event object from a provided token.
  factory Event.fromToken(Scope scope, int token) {
    final ptkClass = calloc<mdTypeDef>();
    final szEvent = wsalloc(MAX_STRING_SIZE);
    final pchEvent = calloc<ULONG>();
    final pdwEventFlags = calloc<DWORD>();
    final ptkEventType = calloc<mdToken>();
    final ptkAddOn = calloc<mdMethodDef>();
    final ptkRemoveOn = calloc<mdMethodDef>();
    final tkkFire = calloc<mdMethodDef>();
    final rgOtherMethod = calloc<mdMethodDef>(16);
    final pcOtherMethod = calloc<ULONG>();

    try {
      final reader = scope.reader;
      final hr = reader.GetEventProps(
          token,
          ptkClass,
          szEvent,
          MAX_STRING_SIZE,
          pchEvent,
          pdwEventFlags,
          ptkEventType,
          ptkAddOn,
          ptkRemoveOn,
          tkkFire,
          rgOtherMethod,
          16,
          pcOtherMethod);

      if (SUCCEEDED(hr)) {
        return Event(
            scope,
            token,
            ptkClass.value,
            szEvent.toDartString(),
            pdwEventFlags.value,
            ptkEventType.value,
            ptkAddOn.value,
            ptkRemoveOn.value,
            tkkFire.value,
            rgOtherMethod.asTypedList(pcOtherMethod.value));
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(ptkClass);
      free(szEvent);
      free(pchEvent);
      free(pdwEventFlags);
      free(ptkEventType);
      free(ptkAddOn);
      free(ptkRemoveOn);
      free(tkkFire);
      free(rgOtherMethod);
      free(pcOtherMethod);
    }
  }

  @override
  String toString() => name;

  /// Returns the add method for the event.
  Method? get addMethod => reader.IsValidToken(_addOnToken) == TRUE
      ? Method.fromToken(scope, _addOnToken)
      : null;

  /// Returns the remove method for the event.
  Method? get removeMethod => reader.IsValidToken(_removeOnToken) == TRUE
      ? Method.fromToken(scope, _removeOnToken)
      : null;

  /// Returns the raise method for the event.
  Method? get raiseMethod => reader.IsValidToken(_fireToken) == TRUE
      ? Method.fromToken(scope, _fireToken)
      : null;

  /// Returns the [TypeDef] representing the class that declares the event.
  TypeDef get parent => TypeDef.fromToken(scope, _parentToken);

  /// Returns true if the event is special; its name describes how.
  bool get isSpecialName =>
      _attributes & CorEventAttr.evSpecialName == CorEventAttr.evSpecialName;

  /// Returns true if the common language runtime should check the encoding of
  /// the event name.
  bool get isRTSpecialName =>
      _attributes & CorEventAttr.evRTSpecialName ==
      CorEventAttr.evRTSpecialName;
}
