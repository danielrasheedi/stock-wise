import 'package:flutter/material.dart';

class StockOutScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;
  const StockOutScreen({super.key, this.itemData});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _nameController.text = widget.itemData!['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Validates the input, ensuring deduction doesn't exceed available stock, and returns the stock out data
  void _saveStockOut() {
    if (_formKey.currentState!.validate()) {
      final stockOutData = {
        'name': _nameController.text.trim(),
        'quantity': int.parse(_quantityController.text),
      };
      Navigator.pop(context, stockOutData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableQty = widget.itemData?['quantity'] as int? ?? 0;

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
                  const Text(
                    'Stock Out',
                    style: TextStyle(
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
                        TextFormField(
                          controller: _nameController,
                          readOnly: widget.itemData != null,
                          decoration: InputDecoration(
                            hintText: 'Item Name *',
                            hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: widget.itemData != null
                                ? const Color(0xFFE2E8F0) // Slightly darker when disabled
                                : const Color(0xFFF1F5F9),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an item name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _quantityController,
                          autofocus: widget.itemData != null,
                          decoration: InputDecoration(
                            hintText: 'Quantity to Deduct *',
                            helperText: widget.itemData != null ? 'Available Stock: $availableQty' : null,
                            helperStyle: const TextStyle(color: Color(0xFF64748B)),
                            hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a quantity';
                            }
                            final val = int.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Quantity must be a positive whole number';
                            }
                            if (widget.itemData != null && val > availableQty) {
                              return 'Cannot deduct more than available quantity ($availableQty)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _saveStockOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6387A9),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm Stock Out',
                            style: TextStyle(
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
