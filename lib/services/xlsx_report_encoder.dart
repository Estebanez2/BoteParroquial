import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../core/errors/app_failure.dart';
import '../models/report_export.dart';

/// Small, write-only SpreadsheetML encoder. Never emits formulas or links.
/// Integers above Excel's 15 significant digits are stored as exact text.
class XlsxReportEncoder {
  const XlsxReportEncoder();
  static const _main =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _relations =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _packageRelations =
      'http://schemas.openxmlformats.org/package/2006/relationships';

  List<int> encode(ReportExport data) {
    final report = data.report;
    final sheets = <String, List<List<Object?>>>{
      'Resumen': [
        ['Concepto', 'Valor'],
        ['Grupo', data.groupName],
        ['Moneda', data.currency],
        ['Desde (incluido)', _date(report.start)],
        ['Hasta (excluido)', _date(report.endExclusive)],
        ['Saldo inicial (céntimos)', report.openingCents],
        ['Ingresos activos (céntimos)', report.incomeCents],
        ['Retiradas activas (céntimos)', report.withdrawalCents],
        ['Saldo final (céntimos)', report.closingCents],
        ['Movimientos activos', report.activeMovementsCount],
        [
          'Criterio',
          'Estado actual del historial; caja por fecha efectiva. No acredita cuotas pagadas.',
        ],
        [
          'Precisión',
          'Importes enteros en céntimos; más de 15 cifras se conservan como texto.',
        ],
      ],
      'Personas': [
        [
          'ID',
          'Nombre',
          'Activa',
          'Ingresos (céntimos)',
          'Retiradas (céntimos)',
          'Neto (céntimos)',
        ],
        for (final person in report.persons)
          [
            person.personId,
            person.name,
            person.isActive ? 'Sí' : 'No',
            person.incomeCents,
            person.withdrawalCents,
            person.netCents,
          ],
      ],
      'Movimientos': data.movementRows,
      'Actividad mensual': [
        ['Mes', 'Ingresos (céntimos)', 'Retiradas (céntimos)'],
        for (final month in report.months)
          [
            _date(month.month).substring(0, 7),
            month.incomeCents,
            month.withdrawalCents,
          ],
      ],
    };
    final archive = Archive();
    void add(String name, XmlBuilder builder) {
      final bytes = utf8.encode(builder.buildDocument().toXmlString());
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    XmlBuilder document() =>
        XmlBuilder()..processing('xml', 'version="1.0" encoding="UTF-8"');
    final types = document();
    types.element(
      'Types',
      namespaceUris: {
        '': 'http://schemas.openxmlformats.org/package/2006/content-types',
      },
      nest: () {
        types.element(
          'Default',
          attributes: {
            'Extension': 'rels',
            'ContentType':
                'application/vnd.openxmlformats-package.relationships+xml',
          },
        );
        types.element(
          'Default',
          attributes: {'Extension': 'xml', 'ContentType': 'application/xml'},
        );
        types.element(
          'Override',
          attributes: {
            'PartName': '/xl/workbook.xml',
            'ContentType':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml',
          },
        );
        for (var i = 1; i <= sheets.length; i++) {
          types.element(
            'Override',
            attributes: {
              'PartName': '/xl/worksheets/sheet$i.xml',
              'ContentType':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml',
            },
          );
        }
      },
    );
    add('[Content_Types].xml', types);
    final root = document();
    root.element(
      'Relationships',
      namespaceUris: {'': _packageRelations},
      nest: () {
        root.element(
          'Relationship',
          attributes: {
            'Id': 'rId1',
            'Type': '$_relations/officeDocument',
            'Target': 'xl/workbook.xml',
          },
        );
      },
    );
    add('_rels/.rels', root);
    final book = document(), relations = document();
    book.element(
      'workbook',
      namespaceUris: {'': _main, 'r': _relations},
      nest: () {
        book.element(
          'sheets',
          nest: () {
            var id = 0;
            for (final name in sheets.keys) {
              id++;
              book.element(
                'sheet',
                attributes: {'name': name, 'sheetId': '$id', 'r:id': 'rId$id'},
              );
            }
          },
        );
      },
    );
    relations.element(
      'Relationships',
      namespaceUris: {'': _packageRelations},
      nest: () {
        for (var i = 1; i <= sheets.length; i++) {
          relations.element(
            'Relationship',
            attributes: {
              'Id': 'rId$i',
              'Type': '$_relations/worksheet',
              'Target': 'worksheets/sheet$i.xml',
            },
          );
        }
      },
    );
    add('xl/workbook.xml', book);
    add('xl/_rels/workbook.xml.rels', relations);
    var index = 0;
    for (final rows in sheets.values) {
      index++;
      if (rows.length > 1048576) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El periodo supera el máximo de filas de Excel. Elige un periodo menor.',
        );
      }
      final sheet = document();
      sheet.element(
        'worksheet',
        namespaceUris: {'': _main},
        nest: () {
          sheet.element(
            'sheetData',
            nest: () {
              for (var r = 0; r < rows.length; r++) {
                sheet.element(
                  'row',
                  attributes: {'r': '${r + 1}'},
                  nest: () {
                    for (var c = 0; c < rows[r].length; c++) {
                      final value = rows[r][c];
                      if (value == null) continue;
                      final numeric =
                          value is int &&
                          value.toString().replaceAll('-', '').length <= 15;
                      final text = value.toString();
                      if (text.length > 32767 ||
                          RegExp(
                            r'[\x00-\x08\x0B\x0C\x0E-\x1F]',
                          ).hasMatch(text)) {
                        throw const AppFailure(
                          FailureCode.invalidData,
                          'Hay un texto que no puede representarse en Excel; usa CSV para conservarlo.',
                        );
                      }
                      sheet.element(
                        'c',
                        attributes: {
                          'r': '${_column(c)}${r + 1}',
                          't': numeric ? 'n' : 'inlineStr',
                        },
                        nest: () {
                          if (numeric) {
                            sheet.element('v', nest: text);
                          } else {
                            sheet.element(
                              'is',
                              nest: () {
                                sheet.element(
                                  't',
                                  attributes: {'xml:space': 'preserve'},
                                  nest: text,
                                );
                              },
                            );
                          }
                        },
                      );
                    }
                  },
                );
              }
            },
          );
        },
      );
      add('xl/worksheets/sheet$index.xml', sheet);
    }
    return ZipEncoder().encode(archive);
  }

  String _column(int index) {
    var number = index + 1, result = '';
    while (number > 0) {
      number--;
      result = String.fromCharCode(65 + number % 26) + result;
      number ~/= 26;
    }
    return result;
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
