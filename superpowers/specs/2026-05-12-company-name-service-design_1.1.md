# 企业名称服务架构设计规格说明

> 版本：v1.2
> 日期：2026-05-18
> 需求来源：doc/企业名称/ 目录下全部原始文档 + 企业名称服务需求分析报告.md + company_schema.sql(v2.0) + company-task设计(v1.1)

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
┌──────────────────────────────────────────────────────────┐
│                      Business 层（Go）                    │
│  eiker-company-service   eiker-company-update             │
│  eiker-location-service  eiker-location-update            │
└─────────────────┬────────────────────────────────────────┘
                  │  Dapr Service Invocation / Pub-Sub
┌─────────────────▼────────────────────────────────────────┐
│                      Atomic 层                            │
│  Go:     eiker-company-db   eiker-company-es              │
│          eiker-address-db                                 │
│          eiker-third-api/eiker-third-tianyancha           │
│          eiker-third-api/eiker-third-tencent              │
│          eiker-third-api/eiker-third-identity（待定）     │
│          eiker-file-go/eiker-file-excelize                │
│  Python: eiker-ocr/eiker-ocr-paddleocr                   │
│          eiker-ocr/eiker-ocr-easyocr                     │
│          eiker-ocr/eiker-ocr-tesseract                   │
│          eiker-file-python/eiker-file-openpyxl            │
│          eiker-file-python/eiker-file-pandas              │
│  Java:   eiker-file-java/eiker-file-apache-poi            │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Business 层模块详述

### 3.1 eiker-company-service（企业名称·数据服务）

- **语言**：Go
- **Dapr app-id**：`eiker-company-service`
- **目录**：`business/business-go/eiker-company-service/`
- **职责**：对外暴露企业名称域的查询类 API，不涉及数据写入

| API 方法 | 说明 | 依赖服务 |
|---------|------|---------|
| `search-company` | 企业名称搜索（关键词/拼音） | eiker-company-es |
| `query-company-info` | 企业信息查询（按 UUID/信用代码） | eiker-company-es |
| `submit-company-appeal` | 提交企业名称申诉 | eiker-company-db, eiker-ocr-*, eiker-third-tianyancha |
| `claim-power-holder` | 权力人主张 | eiker-company-db, eiker-third-identity |
| `appeal-power-holder` | 权力人申诉 | eiker-company-db, eiker-ocr-*, eiker-third-tianyancha |

---

### 3.2 eiker-company-update（企业名称·拉新服务）

- **语言**：Go（含 Dapr Workflow 编排）
- **Dapr app-id**：`eiker-company-update`
- **目录**：`business/business-go/eiker-company-update/`
- **职责**：接收 4 种拉新来源，统一生成任务单，通过 Dapr Workflow 执行多步骤拉新流程

#### 任务单状态机（business 层内部逻辑）

```
PENDING → IN_PROGRESS → SUCCESS
                      → FAILED（可重试）
```

#### 4 种拉新流程（均通过任务单机制统一执行）

| 拉新类型 | 触发方式 | 核心步骤 |
|---------|---------|---------|
| 基础拉新 | 结构化文件批量导入（sql/csv/xlsx/json/txt/xml） | 文件解析 → 任务单入队 → 三要素校验 → 天眼查验实 → 冲突处理 → 写库 → 触发位置预置 |
| 用户拉新 | 用户上传天眼查截图 | OCR 识别 → 三要素校验 → 天眼查验实 → 冲突处理 → 写库 → 触发位置预置 → 首支验证 |
| 业务拉新 | 业务系统推送企业列表 | 三要素校验 → 天眼查验实 → 冲突处理 → 写库 → 触发位置预置 → 首支验证 |
| 公司拉新 | 企业提交结构化文件（与基础拉新输入一致） | 文件解析 → 任务单入队 → 三要素校验 → 天眼查验实 → 冲突处理 → 写库 → 触发位置预置 → 首支验证 |

#### 依赖服务（atomic + business）

