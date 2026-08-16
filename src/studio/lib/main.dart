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

/// 产品云主界面：左侧导航栏 + 内容区
///
/// 内容区两种形态：产品组合（卡片网格）或所选产品的故事地图画布。
class ProductCloudPage extends StatefulWidget {
  const ProductCloudPage({super.key});

  @override
  State<ProductCloudPage> createState() => _ProductCloudPageState();
}

class _ProductCloudPageState extends State<ProductCloudPage> {
  /// 当前选中的产品；null 表示显示产品组合
  Product? _selectedProduct;

  void _openProduct(Product product) {
    setState(() => _selectedProduct = product);
  }

  void _showPortfolio() {
    setState(() => _selectedProduct = null);
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
            onSelectPortfolio: _showPortfolio,
          ),
          Expanded(
            child: _selectedProduct == null
                ? _PortfolioView(onOpenProduct: _openProduct)
                : _ProductCanvasView(
                    product: _selectedProduct!,
                    onBack: _showPortfolio,
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
  final Product? selectedProduct;
  final ValueChanged<Product> onSelectProduct;
  final VoidCallback onSelectPortfolio;

  const _SideNav({
    required this.selectedProduct,
    required this.onSelectProduct,
    required this.onSelectPortfolio,
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
          // 导航项：产品组合
          _NavItem(
            key: const Key('nav-portfolio'),
            icon: Icons.dashboard_outlined,
            label: '产品组合',
            selected: selectedProduct == null,
            onTap: onSelectPortfolio,
          ),
          // 分组标题：产品
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
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
          for (final product in seedPortfolio)
            _NavItem(
              key: Key('nav-${product.id}'),
              icon: _iconFor(product.id),
              label: product.name,
              selected: selectedProduct?.id == product.id,
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

// ============ 产品组合视图（卡片网格） ============

class _PortfolioView extends StatelessWidget {
  final ValueChanged<Product> onOpenProduct;

  const _PortfolioView({required this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            '产品组合',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF37474F),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            '第一批实验对象：集中管理和可视化所有产品，支撑产品决策',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: seedPortfolio.length,
            itemBuilder: (context, index) {
              final product = seedPortfolio[index];
              return _ProductCard(
                key: Key('product-card-${product.id}'),
                product: product,
                onTap: () => onOpenProduct(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 产品卡片：名称、定位、设计思路与故事规模概览
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 名称 + MVP 占比徽章
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${product.mvpStories}/${product.totalStories} MVP',
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                product.tagline,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  '设计思路：${product.designIdea}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.storyMap.activities.length} 个活动 · '
                      '${product.totalStories} 个故事',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                  Text(
                    '查看地图 →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ 产品故事地图视图（嵌入内容区） ============

class _ProductCanvasView extends StatelessWidget {
  final Product product;
  final VoidCallback onBack;
  final Function(UserStory, String)? onStoryMove;
  final Function(UserStory)? onStoryTap;
  final Function(double)? onMVPLineMove;

  const _ProductCanvasView({
    required this.product,
    required this.onBack,
    this.onStoryMove,
    this.onStoryTap,
    this.onMVPLineMove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 内容区头部：返回 + 标题
        Container(
          color: const Color(0xFF2C3E50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              TextButton.icon(
                key: const Key('back-to-portfolio'),
                onPressed: onBack,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('产品组合', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
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
