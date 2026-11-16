import 'package:flutter/material.dart';
import '../../utilities/barcode_saver/barcode_saver.dart';
import 'package:http/http.dart' as http;
import '../../state/app_state.dart';

class ItemScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;
  const ItemScreen({super.key, this.itemData});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _eanUpcController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDownloadingEanUpc = false;
  bool _isDownloadingSku = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _nameController.text = widget.itemData!['name'] ?? '';
      _quantityController.text = (widget.itemData!['quantity'] ?? '').toString();
      final usdPrice = (widget.itemData!['price'] as num?)?.toDouble() ?? 0.0;
      final localPrice = AppState.getConvertedPrice(usdPrice);
      _priceController.text = localPrice > 0 ? localPrice.toStringAsFixed(2) : '';
      _eanUpcController.text = widget.itemData!['eanUpc'] ?? '';
      _skuController.text = widget.itemData!['sku'] ?? '';
      _descriptionController.text = widget.itemData!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _eanUpcController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Extracts the currency symbol from the global [AppState.currency].
  String _getCurrencySymbol() {
    return AppState.getCurrencySymbol();
  }

  /// Validates the form and returns the item data to the previous screen
  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final localPrice = double.parse(_priceController.text);
      final usdPrice = AppState.getUsdPrice(localPrice);
      final item = {
        'name': _nameController.text.trim(),
        'quantity': int.parse(_quantityController.text),
        'price': usdPrice,
        'eanUpc': _eanUpcController.text.trim().isNotEmpty
            ? _eanUpcController.text.trim()
            : null,
        'sku': _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      };
      Navigator.pop(context, item);
    }
  }

  Future<void> _downloadEanUpc() async {
    final code = _eanUpcController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an EAN/UPC first')),
      );
      return;
    }

    setState(() {
      _isDownloadingEanUpc = true;
    });

    try {
      final response = await http.get(Uri.parse('https://barcodeapi.org/api/128/${Uri.encodeComponent(code)}'));
      if (response.statusCode == 200) {
        final result = await saveBarcodeImage(response.bodyBytes, '$code.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barcode $result')),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving barcode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingEanUpc = false;
        });
      }
    }
  }

  Future<void> _downloadSku() async {
    final code = _skuController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an SKU first')),
      );
      return;
    }

    setState(() {
      _isDownloadingSku = true;
    });

    try {
      final response = await http.get(Uri.parse('https://barcodeapi.org/api/128/${Uri.encodeComponent(code)}'));
      if (response.statusCode == 200) {
        final result = await saveBarcodeImage(response.bodyBytes, '$code.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SKU barcode $result')),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving SKU barcode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingSku = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              color: const Color(0xFF6387A9),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.itemData != null ? 'Edit Item Details' : 'Add New Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Item Name *',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an item name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Quantity *',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Quantity must be a whole number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Price *',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            prefixText: "${_getCurrencySymbol()} ",
                            prefixStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid price (e.g., 19.99)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'EAN/UPC (Optional)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _eanUpcController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            suffixIcon: IconButton(
                              icon: _isDownloadingEanUpc 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.download_rounded, color: Color(0xFF6387A9)),
                              onPressed: _isDownloadingEanUpc ? null : _downloadEanUpc,
                              tooltip: 'Download Barcode Image',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'SKU *',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _skuController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            suffixIcon: IconButton(
                              icon: _isDownloadingSku 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.download_rounded, color: Color(0xFF6387A9)),
                              onPressed: _isDownloadingSku ? null : _downloadSku,
                              tooltip: 'Download SKU Barcode Image',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an SKU';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Description (Optional)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6387A9),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.itemData != null ? 'Save Changes' : 'Add Item',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}