-- =============================================
-- 企业名称-拉新任务实体表结构设计
-- 版本: v1.0
-- 日期: 2026-05-15
-- 数据库: PostgreSQL
-- 说明: 企业名称拉新任务相关表，包含任务管理、数据验证、处理日志
-- =============================================

-- =============================================
-- 公共字段说明:
--   id              - 自增主键（内部排序，禁止插队）
--   is_current      - 是否当前有效版本（用于多版本数据）
--   trace_id        - 日志链路追踪ID
--   owner           - 数据拥有人（用于数据权限控制）
--   creater         - 创建人
--   create_time     - 创建时间（DB insert 时自动写入）
--   updater         - 修改人
--   update_time     - 修改时间（DB update 时自动写入）
--   remark          - 备注
-- =============================================

-- =============================================
-- 1. 任务类型配置表
-- 说明: 配置4种拉新任务类型及默认验证规则
-- =============================================
CREATE TABLE IF NOT EXISTS task_type_config (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_type_code      SMALLINT                    NOT NULL UNIQUE,
    task_type_name      VARCHAR(50)                 NOT NULL,
    task_type_desc      VARCHAR(200),
    default_verify_rules JSONB,
    is_enabled          BOOLEAN                     NOT NULL DEFAULT TRUE,

    -- 约束
    CONSTRAINT ck_task_type_code CHECK (task_type_code IN (1, 2, 3, 4))
);

COMMENT ON TABLE task_type_config IS '任务类型配置表';
COMMENT ON COLUMN task_type_config.id IS '自增主键';
COMMENT ON COLUMN task_type_config.is_current IS '是否当前有效版本';
COMMENT ON COLUMN task_type_config.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN task_type_config.owner IS '数据拥有人';
COMMENT ON COLUMN task_type_config.creater IS '创建人';
COMMENT ON COLUMN task_type_config.create_time IS '创建时间';
COMMENT ON COLUMN task_type_config.updater IS '修改人';
COMMENT ON COLUMN task_type_config.update_time IS '修改时间';
COMMENT ON COLUMN task_type_config.remark IS '备注';
COMMENT ON COLUMN task_type_config.task_type_code IS '任务类型编码:1=基础拉新,2=用户拉新,3=业务拉新,4=公司拉新';
COMMENT ON COLUMN task_type_config.task_type_name IS '任务类型名称';
COMMENT ON COLUMN task_type_config.task_type_desc IS '任务类型描述';
COMMENT ON COLUMN task_type_config.default_verify_rules IS '默认验证规则列表(JSON数组)';
COMMENT ON COLUMN task_type_config.is_enabled IS '是否启用';

-- 初始化任务类型数据
INSERT INTO task_type_config (task_type_code, task_type_name, task_type_desc, default_verify_rules, creater) VALUES
(1, '基础拉新', '结构化文件批量导入拉新', '["integrity","compliance","duplicate","authenticity"]', 'system'),
(2, '用户拉新', '用户上传天眼查截图拉新', '["integrity","compliance","duplicate","authenticity"]', 'system'),
(3, '业务拉新', '业务系统推送企业列表拉新', '["integrity","compliance","duplicate","authenticity"]', 'system'),
(4, '公司拉新', '企业提交结构化文件拉新', '["integrity","compliance","duplicate","authenticity"]', 'system');

-- =============================================
-- 2. 任务主表
-- 说明: 拉新任务的核心表，记录任务基本信息
-- =============================================
CREATE TABLE IF NOT EXISTS task_main (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL UNIQUE,
    task_type_code      SMALLINT                    NOT NULL,
    task_status         SMALLINT                    NOT NULL DEFAULT 0,
    task_name           VARCHAR(200),
    input_source_type   SMALLINT                    NOT NULL,
    input_source_path   VARCHAR(500),
    input_file_type      VARCHAR(20),
    verify_rules        JSONB,
    workflow_instance_id VARCHAR(64),
    total_count         INTEGER                     DEFAULT 0,
    success_count       INTEGER                     DEFAULT 0,
    fail_count          INTEGER                     DEFAULT 0,
    retry_count         SMALLINT                    DEFAULT 0,
    error_msg           TEXT,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,

    -- 约束
    CONSTRAINT fk_task_type_code FOREIGN KEY (task_type_code) REFERENCES task_type_config(task_type_code),
    CONSTRAINT ck_task_status CHECK (task_status IN (0, 1, 2, 3)),
    CONSTRAINT ck_input_source_type CHECK (input_source_type IN (1, 2, 3, 4, 5))
);

