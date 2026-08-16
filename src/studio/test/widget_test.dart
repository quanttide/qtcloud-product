import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/data/seed_loader.dart';
import 'package:studio/main.dart';
import 'package:studio/models/product_models.dart';

void main() {
  late List<Product> products;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    products = await loadSeedProducts();
  });

  test('种子数据包含三个实验产品且各有故事地图', () {
    expect(products.length, 3);
    expect([for (final p in products) p.id],
        ['qtcloud-devops', 'qtcloud-product', 'qtcloud-code']);
    for (final product in products) {
      expect(product.storyMap.activities, isNotEmpty);
      expect(product.totalStories, greaterThan(0));
    }
  });

  testWidgets('应用打开：产品切换器 + 产品空间导航 + 需求看板矩阵', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    // 顶部产品切换器（默认第一个产品 qtcloud-devops）
    expect(find.text('量潮产品云'), findsOneWidget);
    expect(find.byKey(const Key('product-switcher')), findsOneWidget);

    // 产品空间侧边导航：需求 / 规格
    expect(find.byKey(const Key('nav-requirements')), findsOneWidget);
    expect(find.byKey(const Key('nav-specification')), findsOneWidget);

    // 需求看板：活动层（跨列合并）与任务层
    expect(find.text('📋 计划与状态'), findsOneWidget);
    expect(find.text('🚀 正式发布'), findsOneWidget);
    expect(find.text('了解当前状态'), findsOneWidget);

    // Release 行（MVP 版本 / 未来迭代）
    expect(find.byKey(const Key('release-toggle-MVP 版本')), findsOneWidget);
    expect(find.byKey(const Key('release-toggle-未来迭代')), findsOneWidget);
  });

  testWidgets('产品切换器切换产品（每个产品一个空间）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('product-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-qtcloud-product')));
    await tester.pumpAndSettle();

    expect(find.text('管理用户故事'), findsOneWidget);
    expect(find.text('制定版本计划'), findsOneWidget);
    expect(find.text('管理产品组合'), findsOneWidget);
  });

  testWidgets('产品空间内切换模块：规格（事件风暴）占位', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-specification')));
    await tester.pumpAndSettle();
    expect(find.text('规格（事件风暴）'), findsOneWidget);
    expect(find.text('📋 计划与状态'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-requirements')));
    await tester.pumpAndSettle();
    expect(find.text('📋 计划与状态'), findsOneWidget);
  });

  testWidgets('Release 行可折叠与展开', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    expect(find.text('查看迭代计划与待办'), findsOneWidget);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('查看迭代计划与待办'), findsNothing);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('查看迭代计划与待办'), findsOneWidget);
  });
}
