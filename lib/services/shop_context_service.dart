import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopModel {
  const ShopModel({
    required this.id,
    required this.name,
    required this.branch,
    required this.address,
    required this.phone,
    required this.gstin,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String branch;
  final String address;
  final String phone;
  final String gstin;
  final bool isPrimary;

  String get displayName => '$name ($branch)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'branch': branch,
        'address': address,
        'phone': phone,
        'gstin': gstin,
        'isPrimary': isPrimary,
      };

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Raj Jewellery').toString(),
        branch: (json['branch'] ?? 'Main Branch').toString(),
        address: (json['address'] ?? 'Patna, Bihar').toString(),
        phone: (json['phone'] ?? '+919876543210').toString(),
        gstin: (json['gstin'] ?? '10AAAAA0000A1Z5').toString(),
        isPrimary: json['isPrimary'] == true,
      );
}

class ShopContextService extends ChangeNotifier {
  ShopContextService._internal();
  static final ShopContextService instance = ShopContextService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  List<ShopModel> _shops = [];
  ShopModel? _currentShop;

  List<ShopModel> get shops => List.unmodifiable(_shops);
  ShopModel? get currentShop => _currentShop;
  String get selectedShopId => _currentShop?.id ?? 'shop_patna';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_multi_shops_list');

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonStr);
        _shops = decoded.map((s) => ShopModel.fromJson(Map<String, dynamic>.from(s))).toList();
      } catch (_) {
        _shops = _defaultShops();
      }
    } else {
      _shops = _defaultShops();
      await _saveShopsLocally();
    }

    final selectedId = await _storage.read(key: 'selected_shop_id');
    if (selectedId != null && selectedId.isNotEmpty) {
      final match = _shops.firstWhere(
        (s) => s.id == selectedId,
        orElse: () => _shops.first,
      );
      _currentShop = match;
    } else {
      _currentShop = _shops.first;
      await _storage.write(key: 'selected_shop_id', value: _currentShop!.id);
      await _storage.write(key: 'shop_name', value: _currentShop!.displayName);
    }

    notifyListeners();
  }

  List<ShopModel> _defaultShops() {
    return const [
      ShopModel(
        id: 'shop_patna',
        name: 'Raj Jewellery',
        branch: 'Patna Main Branch',
        address: 'Boring Road, Patna, Bihar - 800001',
        phone: '+91 98765 43210',
        gstin: '10AAAAA0000A1Z5',
        isPrimary: true,
      ),
      ShopModel(
        id: 'shop_gaya',
        name: 'Raj Jewellery',
        branch: 'Gaya Branch',
        address: 'GB Road, Gaya, Bihar - 823001',
        phone: '+91 91234 56789',
        gstin: '10AAAAA0000A1Z6',
        isPrimary: false,
      ),
    ];
  }

  Future<void> _saveShopsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_shops.map((s) => s.toJson()).toList());
    await prefs.setString('user_multi_shops_list', jsonStr);
  }

  Future<bool> switchShop(String shopId) async {
    final match = _shops.firstWhere((s) => s.id == shopId, orElse: () => _shops.first);
    _currentShop = match;

    await _storage.write(key: 'selected_shop_id', value: match.id);
    await _storage.write(key: 'shop_name', value: match.displayName);
    await _storage.write(key: 'shop_address', value: match.address);

    notifyListeners();
    return true;
  }

  Future<bool> addNewShop(ShopModel shop) async {
    _shops.add(shop);
    await _saveShopsLocally();
    await switchShop(shop.id);
    return true;
  }
}
