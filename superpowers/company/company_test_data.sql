-- =============================================
-- 企业名称服务测试数据集
-- 版本: v2.0
-- 日期: 2026-05-15
-- 数据库: PostgreSQL
-- 来源: 国家企业信用信息公示系统
-- =============================================

-- =============================================
-- 1. 创建企业事实表
-- =============================================
DROP TABLE IF EXISTS company_fact CASCADE;

CREATE TABLE company_fact (
    -- 主键字段
    id                  BIGSERIAL                   PRIMARY KEY,
    
    -- 业务字段（对应国家企业信用信息公示系统）
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
    
    -- 测试场景标记
    test_scene          VARCHAR(50),
    
    -- 审计字段
    created_at          TIMESTAMP                   DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP                   DEFAULT CURRENT_TIMESTAMP
);

-- 添加表注释
COMMENT ON TABLE company_fact IS '企业信息事实表 - 存储企业基本信息数据';

-- 添加字段注释
COMMENT ON COLUMN company_fact.id IS '主键ID';
COMMENT ON COLUMN company_fact.credit_code IS '统一社会信用代码（18位）';
COMMENT ON COLUMN company_fact.reg_no IS '注册号';
COMMENT ON COLUMN company_fact.name IS '企业名称';
COMMENT ON COLUMN company_fact.legal_rep IS '法定代表人';
COMMENT ON COLUMN company_fact.company_type IS '企业类型';
COMMENT ON COLUMN company_fact.found_date IS '成立日期';
COMMENT ON COLUMN company_fact.reg_capital IS '注册资本';
COMMENT ON COLUMN company_fact.reg_capital_currency IS '注册资本币种';
COMMENT ON COLUMN company_fact.approve_date IS '核准日期';
COMMENT ON COLUMN company_fact.registration_authority IS '登记机关';
COMMENT ON COLUMN company_fact.status IS '登记状态';
COMMENT ON COLUMN company_fact.address IS '住所';
COMMENT ON COLUMN company_fact.business_scope IS '经营范围';
COMMENT ON COLUMN company_fact.test_scene IS '测试场景标记';
COMMENT ON COLUMN company_fact.created_at IS '创建时间';
COMMENT ON COLUMN company_fact.updated_at IS '更新时间';

-- 创建索引
CREATE INDEX idx_company_fact_credit_code ON company_fact(credit_code);
CREATE INDEX idx_company_fact_name ON company_fact(name);
CREATE INDEX idx_company_fact_legal_rep ON company_fact(legal_rep);
CREATE INDEX idx_company_fact_status ON company_fact(status);
CREATE INDEX idx_company_fact_test_scene ON company_fact(test_scene);

-- =============================================
-- 2. 插入测试数据
-- =============================================

