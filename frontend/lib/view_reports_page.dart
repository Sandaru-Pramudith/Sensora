// // ignore_for_file: deprecated_member_use
// import 'dart:math' as math;
// import 'dart:ui' as ui;
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../config/api_config.dart';

// // REQUIRED PACKAGES FOR PDF, PRINTING, AND SHARING
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';

// import '../sensor_charts_page.dart';

// class ViewReportDetails extends StatefulWidget {
//   final int basketId;
//   const ViewReportDetails({super.key, required this.basketId});

//   @override
//   State<ViewReportDetails> createState() => _ViewReportDetailsState();
// }

// class _ViewReportDetailsState extends State<ViewReportDetails>
//     with TickerProviderStateMixin {
//   // DATA STATE
//   double avgTemp = 0.0;
//   double avgHum = 0.0;
//   double maxTvoc = 0.0;
//   bool isLoading = true;

//   String fruitCondition = "Unknown";
//   double? hoursLeft;

//   List<List<String>> hourlyDataForTable = [];
//   final GlobalKey _cardKey = GlobalKey();

//   late AnimationController _particleController;
//   late AnimationController _cardControllers;
//   late Animation<double> _cardAnimations;
//   final List<Particle> _particles = List.generate(25, (index) => Particle());

//   @override
//   void initState() {
//     super.initState();
//     _particleController = AnimationController(
//       duration: const Duration(seconds: 20),
//       vsync: this,
//     )..repeat();
//     _cardControllers = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _cardAnimations = CurvedAnimation(
//       parent: _cardControllers,
//       curve: Curves.easeOutBack,
//     );

//     _loadAllData();
//   }

//   Future<void> _loadAllData() async {
//     try {
//       final response = await http.get(
//         Uri.parse("${ApiConfig.baseUrl}/reports/basket/${widget.basketId}"),
//       );

//       if (response.statusCode != 200) {
//         if (mounted) setState(() => isLoading = false);
//         return;
//       }

//       final data = jsonDecode(response.body);
//       final prediction = data["prediction"];
//       final readings = data["sensor_readings"] as List<dynamic>;

//       double tSum = 0;
//       double hSum = 0;
//       double mVal = 0;
//       int count = 0;
//       List<List<String>> tempTableRows = [];

//       for (final row in readings) {
//         final double t = (row["temp"] as num?)?.toDouble() ?? 0.0;
//         final double h = (row["hum"] as num?)?.toDouble() ?? 0.0;
//         final double tv = (row["tvoc"] as num?)?.toDouble() ?? 0.0;

//         tSum += t;
//         hSum += h;
//         if (tv > mVal) mVal = tv;
//         count++;

//         tempTableRows.add([
//           row["recorded_at"].toString(),
//           "${t.toStringAsFixed(1)}°C",
//           "${h.toStringAsFixed(1)}%",
//           "${tv.toStringAsFixed(0)} ppb",
//         ]);
//       }

//       if (mounted) {
//         setState(() {
//           avgTemp = count > 0 ? tSum / count : 0.0;
//           avgHum = count > 0 ? hSum / count : 0.0;
//           maxTvoc = mVal;
//           hourlyDataForTable = tempTableRows;
//           fruitCondition = prediction["condition"] ?? "Unknown";

//           final hl = prediction["hours_left"];
//           hoursLeft = hl == null ? null : (hl as num).toDouble();

//           isLoading = false;
//         });

//         _cardControllers.forward();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   Future<Uint8List?> _captureCardImage() async {
//     try {
//       RenderRepaintBoundary? boundary =
//           _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//       if (boundary == null) return null;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(
//         format: ui.ImageByteFormat.png,
//       );
//       return byteData?.buffer.asUint8List();
//     } catch (e) {
//       return null;
//     }
//   }

