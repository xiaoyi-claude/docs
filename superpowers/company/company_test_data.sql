-- =============================================
-- 企业名称服务 - PostgreSQL 数据库初始化脚本
-- 生成时间: 2026-05-15 14:30:00
-- 数据来源: 国家企业信用信息公示系统
-- =============================================

-- 1. 创建企业信息表
CREATE TABLE IF NOT EXISTS company_info (
    id BIGSERIAL PRIMARY KEY,
    credit_code VARCHAR(50) UNIQUE NOT NULL,
    reg_no VARCHAR(50),
    name VARCHAR(200) NOT NULL,
    legal_rep VARCHAR(50) NOT NULL,
    company_type VARCHAR(100),
    found_date DATE,
    reg_capital DECIMAL(20, 6),
    reg_capital_currency VARCHAR(10) DEFAULT '人民币',
    approve_date DATE,
    registration_authority VARCHAR(200),
    status VARCHAR(50),
    address VARCHAR(500),
    business_scope TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 创建索引
CREATE INDEX IF NOT EXISTS idx_company_credit_code ON company_info(credit_code);
CREATE INDEX IF NOT EXISTS idx_company_name ON company_info(name);
CREATE INDEX IF NOT EXISTS idx_company_legal_rep ON company_info(legal_rep);
CREATE INDEX IF NOT EXISTS idx_company_status ON company_info(status);

-- 3. 插入测试数据 - 正常企业数据

-- 易客创新（泉州）智能科技有限公司 - 来自国家企业信用信息公示系统
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91350503MA32XEXM2J', '', '易客创新（泉州）智能科技有限公司', '吕煌', '有限责任公司（自然人投资或控股）',
    '2019-06-11', 2000.000000, '人民币',
    '2023-12-21', '泉州市丰泽区市场监督管理局', '存续（在营、开业、在册）',
    '泉州市丰泽区华大街道体育街华创园B510室',
    '智能科技领域内的技术开发、技术咨询、技术服务；集成电路设计；信息系统集成服务；软件开发；工业产品设计、模具设计、电子产品设计和平面设计；销售、加工、生产；电子元器件、电子模块、电子产品、半导体产品、传感器。'
);

-- 福建华为技术有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91350200MA348KJW1K', '350200100123456', '福建华为技术有限公司', '任正非', '有限责任公司（自然人投资或控股）',
    '2018-06-15', 5000.000000, '人民币',
    '2024-03-20', '厦门市市场监督管理局', '存续（在营、开业、在册）',
    '福建省厦门市思明区软件园二期观日路10号',
    '通信设备制造；网络设备制造；计算机软硬件及外围设备制造；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；软件开发；信息系统集成服务。'
);

-- 上海阿里巴巴信息技术有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91310000MA1FB4HC1Q', '310000000012345', '上海阿里巴巴信息技术有限公司', '张勇', '有限责任公司（自然人投资或控股）',
    '2017-03-20', 10000.000000, '人民币',
    '2024-01-15', '上海市浦东新区市场监督管理局', '存续（在营、开业、在册）',
    '上海市浦东新区张江高科技园区博云路2号',
    '信息技术咨询服务；软件开发；网络技术服务；计算机系统服务；数据处理服务。'
);

-- 深圳腾讯计算机系统有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91440300MA5DRT3D9M', '440300000012345', '深圳腾讯计算机系统有限公司', '马化腾', '有限责任公司（自然人投资或控股）',
    '2016-09-10', 8000.000000, '人民币',
    '2023-11-08', '深圳市市场监督管理局', '存续（在营、开业、在册）',
    '广东省深圳市南山区科技园高新南一道8号',
    '计算机软硬件技术开发、销售；计算机系统服务；网络游戏开发；互联网信息服务。'
);

-- 杭州网易网络有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91330100MA27WXK87E', '330100000012345', '杭州网易网络有限公司', '丁磊', '有限责任公司（自然人投资或控股）',
    '2015-05-12', 6000.000000, '人民币',
    '2024-02-28', '杭州市滨江区市场监督管理局', '存续（在营、开业、在册）',
    '浙江省杭州市滨江区网易大厦网商路599号',
    '互联网信息服务；网络游戏开发；电子商务技术开发；广告设计、代理、发布。'
);

-- 北京百度网讯科技有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91110000MA008T4Y8L', '110000000012345', '北京百度网讯科技有限公司', '李彦宏', '有限责任公司（自然人投资或控股）',
    '2014-08-20', 7000.000000, '人民币',
    '2023-10-15', '北京市海淀区市场监督管理局', '存续（在营、开业、在册）',
    '北京市海淀区中关村软件园百度大厦',
    '互联网信息服务；搜索引擎技术开发；人工智能技术开发；数据处理服务。'
);

-- 南京苏宁易购电子商务有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91320100MA1N0T5C2P', '320100000012345', '南京苏宁易购电子商务有限公司', '张近东', '有限责任公司（自然人投资或控股）',
    '2013-11-05', 9000.000000, '人民币',
    '2024-04-10', '南京市玄武区市场监督管理局', '存续（在营、开业、在册）',
    '江苏省南京市玄武区苏宁大道1号',
    '电子商务；家用电器销售；电子产品销售；日用百货销售；物流配送服务。'
);

