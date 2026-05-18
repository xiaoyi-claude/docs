# 企业名称-拉新任务实体设计说明

> 版本: v1.0
> 日期: 2026-05-15
> 数据库: PostgreSQL

---

## 1. 设计概述

### 1.1 设计目标

本设计针对企业名称服务的4种拉新任务场景，提供完整的数据实体设计，包含：
- 任务生命周期管理
- 多源数据解析与存储
- 多层级数据验证（完整性、合规性、重复性、真实性）
- 全流程处理留痕
- 与数巢（company_fact）的数据对接

### 1.2 任务类型

| 任务类型编码 | 任务类型名称 | 说明 |
|------------|------------|------|
| 1 | 基础拉新 | 结构化文件批量导入（sql/csv/xlsx/json/txt/xml） |
| 2 | 用户拉新 | 用户上传天眼查截图（png/jpg/bmp） |
| 3 | 业务拉新 | 业务系统推送企业列表数据 |
| 4 | 公司拉新 | 企业提交结构化文件（与基础拉新输入一致） |

### 1.3 处理流程

```
任务创建
    ↓
Step 1: 文件读取与解析 → 写入 task_data_temp
    ↓
Step 2: 数据验证
    ├─ 完整性验证
    ├─ 合规性验证
    ├─ 重复性验证（本任务/数巢）
    └─ 真实性验证（天眼查API）→ 写入 data_verify_result / third_api_log
    ↓
Step 3: 数据入巢 → 写入 company_fact + task_nest_log
```

---

## 2. 实体关系图

```
task_type_config (任务类型配置)
    ↑
    │ 1:N
    │
task_main (任务主表)
    ├─ 1:N → task_data_temp (任务数据临时表)
    │           ├─ 1:N → data_verify_result (数据验证结果表)
    │           └─ 1:N → third_api_log (第三方API调用日志表)
    │           └─ 1:1 → task_nest_log (任务入巢日志表)
    │
    └─ 1:N → task_step_log (任务步骤日志表)

data_verify_rule (数据验证规则表)
    ↓
    │ 1:N
    └─ data_verify_result
```

---

## 3. 数据表详细说明

### 3.1 task_type_config（任务类型配置表）

**说明**: 配置4种拉新任务类型及默认验证规则

| 字段 | 类型 | 说明 |
|------|------|------|
| task_type_code | SMALLINT | 任务类型编码:1=基础拉新,2=用户拉新,3=业务拉新,4=公司拉新 |
| task_type_name | VARCHAR(50) | 任务类型名称 |
| task_type_desc | VARCHAR(200) | 任务类型描述 |
| default_verify_rules | JSONB | 默认验证规则列表(JSON数组) |
| is_enabled | BOOLEAN | 是否启用 |

**初始化数据**:
```json
[
  {"task_type_code": 1, "task_type_name": "基础拉新", "default_verify_rules": ["integrity","compliance","duplicate","authenticity"]},
  {"task_type_code": 2, "task_type_name": "用户拉新", "default_verify_rules": ["integrity","compliance","duplicate","authenticity"]},
  {"task_type_code": 3, "task_type_name": "业务拉新", "default_verify_rules": ["integrity","compliance","duplicate","authenticity"]},
  {"task_type_code": 4, "task_type_name": "公司拉新", "default_verify_rules": ["integrity","compliance","duplicate","authenticity"]}
]
```

---

### 3.2 task_main（任务主表）

**说明**: 拉新任务的核心表，记录任务基本信息和处理状态

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 任务UUID（对外标识，唯一） |
| task_type_code | SMALLINT | 任务类型编码（关联task_type_config） |
| task_status | SMALLINT | 任务状态:0=PENDING,1=IN_PROGRESS,2=SUCCESS,3=FAILED |
| task_name | VARCHAR(200) | 任务名称 |
| input_source_type | SMALLINT | 输入来源类型:1=文件,2=图片,3=压缩包,4=OSS路径,5=直接数据 |
| input_source_path | VARCHAR(500) | 输入来源路径 |
| input_file_type | VARCHAR(20) | 输入文件类型:sql,csv,xlsx,json,txt,xml,png,jpg,bmp,zip,rar,tar,gz |
| verify_rules | JSONB | 实际执行的验证规则列表（JSON数组） |
| workflow_instance_id | VARCHAR(64) | Dapr Workflow实例ID |
| total_count | INTEGER | 总记录数 |
| success_count | INTEGER | 成功记录数 |
| fail_count | INTEGER | 失败记录数 |
| retry_count | SMALLINT | 重试次数 |
| error_msg | TEXT | 错误信息 |
| started_at | TIMESTAMPTZ | 开始处理时间 |
| completed_at | TIMESTAMPTZ | 完成时间 |

