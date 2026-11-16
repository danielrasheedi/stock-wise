import 'package:flutter/material.dart';
import '../../widgets/folder_delete_confirmation_modal.dart';
import '../../widgets/item_delete_confirmation_modal.dart';
import '../../widgets/item_action_modal.dart';
import '../../widgets/item_sort_modal.dart';
import 'stock_in.dart';
import 'item.dart';
import 'stock_out.dart';
import '../../state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utilities/database.dart';


class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => ItemsScreenState();
}

/// Manages the local lists of folders and items, and handles CRUD operations
class ItemsScreenState extends State<ItemsScreen> {
  String? _activeFolderId;
  
  List<QueryDocumentSnapshot> _currentFolders = [];
  List<QueryDocumentSnapshot> _currentItems = [];

  bool _isCreatingFolder = false;
  final TextEditingController _folderController = TextEditingController();

  String? _editingFolderId;
  final TextEditingController _editFolderController = TextEditingController();

  String? _editingItemId;
  final TextEditingController _editItemController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  SortOrder _currentSort = SortOrder.newest;

  void _updateCounts() {
    final threshold = AppState.lowStockThreshold.value;
    int lowStock = 0;
    int outOfStock = 0;
    double totalUsdValue = 0.0;
    
    for (var doc in _currentItems) {
      final data = doc.data() as Map<String, dynamic>;
      final qty = data['quantity'] as int? ?? 0;
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      
      if (qty <= threshold) lowStock++;
      if (qty == 0) outOfStock++;
      
      totalUsdValue += (qty * price);
    }
    
    AppState.lowStockItemsCount.value = lowStock;
    AppState.outOfStockItemsCount.value = outOfStock;
    AppState.totalItems.value = _currentItems.length;
    AppState.totalFolders.value = _currentFolders.length;
    AppState.totalInventoryValueUsd.value = totalUsdValue;
  }

