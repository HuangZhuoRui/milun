/// 时辰反推助手卡片信息实体
class ShichenCardInfo {
  /// 时辰序号：0 至 11（对应子时至亥时）
  final int index;

  /// 地支简称（例如「子」、「丑」、「寅」）
  final String branch;

  /// 时辰全称与公历时间段（例如「子时 (23:00 - 01:00)」）
  final String name;

  /// 五行属性（例如「水」、「土」、「木」）
  final String element;

  /// 传统雅称时段（例如「夜半 / 三更」、「鸡鸣 / 四更」）
  final String alias;

  /// 东方人格原型定位
  final String archetype;

  /// 核心性情与思维特征
  final String temperament;

  /// 作息节律与相貌体态线索
  final String habitTrait;

  /// 适合人群画像标签关键词
  final String tag;

  const ShichenCardInfo({
    required this.index,
    required this.branch,
    required this.name,
    required this.element,
    required this.alias,
    required this.archetype,
    required this.temperament,
    required this.habitTrait,
    required this.tag,
  });
}

/// 十二时辰性格反推数据提供者
class HourFinderHelper {
  /// 十二时辰特征卡片全量数据
  static const List<ShichenCardInfo> cards = [
    ShichenCardInfo(
      index: 0,
      branch: '子',
      name: '子时 (23:00 - 01:00)',
      element: '水',
      alias: '夜半 / 三更',
      archetype: '灵动深邃的智谋家',
      temperament: '思维缜密敏锐，夜间灵感格外活跃，善于洞察人心与底层规律。',
      habitTrait: '出生在深夜万籁俱寂时；通常性格内敛沉静，眼神清亮有神，习惯深思熟虑。',
      tag: '高洞察力 · 策略家 · 敏锐直觉',
    ),
    ShichenCardInfo(
      index: 1,
      branch: '丑',
      name: '丑时 (01:00 - 03:00)',
      element: '土',
      alias: '鸡鸣 / 四更',
      archetype: '沉稳耐力的实干家',
      temperament: '坚韧不拔，极具责任心与工匠精神，不喜浮夸，重信守诺。',
      habitTrait: '出生在黎明前的深沉时刻；个性沉静持重，吃苦耐劳，做事一步一个脚印。',
      tag: '厚重沉稳 · 坚毅执着 · 靠谱信任',
    ),
    ShichenCardInfo(
      index: 2,
      branch: '寅',
      name: '寅时 (03:00 - 05:00)',
      element: '木',
      alias: '平旦 / 五更',
      archetype: '勇毅开创的先锋者',
      temperament: '魄力十足，富有领导欲望与正义感，敢为人先，气场强大。',
      habitTrait: '出生在天将破晓之时；身姿挺拔，说话干脆利落，具开创进取气质。',
      tag: '领袖魄力 · 敢为人先 · 开拓创新',
    ),
    ShichenCardInfo(
      index: 3,
      branch: '卯',
      name: '卯时 (05:00 - 07:00)',
      element: '木',
      alias: '日出 / 破晓',
      archetype: '温润优雅的雅致者',
      temperament: '性情温和谦逊，审美感知力极高，人缘极佳，追求身心和谐。',
      habitTrait: '出生在晨曦初现、旭日东升时；面容温润亲切，谈吐有礼，富有艺术才情。',
      tag: '温文尔雅 · 艺术审美 · 和善包容',
    ),
    ShichenCardInfo(
      index: 4,
      branch: '辰',
      name: '辰时 (07:00 - 09:00)',
      element: '土',
      alias: '食时 / 早膳',
      archetype: '宏才大略的筑梦者',
      temperament: '抱负远大，思维活跃多变，适应力极强，天生带有自信与威仪。',
      habitTrait: '出生在早晨阳气升腾、用早膳时；精力充沛，动作敏捷，富有野心。',
      tag: '自信从容 · 大局视野 · 活力充沛',
    ),
    ShichenCardInfo(
      index: 5,
      branch: '巳',
      name: '巳时 (09:00 - 11:00)',
      element: '火',
      alias: '隅中 / 巳时',
      archetype: '精明干练的洞见者',
      temperament: '逻辑清晰，善于交际沟通与资源整合，观察力敏锐，行事利落。',
      habitTrait: '出生在上午阳光渐烈之时；眼神敏锐，表达能力极强，富商业智慧。',
      tag: '口才出众 · 商业嗅觉 · 敏捷应变',
    ),
    ShichenCardInfo(
      index: 6,
      branch: '午',
      name: '午时 (11:00 - 13:00)',
      element: '火',
      alias: '日中 / 正午',
      archetype: '热情正气的光明使',
      temperament: '光明磊落，性格直爽热烈，具感染力与号召力，热爱展示才华。',
      habitTrait: '出生在正午烈日当空时；气宇轩昂，笑声爽朗，行事坦荡，富有感染力。',
      tag: '热情开朗 · 领袖魅力 · 光明坦荡',
    ),
    ShichenCardInfo(
      index: 7,
      branch: '未',
      name: '未时 (13:00 - 15:00)',
      element: '土',
      alias: '日昳 / 晌午',
      archetype: '慈悲敦厚的守护者',
      temperament: '外柔内刚，重情重义，富有同理心与艺术灵性，善解人意。',
      habitTrait: '出生在午后微暖斜阳时；神态柔和，情感细腻，注重家庭与朋友。',
      tag: '善良敦厚 · 同理共情 · 细腻温情',
    ),
    ShichenCardInfo(
      index: 8,
      branch: '申',
      name: '申时 (15:00 - 17:00)',
      element: '金',
      alias: '晡时 / 下午',
      archetype: '多才机变的行家里',
      temperament: '聪慧敏捷，幽默风趣，多才多艺，善于在逆境中灵活化解危机。',
      habitTrait: '出生在午后微风渐起时；眼神灵动，好奇心强，适应新事物极快。',
      tag: '机智敏捷 · 幽默多才 · 善于变通',
    ),
    ShichenCardInfo(
      index: 9,
      branch: '酉',
      name: '酉时 (17:00 - 19:00)',
      element: '金',
      alias: '日入 / 傍晚',
      archetype: '追求完美的品味家',
      temperament: '条理分明，注重仪表与生活品质，对细节要求苛刻，讲究原则。',
      habitTrait: '出生在夕阳西下、万家灯火初亮时；外貌清秀端正，行事严谨讲究。',
      tag: '完美主义 · 高端品味 · 严谨条理',
    ),
    ShichenCardInfo(
      index: 10,
      branch: '戌',
      name: '戌时 (19:00 - 21:00)',
      element: '土',
      alias: '黄昏 / 初更',
      archetype: '忠诚仗义的守卫者',
      temperament: '极具正义感与忠诚度，护短有担当，警惕性高，值得托付生死。',
      habitTrait: '出生在暮色四合之时；神情沉静坚定，重情义，防备心略重但极诚恳。',
      tag: '忠诚可靠 · 侠义担当 · 踏实守信',
    ),
    ShichenCardInfo(
      index: 11,
      branch: '亥',
      name: '亥时 (21:00 - 23:00)',
      element: '水',
      alias: '人定 / 二更',
      archetype: '通达豁达的隐修者',
      temperament: '心胸宽广，知足常乐，富有哲学慧根与包容力，乐于享受生活。',
      habitTrait: '出生在夜深人静、安然入眠时；性格温和平易近人，具福相与豁达胸怀。',
      tag: '随和豁达 · 智慧通透 · 乐天知命',
    ),
  ];
}
