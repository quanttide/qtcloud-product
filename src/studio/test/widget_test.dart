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

  testWidgets('产品组合页展示三个实验产品的种子数据', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('qtcloud-devops'), findsOneWidget);
    expect(find.text('qtcloud-product'), findsOneWidget);
    expect(find.text('qtcloud-code'), findsOneWidget);
  });

  testWidgets('点击产品卡片进入该产品的故事地图画布', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('qtcloud-product'));
    await tester.pumpAndSettle();

    // 画布 AppBar 显示产品名
    expect(find.text('qtcloud-product'), findsOneWidget);
    // 画布包含该产品的用户活动泳道
    expect(find.text('管理用户故事'), findsOneWidget);
    expect(find.text('制定版本计划'), findsOneWidget);
    expect(find.text('管理产品组合'), findsOneWidget);
  });

  testWidgets('返回组合页后三个产品仍可见', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('qtcloud-code'));
    await tester.pumpAndSettle();
    expect(find.text('审查代码'), findsOneWidget);

    // 返回组合页
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('qtcloud-devops'), findsOneWidget);
    expect(find.text('qtcloud-code'), findsOneWidget);
  });
}
