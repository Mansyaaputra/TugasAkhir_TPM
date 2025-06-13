import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversionPage extends StatefulWidget {
  @override
  _CState createState() => _CState();
}

class _CState extends State<ConversionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Currency conversion variables
  final _amountCtrl = TextEditingController(text: '1');
  String _from = 'USD', _to = 'IDR', _result = '';

  // Gunakan data real atau dari API
  Map<String, double> rates = {
    'USD': 1,
    'IDR': 15000,
    'EUR': 0.85,
    'JPY': 110,
    'GBP': 0.75,
    'AUD': 1.35
  };

  // Time conversion variables tetap sama karena bukan dummy
  String _fromTimeZone = 'WIB', _toTimeZone = 'WITA';
  String _timeResult = '';

  final Map<String, Map<String, dynamic>> timeZones = {
    'WIB': {'offset': 7, 'name': 'Waktu Indonesia Barat (UTC+7)'},
    'WITA': {'offset': 8, 'name': 'Waktu Indonesia Tengah (UTC+8)'},
    'WIT': {'offset': 9, 'name': 'Waktu Indonesia Timur (UTC+9)'},
    'UTC': {'offset': 0, 'name': 'Coordinated Universal Time (UTC+0)'},
    'GMT': {'offset': 0, 'name': 'Greenwich Mean Time (UTC+0)'},
    'JST': {'offset': 9, 'name': 'Japan Standard Time (UTC+9)'},
    'KST': {'offset': 9, 'name': 'Korea Standard Time (UTC+9)'},
    'PST': {'offset': -8, 'name': 'Pacific Standard Time (UTC-8)'},
    'EST': {'offset': -5, 'name': 'Eastern Standard Time (UTC-5)'},
  };
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _convert() {
    final a = double.tryParse(_amountCtrl.text) ?? 1;
    final r = a * (rates[_to]! / rates[_from]!);
    setState(() => _result = r.toStringAsFixed(2));
  }

  void _convertTime() {
    // Gunakan waktu saat ini
    final now = DateTime.now();

    // Get timezone offsets
    final fromOffset = timeZones[_fromTimeZone]!['offset'] as int;
    final toOffset = timeZones[_toTimeZone]!['offset'] as int;

    // Convert to UTC first, then to target timezone
    final utcTime = now.subtract(Duration(hours: fromOffset));
    final convertedTime = utcTime.add(Duration(hours: toOffset));

    setState(() {
      _timeResult = DateFormat('dd/MM/yyyy HH:mm').format(convertedTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar with gradient
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Konversi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      labelColor: Colors.blue.shade700,
                      unselectedLabelColor: Colors.white,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.monetization_on),
                          text: 'Mata Uang',
                        ),
                        Tab(
                          icon: Icon(Icons.access_time),
                          text: 'Waktu',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrencyConverter(),
                  _buildTimeConverter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyConverter() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Konversi Mata Uang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _from,
                          decoration: InputDecoration(
                            labelText: 'Dari',
                            border: OutlineInputBorder(),
                          ),
                          items: rates.keys
                              .map((e) => DropdownMenuItem(
                                    child: Text(e),
                                    value: e,
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _from = v!),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.arrow_right_alt, size: 32),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _to,
                          decoration: InputDecoration(
                            labelText: 'Ke',
                            border: OutlineInputBorder(),
                          ),
                          items: rates.keys
                              .map((e) => DropdownMenuItem(
                                    child: Text(e),
                                    value: e,
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _to = v!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _convert,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      'Konversi',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  if (_result.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50, // kembali hijau
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Hasil: $_result $_to',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700, // hijau
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kurs Mata Uang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...rates.entries
                      .map((entry) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  child: Text(
                                    entry.key,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('1 USD = ${entry.value} ${entry.key}'),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeConverter() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Konversi Waktu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waktu saat ini: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fromTimeZone,
                          decoration: InputDecoration(
                            labelText: 'Dari Zona Waktu',
                            border: OutlineInputBorder(),
                          ),
                          items: timeZones.entries
                              .map((e) => DropdownMenuItem(
                                    child: Text(
                                      '${e.key}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: e.key,
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _fromTimeZone = v!),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.arrow_right_alt, size: 32),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _toTimeZone,
                          decoration: InputDecoration(
                            labelText: 'Ke Zona Waktu',
                            border: OutlineInputBorder(),
                          ),
                          items: timeZones.entries
                              .map((e) => DropdownMenuItem(
                                    child: Text(
                                      '${e.key}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: e.key,
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _toTimeZone = v!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _convertTime,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      'Konversi Waktu',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  if (_timeResult.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100, // biru muda
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _timeResult,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // font hitam
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Saat Ini di Berbagai Zona',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...timeZones.entries.take(4).map((entry) {
                    final now = DateTime.now()
                        .toUtc()
                        .add(Duration(hours: entry.value['offset']));
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM HH:mm').format(now),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(Icons.public,
                                color: Colors.blue.shade400, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
