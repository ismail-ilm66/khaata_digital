import 'dart:typed_data';

/// Reads legacy Excel 97–2003 `.xls` files (BIFF8 inside a Compound File),
/// which is what Hysab Kytab's "Export All" produces. Pure Dart, on device.
///
/// Only cell *values* are read, as text: shared and inline strings, numbers
/// (RK, MULRK, NUMBER), formula results and booleans. Formatting, merged
/// cells and charts are ignored.
abstract final class XlsReader {
  static const _magic = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];

  /// True when [bytes] start with the Compound File signature.
  static bool looksLikeXls(List<int> bytes) {
    if (bytes.length < 8) return false;
    for (var i = 0; i < 8; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  /// Every worksheet, in workbook order: (name, rows of text cells).
  /// Throws [FormatException] for anything that isn't a readable BIFF8 file.
  static List<({String name, List<List<String>> rows})> read(List<int> bytes) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (!looksLikeXls(data)) {
      throw const FormatException('Not an Excel 97–2003 (.xls) file');
    }
    final stream =
        _CompoundFile(data).stream('Workbook') ??
        _CompoundFile(data).stream('Book');
    if (stream == null) {
      throw const FormatException('No workbook inside this .xls file');
    }
    return _Biff8(stream).sheets();
  }
}

// ── Compound File Binary (the container) ───────────────────────────────

class _CompoundFile {
  _CompoundFile(this._d) : _v = ByteData.sublistView(_d) {
    _sectorSize = 1 << _u16(30);
    _miniSectorSize = 1 << _u16(32);
    _miniCutoff = _u32(56);
    _fat = _readFat();
    _dir = _chain(_u32(48));
  }

  final Uint8List _d;
  final ByteData _v;
  late final int _sectorSize;
  late final int _miniSectorSize;
  late final int _miniCutoff;
  late final List<int> _fat;
  late final Uint8List _dir;

  static const _endOfChain = 0xFFFFFFFE;
  static const _free = 0xFFFFFFFF;

  int _u16(int o) => _v.getUint16(o, Endian.little);
  int _u32(int o) => _v.getUint32(o, Endian.little);

  int _offset(int sector) => (sector + 1) * _sectorSize;

  List<int> _readFat() {
    final fatSectors = <int>[];
    final count = _u32(44);
    for (var i = 0; i < 109 && fatSectors.length < count; i++) {
      final s = _u32(76 + i * 4);
      if (s != _free) fatSectors.add(s);
    }
    // Further FAT sector ids live in the DIFAT chain.
    var difat = _u32(68);
    final perSector = _sectorSize ~/ 4 - 1;
    var guard = 0;
    while (difat != _endOfChain &&
        difat != _free &&
        fatSectors.length < count) {
      if (++guard > 1 << 20) throw const FormatException('Corrupt DIFAT');
      final o = _offset(difat);
      for (var i = 0; i < perSector && fatSectors.length < count; i++) {
        fatSectors.add(_u32(o + i * 4));
      }
      difat = _u32(o + perSector * 4);
    }
    final fat = <int>[];
    for (final s in fatSectors) {
      final o = _offset(s);
      if (o + _sectorSize > _d.length) {
        throw const FormatException('Truncated .xls file');
      }
      for (var i = 0; i < _sectorSize; i += 4) {
        fat.add(_u32(o + i));
      }
    }
    return fat;
  }

  /// The bytes of a regular-sector chain starting at [start].
  Uint8List _chain(int start, [int? size]) {
    final out = BytesBuilder(copy: false);
    var s = start;
    var guard = 0;
    while (s != _endOfChain && s != _free) {
      if (s >= _fat.length || ++guard > _fat.length) {
        throw const FormatException('Corrupt sector chain');
      }
      final o = _offset(s);
      final end = o + _sectorSize;
      if (end > _d.length) throw const FormatException('Truncated .xls file');
      out.add(Uint8List.sublistView(_d, o, end));
      s = _fat[s];
    }
    final bytes = out.takeBytes();
    return size == null || size >= bytes.length
        ? bytes
        : Uint8List.sublistView(bytes, 0, size);
  }

  /// A named stream from the root storage, or null.
  Uint8List? stream(String name) {
    final dir = ByteData.sublistView(_dir);
    Uint8List? root;
    for (var o = 0; o + 128 <= _dir.length; o += 128) {
      final type = _dir[o + 66];
      final nameLen = dir.getUint16(o + 64, Endian.little);
      final start = dir.getUint32(o + 116, Endian.little);
      final size = dir.getUint32(o + 120, Endian.little);
      if (type == 5) {
        root = _chain(start, size); // the mini stream container
        continue;
      }
      if (type != 2 || nameLen < 2) continue;
      final chars = <int>[
        for (var i = 0; i < nameLen - 2; i += 2)
          dir.getUint16(o + i, Endian.little),
      ];
      if (String.fromCharCodes(chars) != name) continue;
      if (size >= _miniCutoff) return _chain(start, size);
      return _miniChain(root, start, size);
    }
    return null;
  }

