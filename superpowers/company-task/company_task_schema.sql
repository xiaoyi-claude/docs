-- =============================================
-- 企业名称-拉新任务实体表结构
-- 版本: v1.0
-- 日期: 2026-05-15
-- 数据库: PostgreSQL
-- =============================================
-- 公共字段（所有表均包含）：
--   id          BIGSERIAL    自增主键
--   is_current  BOOLEAN      是否当前有效版本
--   trace_id    VARCHAR(64)  链路追踪 ID
--   owner       VARCHAR(64)  数据归属人
--   creater     VARCHAR(64)  创建人
--   create_time TIMESTAMPTZ  创建时间（insert 时自动写入）
--   updater     VARCHAR(64)  修改人
--   update_time TIMESTAMPTZ  修改时间（update 时自动写入）
--   remark      VARCHAR(500) 备注
-- =============================================


-- =============================================
-- 1. task_type_config 任务类型配置表
--    存储 4 种拉新任务类型及默认验证规则列表
-- =============================================
CREATE TABLE IF NOT EXISTS task_type_config (
    id                        BIGSERIAL     PRIMARY KEY,
    is_current                BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id                  VARCHAR(64),
    owner                     VARCHAR(64),
    creater                   VARCHAR(64),
    create_time               TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater                   VARCHAR(64),
    update_time               TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark                    VARCHAR(500),

    task_type_code            SMALLINT      NOT NULL,
    task_type_name            VARCHAR(50)   NOT NULL,
    task_type_desc            VARCHAR(200),
    default_verify_rule_codes JSONB         NOT NULL,
    is_enabled                BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT uk_task_type_code UNIQUE (task_type_code),
    CONSTRAINT ck_task_type_code CHECK (task_type_code IN (1, 2, 3, 4))
);

COMMENT ON TABLE task_type_config IS '任务类型配置表';
COMMENT ON COLUMN task_type_config.task_type_code IS '编码：1=基础拉新，2=用户拉新，3=业务拉新，4=公司拉新';
COMMENT ON COLUMN task_type_config.default_verify_rule_codes IS '默认验证规则编码列表（rule_code 字符串数组）';
COMMENT ON COLUMN task_type_config.is_enabled IS '是否启用';

INSERT INTO task_type_config (task_type_code, task_type_name, task_type_desc, default_verify_rule_codes, creater)
VALUES
(1, '基础拉新', '结构化文件批量导入拉新',
 '["integrity_credit_code","integrity_company_name","integrity_legal_rep","integrity_found_date","integrity_reg_status","integrity_address","compliance_credit_code","compliance_company_name_char","compliance_company_name_len","compliance_legal_rep_char","compliance_legal_rep_len","compliance_found_date","compliance_reg_status","duplicate_name_in_task","duplicate_name_in_nest","duplicate_code_in_task","duplicate_code_in_nest","authenticity_tianyancha"]',
 'system'),
(2, '用户拉新', '用户上传天眼查截图拉新',
 '["integrity_credit_code","integrity_company_name","integrity_legal_rep","integrity_found_date","integrity_reg_status","integrity_address","compliance_credit_code","compliance_company_name_char","compliance_company_name_len","compliance_legal_rep_char","compliance_legal_rep_len","compliance_found_date","compliance_reg_status","duplicate_name_in_task","duplicate_name_in_nest","duplicate_code_in_task","duplicate_code_in_nest","authenticity_tianyancha"]',
 'system'),
(3, '业务拉新', '业务系统推送压缩包拉新',
 '["integrity_credit_code","integrity_company_name","integrity_legal_rep","integrity_found_date","integrity_reg_status","integrity_address","compliance_credit_code","compliance_company_name_char","compliance_company_name_len","compliance_legal_rep_char","compliance_legal_rep_len","compliance_found_date","compliance_reg_status","duplicate_name_in_task","duplicate_name_in_nest","duplicate_code_in_task","duplicate_code_in_nest","authenticity_tianyancha"]',
 'system'),
(4, '公司拉新', '企业提交结构化文件拉新',
 '["integrity_credit_code","integrity_company_name","integrity_legal_rep","integrity_found_date","integrity_reg_status","integrity_address","compliance_credit_code","compliance_company_name_char","compliance_company_name_len","compliance_legal_rep_char","compliance_legal_rep_len","compliance_found_date","compliance_reg_status","duplicate_name_in_task","duplicate_name_in_nest","duplicate_code_in_task","duplicate_code_in_nest","authenticity_tianyancha"]',
 'system');


