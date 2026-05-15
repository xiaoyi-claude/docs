-- =============================================
-- 企业名称服务实体表结构设计
-- 版本: v2.0
-- 日期: 2026-05-15
-- 数据库: PostgreSQL
-- 来源: 国家企业信用信息公示系统
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
-- 对应图片字段：统一社会信用代码、企业名称、注册号、法定代表人、
--               类型、成立日期、注册资本、核准日期、登记机关、
--               登记状态、住所、经营范围
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

    -- 业务字段（对应国家企业信用信息公示系统）
    ent_code            VARCHAR(36)                 NOT NULL UNIQUE,
    credit_code         VARCHAR(18)                 NOT NULL,
    reg_no              VARCHAR(50),
    name                VARCHAR(200)                NOT NULL,
    legal_rep           VARCHAR(50)                 NOT NULL,
    company_type        VARCHAR(100),
    found_date          DATE,
    reg_capital         DECIMAL(20, 6),
    reg_capital_currency VARCHAR(10)                DEFAULT '人民币',
    approve_date        DATE,
    registration_authority VARCHAR(200),
    status              VARCHAR(50),
    address             VARCHAR(500),
    business_scope      TEXT,
    business_term_start DATE,
    business_term_end   DATE,

    -- 约束
    CONSTRAINT uk_credit_code_current UNIQUE (credit_code, is_current),
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
COMMENT ON COLUMN company_fact.ent_code IS '企业UUID（对外标识）';
COMMENT ON COLUMN company_fact.credit_code IS '统一社会信用代码（GB 32100-2015）';
COMMENT ON COLUMN company_fact.reg_no IS '注册号';
COMMENT ON COLUMN company_fact.name IS '企业名称';
COMMENT ON COLUMN company_fact.legal_rep IS '法定代表人';
COMMENT ON COLUMN company_fact.company_type IS '公司类型';
COMMENT ON COLUMN company_fact.found_date IS '成立日期';
COMMENT ON COLUMN company_fact.reg_capital IS '注册资本';
COMMENT ON COLUMN company_fact.reg_capital_currency IS '注册资本币种';
COMMENT ON COLUMN company_fact.approve_date IS '核准日期';
COMMENT ON COLUMN company_fact.registration_authority IS '登记机关';
COMMENT ON COLUMN company_fact.status IS '登记状态';
COMMENT ON COLUMN company_fact.address IS '住所';
COMMENT ON COLUMN company_fact.business_scope IS '经营范围';
COMMENT ON COLUMN company_fact.business_term_start IS '营业期限自';
COMMENT ON COLUMN company_fact.business_term_end IS '营业期限至';

-- 索引
CREATE INDEX idx_company_fact_credit_code ON company_fact(credit_code);
CREATE INDEX idx_company_fact_name ON company_fact(name);
CREATE INDEX idx_company_fact_legal_rep ON company_fact(legal_rep);
CREATE INDEX idx_company_fact_status ON company_fact(status);
CREATE INDEX idx_company_fact_found_date ON company_fact(found_date);

-- =============================================
-- 表结构创建完成
-- =============================================
