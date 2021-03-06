//===----------------- OSLogIntegerTypes.swift ----------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// This file defines extensions for interpolating integer expressions into a
// OSLogMesage. It defines `appendInterpolation` functions for standard integer
// types. It also defines extensions for serializing integer types into the
// argument buffer passed to os_log ABIs.
//
// The `appendInterpolation` functions defined in this file accept formatting
// and privacy options along with the interpolated expression as shown below:
//
//         "\(x, format: .hex, privacy: .private\)"

extension OSLogInterpolation {

  /// Define interpolation for expressions of type Int.
  /// - Parameters:
  ///  - number: the interpolated expression of type Int, which is autoclosured.
  ///  - format: a formatting option available for integer types, defined by the
  ///    enum `OSLogIntegerFormatting`.
  ///  - privacy: a privacy qualifier which is either private or public.
  ///    The default is public.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  public mutating func appendInterpolation(
    _ number: @autoclosure @escaping () -> Int,
    format: OSLogIntegerFormatting = .decimal,
    align: OSLogStringAlignment = .none,
    privacy: OSLogPrivacy = .public
  ) {
    appendInteger(number, format: format, align: align, privacy: privacy)
  }

  /// Define interpolation for expressions of type Int32.
  /// - Parameters:
  ///  - number: the interpolated expression of type Int32, which is autoclosured.
  ///  - format: a formatting option available for integer types, defined by the
  ///    enum `OSLogIntegerFormatting`.
  ///  - privacy: a privacy qualifier which is either private or public.
  ///    The default is public.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  public mutating func appendInterpolation(
    _ number: @autoclosure @escaping () -> Int32,
    format: OSLogIntegerFormatting = .decimal,
    align: OSLogStringAlignment = .none,
    privacy: OSLogPrivacy = .public
  ) {
    appendInteger(number, format: format, align: align, privacy: privacy)
  }

  /// Define interpolation for expressions of type UInt.
  /// - Parameters:
  ///  - number: the interpolated expression of type UInt, which is autoclosured.
  ///  - format: a formatting option available for integer types, defined by the
  ///    enum `OSLogIntegerFormatting`.
  ///  - privacy: a privacy qualifier which is either private or public.
  ///    The default is public.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  public mutating func appendInterpolation(
    _ number: @autoclosure @escaping () -> UInt,
    format: OSLogIntegerFormatting = .decimal,
    align: OSLogStringAlignment = .none,
    privacy: OSLogPrivacy = .public
  ) {
    appendInteger(number, format: format, align: align, privacy: privacy)
  }

  /// Given an integer, create and append a format specifier for the integer to the
  /// format string property. Also, append the integer along with necessary headers
  /// to the OSLogArguments property.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  internal mutating func appendInteger<T>(
    _ number: @escaping () -> T,
    format: OSLogIntegerFormatting,
    align: OSLogStringAlignment,
    privacy: OSLogPrivacy
  ) where T: FixedWidthInteger {
    guard argumentCount < maxOSLogArgumentCount else { return }
    formatString +=
      format.formatSpecifier(for: T.self, align: align, privacy: privacy)

    let isPrivateArgument = isPrivate(privacy)
    addIntHeaders(isPrivateArgument, sizeForEncoding(T.self))

    arguments.append(number)
    argumentCount += 1
  }

  /// Update preamble and append argument headers based on the parameters of
  /// the interpolation.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  internal mutating func addIntHeaders(_ isPrivate: Bool, _ byteCount: Int) {
    // Append argument header.
    let argumentHeader = getArgumentHeader(isPrivate: isPrivate, type: .scalar)
    arguments.append(argumentHeader)

    // Append number of bytes needed to serialize the argument.
    arguments.append(UInt8(byteCount))

    // Increment total byte size by the number of bytes needed for this
    // argument, which is the sum of the byte size of the argument and
    // two bytes needed for the headers.
    totalBytesForSerializingArguments += byteCount + 2

    preamble = getUpdatedPreamble(isPrivate: isPrivate, isScalar: true)
  }
}

extension OSLogArguments {
  /// Append an (autoclosured) interpolated expression of integer type, passed to
  /// `OSLogMessage.appendInterpolation`, to the array of closures tracked
  /// by this instance.
  @_semantics("constant_evaluable")
  @inlinable
  @_optimize(none)
  internal mutating func append<T>(
    _ value: @escaping () -> T
  ) where T: FixedWidthInteger {
    argumentClosures.append({ (position, _) in
      serialize(value(), at: &position)
    })
  }
}

/// Return the number of bytes needed for serializing an integer argument as
/// specified by os_log. This function must be constant evaluable. Note that
/// it is marked transparent instead of @inline(__always) as it is used in
/// optimize(none) functions.
@_transparent
@usableFromInline
internal func sizeForEncoding<T>(
  _ type: T.Type
) -> Int where T : FixedWidthInteger  {
  return type.bitWidth &>> logBitsPerByte
}

/// Serialize an integer at the buffer location that `position` points to and
/// increment `position` by the byte size of `T`.
@inlinable
@_alwaysEmitIntoClient
@inline(__always)
internal func serialize<T>(
  _ value: T,
  at bufferPosition: inout ByteBufferPointer
) where T : FixedWidthInteger {
  let byteCount = sizeForEncoding(T.self)
  let dest =
    UnsafeMutableRawBufferPointer(start: bufferPosition, count: byteCount)
  withUnsafeBytes(of: value) { dest.copyMemory(from: $0) }
  bufferPosition += byteCount
}