  Uint8List _miniChain(Uint8List? miniStream, int start, int size) {
    if (miniStream == null) throw const FormatException('No mini stream');
    final miniFatBytes = _chain(_u32(60));
    final miniFat = ByteData.sublistView(miniFatBytes);
    final out = BytesBuilder(copy: false);
    var s = start;
    var guard = 0;
    while (s != _endOfChain && s != _free && out.length < size) {
      if (++guard > miniFatBytes.length) {
        throw const FormatException('Corrupt mini chain');
      }
      final o = s * _miniSectorSize;
      out.add(Uint8List.sublistView(miniStream, o, o + _miniSectorSize));
      s = miniFat.getUint32(s * 4, Endian.little);
    }
    return Uint8List.sublistView(out.takeBytes(), 0, size);
  }
}

// ── BIFF8 records (the workbook) ───────────────────────────────────────

class _Biff8 {
  _Biff8(this._d) : _v = ByteData.sublistView(_d);

  final Uint8List _d;
  final ByteData _v;

  static const _bof = 0x0809;
  static const _eof = 0x000A;
  static const _boundSheet = 0x0085;
  static const _sst = 0x00FC;
  static const _continue = 0x003C;
  static const _labelSst = 0x00FD;
  static const _label = 0x0204;
  static const _number = 0x0203;
  static const _rk = 0x027E;
  static const _mulRk = 0x00BD;
  static const _formula = 0x0006;
  static const _string = 0x0207;
  static const _boolErr = 0x0205;

  int _u16(int o) => _v.getUint16(o, Endian.little);
  int _u32(int o) => _v.getUint32(o, Endian.little);

  List<({String name, List<List<String>> rows})> sheets() {
    final strings = <String>[];
    final bound = <({int pos, String name, int kind})>[];

    // Workbook globals: up to the first EOF.
    var o = 0;
    while (o + 4 <= _d.length) {
      final type = _u16(o);
      final len = _u16(o + 2);
      final body = o + 4;
      if (type == _boundSheet) {
        final cch = _d[body + 6];
        final high = _d[body + 7] & 1 == 1;
        bound.add((
          pos: _u32(body),
          kind: _d[body + 5],
          name: _chars(body + 8, cch, high),
        ));
      } else if (type == _sst) {
        // The SST and its CONTINUE records form one logical stream.
        final segments = <Uint8List>[
          Uint8List.sublistView(_d, body, body + len),
        ];
        var n = body + len;
        while (n + 4 <= _d.length && _u16(n) == _continue) {
          final l = _u16(n + 2);
          segments.add(Uint8List.sublistView(_d, n + 4, n + 4 + l));
          n += 4 + l;
        }
        strings.addAll(_SstReader(segments).read());
      } else if (type == _eof) {
        break;
      }
      o = body + len;
    }

    return [
      for (final b in bound)
        if (b.kind == 0) (name: b.name, rows: _sheet(b.pos, strings)),
    ];
  }

  List<List<String>> _sheet(int start, List<String> strings) {
    final cells = <int, Map<int, String>>{};
    void put(int row, int col, String value) =>
        (cells[row] ??= {})[col] = value;

    if (start + 4 > _d.length || _u16(start) != _bof) {
      throw const FormatException('Bad worksheet offset');
    }
    var o = start;
    ({int row, int col})? pendingString;
    while (o + 4 <= _d.length) {
      final type = _u16(o);
      final len = _u16(o + 2);
      final b = o + 4;
      if (b + len > _d.length) throw const FormatException('Truncated record');
      switch (type) {
        case _eof:
          return _grid(cells);
        case _labelSst:
          final i = _u32(b + 6);
          put(_u16(b), _u16(b + 2), i < strings.length ? strings[i] : '');
        case _label:
          final cch = _u16(b + 6);
          put(_u16(b), _u16(b + 2), _chars(b + 9, cch, _d[b + 8] & 1 == 1));
        case _number:
          put(_u16(b), _u16(b + 2), _num(_v.getFloat64(b + 6, Endian.little)));
        case _rk:
          put(_u16(b), _u16(b + 2), _num(_rkValue(_u32(b + 6))));
        case _mulRk:
          final row = _u16(b);
          final first = _u16(b + 2);
          final count = (len - 6) ~/ 6;
          for (var i = 0; i < count; i++) {
            put(row, first + i, _num(_rkValue(_u32(b + 4 + i * 6 + 2))));
          }
        case _formula:
          final row = _u16(b);
          final col = _u16(b + 2);
          if (_u16(b + 12) == 0xFFFF) {
            switch (_d[b + 6]) {
              case 0: // string result follows in a STRING record
                pendingString = (row: row, col: col);
              case 1:
                put(row, col, _d[b + 8] == 1 ? 'TRUE' : 'FALSE');
              default: // error or empty
                put(row, col, '');
            }
          } else {
            put(row, col, _num(_v.getFloat64(b + 6, Endian.little)));
          }
        case _string:
          if (pendingString != null) {
            final cch = _u16(b);
            put(
              pendingString.row,
              pendingString.col,
              _chars(b + 3, cch, _d[b + 2] & 1 == 1),
            );
            pendingString = null;
          }
        case _boolErr:
          final isError = _d[b + 7] == 1;
          put(
            _u16(b),
            _u16(b + 2),
            isError ? '' : (_d[b + 6] == 1 ? 'TRUE' : 'FALSE'),
          );
      }
      o = b + len;
    }
    return _grid(cells);
  }

