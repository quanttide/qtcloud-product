import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/data/seed_data.dart';
import 'package:studio/main.dart';

void main() {
  test('种子数据包含三个实验产品且各有故事地图', () {
    expect(seedPortfolio.length, 3);
    for (final product in seedPortfolio) {
      expect(product.storyMap.activities, isNotEmpty);
      expect(product.totalStories, greaterThan(0));
    }
  });

  testWidgets('主界面展示侧边导航与三个产品卡片', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    // 标题与侧边导航
    expect(find.text('量潮产品云'), findsWidgets);
    expect(find.byKey(const Key('nav-portfolio')), findsOneWidget);
    expect(find.byKey(const Key('nav-qtcloud-devops')), findsOneWidget);
    expect(find.byKey(const Key('nav-qtcloud-product')), findsOneWidget);
    expect(find.byKey(const Key('nav-qtcloud-code')), findsOneWidget);

    // 产品卡片网格
    expect(find.byKey(const Key('product-card-qtcloud-devops')), findsOneWidget);
    expect(find.byKey(const Key('product-card-qtcloud-product')), findsOneWidget);
    expect(find.byKey(const Key('product-card-qtcloud-code')), findsOneWidget);
  });

  testWidgets('点击产品进入故事地图画布，可返回产品组合', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    // 通过侧边导航打开产品
    await tester.tap(find.byKey(const Key('nav-qtcloud-product')));
    await tester.pumpAndSettle();

    // 画布标题与用户活动泳道
    expect(find.text('量潮产品云 · qtcloud-product'), findsOneWidget);
    expect(find.text('管理用户故事'), findsOneWidget);
    expect(find.text('制定版本计划'), findsOneWidget);
    expect(find.text('管理产品组合'), findsOneWidget);

    // 返回产品组合
    await tester.tap(find.byKey(const Key('back-to-portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-card-qtcloud-devops')), findsOneWidget);
  });

  testWidgets('点击产品卡片同样能打开故事地图', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byKey(const Key('product-card-qtcloud-code')));
    await tester.pumpAndSettle();

    expect(find.text('量潮产品云 · qtcloud-code'), findsOneWidget);
    expect(find.text('审查代码'), findsOneWidget);
    expect(find.text('执行重构'), findsOneWidget);
  });

  testWidgets('侧边导航打开 devops 四阶段地图', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byKey(const Key('nav-qtcloud-devops')));
    await tester.pumpAndSettle();

    expect(find.text('📋 计划与状态'), findsOneWidget);
    expect(find.text('💻 开发编码'), findsOneWidget);
    expect(find.text('✅ 测试与验证'), findsOneWidget);
    expect(find.text('🚀 正式发布'), findsOneWidget);
  });
}
