import 'package:flutter/material.dart';

import 'data/seed_loader.dart';
import 'models/product_models.dart';
import 'screens/product_cloud_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 种子数据由 CLI 加工于 assets/data/，Studio 仅加载渲染
  final products = await loadSeedProducts();
  runApp(MyApp(products: products));
}

class MyApp extends StatelessWidget {
  final List<Product> products;

  const MyApp({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮产品云',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ProductCloudScreen(products: products),
    );
  }
}