-- =============================================
-- 2. task_main 任务主表
--    每个拉新任务的完整记录
-- =============================================
CREATE TABLE IF NOT EXISTS task_main (
    id                  BIGSERIAL     PRIMARY KEY,
    is_current          BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id            VARCHAR(64),
    owner               VARCHAR(64),
    creater             VARCHAR(64),
    create_time         TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater             VARCHAR(64),
    update_time         TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark              VARCHAR(500),

    task_id             VARCHAR(36)   NOT NULL,
    task_type_code      SMALLINT      NOT NULL,
    task_name           VARCHAR(200),
    task_status         SMALLINT      NOT NULL DEFAULT 0,
    input_type          SMALLINT      NOT NULL,
    input_file_ext      VARCHAR(10),
    input_path          VARCHAR(500)  NOT NULL,
    verify_rule_codes   JSONB         NOT NULL,
    total_count         INTEGER       NOT NULL DEFAULT 0,
    pass_count          INTEGER       NOT NULL DEFAULT 0,
    fail_count          INTEGER       NOT NULL DEFAULT 0,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    error_msg           TEXT,

    CONSTRAINT uk_task_id UNIQUE (task_id),
    CONSTRAINT fk_task_type FOREIGN KEY (task_type_code) REFERENCES task_type_config (task_type_code),
    CONSTRAINT ck_task_status CHECK (task_status IN (0, 1, 2, 3)),
    CONSTRAINT ck_input_type  CHECK (input_type IN (1, 2, 3, 4))
);

COMMENT ON TABLE task_main IS '任务主表';
COMMENT ON COLUMN task_main.task_id IS '任务 UUID（对外标识）';
COMMENT ON COLUMN task_main.task_type_code IS '任务类型编码，关联 task_type_config';
COMMENT ON COLUMN task_main.task_status IS '0=PENDING，1=IN_PROGRESS，2=SUCCESS，3=FAILED';
COMMENT ON COLUMN task_main.input_type IS '1=文件，2=图片，3=压缩包，4=OSS路径';
COMMENT ON COLUMN task_main.input_file_ext IS '文件后缀（sql/csv/xlsx/json/txt/xml/png/jpg/bmp/zip/rar/tar/gz）';
COMMENT ON COLUMN task_main.input_path IS '文件存储路径或 OSS 路径';
COMMENT ON COLUMN task_main.verify_rule_codes IS '实际执行的规则编码列表（创建时确定；未传入则从任务类型默认值复制）';
COMMENT ON COLUMN task_main.total_count IS '解析出的总记录数';
COMMENT ON COLUMN task_main.pass_count IS '成功入巢数';
COMMENT ON COLUMN task_main.fail_count IS '未入巢数（解析失败 + 验证失败）';

CREATE INDEX idx_task_main_task_id      ON task_main (task_id);
CREATE INDEX idx_task_main_task_type    ON task_main (task_type_code);
CREATE INDEX idx_task_main_status       ON task_main (task_status);
CREATE INDEX idx_task_main_create_time  ON task_main (create_time);


-- =============================================
-- 3. task_data_temp 任务数据临时表
--    文件解析后逐行存储，贯穿验证和入巢全流程
-- =============================================
CREATE TABLE IF NOT EXISTS task_data_temp (
    id              BIGSERIAL     PRIMARY KEY,
    is_current      BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id        VARCHAR(64),
    owner           VARCHAR(64),
    creater         VARCHAR(64),
    create_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         VARCHAR(64),
    update_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark          VARCHAR(500),

    task_id         VARCHAR(36)   NOT NULL,
    row_no          INTEGER       NOT NULL,
    raw_data        JSONB         NOT NULL,
    credit_code     VARCHAR(18),
    company_name    VARCHAR(200),
    legal_rep       VARCHAR(50),
    found_date      DATE,
    reg_status      VARCHAR(50),
    address         VARCHAR(500),
    parse_status    SMALLINT      NOT NULL DEFAULT 0,
    parse_error     VARCHAR(500),
    verify_status   SMALLINT      NOT NULL DEFAULT 0,
    nest_status     SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT uk_task_row    UNIQUE (task_id, row_no),
    CONSTRAINT ck_parse_status  CHECK (parse_status  IN (0, 1, 2)),
    CONSTRAINT ck_verify_status CHECK (verify_status IN (0, 1, 2)),
    CONSTRAINT ck_nest_status   CHECK (nest_status   IN (0, 1, 2))
);

