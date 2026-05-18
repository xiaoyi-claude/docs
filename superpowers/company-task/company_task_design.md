# 企业名称-拉新任务实体设计

> 版本: v1.0
> 日期: 2026-05-15
> 数据库: PostgreSQL

---

## 1. 设计概述

### 1.1 任务类型

| 编码 | 名称 | 输入来源 |
|------|------|----------|
| 1 | 基础拉新 | 结构化文件（.sql / .csv / .xlsx / .json / .txt / .xml） |
| 2 | 用户拉新 | 天眼查截图（.png / .jpg / .bmp） |
| 3 | 业务拉新 | 业务系统压缩包（.zip / .rar / .tar / .gz） |
| 4 | 公司拉新 | 企业提交结构化文件（与基础拉新输入一致） |

### 1.2 任务输入规则

**输入来源（四选一）**：

| 编码 | 类型 | 允许格式 |
|------|------|----------|
| 1 | 文件 | .sql / .csv / .xlsx / .json / .txt / .xml |
| 2 | 图片 | .png / .jpg / .bmp |
| 3 | 压缩包 | .zip / .rar / .tar / .gz |
| 4 | OSS 路径 | 任意上述格式的 OSS 对象路径 |

**验证规则列表**：创建任务时可指定 `verify_rule_codes`；若不传入，自动从 `task_type_config.default_verify_rule_codes` 复制。`task_main.verify_rule_codes` 在任务创建时即确定，始终有值。

### 1.3 处理步骤

```
任务创建
    │
    ▼ Step 1: 文件读取与解析
    │   ├─ 解析文件内容，逐行写入 task_data_temp
    │   │   （图片：OCR 解析，row_no 固定为 1）
    │   ├─ 更新 task_data_temp.parse_status
    │   └─ 写入 task_step_log（step_code=1）
    │
    ▼ Step 2: 数据验证
    │   ├─ 按 verify_rule_codes 逐条规则、逐行验证
    │   ├─ 每条验证结果写入 data_verify_result
    │   ├─ 天眼查规则：验证结果写 data_verify_result，同时写 third_api_log
    │   │   third_api_log.verify_result_id → data_verify_result.id
    │   ├─ 更新 task_data_temp.verify_status
    │   │   （全部规则通过 → 1=通过；任一规则失败 → 2=失败）
    │   └─ 写入 task_step_log（step_code=2）
    │
    ▼ Step 3: 数据入巢
        ├─ 筛选 verify_status=1 的行写入 company_fact
        ├─ 写入 task_nest_log
        ├─ 更新 task_data_temp.nest_status（1=已入巢 / 2=跳过）
        └─ 写入 task_step_log（step_code=3）
```

---

## 2. 实体关系

```
task_type_config（任务类型配置）
    │ 1:N
    ▼
task_main（任务主表）
    │ 1:N
    ▼
task_data_temp（任务数据临时表）
    ├─ 1:N ──────────────────► data_verify_result（验证结果）
    │                               │ 1:1
    │                               ▼
    │                          third_api_log（天眼查 API 调用日志）
    │ 1:1
    ▼
task_nest_log（入巢日志）

task_main ──1:N──► task_step_log（步骤日志）

data_verify_rule ──被引用──► task_main.verify_rule_codes[]
data_verify_rule.rule_code ──被引用──► data_verify_result.rule_code
```

---

## 3. 数据表说明

### 3.1 task_type_config（任务类型配置表）

存储 4 种拉新任务类型及各类型默认执行的验证规则列表。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_type_code | SMALLINT | NOT NULL, UNIQUE, IN(1,2,3,4) | 1=基础拉新，2=用户拉新，3=业务拉新，4=公司拉新 |
| task_type_name | VARCHAR(50) | NOT NULL | 任务类型名称 |
| task_type_desc | VARCHAR(200) | | 描述 |
| default_verify_rule_codes | JSONB | NOT NULL | 默认验证规则编码列表（rule_code 字符串数组） |
| is_enabled | BOOLEAN | NOT NULL DEFAULT TRUE | 是否启用 |

> `default_verify_rule_codes` 存储具体 rule_code，而非大类标签，与 `data_verify_rule` 表直接对应。

---

