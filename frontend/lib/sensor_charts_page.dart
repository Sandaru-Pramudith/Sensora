// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import './config/api_config.dart';

// class SensorChartsPage extends StatefulWidget {
//   final int basketId;
//   const SensorChartsPage({super.key, required this.basketId});

//   @override
//   State<SensorChartsPage> createState() => _SensorChartsPageState();
// }

// class _SensorChartsPageState extends State<SensorChartsPage>
//     with TickerProviderStateMixin {
//   //  DATA STATE
//   List<FlSpot> tempSpots = [];
//   List<FlSpot> humSpots = [];
//   List<FlSpot> gasSpots = [];
//   List<FlSpot> co2Spots = [];
//   List<PieChartSectionData> pieSections = [];
//   bool isLoading = true;
//   bool isHourlySummary = false;

//   //  BASKET COMPARISON STATE
//   int? compareBasketId;
//   List<FlSpot> compareTempSpots = [];
//   List<FlSpot> compareHumSpots = [];
//   List<FlSpot> compareGasSpots = [];
//   List<FlSpot> compareCo2Spots = [];
//   List<int> availableBaskets = [];

//   //  FILTER STATE
//   DateTimeRange? selectedDateRange;

//   late AnimationController _particleController;
//   final List<ChartParticle> _particles = List.generate(
//     20,
//     (index) => ChartParticle(),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _particleController = AnimationController(
//       duration: const Duration(seconds: 20),
//       vsync: this,
//     )..repeat();
//     _loadAllAnalyticsData();
//   }

//   Future<void> _loadAllAnalyticsData() async {
//     try {
//       // load main basket readings
//       final mainReadings = await _fetchReadings(widget.basketId);

//       tempSpots = _buildSpots(mainReadings, "temp");
//       humSpots = _buildSpots(mainReadings, "hum");
//       gasSpots = _buildSpots(mainReadings, "tvoc");
//       co2Spots = _buildSpots(mainReadings, "mq_volts");

//       // load comparison basket readings if selected
//       if (compareBasketId != null) {
//         final compareReadings = await _fetchReadings(compareBasketId!);
//         compareTempSpots = _buildSpots(compareReadings, "temp");
//         compareHumSpots = _buildSpots(compareReadings, "hum");
//         compareGasSpots = _buildSpots(compareReadings, "tvoc");
//         compareCo2Spots = _buildSpots(compareReadings, "mq_volts");
//       } else {
//         compareTempSpots = [];
//         compareHumSpots = [];
//         compareGasSpots = [];
//         compareCo2Spots = [];
//       }

//       // load all baskets for dropdown
//       availableBaskets = await _fetchBasketIds();

//       // build pie chart from basket predictions
//       pieSections = await _loadPieSectionsFromApi();

//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("Load Error: $e");
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   // Updated Helper: Uses columnIdx to load specific sensor data
//   Future<List<dynamic>> _fetchReadings(int basketId) async {
//     final response = await http.get(
//       Uri.parse("${ApiConfig.baseUrl}/reports/basket/$basketId/readings"),
//     );

//     if (response.statusCode != 200) return [];

//     final data = jsonDecode(response.body);
//     List<dynamic> readings = data["readings"] as List<dynamic>;

//     if (selectedDateRange != null) {
//       readings = readings.where((row) {
//         final dt = DateTime.tryParse(row["recorded_at"].toString());
//         if (dt == null) return false;

//         return !dt.isBefore(selectedDateRange!.start) &&
//             !dt.isAfter(selectedDateRange!.end.add(const Duration(days: 1)));
//       }).toList();
//     }

//     return readings;
//   }

//   List<FlSpot> _buildSpots(List<dynamic> readings, String fieldName) {
//     List<FlSpot> spots = [];

//     int step = isHourlySummary ? 6 : 1;
//     int xIdx = 0;

//     for (int i = 0; i < readings.length; i += step) {
//       final row = readings[i];
//       final double val = (row[fieldName] as num?)?.toDouble() ?? 0.0;
//       spots.add(FlSpot(xIdx.toDouble(), val));
//       xIdx++;
//     }