COMMENT ON TABLE task_main IS '任务主表';
COMMENT ON COLUMN task_main.id IS '自增主键';
COMMENT ON COLUMN task_main.is_current IS '是否当前有效版本';
COMMENT ON COLUMN task_main.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN task_main.owner IS '数据拥有人';
COMMENT ON COLUMN task_main.creater IS '创建人';
COMMENT ON COLUMN task_main.create_time IS '创建时间';
COMMENT ON COLUMN task_main.updater IS '修改人';
COMMENT ON COLUMN task_main.update_time IS '修改时间';
COMMENT ON COLUMN task_main.remark IS '备注';
COMMENT ON COLUMN task_main.task_id IS '任务UUID（对外标识）';
COMMENT ON COLUMN task_main.task_type_code IS '任务类型编码:1=基础拉新,2=用户拉新,3=业务拉新,4=公司拉新';
COMMENT ON COLUMN task_main.task_status IS '任务状态:0=PENDING,1=IN_PROGRESS,2=SUCCESS,3=FAILED';
COMMENT ON COLUMN task_main.task_name IS '任务名称';
COMMENT ON COLUMN task_main.input_source_type IS '输入来源类型:1=文件,2=图片,3=压缩包,4=OSS路径,5=直接数据';
COMMENT ON COLUMN task_main.input_source_path IS '输入来源路径（文件路径/图片路径/OSS路径）';
COMMENT ON COLUMN task_main.input_file_type IS '输入文件类型:sql,csv,xlsx,json,txt,xml,png,jpg,bmp,zip,rar,tar,gz';
COMMENT ON COLUMN task_main.verify_rules IS '验证规则列表（JSON数组）';
COMMENT ON COLUMN task_main.workflow_instance_id IS 'Dapr Workflow实例ID';
COMMENT ON COLUMN task_main.total_count IS '总记录数';
COMMENT ON COLUMN task_main.success_count IS '成功记录数';
COMMENT ON COLUMN task_main.fail_count IS '失败记录数';
COMMENT ON COLUMN task_main.retry_count IS '重试次数';
COMMENT ON COLUMN task_main.error_msg IS '错误信息';
COMMENT ON COLUMN task_main.started_at IS '开始处理时间';
COMMENT ON COLUMN task_main.completed_at IS '完成时间';

-- 索引
CREATE INDEX idx_task_main_task_id ON task_main(task_id);
CREATE INDEX idx_task_main_task_type_code ON task_main(task_type_code);
CREATE INDEX idx_task_main_task_status ON task_main(task_status);
CREATE INDEX idx_task_main_create_time ON task_main(create_time);

-- =============================================
-- 3. 任务数据临时表
-- 说明: 文件读取解析后的临时数据，用于后续验证和入巢
-- =============================================
CREATE TABLE IF NOT EXISTS task_data_temp (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL,
    row_no              INTEGER                     NOT NULL,
    raw_data            JSONB                       NOT NULL,
    credit_code         VARCHAR(18),
    company_name        VARCHAR(200),
    legal_rep           VARCHAR(50),
    found_date          DATE,
    status              VARCHAR(50),
    address             VARCHAR(500),
    parse_status        SMALLINT                    NOT NULL DEFAULT 0,
    parse_error_msg     VARCHAR(500),

    -- 约束
    CONSTRAINT uk_task_row UNIQUE (task_id, row_no)
);