**状态流转**:
```
PENDING (0) → IN_PROGRESS (1) → SUCCESS (2)
                             → FAILED (3) [可重试]
```

---

### 3.3 task_data_temp（任务数据临时表）

**说明**: 文件读取解析后的临时数据，用于后续验证和入巢

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 关联任务ID |
| row_no | INTEGER | 行号（原始文件中的行号，任务内唯一） |
| raw_data | JSONB | 原始解析数据（完整JSON） |
| credit_code | VARCHAR(18) | 统一社会信用代码（解析后提取） |
| company_name | VARCHAR(200) | 企业名称（解析后提取） |
| legal_rep | VARCHAR(50) | 法定代表人（解析后提取） |
| found_date | DATE | 成立日期（解析后提取） |
| status | VARCHAR(50) | 登记状态（解析后提取） |
| address | VARCHAR(500) | 住所（解析后提取） |
| parse_status | SMALLINT | 解析状态:0=待处理,1=解析成功,2=解析失败 |
| parse_error_msg | VARCHAR(500) | 解析错误信息 |

**设计要点**:
- 保留完整原始数据（raw_data），便于追溯
- 提取关键字段（credit_code, company_name等），便于后续验证
- parse_status 标识解析阶段的结果

---

### 3.4 task_step_log（任务步骤日志表）

**说明**: 记录任务每一步处理的输入输出，完整留痕

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 关联任务ID |
| step_code | SMALLINT | 步骤编码:1=文件读取解析,2=数据验证,3=数据入巢 |
| step_name | VARCHAR(50) | 步骤名称 |
| step_input | JSONB | 步骤输入数据（完整快照） |
| step_output | JSONB | 步骤输出数据（完整快照） |
| step_status | SMALLINT | 步骤状态:0=PENDING,1=IN_PROGRESS,2=SUCCESS,3=FAILED |
| error_msg | TEXT | 错误信息 |
| started_at | TIMESTAMPTZ | 开始时间 |
| completed_at | TIMESTAMPTZ | 完成时间 |
| duration_ms | BIGINT | 耗时（毫秒） |

**设计要点**:
- 每一步骤的输入输出完整记录（JSON格式）
- 记录处理耗时，便于性能分析
- 可追溯每一步的处理结果，问题快速定位

---

### 3.5 data_verify_rule（数据验证规则表）

**说明**: 定义数据验证的具体规则，可配置化管理

| 字段 | 类型 | 说明 |
|------|------|------|
| rule_code | VARCHAR(50) | 规则编码（唯一标识） |
| rule_name | VARCHAR(100) | 规则名称 |
| rule_desc | VARCHAR(500) | 规则描述 |
| error_category | SMALLINT | 错误大类:1=完整性,2=合规性,3=重复性,4=真实性 |
| error_category_name | VARCHAR(50) | 错误大类名称 |
| error_type | SMALLINT | 错误小类编码 |
| error_type_name | VARCHAR(50) | 错误小类名称 |
| verify_expression | TEXT | 验证表达式（SQL或规则引擎表达式） |
| is_enabled | BOOLEAN | 是否启用 |
| sort_order | INTEGER | 排序号（执行顺序） |

**验证规则分类**:

#### 错误大类 1: 完整性验证错误
| error_type | error_type_name | 说明 |
|-----------|----------------|------|
| 1 | 统一社会信用代码缺失 | credit_code 为空 |
| 2 | 企业名称缺失 | company_name 为空 |
| 3 | 法定代表人缺失 | legal_rep 为空 |
| 4 | 成立日期缺失 | found_date 为空 |
| 5 | 登记状态缺失 | status 为空 |
| 6 | 住所缺失 | address 为空 |

#### 错误大类 2: 合规性验证错误
| error_type | error_type_name | 说明 |
|-----------|----------------|------|
| 1 | 统一社会信用代码非法 | 格式不符合GB 32100-2015 |
| 2 | 企业名称字符合法 | 只能是汉字+括号 |
| 3 | 企业名称长度非法 | 不在4-26字之间 |
| 4 | 法定代表人字符合法 | 只能是汉字 |
| 5 | 法定代表人长度非法 | 不在2-5字之间 |
| 6 | 成立日期非法 | 大于当前日期 |
| 7 | 登记状态非法 | 不在有效值列表 |