//     return spots;
//   }

//   Future<List<int>> _fetchBasketIds() async {
//     final response = await http.get(
//       Uri.parse("${ApiConfig.baseUrl}/reports/baskets"),
//     );

//     if (response.statusCode != 200) return [];

//     final data = jsonDecode(response.body) as List<dynamic>;
//     return data.map((e) => e["basket_id"]).whereType<int>().toList();
//   }

//   Future<List<PieChartSectionData>> _loadPieSectionsFromApi() async {
//     final basketIds = await _fetchBasketIds();

//     int fresh = 0;
//     int spoiled = 0;
//     int unknown = 0;

//     for (final id in basketIds) {
//       final response = await http.get(
//         Uri.parse("${ApiConfig.baseUrl}/reports/basket/$id/predictions"),
//       );

//       if (response.statusCode != 200) {
//         unknown++;
//         continue;
//       }

//       final data = jsonDecode(response.body);
//       final predictions = data["predictions"] as List<dynamic>;

//       if (predictions.isEmpty) {
//         unknown++;
//       } else {
//         final latest = predictions.first;
//         final bool spoiledStage = latest["spoil_stage"] == true;
//         if (spoiledStage) {
//           spoiled++;
//         } else {
//           fresh++;
//         }
//       }
//     }

//     if (fresh == 0 && spoiled == 0 && unknown == 0) {
//       unknown = 1;
//     }

//     return [
//       PieChartSectionData(
//         value: fresh.toDouble(),
//         color: const Color(0xFF00FFA3),
//         radius: 50,
//         showTitle: false,
//       ),
//       PieChartSectionData(
//         value: spoiled.toDouble(),
//         color: Colors.redAccent,
//         radius: 50,
//         showTitle: false,
//       ),
//       PieChartSectionData(
//         value: unknown.toDouble(),
//         color: Colors.grey,
//         radius: 50,
//         showTitle: false,
//       ),
//     ];
//   }

//   @override
//   void dispose() {
//     _particleController.dispose();
//     super.dispose();
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
//                 : SingleChildScrollView(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Column(
//                       children: [
//                         _buildHeader(),
//                         const SizedBox(height: 15),
//                         _buildControlRow(),
//                         const SizedBox(height: 20),
//                         _buildPieChartCard(),

//                         // CHARTS SECTION
//                         const SizedBox(height: 20),
//                         _buildChartCard(
//                           "TEMPERATURE TREND (°C)",
//                           tempSpots,
//                           compareTempSpots,
//                           const Color(0xFF00FFA3),
//                         ),

//                         const SizedBox(height: 20),
//                         _buildChartCard(
//                           "HUMIDITY LEVEL (%)",
//                           humSpots,
//                           compareHumSpots,
//                           Colors.blueAccent,
//                         ),

//                         const SizedBox(height: 20),
//                         _buildChartCard(
//                           "GAS EMISSION (TVOC)",
//                           gasSpots,
//                           compareGasSpots,
//                           Colors.orangeAccent,
//                         ),

//                         const SizedBox(height: 20),
//                         _buildChartCard(
//                           "CO2 CONCENTRATION (MQ VOLTS)",
//                           co2Spots,
//                           compareCo2Spots,
//                           Colors.purpleAccent,
//                         ),