COMMENT ON TABLE task_data_temp IS '任务数据临时表';
COMMENT ON COLUMN task_data_temp.id IS '自增主键';
COMMENT ON COLUMN task_data_temp.is_current IS '是否当前有效版本';
COMMENT ON COLUMN task_data_temp.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN task_data_temp.owner IS '数据拥有人';
COMMENT ON COLUMN task_data_temp.creater IS '创建人';
COMMENT ON COLUMN task_data_temp.create_time IS '创建时间';
COMMENT ON COLUMN task_data_temp.updater IS '修改人';
COMMENT ON COLUMN task_data_temp.update_time IS '修改时间';
COMMENT ON COLUMN task_data_temp.remark IS '备注';
COMMENT ON COLUMN task_data_temp.task_id IS '关联任务ID';
COMMENT ON COLUMN task_data_temp.row_no IS '行号（原始文件中的行号）';
COMMENT ON COLUMN task_data_temp.raw_data IS '原始解析数据（JSON）';
COMMENT ON COLUMN task_data_temp.credit_code IS '统一社会信用代码';
COMMENT ON COLUMN task_data_temp.company_name IS '企业名称';
COMMENT ON COLUMN task_data_temp.legal_rep IS '法定代表人';
COMMENT ON COLUMN task_data_temp.found_date IS '成立日期';
COMMENT ON COLUMN task_data_temp.status IS '登记状态';
COMMENT ON COLUMN task_data_temp.address IS '住所';
COMMENT ON COLUMN task_data_temp.parse_status IS '解析状态:0=待处理,1=解析成功,2=解析失败';
COMMENT ON COLUMN task_data_temp.parse_error_msg IS '解析错误信息';

-- 索引
CREATE INDEX idx_task_data_temp_task_id ON task_data_temp(task_id);
CREATE INDEX idx_task_data_temp_credit_code ON task_data_temp(credit_code);
CREATE INDEX idx_task_data_temp_company_name ON task_data_temp(company_name);

-- =============================================
-- 4. 任务步骤日志表
-- 说明: 记录任务每一步处理的输入输出，完整留痕
-- =============================================
CREATE TABLE IF NOT EXISTS task_step_log (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL,
    step_code           SMALLINT                    NOT NULL,
    step_name           VARCHAR(50)                 NOT NULL,
    step_input          JSONB                       NOT NULL,
    step_output         JSONB,
    step_status         SMALLINT                    NOT NULL DEFAULT 0,
    error_msg           TEXT,
    started_at          TIMESTAMPTZ                 NOT NULL,
    completed_at        TIMESTAMPTZ,
    duration_ms         BIGINT,

    -- 约束
    CONSTRAINT ck_step_code CHECK (step_code IN (1, 2, 3)),
    CONSTRAINT ck_step_status CHECK (step_status IN (0, 1, 2, 3))
);

COMMENT ON TABLE task_step_log IS '任务步骤日志表';
COMMENT ON COLUMN task_step_log.id IS '自增主键';
COMMENT ON COLUMN task_step_log.is_current IS '是否当前有效版本';
COMMENT ON COLUMN task_step_log.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN task_step_log.owner IS '数据拥有人';
COMMENT ON COLUMN task_step_log.creater IS '创建人';
COMMENT ON COLUMN task_step_log.create_time IS '创建时间';
COMMENT ON COLUMN task_step_log.updater IS '修改人';
COMMENT ON COLUMN task_step_log.update_time IS '修改时间';
COMMENT ON COLUMN task_step_log.remark IS '备注';
COMMENT ON COLUMN task_step_log.task_id IS '关联任务ID';
COMMENT ON COLUMN task_step_log.step_code IS '步骤编码:1=文件读取解析,2=数据验证,3=数据入巢';
COMMENT ON COLUMN task_step_log.step_name IS '步骤名称';
COMMENT ON COLUMN task_step_log.step_input IS '步骤输入数据';
COMMENT ON COLUMN task_step_log.step_output IS '步骤输出数据';
COMMENT ON COLUMN task_step_log.step_status IS '步骤状态:0=PENDING,1=IN_PROGRESS,2=SUCCESS,3=FAILED';
COMMENT ON COLUMN task_step_log.error_msg IS '错误信息';
COMMENT ON COLUMN task_step_log.started_at IS '开始时间';
COMMENT ON COLUMN task_step_log.completed_at IS '完成时间';
COMMENT ON COLUMN task_step_log.duration_ms IS '耗时（毫秒）';

-- 索引
CREATE INDEX idx_task_step_log_task_id ON task_step_log(task_id);
CREATE INDEX idx_task_step_log_step_code ON task_step_log(step_code);
CREATE INDEX idx_task_step_log_step_status ON task_step_log(step_status);
CREATE INDEX idx_task_step_log_create_time ON task_step_log(create_time);