  @override
  void initState() {
    super.initState();
    AppState.lowStockThreshold.addListener(_updateCounts);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    AppState.lowStockThreshold.removeListener(_updateCounts);
    _folderController.dispose();
    _editFolderController.dispose();
    _editItemController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAllDescendantFolderIds(String parentId) {
    final List<String> ids = [];
    void recurse(String pid) {
      for (final folder in _currentFolders) {
        final data = folder.data() as Map<String, dynamic>;
        final pId = data.containsKey('parentID') ? data['parentID'] : (data.containsKey('parentId') ? data['parentId'] : null);
        if (pId == pid) {
          ids.add(folder.id);
          recurse(folder.id);
        }
      }
    }
    recurse(parentId);
    return ids;
  }

  void _submitNewFolder(String value) async {
    if (value.trim().isNotEmpty) {
      await Database.userDoc.collection('folders').add({
        'name': value.trim(),
        'parentID': _activeFolderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    setState(() {
      _isCreatingFolder = false;
      _folderController.clear();
    });
  }

  void _submitRenameFolder(String id, String value) async {
    if (value.trim().isNotEmpty) {
      await Database.userDoc.collection('folders').doc(id).update({
        'name': value.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    setState(() {
      _editingFolderId = null;
      _editFolderController.clear();
    });
  }

  void _submitRenameItem(String id, String value) async {
    if (value.trim().isNotEmpty) {
      await Database.userDoc.collection('items').doc(id).update({
        'name': value.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    setState(() {
      _editingItemId = null;
      _editItemController.clear();
    });
  }

  void addItem(Map<String, dynamic> item) async {
    item['folderId'] = _activeFolderId;
    item['createdAt'] = FieldValue.serverTimestamp();
    item['updatedAt'] = FieldValue.serverTimestamp();
    
    final qty = item['quantity'] as int? ?? 0;
    if (qty > 0) {
      AppState.incrementStockIn(qty);
    }
    await Database.userDoc.collection('items').add(item);
    AppState.addHistory('add_item', item['name'] as String, qty);
  }

  void editItem(String id, Map<String, dynamic> updatedItem) async {
    updatedItem['updatedAt'] = FieldValue.serverTimestamp();
    await Database.userDoc.collection('items').doc(id).update(updatedItem);
  }

  void stockInItem(String name, int qty) async {
    AppState.incrementStockIn(qty);
    AppState.addHistory('stock_in', name, qty);
    final idx = _currentItems.indexWhere((doc) =>
        (doc['name'] as String).toLowerCase() == name.toLowerCase() &&
        (doc.data() as Map<String, dynamic>)['folderId'] == _activeFolderId);
    if (idx != -1) {
      final doc = _currentItems[idx];
      final newQty = ((doc.data() as Map<String, dynamic>)['quantity'] as int? ?? 0) + qty;
      await Database.userDoc.collection('items').doc(doc.id).update({
        'quantity': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully stocked in $qty units of "${doc['name']}"')),
        );
      }
    } else {
      await Database.userDoc.collection('items').add({
        'name': name,
        'quantity': qty,
        'price': 0.0,
        'description': 'Automated Stock In entry',
        'folderId': _activeFolderId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created new item "$name" with $qty units')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Database.userDoc.collection('folders').snapshots(),
      builder: (context, folderSnapshot) {
        if (folderSnapshot.hasData) {
          _currentFolders = folderSnapshot.data!.docs;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: Database.userDoc.collection('items').snapshots(),
          builder: (context, itemSnapshot) {
            if (itemSnapshot.hasData) {
              _currentItems = itemSnapshot.data!.docs;
              WidgetsBinding.instance.addPostFrameCallback((_) => _updateCounts());
            }

            var filteredFolders = _currentFolders.where((f) {
              final data = f.data() as Map<String, dynamic>;
              final pId = data.containsKey('parentID') ? data['parentID'] : (data.containsKey('parentId') ? data['parentId'] : null);
              if (pId != _activeFolderId) return false;
              if (_searchQuery.isNotEmpty) {
                return (data['name'] as String).toLowerCase().contains(_searchQuery);
              }
              return true;
            }).toList();

            var filteredItems = _currentItems.where((item) {
              final data = item.data() as Map<String, dynamic>;
              if (data['folderId'] != _activeFolderId) return false;
              if (_searchQuery.isNotEmpty) {
                return (data['name'] as String).toLowerCase().contains(_searchQuery);
              }
              return true;
            }).toList();

            Timestamp getSortTime(Map<String, dynamic> data) {
              return (data['createdAt'] as Timestamp?) ?? 
                     (data['updatedAt'] as Timestamp?) ?? 
                     Timestamp.fromMillisecondsSinceEpoch(0);
            }

            if (_currentSort == SortOrder.ascending) {
              filteredFolders.sort((a, b) => ((a.data() as Map<String, dynamic>)['name'] as String).toLowerCase().compareTo(((b.data() as Map<String, dynamic>)['name'] as String).toLowerCase()));
              filteredItems.sort((a, b) => ((a.data() as Map<String, dynamic>)['name'] as String).toLowerCase().compareTo(((b.data() as Map<String, dynamic>)['name'] as String).toLowerCase()));
            } else if (_currentSort == SortOrder.descending) {
              filteredFolders.sort((a, b) => ((b.data() as Map<String, dynamic>)['name'] as String).toLowerCase().compareTo(((a.data() as Map<String, dynamic>)['name'] as String).toLowerCase()));
              filteredItems.sort((a, b) => ((b.data() as Map<String, dynamic>)['name'] as String).toLowerCase().compareTo(((a.data() as Map<String, dynamic>)['name'] as String).toLowerCase()));
            } else if (_currentSort == SortOrder.newest) {
              filteredFolders.sort((a, b) => getSortTime(b.data() as Map<String, dynamic>).compareTo(getSortTime(a.data() as Map<String, dynamic>)));
              filteredItems.sort((a, b) => getSortTime(b.data() as Map<String, dynamic>).compareTo(getSortTime(a.data() as Map<String, dynamic>)));
            } else if (_currentSort == SortOrder.oldest) {
              filteredFolders.sort((a, b) => getSortTime(a.data() as Map<String, dynamic>).compareTo(getSortTime(b.data() as Map<String, dynamic>)));
              filteredItems.sort((a, b) => getSortTime(a.data() as Map<String, dynamic>).compareTo(getSortTime(b.data() as Map<String, dynamic>)));
            }

            String getHeaderTitle() {
              if (_activeFolderId == null) return 'Inventory';
              try {
                final currentFolder = _currentFolders.firstWhere((f) => f.id == _activeFolderId);
                return (currentFolder.data() as Map<String, dynamic>)['name'] as String;
              } catch (e) {
                return 'Inventory';
              }
            }

            return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              color: const Color(0xFF6387A9),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_activeFolderId != null)
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                        onPressed: () {
                          try {
                            final currentFolder = _currentFolders.firstWhere((f) => f.id == _activeFolderId);
                            final data = currentFolder.data() as Map<String, dynamic>;
                            setState(() {
                              _activeFolderId = data.containsKey('parentID') ? data['parentID'] : (data.containsKey('parentId') ? data['parentId'] : null);
                            });
                          } catch (_) {
                            setState(() {
                              _activeFolderId = null;
                            });
                          }
                        },
                      ),
                    ),
                  Text(
                    getHeaderTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white, size: 26),
                      onPressed: () {
                        showSortActionModal(
                          context,
                          currentSort: _currentSort,
                          onSortSelected: (order) {
                            setState(() {
                              _currentSort = order;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF64748B), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search your item or folder here',
                              hintStyle: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty && filteredFolders.isEmpty && filteredItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        'Item not found',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Folders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredFolders.length + 1, // +1 for the topmost creation tile
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildGhostTile();
                        }
                        return _buildFolderTile(index - 1, filteredFolders);
                      },
                    ),
                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _activeFolderId != null ? 'Items' : 'Items',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredItems.length + 1, // +1 for the ghost tile
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildItemGhostTile();
                        }
                        return _buildItemTile(index - 1, filteredItems);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
          },
        );
      },
    );
  }

  Widget _buildFolderTile(int index, List<QueryDocumentSnapshot> filteredFolders) {
    final folder = filteredFolders[index];
    final docId = folder.id;
    final folderData = folder.data() as Map<String, dynamic>;
    final folderName = folderData['name'] as String;

    if (_editingFolderId == docId) {
      return Container(
        height: 64, // Matches search bar and normal folder tile
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
        alignment: Alignment.center,
        child: Row(
          children: [
            const Icon(Icons.folder_open_rounded, color: Color(0xFF6387A9), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _editFolderController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => _submitRenameFolder(docId, value),
                decoration: const InputDecoration(
                  hintText: 'Rename folder...',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              onPressed: () {
                setState(() {
                  _editingFolderId = null;
                  _editFolderController.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64, // Matches search bar and ghost tile
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _activeFolderId = docId;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Row(
              children: [
                const Icon(Icons.folder_rounded, color: Color(0xFF6387A9), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    folderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 22),
                  onPressed: () {
                    setState(() {
                      _editingFolderId = docId;
                      _editFolderController.text = folderName;
                      _isCreatingFolder = false;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  onPressed: () {
                    showDeleteConfirmationModal(
                      context,
                      folderName: folderName,
                      onConfirm: () async {
                        final descendantIds = _getAllDescendantFolderIds(docId);
                        final itemsToDelete = _currentItems.where((item) {
                          final fId = (item.data() as Map<String, dynamic>)['folderId'];
                          return fId == docId || descendantIds.contains(fId);
                        }).toList();
                        
                        for (final item in itemsToDelete) {
                          final iData = item.data() as Map<String, dynamic>;
                          AppState.addHistory('delete_item', iData['name'] as String, null);
                          await Database.userDoc.collection('items').doc(item.id).delete();
                        }
                        
                        final foldersToDelete = _currentFolders.where((f) => f.id == docId || descendantIds.contains(f.id)).toList();
                        for (final f in foldersToDelete) {
                          await Database.userDoc.collection('folders').doc(f.id).delete();
                        }
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$folderName" and all contents deleted')),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostTile() {
    if (_isCreatingFolder) {
      return Container(
        height: 64, // Matches search bar and folder tiles
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
        alignment: Alignment.center,
        child: Row(
          children: [
            const Icon(Icons.folder_open_rounded, color: Color(0xFF94A3B8), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _folderController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: _submitNewFolder,
                decoration: const InputDecoration(
                  hintText: 'Folder name...',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              onPressed: () {
                setState(() {
                  _isCreatingFolder = false;
                  _folderController.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isCreatingFolder = true;
          _editingFolderId = null;
        });
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF94A3B8),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF94A3B8), size: 24),
            SizedBox(width: 8),
            Text(
              'New Folder',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGhostTile() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ItemScreen()),
        );
        if (result != null && result is Map<String, dynamic>) {
          addItem(result);
        }
      },
      child: Container(
        height: 64, // Matches search bar and folder tiles
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF94A3B8),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF94A3B8), size: 24),
            SizedBox(width: 8),
            Text(
              'New Item',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(int index, List<QueryDocumentSnapshot> filteredItems) {
    final item = filteredItems[index];
    final docId = item.id;
    final itemData = item.data() as Map<String, dynamic>;

    if (_editingItemId == docId) {
      return Container(
        height: 64, // Matches search bar and folder tiles
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
        alignment: Alignment.center,
        child: Row(
          children: [
            const Icon(Icons.inventory_2_rounded, color: Color(0xFF6387A9), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _editItemController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => _submitRenameItem(docId, value),
                decoration: const InputDecoration(
                  hintText: 'Rename item...',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              onPressed: () {
                setState(() {
                  _editingItemId = null;
                  _editItemController.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    final itemName = itemData['name'] as String;

    return Container(
      height: 64, // Matches search bar and ghost tile
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showItemActionModal(
              context,
              itemName: itemName,
              onEditDetails: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemScreen(itemData: itemData),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  editItem(docId, result);
                }
              },
              onStockIn: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockInScreen(itemData: itemData),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  final addedQty = result['quantity'] as int;
                  AppState.incrementStockIn(addedQty);
                  final newQty = (itemData['quantity'] ?? 0) + addedQty;
                  await Database.userDoc.collection('items').doc(docId).update({
                    'quantity': newQty,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  AppState.addHistory('stock_in', itemName, addedQty);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully stocked in $addedQty units of "$itemName"')),
                  );
                }
              },
              onStockOut: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockOutScreen(itemData: itemData),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  final deductedQty = result['quantity'] as int;
                  AppState.incrementStockOut(deductedQty);
                  final newQty = (itemData['quantity'] ?? 0) - deductedQty;
                  await Database.userDoc.collection('items').doc(docId).update({
                    'quantity': newQty,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  AppState.addHistory('stock_out', itemName, deductedQty);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully stocked out $deductedQty units of "$itemName"')),
                  );
                }
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<int>(
                        valueListenable: AppState.lowStockThreshold,
                        builder: (context, threshold, _) {
                          final qty = itemData['quantity'] as int? ?? 0;
                          final sku = itemData['sku'] as String? ?? 'N/A';
                          final isLow = qty <= threshold;
                          return Text(
                            'SKU: $sku • Stock: $qty',
                            style: TextStyle(
                              color: isLow ? Colors.redAccent : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 22),
                  onPressed: () {
                    setState(() {
                      _editingItemId = docId;
                      _editItemController.text = itemName;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  onPressed: () {
                    showItemDeleteConfirmationModal(
                      context,
                      itemName: itemName,
                      onConfirm: () async {
                        await Database.userDoc.collection('items').doc(docId).delete();
                        AppState.addHistory('delete_item', itemName, null);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$itemName" deleted')),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}