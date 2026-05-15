-- =============================================
-- 企业名称服务测试数据SQL脚本
-- 生成时间: 2026-05-15 14:30:00
-- =============================================

-- 插入正常企业数据
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene, create_time) VALUES
('550e8400-e29b-41d4-a716-446655440001', '91350200MA348KJW1K', '福建华为技术有限公司', '任正非', '福建省厦门市思明区软件园二期', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440002', '91310000MA1FB4HC1Q', '上海阿里巴巴信息技术有限公司', '张勇', '上海市浦东新区张江高科技园区', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440003', '91440300MA5DRT3D9M', '深圳腾讯计算机系统有限公司', '马化腾', '广东省深圳市南山区科技园', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440004', '91330100MA27WXK87E', '杭州网易网络有限公司', '丁磊', '浙江省杭州市滨江区网易大厦', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440005', '91110000MA008T4Y8L', '北京百度网讯科技有限公司', '李彦宏', '北京市海淀区中关村软件园', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440006', '91320100MA1N0T5C2P', '南京苏宁易购电子商务有限公司', '张近东', '江苏省南京市玄武区苏宁大道', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440007', '91420100MA4K0X5D7Q', '武汉小米科技有限公司', '雷军', '湖北省武汉市东湖新技术开发区', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440008', '91440100MA3CJC3E6H', '广州字节跳动网络技术有限公司', '张一鸣', '广东省广州市天河区珠江新城', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440009', '91500000MA5U6K8E2F', '重庆京东世纪贸易有限公司', '刘强东', '重庆市渝北区两江新区', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440010', '91510100MA61R8T7XQ', '成都美团点评信息技术有限公司', '王兴', '四川省成都市高新区天府大道', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440011', '91350500MA2YXTK38K', '泉州安踏体育用品有限公司', '丁世忠', '福建省泉州市晋江市安踏工业园', 1, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440012', '91330200MA293KDE7Q', '宁波雅戈尔集团股份有限公司', '李如成', '浙江省宁波市鄞州区雅戈尔大道', 1, CURRENT_TIMESTAMP);

-- 插入异常企业数据（用于测试校验逻辑）
-- 注意：这些数据可能违反约束，仅用于测试校验逻辑
/*
-- 场景: missing_credit_code
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440013', '', '测试缺失信用代码公司', '张三', '北京市朝阳区', 1);

-- 场景: missing_name
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440014', '91350200MA348KJW1K', '', '李四', '上海市浦东新区', 1);

-- 场景: missing_legal_rep
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440015', '91310000MA1FB4HC1Q', '测试缺失法定代表人公司', '', '广东省深圳市', 1);

-- 场景: missing_address
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440016', '91350200MA348KJW1K', '测试缺失地址公司', '王五', '', 1);

-- 场景: invalid_credit_code_prefix
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440017', '88350200MA348KJW1K', '测试信用代码前缀错误公司', '赵六', '杭州市西湖区', 1);

-- 场景: invalid_credit_code_length
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440018', '91350200MA', '测试信用代码长度错误公司', '孙七', '南京市鼓楼区', 1);

-- 场景: invalid_name_english
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440019', '91350200MA348KJW1K', 'ABC公司', '周八', '武汉市洪山区', 1);

-- 场景: invalid_name_too_short
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440020', '91310000MA1FB4HC1Q', '科技', '吴九', '广州市天河区', 1);

-- 场景: invalid_name_too_long
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440021', '91440300MA5DRT3D9M', '这是一个企业名称长度超过二十六个字符的超长名称测试公司', '郑十', '成都市武侯区', 1);

-- 场景: invalid_name_all_parentheses
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440022', '91330100MA27WXK87E', '（全括号测试）', '冯十一', '重庆市渝中区', 1);

-- 场景: invalid_name_pinyin
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440023', '91110000MA008T4Y8L', 'ZhangSan', '陈十二', '西安市雁塔区', 1);

-- 场景: invalid_legal_rep_too_short
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440024', '91320100MA1N0T5C2P', '测试法定代表人过短公司', 'A', '苏州市工业园区', 1);

-- 场景: invalid_legal_rep_too_long
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440025', '91420100MA4K0X5D7Q', '测试法定代表人过长公司', '一二三四五六七', '青岛市崂山区', 1);

-- 场景: invalid_legal_rep_not_chinese
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440026', '91440100MA3CJC3E6H', '测试法定代表人非汉字公司', 'LiMing', '天津市南开区', 1);

-- 场景: same_name_different_company
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440027', '91350200MA348KJW1K', '同名不同企测试公司', '黄十五', '长沙市岳麓区', 1);

INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440028', '91310000MA1FB4HC2Q', '同名不同企测试公司', '杨十六', '郑州市金水区', 1);

-- 场景: same_company_different_name
INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440029', '91440300MA5DRT3D9M', '同企不同名测试公司（旧名）', '朱十七', '合肥市蜀山区', 1);

INSERT INTO company_fact (ent_code, credit_code, name, legal_rep, address, ent_record_scene)
VALUES ('550e8400-e29b-41d4-a716-446655440030', '91440300MA5DRT3D9M', '同企不同名测试公司（新名）', '朱十七', '合肥市蜀山区', 1);
*/