### 3.2 task_main（任务主表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_id | VARCHAR(36) | NOT NULL, UNIQUE | 任务 UUID（对外标识） |
| task_type_code | SMALLINT | NOT NULL, FK | 任务类型编码 |
| task_name | VARCHAR(200) | | 任务名称 |
| task_status | SMALLINT | NOT NULL DEFAULT 0 | 0=PENDING，1=IN_PROGRESS，2=SUCCESS，3=FAILED |
| input_type | SMALLINT | NOT NULL, IN(1,2,3,4) | 1=文件，2=图片，3=压缩包，4=OSS路径 |
| input_file_ext | VARCHAR(10) | | 文件后缀（sql/csv/xlsx/json/txt/xml/png/jpg/bmp/zip/rar/tar/gz） |
| input_path | VARCHAR(500) | NOT NULL | 文件存储路径或 OSS 路径 |
| verify_rule_codes | JSONB | NOT NULL | 实际执行的规则编码列表（创建时确定） |
| total_count | INTEGER | DEFAULT 0 | 解析出的总记录数 |
| pass_count | INTEGER | DEFAULT 0 | 成功入巢数 |
| fail_count | INTEGER | DEFAULT 0 | 未入巢数（解析失败 + 验证失败） |
| started_at | TIMESTAMPTZ | | 处理开始时间 |
| completed_at | TIMESTAMPTZ | | 处理完成时间 |
| error_msg | TEXT | | 任务级错误信息 |

---

### 3.3 task_data_temp（任务数据临时表）

文件解析后逐行存储的临时数据，贯穿验证和入巢全流程。三个状态字段分别标记各步骤处理结论。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_id | VARCHAR(36) | NOT NULL | 关联任务 ID |
| row_no | INTEGER | NOT NULL | 行序号（文件按原始行顺序 1-based；图片类型固定为 1） |
| raw_data | JSONB | NOT NULL | 原始解析内容完整快照 |
| credit_code | VARCHAR(18) | | 统一社会信用代码 |
| company_name | VARCHAR(200) | | 企业名称 |
| legal_rep | VARCHAR(50) | | 法定代表人 |
| found_date | DATE | | 成立日期 |
| reg_status | VARCHAR(50) | | 登记状态 |
| address | VARCHAR(500) | | 住所 |
| parse_status | SMALLINT | NOT NULL DEFAULT 0 | 0=待解析，1=解析成功，2=解析失败 |
| parse_error | VARCHAR(500) | | 解析失败原因 |
| verify_status | SMALLINT | NOT NULL DEFAULT 0 | 0=待验证，1=全部规则通过，2=任一规则失败 |
| nest_status | SMALLINT | NOT NULL DEFAULT 0 | 0=待处理，1=已入巢，2=跳过 |

**唯一约束**：(task_id, row_no)

---

### 3.4 task_step_log（任务步骤日志表）

记录每个处理步骤的输入输出快照，是全流程留痕的核心。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_id | VARCHAR(36) | NOT NULL | 关联任务 ID |
| step_code | SMALLINT | NOT NULL, IN(1,2,3) | 1=文件读取与解析，2=数据验证，3=数据入巢 |
| step_name | VARCHAR(50) | NOT NULL | 步骤名称 |
| step_input | JSONB | NOT NULL | 步骤输入快照（步骤开始时写入） |
| step_output | JSONB | | 步骤输出快照（步骤完成时写入） |
| step_status | SMALLINT | NOT NULL DEFAULT 0 | 0=PENDING，1=IN_PROGRESS，2=SUCCESS，3=FAILED |
| started_at | TIMESTAMPTZ | NOT NULL | 步骤开始时间 |
| completed_at | TIMESTAMPTZ | | 步骤完成时间 |
| duration_ms | BIGINT | | 耗时（毫秒） |
| error_msg | TEXT | | 步骤级错误信息 |

---

### 3.5 data_verify_rule（数据验证规则表）

