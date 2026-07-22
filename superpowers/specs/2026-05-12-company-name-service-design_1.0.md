# 企业名称服务架构设计规格说明

> 版本：v1.0
> 日期：2026-05-12
> 需求来源：doc/企业名称/ 目录下全部原始文档 + 企业名称服务需求分析报告.md

---

## 1. 背景与目标

基于 Dapr 微服务框架，将企业名称服务（company）与位置预置服务（location）拆分为多个职责单一的原子服务，并在其上构建业务编排层，实现：

- 企业名称数据的多来源拉新（批量/用户/业务/公司自主）
- 企业名称搜索、申诉、权力人主张/申诉、信息查询
- 企业位置信息独立预置与查询
- PostgreSQL 事实数据与 Elasticsearch 搜索索引通过 Dapr pub/sub 解耦同步

---

## 2. 分层架构

```
┌─────────────────────────────────────────────────────┐
│                     Business 层（Go）                │
│  eiker-company-service  eiker-company-update         │
│  eiker-location-service eiker-location-update        │
└────────────────┬────────────────────────────────────┘
                 │  Dapr Service Invocation / Pub-Sub
┌────────────────▼────────────────────────────────────┐
│                     Atomic 层                        │
│  Go: eiker-company-db  eiker-company-es              │
│      eiker-location-db                               │
│      eiker-third-api/eiker-third-tianyancha          │
│      eiker-third-api/eiker-third-tencent             │
│      eiker-file-go/eiker-file-excelize               │
│  Python: eiker-ocr/eiker-ocr-paddleocr               │
│          eiker-ocr/eiker-ocr-easyocr                 │
│          eiker-ocr/eiker-ocr-tesseract               │
│  Java: eiker-file-java/eiker-file-apache-poi         │
│  Python: eiker-file-python/eiker-file-openpyxl       │
│          eiker-file-python/eiker-file-pandas         │
└─────────────────────────────────────────────────────┘
```

---

## 3. Business 层模块详述

### 3.1 eiker-company-service（企业名称·数据服务）

- **语言**：Go
- **Dapr app-id**：`eiker-company-service`
- **目录**：`business/business-go/eiker-company-service/`
- **职责**：对外暴露企业名称域的查询类 API，不涉及数据写入

| API 方法 | 说明 | 依赖 atomic |
|---------|------|------------|
| `search-company` | 企业名称搜索（关键词/拼音） | eiker-company-es |
| `query-company-info` | 企业信息查询（按 UUID/信用代码） | eiker-company-es |
| `submit-company-appeal` | 提交企业名称申诉 | eiker-company-db, eiker-ocr-*, eiker-third-tianyancha |
| `claim-power-holder` | 权力人主张 | eiker-company-db, eiker-third-tencent |
| `appeal-power-holder` | 权力人申诉 | eiker-company-db, eiker-ocr-*, eiker-third-tianyancha |

---

### 3.2 eiker-company-update（企业名称·拉新服务）

- **语言**：Go（含 Dapr Workflow 编排）
- **Dapr app-id**：`eiker-company-update`
- **目录**：`business/business-go/eiker-company-update/`
- **职责**：接收 4 种拉新来源，统一生成任务单，通过 Dapr Workflow 执行多步骤拉新流程

#### 任务单状态机

```
PENDING → IN_PROGRESS → SUCCESS
                      → FAILED（可重试）
```

#### 4 种拉新流程（均通过任务单机制统一执行）

| 拉新类型 | 触发方式 | 核心步骤 |
|---------|---------|---------|
| 基础拉新 | 结构化文件或图片批量导入 | 文件解析 → 任务单入队 → 校验 → 去重 → 写库 |
| 用户拉新 | 用户上传天眼查截图 | OCR 识别 → 三要素校验 → 天眼查验实 → 写库 → 首支验证 |
| 业务拉新 | 业务系统推送企业列表 | 天眼查验实 → 校验 → 同名冲突处理 → 写库 → 首支验证 |
| 公司拉新 | 企业主动提交信息说明 | 信息结构化 → 天眼查验实 → 校验 → 写库 → 首支验证 |

#### 依赖 atomic 服务

- `eiker-company-db`：任务单写入、企业事实数据写入
- `eiker-ocr-paddleocr` / `eiker-ocr-easyocr`：图片三要素 OCR（双模型比对）
- `eiker-third-tianyancha`：天眼查验实、第三方数据源查询
- `eiker-file-excelize` / `eiker-file-apache-poi` / `eiker-file-pandas`：文件解析
- `eiker-location-update`：拉新成功后触发位置预置