//   // CORE LOGIC: GENERATE THE PDF DOCUMENT OBJECT
//   Future<pw.Document> _buildPdfDocument(Uint8List? cardImg) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (pw.Context context) => [
//           pw.Header(level: 0, text: "SENSORA  ANALYSIS  REPORT"),
//           pw.Paragraph(text: "Batch ID: ${widget.basketId}"),
//           pw.Paragraph(
//             text:
//                 "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
//           ),
//           pw.Divider(),
//           if (cardImg != null) ...[
//             pw.SizedBox(height: 10),
//             pw.Center(child: pw.Image(pw.MemoryImage(cardImg), width: 380)),
//           ],
//           pw.SizedBox(height: 25),
//           pw.Text(
//             "Hour-by-Hour Environmental Summary:",
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
//           ),
//           pw.SizedBox(height: 10),
//           pw.Table.fromTextArray(
//             headerStyle: pw.TextStyle(
//               fontWeight: pw.FontWeight.bold,
//               color: PdfColors.white,
//             ),
//             headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
//             cellHeight: 25,
//             headers: ['Timestamp', 'Temp', 'Humidity', 'TVOC'],
//             data: hourlyDataForTable,
//           ),
//           pw.Footer(trailing: pw.Text("Sensora - Official Report")),
//         ],
//       ),
//     );
//     return pdf;
//   }

//   // ACTION: DOWNLOAD PDF
//   Future<void> _generatePdfReport() async {
//     final cardImg = await _captureCardImage();
//     final pdf = await _buildPdfDocument(cardImg);
//     await Printing.sharePdf(
//       bytes: await pdf.save(),
//       filename: 'Sensora_Report_${widget.basketId}.pdf',
//     );
//   }

//   // SHARE PDF FILE
//   Future<void> _sharePdfFile() async {
//     final cardImg = await _captureCardImage();
//     final pdf = await _buildPdfDocument(cardImg);
//     final bytes = await pdf.save();

//     // Sharing as a file using XFile
//     await Share.shareXFiles(
//       [
//         XFile.fromData(
//           bytes,
//           name: 'Sensora_Report_${widget.basketId}.pdf',
//           mimeType: 'application/pdf',
//         ),
//       ],
//       text:
//           'Check out the Sensora Analysis Report for Batch ${widget.basketId}',
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0a0a0a),
//       body: Stack(
//         children: [
//           _animatedBackground(),
//           _buildParticles(),
//           SafeArea(
//             child: isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
//                   )
//                 : Column(
//                     children: [
//                       _buildTopNav(),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           padding: const EdgeInsets.symmetric(horizontal: 24),
//                           child: Column(
//                             children: [
//                               const SizedBox(height: 20),
//                               RepaintBoundary(
//                                 key: _cardKey,
//                                 child: _buildAnalysisCard(),
//                               ),
//                               const SizedBox(height: 30),
//                               _buildActionButton(
//                                 "CHARTS",
//                                 Icons.analytics_outlined,
//                                 () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (c) => SensorChartsPage(
//                                         basketId: widget.basketId,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               _buildActionButton(
//                                 "DOWNLOAD PDF",
//                                 Icons.table_chart_outlined,
//                                 _generatePdfReport,
//                               ),
//                               const SizedBox(height: 16),
//                               // UPDATED SHARE BUTTON TO SHARE THE ACTUAL PDF FILE
//                               _buildActionButton(
//                                 "SHARE PDF",
//                                 Icons.share_outlined,
//                                 _sharePdfFile,
//                               ),
//                               const SizedBox(height: 120),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopNav() => Padding(
//     padding: const EdgeInsets.all(20),
//     child: Row(
//       children: [
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ],
//     ),
//   );

//   Widget _buildAnalysisCard() {
//     String status = fruitCondition;
//     Color sColor = fruitCondition == "Spoilage Detected"
//         ? Colors.redAccent
//         : const Color(0xFF00FFA3);
//     return Container(
//       padding: const EdgeInsets.all(28),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF134E2E).withOpacity(0.6),
//             const Color(0xFF06140C).withOpacity(0.8),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             "BATCH ANALYSIS",
//             style: TextStyle(
//               color: Color(0xFF00FFA3),
//               fontSize: 22,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 25),
//           _row("Batch ID:", widget.basketId.toString()),
//           const SizedBox(height: 20),
//           _statBar(
//             "Avg Temperature",
//             (avgTemp / 50),
//             const Color(0xFF00FFA3),
//             "${avgTemp.toStringAsFixed(1)}°C",
//           ),
//           const SizedBox(height: 15),
//           _statBar(
//             "Ripeness",
//             (avgHum / 50),
//             Colors.yellowAccent,
//             "${avgHum.toStringAsFixed(1)}%",
//           ),
//           const SizedBox(height: 15),
//           _statBar(
//             "Spoilage Risk",
//             (maxTvoc / 5000),
//             Colors.redAccent,
//             maxTvoc > 2000 ? "High" : "Low",
//           ),

