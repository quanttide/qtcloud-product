import 'package:flutter/material.dart';
import 'data/seed_data.dart';
import 'models/product_models.dart';
import 'models/story_map_models.dart';
import 'widgets/story_map_canvas.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮产品云',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductCloudPage(),
    );
  }
}

/// 产品云主界面：左侧导航栏 + 所选产品的故事地图画布
class ProductCloudPage extends StatefulWidget {
  const ProductCloudPage({super.key});

  @override
  State<ProductCloudPage> createState() => _ProductCloudPageState();
}

class _ProductCloudPageState extends State<ProductCloudPage> {
  late Product _selectedProduct;

  @override
  void initState() {
    super.initState();
    _selectedProduct = seedProducts.first;
  }

  void _openProduct(Product product) {
    setState(() => _selectedProduct = product);
  }

  void _debugStoryMove(UserStory story, String newTaskId) {
    debugPrint('故事移动: ${story.title} -> 任务 $newTaskId');
  }

  void _debugStoryTap(UserStory story) {
    debugPrint('点击故事: ${story.title}');
  }

  void _debugMVPLineMove(double position) {
    debugPrint(
      'Release Line 移动到: ${(position * 100).toStringAsFixed(1)}%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideNav(
            selectedProduct: _selectedProduct,
            onSelectProduct: _openProduct,
          ),
          Expanded(
            child: _ProductCanvasView(
              product: _selectedProduct,
              onStoryMove: _debugStoryMove,
              onStoryTap: _debugStoryTap,
              onMVPLineMove: _debugMVPLineMove,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 左侧导航栏 ============

class _SideNav extends StatelessWidget {
  final Product selectedProduct;
  final ValueChanged<Product> onSelectProduct;

  const _SideNav({
    required this.selectedProduct,
    required this.onSelectProduct,
  });

  IconData _iconFor(String id) {
    switch (id) {
      case 'qtcloud-devops':
        return Icons.rocket_launch_outlined;
      case 'qtcloud-code':
        return Icons.code;
      default:
        return Icons.insights_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF2C3E50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 品牌区
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '量潮产品云',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'QtCloud Product',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          // 分组标题：产品
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              '产品',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 导航项：三个实验产品
          for (final product in seedProducts)
            _NavItem(
              key: Key('nav-${product.id}'),
              icon: _iconFor(product.id),
              label: product.name,
              selected: selectedProduct.id == product.id,
              onTap: () => onSelectProduct(product),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'v0.0.1 · 实验原型',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// 侧边导航单项
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = selected ? const Color(0xFF2C3E50) : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 16, color: fgColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fgColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ 产品故事地图视图（嵌入内容区） ============

class _ProductCanvasView extends StatelessWidget {
  final Product product;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;
  final Function(double)? onMVPLineMove;

  const _ProductCanvasView({
    required this.product,
    this.onStoryMove,
    this.onStoryTap,
    this.onMVPLineMove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 内容区头部：标题
        Container(
          color: const Color(0xFF2C3E50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '量潮产品云 · ${product.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                product.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StoryMapCanvasView(
            mapData: product.storyMap,
            onStoryMove: onStoryMove,
            onStoryTap: onStoryTap,
            onMVPLineMove: onMVPLineMove,
          ),
        ),
      ],
    );
  }
}