---

### 3.3 eiker-location-service（位置·数据服务）

- **语言**：Go
- **Dapr app-id**：`eiker-location-service`
- **目录**：`business/business-go/eiker-location-service/`
- **职责**：对外暴露位置信息查询 API

| API 方法 | 说明 | 依赖 atomic |
|---------|------|------------|
| `query-location` | 按企业 UUID 查询预置位置信息 | eiker-location-db |

---

### 3.4 eiker-location-update（位置·预置服务）

- **语言**：Go（含 Dapr Workflow 编排）
- **Dapr app-id**：`eiker-location-update`
- **目录**：`business/business-go/eiker-location-update/`
- **职责**：接收企业地址，执行腾讯地图三步转化，将位置三要素写入 location DB

#### 位置三要素转化流程（Dapr Workflow）

```
Step 1  接收企业地址 + 信用代码省编码
Step 2  准确率策略判断（4种场景路由）
Step 3  调用腾讯地图「地址解析 API」→ 得到地理坐标
Step 4  调用腾讯地图「逆地址解析 API」→ 取首个不含括号的 POI
Step 5  特殊路径：落到省人民政府时调用「关键词搜索 API」
Step 6  写入 eiker-location-db
```

#### 依赖 atomic 服务

- `eiker-location-db`：位置数据写入/查询
- `eiker-third-tencent`：腾讯地图三类 API

---

## 4. Atomic 层模块详述

### 4.1 eiker-company-db（企业事实数据·PostgreSQL）

- **语言**：Go
- **Dapr app-id**：`eiker-company-db`
- **目录**：`atomic/atomic-go/eiker-company-db/`
- **职责**：企业事实数据 PostgreSQL CRUD；写入成功后通过 Dapr pub/sub 发布事件触发 ES 同步

#### 核心数据表：`company_fact`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | BIGSERIAL | 自增主键，内部排序，禁止插队 |
| `ent_code` | VARCHAR(36) | 企业 UUID v4（对外标识） |
| `credit_code` | VARCHAR(18) | 统一社会信用代码 |
| `name` | VARCHAR(100) | 企业名称 |
| `legal_rep` | VARCHAR(20) | 权力人姓名 |
| `fact_time` | TIMESTAMPTZ | 事实发生时间 |
| `fact_record_time` | TIMESTAMPTZ | 入巢时间 |
| `ent_record_scene` | SMALLINT | 新增场景：1=基础拉新；2=用户拉新；3=业务拉新；4=公司拉新 |
| `legal_rep_record_scene` | SMALLINT | 权力人场景：1=代为确定性主张；2=确定实际主张；3=权力人替换并主张 |

#### 核心数据表：`company_task`（任务单）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | BIGSERIAL | 自增主键 |
| `task_id` | VARCHAR(36) | 任务单 UUID |
| `source` | SMALLINT | 来源：1=基础；2=用户；3=业务；4=公司 |
| `status` | SMALLINT | 状态：0=PENDING；1=IN_PROGRESS；2=SUCCESS；3=FAILED |
| `payload` | JSONB | 采信来源、凭证、处理规则 |
| `result` | JSONB | 处理结果 |
| `created_at` | TIMESTAMPTZ | 创建时间 |
| `updated_at` | TIMESTAMPTZ | 更新时间 |

#### Dapr pub/sub 事件

- **发布 topic**：`company-fact-upserted`
- **触发时机**：PostgreSQL 写入成功后
- **Payload**：`{ "ent_code": "...", "fact_id": ..., "action": "create|update" }`

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `upsert-company-fact` | 写入/更新企业事实数据 |
| `query-company-fact` | 按条件查询事实数据 |
| `create-task` | 创建任务单 |
| `update-task-status` | 更新任务单状态 |
| `query-task` | 查询任务单 |

---

### 4.2 eiker-company-es（企业名称·ES 索引）

- **语言**：Go
- **Dapr app-id**：`eiker-company-es`
- **目录**：`atomic/atomic-go/eiker-company-es/`
- **职责**：维护 ES 索引；订阅 `company-fact-upserted` 事件自动同步；提供搜索查询接口

#### ES Index Schema（索引名：`company_name`）

