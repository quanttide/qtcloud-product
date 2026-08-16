import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/product_models.dart';

/// 种子数据路径：qtcloud-product/assets/data/
///
/// 组织结构（每个产品一个 JSON，便于单独修改）：
/// - `manifest.json` — 产品清单（CLI 增删产品时更新）
/// - `products/<id>.json` — 每个产品一个文件，文件名为唯一命名（qtcloud-devops 等）
///
/// 说明：`src/studio/assets` 是指向仓库根 `assets/` 的符号链接（git 可跟踪），
/// 因此包内资产路径即仓库根的数据文件。
///
/// 约定（见仓库根 AGENTS.md）：
/// - **CLI 负责加工种子数据**：生成、校验、更新 `assets/data/` 下的数据文件
/// - **Studio 只负责渲染**：加载并渲染种子数据，不内嵌数据、不修改数据
const String seedManifestPath = 'assets/data/manifest.json';

/// 加载种子产品数据（按 manifest 清单逐个加载产品文件）
Future<List<Product>> loadSeedProducts() async {
  final manifestRaw = await rootBundle.loadString(seedManifestPath);
  final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
  final ids = [
    for (final id in manifest['products'] as List<dynamic>? ?? const [])
      id as String,
  ];

  final products = <Product>[];
  for (final id in ids) {
    final raw = await rootBundle.loadString('assets/data/products/$id.json');
    products.add(Product.fromJson(jsonDecode(raw) as Map<String, dynamic>));
  }
  return products;
}