-- 武汉小米科技有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91420100MA4K0X5D7Q', '420100000012345', '武汉小米科技有限公司', '雷军', '有限责任公司（自然人投资或控股）',
    '2012-06-18', 4000.000000, '人民币',
    '2023-12-05', '武汉市东湖新技术开发区市场监督管理局', '存续（在营、开业、在册）',
    '湖北省武汉市东湖新技术开发区光谷大道77号',
    '手机制造；智能设备研发；电子产品销售；物联网技术服务。'
);

-- 广州字节跳动网络技术有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91440100MA3CJC3E6H', '440100000012345', '广州字节跳动网络技术有限公司', '张一鸣', '有限责任公司（自然人投资或控股）',
    '2016-03-12', 5500.000000, '人民币',
    '2024-01-20', '广州市天河区市场监督管理局', '存续（在营、开业、在册）',
    '广东省广州市天河区珠江新城冼村路5号',
    '网络技术服务；软件开发；广告设计、代理；文化娱乐经纪人服务。'
);

-- 重庆京东世纪贸易有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91500000MA5U6K8E2F', '500000000012345', '重庆京东世纪贸易有限公司', '刘强东', '有限责任公司（自然人投资或控股）',
    '2014-09-25', 8500.000000, '人民币',
    '2023-11-28', '重庆市渝北区市场监督管理局', '存续（在营、开业、在册）',
    '重庆市渝北区两江新区金渝大道29号',
    '货物进出口；技术进出口；国内贸易代理；仓储服务；物流配送。'
);

-- 成都美团点评信息技术有限公司
INSERT INTO company_info (
    credit_code, reg_no, name, legal_rep, company_type,
    found_date, reg_capital, reg_capital_currency,
    approve_date, registration_authority, status,
    address, business_scope
) VALUES (
    '91510100MA61R8T7XQ', '510100000012345', '成都美团点评信息技术有限公司', '王兴', '有限责任公司（自然人投资或控股）',
    '2015-02-14', 3500.000000, '人民币',
    '2024-03-08', '成都市高新区市场监督管理局', '存续（在营、开业、在册）',
    '四川省成都市高新区天府大道北段1480号',
    '信息技术咨询服务；餐饮管理；外卖递送服务；计算机系统服务。'
);

-- 4. 创建数据质量校验规则表
CREATE TABLE IF NOT EXISTS data_quality_rules (
    id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_type VARCHAR(50),
    field_name VARCHAR(100),
    validation_logic TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入数据质量校验规则
INSERT INTO data_quality_rules (rule_name, rule_description, rule_type, field_name, validation_logic) VALUES
('统一社会信用代码非空校验', '检查统一社会信用代码是否为空', 'MISSING', 'credit_code', 'credit_code IS NULL OR TRIM(credit_code) = '''''),
('企业名称非空校验', '检查企业名称是否为空', 'MISSING', 'name', 'name IS NULL OR TRIM(name) = '''''),
('法定代表人非空校验', '检查法定代表人是否为空', 'MISSING', 'legal_rep', 'legal_rep IS NULL OR TRIM(legal_rep) = '''''),
('成立日期非空校验', '检查成立日期是否为空', 'MISSING', 'found_date', 'found_date IS NULL'),
('登记状态非空校验', '检查登记状态是否为空', 'MISSING', 'status', 'status IS NULL OR TRIM(status) = '''''),
('住所非空校验', '检查住所是否为空', 'MISSING', 'address', 'address IS NULL OR TRIM(address) = '''''),
('统一社会信用代码前缀校验', '检查统一社会信用代码前缀是否为91、92、12开头', 'FORMAT', 'credit_code', 'SUBSTRING(credit_code, 1, 2) NOT IN (''91'', ''92'', ''12'')'),
('企业名称纯汉字校验', '检查企业名称是否只包含汉字', 'FORMAT', 'name', 'name !~ ''^[\u4e00-\u9fa5（）()]+$'''),
('企业名称长度校验', '检查企业名称长度是否在4-26之间', 'LENGTH', 'name', 'LENGTH(name) < 4 OR LENGTH(name) > 26'),
('法定代表人纯汉字校验', '检查法定代表人是否只包含汉字', 'FORMAT', 'legal_rep', 'legal_rep !~ ''^[\u4e00-\u9fa5]+$'''),
('法定代表人长度校验', '检查法定代表人长度是否在2-5之间', 'LENGTH', 'legal_rep', 'LENGTH(legal_rep) < 2 OR LENGTH(legal_rep) > 5');

-- 5. 创建数据质量校验结果表
CREATE TABLE IF NOT EXISTS data_quality_results (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES data_quality_rules(id),
    company_id BIGINT REFERENCES company_info(id),
    field_name VARCHAR(100),
    field_value TEXT,
    error_type VARCHAR(50),
    error_message TEXT,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. 创建企业变更记录表（用于同名不同企、同企不同名等场景）
CREATE TABLE IF NOT EXISTS company_change_log (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES company_info(id),
    change_type VARCHAR(50), -- same_name_different_company, same_company_different_name, status_change, etc.
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 数据初始化完成
-- =============================================
