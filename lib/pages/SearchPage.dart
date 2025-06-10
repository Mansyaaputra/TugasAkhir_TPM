import 'package:flutter/material.dart';
import '../services/ProductService.dart';
import '../services/NotificationService.dart';
import 'ProductDetailPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _selectedProducts = [];
  List<String> _searchHistory = [];

  bool _isLoading = false;
  bool _isSelectionMode = false;
  String _sortBy = 'nama'; // nama, harga_rendah, harga_tinggi
  String _filterCategory = 'semua';
  RangeValues _priceRange = RangeValues(0, 1000);

  final List<String> _categories = [
    'semua',
    'skateboard',
    'helm',
    'roda',
    'sepatu',
    'aksesoris',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      // Jika API gagal, gunakan data dummy untuk demo pencarian
      setState(() {
        _allProducts = _getDummyProducts();
        _filteredProducts = _allProducts;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getDummyProducts() {
    return [
      {
        'title': 'Papan Skateboard Pro',
        'name': 'Papan Skateboard Pro',
        'price': '\$89.99',
        'description':
            'Papan skateboard berkualitas tinggi untuk skater profesional',
        'image': 'https://picsum.photos/300/200?random=1',
        'category': 'skateboard',
        'priceValue': 89.99,
      },
      {
        'title': 'Helm Keselamatan Premium',
        'name': 'Helm Keselamatan Premium',
        'price': '\$34.99',
        'description': 'Helm pelindung untuk skateboarding yang aman',
        'image': 'https://picsum.photos/300/200?random=2',
        'category': 'helm',
        'priceValue': 34.99,
      },
      {
        'title': 'Roda Skateboard Premium',
        'name': 'Roda Skateboard Premium',
        'price': '\$24.99',
        'description': 'Set roda skateboard berkualitas tinggi 52mm',
        'image': 'https://picsum.photos/300/200?random=3',
        'category': 'roda',
        'priceValue': 24.99,
      },
      {
        'title': 'Sepatu Skate Street',
        'name': 'Sepatu Skate Street',
        'price': '\$79.99',
        'description': 'Sepatu skate dengan sole vulkanisir',
        'image': 'https://picsum.photos/300/200?random=4',
        'category': 'sepatu',
        'priceValue': 79.99,
      },
      {
        'title': 'Bearing ABEC-7',
        'name': 'Bearing ABEC-7',
        'price': '\$19.99',
        'description': 'Set bearing ABEC-7 precision untuk roda skateboard',
        'image': 'https://picsum.photos/300/200?random=5',
        'category': 'aksesoris',
        'priceValue': 19.99,
      },
      {
        'title': 'Grip Tape Pro',
        'name': 'Grip Tape Pro',
        'price': '\$12.99',
        'description': 'Grip tape anti slip untuk deck skateboard',
        'image': 'https://picsum.photos/300/200?random=6',
        'category': 'aksesoris',
        'priceValue': 12.99,
      },
    ];
  }

  void _loadSearchHistory() {
    // Simulasi load dari local storage
    setState(() {
      _searchHistory = [
        'skateboard deck',
        'helm safety',
        'roda 52mm',
        'sepatu vans',
      ];
    });
  }

  void _addToSearchHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  void _performSearch(String query) {
    _addToSearchHistory(query);

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
      if (_filterCategory != 'semua') {
        filtered = filtered.where((product) {
          final category = product['category']?.toString().toLowerCase() ?? '';
          return category.contains(_filterCategory);
        }).toList();
      }

      // Filter by price range
      filtered = filtered.where((product) {
        final priceValue =
            product['priceValue'] ?? _extractPriceValue(product['price']);
        return priceValue >= _priceRange.start && priceValue <= _priceRange.end;
      }).toList();

      // Sort products
      switch (_sortBy) {
        case 'nama':
          filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          break;
        case 'harga_rendah':
          filtered.sort((a, b) {
            final priceA = a['priceValue'] ?? _extractPriceValue(a['price']);
            final priceB = b['priceValue'] ?? _extractPriceValue(b['price']);
            return priceA.compareTo(priceB);
          });
          break;
        case 'harga_tinggi':
          filtered.sort((a, b) {
            final priceA = a['priceValue'] ?? _extractPriceValue(a['price']);
            final priceB = b['priceValue'] ?? _extractPriceValue(b['price']);
            return priceB.compareTo(priceA);
          });
          break;
      }

      _filteredProducts = filtered;
    });
  }

  double _extractPriceValue(String? priceString) {
    if (priceString == null) return 0.0;
    final cleaned = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProducts.clear();
      }
    });
  }

  void _toggleProductSelection(dynamic product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  void _performBulkAction(String action) {
    if (_selectedProducts.isEmpty) return;

    switch (action) {
      case 'compare':
        _compareProducts();
        break;
      case 'wishlist':
        _addToWishlist();
        break;
      case 'share':
        _shareProducts();
        break;
    }
  }

  void _compareProducts() {
    NotificationService.showInfo(
      'Perbandingan Produk',
      '${_selectedProducts.length} produk ditambahkan ke perbandingan',
      actionLabel: 'Lihat Perbandingan',
      onAction: () {
        // Navigate to compare page
      },
    );

    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  void _addToWishlist() {
    NotificationService.showSuccess(
      'Wishlist',
      '${_selectedProducts.length} produk ditambahkan ke wishlist',
    );

    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  void _shareProducts() {
    NotificationService.showInfo(
      'Berbagi Produk',
      '${_selectedProducts.length} produk dibagikan',
    );

    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedProducts.length} Dipilih')
            : Text('Pencarian Produk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.compare),
              onPressed: () => _performBulkAction('compare'),
              tooltip: 'Bandingkan',
            ),
            IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: () => _performBulkAction('wishlist'),
              tooltip: 'Tambah ke Wishlist',
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () => _performBulkAction('share'),
              tooltip: 'Bagikan',
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Tutup Mode Pilih',
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.tune),
              onPressed: _showFilterSheet,
              tooltip: 'Filter & Urutkan',
            ),
            IconButton(
              icon: Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Mode Pilih',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Cari produk skateboard...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),

          // Quick Filters
          _buildQuickFilters(),

          // Search Results or History
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSearchHistory()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _filterCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getCategoryDisplayName(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterCategory = category;
                });
                _applyFilters();
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'semua':
        return 'Semua';
      case 'skateboard':
        return 'Skateboard';
      case 'helm':
        return 'Helm';
      case 'roda':
        return 'Roda';
      case 'sepatu':
        return 'Sepatu';
      case 'aksesoris':
        return 'Aksesoris';
      default:
        return category;
    }
  }

  Widget _buildSearchHistory() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'Riwayat Pencarian',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        ..._searchHistory
            .map((query) => ListTile(
                  leading: Icon(Icons.history, color: Colors.grey),
                  title: Text(query),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchHistory.remove(query);
                      });
                    },
                  ),
                ))
            .toList(),
        if (_searchHistory.isNotEmpty) ...[
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _searchHistory.clear();
              });
            },
            child: Text('Hapus Semua Riwayat'),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coba gunakan kata kunci lain',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final isSelected = _selectedProducts.contains(product);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isSelectionMode && isSelected
            ? BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isSelectionMode) {
            _toggleProductSelection(product);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleProductSelection(product);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection Checkbox
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleProductSelection(product),
                ),
                SizedBox(width: 8),
              ],

              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image'] ?? 'https://picsum.photos/100/100?random=1',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Produk Skateboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      product['description'] ?? 'Deskripsi produk',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product['price'] ?? '\$0.00',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (!_isSelectionMode)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Urutkan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Sort Options
              Text(
                'Urutkan berdasarkan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Nama A-Z'),
                    value: 'nama',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() => _sortBy = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Harga Terendah'),
                    value: 'harga_rendah',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() => _sortBy = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Harga Tertinggi'),
                    value: 'harga_tinggi',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() => _sortBy = value!);
                    },
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Price Range
              Text(
                'Rentang Harga: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000,
                divisions: 20,
                labels: RangeLabels(
                  '\$${_priceRange.start.round()}',
                  '\$${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                },
              ),

              SizedBox(height: 20),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Apply filters
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Terapkan Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
