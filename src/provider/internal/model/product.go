// Package model 定义产品云数据模型（与 Studio 渲染需求一一对齐）。
//
// 数据契约（src/studio/lib/models/*.dart 为唯一事实源）：
//   - Product        ← product.dart：id/name/title/tagline/designIdea/storyMap
//   - StoryMap       ← story_map_models.dart：id/name/mvpLinePosition/activities
//   - UserActivity   ← story_map_models.dart：id/title/order/color?/tasks
//   - UserTask       ← story_map_models.dart：id/title/activityId/order/stories
//   - UserStory      ← story_map_models.dart：id/title/taskId/phase/status/description?
//
// 本包负责解析与校验 provider 存储的数据文件（与 CLI 加工的 assets/data/ 同构），
// 服务端在响应前做整树校验：结构错乱的数据会在源头上被拒绝，
// 而不是等到 Studio 渲染时才暴露（Studio 的 fromJson 对缺失字段较宽容）。
package model

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
)

// 数据规模上限（防御异常数据，正常种子数据远小于此）。
const (
	MaxProductSize     = 1 << 20 // 单个产品文件 ≤ 1 MB
	MaxNameLength      = 64      // id/name 长度上限
	MaxTitleLength     = 256     // title/tagline 长度上限
	MaxDesignIdeaSize  = 8 << 10 // designIdea（设计思路）长度上限
	MaxActivityCount   = 64      // 活动数上限
	MaxTaskCount       = 512     // 任务数上限
	MaxStoryCount      = 4096    // 故事数上限
	MaxDescriptionSize = 4096    // story.description 长度上限
)