定义全部验证规则，共 4 个大类 18 条规则。任务类型通过引用具体 rule_code 实现可配置的规则选取。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| rule_code | VARCHAR(50) | NOT NULL, UNIQUE | 规则唯一编码 |
| rule_name | VARCHAR(100) | NOT NULL | 规则名称 |
| error_category | SMALLINT | NOT NULL, IN(1,2,3,4) | 1=完整性验证，2=合规性验证，3=数据重复，4=数据真实性验证 |
| error_sub_code | SMALLINT | NOT NULL | 大类内小类编码 |
| error_sub_name | VARCHAR(100) | NOT NULL | 小类名称 |
| is_enabled | BOOLEAN | NOT NULL DEFAULT TRUE | 是否启用 |
| sort_order | SMALLINT | NOT NULL DEFAULT 0 | 执行顺序 |

**规则清单**：

| rule_code | 大类 | 小类编码 | 小类名称 |
|-----------|------|----------|----------|
| integrity_credit_code | 完整性(1) | 1 | 统一社会信用代码缺失 |
| integrity_company_name | 完整性(1) | 2 | 企业名称缺失 |
| integrity_legal_rep | 完整性(1) | 3 | 法定代表人缺失 |
| integrity_found_date | 完整性(1) | 4 | 成立日期缺失 |
| integrity_reg_status | 完整性(1) | 5 | 登记状态缺失 |
| integrity_address | 完整性(1) | 6 | 住所缺失 |
| compliance_credit_code | 合规性(2) | 1 | 统一社会信用代码非法（不符合 GB 32100-2015） |
| compliance_company_name_char | 合规性(2) | 2 | 企业名称字符非法（仅允许汉字及括号） |
| compliance_company_name_len | 合规性(2) | 3 | 企业名称长度不在 [4, 26] |
| compliance_legal_rep_char | 合规性(2) | 4 | 法定代表人字符非法（仅允许汉字） |
| compliance_legal_rep_len | 合规性(2) | 5 | 法定代表人长度不在 [2, 5] |
| compliance_found_date | 合规性(2) | 6 | 成立日期非法（大于当前日期） |
| compliance_reg_status | 合规性(2) | 7 | 登记状态非法（不在有效值列表） |
| duplicate_name_in_task | 数据重复(3) | 1 | 同名不同企（本任务内） |
| duplicate_name_in_nest | 数据重复(3) | 2 | 同名不同企（与数巢） |
| duplicate_code_in_task | 数据重复(3) | 3 | 同企不同名（本任务内） |
| duplicate_code_in_nest | 数据重复(3) | 4 | 同企不同名（与数巢） |
| authenticity_tianyancha | 真实性(4) | 1 | 天眼查企业信息真实性验证 |

> 注：住所的合规性验证由位置服务处理，不在本模块规则范围内。

---

### 3.6 data_verify_result（数据验证结果表）

每行数据每条规则的验证结论，是 Step 2 的核心留痕表。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_id | VARCHAR(36) | NOT NULL | 关联任务 ID（冗余，便于按任务查询） |
| temp_data_id | BIGINT | NOT NULL | 关联 task_data_temp.id |
| row_no | INTEGER | NOT NULL | 行号（冗余，便于报告展示） |
| rule_code | VARCHAR(50) | NOT NULL | 验证规则编码 |
| is_pass | BOOLEAN | NOT NULL | TRUE=通过，FALSE=未通过 |
| error_field | VARCHAR(50) | | 未通过时的字段名 |
| error_value | TEXT | | 未通过时的字段值 |
| error_msg | VARCHAR(500) | | 未通过时的错误说明 |

---

### 3.7 third_api_log（第三方 API 调用日志表）

记录天眼查真实性验证的 API 调用详情，通过 `verify_result_id` 与 `data_verify_result` 1:1 关联。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| verify_result_id | BIGINT | NOT NULL, UNIQUE | 关联 data_verify_result.id |
| task_id | VARCHAR(36) | NOT NULL | 关联任务 ID（冗余） |
| temp_data_id | BIGINT | NOT NULL | 关联 task_data_temp.id（冗余） |
| api_url | VARCHAR(500) | NOT NULL | API 请求 URL |
| request_body | TEXT | | 请求内容 |
| response_body | TEXT | | 响应内容 |
| is_success | BOOLEAN | NOT NULL | API 调用是否成功 |
| error_msg | TEXT | | 调用失败时的错误信息 |
| duration_ms | BIGINT | | 调用耗时（毫秒） |
| called_at | TIMESTAMPTZ | NOT NULL | 调用时间 |