| 服务 | 层级 | 用途 |
|------|------|------|
| `eiker-company-db` | atomic | 企业事实数据写入、处理日志写入 |
| `eiker-ocr-paddleocr` / `eiker-ocr-easyocr` | atomic | 图片三要素 OCR（双模型比对） |
| `eiker-third-tianyancha` | atomic | 天眼查查询验实 |
| `eiker-file-excelize` / `eiker-file-apache-poi` / `eiker-file-pandas` | atomic | 文件解析 |
| `eiker-location-update` | **business** | 拉新成功后触发位置预置 |

---

### 3.3 eiker-location-service（位置·数据服务）

- **语言**：Go
- **Dapr app-id**：`eiker-location-service`
- **目录**：`business/business-go/eiker-location-service/`
- **职责**：对外暴露位置信息查询 API

| API 方法 | 说明 | 依赖服务 |
|---------|------|---------|
| `query-location` | 按实体类型+实体ID查询预置位置信息 | eiker-address-db |

---

### 3.4 eiker-location-update（位置·预置服务）

- **语言**：Go（含 Dapr Workflow 编排）
- **Dapr app-id**：`eiker-location-update`
- **目录**：`business/business-go/eiker-location-update/`
- **职责**：接收企业地址，执行腾讯地图三步转化，将位置三要素写入 eiker-address-db

#### 位置三要素转化流程（Dapr Workflow）

```
Step 1  接收企业地址 + 信用代码省编码 + entity_type + entity_id
Step 2  准确率策略判断（4种场景路由）
          ├── 省编码一致                    → 直接使用腾讯返回
          ├── 省编码不一致 + 含省级信息     → 直接使用腾讯返回
          ├── 省编码不一致 + 无省级信息     → 补省市县后重新调用
          └── 其他                         → 补省后默认省人民政府地址
Step 3  调用腾讯地图「地址解析 API」→ 得到地理坐标
Step 4  调用腾讯地图「逆地址解析 API」→ 取首个不含括号的 POI
Step 5  特殊路径：落到省人民政府时调用「关键词搜索 API」
Step 6  写入 eiker-address-db
```

#### 依赖服务（atomic）

- `eiker-address-db`：地址数据写入/查询
- `eiker-third-tencent`：腾讯地图三类 API

---

## 4. Atomic 层模块详述

### 公共字段规范

所有数据表均须包含以下公共字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | BIGSERIAL | 自增主键 |
| `is_current` | BOOLEAN | 是否当前有效版本（用于多版本数据） |
| `trace_id` | VARCHAR(64) | 日志链路追踪ID |
| `owner` | VARCHAR(64) | 数据拥有人（用于数据权限控制） |
| `creater` | VARCHAR(64) | 创建人 |
| `create_time` | TIMESTAMPTZ | 创建时间（DB insert 时自动写入） |
| `updater` | VARCHAR(64) | 修改人 |
| `update_time` | TIMESTAMPTZ | 修改时间（DB update 时自动写入） |
| `remark` | VARCHAR(500) | 备注 |

> 以下各表字段仅列出业务字段，公共字段默认包含。

---

### 4.1 eiker-company-db（企业事实数据·PostgreSQL）

- **语言**：Go
- **Dapr app-id**：`eiker-company-db`
- **目录**：`atomic/atomic-go/eiker-company-db/`
- **职责**：企业名称域 PostgreSQL CRUD；写入事实数据后通过 Dapr pub/sub 发布事件触发 ES 同步

#### 核心数据表：`company_fact`（企业事实数据）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ent_code` | VARCHAR(36) | 企业 UUID v4（对外标识，公域使用） |
| `credit_code` | VARCHAR(18) | 统一社会信用代码（GB 32100-2015） |
| `reg_no` | VARCHAR(50) | 注册号 |
| `name` | VARCHAR(200) | 企业名称（4-26字，汉字或汉字+括号） |
| `legal_rep` | VARCHAR(50) | 法定代表人（2-5字，纯汉字） |
| `company_type` | VARCHAR(100) | 公司类型 |
| `found_date` | DATE | 成立日期 |
| `reg_capital` | DECIMAL(20, 6) | 注册资本 |
| `reg_capital_currency` | VARCHAR(10) | 注册资本币种（默认：人民币） |
| `approve_date` | DATE | 核准日期 |
| `registration_authority` | VARCHAR(200) | 登记机关 |
| `status` | VARCHAR(50) | 登记状态（存续/在营/开业/在册/吊销/注销/迁出/停业/清算） |
| `address` | VARCHAR(500) | 住所 |
| `business_scope` | TEXT | 经营范围 |
| `business_term_start` | DATE | 营业期限自 |
| `business_term_end` | DATE | 营业期限至 |

