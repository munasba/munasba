import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/category.dart';
import '../models/event.dart';
import '../models/invitee.dart';
import '../models/person.dart';
import '../repositories/invitees_repository.dart';

/// NOTE: Arabic text in `pdf` needs an Arabic-capable font loaded explicitly
/// (the package's default font has no Arabic glyphs). This service tries to
/// load Google Fonts' Cairo/Noto Naskh Arabic at runtime via `printing`'s
/// font loading helpers; if that fails offline, the PDF still generates but
/// Arabic glyphs may render as boxes — bundle a .ttf under assets/fonts and
/// load it with `pw.Font.ttf(await rootBundle.load(...))` for a fully
/// offline-safe result.
class PdfService {
  static Future<pw.Font?> _tryLoadArabicFont() async {
    try {
      return await PdfGoogleFonts.notoNaskhArabicRegular();
    } catch (_) {
      return null;
    }
  }

  /// Generates and opens the print/share dialog for a single event's
  /// attendee report — the Dart equivalent of the PWA version's
  /// `printEventReport` helper.
  static Future<void> printEventReport({
    required EventItem event,
    required List<Invitee> invitees,
    required Map<String, Person> peopleById,
  }) async {
    final font = await _tryLoadArabicFont();
    final stats = AttendeeStats.fromInvitees(invitees);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: font != null ? pw.ThemeData.withFont(base: font, bold: font) : null,
        build: (context) => [
          pw.Text(event.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(event.date != null ? '${event.date!.year}-${event.date!.month}-${event.date!.day}' : ''),
          pw.SizedBox(height: 16),
          pw.Wrap(spacing: 10, runSpacing: 8, children: [
            _summaryChip('المدعوون', '${stats.invited}'),
            _summaryChip('الحضور المتوقع', '${stats.expected}'),
            _summaryChip('مؤكدون', '${stats.confirmed}'),
            _summaryChip('معتذرون', '${stats.declined}'),
            _summaryChip('قيد الانتظار', '${stats.pending}'),
          ]),
          pw.SizedBox(height: 20),
          // NOTE: `pw.TableHelper.fromTextArray` is the current API name; older
          // `pdf` package versions call this `pw.Table.fromTextArray` instead.
          pw.TableHelper.fromTextArray(
            headers: ['الاسم', 'الهاتف', 'عدد الحضور المتوقع', 'الحالة'],
            data: invitees.map((inv) {
              final p = peopleById[inv.personId];
              return [
                p?.fullName ?? '',
                p?.phone ?? '',
                '${inv.companions}',
                inv.rsvpStatus.label,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  /// Generates and opens the print/share dialog for an app-wide summary
  /// report (people / categories / events / attendance).
  static Future<void> printAppReport({
    required List<Person> people,
    required List<Category> categories,
    required List<EventItem> events,
    required List<Invitee> allInvitees,
  }) async {
    final font = await _tryLoadArabicFont();
    final stats = AttendeeStats.fromInvitees(allInvitees);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: font != null ? pw.ThemeData.withFont(base: font, bold: font) : null,
        build: (context) => [
          pw.Text('تقرير دعواتي الشامل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Wrap(spacing: 10, runSpacing: 8, children: [
            _summaryChip('الأشخاص', '${people.length}'),
            _summaryChip('الفئات', '${categories.length}'),
            _summaryChip('المناسبات', '${events.length}'),
            _summaryChip('إجمالي المدعوين', '${stats.invited}'),
            _summaryChip('الحضور المتوقع', '${stats.expected}'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('المناسبات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['اسم المناسبة', 'التاريخ', 'الموقع'],
            data: events
                .map((e) => [e.name, e.date != null ? '${e.date!.year}-${e.date!.month}-${e.date!.day}' : '', e.location ?? ''])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static pw.Widget _summaryChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(8), color: PdfColors.purple50),
      child: pw.Text('$label: $value'),
    );
  }
}