-- =============================================
-- 5. 数据验证规则表
-- 说明: 定义数据验证的具体规则
-- =============================================
CREATE TABLE IF NOT EXISTS data_verify_rule (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    rule_code           VARCHAR(50)                 NOT NULL UNIQUE,
    rule_name           VARCHAR(100)                NOT NULL,
    rule_desc           VARCHAR(500),
    error_category      SMALLINT                    NOT NULL,
    error_category_name VARCHAR(50)                 NOT NULL,
    error_type          SMALLINT                    NOT NULL,
    error_type_name     VARCHAR(50)                 NOT NULL,
    verify_expression   TEXT,
    is_enabled          BOOLEAN                     NOT NULL DEFAULT TRUE,
    sort_order          INTEGER                     NOT NULL DEFAULT 0
);

COMMENT ON TABLE data_verify_rule IS '数据验证规则表';
COMMENT ON COLUMN data_verify_rule.id IS '自增主键';
COMMENT ON COLUMN data_verify_rule.is_current IS '是否当前有效版本';
COMMENT ON COLUMN data_verify_rule.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN data_verify_rule.owner IS '数据拥有人';
COMMENT ON COLUMN data_verify_rule.creater IS '创建人';
COMMENT ON COLUMN data_verify_rule.create_time IS '创建时间';
COMMENT ON COLUMN data_verify_rule.updater IS '修改人';
COMMENT ON COLUMN data_verify_rule.update_time IS '修改时间';
COMMENT ON COLUMN data_verify_rule.remark IS '备注';
COMMENT ON COLUMN data_verify_rule.rule_code IS '规则编码';
COMMENT ON COLUMN data_verify_rule.rule_name IS '规则名称';
COMMENT ON COLUMN data_verify_rule.rule_desc IS '规则描述';
COMMENT ON COLUMN data_verify_rule.error_category IS '错误大类:1=完整性验证错误,2=合规性验证错误,3=数据重复,4=数据真实性验证';
COMMENT ON COLUMN data_verify_rule.error_category_name IS '错误大类名称';
COMMENT ON COLUMN data_verify_rule.error_type IS '错误小类编码';
COMMENT ON COLUMN data_verify_rule.error_type_name IS '错误小类名称';
COMMENT ON COLUMN data_verify_rule.verify_expression IS '验证表达式';
COMMENT ON COLUMN data_verify_rule.is_enabled IS '是否启用';
COMMENT ON COLUMN data_verify_rule.sort_order IS '排序号';

-- 初始化验证规则数据
INSERT INTO data_verify_rule (rule_code, rule_name, rule_desc, error_category, error_category_name, error_type, error_type_name, verify_expression, sort_order, creater) VALUES
-- 完整性验证错误
('integrity_credit_code', '统一社会信用代码不能为空', '验证统一社会信用代码字段是否为空', 1, '完整性验证错误', 1, '统一社会信用代码缺失', 'credit_code IS NOT NULL AND TRIM(credit_code) <> '''''', 1, 'system'),
('integrity_company_name', '企业名称不能为空', '验证企业名称字段是否为空', 1, '完整性验证错误', 2, '企业名称缺失', 'company_name IS NOT NULL AND TRIM(company_name) <> '''''', 2, 'system'),
('integrity_legal_rep', '法定代表人不能为空', '验证法定代表人字段是否为空', 1, '完整性验证错误', 3, '法定代表人缺失', 'legal_rep IS NOT NULL AND TRIM(legal_rep) <> '''''', 3, 'system'),
('integrity_found_date', '成立日期不能为空', '验证成立日期字段是否为空', 1, '完整性验证错误', 4, '成立日期缺失', 'found_date IS NOT NULL', 4, 'system'),
('integrity_status', '登记状态不能为空', '验证登记状态字段是否为空', 1, '完整性验证错误', 5, '登记状态缺失', 'status IS NOT NULL AND TRIM(status) <> '''''', 5, 'system'),
('integrity_address', '住所不能为空', '验证住所字段是否为空', 1, '完整性验证错误', 6, '住所缺失', 'address IS NOT NULL AND TRIM(address) <> '''''', 6, 'system'),

-- 合规性验证错误
('compliance_credit_code_format', '统一社会信用代码格式验证', '验证统一社会信用代码格式是否符合GB 32100-2015标准', 2, '合规性验证错误', 1, '统一社会信用代码非法', 'credit_code ~ ''^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$'' AND SUBSTRING(credit_code, 1, 2) IN (''91'', ''92'', ''12'')', 10, 'system'),
('compliance_company_name_format', '企业名称字符合规性', '验证企业名称字符合法性', 2, '合规性验证错误', 2, '企业名称字符合法', 'company_name ~ ''^[\u4e00-\u9fa5（）()]+$''', 11, 'system'),
('compliance_company_name_length', '企业名称长度验证', '验证企业名称长度是否在4-26字之间', 2, '合规性验证错误', 3, '企业名称长度非法', 'LENGTH(company_name) >= 4 AND LENGTH(company_name) <= 26', 12, 'system'),
('compliance_legal_rep_format', '法定代表人字符合规性', '验证法定代表人字符合法性', 2, '合规性验证错误', 4, '法定代表人字符合法', 'legal_rep ~ ''^[\u4e00-\u9fa5]+$''', 13, 'system'),
('compliance_legal_rep_length', '法定代表人长度验证', '验证法定代表人长度是否在2-5字之间', 2, '合规性验证错误', 5, '法定代表人长度非法', 'LENGTH(legal_rep) >= 2 AND LENGTH(legal_rep) <= 5', 14, 'system'),
('compliance_found_date', '成立日期验证', '验证成立日期是否为有效日期', 2, '合规性验证错误', 6, '成立日期非法', 'found_date <= CURRENT_DATE', 15, 'system'),
('compliance_status', '登记状态验证', '验证登记状态是否为有效值', 2, '合规性验证错误', 7, '登记状态非法', 'status IN (''存续'', ''在营'', ''开业'', ''在册'', ''吊销'', ''注销'', ''迁出'', ''停业'', ''清算'')', 16, 'system'),