---

### 3.8 task_nest_log（任务入巢日志表）

记录 verify_status=1 的数据写入 company_fact 的操作日志，建立任务数据与数巢数据的追溯关系。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| task_id | VARCHAR(36) | NOT NULL | 关联任务 ID |
| temp_data_id | BIGINT | NOT NULL, UNIQUE | 关联 task_data_temp.id（每条数据只入巢一次） |
| row_no | INTEGER | NOT NULL | 行号（冗余） |
| fact_id | BIGINT | NOT NULL | 关联 company_fact.id |
| credit_code | VARCHAR(18) | NOT NULL | 统一社会信用代码（冗余） |
| company_name | VARCHAR(200) | NOT NULL | 企业名称（冗余） |
| nest_time | TIMESTAMPTZ | NOT NULL | 入巢时间 |

---

## 4. 公共字段规范

所有表均包含以下公共字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 自增主键 |
| is_current | BOOLEAN | 是否当前有效版本 |
| trace_id | VARCHAR(64) | 链路追踪 ID |
| owner | VARCHAR(64) | 数据归属人 |
| creater | VARCHAR(64) | 创建人 |
| create_time | TIMESTAMPTZ | 创建时间（insert 时自动写入） |
| updater | VARCHAR(64) | 修改人 |
| update_time | TIMESTAMPTZ | 修改时间（update 时自动写入） |
| remark | VARCHAR(500) | 备注 |

---

## 5. 索引设计

### task_main
- `idx_task_main_task_id` (task_id)
- `idx_task_main_task_type` (task_type_code)
- `idx_task_main_status` (task_status)
- `idx_task_main_create_time` (create_time)

### task_data_temp
- `idx_task_data_temp_task_id` (task_id)
- `idx_task_data_temp_credit_code` (credit_code)
- `idx_task_data_temp_company_name` (company_name)
- `idx_task_data_temp_verify_status` (task_id, verify_status) — Step 3 筛选入巢候选行

### data_verify_result
- `idx_verify_result_task_id` (task_id)
- `idx_verify_result_temp_data_id` (temp_data_id)
- `idx_verify_result_is_pass` (task_id, is_pass)

### third_api_log
- `idx_third_api_log_task_id` (task_id)
- `idx_third_api_log_called_at` (called_at)

### task_nest_log
- `idx_task_nest_log_task_id` (task_id)
- `idx_task_nest_log_credit_code` (credit_code)
- `idx_task_nest_log_fact_id` (fact_id)

---

## 6. 关键设计决策

**1. verify_rule_codes 存 rule_code 数组而非大类标签**

`task_type_config.default_verify_rule_codes` 和 `task_main.verify_rule_codes` 直接存储具体的 rule_code 列表（如 `["integrity_credit_code", "compliance_credit_code", ...]`），与 `data_verify_rule` 表一一对应。
需求要求"根据任务配置的校验规则列表逐条校验"——"逐条"指向具体规则，而非大类，存大类标签会引入应用层硬编码映射，破坏规则的可配置性。

**2. task_data_temp 三状态字段**

`parse_status` / `verify_status` / `nest_status` 分别标记三个 Step 的处理结论，使各步骤状态独立可查，Step 3 直接按 `verify_status=1` 过滤入巢候选行，无需聚合 `data_verify_result`。

**3. third_api_log 通过 verify_result_id 1:1 关联验证结果**

需求要求"数据真实性验证需要记录 api 的 url、request、response、调用时间"，通过 `verify_result_id` 可从验证结果直接定位 API 调用详情，也可从日志反查验证结论，形成完整追溯链。

**4. 图片场景的 row_no**

用户拉新（图片输入）每张图片 OCR 解析后生成一条企业记录，row_no 固定赋值为 1，保持与其他输入类型的字段语义一致。

**5. 住所合规性验证不在本模块**

需求明确"住所的非法性验证在位置服务处理"，`data_verify_rule` 中只包含住所的完整性规则（`integrity_address`），不定义住所的合规性规则。

---

## 7. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-05-15 | 初始版本，8 张表完整设计 |
