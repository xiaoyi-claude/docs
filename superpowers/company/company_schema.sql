-- =============================================
-- 企业名称服务实体表结构设计
-- 版本: v1.0
-- 日期: 2026-05-15
-- 数据库: PostgreSQL
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
-- 1. 企业事实数据表（核心表）
-- =============================================
CREATE TABLE IF NOT EXISTS company_fact (
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
    ent_code            VARCHAR(36)                 NOT NULL UNIQUE,
    credit_code         VARCHAR(18)                 NOT NULL,
    name                VARCHAR(100)                NOT NULL,
    legal_rep           VARCHAR(20)                 NOT NULL,
    address             VARCHAR(500),
    location_id         VARCHAR(36),
    fact_time           TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fact_record_time    TIMESTAMPTZ                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ent_record_scene    SMALLINT                    NOT NULL DEFAULT 1,
    legal_rep_record_scene SMALLINT                NOT NULL DEFAULT 1,
    task_id             VARCHAR(36),

    -- 约束
    CONSTRAINT uk_credit_code_current UNIQUE (credit_code, is_current),
    CONSTRAINT ck_ent_record_scene CHECK (ent_record_scene IN (1, 2, 3, 4)),
    CONSTRAINT ck_legal_rep_record_scene CHECK (legal_rep_record_scene IN (1, 2, 3)),
    CONSTRAINT ck_credit_code_format CHECK (
        credit_code ~ '^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$'
        AND SUBSTRING(credit_code, 1, 2) IN ('91', '92', '12')
    ),
    CONSTRAINT ck_name_format CHECK (
        LENGTH(name) >= 4 AND LENGTH(name) <= 26
        AND name ~ '^[\u4e00-\u9fa5（）()]+$'
        AND name !~ '^（.*）$'
        AND name !~ '^\(.*\)$'
    ),
    CONSTRAINT ck_legal_rep_format CHECK (
        LENGTH(legal_rep) >= 2 AND LENGTH(legal_rep) <= 5
        AND legal_rep ~ '^[\u4e00-\u9fa5]+$'
    )
);

COMMENT ON TABLE company_fact IS '企业事实数据表';
COMMENT ON COLUMN company_fact.id IS '自增主键（内部排序，禁止插队）';
COMMENT ON COLUMN company_fact.is_current IS '是否当前有效版本';
COMMENT ON COLUMN company_fact.trace_id IS '日志链路追踪ID';
COMMENT ON COLUMN company_fact.owner IS '数据拥有人';
COMMENT ON COLUMN company_fact.creater IS '创建人';
COMMENT ON COLUMN company_fact.create_time IS '创建时间';
COMMENT ON COLUMN company_fact.updater IS '修改人';
COMMENT ON COLUMN company_fact.update_time IS '修改时间';
COMMENT ON COLUMN company_fact.remark IS '备注';
COMMENT ON COLUMN company_fact.ent_code IS '企业UUID v4（对外标识）';
COMMENT ON COLUMN company_fact.credit_code IS '统一社会信用代码（GB 32100-2015）';
COMMENT ON COLUMN company_fact.name IS '企业名称';
COMMENT ON COLUMN company_fact.legal_rep IS '权力人姓名';
COMMENT ON COLUMN company_fact.address IS '企业地址';
COMMENT ON COLUMN company_fact.location_id IS '关联位置信息ID';
COMMENT ON COLUMN company_fact.fact_time IS '事实发生时间';
COMMENT ON COLUMN company_fact.fact_record_time IS '入巢时间';
COMMENT ON COLUMN company_fact.ent_record_scene IS '企业新增场景：1=基础拉新；2=用户拉新；3=业务拉新；4=公司拉新';
COMMENT ON COLUMN company_fact.legal_rep_record_scene IS '权力人新增场景：1=代为确定性主张；2=确定实际主张；3=权力人替换并主张';
COMMENT ON COLUMN company_fact.task_id IS '关联任务单ID';

-- 索引
CREATE INDEX idx_company_fact_credit_code ON company_fact(credit_code);
CREATE INDEX idx_company_fact_name ON company_fact(name);
CREATE INDEX idx_company_fact_legal_rep ON company_fact(legal_rep);
CREATE INDEX idx_company_fact_ent_code ON company_fact(ent_code);

-- =============================================
-- 2. 任务单表
-- =============================================
CREATE TABLE IF NOT EXISTS company_task (
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
    task_type           SMALLINT                    NOT NULL,
    task_status         SMALLINT                    NOT NULL DEFAULT 0,
    input_source        VARCHAR(500),
    payload             JSONB,
    result              JSONB,
    workflow_instance_id VARCHAR(64),
    retry_count         SMALLINT                    NOT NULL DEFAULT 0,
    error_msg           TEXT,

    -- 约束
    CONSTRAINT ck_task_type CHECK (task_type IN (1, 2, 3, 4)),
    CONSTRAINT ck_task_status CHECK (task_status IN (0, 1, 2, 3))
);

