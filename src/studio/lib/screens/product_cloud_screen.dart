import 'package:flutter/material.dart';

import '../models/product_models.dart';
import 'requirement_screen.dart';
import 'specification_screen.dart';

/// 产品空间内的模块
enum ProductModule {
  /// 需求：用户故事地图看板（二维矩阵）
  requirements,

  /// 规格：事件风暴（规划中）
  specification,
}

/// 产品云主界面（参考项目管理软件）：
/// 顶部产品切换器（每个产品 = 一个项目空间）+ 产品空间侧边导航 + 模块内容区
class ProductCloudScreen extends StatefulWidget {
  final List<Product> products;

  const ProductCloudScreen({super.key, required this.products});

  @override
  State<ProductCloudScreen> createState() => _ProductCloudScreenState();
}

class _ProductCloudScreenState extends State<ProductCloudScreen> {
  late Product _selectedProduct;
  ProductModule _selectedModule = ProductModule.requirements;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.products.first;
  }

  void _openProduct(Product product) {
    setState(() => _selectedProduct = product);
  }

  void _openModule(ProductModule module) {
    setState(() => _selectedModule = module);
  }

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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部：品牌 + 产品切换器（每个产品 = 一个项目空间）
          Container(
            color: const Color(0xFF2C3E50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '量潮产品云',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white24,
                ),
                const SizedBox(width: 12),
                // 产品切换器（Switcher）
                PopupMenuButton<Product>(
                  key: const Key('product-switcher'),
                  tooltip: '切换产品',
                  onSelected: _openProduct,
                  itemBuilder: (context) => [
                    for (final product in widget.products)
                      PopupMenuItem<Product>(
                        key: Key('switch-${product.id}'),
                        value: product,
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(product.id),
                              size: 16,
                              color: const Color(0xFF2C3E50),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(_selectedProduct.id),
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedProduct.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    _selectedProduct.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 产品空间：侧边导航 + 模块内容
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SpaceNav(
                  product: _selectedProduct,
                  selectedModule: _selectedModule,
                  onSelectModule: _openModule,
                ),
                Expanded(
                  child: switch (_selectedModule) {
                    ProductModule.requirements => RequirementScreen(
                        stories: _selectedProduct.stories,
                      ),
                    ProductModule.specification => SpecificationScreen(
                        eventStorm: _selectedProduct.eventStorm,
                      ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 产品空间侧边导航 ============

class _SpaceNav extends StatelessWidget {
  final Product product;
  final ProductModule selectedModule;
  final ValueChanged<ProductModule> onSelectModule;

  const _SpaceNav({
    required this.product,
    required this.selectedModule,
    required this.onSelectModule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF2C3E50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 空间标识：当前产品
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '产品空间',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // 模块导航
          _NavItem(
            key: const Key('nav-requirements'),
            icon: Icons.view_kanban_outlined,
            label: '需求',
            selected: selectedModule == ProductModule.requirements,
            onTap: () => onSelectModule(ProductModule.requirements),
          ),
          _NavItem(
            key: const Key('nav-specification'),
            icon: Icons.account_tree_outlined,
            label: '规格',
            selected: selectedModule == ProductModule.specification,
            onTap: () => onSelectModule(ProductModule.specification),
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