//                         const SizedBox(height: 100),
//                       ],
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlRow() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: DropdownButton<int>(
//             dropdownColor: const Color(0xFF0a0a0a),
//             underline: const SizedBox(),
//             hint: const Text(
//               "Compare Basket",
//               style: TextStyle(color: Colors.white38, fontSize: 11),
//             ),
//             value: compareBasketId,
//             items: availableBaskets.where((b) => b != widget.basketId).map((
//               int b,
//             ) {
//               return DropdownMenuItem<int>(
//                 value: b,
//                 child: Text(
//                   "Basket $b",
//                   style: const TextStyle(
//                     color: Color(0xFF00FFA3),
//                     fontSize: 11,
//                   ),
//                 ),
//               );
//             }).toList(),
//             onChanged: (val) {
//               setState(() {
//                 compareBasketId = val;
//                 isLoading = true;
//               });
//               _loadAllAnalyticsData();
//             },
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               isHourlySummary = !isHourlySummary;
//               isLoading = true;
//             });
//             _loadAllAnalyticsData();
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: isHourlySummary
//                   ? const Color(0xFF00FFA3).withOpacity(0.1)
//                   : Colors.white.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: isHourlySummary
//                     ? const Color(0xFF00FFA3)
//                     : Colors.transparent,
//               ),
//             ),
//             child: Text(
//               isHourlySummary ? "Hourly View" : "Raw Data",
//               style: TextStyle(
//                 color: isHourlySummary
//                     ? const Color(0xFF00FFA3)
//                     : Colors.white38,
//                 fontSize: 11,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.only(top: 20),
//       child: Row(
//         children: [
//           _glassCircleButton(
//             Icons.arrow_back_ios_new,
//             () => Navigator.pop(context),
//           ),
//           const SizedBox(width: 15),
//           const Text(
//             'Analytics',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const Spacer(),
//           _glassCircleButton(Icons.calendar_month, () async {
//             final range = await showDateRangePicker(
//               context: context,
//               firstDate: DateTime(2025, 1, 1),
//               lastDate: DateTime.now(),
//             );
//             if (range != null) {
//               setState(() {
//                 selectedDateRange = range;
//                 isLoading = true;
//               });
//               _loadAllAnalyticsData();
//             }
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildPieChartCard() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             "WAREHOUSE DISTRIBUTION",
//             style: TextStyle(
//               color: Colors.white70,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             height: 140,
//             child: PieChart(
//               PieChartData(sections: pieSections, centerSpaceRadius: 35),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _legend(const Color(0xFF00FFA3), "Fresh"),
//               _legend(Colors.redAccent, "Spoiled"),
//               _legend(Colors.grey, "Unknown"),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartCard(
//     String title,
//     List<FlSpot> mainSpots,
//     List<FlSpot> secondarySpots,
//     Color color,
//   ) {
//     return Container(
//       height: 280,
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: LineChart(
//               LineChartData(
//                 gridData: const FlGridData(show: false),
//                 titlesData: const FlTitlesData(show: false),
//                 borderData: FlBorderData(show: false),
//                 lineBarsData: [
//                   if (secondarySpots.isNotEmpty)
//                     LineChartBarData(
//                       spots: secondarySpots,
//                       isCurved: true,
//                       color: Colors.white.withOpacity(0.7),
//                       barWidth: 3,
//                       dashArray: [8, 4],
//                       dotData: const FlDotData(show: false),
//                     ),
//                   LineChartBarData(
//                     spots: mainSpots,
//                     isCurved: true,
//                     color: color,
//                     barWidth: 4,
//                     dotData: const FlDotData(show: false),
//                     belowBarData: BarAreaData(
//                       show: secondarySpots.isEmpty,
//                       color: color.withOpacity(0.1),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (secondarySpots.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: Row(
//                 children: [
//                   Container(width: 8, height: 2, color: Colors.white70),
//                   const SizedBox(width: 4),
//                   Container(width: 8, height: 2, color: Colors.transparent),
//                   const SizedBox(width: 4),
//                   Container(width: 8, height: 2, color: Colors.white70),
//                   const SizedBox(width: 8),
//                   Text(
//                     "Compared to Basket $compareBasketId",
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _legend(Color color, String text) => Row(
//     children: [
//       Container(
//         width: 8,
//         height: 8,
//         decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//       ),
//       const SizedBox(width: 6),
//       Text(text, style: const TextStyle(color: Colors.white60, fontSize: 10)),
//     ],
//   );

//   Widget _glassCircleButton(IconData icon, VoidCallback onTap) => Container(
//     width: 48,
//     height: 48,
//     decoration: BoxDecoration(
//       color: Colors.white.withOpacity(0.08),
//       borderRadius: BorderRadius.circular(16),
//     ),
//     child: IconButton(
//       onPressed: onTap,
//       icon: Icon(icon, color: Colors.white, size: 20),
//     ),
//   );

//   Widget _animatedBackground() => Container(
//     decoration: const BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [Color(0xFF05150d), Color(0xFF0a0a0a)],
//       ),
//     ),
//   );

//   Widget _buildParticles() => AnimatedBuilder(
//     animation: _particleController,
//     builder: (_, __) => CustomPaint(
//       painter: ChartParticlePainter(_particles, _particleController.value),
//       size: Size.infinite,
//     ),
//   );
// }

// // Painter and Particle classes
// class ChartParticle {
//   double x = math.Random().nextDouble();
//   double y = math.Random().nextDouble();
//   double size = math.Random().nextDouble() * 4 + 1;
//   double speedX = (math.Random().nextDouble() - 0.5) * 0.001;
//   double speedY = (math.Random().nextDouble() - 0.5) * 0.001;
// }

// class ChartParticlePainter extends CustomPainter {
//   final List<ChartParticle> particles;
//   final double progress;
//   ChartParticlePainter(this.particles, this.progress);
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
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core (Shared logic, themes, constants)/api_config.dart';

class SensorChartsPage extends StatefulWidget {
  final int basketId;
  const SensorChartsPage({super.key, required this.basketId});

  @override
  State<SensorChartsPage> createState() => _SensorChartsPageState();
}

class _SensorChartsPageState extends State<SensorChartsPage>
    with TickerProviderStateMixin {
  //  DATA STATE
  List<FlSpot> tempSpots = [];
  List<FlSpot> humSpots = [];
  List<FlSpot> gasSpots = [];
  List<FlSpot> co2Spots = [];
  bool isLoading = true;
  bool isHourlySummary = false;

  //  BASKET COMPARISON STATE
  int? compareBasketId;
  List<FlSpot> compareTempSpots = [];
  List<FlSpot> compareHumSpots = [];
  List<FlSpot> compareGasSpots = [];
  List<FlSpot> compareCo2Spots = [];
  List<int> availableBaskets = [];

  //  FILTER STATE
  DateTimeRange? selectedDateRange;

  late AnimationController _particleController;
  final List<ChartParticle> _particles = List.generate(
    20,
    (index) => ChartParticle(),
  );

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _loadAllAnalyticsData();
  }

  Future<void> _loadAllAnalyticsData() async {
    try {
      // load main basket readings
      final mainReadings = await _fetchReadings(widget.basketId);

      tempSpots = _buildSpots(mainReadings, "temp");
      humSpots = _buildSpots(mainReadings, "hum");
      gasSpots = _buildSpots(mainReadings, "tvoc");
      co2Spots = _buildSpots(mainReadings, "mq_volts");

      // load comparison basket readings if selected
      if (compareBasketId != null) {
        final compareReadings = await _fetchReadings(compareBasketId!);
        compareTempSpots = _buildSpots(compareReadings, "temp");
        compareHumSpots = _buildSpots(compareReadings, "hum");
        compareGasSpots = _buildSpots(compareReadings, "tvoc");
        compareCo2Spots = _buildSpots(compareReadings, "mq_volts");
      } else {
        compareTempSpots = [];
        compareHumSpots = [];
        compareGasSpots = [];
        compareCo2Spots = [];
      }

      // load all baskets for dropdown
      availableBaskets = await _fetchBasketIds();

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Load Error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Updated Helper: Uses columnIdx to load specific sensor data
  Future<List<dynamic>> _fetchReadings(int basketId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/basket/$basketId/readings"),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    List<dynamic> readings = data["readings"] as List<dynamic>;

    if (selectedDateRange != null) {
      readings = readings.where((row) {
        final dt = DateTime.tryParse(row["recorded_at"].toString());
        if (dt == null) return false;

        return !dt.isBefore(selectedDateRange!.start) &&
            !dt.isAfter(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return readings;
  }

  List<FlSpot> _buildSpots(List<dynamic> readings, String fieldName) {
    List<FlSpot> spots = [];

    int step = isHourlySummary ? 6 : 1;
    int xIdx = 0;

    for (int i = 0; i < readings.length; i += step) {
      final row = readings[i];
      final double val = (row[fieldName] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(xIdx.toDouble(), val));
      xIdx++;
    }

    return spots;
  }

  Future<List<int>> _fetchBasketIds() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/baskets"),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => e["basket_id"]).whereType<int>().toList();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 15),
                        _buildControlRow(),

                        // CHARTS SECTION
                        const SizedBox(height: 20),
                        _buildChartCard(
                          "TEMPERATURE TREND (°C)",
                          tempSpots,
                          compareTempSpots,
                          const Color(0xFF00FFA3),
                        ),

                        const SizedBox(height: 20),
                        _buildChartCard(
                          "HUMIDITY LEVEL (%)",
                          humSpots,
                          compareHumSpots,
                          Colors.blueAccent,
                        ),

                        const SizedBox(height: 20),
                        _buildChartCard(
                          "GAS EMISSION (TVOC)",
                          gasSpots,
                          compareGasSpots,
                          Colors.orangeAccent,
                        ),

                        const SizedBox(height: 20),
                        _buildChartCard(
                          "CO2 CONCENTRATION (MQ VOLTS)",
                          co2Spots,
                          compareCo2Spots,
                          Colors.purpleAccent,
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButton<int>(
            dropdownColor: const Color(0xFF0a0a0a),
            underline: const SizedBox(),
            hint: const Text(
              "Compare Basket",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            value: compareBasketId,
            items: availableBaskets.where((b) => b != widget.basketId).map((
              int b,
            ) {
              return DropdownMenuItem<int>(
                value: b,
                child: Text(
                  "Basket $b",
                  style: const TextStyle(
                    color: Color(0xFF00FFA3),
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                compareBasketId = val;
                isLoading = true;
              });
              _loadAllAnalyticsData();
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              isHourlySummary = !isHourlySummary;
              isLoading = true;
            });
            _loadAllAnalyticsData();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHourlySummary
                  ? const Color(0xFF00FFA3).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isHourlySummary
                    ? const Color(0xFF00FFA3)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              isHourlySummary ? "Hourly View" : "Raw Data",
              style: TextStyle(
                color: isHourlySummary
                    ? const Color(0xFF00FFA3)
                    : Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          _glassCircleButton(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
          const SizedBox(width: 15),
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _glassCircleButton(Icons.calendar_month, () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2025, 1, 1),
              lastDate: DateTime.now(),
            );
            if (range != null) {
              setState(() {
                selectedDateRange = range;
                isLoading = true;
              });
              _loadAllAnalyticsData();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    List<FlSpot> mainSpots,
    List<FlSpot> secondarySpots,
    Color color,
  ) {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (secondarySpots.isNotEmpty)
                    LineChartBarData(
                      spots: secondarySpots,
                      isCurved: true,
                      color: Colors.white.withOpacity(0.7),
                      barWidth: 3,
                      dashArray: [8, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  LineChartBarData(
                    spots: mainSpots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: secondarySpots.isEmpty,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (secondarySpots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Container(width: 8, height: 2, color: Colors.white70),
                  const SizedBox(width: 4),
                  Container(width: 8, height: 2, color: Colors.transparent),
                  const SizedBox(width: 4),
                  Container(width: 8, height: 2, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    "Compared to Basket $compareBasketId",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassCircleButton(IconData icon, VoidCallback onTap) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  Widget _animatedBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF05150d), Color(0xFF0a0a0a)],
      ),
    ),
  );

  Widget _buildParticles() => AnimatedBuilder(
    animation: _particleController,
    builder: (_, __) => CustomPaint(
      painter: ChartParticlePainter(_particles, _particleController.value),
      size: Size.infinite,
    ),
  );
}

class ChartParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 4 + 1;
  double speedX = (math.Random().nextDouble() - 0.5) * 0.001;
  double speedY = (math.Random().nextDouble() - 0.5) * 0.001;
}

class ChartParticlePainter extends CustomPainter {
  final List<ChartParticle> particles;
  final double progress;
  ChartParticlePainter(this.particles, this.progress);
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