  String _chars(int o, int count, bool high) {
    if (!high) return String.fromCharCodes(_d, o, o + count);
    return String.fromCharCodes([
      for (var i = 0; i < count; i++) _u16(o + i * 2),
    ]);
  }

  static double _rkValue(int rk) {
    final double v;
    if (rk & 2 != 0) {
      v = (rk >> 2).toSigned(30).toDouble();
    } else {
      final bits = ByteData(8)..setUint32(4, rk & 0xFFFFFFFC, Endian.big);
      v = bits.getFloat64(0, Endian.big);
    }
    return rk & 1 != 0 ? v / 100 : v;
  }

  /// Numbers as text: whole numbers without ".0", others as Dart prints.
  static String _num(double v) => v == v.truncateToDouble() && v.abs() < 1e15
      ? v.toInt().toString()
      : v.toString();

  static List<List<String>> _grid(Map<int, Map<int, String>> cells) {
    if (cells.isEmpty) return [];
    final lastRow = cells.keys.reduce((a, b) => a > b ? a : b);
    final width =
        cells.values
            .map((r) => r.keys.reduce((a, b) => a > b ? a : b))
            .reduce((a, b) => a > b ? a : b) +
        1;
    return [
      for (var r = 0; r <= lastRow; r++)
        [for (var c = 0; c < width; c++) (cells[r]?[c] ?? '').trim()],
    ];
  }
}

/// Reads the shared string table across its CONTINUE boundaries. A string
/// split by a boundary restarts with a fresh flags byte (BIFF8 rule).
class _SstReader {
  _SstReader(this._segments);

  final List<Uint8List> _segments;
  int _seg = 0;
  int _pos = 0;

  Uint8List get _cur => _segments[_seg];

  void _ensure() {
    while (_seg < _segments.length && _pos >= _cur.length) {
      _seg++;
      _pos = 0;
    }
    if (_seg >= _segments.length) {
      throw const FormatException('Shared strings end early');
    }
  }

  int _byte() {
    _ensure();
    return _cur[_pos++];
  }

  int _u16() => _byte() | (_byte() << 8);
  int _u32() => _u16() | (_u16() << 16);

  void _skip(int n) {
    for (var left = n; left > 0;) {
      _ensure();
      final take = (_cur.length - _pos).clamp(0, left);
      _pos += take;
      left -= take;
    }
  }

  List<String> read() {
    _u32(); // total references
    final unique = _u32();
    final out = <String>[];
    for (var i = 0; i < unique; i++) {
      out.add(_string());
    }
    return out;
  }

  String _string() {
    final cch = _u16();
    final flags = _byte();
    var high = flags & 0x01 != 0;
    final runs = flags & 0x08 != 0 ? _u16() : 0;
    final ext = flags & 0x04 != 0 ? _u32() : 0;
    final chars = <int>[];
    while (chars.length < cch) {
      if (_pos >= _cur.length) {
        // Crossed into a CONTINUE: it starts with a new flags byte.
        _seg++;
        _pos = 0;
        if (_seg >= _segments.length) {
          throw const FormatException('Shared strings end early');
        }
        high = _cur[_pos++] & 0x01 != 0;
      }
      final room = high ? (_cur.length - _pos) ~/ 2 : _cur.length - _pos;
      final take = (cch - chars.length).clamp(0, room);
      for (var k = 0; k < take; k++) {
        chars.add(
          high
              ? _cur[_pos + 2 * k] | (_cur[_pos + 2 * k + 1] << 8)
              : _cur[_pos + k],
        );
      }
      _pos += high ? take * 2 : take;
    }
    _skip(runs * 4 + ext);
    return String.fromCharCodes(chars);
  }
}