//           if (hoursLeft != null) ...[
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Center(
//                 child: Text(
//                   "Estimated Hours Left: ${hoursLeft!.toStringAsFixed(1)} h",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],

//           const SizedBox(height: 25),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: sColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.info_outline, color: sColor, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     "Status: $status",
//                     style: TextStyle(
//                       color: sColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _row(String l, String v) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(l, style: const TextStyle(color: Colors.white60)),
//       Text(
//         v,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ],
//   );

//   Widget _statBar(String l, double p, Color c, String t) => Column(
//     children: [
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(l, style: const TextStyle(color: Colors.white70, fontSize: 14)),
//           Text(
//             t,
//             style: TextStyle(
//               color: c,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 8),
//       ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: LinearProgressIndicator(
//           value: p.clamp(0, 1),
//           backgroundColor: Colors.white10,
//           valueColor: AlwaysStoppedAnimation(c),
//           minHeight: 8,
//         ),
//       ),
//     ],
//   );

//   Widget _buildActionButton(String t, IconData i, VoidCallback o) => InkWell(
//     onTap: o,
//     child: Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       height: 80,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(25),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(i, color: const Color(0xFF00FFA3)),
//           const SizedBox(width: 15),
//           Text(
//             t,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );

//   Widget _animatedBackground() => Container(
//     decoration: const BoxDecoration(
//       gradient: LinearGradient(colors: [Color(0xFF05150d), Color(0xFF0a0a0a)]),
//     ),
//   );

//   Widget _buildParticles() => AnimatedBuilder(
//     animation: _particleController,
//     builder: (_, __) => CustomPaint(
//       painter: ParticlePainter(_particles, _particleController.value),
//       size: Size.infinite,
//     ),
//   );

//   @override
//   void dispose() {
//     _particleController.dispose();
//     _cardControllers.dispose();
//     super.dispose();
//   }
// }

// class Particle {
//   double x = math.Random().nextDouble();
//   double y = math.Random().nextDouble();
//   double size = math.Random().nextDouble() * 3 + 1;
//   double speedX = (math.Random().nextDouble() - 0.5) * 0.001;
//   double speedY = (math.Random().nextDouble() - 0.5) * 0.001;
// }

// class ParticlePainter extends CustomPainter {
//   final List<Particle> particles;
//   final double progress;
//   ParticlePainter(this.particles, this.progress);
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = const Color(0xFF00FFA3).withOpacity(0.2);
//     for (var p in particles) {
//       p.x = (p.x + p.speedX) % 1.0;
//       p.y = (p.y + p.speedY) % 1.0;
//       canvas.drawCircle(
//         Offset(p.x * size.width, p.y * size.height),
//         p.size,
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter old) => true;
// }

// Testing

// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core (Shared logic, themes, constants)/api_config.dart';

// REQUIRED PACKAGES FOR PDF, PRINTING, AND SHARING
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../sensor_charts_page.dart';

class ViewReportDetails extends StatefulWidget {
  final int basketId;
  const ViewReportDetails({super.key, required this.basketId});

  @override
  State<ViewReportDetails> createState() => _ViewReportDetailsState();
}

