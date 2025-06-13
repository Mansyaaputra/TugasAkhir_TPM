import 'package:flutter/material.dart';
import '../services/ProductService.dart';
import '../services/NotificationService.dart';
import 'ProductDetailPage.dart';

class SearchPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddOrder;
  const SearchPage({Key? key, required this.onAddOrder}) : super(key: key);

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
    'deck',
    'griptape',
    'trucks',
    'wheels',
    'bearing',
    'bolt',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSearchHistory();
    // Remove auto focus untuk menghindari keyboard pop-up yang tidak diinginkan
    // _searchFocusNode.requestFocus();
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
      // Jika API gagal, tampilkan pesan error
      setState(() {
        _allProducts = [];
        _filteredProducts = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat produk: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadSearchHistory() {
    // Load dari local storage atau database
    setState(() {
      _searchHistory = [
        'skateboard deck',
        'roda skateboard',
        'bearing ABEC',
        'grip tape',
        'truck skateboard',
      ];
    });
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
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

    // Add to search history only if query is not empty
    if (query.isNotEmpty) {
      _addToSearchHistory(query);
    }

    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      // Start with current search results
      var filtered = List<dynamic>.from(_filteredProducts);

      // Apply category filter
      if (_filterCategory != 'semua') {
        filtered = filtered.where((product) {
          final category = product['category']?.toString().toLowerCase() ?? '';
          return category == _filterCategory.toLowerCase();
        }).toList();
      }

      // Apply price range filter
      filtered = filtered.where((product) {
        final priceValue =
            product['priceValue'] ?? _extractPriceValue(product['price']);
        return priceValue >= _priceRange.start && priceValue <= _priceRange.end;
      }).toList();

      // Apply sorting
      switch (_sortBy) {
        case 'nama':
          filtered.sort((a, b) {
            final nameA = a['name']?.toString() ?? '';
            final nameB = b['name']?.toString() ?? '';
            return nameA.compareTo(nameB);
          });
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
                          setState(() {
                            _searchController.clear();
                          });
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
              onChanged: (value) {
                setState(() {}); // Update UI untuk suffix icon
                _performSearch(value);
              },
              onSubmitted: _performSearch,
            ),
          ),
          _buildQuickFilters(),
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
                // Re-apply current search with new filter
                _performSearch(_searchController.text);
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
      case 'deck':
        return 'Deck';
      case 'griptape':
        return 'Griptape';
      case 'trucks':
        return 'Trucks';
      case 'wheels':
        return 'Wheels';
      case 'bearing':
        return 'Bearing';
      case 'bolt':
        return 'Bolt';
      default:
        return category.toUpperCase();
    }
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Mulai cari produk skateboard',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ketik kata kunci di kolom pencarian',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

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
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                      product: product, onAddOrder: widget.onAddOrder),
                ),
              ).then((_) {
                // Handle navigation completion
              }).catchError((error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error navigasi: ${error.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return Future
                    .value(); // Return empty future to avoid type error
              });
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
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
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleProductSelection(product),
                ),
                SizedBox(width: 8),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProductImage(product),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name']?.toString() ?? 'Produk Skateboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      product['description']?.toString() ?? 'Deskripsi produk',
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
                          product['price']?.toString() ??
                              'Harga tidak tersedia',
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

  Widget _buildProductImage(dynamic product) {
    final imageUrl = product['image']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[600],
              size: 30,
            ),
          );
        },
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.skateboarding,
          color: Colors.grey[600],
          size: 30,
        ),
      );
    }
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
