import 'package:flutter/material.dart';
import '../models/FeedbackModel.dart';

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({Key? key}) : super(key: key);

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _saranController = TextEditingController();
  final _kesanController = TextEditingController();
  bool _isLoading = false;
  List<FeedbackModel> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _saranController.dispose();
    _kesanController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    try {
      // Untuk demo, kita gunakan state lokal dengan contoh data
      print('Loading feedback from local state...');

      // Simulasi delay loading
      await Future.delayed(Duration(milliseconds: 500));

      // Tambahkan beberapa contoh feedback untuk demo
      final exampleFeedback = [
        FeedbackModel(
          name: 'Ahmad Rizki',
          message:
              'SARAN: Materi pembelajaran Flutter sebaiknya ditambah dengan lebih banyak praktik hands-on project. Mungkin bisa ditambah workshop pengembangan aplikasi mobile yang lebih kompleks.\n\nKESAN: Mata kuliah TPM sangat menarik dan memberikan wawasan baru tentang teknologi mobile. Dosen sangat supportif dan materi yang diajarkan up-to-date dengan perkembangan teknologi.',
        ),
        FeedbackModel(
          name: 'Sari Melati',
          message:
              'SARAN: Lebih baik jika ada lebih banyak studi kasus nyata dari industri. Juga mungkin bisa diundang praktisi industri untuk sharing experience.\n\nKESAN: Pembelajaran sangat menyenangkan, terutama saat praktik membuat aplikasi. Terima kasih untuk guidance yang diberikan selama semester ini.',
        ),
        FeedbackModel(
          name: 'Budi Santoso',
          message:
              'SARAN: Waktu untuk project akhir mungkin bisa diperpanjang agar hasil lebih maksimal. Dan mungkin bisa ditambah sesi konsultasi individu.\n\nKESAN: Mata kuliah ini membuka mata saya tentang potensi besar pengembangan aplikasi mobile. Semoga kedepannya bisa lebih banyak eksplorasi teknologi terbaru.',
        ),
      ];

      if (mounted) {
        setState(() {
          _feedbackList = exampleFeedback;
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      if (mounted) {
        setState(() {
          _feedbackList = [];
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final feedback = FeedbackModel(
        id: DateTime.now()
            .millisecondsSinceEpoch, // ID unik berdasarkan timestamp
        name: _namaController.text.trim(),
        message:
            'SARAN: ${_saranController.text.trim()}\n\nKESAN: ${_kesanController.text.trim()}',
      );

      // Simulasi delay untuk menunjukkan proses penyimpanan
      await Future.delayed(Duration(milliseconds: 1000));

      // Tambahkan ke awal list agar feedback baru muncul di atas
      if (mounted) {
        setState(() {
          _feedbackList.insert(0, feedback);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saran dan kesan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _namaController.clear();
        _saranController.clear();
        _kesanController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Method untuk memformat dan menampilkan content saran dan kesan
  Widget _buildFeedbackContent(String message) {
    // Parse message untuk memisahkan saran dan kesan
    final parts = message.split('\n\nKESAN:');
    String saran = parts[0].replaceFirst('SARAN: ', '');
    String kesan = parts.length > 1 ? parts[1].trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bagian Saran
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.lightbulb,
                color: Colors.orange.shade700,
                size: 16,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    saran,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (kesan.isNotEmpty) ...[
          SizedBox(height: 16),
          // Bagian Kesan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red.shade700,
                  size: 16,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kesan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      kesan,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saran & Kesan TPM'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mata Kuliah',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Teknologi dan Pemrograman Mobile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Semester 6 - 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Form Section
            Text(
              'Berikan Saran dan Kesan Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nama Field
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Saran Field
                  TextFormField(
                    controller: _saranController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Saran untuk Mata Kuliah TPM',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.lightbulb, color: Colors.orange),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      helperText:
                          'Contoh: Materi yang ingin ditambahkan, metode pembelajaran, dll.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Saran tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Saran minimal 10 karakter';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Kesan Field
                  TextFormField(
                    controller: _kesanController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Kesan selama Mengikuti Mata Kuliah TPM',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.favorite, color: Colors.red),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      helperText:
                          'Contoh: Pengalaman belajar, tantangan yang dihadapi, dll.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kesan tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Kesan minimal 10 karakter';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitFeedback,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Mengirim...' : 'Kirim Saran & Kesan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ), // Feedback List Section
            if (_feedbackList.isNotEmpty) ...[
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.forum,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saran & Kesan dari Mahasiswa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_feedbackList.length} feedback tersimpan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_feedbackList.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _feedbackList.length,
                itemBuilder: (context, index) {
                  final feedback = _feedbackList[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.deepPurple.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan avatar dan nama
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Text(
                                  feedback.name.isNotEmpty
                                      ? feedback.name[0].toUpperCase()
                                      : 'A',
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      feedback.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Mahasiswa TPM',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.school,
                                color: Colors.deepPurple.shade300,
                                size: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Divider
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),

                          // Content dengan parsing saran dan kesan
                          _buildFeedbackContent(feedback.message),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