#### 错误大类 3: 数据重复
| error_type | error_type_name | 说明 |
|-----------|----------------|------|
| 1 | 同名不同企（本任务） | 同一任务内，相同名称不同信用代码 |
| 2 | 同名不同企（数巢） | 与数巢中，相同名称不同信用代码 |
| 3 | 同企不同名（本任务） | 同一任务内，相同信用代码不同名称 |
| 4 | 同企不同名（数巢） | 与数巢中，相同信用代码不同名称 |

#### 错误大类 4: 数据真实性验证
| error_type | error_type_name | 说明 |
|-----------|----------------|------|
| 1 | 天眼查验证 | 调用天眼查API验证企业信息真实性 |

---

### 3.6 data_verify_result（数据验证结果表）

**说明**: 每条数据每条规则的验证结果，详细留痕

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 关联任务ID |
| temp_data_id | BIGINT | 关联task_data_temp的ID |
| row_no | INTEGER | 行号（冗余，便于查询） |
| rule_code | VARCHAR(50) | 验证规则编码 |
| rule_name | VARCHAR(100) | 验证规则名称（冗余） |
| error_category | SMALLINT | 错误大类（冗余） |
| error_category_name | VARCHAR(50) | 错误大类名称（冗余） |
| error_type | SMALLINT | 错误小类编码（冗余） |
| error_type_name | VARCHAR(50) | 错误小类名称（冗余） |
| verify_result | BOOLEAN | 验证结果:TRUE=通过,FALSE=不通过 |
| error_field | VARCHAR(50) | 错误字段名 |
| error_value | TEXT | 错误字段值 |
| error_msg | VARCHAR(500) | 错误信息 |

**设计要点**:
- 逐条数据逐条规则记录，验证粒度精确
- 冗余规则相关字段，避免JOIN查询，提高查询性能
- 记录错误字段和值，便于问题定位和数据修复

---

### 3.7 third_api_log（第三方API调用日志表）

**说明**: 记录天眼查等第三方API调用的详细信息

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 关联任务ID |
| temp_data_id | BIGINT | 关联task_data_temp的ID |
| api_name | VARCHAR(100) | API名称 |
| api_provider | VARCHAR(50) | API提供商:tianyancha=天眼查 |
| api_url | VARCHAR(500) | API请求URL |
| request_method | VARCHAR(10) | 请求方法:GET,POST等 |
| request_headers | JSONB | 请求头（JSON） |
| request_body | TEXT | 请求体 |
| response_status | INTEGER | 响应状态码 |
| response_headers | JSONB | 响应头（JSON） |
| response_body | TEXT | 响应体 |
| is_success | BOOLEAN | 调用是否成功 |
| error_msg | TEXT | 错误信息 |
| duration_ms | BIGINT | 耗时（毫秒） |
| called_at | TIMESTAMPTZ | 调用时间 |

**设计要点**:
- 完整记录HTTP请求响应的所有要素
- 可追溯每一次API调用的详细情况
- 支持调用成功/失败的统计分析
- 支持按时间范围、提供商等维度查询

---

### 3.8 task_nest_log（任务入巢日志表）

**说明**: 记录数据成功入巢的日志，关联任务与数巢数据

| 字段 | 类型 | 说明 |
|------|------|------|
| task_id | VARCHAR(36) | 关联任务ID |
| temp_data_id | BIGINT | 关联task_data_temp的ID |
| row_no | INTEGER | 行号（冗余） |
| ent_code | VARCHAR(36) | 企业UUID（关联company_fact） |
| credit_code | VARCHAR(18) | 统一社会信用代码（冗余） |
| company_name | VARCHAR(200) | 企业名称（冗余） |
| fact_id | BIGINT | 关联company_fact表的ID |
| nest_time | TIMESTAMPTZ | 入巢时间 |

**设计要点**:
- 建立任务数据与数巢数据的关联桥梁
- 可追溯哪条数据通过哪个任务在什么时间入巢
- 冗余关键字段，便于快速查询

---

## 4. 公共字段规范