var (
	// slugRe 产品唯一命名（URL / 识别场景）：小写字母开头，仅小写字母数字与连字符。
	slugRe   = regexp.MustCompile(`^[a-z][a-z0-9-]*$`)
	idRe     = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]*$`)
	phaseRe  = regexp.MustCompile(`^(mvp|future)$`)
	statusRe = regexp.MustCompile(`^(todo|inProgress|done)$`)
)

// ReleasePhase 发布阶段（对齐 Dart enum ReleasePhase：mvp / future）。
type ReleasePhase string

// ReleasePhase 取值。
const (
	PhaseMVP    ReleasePhase = "mvp"
	PhaseFuture ReleasePhase = "future"
)

// StoryStatus 故事状态（对齐 Dart enum StoryStatus：todo / inProgress / done）。
type StoryStatus string

// StoryStatus 取值。
const (
	StatusTodo       StoryStatus = "todo"
	StatusInProgress StoryStatus = "inProgress"
	StatusDone       StoryStatus = "done"
)

// Product 产品（组合层 → 产品 → 用户故事地图的第二层）。
type Product struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	Title      string   `json:"title"`
	Tagline    string   `json:"tagline"`
	DesignIdea string   `json:"designIdea"`
	StoryMap   StoryMap `json:"storyMap"`
}

// StoryMap 用户故事地图根对象。
type StoryMap struct {
	ID              string         `json:"id"`
	Name            string         `json:"name"`
	MVPLinePosition float64        `json:"mvpLinePosition"`
	Activities      []UserActivity `json:"activities"`
}

// UserActivity 第一层：用户活动（地图的"脊柱"）。
type UserActivity struct {
	ID    string     `json:"id"`
	Title string     `json:"title"`
	Order int        `json:"order"`
	Color string     `json:"color,omitempty"`
	Tasks []UserTask `json:"tasks"`
}

// UserTask 第二层：用户任务（地图的"行走的骨骼"）。
type UserTask struct {
	ID         string      `json:"id"`
	Title      string      `json:"title"`
	ActivityID string      `json:"activityId"`
	Order      int         `json:"order"`
	Stories    []UserStory `json:"stories"`
}

// UserStory 第三层：用户故事（具体功能点或技术细节）。
type UserStory struct {
	ID          string       `json:"id"`
	Title       string       `json:"title"`
	TaskID      string       `json:"taskId"`
	Phase       ReleasePhase `json:"phase"`
	Status      StoryStatus  `json:"status"`
	Description string       `json:"description,omitempty"`
}

// ParseProduct 解析并整树校验产品文档（含大小上限）。
func ParseProduct(body []byte) (*Product, error) {
	if len(body) == 0 {
		return nil, errors.New("产品数据为空")
	}
	if len(body) > MaxProductSize {
		return nil, fmt.Errorf("产品数据大小超过上限 %d 字节", MaxProductSize)
	}
	var p Product
	if err := json.Unmarshal(body, &p); err != nil {
		return nil, fmt.Errorf("非法 JSON: %w", err)
	}
	if err := p.Validate(); err != nil {
		return nil, err
	}
	return &p, nil
}

// Validate 校验产品文档整树结构。
func (p *Product) Validate() error {
	if !slugRe.MatchString(p.Name) {
		return fmt.Errorf("name 必须是小写字母开头的短横线命名（如 qtcloud-devops）")
	}
	if len(p.Name) > MaxNameLength {
		return fmt.Errorf("name 长度超过 %d", MaxNameLength)
	}
	if p.ID == "" || len(p.ID) > MaxNameLength {
		return fmt.Errorf("id 长度必须在 1-%d 之间", MaxNameLength)
	}
	// Studio 以 name 为 URL / 识别场景，id 与 name 保持一致（CLI 加工约定）
	if p.ID != p.Name {
		return fmt.Errorf("id 必须与 name 一致（当前 id=%q name=%q）", p.ID, p.Name)
	}
	if err := checkLen("title", p.Title, 1, MaxTitleLength); err != nil {
		return err
	}
	if err := checkLen("tagline", p.Tagline, 0, MaxTitleLength); err != nil {
		return err
	}
	if err := checkLen("designIdea", p.DesignIdea, 0, MaxDesignIdeaSize); err != nil {
		return err
	}
	return p.StoryMap.Validate()
}

// Validate 校验故事地图。
func (s *StoryMap) Validate() error {
	if s.ID == "" || len(s.ID) > MaxNameLength {
		return fmt.Errorf("storyMap.id 长度必须在 1-%d 之间", MaxNameLength)
	}
	if s.MVPLinePosition < 0 || s.MVPLinePosition > 1 {
		return fmt.Errorf("storyMap.mvpLinePosition 必须在 0.0-1.0 之间（当前 %v）", s.MVPLinePosition)
	}
	if len(s.Activities) > MaxActivityCount {
		return fmt.Errorf("活动数超过上限 %d", MaxActivityCount)
	}
	tasks, stories := 0, 0
	for i := range s.Activities {
		a := &s.Activities[i]
		if !idRe.MatchString(a.ID) {
			return fmt.Errorf("activity.id %q 格式非法", a.ID)
		}
		if err := checkLen("activity.title", a.Title, 1, MaxTitleLength); err != nil {
			return err
		}
		tasks += len(a.Tasks)
		stories += countStories(a.Tasks)
		if tasks > MaxTaskCount {
			return fmt.Errorf("任务数超过上限 %d", MaxTaskCount)
		}
		if stories > MaxStoryCount {
			return fmt.Errorf("故事数超过上限 %d", MaxStoryCount)
		}
		for j := range a.Tasks {
			t := &a.Tasks[j]
			if !idRe.MatchString(t.ID) {
				return fmt.Errorf("task.id %q 格式非法", t.ID)
			}
			// 关系一致性：task.activityId 必须指向所属活动（Studio 渲染按活动分组）
			if t.ActivityID != a.ID {
				return fmt.Errorf("task %q 的 activityId=%q 与所属活动 %q 不一致", t.ID, t.ActivityID, a.ID)
			}
			if err := checkLen("task.title", t.Title, 1, MaxTitleLength); err != nil {
				return err
			}
			for k := range t.Stories {
				st := &t.Stories[k]
				if !idRe.MatchString(st.ID) {
					return fmt.Errorf("story.id %q 格式非法", st.ID)
				}
				// 关系一致性：story.taskId 必须指向所属任务
				if st.TaskID != t.ID {
					return fmt.Errorf("story %q 的 taskId=%q 与所属任务 %q 不一致", st.ID, st.TaskID, t.ID)
				}
				if !phaseRe.MatchString(string(st.Phase)) {
					return fmt.Errorf("story %q 的 phase=%q 非法（必须为 mvp 或 future）", st.ID, st.Phase)
				}
				if !statusRe.MatchString(string(st.Status)) {
					return fmt.Errorf("story %q 的 status=%q 非法（必须为 todo/inProgress/done）", st.ID, st.Status)
				}
				if err := checkLen("story.title", st.Title, 1, MaxTitleLength); err != nil {
					return err
				}
				if len(st.Description) > MaxDescriptionSize {
					return fmt.Errorf("story %q 的 description 超过 %d 字节", st.ID, MaxDescriptionSize)
				}
			}
		}
	}
	return nil
}

// Manifest 产品清单（对齐 assets/data/manifest.json）。
type Manifest struct {
	Products []string `json:"products"`
}

// Validate 校验清单。
func (m *Manifest) Validate() error {
	for _, name := range m.Products {
		if !slugRe.MatchString(name) {
			return fmt.Errorf("清单中产品名 %q 非法（必须是小写字母开头的短横线命名）", name)
		}
	}
	return nil
}

func countStories(tasks []UserTask) int {
	n := 0
	for _, t := range tasks {
		n += len(t.Stories)
	}
	return n
}

func checkLen(field, value string, min, max int) error {
	n := len(strings.TrimSpace(value))
	if n < min {
		return fmt.Errorf("%s 不能为空", field)
	}
	if n > max {
		return fmt.Errorf("%s 长度超过 %d", field, max)
	}
	return nil
}
