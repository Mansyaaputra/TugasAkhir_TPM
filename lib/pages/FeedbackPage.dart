import 'package:flutter/material.dart';
import '../services/NotificationService.dart';

class FeedbackModel {
  final String name;
  final String message;
  final DateTime timestamp;

  FeedbackModel({
    required this.name,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _nameCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  List<FeedbackModel> feedbackList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _loadFeedback() async {
    try {
      // Load dari database atau local storage
      setState(() {
        feedbackList = [];
      });
    } catch (e) {
      print('Error loading feedback: $e');
    }
  }

  void _submitFeedback() async {
    final name = _nameCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (name.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi nama dan pesan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulasi delay untuk menunjukkan loading
      await Future.delayed(Duration(milliseconds: 500));

      // Tambahkan ke list lokal
      final feedback = FeedbackModel(name: name, message: message);
      setState(() {
        feedbackList.insert(0, feedback);
        _isLoading = false;
      });

      NotificationService.showSuccess(
        'Feedback Terkirim',
        'Terima kasih $name! Saran Anda telah berhasil disimpan.',
      );

      _nameCtrl.clear();
      _messageCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terima kasih atas saran Anda!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error submitting feedback: $e');
      NotificationService.showError(
        'Error Feedback',
        'Terjadi kesalahan saat menyimpan feedback: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saran & Kesan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berikan Saran & Kesan Anda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        labelText: 'Saran / Kesan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.comment),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitFeedback,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Mengirim...' : 'Kirim Saran',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isLoading ? Colors.grey : Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Daftar feedback
            if (feedbackList.isNotEmpty) ...[
              Text(
                'Feedback Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: feedbackList.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbackList[index];
                    return Card(
                      color: Colors.blue.shade100,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading:
                            Icon(Icons.message, color: Colors.blue.shade700),
                        title: Text(feedback.name,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(feedback.message),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada feedback',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