#### 冲突处理数据表：`company_conflict_log`（企业名称冲突日志）

| 字段 | 类型 | 说明 |
|------|------|------|
| `conflict_id` | VARCHAR(36) | 冲突记录 UUID（对外标识） |
| `task_id` | VARCHAR(36) | 触发冲突的任务 ID |
| `temp_data_id` | BIGINT | 关联 task_data_temp.id |
| `conflict_type` | SMALLINT | 冲突类型：1=同名不同企，2=同企不同名 |
| `credit_code_incoming` | VARCHAR(18) | 新数据信用代码 |
| `name_incoming` | VARCHAR(200) | 新数据企业名称 |
| `credit_code_existing` | VARCHAR(18) | 已存在数据信用代码 |
| `name_existing` | VARCHAR(200) | 已存在数据企业名称 |
| `ent_code_existing` | VARCHAR(36) | 已存在企业 UUID |
| `resolution` | SMALLINT | 处理状态：0=待处理，1=已全部保留，2=人工处理中，3=已处理 |
| `resolved_at` | TIMESTAMPTZ | 处理完成时间 |
| `resolved_by` | VARCHAR(64) | 处理人 |

> 与 §8 决策 C-03 对应：同名不同企全部保留，冲突记录写入本表，支持后续人工介入处理。

#### 拉新任务管理数据表（8张表，详见 company-task 设计文档）

> 任务单管理系统已重构为完整的8张表体系，替代原单表 company_task 及多张中间结果表。

**实体关系图：**
```
task_type_config (任务类型配置)
    ↑
    │ 1:N
    │
task_main (任务主表)
    ├─ 1:N → task_data_temp (任务数据临时表)
    │           ├─ 1:N → data_verify_result (数据验证结果表)
    │           │           └─ N:1 → third_api_log (via third_api_log_id，仅真实性验证时有值)
    │           ├─ 1:N → third_api_log (第三方API调用日志表)
    │           └─ 1:1 → task_nest_log (任务入巢日志表)
    │
    └─ 1:N → task_step_log (任务步骤日志表)

data_verify_rule (数据验证规则表)
    ↓
    │ 1:N
    └─ data_verify_result
```

**核心表说明：**

| 表名 | 说明 | 关键设计点 |
|------|------|-----------|
| `task_type_config` | 任务类型配置表 | 配置4种拉新类型及默认验证规则 |
| `task_main` | 任务主表 | 任务UUID、类型、状态、统计信息、Dapr Workflow实例ID |
| `task_data_temp` | 任务数据临时表 | 原始解析数据、提取关键字段、解析阶段状态(parse_status)、行级综合处理状态(row_status) |
| `task_step_log` | 任务步骤日志表 | 每一步骤输入输出完整留痕、耗时统计 |
| `data_verify_rule` | 数据验证规则表 | 4大类18条验证规则，可配置化管理 |
| `data_verify_result` | 数据验证结果表 | 逐条数据逐条规则记录，关联third_api_log |
| `third_api_log` | 第三方API调用日志表 | 完整HTTP请求响应记录，天眼查等API调用留痕 |
| `task_nest_log` | 任务入巢日志表 | 任务数据与数巢数据关联桥梁，永久保留 |

**数据验证规则分类（共18条）：**
- **完整性验证（6条）**：统一社会信用代码、企业名称、法定代表人、成立日期、登记状态、住所不能为空
- **合规性验证（7条）**：信用代码格式、企业名称格式/长度、法定代表人格式/长度、成立日期、登记状态
- **重复性验证（4条）**：同名不同企（本任务/数巢）、同企不同名（本任务/数巢）
- **真实性验证（1条）**：天眼查API验证

