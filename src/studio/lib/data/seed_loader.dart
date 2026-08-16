import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/product_models.dart';

/// 种子数据路径：qtcloud-product/assets/data/products.json
///
/// 说明：`src/studio/assets` 是到仓库根 `assets/` 的符号链接（git 可跟踪），
/// 因此包内资产路径 `assets/data/products.json` 即仓库根的数据文件。
///
/// 约定（见仓库根 AGENTS.md）：
/// - **CLI 负责加工种子数据**：生成、校验、更新 `assets/data/products.json`
/// - **Studio 只负责渲染**：加载并渲染种子数据，不内嵌数据、不修改数据
const String seedDataPath = 'assets/data/products.json';

/// 加载种子产品数据（产品 → 用户故事地图）
Future<List<Product>> loadSeedProducts() async {
  final raw = await rootBundle.loadString(seedDataPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = decoded['products'] as List<dynamic>;
  return [
    for (final item in list) Product.fromJson(item as Map<String, dynamic>),
  ];
}
