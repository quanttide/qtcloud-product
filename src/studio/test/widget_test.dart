import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';
import 'package:studio/models/product_models.dart';
import 'package:studio/models/story_map_models.dart';

/// 组件测试使用内置夹具数据，不依赖 `assets/data/` 种子数据。
/// 种子数据增删产品（manifest）或修改故事内容时，本测试不受影响。
void main() {
  late List<Product> products;

  setUp(() {
    products = _fixtureProducts();
  });

  test('内置夹具包含三个产品且各有故事地图', () {
    expect(products.length, 3);
    expect([for (final p in products) p.id], ['alpha', 'beta', 'gamma']);
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

    // 品牌 + 产品切换器（默认第一个产品 alpha）
    expect(find.text('量潮产品云'), findsOneWidget);
    expect(find.byKey(const Key('product-switcher')), findsOneWidget);

    // 前台展示产品标题，唯一命名（alpha）仅作识别副标题
    expect(find.text('测试产品甲'), findsWidgets);
    expect(find.text('alpha'), findsWidgets);

    // 产品空间侧边导航：需求 / 规格
    expect(find.byKey(const Key('nav-requirements')), findsOneWidget);
    expect(find.byKey(const Key('nav-specification')), findsOneWidget);

    // 需求看板：活动层（跨列合并）与任务层
    expect(find.text('活动甲'), findsOneWidget);
    expect(find.text('活动乙'), findsOneWidget);
    expect(find.text('任务甲一'), findsOneWidget);

    // Release 行（MVP 版本 / 未来迭代）
    expect(find.byKey(const Key('release-toggle-MVP 版本')), findsOneWidget);
    expect(find.byKey(const Key('release-toggle-未来迭代')), findsOneWidget);

    // 双层滚动条容器常显；水平方向多列必然溢出 → 拇指必渲染
    expect(find.byKey(const Key('scrollbar-vertical')), findsOneWidget);
    expect(find.byKey(const Key('scrollbar-horizontal')), findsOneWidget);
    expect(find.byKey(const Key('scrollbar-thumb-horizontal')), findsOneWidget);
  });

  testWidgets('产品切换器切换产品（每个产品一个空间）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('product-switcher')));
    await tester.pumpAndSettle();
    // 菜单项展示标题 + 唯一命名
    expect(find.text('测试产品乙'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('switch-beta')));
    await tester.pumpAndSettle();

    expect(find.text('活动丙'), findsOneWidget);
    expect(find.text('任务丙一'), findsOneWidget);
  });

  testWidgets('产品空间内切换模块：规格（事件风暴）占位', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    await tester.tap(find.byKey(const Key('nav-specification')));
    await tester.pumpAndSettle();
    expect(find.text('规格（事件风暴）'), findsOneWidget);
    expect(find.text('活动甲'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-requirements')));
    await tester.pumpAndSettle();
    expect(find.text('活动甲'), findsOneWidget);
  });

  testWidgets('Release 行可折叠与展开', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(products: products));

    expect(find.text('故事甲一'), findsOneWidget);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('故事甲一'), findsNothing);

    await tester.tap(find.byKey(const Key('release-toggle-MVP 版本')));
    await tester.pumpAndSettle();
    expect(find.text('故事甲一'), findsOneWidget);
  });
}

/// 夹具产品（不依赖种子数据）
List<Product> _fixtureProducts() {
  return [
    Product(
      id: 'alpha',
      name: 'alpha',
      title: '测试产品甲',
      tagline: '组件测试夹具：不依赖种子数据',
      designIdea: '夹具设计思路',
      storyMap: StoryMap(
        id: 'map-alpha',
        name: 'alpha',
        mvpLinePosition: 0.4,
        activities: [
          UserActivity(id: 'act-1', title: '活动甲', order: 0, tasks: [
            UserTask(
              id: 'task-1-1',
              title: '任务甲一',
              activityId: 'act-1',
              order: 0,
              stories: [
                UserStory(
                  id: 'story-1-1',
                  title: '故事甲一',
                  taskId: 'task-1-1',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.done,
                ),
                UserStory(
                  id: 'story-1-2',
                  title: '故事甲二',
                  taskId: 'task-1-1',
                  phase: ReleasePhase.future,
                  status: StoryStatus.todo,
                ),
              ],
            ),
            UserTask(
              id: 'task-1-2',
              title: '任务甲二',
              activityId: 'act-1',
              order: 1,
              stories: [
                UserStory(
                  id: 'story-1-3',
                  title: '故事甲三',
                  taskId: 'task-1-2',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.inProgress,
                ),
              ],
            ),
          ]),
          UserActivity(id: 'act-2', title: '活动乙', order: 1, tasks: [
            UserTask(
              id: 'task-2-1',
              title: '任务乙一',
              activityId: 'act-2',
              order: 0,
              stories: [
                UserStory(
                  id: 'story-2-1',
                  title: '故事乙一',
                  taskId: 'task-2-1',
                  phase: ReleasePhase.mvp,
                  status: StoryStatus.todo,
                ),
              ],
            ),
          ]),
        ],
      ),
    ),
    Product(
      id: 'beta',
      name: 'beta',
      title: '测试产品乙',
      tagline: '乙定位',
      designIdea: '',
      storyMap: StoryMap(id: 'map-beta', name: 'beta', activities: [
        UserActivity(id: 'act-3', title: '活动丙', order: 0, tasks: [
          UserTask(
            id: 'task-3-1',
            title: '任务丙一',
            activityId: 'act-3',
            order: 0,
            stories: [
              UserStory(
                id: 'story-3-1',
                title: '故事丙一',
                taskId: 'task-3-1',
                phase: ReleasePhase.mvp,
                status: StoryStatus.done,
              ),
            ],
          ),
        ]),
      ]),
    ),
    Product(
      id: 'gamma',
      name: 'gamma',
      title: '测试产品丙',
      tagline: '丙定位',
      designIdea: '',
      storyMap: StoryMap(id: 'map-gamma', name: 'gamma', activities: [
        UserActivity(id: 'act-4', title: '活动丁', order: 0, tasks: [
          UserTask(
            id: 'task-4-1',
            title: '任务丁一',
            activityId: 'act-4',
            order: 0,
            stories: [
              UserStory(
                id: 'story-4-1',
                title: '故事丁一',
                taskId: 'task-4-1',
                phase: ReleasePhase.future,
                status: StoryStatus.todo,
              ),
            ],
          ),
        ]),
      ]),
    ),
  ];
}
