import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utilities/database.dart';
import '../inventory/item.dart';
import '../../state/app_state.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    // In a browser every frame is decoded in software, so use 720p instead of
    // full HD (less than half the pixels) and check frames more often
    cameraResolution: kIsWeb ? const Size(1280, 720) : null,
    detectionTimeoutMs: kIsWeb ? 100 : 250,
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
    ],
  );
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      var querySnapshot = await Database.userDoc
          .collection('items')
          .where('eanUpc', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await Database.userDoc
            .collection('items')
            .where('sku', isEqualTo: code)
            .limit(1)
            .get();
      }

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final docId = doc.id;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemScreen(itemData: doc.data())),
        );
        if (result != null && result is Map<String, dynamic>) {
          result['updatedAt'] = FieldValue.serverTimestamp();
          await Database.userDoc.collection('items').doc(docId).update(result);
        }
      } else {
        final bool? shouldAdd = await showModalBottomSheet<bool>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          backgroundColor: Colors.white,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Item Not Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6387A9), size: 28),
                    title: const Text(
                      'Add New Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      'Create a new item with barcode "$code"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );

        if (shouldAdd == true && mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemScreen(itemData: {'eanUpc': code, 'sku': code})),
          );
          if (result != null && result is Map<String, dynamic>) {
            result['folderId'] = null; // Root folder
            result['createdAt'] = FieldValue.serverTimestamp();
            result['updatedAt'] = FieldValue.serverTimestamp();
            final qty = result['quantity'] as int? ?? 0;
            if (qty > 0) {
              AppState.incrementStockIn(qty);
            }
            await Database.userDoc.collection('items').add(result);
            AppState.addHistory('add_item', result['name'] as String, qty);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for barcode: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
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
                  const Text(
                    'Barcode Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    // Only show the flashlight button when the camera can use it
                    // (browsers on iPhone, for example, don't allow it)
                    child: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, state, _) {
                        if (state.torchState == TorchState.unavailable) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: Icon(
                            state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () => _scannerController.toggleTorch(),
                        );
                      },
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
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF6387A9), width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