**状态流转：**
- task_main: PENDING(0) → IN_PROGRESS(1) → SUCCESS(2)/FAILED(3)
- task_data_temp.row_status: 待处理(0) → 解析中(1) → 解析完成(2) → 验证中(3) → 验证通过(4)/验证失败(5) → 入巢中(6) → 入巢成功(7)/入巢失败(8)

#### Dapr pub/sub 事件

- **发布 topic**：`company-fact-upserted`
- **触发时机**：PostgreSQL 事实数据写入成功后
- **Payload**：`{ "ent_code": "...", "fact_id": ..., "action": "create|update" }`

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `upsert-company-fact` | 写入/更新企业事实数据 |
| `batch-upsert-company-fact` | 批量写入企业事实数据（基础拉新用） |
| `query-company-fact-by-name` | 按企业名称查询事实数据 |
| `query-company-fact-by-code` | 按信用代码查询事实数据 |
| `query-company-fact-by-ent-code` | 按企业 UUID 查询事实数据 |
| `create-task-main` | 创建任务主表记录 |
| `update-task-main` | 更新任务状态及统计信息（task_status / total_count / success_count / fail_count） |
| `save-task-data-temp` | 批量写入任务数据临时表 |
| `query-task-main` | 查询任务主表信息 |
| `save-task-step-log` | 保存任务步骤日志 |
| `save-data-verify-result` | 保存数据验证结果 |
| `save-third-api-log` | 保存第三方API调用日志 |
| `save-task-nest-log` | 保存任务入巢日志 |

---

### 4.2 eiker-company-es（企业名称·ES 索引）

- **语言**：Go
- **Dapr app-id**：`eiker-company-es`
- **目录**：`atomic/atomic-go/eiker-company-es/`
- **职责**：维护 ES 索引；订阅 `company-fact-upserted` 事件自动同步；提供搜索查询接口

#### ES Index Schema（索引名：`company_name`）

索引字段与 `company_fact` 表保持一致，额外增加 `name.pinyin` 和 `legal_rep.pinyin` 两个拼音子字段用于搜索：

| 字段 | 额外说明（与 DB 一致字段省略） |
|------|------|
| 与 `company_fact` 表全部字段一一对应 | 类型按 ES 映射规范转换（VARCHAR→keyword/text，TIMESTAMPTZ→date，BOOLEAN→boolean，BIGSERIAL→long，SMALLINT→integer） |
| `name.pinyin` | **新增**，逐汉字分拼音，用于拼音连续子字符串匹配 |
| `name.char_token` | **新增**，逐字符分词，用于过滤搜索词中不存在于企业名称的字符 |
| `name.keyword` | **新增**，不分词，用于精确全名匹配 |
| `legal_rep.pinyin` | **新增**，逐汉字分拼音，用于权力人姓名拼音匹配 |

> `name` 字段本身使用 ngram 2_3 分词，支持片段模糊搜索；`credit_code` 使用 edge_ngram 4_18，支持前缀匹配。

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `search-company` | 关键词/拼音搜索，返回最多 100 条 |
| `query-company-by-id` | 按 ent_code 或 credit_code 精确查询 |

#### Dapr pub/sub 订阅

- **订阅 topic**：`company-fact-upserted`
- **处理**：接收事件 → 写入/更新 ES 文档

---

### 4.3 eiker-address-db（通用地址服务·PostgreSQL）

- **语言**：Go
- **Dapr app-id**：`eiker-address-db`
- **目录**：`atomic/atomic-go/eiker-address-db/`
- **职责**：通用地址数据 PostgreSQL CRUD，不绑定任何业务域，通过 entity_type + entity_id 与任意实体关联

#### 核心数据表：`address_info`