所有数据表均包含以下公共字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 自增主键（内部排序，禁止插队） |
| is_current | BOOLEAN | 是否当前有效版本（用于多版本数据） |
| trace_id | VARCHAR(64) | 日志链路追踪ID |
| owner | VARCHAR(64) | 数据拥有人（用于数据权限控制） |
| creater | VARCHAR(64) | 创建人 |
| create_time | TIMESTAMPTZ | 创建时间（DB insert时自动写入） |
| updater | VARCHAR(64) | 修改人 |
| update_time | TIMESTAMPTZ | 修改时间（DB update时自动写入） |
| remark | VARCHAR(500) | 备注 |

---

## 5. 索引设计

### 5.1 task_main 索引
- idx_task_main_task_id (task_id)
- idx_task_main_task_type_code (task_type_code)
- idx_task_main_task_status (task_status)
- idx_task_main_create_time (create_time)

### 5.2 task_data_temp 索引
- idx_task_data_temp_task_id (task_id)
- idx_task_data_temp_credit_code (credit_code)
- idx_task_data_temp_company_name (company_name)

### 5.3 data_verify_result 索引
- idx_data_verify_result_task_id (task_id)
- idx_data_verify_result_temp_data_id (temp_data_id)
- idx_data_verify_result_rule_code (rule_code)
- idx_data_verify_result_verify_result (verify_result)
- idx_data_verify_result_error_category (error_category)

### 5.4 third_api_log 索引
- idx_third_api_log_task_id (task_id)
- idx_third_api_log_temp_data_id (temp_data_id)
- idx_third_api_log_api_provider (api_provider)
- idx_third_api_log_is_success (is_success)
- idx_third_api_log_called_at (called_at)

### 5.5 task_nest_log 索引
- idx_task_nest_log_task_id (task_id)
- idx_task_nest_log_ent_code (ent_code)
- idx_task_nest_log_credit_code (credit_code)
- idx_task_nest_log_fact_id (fact_id)

---

## 6. 典型查询场景

### 6.1 查询任务处理进度
```sql
SELECT
    task_id,
    task_name,
    task_status,
    total_count,
    success_count,
    fail_count,
    started_at,
    completed_at
FROM task_main
WHERE task_id = 'xxx';
```

### 6.2 查询某任务的所有验证失败记录
```sql
SELECT
    dvr.row_no,
    dvr.rule_name,
    dvr.error_category_name,
    dvr.error_type_name,
    dvr.error_field,
    dvr.error_value,
    dvr.error_msg
FROM data_verify_result dvr
WHERE dvr.task_id = 'xxx'
  AND dvr.verify_result = FALSE
ORDER BY dvr.row_no, dvr.id;
```

### 6.3 查询某任务的API调用统计
```sql
SELECT
    api_provider,
    COUNT(*) as total_calls,
    SUM(CASE WHEN is_success THEN 1 ELSE 0 END) as success_calls,
    AVG(duration_ms) as avg_duration_ms
FROM third_api_log
WHERE task_id = 'xxx'
GROUP BY api_provider;
```

### 6.4 查询某企业的入巢来源任务
```sql
SELECT
    tnl.task_id,
    tm.task_name,
    tnl.nest_time
FROM task_nest_log tnl
JOIN task_main tm ON tnl.task_id = tm.task_id
WHERE tnl.credit_code = '91110000XXXXXXXXXX'
ORDER BY tnl.nest_time DESC;
```

---

## 7. 数据清理策略

### 7.1 临时数据清理
- task_data_temp: 任务完成后保留30天，然后归档或清理
- data_verify_result: 任务完成后保留90天，然后归档或清理
- third_api_log: 保留180天，然后归档或清理
- task_step_log: 保留180天，然后归档或清理

### 7.2 永久保留数据
- task_main: 永久保留（任务元数据）
- task_type_config: 永久保留（配置数据）
- data_verify_rule: 永久保留（配置数据）
- task_nest_log: 永久保留（入巢追溯数据）

---

## 8. 与现有表的关系

### 8.1 与 company_fact 的关系
- task_nest_log.fact_id → company_fact.id
- task_nest_log.ent_code → company_fact.ent_code
- task_nest_log.credit_code → company_fact.credit_code

### 8.2 与架构设计的对应关系
本设计对应架构设计中的以下模块：
- business层: eiker-company-update（拉新服务）
- atomic层: 数据验证逻辑、文件解析逻辑、API调用逻辑

---

## 9. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-05-15 | 初始版本，完成8张表的完整设计 |