| 字段 | 类型 | 分词策略 | 用途 |
|------|------|---------|------|
| `_id` | keyword | — | 企业名称 SHA256 哈希 |
| `name` | text | ngram 2_3 | 片段模糊搜索 |
| `name.pinyin` | text | 逐汉字分拼音 | 拼音连续子字符串匹配 |
| `name.char_token` | text | 逐字符 | 过滤搜索词中不存在的字 |
| `name.keyword` | keyword | 不分词 | 精确查询 |
| `credit_code` | text | edge_ngram 4_18 | 信用代码前缀匹配 |
| `legal_rep` | text | 逐字分词 | 连续子字符串匹配 |
| `legal_rep.pinyin` | text | 逐汉字分拼音 | 权力人拼音匹配 |
| `ent_code` | keyword | 不分词 | UUID 精确查询 |
| `fact_id` | keyword | 不分词 | 事实 ID 精确查询 |

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `search-company` | 关键词/拼音搜索，返回最多100条 |
| `query-company-by-id` | 按 ent_code 或 credit_code 精确查询 |

#### Dapr pub/sub 订阅

- **订阅 topic**：`company-fact-upserted`
- **处理**：接收事件 → 写入/更新 ES 文档

---

### 4.3 eiker-location-db（位置数据·PostgreSQL）

- **语言**：Go
- **Dapr app-id**：`eiker-location-db`
- **目录**：`atomic/atomic-go/eiker-location-db/`
- **职责**：位置预置数据 PostgreSQL CRUD

#### 核心数据表：`company_location`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | BIGSERIAL | 自增主键 |
| `ent_code` | VARCHAR(36) | 企业 UUID（与 company_fact.ent_code 关联） |
| `address` | VARCHAR(200) | 原始企业地址 |
| `longitude` | DECIMAL(10,7) | 经度 |
| `latitude` | DECIMAL(10,7) | 纬度 |
| `poi_name` | VARCHAR(200) | 地标名称（位置三要素之一） |
| `poi_address` | VARCHAR(200) | 地标地址（位置三要素之一） |
| `poi_id` | VARCHAR(50) | 腾讯地图 POI ID（位置三要素之一） |
| `created_at` | TIMESTAMPTZ | 创建时间 |

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `upsert-location` | 写入/更新位置数据 |
| `query-location` | 按 ent_code 查询位置 |

---

### 4.4 eiker-third-api 子模块

#### 4.4.1 eiker-third-tianyancha

- **语言**：Go
- **Dapr app-id**：`eiker-third-tianyancha`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-tianyancha/`

| 方法 | 说明 |
|------|------|
| `verify-company-triple` | 按信用代码查询天眼查返回企业三要素，与输入比对 |
| `query-company-by-code` | 按信用代码查询企业信息（第三方数据源） |

#### 4.4.2 eiker-third-tencent

- **语言**：Go
- **Dapr app-id**：`eiker-third-tencent`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-tencent/`

| 方法 | 说明 |
|------|------|
| `geocode-address` | 腾讯地图地址解析（地址 → 坐标） |
| `reverse-geocode` | 腾讯地图逆地址解析（坐标 → POI 列表） |
| `search-poi-by-keyword` | 腾讯地图关键词搜索（关键词 → POI） |

#### 4.4.3 eiker-third-identity（待定）

- **语言**：Go
- **Dapr app-id**：`eiker-third-identity`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-identity/`
- **说明**：五要素认证提供方在需求文档中未定义（见缺口 G-20），此处预留模块占位，具体对接方在提供方确认后实现

| 方法 | 说明 |
|------|------|
| `verify-five-elements` | 五要素认证（企业名称+信用代码+权力人+手机号+身份证号） |

---

### 4.5 eiker-ocr 子模块

每个子模块均通过 Dapr gRPC service invocation 暴露统一方法：`extract-company-triple`

输入：图片 base64 / 图片文件路径
输出：`{ "credit_code": "...", "name": "...", "legal_rep": "..." }`

| 子模块 | 语言 | 目录 | 框架 | 特点 |
|--------|------|------|------|------|
| `eiker-ocr-paddleocr` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-paddleocr/` | PaddleOCR | 中文识别优先，百度开源 |
| `eiker-ocr-easyocr` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-easyocr/` | EasyOCR | 多语言备选 |
| `eiker-ocr-tesseract` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-tesseract/` | pytesseract | 经典引擎，轻量备选 |

**双模型比对策略**（在 business 层实现）：同时调用2个模型，三要素完全一致则通过，否则返回识别失败。

---

### 4.6 eiker-file 子模块

每个子模块通过 Dapr service invocation 暴露统一方法：`parse-file`