COMMENT ON TABLE task_data_temp IS '任务数据临时表';
COMMENT ON COLUMN task_data_temp.row_no IS '行序号（文件按原始行顺序 1-based；图片类型固定为 1）';
COMMENT ON COLUMN task_data_temp.raw_data IS '原始解析内容完整快照';
COMMENT ON COLUMN task_data_temp.reg_status IS '登记状态';
COMMENT ON COLUMN task_data_temp.parse_status IS '0=待解析，1=解析成功，2=解析失败';
COMMENT ON COLUMN task_data_temp.parse_error IS '解析失败原因';
COMMENT ON COLUMN task_data_temp.verify_status IS '0=待验证，1=全部规则通过，2=任一规则失败';
COMMENT ON COLUMN task_data_temp.nest_status IS '0=待处理，1=已入巢，2=跳过';

CREATE INDEX idx_task_data_temp_task_id       ON task_data_temp (task_id);
CREATE INDEX idx_task_data_temp_credit_code   ON task_data_temp (credit_code);
CREATE INDEX idx_task_data_temp_company_name  ON task_data_temp (company_name);
-- Step 3 筛选入巢候选行的复合索引
CREATE INDEX idx_task_data_temp_verify        ON task_data_temp (task_id, verify_status);


-- =============================================
-- 4. task_step_log 任务步骤日志表
--    记录每个步骤的输入输出快照（全流程留痕）
-- =============================================
CREATE TABLE IF NOT EXISTS task_step_log (
    id              BIGSERIAL     PRIMARY KEY,
    is_current      BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id        VARCHAR(64),
    owner           VARCHAR(64),
    creater         VARCHAR(64),
    create_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         VARCHAR(64),
    update_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark          VARCHAR(500),

    task_id         VARCHAR(36)   NOT NULL,
    step_code       SMALLINT      NOT NULL,
    step_name       VARCHAR(50)   NOT NULL,
    step_input      JSONB         NOT NULL,
    step_output     JSONB,
    step_status     SMALLINT      NOT NULL DEFAULT 0,
    started_at      TIMESTAMPTZ   NOT NULL,
    completed_at    TIMESTAMPTZ,
    duration_ms     BIGINT,
    error_msg       TEXT,

    CONSTRAINT ck_step_code   CHECK (step_code   IN (1, 2, 3)),
    CONSTRAINT ck_step_status CHECK (step_status IN (0, 1, 2, 3))
);

COMMENT ON TABLE task_step_log IS '任务步骤日志表';
COMMENT ON COLUMN task_step_log.step_code IS '1=文件读取与解析，2=数据验证，3=数据入巢';
COMMENT ON COLUMN task_step_log.step_input IS '步骤输入快照（步骤开始时写入）';
COMMENT ON COLUMN task_step_log.step_output IS '步骤输出快照（步骤完成时写入）';
COMMENT ON COLUMN task_step_log.step_status IS '0=PENDING，1=IN_PROGRESS，2=SUCCESS，3=FAILED';
COMMENT ON COLUMN task_step_log.duration_ms IS '耗时（毫秒）';

CREATE INDEX idx_task_step_log_task_id ON task_step_log (task_id);


-- =============================================
-- 5. data_verify_rule 数据验证规则表
--    定义全部验证规则，4 个大类 18 条规则
-- =============================================
CREATE TABLE IF NOT EXISTS data_verify_rule (
    id               BIGSERIAL     PRIMARY KEY,
    is_current       BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id         VARCHAR(64),
    owner            VARCHAR(64),
    creater          VARCHAR(64),
    create_time      TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater          VARCHAR(64),
    update_time      TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark           VARCHAR(500),

    rule_code        VARCHAR(50)   NOT NULL,
    rule_name        VARCHAR(100)  NOT NULL,
    error_category   SMALLINT      NOT NULL,
    error_sub_code   SMALLINT      NOT NULL,
    error_sub_name   VARCHAR(100)  NOT NULL,
    is_enabled       BOOLEAN       NOT NULL DEFAULT TRUE,
    sort_order       SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT uk_rule_code      UNIQUE (rule_code),
    CONSTRAINT ck_error_category CHECK (error_category IN (1, 2, 3, 4))
);

COMMENT ON TABLE data_verify_rule IS '数据验证规则表';
COMMENT ON COLUMN data_verify_rule.rule_code IS '规则唯一编码';
COMMENT ON COLUMN data_verify_rule.error_category IS '1=完整性验证，2=合规性验证，3=数据重复，4=数据真实性验证';
COMMENT ON COLUMN data_verify_rule.error_sub_code IS '大类内小类编码';
COMMENT ON COLUMN data_verify_rule.sort_order IS '执行顺序';