-- 数据重复验证
('duplicate_same_name_diff_company_local', '同名不同企（本任务）', '验证本任务内是否存在同名不同企情况', 3, '数据重复', 1, '同名不同企（本任务）', 'EXISTS (SELECT 1 FROM task_data_temp t2 WHERE t2.task_id = task_data_temp.task_id AND t2.company_name = task_data_temp.company_name AND t2.credit_code <> task_data_temp.credit_code)', 20, 'system'),
('duplicate_same_name_diff_company_nest', '同名不同企（数巢）', '验证与数巢中是否存在同名不同企情况', 3, '数据重复', 2, '同名不同企（数巢）', 'EXISTS (SELECT 1 FROM company_fact cf WHERE cf.name = task_data_temp.company_name AND cf.credit_code <> task_data_temp.credit_code AND cf.is_current = TRUE)', 21, 'system'),
('duplicate_same_company_diff_name_local', '同企不同名（本任务）', '验证本任务内是否存在同企不同名情况', 3, '数据重复', 3, '同企不同名（本任务）', 'EXISTS (SELECT 1 FROM task_data_temp t2 WHERE t2.task_id = task_data_temp.task_id AND t2.credit_code = task_data_temp.credit_code AND t2.company_name <> task_data_temp.company_name)', 22, 'system'),
('duplicate_same_company_diff_name_nest', '同企不同名（数巢）', '验证与数巢中是否存在同企不同名情况', 3, '数据重复', 4, '同企不同名（数巢）', 'EXISTS (SELECT 1 FROM company_fact cf WHERE cf.credit_code = task_data_temp.credit_code AND cf.name <> task_data_temp.company_name AND cf.is_current = TRUE)', 23, 'system'),

-- 数据真实性验证
('authenticity_tianyancha', '天眼查真实性验证', '调用天眼查API验证企业信息真实性', 4, '数据真实性验证', 1, '天眼查验证', '需要调用API验证', 30, 'system');

-- =============================================
-- 6. 数据验证结果表
-- 说明: 每条数据每条规则的验证结果，详细留痕
-- =============================================
CREATE TABLE IF NOT EXISTS data_verify_result (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL,
    temp_data_id        BIGINT                      NOT NULL,
    row_no              INTEGER                     NOT NULL,
    rule_code           VARCHAR(50)                 NOT NULL,
    rule_name           VARCHAR(100)                NOT NULL,
    error_category      SMALLINT                    NOT NULL,
    error_category_name VARCHAR(50)                 NOT NULL,
    error_type          SMALLINT                    NOT NULL,
    error_type_name     VARCHAR(50)                 NOT NULL,
    verify_result       BOOLEAN                     NOT NULL,
    error_field         VARCHAR(50),
    error_value         TEXT,
    error_msg           VARCHAR(500)
);

