import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/data/seed_data.dart';
import 'package:studio/main.dart';
import 'package:studio/widgets/story_map_canvas.dart';

void main() {
  test('种子数据包含三个实验产品且各有故事地图', () {
    expect(seedProducts.length, 3);
    for (final product in seedProducts) {
      expect(product.storyMap.activities, isNotEmpty);
      expect(product.totalStories, greaterThan(0));
    }
  });

  testWidgets('应用打开：产品切换器 + 产品空间导航 + 需求看板', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    // 顶部产品切换器（默认第一个产品 qtcloud-devops）
    expect(find.text('量潮产品云'), findsOneWidget);
    expect(find.byKey(const Key('product-switcher')), findsOneWidget);
    expect(find.text('qtcloud-devops'), findsWidgets);

    // 产品空间侧边导航：需求 / 规格
    expect(find.byKey(const Key('nav-requirements')), findsOneWidget);
    expect(find.byKey(const Key('nav-specification')), findsOneWidget);

    // 需求模块：devops 四阶段用户故事地图看板
    expect(find.text('📋 计划与状态'), findsOneWidget);
    expect(find.text('💻 开发编码'), findsOneWidget);
    expect(find.text('✅ 测试与验证'), findsOneWidget);
    expect(find.text('🚀 正式发布'), findsOneWidget);
  });

  testWidgets('产品切换器切换产品（每个产品一个空间）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    // 打开切换器，选择 qtcloud-product
    await tester.tap(find.byKey(const Key('product-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-qtcloud-product')));
    await tester.pumpAndSettle();

    // 空间切换：侧边导航标识与需求看板内容都变为该产品
    expect(find.text('qtcloud-product'), findsWidgets);
    expect(find.text('管理用户故事'), findsOneWidget);
    expect(find.text('制定版本计划'), findsOneWidget);
    expect(find.text('管理产品组合'), findsOneWidget);
  });

  testWidgets('产品空间内切换模块：规格（事件风暴）占位', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    // 切到规格模块
    await tester.tap(find.byKey(const Key('nav-specification')));
    await tester.pumpAndSettle();
    expect(find.text('规格（事件风暴）'), findsOneWidget);
    expect(find.text('📋 计划与状态'), findsNothing);

    // 切回需求模块
    await tester.tap(find.byKey(const Key('nav-requirements')));
    await tester.pumpAndSettle();
    expect(find.text('📋 计划与状态'), findsOneWidget);
  });

  testWidgets('发布线拖拽精确跟随指针（多事件同帧不抖动）', (WidgetTester tester) async {
    final positions = <double>[];
    final product = seedProducts[1]; // qtcloud-product，初始 0.4
    await tester.pumpWidget(
      MaterialApp(
        home: StoryMapCanvasPage(
          mapData: product.storyMap,
          onMVPLineMove: positions.add,
        ),
      ),
    );

    final canvasHeight = tester.getSize(find.byType(StoryMapCanvasView)).height;

    // 模拟快速拖拽：连续 8 次 move 事件、中间不 pump 帧
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('mvp-line-drag'))),
    );
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 10));
    }
    await gesture.up();
    await tester.pump();

    expect(positions, isNotEmpty);
    // 线应精确移动 80px / 画布高度，而不是只跟了最后一段增量
    expect(
      positions.last,
      closeTo(0.4 + 80 / canvasHeight, 0.01),
    );
  });
}