INSERT INTO data_verify_rule (rule_code, rule_name, error_category, error_sub_code, error_sub_name, sort_order, creater)
VALUES
-- 完整性验证（大类 1）
('integrity_credit_code',        '统一社会信用代码不能为空', 1, 1, '统一社会信用代码缺失',  10, 'system'),
('integrity_company_name',       '企业名称不能为空',         1, 2, '企业名称缺失',          11, 'system'),
('integrity_legal_rep',          '法定代表人不能为空',        1, 3, '法定代表人缺失',        12, 'system'),
('integrity_found_date',         '成立日期不能为空',          1, 4, '成立日期缺失',          13, 'system'),
('integrity_reg_status',         '登记状态不能为空',          1, 5, '登记状态缺失',          14, 'system'),
('integrity_address',            '住所不能为空',              1, 6, '住所缺失',              15, 'system'),

-- 合规性验证（大类 2）
('compliance_credit_code',       '统一社会信用代码格式验证',  2, 1, '统一社会信用代码非法',  20, 'system'),
('compliance_company_name_char', '企业名称字符合规性验证',    2, 2, '企业名称字符非法',      21, 'system'),
('compliance_company_name_len',  '企业名称长度验证',          2, 3, '企业名称长度不在[4,26]',22, 'system'),
('compliance_legal_rep_char',    '法定代表人字符合规性验证',  2, 4, '法定代表人字符非法',    23, 'system'),
('compliance_legal_rep_len',     '法定代表人长度验证',        2, 5, '法定代表人长度不在[2,5]',24,'system'),
('compliance_found_date',        '成立日期合规性验证',        2, 6, '成立日期非法',          25, 'system'),
('compliance_reg_status',        '登记状态合规性验证',        2, 7, '登记状态非法',          26, 'system'),

-- 数据重复（大类 3）
('duplicate_name_in_task',       '同名不同企（本任务内）',    3, 1, '同名不同企（本任务）',  30, 'system'),
('duplicate_name_in_nest',       '同名不同企（与数巢）',      3, 2, '同名不同企（数巢）',    31, 'system'),
('duplicate_code_in_task',       '同企不同名（本任务内）',    3, 3, '同企不同名（本任务）',  32, 'system'),
('duplicate_code_in_nest',       '同企不同名（与数巢）',      3, 4, '同企不同名（数巢）',    33, 'system'),

-- 数据真实性验证（大类 4）
('authenticity_tianyancha',      '天眼查企业信息真实性验证',  4, 1, '天眼查验证',            40, 'system');


-- =============================================
-- 6. data_verify_result 数据验证结果表
--    每行数据每条规则的验证结论（Step 2 核心留痕）
-- =============================================
CREATE TABLE IF NOT EXISTS data_verify_result (
    id              BIGSERIAL     PRIMARY KEY,
    is_current      BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id        VARCHAR(64),
    owner           VARCHAR(64),
    creater         VARCHAR(64),
    create_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         VARCHAR(64),
    update_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark          VARCHAR(500),

    task_id         VARCHAR(36)   NOT NULL,
    temp_data_id    BIGINT        NOT NULL,
    row_no          INTEGER       NOT NULL,
    rule_code       VARCHAR(50)   NOT NULL,
    is_pass         BOOLEAN       NOT NULL,
    error_field     VARCHAR(50),
    error_value     TEXT,
    error_msg       VARCHAR(500)
);

COMMENT ON TABLE data_verify_result IS '数据验证结果表';
COMMENT ON COLUMN data_verify_result.task_id IS '关联任务 ID（冗余，便于按任务查询）';
COMMENT ON COLUMN data_verify_result.temp_data_id IS '关联 task_data_temp.id';
COMMENT ON COLUMN data_verify_result.row_no IS '行号（冗余，便于报告展示）';
COMMENT ON COLUMN data_verify_result.rule_code IS '验证规则编码';
COMMENT ON COLUMN data_verify_result.is_pass IS 'TRUE=通过，FALSE=未通过';
COMMENT ON COLUMN data_verify_result.error_field IS '未通过时的字段名';
COMMENT ON COLUMN data_verify_result.error_value IS '未通过时的字段值';
COMMENT ON COLUMN data_verify_result.error_msg IS '未通过时的错误说明';