COMMENT ON TABLE data_verify_result IS '数据验证结果表';
COMMENT ON COLUMN data_verify_result.id IS '自增主键';
COMMENT ON COLUMN data_verify_result.is_current IS '是否当前有效版本';
COMMENT ON COLUMN data_verify_result.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN data_verify_result.owner IS '数据拥有人';
COMMENT ON COLUMN data_verify_result.creater IS '创建人';
COMMENT ON COLUMN data_verify_result.create_time IS '创建时间';
COMMENT ON COLUMN data_verify_result.updater IS '修改人';
COMMENT ON COLUMN data_verify_result.update_time IS '修改时间';
COMMENT ON COLUMN data_verify_result.remark IS '备注';
COMMENT ON COLUMN data_verify_result.task_id IS '关联任务ID';
COMMENT ON COLUMN data_verify_result.temp_data_id IS '关联任务数据临时表ID';
COMMENT ON COLUMN data_verify_result.row_no IS '行号';
COMMENT ON COLUMN data_verify_result.rule_code IS '验证规则编码';
COMMENT ON COLUMN data_verify_result.rule_name IS '验证规则名称';
COMMENT ON COLUMN data_verify_result.error_category IS '错误大类:1=完整性验证错误,2=合规性验证错误,3=数据重复,4=数据真实性验证';
COMMENT ON COLUMN data_verify_result.error_category_name IS '错误大类名称';
COMMENT ON COLUMN data_verify_result.error_type IS '错误小类编码';
COMMENT ON COLUMN data_verify_result.error_type_name IS '错误小类名称';
COMMENT ON COLUMN data_verify_result.verify_result IS '验证结果:TRUE=通过,FALSE=不通过';
COMMENT ON COLUMN data_verify_result.error_field IS '错误字段名';
COMMENT ON COLUMN data_verify_result.error_value IS '错误字段值';
COMMENT ON COLUMN data_verify_result.error_msg IS '错误信息';

-- 索引
CREATE INDEX idx_data_verify_result_task_id ON data_verify_result(task_id);
CREATE INDEX idx_data_verify_result_temp_data_id ON data_verify_result(temp_data_id);
CREATE INDEX idx_data_verify_result_rule_code ON data_verify_result(rule_code);
CREATE INDEX idx_data_verify_result_verify_result ON data_verify_result(verify_result);
CREATE INDEX idx_data_verify_result_error_category ON data_verify_result(error_category);

-- =============================================
-- 7. 第三方API调用日志表
-- 说明: 记录天眼查等第三方API调用的详细信息
-- =============================================
CREATE TABLE IF NOT EXISTS third_api_log (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL,
    temp_data_id        BIGINT                      NOT NULL,
    api_name            VARCHAR(100)                NOT NULL,
    api_provider        VARCHAR(50)                 NOT NULL,
    api_url             VARCHAR(500)                NOT NULL,
    request_method      VARCHAR(10)                 NOT NULL,
    request_headers     JSONB,
    request_body        TEXT,
    response_status     INTEGER,
    response_headers    JSONB,
    response_body       TEXT,
    is_success          BOOLEAN                     NOT NULL,
    error_msg           TEXT,
    duration_ms         BIGINT,
    called_at           TIMESTAMPTZ                 NOT NULL
);

