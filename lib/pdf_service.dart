import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

/// Servicio para generar y compartir/descargar PDFs.
/// `Printing.layoutPdf` abre el diálogo del sistema donde el usuario
/// puede imprimir, compartir o guardar el archivo.
class PdfService {
  static Future<void> generateUsersReport(List<AppUser> users) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header('Informe de Usuarios'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Fecha de generación: ${_formattedDate()}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Nombre', 'Correo', 'Rol', 'Estado'],
            data: users
                .map((u) => [
                      u.name,
                      u.email,
                      u.role,
                      u.active ? 'Activo' : 'Inactivo',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 11),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'informe_usuarios_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateSummaryReport(
    List<AppUser> users,
    int pdfCount,
  ) async {
    final active = users.where((u) => u.active).length;
    final inactive = users.length - active;
    final pct = users.isEmpty
        ? '0.0'
        : (active * 100 / users.length).toStringAsFixed(1);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('Informe Resumido'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Estadísticas generales del sistema',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            _kpi('Total de usuarios registrados', users.length.toString()),
            _kpi('Usuarios activos', active.toString()),
            _kpi('Usuarios inactivos', inactive.toString()),
            _kpi('PDFs cargados', pdfCount.toString()),
            _kpi('% de usuarios activos', '$pct %'),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'Documento generado automáticamente desde la consola de '
                'administración FET. Uso académico - Especialización en '
                'Ciberseguridad.',
                style: const pw.TextStyle(color: PdfColors.blue900, fontSize: 11),
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'Generado: ${_formattedDate()}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'informe_resumido_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Abre un PDF previamente cargado por el usuario.
  static Future<void> openPdf(String name, List<int> bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) => Uint8List.fromList(bytes),
      name: name,
    );
  }

  // -------- helpers --------
  static pw.Widget _header(String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FET - Consola de Administración',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Divider(color: PdfColors.blue900, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Fundación Escuela Tecnológica de Neiva — Especialización en Ciberseguridad',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _kpi(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 13)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ],
      ),
    );
  }

  static String _formattedDate() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