CREATE INDEX idx_verify_result_task_id      ON data_verify_result (task_id);
CREATE INDEX idx_verify_result_temp_data_id ON data_verify_result (temp_data_id);
-- 查询任务内所有未通过记录
CREATE INDEX idx_verify_result_is_pass      ON data_verify_result (task_id, is_pass);


-- =============================================
-- 7. third_api_log 第三方 API 调用日志表
--    天眼查真实性验证的 API 调用详情，
--    通过 verify_result_id 与 data_verify_result 1:1 关联
-- =============================================
CREATE TABLE IF NOT EXISTS third_api_log (
    id                BIGSERIAL     PRIMARY KEY,
    is_current        BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id          VARCHAR(64),
    owner             VARCHAR(64),
    creater           VARCHAR(64),
    create_time       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater           VARCHAR(64),
    update_time       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark            VARCHAR(500),

    verify_result_id  BIGINT        NOT NULL,
    task_id           VARCHAR(36)   NOT NULL,
    temp_data_id      BIGINT        NOT NULL,
    api_url           VARCHAR(500)  NOT NULL,
    request_body      TEXT,
    response_body     TEXT,
    is_success        BOOLEAN       NOT NULL,
    error_msg         TEXT,
    duration_ms       BIGINT,
    called_at         TIMESTAMPTZ   NOT NULL,

    CONSTRAINT uk_verify_result_id UNIQUE (verify_result_id),
    CONSTRAINT fk_verify_result    FOREIGN KEY (verify_result_id) REFERENCES data_verify_result (id)
);

COMMENT ON TABLE third_api_log IS '第三方 API 调用日志表';
COMMENT ON COLUMN third_api_log.verify_result_id IS '关联 data_verify_result.id（1:1）';
COMMENT ON COLUMN third_api_log.task_id IS '关联任务 ID（冗余）';
COMMENT ON COLUMN third_api_log.temp_data_id IS '关联 task_data_temp.id（冗余）';
COMMENT ON COLUMN third_api_log.api_url IS 'API 请求 URL';
COMMENT ON COLUMN third_api_log.request_body IS '请求内容';
COMMENT ON COLUMN third_api_log.response_body IS '响应内容';
COMMENT ON COLUMN third_api_log.is_success IS 'API 调用是否成功';
COMMENT ON COLUMN third_api_log.called_at IS '调用时间';

CREATE INDEX idx_third_api_log_task_id    ON third_api_log (task_id);
CREATE INDEX idx_third_api_log_called_at  ON third_api_log (called_at);


-- =============================================
-- 8. task_nest_log 任务入巢日志表
--    记录验证通过的数据写入 company_fact 的操作
-- =============================================
CREATE TABLE IF NOT EXISTS task_nest_log (
    id              BIGSERIAL     PRIMARY KEY,
    is_current      BOOLEAN       NOT NULL DEFAULT TRUE,
    trace_id        VARCHAR(64),
    owner           VARCHAR(64),
    creater         VARCHAR(64),
    create_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         VARCHAR(64),
    update_time     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark          VARCHAR(500),

    task_id         VARCHAR(36)   NOT NULL,
    temp_data_id    BIGINT        NOT NULL,
    row_no          INTEGER       NOT NULL,
    fact_id         BIGINT        NOT NULL,
    credit_code     VARCHAR(18)   NOT NULL,
    company_name    VARCHAR(200)  NOT NULL,
    nest_time       TIMESTAMPTZ   NOT NULL,

    CONSTRAINT uk_task_nest_temp_data UNIQUE (temp_data_id)
);

COMMENT ON TABLE task_nest_log IS '任务入巢日志表';
COMMENT ON COLUMN task_nest_log.task_id IS '关联任务 ID';
COMMENT ON COLUMN task_nest_log.temp_data_id IS '关联 task_data_temp.id（每条数据只入巢一次）';
COMMENT ON COLUMN task_nest_log.row_no IS '行号（冗余）';
COMMENT ON COLUMN task_nest_log.fact_id IS '关联 company_fact.id';
COMMENT ON COLUMN task_nest_log.credit_code IS '统一社会信用代码（冗余，便于追溯查询）';
COMMENT ON COLUMN task_nest_log.company_name IS '企业名称（冗余）';
COMMENT ON COLUMN task_nest_log.nest_time IS '入巢时间';

CREATE INDEX idx_task_nest_log_task_id     ON task_nest_log (task_id);
CREATE INDEX idx_task_nest_log_credit_code ON task_nest_log (credit_code);
CREATE INDEX idx_task_nest_log_fact_id     ON task_nest_log (fact_id);

-- =============================================
-- 表结构创建完成
-- =============================================