COMMENT ON TABLE third_api_log IS '第三方API调用日志表';
COMMENT ON COLUMN third_api_log.id IS '自增主键';
COMMENT ON COLUMN third_api_log.is_current IS '是否当前有效版本';
COMMENT ON COLUMN third_api_log.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN third_api_log.owner IS '数据拥有人';
COMMENT ON COLUMN third_api_log.creater IS '创建人';
COMMENT ON COLUMN third_api_log.create_time IS '创建时间';
COMMENT ON COLUMN third_api_log.updater IS '修改人';
COMMENT ON COLUMN third_api_log.update_time IS '修改时间';
COMMENT ON COLUMN third_api_log.remark IS '备注';
COMMENT ON COLUMN third_api_log.task_id IS '关联任务ID';
COMMENT ON COLUMN third_api_log.temp_data_id IS '关联任务数据临时表ID';
COMMENT ON COLUMN third_api_log.api_name IS 'API名称';
COMMENT ON COLUMN third_api_log.api_provider IS 'API提供商:tianyancha=天眼查';
COMMENT ON COLUMN third_api_log.api_url IS 'API请求URL';
COMMENT ON COLUMN third_api_log.request_method IS '请求方法:GET,POST等';
COMMENT ON COLUMN third_api_log.request_headers IS '请求头（JSON）';
COMMENT ON COLUMN third_api_log.request_body IS '请求体';
COMMENT ON COLUMN third_api_log.response_status IS '响应状态码';
COMMENT ON COLUMN third_api_log.response_headers IS '响应头（JSON）';
COMMENT ON COLUMN third_api_log.response_body IS '响应体';
COMMENT ON COLUMN third_api_log.is_success IS '调用是否成功';
COMMENT ON COLUMN third_api_log.error_msg IS '错误信息';
COMMENT ON COLUMN third_api_log.duration_ms IS '耗时（毫秒）';
COMMENT ON COLUMN third_api_log.called_at IS '调用时间';

-- 索引
CREATE INDEX idx_third_api_log_task_id ON third_api_log(task_id);
CREATE INDEX idx_third_api_log_temp_data_id ON third_api_log(temp_data_id);
CREATE INDEX idx_third_api_log_api_provider ON third_api_log(api_provider);
CREATE INDEX idx_third_api_log_is_success ON third_api_log(is_success);
CREATE INDEX idx_third_api_log_called_at ON third_api_log(called_at);

-- =============================================
-- 8. 任务入巢日志表
-- 说明: 记录数据成功入巢的日志
-- =============================================
CREATE TABLE IF NOT EXISTS task_nest_log (
    -- 公共字段
    id                  BIGSERIAL                   PRIMARY KEY,
    is_current          BOOLEAN                     NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    -- 业务字段
    task_id             VARCHAR(36)                 NOT NULL,
    temp_data_id        BIGINT                      NOT NULL,
    row_no              INTEGER                     NOT NULL,
    ent_code            VARCHAR(36)                 NOT NULL,
    credit_code         VARCHAR(18)                 NOT NULL,
    company_name        VARCHAR(200)                NOT NULL,
    fact_id             BIGINT                      NOT NULL,
    nest_time           TIMESTAMPTZ                 NOT NULL,

    -- 约束
    CONSTRAINT uk_task_nest UNIQUE (task_id, temp_data_id)
);

COMMENT ON TABLE task_nest_log IS '任务入巢日志表';
COMMENT ON COLUMN task_nest_log.id IS '自增主键';
COMMENT ON COLUMN task_nest_log.is_current IS '是否当前有效版本';
COMMENT ON COLUMN task_nest_log.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN task_nest_log.owner IS '数据拥有人';
COMMENT ON COLUMN task_nest_log.creater IS '创建人';
COMMENT ON COLUMN task_nest_log.create_time IS '创建时间';
COMMENT ON COLUMN task_nest_log.updater IS '修改人';
COMMENT ON COLUMN task_nest_log.update_time IS '修改时间';
COMMENT ON COLUMN task_nest_log.remark IS '备注';
COMMENT ON COLUMN task_nest_log.task_id IS '关联任务ID';
COMMENT ON COLUMN task_nest_log.temp_data_id IS '关联任务数据临时表ID';
COMMENT ON COLUMN task_nest_log.row_no IS '行号';
COMMENT ON COLUMN task_nest_log.ent_code IS '企业UUID';
COMMENT ON COLUMN task_nest_log.credit_code IS '统一社会信用代码';
COMMENT ON COLUMN task_nest_log.company_name IS '企业名称';
COMMENT ON COLUMN task_nest_log.fact_id IS '关联company_fact表ID';
COMMENT ON COLUMN task_nest_log.nest_time IS '入巢时间';

-- 索引
CREATE INDEX idx_task_nest_log_task_id ON task_nest_log(task_id);
CREATE INDEX idx_task_nest_log_ent_code ON task_nest_log(ent_code);
CREATE INDEX idx_task_nest_log_credit_code ON task_nest_log(credit_code);
CREATE INDEX idx_task_nest_log_fact_id ON task_nest_log(fact_id);

-- =============================================
-- 表结构创建完成
-- =============================================