COMMENT ON TABLE company_task IS '任务单表';
COMMENT ON COLUMN company_task.task_id IS '任务单UUID';
COMMENT ON COLUMN company_task.task_type IS '任务类型：1=基础拉新；2=用户拉新；3=业务拉新；4=公司拉新';
COMMENT ON COLUMN company_task.task_status IS '任务状态：0=PENDING；1=IN_PROGRESS；2=SUCCESS；3=FAILED';
COMMENT ON COLUMN company_task.input_source IS '输入来源标识';
COMMENT ON COLUMN company_task.payload IS '采信来源、凭证、处理规则';
COMMENT ON COLUMN company_task.result IS '处理结果';
COMMENT ON COLUMN company_task.workflow_instance_id IS 'Dapr工作流实例ID';
COMMENT ON COLUMN company_task.retry_count IS '重试次数';
COMMENT ON COLUMN company_task.error_msg IS '失败原因';

-- 索引
CREATE INDEX idx_company_task_type ON company_task(task_type);
CREATE INDEX idx_company_task_status ON company_task(task_status);

-- =============================================
-- 3. OCR处理日志表
-- =============================================
CREATE TABLE IF NOT EXISTS company_ocr_log (
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
    model_name          VARCHAR(50)                 NOT NULL,
    image_path          VARCHAR(500),
    raw_result          JSONB,
    credit_code         VARCHAR(18),
    company_name        VARCHAR(100),
    legal_rep_name      VARCHAR(20),
    is_success          BOOLEAN                     NOT NULL DEFAULT FALSE,
    fail_reason         VARCHAR(200)
);

COMMENT ON TABLE company_ocr_log IS 'OCR处理日志表';
COMMENT ON COLUMN company_ocr_log.task_id IS '关联任务单';
COMMENT ON COLUMN company_ocr_log.model_name IS 'OCR模型名称（paddleocr/easyocr/tesseract）';
COMMENT ON COLUMN company_ocr_log.image_path IS '图片路径或URL';
COMMENT ON COLUMN company_ocr_log.raw_result IS 'OCR原始输出';
COMMENT ON COLUMN company_ocr_log.credit_code IS '提取的统一社会信用代码';
COMMENT ON COLUMN company_ocr_log.company_name IS '提取的企业名称';
COMMENT ON COLUMN company_ocr_log.legal_rep_name IS '提取的权力人姓名';
COMMENT ON COLUMN company_ocr_log.is_success IS '提取是否成功';
COMMENT ON COLUMN company_ocr_log.fail_reason IS '失败原因';

-- 索引
CREATE INDEX idx_company_ocr_task_id ON company_ocr_log(task_id);

-- =============================================
-- 4. 第三方数据源验证日志表
-- =============================================
CREATE TABLE IF NOT EXISTS company_data_verify_log (
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
    source_name         VARCHAR(50)                 NOT NULL,
    query_name          VARCHAR(100),
    response_data       JSONB,
    is_consistent       BOOLEAN,
    is_success          BOOLEAN                     NOT NULL DEFAULT FALSE,
    fail_reason         VARCHAR(200)
);

COMMENT ON TABLE company_data_verify_log IS '第三方数据源验证日志表';
COMMENT ON COLUMN company_data_verify_log.task_id IS '关联任务单';
COMMENT ON COLUMN company_data_verify_log.source_name IS '数据源名称（tianyancha等）';
COMMENT ON COLUMN company_data_verify_log.query_name IS '查询企业名称';
COMMENT ON COLUMN company_data_verify_log.response_data IS '数据源返回结果';
COMMENT ON COLUMN company_data_verify_log.is_consistent IS '与输入三要素是否一致';
COMMENT ON COLUMN company_data_verify_log.is_success IS 'API调用是否成功';
COMMENT ON COLUMN company_data_verify_log.fail_reason IS '失败原因';

-- 索引
CREATE INDEX idx_company_verify_task_id ON company_data_verify_log(task_id);

-- =============================================
-- 5. 冲突处理日志表
-- =============================================
CREATE TABLE IF NOT EXISTS company_conflict_log (
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
    conflict_type       SMALLINT                    NOT NULL,
    new_credit_code     VARCHAR(18),
    new_name            VARCHAR(100),
    existing_ent_code   VARCHAR(36),
    existing_credit_code VARCHAR(18),
    existing_name       VARCHAR(100),
    resolution          SMALLINT                    NOT NULL,
    resolution_reason   VARCHAR(200),

    -- 约束
    CONSTRAINT ck_conflict_type CHECK (conflict_type IN (1, 2)),
    CONSTRAINT ck_resolution CHECK (resolution IN (1, 2, 3))
);