| 字段 | 类型 | 说明 |
|------|------|------|
| `address_id` | VARCHAR(36) | 地址 UUID v4（对外标识） |
| `entity_type` | VARCHAR(50) | 关联实体类型（如：company） |
| `entity_id` | VARCHAR(36) | 关联实体 UUID |
| `raw_address` | VARCHAR(500) | 原始输入地址 |
| `province_code` | VARCHAR(6) | 省编码（从信用代码提取或地址解析获得） |
| `longitude` | DECIMAL(10,7) | 经度 |
| `latitude` | DECIMAL(10,7) | 纬度 |
| `poi_name` | VARCHAR(200) | 地标名称（位置三要素之一） |
| `poi_address` | VARCHAR(200) | 地标地址（位置三要素之一） |
| `poi_id` | VARCHAR(50) | 腾讯地图 POI ID（位置三要素之一） |
| `accuracy_level` | SMALLINT | 准确率级别：1=精确匹配；2=省市县补全后匹配；3=省人民政府兜底 |

#### 暴露的 Dapr 服务调用方法

| 方法 | 说明 |
|------|------|
| `upsert-address` | 写入/更新地址 |
| `query-address-by-id` | 按 address_id 查询 |
| `query-address-by-entity` | 按 entity_type + entity_id 查询 |

---

### 4.4 eiker-third-api 子模块

#### 4.4.1 eiker-third-tianyancha

- **语言**：Go
- **Dapr app-id**：`eiker-third-tianyancha`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-tianyancha/`
- **说明**：天眼查仅提供按企业名称查询企业列表一个查询接口，验实逻辑由 business 层比对完成

| 方法 | 说明 |
|------|------|
| `query-companies-by-name` | 按企业名称调用天眼查 API 查询企业列表，返回原始结果 |

#### 4.4.2 eiker-third-tencent

- **语言**：Go
- **Dapr app-id**：`eiker-third-tencent`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-tencent/`

| 方法 | 说明 |
|------|------|
| `geocode-address` | 腾讯地图地址解析（地址 → 坐标） |
| `reverse-geocode` | 腾讯地图逆地址解析（坐标 → POI 列表） |
| `search-poi-by-keyword` | 腾讯地图关键词搜索（关键词 → POI） |
| `verify-user-two-elements` | 用户二要素认证（姓名 + 手机号码） |
| `verify-user-three-elements` | 用户三要素认证（姓名 + 手机号码 + 身份证号） |
| `verify-user-three-elements-liveness` | 用户三要素认证 + 活体认证（姓名 + 手机号码 + 身份证号 + 活体） |

#### 4.4.3 eiker-third-identity（待定）

- **语言**：Go
- **Dapr app-id**：`eiker-third-identity`
- **目录**：`atomic/atomic-go/eiker-third-api/eiker-third-identity/`
- **说明**：五要素认证（企业名称+信用代码+权力人+手机号+身份证号）提供方待确定（见缺口 G-20），预留占位

| 方法 | 说明 |
|------|------|
| `verify-five-elements` | 五要素认证（企业名称+信用代码+权力人+手机号+身份证号） |

---

### 4.5 eiker-ocr 子模块

每个子模块均通过 Dapr gRPC service invocation 暴露统一方法：`extract-company-triple`

- **输入**：图片 base64 或图片文件路径
- **输出**：`{ "credit_code": "...", "name": "...", "legal_rep": "..." }`

| 子模块 | 语言 | 目录 | 框架 | 特点 |
|--------|------|------|------|------|
| `eiker-ocr-paddleocr` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-paddleocr/` | PaddleOCR | 中文识别优先，百度开源，推荐主模型 |
| `eiker-ocr-easyocr` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-easyocr/` | EasyOCR | 多语言备选 |
| `eiker-ocr-tesseract` | Python | `atomic/atomic-python/eiker-ocr/eiker-ocr-tesseract/` | pytesseract | 经典引擎，轻量备选 |

**双模型比对策略**（在 business 层 eiker-company-update / eiker-company-service 内实现）：同时调用两个模型，三要素完全一致则通过，不一致则返回识别失败，由 business 层处理重试或人工介入。

---

### 4.6 eiker-file 子模块

每个子模块通过 Dapr service invocation 暴露统一方法：`parse-file`

- **输入**：文件 base64 + 文件类型标识
- **输出**：`{ "rows": [ { "credit_code": "...", "name": "...", "legal_rep": "..." }, ... ] }`

