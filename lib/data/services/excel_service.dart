import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../models/event.dart';
import '../models/invitee.dart';
import '../models/person.dart';
import '../repositories/invitees_repository.dart';
import '../repositories/people_repository.dart';

/// NOTE on the `excel` package API: the cell-value wrapper classes
/// (TextCellValue / IntCellValue / etc.) were introduced in `excel` v4.
/// If your resolved version differs and these constructors don't match,
/// check `excel`'s changelog for the version pub gets — the read/write
/// calls below may need small adjustments (this couldn't be verified
/// against a live SDK when this file was written).
class ExcelService {
  /// Exports all people (with their category name) to an .xlsx file and
  /// opens the OS share sheet so the user can save it wherever they like.
  static Future<void> exportPeople(List<Person> people, Map<String, Category> categoriesById) async {
    final excelDoc = Excel.createExcel();
    final sheet = excelDoc['الأشخاص'];
    excelDoc.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('الاسم الكامل'),
      TextCellValue('الاسم المختصر'),
      TextCellValue('الهاتف'),
      TextCellValue('واتساب'),
      TextCellValue('الفئة'),
      TextCellValue('عدد أفراد العائلة'),
      TextCellValue('العنوان'),
      TextCellValue('ملاحظات'),
    ]);

    for (final p in people) {
      sheet.appendRow([
        TextCellValue(p.fullName),
        TextCellValue(p.shortName ?? ''),
        TextCellValue(p.phone ?? ''),
        TextCellValue(p.whatsapp ?? ''),
        TextCellValue(p.categoryId != null ? (categoriesById[p.categoryId]?.name ?? '') : ''),
        IntCellValue(p.familyMembersCount),
        TextCellValue(p.address ?? ''),
        TextCellValue(p.notes ?? ''),
      ]);
    }

    await _saveAndShare(excelDoc, 'دعواتي-الأشخاص');
  }

  /// Exports one event's invitee list (with companions + RSVP status) to
  /// an .xlsx file — the Dart equivalent of the PWA's exportEventInviteesExcel.
  static Future<void> exportEventInvitees(EventItem event, List<Invitee> invitees, Map<String, Person> peopleById) async {
    final excelDoc = Excel.createExcel();
    final sheet = excelDoc['المدعوون'];
    excelDoc.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('الهاتف'),
      TextCellValue('عدد الحضور المتوقع'),
      TextCellValue('حالة الدعوة'),
    ]);

    for (final inv in invitees) {
      final p = peopleById[inv.personId];
      sheet.appendRow([
        TextCellValue(p?.fullName ?? ''),
        TextCellValue(p?.phone ?? ''),
        IntCellValue(inv.companions),
        TextCellValue(inv.rsvpStatus.label),
      ]);
    }

    await _saveAndShare(excelDoc, 'دعواتي-${event.name}');
  }

  /// Exports all events with their attendance stats to an .xlsx file.
  static Future<void> exportEventsWithStats(List<EventItem> events, Map<String, AttendeeStats> statsByEventId) async {
    final excelDoc = Excel.createExcel();
    final sheet = excelDoc['المناسبات'];
    excelDoc.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('اسم المناسبة'),
      TextCellValue('النوع'),
      TextCellValue('التاريخ'),
      TextCellValue('الموقع'),
      TextCellValue('عدد المدعوين'),
      TextCellValue('الحضور المتوقع'),
      TextCellValue('نسبة الإنجاز %'),
    ]);

    for (final e in events) {
      final stats = statsByEventId[e.id];
      sheet.appendRow([
        TextCellValue(e.name),
        TextCellValue(kEventTypes[e.type] ?? e.type),
        TextCellValue(e.date != null ? '${e.date!.year}-${e.date!.month}-${e.date!.day}' : ''),
        TextCellValue(e.location ?? ''),
        IntCellValue(stats?.invited ?? 0),
        IntCellValue(stats?.expected ?? 0),
        IntCellValue(stats?.percent ?? 0),
      ]);
    }

    await _saveAndShare(excelDoc, 'دعواتي-المناسبات');
  }

  /// Reads an .xlsx file (path picked via file_selector/image_picker-style
  /// flow provided by the caller) and inserts each row as a new [Person].
  /// Expects the same column order produced by [exportPeople].
  static Future<int> importPeopleFromFile(String filePath, PeopleRepository repo) async {
    final bytes = await File(filePath).readAsBytes();
    final excelDoc = Excel.decodeBytes(bytes);
    var imported = 0;

    for (final table in excelDoc.tables.keys) {
      final rows = excelDoc.tables[table]!.rows;
      for (var i = 1; i < rows.length; i++) {
        // skip header row
        final row = rows[i];
        final fullName = _cellText(row, 0);
        if (fullName.isEmpty) continue;

        await repo.create(Person(
          id: '',
          fullName: fullName,
          shortName: _cellText(row, 1).isEmpty ? null : _cellText(row, 1),
          phone: _cellText(row, 2).isEmpty ? null : _cellText(row, 2),
          whatsapp: _cellText(row, 3).isEmpty ? null : _cellText(row, 3),
          familyMembersCount: int.tryParse(_cellText(row, 5)) ?? 1,
          address: _cellText(row, 6).isEmpty ? null : _cellText(row, 6),
          notes: _cellText(row, 7).isEmpty ? null : _cellText(row, 7),
          createdAt: DateTime.now(),
        ));
        imported++;
      }
    }
    return imported;
  }

  static String _cellText(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  static Future<void> _saveAndShare(Excel excelDoc, String fileNamePrefix) async {
    final bytes = excelDoc.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileNamePrefix-${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes);
    // NOTE: share_plus's API has changed across major versions (Share.shareXFiles
    // vs. the newer SharePlus.instance.share(ShareParams(...)) singleton). If the
    // resolved package version rejects this call, check share_plus's changelog
    // for whichever form is current for the version pub get installs.
    await Share.shareXFiles([XFile(path)], text: fileNamePrefix);
  }
}