class _ViewReportDetailsState extends State<ViewReportDetails>
    with TickerProviderStateMixin {
  // DATA STATE
  double avgTemp = 0.0;
  double avgHumidity = 0.0;
  double avgAqi = 0.0;
  double maxTvoc = 0.0;
  double lastTvoc = 0.0;
  bool isLoading = true;

  String fruitCondition = "Unknown";
  double? hoursLeft;

  List<List<String>> hourlyDataForTable = [];
  final GlobalKey _cardKey = GlobalKey();

  late AnimationController _particleController;
  late AnimationController _cardControllers;
  final List<Particle> _particles = List.generate(25, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _cardControllers = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/reports/basket/${widget.basketId}"),
      );

      if (response.statusCode != 200) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(response.body);
      final prediction = data["prediction"];
      final readings = data["sensor_readings"] as List<dynamic>;

      final latestRow = readings.isNotEmpty ? readings.first : null;
      final double latestTv = (latestRow?["tvoc"] as num?)?.toDouble() ?? 0.0;

      double tSum = 0;
      double humSum = 0;
      double aqiSum = 0;
      double mVal = 0;
      int count = 0;
      List<List<String>> tempTableRows = [];

      for (final row in readings) {
        final double t = (row["temp"] as num?)?.toDouble() ?? 0.0;
        final double hum = (row["hum"] as num?)?.toDouble() ?? 0.0;
        final double aqi = (row["aqi"] as num?)?.toDouble() ?? 0.0;
        final double tv = (row["tvoc"] as num?)?.toDouble() ?? 0.0;

        tSum += t;
        humSum += hum;
        aqiSum += aqi;
        if (tv > mVal) mVal = tv;
        count++;

        tempTableRows.add([
          row["recorded_at"].toString(),
          "${t.toStringAsFixed(1)}°C",
          "${hum.toStringAsFixed(1)}%",
          "${tv.toStringAsFixed(0)} ppb",
        ]);
      }

      if (mounted) {
        setState(() {
          avgTemp = count > 0 ? tSum / count : 0.0;
          avgHumidity = count > 0 ? humSum / count : 0.0;
          avgAqi = count > 0 ? aqiSum / count : 0.0;
          maxTvoc = mVal;
          lastTvoc = latestTv;
          hourlyDataForTable = tempTableRows;
          fruitCondition = prediction["condition"] ?? "Unknown";

          final hl = prediction["hours_left"];
          hoursLeft = hl == null ? null : (hl as num).toDouble();

          isLoading = false;
        });

        _cardControllers.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<Uint8List?> _captureCardImage() async {
    try {
      RenderRepaintBoundary? boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  // CORE LOGIC: GENERATE THE PDF DOCUMENT OBJECT
  Future<pw.Document> _buildPdfDocument(Uint8List? cardImg) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(level: 0, text: "SENSORA  ANALYSIS  REPORT"),
          pw.Paragraph(text: "Batch ID: ${widget.basketId}"),
          pw.Paragraph(
            text:
                "Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
          ),
          pw.Divider(),
          if (cardImg != null) ...[
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Image(pw.MemoryImage(cardImg), width: 380)),
          ],
          pw.SizedBox(height: 25),
          pw.Text(
            "Hour-by-Hour Environmental Summary:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
            cellHeight: 25,
            headers: ['Timestamp', 'Temp', 'Humidity', 'TVOC'],
            data: hourlyDataForTable,
          ),
          pw.Footer(trailing: pw.Text("Sensora - Official Report")),
        ],
      ),
    );
    return pdf;
  }

  // ACTION: DOWNLOAD PDF
  Future<void> _generatePdfReport() async {
    final cardImg = await _captureCardImage();
    final pdf = await _buildPdfDocument(cardImg);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Sensora_Report_${widget.basketId}.pdf',
    );
  }

  // SHARE PDF FILE
  Future<void> _sharePdfFile() async {
    final cardImg = await _captureCardImage();
    final pdf = await _buildPdfDocument(cardImg);
    final bytes = await pdf.save();

    // Sharing as a file using XFile
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'Sensora_Report_${widget.basketId}.pdf',
          mimeType: 'application/pdf',
        ),
      ],
      text:
          'Check out the Sensora Analysis Report for Batch ${widget.basketId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          _animatedBackground(),
          _buildParticles(),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
                  )
                : Column(
                    children: [
                      _buildTopNav(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              RepaintBoundary(
                                key: _cardKey,
                                child: _buildAnalysisCard(),
                              ),
                              const SizedBox(height: 30),
                              _buildActionButton(
                                "CHARTS",
                                Icons.analytics_outlined,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => SensorChartsPage(
                                        basketId: widget.basketId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildActionButton(
                                "DOWNLOAD PDF",
                                Icons.table_chart_outlined,
                                _generatePdfReport,
                              ),
                              const SizedBox(height: 16),
                              // UPDATED SHARE BUTTON TO SHARE THE ACTUAL PDF FILE
                              _buildActionButton(
                                "SHARE PDF",
                                Icons.share_outlined,
                                _sharePdfFile,
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  Widget _buildAnalysisCard() {
    // Logic based on SQL 'prediction' table fields
    bool isSpoiled = fruitCondition == "Spoilage Detected";
    Color sColor = isSpoiled ? Colors.redAccent : const Color(0xFF00FFA3);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF134E2E).withOpacity(0.6),
            const Color(0xFF06140C).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            "BATCH ANALYSIS",
            style: TextStyle(
              color: Color(0xFF00FFA3),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 25),
          _row("Batch ID:", widget.basketId.toString()), // SQL basket_id
          const SizedBox(height: 20),

          // 1. AVG TEMPERATURE (Keep)
          _statBar(
            "Avg Temperature",
            (avgTemp / 50), // Scale: 0-50°C
            const Color(0xFF00FFA3),
            "${avgTemp.toStringAsFixed(1)}°C",
          ),
          const SizedBox(height: 15),

          _statBar(
            "Humidity",
            (avgHumidity / 100).clamp(0.0, 1.0),
            Colors.yellowAccent,
            "${avgHumidity.toStringAsFixed(1)}%",
          ),
          const SizedBox(height: 15),
          // 2. LAST SENSOR READING
          _statBar(
            "VOC (Volatile Organic Compounds)",
            (lastTvoc / 5000).clamp(0.0, 1.0),
            Colors.orangeAccent,
            "${lastTvoc.toStringAsFixed(0)} ppb",
          ),
          const SizedBox(height: 15),

          // 3. AIR QUALITY INDEX (New - from aqi)
          _statBar(
            "Air Quality Index",
            (avgAqi / 10).clamp(0.0, 1.0),
            Colors.lightBlueAccent,
            avgAqi.toStringAsFixed(0),
          ),
          const SizedBox(height: 25),

          // 4. BATCH LIFETIME (Directly from prediction.hours_left)
          if (hoursLeft != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  "LIFETIME REMAINING: ${hoursLeft!.toStringAsFixed(1)} HOURS",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // FINAL STATUS BADGE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSpoiled
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                    color: sColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Status: $fruitCondition",
                    style: TextStyle(
                      color: sColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(color: Colors.white60)),
      Text(
        v,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _statBar(String l, double p, Color c, String t) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            t,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: p.clamp(0, 1),
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation(c),
          minHeight: 8,
        ),
      ),
    ],
  );

  Widget _buildActionButton(String t, IconData i, VoidCallback o) => InkWell(
    onTap: o,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: const Color(0xFF00FFA3)),
          const SizedBox(width: 15),
          Text(
            t,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _animatedBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF05150d), Color(0xFF0a0a0a)]),
    ),
  );

  Widget _buildParticles() => AnimatedBuilder(
    animation: _particleController,
    builder: (_, __) => CustomPaint(
      painter: ParticlePainter(_particles, _particleController.value),
      size: Size.infinite,
    ),
  );

  @override
  void dispose() {
    _particleController.dispose();
    _cardControllers.dispose();
    super.dispose();
  }
}

class Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 3 + 1;
  double speedX = (math.Random().nextDouble() - 0.5) * 0.001;
  double speedY = (math.Random().nextDouble() - 0.5) * 0.001;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  ParticlePainter(this.particles, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00FFA3).withOpacity(0.2);
    for (var p in particles) {
      p.x = (p.x + p.speedX) % 1.0;
      p.y = (p.y + p.speedY) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