-- 正常企业数据 (11条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('91350503MA32XEXM2J', '', '易客创新（泉州）智能科技有限公司', '吕煌', '有限责任公司（自然人投资或控股）', '2019-06-11', 2000.000000, '人民币', '2023-12-21', '泉州市丰泽区市场监督管理局', '存续（在营、开业、在册）', '泉州市丰泽区华大街道体育街华创园B510室', '智能科技领域内的技术开发、技术咨询、技术服务；集成电路设计；信息系统集成服务；软件开发；工业产品设计、模具设计、电子产品设计和平面设计；销售、加工、生产；电子元器件、电子模块、电子产品、半导体产品、传感器。', 'normal'),
('91350200MA348KJW1K', '350200100123456', '福建华为技术有限公司', '任正非', '有限责任公司（自然人投资或控股）', '2018-06-15', 5000.000000, '人民币', '2024-03-20', '厦门市市场监督管理局', '存续（在营、开业、在册）', '福建省厦门市思明区软件园二期观日路10号', '通信设备制造；网络设备制造；计算机软硬件及外围设备制造；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；软件开发；信息系统集成服务。', 'normal'),
('91310000MA1FB4HC1Q', '310000000012345', '上海阿里巴巴信息技术有限公司', '张勇', '有限责任公司（自然人投资或控股）', '2017-03-20', 10000.000000, '人民币', '2024-01-15', '上海市浦东新区市场监督管理局', '存续（在营、开业、在册）', '上海市浦东新区张江高科技园区博云路2号', '信息技术咨询服务；软件开发；网络技术服务；计算机系统服务；数据处理服务。', 'normal'),
('91440300MA5DRT3D9M', '440300000012345', '深圳腾讯计算机系统有限公司', '马化腾', '有限责任公司（自然人投资或控股）', '2016-09-10', 8000.000000, '人民币', '2023-11-08', '深圳市市场监督管理局', '存续（在营、开业、在册）', '广东省深圳市南山区科技园高新南一道8号', '计算机软硬件技术开发、销售；计算机系统服务；网络游戏开发；互联网信息服务。', 'normal'),
('91330100MA27WXK87E', '330100000012345', '杭州网易网络有限公司', '丁磊', '有限责任公司（自然人投资或控股）', '2015-05-12', 6000.000000, '人民币', '2024-02-28', '杭州市滨江区市场监督管理局', '存续（在营、开业、在册）', '浙江省杭州市滨江区网易大厦网商路599号', '互联网信息服务；网络游戏开发；电子商务技术开发；广告设计、代理、发布。', 'normal'),
('91110000MA008T4Y8L', '110000000012345', '北京百度网讯科技有限公司', '李彦宏', '有限责任公司（自然人投资或控股）', '2014-08-20', 7000.000000, '人民币', '2023-10-15', '北京市海淀区市场监督管理局', '存续（在营、开业、在册）', '北京市海淀区中关村软件园百度大厦', '互联网信息服务；搜索引擎技术开发；人工智能技术开发；数据处理服务。', 'normal'),
('91320100MA1N0T5C2P', '320100000012345', '南京苏宁易购电子商务有限公司', '张近东', '有限责任公司（自然人投资或控股）', '2013-11-05', 9000.000000, '人民币', '2024-04-10', '南京市玄武区市场监督管理局', '存续（在营、开业、在册）', '江苏省南京市玄武区苏宁大道1号', '电子商务；家用电器销售；电子产品销售；日用百货销售；物流配送服务。', 'normal'),
('91420100MA4K0X5D7Q', '420100000012345', '武汉小米科技有限公司', '雷军', '有限责任公司（自然人投资或控股）', '2012-06-18', 4000.000000, '人民币', '2023-12-05', '武汉市东湖新技术开发区市场监督管理局', '存续（在营、开业、在册）', '湖北省武汉市东湖新技术开发区光谷大道77号', '手机制造；智能设备研发；电子产品销售；物联网技术服务。', 'normal'),
('91440100MA3CJC3E6H', '440100000012345', '广州字节跳动网络技术有限公司', '张一鸣', '有限责任公司（自然人投资或控股）', '2016-03-12', 5500.000000, '人民币', '2024-01-20', '广州市天河区市场监督管理局', '存续（在营、开业、在册）', '广东省广州市天河区珠江新城冼村路5号', '网络技术服务；软件开发；广告设计、代理；文化娱乐经纪人服务。', 'normal'),
('91500000MA5U6K8E2F', '500000000012345', '重庆京东世纪贸易有限公司', '刘强东', '有限责任公司（自然人投资或控股）', '2014-09-25', 8500.000000, '人民币', '2023-11-28', '重庆市渝北区市场监督管理局', '存续（在营、开业、在册）', '重庆市渝北区两江新区金渝大道29号', '货物进出口；技术进出口；国内贸易代理；仓储服务；物流配送。', 'normal'),
('91510100MA61R8T7XQ', '510100000012345', '成都美团点评信息技术有限公司', '王兴', '有限责任公司（自然人投资或控股）', '2015-02-14', 3500.000000, '人民币', '2024-03-08', '成都市高新区市场监督管理局', '存续（在营、开业、在册）', '四川省成都市高新区天府大道北段1480号', '信息技术咨询服务；餐饮管理；外卖递送服务；计算机系统服务。', 'normal');

-- 关键字段缺失场景 (6条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('', '', '测试缺失信用代码公司', '张三', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '北京市朝阳区市场监督管理局', '存续（在营、开业、在册）', '北京市朝阳区建国路88号', '技术开发、技术服务。', 'missing_credit_code'),
('91350200MA348KJW1K', '', '', '李四', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '上海市浦东新区市场监督管理局', '存续（在营、开业、在册）', '上海市浦东新区陆家嘴环路1000号', '技术开发、技术服务。', 'missing_name'),
('91310000MA1FB4HC1Q', '', '测试缺失法定代表人公司', '', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '广东省深圳市市场监督管理局', '存续（在营、开业、在册）', '广东省深圳市福田区深南大道6011号', '技术开发、技术服务。', 'missing_legal_rep'),
('91350200MA348KJW1K', '', '测试缺失成立日期公司', '王五', '有限责任公司', NULL, 100.000000, '人民币', '2020-01-01', '杭州市西湖区市场监督管理局', '存续（在营、开业、在册）', '杭州市西湖区文三路478号', '技术开发、技术服务。', 'missing_found_date'),
('91350200MA348KJW1K', '', '测试缺失登记状态公司', '赵六', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '南京市鼓楼区市场监督管理局', '', '南京市鼓楼区中山北路200号', '技术开发、技术服务。', 'missing_status'),
('91350200MA348KJW1K', '', '测试缺失住所公司', '孙七', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '武汉市洪山区市场监督管理局', '存续（在营、开业、在册）', '', '技术开发、技术服务。', 'missing_address');

-- 统一社会信用代码格式错误 (2条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('88350503MA32XEXM2J', '', '测试信用代码前缀错误公司', '周八', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '广州市天河区市场监督管理局', '存续（在营、开业、在册）', '广州市天河区体育西路103号', '技术开发、技术服务。', 'invalid_credit_code_prefix'),
('91350503MA', '', '测试信用代码长度错误公司', '吴九', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '成都市武侯区市场监督管理局', '存续（在营、开业、在册）', '成都市武侯区人民南路四段3号', '技术开发、技术服务。', 'invalid_credit_code_length');

-- 企业名称格式错误 (3条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('91350200MA348KJW1K', '', 'ABC科技有限公司', '郑十', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '重庆市渝中区市场监督管理局', '存续（在营、开业、在册）', '重庆市渝中区解放碑步行街1号', '技术开发、技术服务。', 'invalid_name_not_chinese'),
('91310000MA1FB4HC1Q', '', '科技', '冯十一', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '西安市雁塔区市场监督管理局', '存续（在营、开业、在册）', '西安市雁塔区高新路2号', '技术开发、技术服务。', 'invalid_name_too_short'),
('91440300MA5DRT3D9M', '', '这是一个企业名称长度超过二十六个字符的超长名称测试公司', '褚十二', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '苏州市工业园区市场监督管理局', '存续（在营、开业、在册）', '苏州市工业园区现代大道1号', '技术开发、技术服务。', 'invalid_name_too_long');

-- 法定代表人格式错误 (3条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('91320100MA1N0T5C2P', '', '测试法定代表人非汉字公司', 'LiMing', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '天津市南开区市场监督管理局', '存续（在营、开业、在册）', '天津市南开区南京路309号', '技术开发、技术服务。', 'invalid_legal_rep_not_chinese'),
('91420100MA4K0X5D7Q', '', '测试法定代表人过短公司', '赵', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '长沙市岳麓区市场监督管理局', '存续（在营、开业、在册）', '长沙市岳麓区岳麓大道1号', '技术开发、技术服务。', 'invalid_legal_rep_too_short'),
('91440100MA3CJC3E6H', '', '测试法定代表人过长公司', '一二三四五六七', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '郑州市金水区市场监督管理局', '存续（在营、开业、在册）', '郑州市金水区金水路20号', '技术开发、技术服务。', 'invalid_legal_rep_too_long');

-- 特殊场景数据 (3条)
INSERT INTO company_fact (credit_code, reg_no, name, legal_rep, company_type, found_date, reg_capital, reg_capital_currency, approve_date, registration_authority, status, address, business_scope, test_scene) VALUES
('91350503MA32XEXM2K', '', '易客创新（泉州）智能科技有限公司', '黄十七', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '泉州市丰泽区市场监督管理局', '存续（在营、开业、在册）', '泉州市丰泽区丰泽街1号', '技术开发、技术服务。', 'same_name_different_company'),
('91350503MA32XEXM2J', '', '同企不同名测试公司', '吕煌', '有限责任公司', '2020-01-01', 100.000000, '人民币', '2020-01-01', '泉州市丰泽区市场监督管理局', '存续（在营、开业、在册）', '泉州市丰泽区华大街道体育街华创园B510室', '技术开发、技术服务。', 'same_company_different_name'),
('91350503MA32XEXM2J', '', '易客创新（泉州）智能科技有限公司', '吕煌', '有限责任公司（自然人投资或控股）', '2019-06-11', 2000.000000, '人民币', '2023-12-21', '泉州市丰泽区市场监督管理局', '注销', '泉州市丰泽区华大街道体育街华创园B510室', '智能科技领域内的技术开发、技术咨询、技术服务。', 'same_company_different_status');

-- =============================================
-- 3. 数据质量校验规则表
-- =============================================
DROP TABLE IF EXISTS data_quality_rules CASCADE;

CREATE TABLE data_quality_rules (
    id              SERIAL PRIMARY KEY,
    rule_code       VARCHAR(50)    UNIQUE NOT NULL,
    rule_name       VARCHAR(200)   NOT NULL,
    rule_type       VARCHAR(50)    NOT NULL,
    check_field     VARCHAR(100),
    check_expression TEXT,
    error_message   VARCHAR(500),
    is_enabled      BOOLEAN        DEFAULT TRUE,
    priority        INT            DEFAULT 100,
    created_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality_rules IS '数据质量校验规则表';
COMMENT ON COLUMN data_quality_rules.rule_code IS '规则代码';
COMMENT ON COLUMN data_quality_rules.rule_name IS '规则名称';
COMMENT ON COLUMN data_quality_rules.rule_type IS '规则类型: mandatory-必填校验, format-格式校验, business-业务校验';
COMMENT ON COLUMN data_quality_rules.check_field IS '校验字段';
COMMENT ON COLUMN data_quality_rules.check_expression IS '校验表达式';
COMMENT ON COLUMN data_quality_rules.error_message IS '错误信息';
COMMENT ON COLUMN data_quality_rules.is_enabled IS '是否启用';
COMMENT ON COLUMN data_quality_rules.priority IS '优先级（数字越小越优先）';

-- 插入数据质量规则
INSERT INTO data_quality_rules (rule_code, rule_name, rule_type, check_field, error_message, priority) VALUES
('R001', '统一社会信用代码必填校验', 'mandatory', 'credit_code', '统一社会信用代码不能为空', 10),
('R002', '企业名称必填校验', 'mandatory', 'name', '企业名称不能为空', 10),
('R003', '法定代表人必填校验', 'mandatory', 'legal_rep', '法定代表人不能为空', 10),
('R004', '成立日期必填校验', 'mandatory', 'found_date', '成立日期不能为空', 20),
('R005', '登记状态必填校验', 'mandatory', 'status', '登记状态不能为空', 20),
('R006', '住所必填校验', 'mandatory', 'address', '住所不能为空', 20),
('R007', '统一社会信用代码前缀校验', 'format', 'credit_code', '统一社会信用代码必须以91、92或12开头', 30),
('R008', '统一社会信用代码长度校验', 'format', 'credit_code', '统一社会信用代码长度必须为18位', 30),
('R009', '企业名称汉字校验', 'format', 'name', '企业名称只能包含汉字和括号', 40),
('R010', '企业名称最小长度校验', 'format', 'name', '企业名称长度不能少于4个字符', 40),
('R011', '企业名称最大长度校验', 'format', 'name', '企业名称长度不能超过26个字符', 40),
('R012', '法定代表人汉字校验', 'format', 'legal_rep', '法定代表人只能是汉字', 50),
('R013', '法定代表人最小长度校验', 'format', 'legal_rep', '法定代表人长度不能少于2个字符', 50),
('R014', '法定代表人最大长度校验', 'format', 'legal_rep', '法定代表人长度不能超过5个字符', 50);

-- =============================================
-- 4. 数据质量校验结果表
-- =============================================
DROP TABLE IF EXISTS data_quality_results CASCADE;

CREATE TABLE data_quality_results (
    id              BIGSERIAL PRIMARY KEY,
    company_id      BIGINT         REFERENCES company_fact(id),
    rule_code       VARCHAR(50)    REFERENCES data_quality_rules(rule_code),
    check_result    VARCHAR(20)    NOT NULL,
    error_detail    TEXT,
    checked_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality_results IS '数据质量校验结果表';
COMMENT ON COLUMN data_quality_results.company_id IS '企业ID';
COMMENT ON COLUMN data_quality_results.rule_code IS '规则代码';
COMMENT ON COLUMN data_quality_results.check_result IS '校验结果: PASS-通过, FAIL-不通过';
COMMENT ON COLUMN data_quality_results.error_detail IS '错误详情';

-- =============================================
-- 5. 数据统计查询
-- =============================================

-- 查看各测试场景数据统计
SELECT test_scene, COUNT(*) as count
FROM company_fact
GROUP BY test_scene
ORDER BY test_scene;

-- 查看总数据量
SELECT COUNT(*) as total_count FROM company_fact;

-- =============================================
-- 数据集说明
-- =============================================
-- 本数据集用于企业名称服务的单元测试和集成测试
-- 包含真实企业数据（来自国家企业信用信息公示系统）作为基准
-- 覆盖企业名称服务的主要校验规则：
--   - 关键字段完整性校验
--   - 统一社会信用代码格式校验
--   - 企业名称格式校验
--   - 法定代表人格式校验
--   - 重复数据识别（同名不同企、同企不同名）
-- 所有测试数据均为模拟数据，仅供测试使用