| 子模块 | 语言 | 目录 | 框架 | 支持格式 |
|--------|------|------|------|---------|
| `eiker-file-excelize` | Go | `atomic/atomic-go/eiker-file-go/eiker-file-excelize/` | excelize | xlsx |
| `eiker-file-apache-poi` | Java | `atomic/atomic-java/eiker-file-java/eiker-file-apache-poi/` | Apache POI | xls/xlsx/csv |
| `eiker-file-openpyxl` | Python | `atomic/atomic-python/eiker-file-python/eiker-file-openpyxl/` | openpyxl | xlsx |
| `eiker-file-pandas` | Python | `atomic/atomic-python/eiker-file-python/eiker-file-pandas/` | pandas | csv/xlsx/json |

> 同一格式提供多语言实现，business 层根据实际部署环境选择调用哪个子模块。现有 `eiker-file-go` 根目录代码迁移至 `eiker-file-excelize` 子模块。

> ⚠️ **待补充**：基础拉新和公司拉新支持的 `sql`、`txt`、`xml` 格式当前无对应原子解析子模块，需补充实现（建议：`eiker-file-go/eiker-file-sqlparser`、`eiker-file-go/eiker-file-txtparser`、`eiker-file-go/eiker-file-xmlparser`）。

---

## 5. Dapr 服务调用关系总览

```
前端
  ↓
eiker-company-service (business·Go)
  ├─ invoke → eiker-company-es            搜索/查询
  ├─ invoke → eiker-company-db            申诉/主张写入、日志写入
  ├─ invoke → eiker-ocr-paddleocr         OCR（主）
  ├─ invoke → eiker-ocr-easyocr           OCR（备）
  ├─ invoke → eiker-third-tianyancha      天眼查查询
  └─ invoke → eiker-third-identity        五要素认证

eiker-company-update (business·Go)
  ├─ invoke → eiker-company-db            任务单管理、事实数据写入、日志写入
  ├─ invoke → eiker-ocr-paddleocr / eiker-ocr-easyocr
  ├─ invoke → eiker-third-tianyancha
  ├─ invoke → eiker-file-excelize / eiker-file-apache-poi / eiker-file-pandas
  └─ invoke → eiker-location-update (business)  触发位置预置

eiker-location-update (business·Go)
  ├─ invoke → eiker-address-db            地址数据写入/查询
  └─ invoke → eiker-third-tencent         腾讯地图三类 API

eiker-location-service (business·Go)
  └─ invoke → eiker-address-db            地址数据查询

eiker-company-db (atomic·Go)
  └─ pub/sub publish → topic: company-fact-upserted

eiker-company-es (atomic·Go)
  └─ pub/sub subscribe ← topic: company-fact-upserted
```

---

## 6. eiker-java-common 变更

**无需新增依赖。** Business 层与 Atomic 文件解析 Java 服务均通过 Dapr service invocation 通信，business 层使用 Go 实现 Dapr Workflow，与 Java common 库无关。

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
│   │   ├── eiker-address-db/
│   │   ├── eiker-file-go/
│   │   │   └── eiker-file-excelize/      ← 现有 eiker-file-go 代码迁入
│   │   └── eiker-third-api/
│   │       ├── eiker-third-tianyancha/
│   │       ├── eiker-third-tencent/
│   │       └── eiker-third-identity/     ← 五要素认证（提供方待定）
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

## 8. 已决策事项

| 编号 | 问题 | 决策 |
|------|------|------|
| **C-03** | 同名不同企处理 | 以《企业名称服务.pdf》流程图为准（图中存在"重复数据人工处理"分支，即全部保留，通过冲突处理流程解决，记录至 company_conflict_log） |
| **C-07** | 权力人申诉校验逻辑 | 以流程图逻辑为准：OCR ≠ 库中数据时，申诉有依据，继续处理；OCR = 库中数据时，申诉失败 |
| **G-06** | 公司拉新输入形式 | 与基础拉新一致，输入为结构化文件（sql/csv/xlsx/json） |
| **G-10** | 首支验证自动化 | 首期保留手动确认，生产环境另行定义 |
| **G-18/19** | 双模型/双数据源不一致时策略 | 首期返回失败，由 business 层处理重试或人工介入 |
| **eiker-third-identity** | 五要素认证提供方 | 暂无指定供应商，预留占位模块 |
