import 'package:flutter/material.dart';
import 'data/seed_data.dart';
import 'models/product_models.dart';
import 'widgets/story_map_canvas.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QtCloud Studio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PortfolioPage(),
    );
  }
}

/// 产品组合页：集中展示所有产品及其设计思路
///
/// 组合视图（规划中的核心视图）的当前形态：产品卡片列表。
/// 点击产品进入该产品的用户故事地图画布。
class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryMapCanvasPage(
          mapData: product.storyMap,
          onStoryMove: (story, newTaskId) {
            debugPrint('故事移动: ${story.title} -> 任务 $newTaskId');
          },
          onStoryTap: (story) {
            debugPrint('点击故事: ${story.title}');
          },
          onMVPLineMove: (position) {
            debugPrint(
              'Release Line 移动到: ${(position * 100).toStringAsFixed(1)}%',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QtCloud Studio · 产品组合'),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          for (final product in seedPortfolio)
            _ProductCard(
              product: product,
              onTap: () => _openProduct(context, product),
            ),
        ],
      ),
    );
  }
}

/// 产品卡片：名称、定位、设计思路与故事规模概览
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '${product.mvpStories}/${product.totalStories} MVP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                product.tagline,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '设计思路：${product.designIdea}',
                style: TextStyle(
                  fontSize: 13.0,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${product.storyMap.activities.length} 个用户活动 · '
                '${product.storyMap.activities.expand((a) => a.tasks).length} '
                '个用户任务 · ${product.totalStories} 个用户故事',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
