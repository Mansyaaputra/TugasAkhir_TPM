import 'package:flutter/material.dart';
import '../services/ProductService.dart';
import '../services/NotificationService.dart';
import '../services/SensorService.dart';
import 'ProductDetailPage.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  final SensorService _sensorService = SensorService();

  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'semua';

  final List<Map<String, String>> _categories = [
    {'value': 'semua', 'label': 'Semua Produk'},
    {'value': 'deck', 'label': 'Deck'},
    {'value': 'griptape', 'label': 'Griptape'},
    {'value': 'trucks', 'label': 'Trucks'},
    {'value': 'wheels', 'label': 'Wheels'},
    {'value': 'bearing', 'label': 'Bearing'},
    {'value': 'bolt', 'label': 'Bolt'},
  ];
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeSensor();
  }

  void _initializeSensor() async {
    await _sensorService.initialize();
    _sensorService.setShakeCallback(() {
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text('Data produk di-refresh dengan shake!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final products = await ProductService.fetchProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      setState(() {
        _allProducts = [];
        _filteredProducts = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          final description =
              product['description']?.toString().toLowerCase() ?? '';
          final category = product['category']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              description.contains(searchQuery) ||
              category.contains(searchQuery);
        }).toList();
      }
    });

    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      var filtered = List<dynamic>.from(_filteredProducts);

      // Filter by category
      if (_selectedCategory != 'semua') {
        filtered = filtered.where((product) {
          final category = product['category']?.toString().toLowerCase() ?? '';
          return category == _selectedCategory.toLowerCase();
        }).toList();
      }

      _filteredProducts = filtered;
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      if (category == 'semua') {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts
            .where((product) => product['category'] == category)
            .toList();
      }
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Harga tidak tersedia';
    // Jika string mengandung $ (dari API), konversi ke rupiah kasar (misal 1$ = 16.000)
    if (price is String && price.contains('4')) {
      // Ambil angka setelah $ dan konversi ke double
      final numStr = price.replaceAll(RegExp(r'[^0-9.]'), '');
      final double? usd = double.tryParse(numStr);
      if (usd != null) {
        final int rupiah = (usd * 16000).round();
        return 'Rp${rupiah.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
      }
    }
    // Jika double (misal dari API), konversi ke rupiah
    if (price is double) {
      final int rupiah = (price * 16000).round();
      return 'Rp${rupiah.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
    }
    // Format as Rupiah jika int
    int? numPrice = int.tryParse(price.toString());
    if (numPrice != null) {
      return 'Rp${numPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
    }
    return price.toString();
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    String? imageUrl;

    // Check different possible image fields
    if (product['image'] != null && product['image'].toString().isNotEmpty) {
      imageUrl = product['image'];
    } else if (product['imageUrls'] != null &&
        product['imageUrls'] is List &&
        product['imageUrls'].isNotEmpty) {
      imageUrl = product['imageUrls'][0];
    } else if (product['imageUrl'] != null &&
        product['imageUrl'].toString().isNotEmpty) {
      imageUrl = product['imageUrl'];
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: 80, // Lebih kecil agar tidak overflow
          height: 60,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Icon(Icons.image_not_supported,
                color: Colors.grey, size: 32);
          },
        ),
      );
    } else {
      return Icon(Icons.skateboarding, color: Colors.blue, size: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  colors: [Colors.blue.shade400, Colors.indigo.shade400],
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SkateShop',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Temukan skateboard impianmu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 24),
                      onPressed: () {
                        NotificationService.showInfo(
                          'Refresh Data',
                          'Memuat ulang data produk...',
                        );
                        _loadProducts();
                      },
                      tooltip: 'Refresh Data',
                    ),
                  ),
                ],
              ),
            ),

            // Search and Filter Section
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari produk skateboard...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Category Filter
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        icon:
                            Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue ?? 'semua';
                          });
                          _filterByCategory(_selectedCategory);
                        },
                        items: _categories.map<DropdownMenuItem<String>>(
                            (Map<String, String> category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category['value']!),
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(category['label']!),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products Grid
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text('Memuat produk...',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada produk ditemukan',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Coba ubah kata kunci atau kategori',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                  _filteredProducts[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 1 / 3.2, // mirip skateboard deck
        child: Card(
          color: Colors.white, // card putih
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar produk
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      product['image'] ?? '',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              // Nama produk di bawah gambar
              Padding(
                padding:
                    const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 4),
                child: Text(
                  product['name']?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              // Hanya ikon keranjang di bawah nama
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(Icons.shopping_cart_outlined,
                    size: 28, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'deck':
        return Icons.view_column;
      case 'skateboard':
        return Icons.skateboarding;
      case 'helm':
        return Icons.sports_motorsports;
      case 'roda':
        return Icons.circle;
      case 'sepatu':
        return Icons.run_circle;
      case 'aksesoris':
        return Icons.build;
      default:
        return Icons.category;
    }
  }
}
