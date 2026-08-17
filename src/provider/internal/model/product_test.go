package model

import (
	"strings"
	"testing"
)

// validProduct 与种子数据同构的最小合法产品文档（对齐 Studio Product.fromJson）。
const validProduct = `{
  "id": "qtcloud-demo",
  "name": "qtcloud-demo",
  "title": "量潮演示云",
  "tagline": "演示用产品",
  "designIdea": "以用户故事地图展示产品结构",
  "storyMap": {
    "id": "map-qtcloud-demo",
    "name": "qtcloud-demo",
    "mvpLinePosition": 0.5,
    "activities": [
      {
        "id": "lifecycle",
        "title": "阶段/生命周期管理",
        "order": 0,
        "color": "#FF5722",
        "tasks": [
          {
            "id": "lifecycle-task-1",
            "title": "plan 计划",
            "activityId": "lifecycle",
            "order": 0,
            "stories": [
              {
                "id": "lifecycle-plan-1",
                "title": "查看迭代计划与待办",
                "taskId": "lifecycle-task-1",
                "phase": "mvp",
                "status": "done",
                "description": "ROADMAP / BUGS / TODO"
              },
              {
                "id": "lifecycle-plan-2",
                "title": "从审计自动生成规划",
                "taskId": "lifecycle-task-1",
                "phase": "future",
                "status": "todo"
              }
            ]
          }
        ]
      }
    ]
  }
}`

func TestParseProductValid(t *testing.T) {
	p, err := ParseProduct([]byte(validProduct))
	if err != nil {
		t.Fatalf("解析合法产品失败: %v", err)
	}
	if p.ID != "qtcloud-demo" || p.Name != "qtcloud-demo" {
		t.Errorf("id/name 解析错误: %+v", p)
	}
	if p.Title != "量潮演示云" {
		t.Errorf("title 解析错误: %q", p.Title)
	}
	if p.StoryMap.MVPLinePosition != 0.5 {
		t.Errorf("mvpLinePosition 解析错误: %v", p.StoryMap.MVPLinePosition)
	}
	if len(p.StoryMap.Activities) != 1 || len(p.StoryMap.Activities[0].Tasks) != 1 {
		t.Fatalf("activities/tasks 解析错误: %+v", p.StoryMap)
	}
	stories := p.StoryMap.Activities[0].Tasks[0].Stories
	if len(stories) != 2 {
		t.Fatalf("stories 解析错误: %+v", stories)
	}
	if stories[0].Phase != PhaseMVP || stories[0].Status != StatusDone {
		t.Errorf("phase/status 解析错误: %+v", stories[0])
	}
	if stories[1].Phase != PhaseFuture || stories[1].Status != StatusTodo {
		t.Errorf("phase/status 解析错误: %+v", stories[1])
	}
	if stories[1].Description != "" {
		t.Errorf("description 应为空: %q", stories[1].Description)
	}
}

func TestParseProductRejects(t *testing.T) {
	cases := []struct {
		name string
		mut  func(*string)
		want string
	}{
		{
			name: "空数据",
			mut:  func(s *string) { *s = "" },
			want: "为空",
		},
		{
			name: "非法 JSON",
			mut:  func(s *string) { *s = "{not json" },
			want: "非法 JSON",
		},
		{
			name: "name 大写",
			mut:  func(s *string) { *s = strings.Replace(*s, `"name": "qtcloud-demo"`, `"name": "Qtcloud-demo"`, 1) },
			want: "name 必须",
		},
		{
			name: "id 与 name 不一致",
			mut:  func(s *string) { *s = strings.Replace(*s, `"id": "qtcloud-demo"`, `"id": "qtcloud-other"`, 1) },
			want: "id 必须与 name 一致",
		},
		{
			name: "title 为空",
			mut:  func(s *string) { *s = strings.Replace(*s, `"title": "量潮演示云",`, `"title": "",`, 1) },
			want: "title 不能为空",
		},
		{
			name: "mvpLinePosition 越界",
			mut:  func(s *string) { *s = strings.Replace(*s, `"mvpLinePosition": 0.5`, `"mvpLinePosition": 1.5`, 1) },
			want: "mvpLinePosition 必须在 0.0-1.0",
		},
		{
			name: "phase 非法枚举",
			mut:  func(s *string) { *s = strings.Replace(*s, `"phase": "mvp"`, `"phase": "v2"`, 1) },
			want: "phase=",
		},
		{
			name: "status 非法枚举",
			mut:  func(s *string) { *s = strings.Replace(*s, `"status": "done"`, `"status": "blocked"`, 1) },
			want: "status=",
		},
		{
			name: "taskId 与所属任务不一致",
			mut: func(s *string) {
				*s = strings.Replace(*s, `"taskId": "lifecycle-task-1"`, `"taskId": "lifecycle-task-9"`, 1)
			},
			want: "taskId=",
		},
		{
			name: "activityId 与所属活动不一致",
			mut:  func(s *string) { *s = strings.Replace(*s, `"activityId": "lifecycle"`, `"activityId": "other"`, 1) },
			want: "activityId=",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			src := validProduct
			tc.mut(&src)
			_, err := ParseProduct([]byte(src))
			if err == nil {
				t.Fatal("期望校验失败，实际通过")
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Errorf("错误信息 %q 不含 %q", err.Error(), tc.want)
			}
		})
	}
}

func TestParseProductSizeLimit(t *testing.T) {
	// 超过 MaxProductSize 的文档必须被拒绝
	big := `{"id": "qtcloud-demo", "name": "qtcloud-demo", "title": "x", "tagline": "", "designIdea": "", "storyMap": {"id": "m", "name": "m", "mvpLinePosition": 0.3, "activities": []}}`
	pad := strings.Repeat(" ", MaxProductSize+1)
	_, err := ParseProduct([]byte(big + pad))
	if err == nil {
		t.Fatal("期望大小超限被拒绝，实际通过")
	}
}

func TestManifestValidate(t *testing.T) {
	if err := (&Manifest{Products: []string{"qtcloud-devops", "qtcloud-product"}}).Validate(); err != nil {
		t.Errorf("合法清单校验失败: %v", err)
	}
	if err := (&Manifest{Products: []string{"Qtcloud-devops"}}).Validate(); err == nil {
		t.Error("非法产品名应校验失败")
	}
}