COMMENT ON TABLE company_conflict_log IS '冲突处理日志表';
COMMENT ON COLUMN company_conflict_log.task_id IS '关联任务单';
COMMENT ON COLUMN company_conflict_log.conflict_type IS '冲突类型：1=同名不同企；2=同企不同名';
COMMENT ON COLUMN company_conflict_log.new_credit_code IS '新记录信用代码';
COMMENT ON COLUMN company_conflict_log.new_name IS '新记录企业名称';
COMMENT ON COLUMN company_conflict_log.existing_ent_code IS '已有企业UUID';
COMMENT ON COLUMN company_conflict_log.existing_credit_code IS '已有信用代码';
COMMENT ON COLUMN company_conflict_log.existing_name IS '已有企业名称';
COMMENT ON COLUMN company_conflict_log.resolution IS '处理方案：1=全部保留独立存在；2=复用UUID挂载新名称；3=拒绝拉新';
COMMENT ON COLUMN company_conflict_log.resolution_reason IS '处理原因';

-- 索引
CREATE INDEX idx_company_conflict_task_id ON company_conflict_log(task_id);

-- =============================================
-- 6. 首支验证日志表
-- =============================================
CREATE TABLE IF NOT EXISTS company_first_link_log (
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
    fact_id             BIGINT                      NOT NULL,
    verifier_type       SMALLINT                    NOT NULL,
    expected_data       JSONB,
    actual_data         JSONB,
    is_consistent       BOOLEAN,
    verify_status       SMALLINT                    NOT NULL DEFAULT 0,
    verified_at         TIMESTAMPTZ,

    -- 约束
    CONSTRAINT ck_verifier_type CHECK (verifier_type IN (1, 2, 3)),
    CONSTRAINT ck_verify_status CHECK (verify_status IN (0, 1, 2))
);

COMMENT ON TABLE company_first_link_log IS '首支验证日志表';
COMMENT ON COLUMN company_first_link_log.task_id IS '关联任务单';
COMMENT ON COLUMN company_first_link_log.fact_id IS '关联company_fact.id';
COMMENT ON COLUMN company_first_link_log.verifier_type IS '验证方类型：1=系统自验；2=用户确认；3=业务方确认';
COMMENT ON COLUMN company_first_link_log.expected_data IS '写入前信息';
COMMENT ON COLUMN company_first_link_log.actual_data IS '写入后信息';
COMMENT ON COLUMN company_first_link_log.is_consistent IS '是否一致';
COMMENT ON COLUMN company_first_link_log.verify_status IS '验证状态：0=待确认；1=已通过；2=已拒绝';
COMMENT ON COLUMN company_first_link_log.verified_at IS '确认时间';

-- 索引
CREATE INDEX idx_company_firstlink_task_id ON company_first_link_log(task_id);
CREATE INDEX idx_company_firstlink_fact_id ON company_first_link_log(fact_id);

-- =============================================
-- 7. 通用地址信息表
-- =============================================
CREATE TABLE IF NOT EXISTS address_info (
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
    address_id          VARCHAR(36)                 NOT NULL UNIQUE,
    entity_type         VARCHAR(50)                 NOT NULL,
    entity_id           VARCHAR(36)                 NOT NULL,
    raw_address         VARCHAR(500),
    province_code       VARCHAR(6),
    longitude           DECIMAL(10, 7),
    latitude            DECIMAL(10, 7),
    poi_name            VARCHAR(200),
    poi_address         VARCHAR(200),
    poi_id              VARCHAR(50),
    accuracy_level      SMALLINT                    NOT NULL DEFAULT 1,

    -- 约束
    CONSTRAINT ck_accuracy_level CHECK (accuracy_level IN (1, 2, 3))
);

COMMENT ON TABLE address_info IS '通用地址信息表';
COMMENT ON COLUMN address_info.address_id IS '地址UUID v4（对外标识）';
COMMENT ON COLUMN address_info.entity_type IS '关联实体类型（如：company）';
COMMENT ON COLUMN address_info.entity_id IS '关联实体UUID';
COMMENT ON COLUMN address_info.raw_address IS '原始输入地址';
COMMENT ON COLUMN address_info.province_code IS '省编码';
COMMENT ON COLUMN address_info.longitude IS '经度';
COMMENT ON COLUMN address_info.latitude IS '纬度';
COMMENT ON COLUMN address_info.poi_name IS '地标名称';
COMMENT ON COLUMN address_info.poi_address IS '地标地址';
COMMENT ON COLUMN address_info.poi_id IS '腾讯地图POI ID';
COMMENT ON COLUMN address_info.accuracy_level IS '准确率级别：1=精确匹配；2=省市县补全后匹配；3=省人民政府兜底';

-- 索引
CREATE INDEX idx_address_entity ON address_info(entity_type, entity_id);
CREATE INDEX idx_address_poi ON address_info(poi_id);

-- =============================================
-- 表结构创建完成
-- =============================================