输入：文件 base64 + 文件类型标识
输出：`{ "rows": [ { "credit_code": "...", "name": "...", "legal_rep": "..." }, ... ] }`

| 子模块 | 语言 | 目录 | 框架 | 支持格式 |
|--------|------|------|------|---------|
| `eiker-file-excelize` | Go | `atomic/atomic-go/eiker-file-go/eiker-file-excelize/` | excelize | xlsx/xls |
| `eiker-file-apache-poi` | Java | `atomic/atomic-java/eiker-file-java/eiker-file-apache-poi/` | Apache POI | xls/xlsx/csv |
| `eiker-file-openpyxl` | Python | `atomic/atomic-python/eiker-file-python/eiker-file-openpyxl/` | openpyxl | xlsx |
| `eiker-file-pandas` | Python | `atomic/atomic-python/eiker-file-python/eiker-file-pandas/` | pandas | csv/xlsx/json |

> 同一文件格式提供多语言实现，business 层根据实际部署环境选择调用哪个子模块。

---

## 5. Dapr 服务调用关系总览

```
前端
  ↓
eiker-company-service (business·Go)
  ├─ invoke → eiker-company-es       搜索/查询
  ├─ invoke → eiker-company-db       申诉/主张写入
  ├─ invoke → eiker-ocr-paddleocr    OCR（主）
  ├─ invoke → eiker-ocr-easyocr      OCR（备）
  └─ invoke → eiker-third-tianyancha 天眼查验实

eiker-company-update (business·Go)
  ├─ invoke → eiker-company-db       任务单管理、事实数据写入
  ├─ invoke → eiker-ocr-paddleocr / eiker-ocr-easyocr
  ├─ invoke → eiker-third-tianyancha
  ├─ invoke → eiker-file-excelize / eiker-file-pandas  文件解析
  └─ invoke → eiker-location-update  触发位置预置

eiker-location-update (business·Go)
  ├─ invoke → eiker-location-db
  └─ invoke → eiker-third-tencent    腾讯地图三类API

eiker-company-db (atomic·Go)
  └─ pub/sub publish → topic: company-fact-upserted

eiker-company-es (atomic·Go)
  └─ pub/sub subscribe ← topic: company-fact-upserted
```

---

## 6. eiker-java-common 变更

**无需新增依赖。** Business 层使用 Go 实现 Dapr Workflow，与 Java common 库无关。

---

## 7. 目录结构汇总

```
eiker-be/
├── business/
│   └── business-go/
│       ├── eiker-company-service/
│       ├── eiker-company-update/
│       ├── eiker-location-service/
│       └── eiker-location-update/
├── atomic/
│   ├── atomic-go/
│   │   ├── eiker-company-db/
│   │   ├── eiker-company-es/
│   │   ├── eiker-location-db/
│   │   ├── eiker-file-go/
│   │   │   └── eiker-file-excelize/   ← 现有 eiker-file-go 代码迁入
│   │   └── eiker-third-api/
│   │       ├── eiker-third-tianyancha/
│   │       ├── eiker-third-tencent/
│   │       └── eiker-third-identity/   ← 五要素认证（提供方待定）
│   ├── atomic-java/
│   │   └── eiker-file-java/
│   │       └── eiker-file-apache-poi/
│   └── atomic-python/
│       ├── eiker-ocr/
│       │   ├── eiker-ocr-paddleocr/
│       │   ├── eiker-ocr-easyocr/
│       │   └── eiker-ocr-tesseract/
│       └── eiker-file-python/
│           ├── eiker-file-openpyxl/
│           └── eiker-file-pandas/
└── common/
    ├── eiker-go-common/
    ├── eiker-java-common/
    └── eiker-python-common/
```

---

## 8. 待决策事项（来自需求分析报告矛盾/缺口）

| 编号 | 问题 | 建议 |
|------|------|------|
| C-03 | 同名不同企：随机留一 vs 全部保留 | 以会议记录为准：全部保留，独立存在 |
| C-07 | 权力人申诉校验逻辑相反 | 以流程图为准：OCR ≠ 库时申诉有依据 |
| G-06 | 公司拉新：非结构化文本解析方式 | 建议采用 AI 抽取（如调用 LLM 结构化提取） |
| G-10 | 首支验证自动化机制 | 首期保留手动确认，生产环境另行定义 |
| G-18/19 | 双模型/双数据源结果不一致时策略 | 首期返回失败，由 business 层处理重试或人工介入 |
