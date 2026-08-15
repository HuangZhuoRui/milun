import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoami/data/models/hexagram_detail.dart';
import 'package:whoami/data/repositories/iching_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('易经六十四卦与三百八十四爻全量典籍数据严格校验', () {
    late List<HexagramDetail> hexagrams;

    setUpAll(() {
      final file = File('assets/data/iching_64.json');
      final jsonStr = file.readAsStringSync();
      final list = json.decode(jsonStr) as List<dynamic>;
      hexagrams = list.map((e) => HexagramDetail.fromJson(e as Map<String, dynamic>)).toList();
      IChingRepository.instance.loadFromList(hexagrams);
    });

    test('六十四卦序与数量严格符合文王六十四卦体系 (1 至 64)', () {
      expect(hexagrams.length, 64);
      for (int i = 0; i < 64; i++) {
        expect(hexagrams[i].id, i + 1);
        expect(hexagrams[i].code.length, 6);
        expect(hexagrams[i].yaos.length, 6);
      }
    });

    test('全量三百八十四爻爻辞与象传非空且无模板占位符', () {
      for (var h in hexagrams) {
        expect(h.guaci.isNotEmpty, true);
        expect(h.tuan.isNotEmpty, true);
        expect(h.xiang.isNotEmpty, true);
        expect(h.overview.isNotEmpty, true);
        expect(h.personality.isNotEmpty, true);
        expect(h.career.isNotEmpty, true);
        expect(h.wealth.isNotEmpty, true);
        expect(h.love.isNotEmpty, true);
        expect(h.health.isNotEmpty, true);
        expect(h.advice.isNotEmpty, true);

        for (int yIdx = 0; yIdx < 6; yIdx++) {
          final yao = h.yaos[yIdx];
          expect(yao.index, yIdx + 1);
          expect(yao.name.isNotEmpty, true);
          expect(yao.text.isNotEmpty, true);
          expect(yao.xiang.isNotEmpty, true);
          expect(yao.interpretation.isNotEmpty, true);

          // 验证绝无通用占位符
          expect(yao.text.contains('贞吉，利有攸往') && yao.text.length < 15, false);
          expect(yao.xiang.contains('顺应时势也'), false);
        }
      }
    });

    test('经典卦象核心经文抽样验证准确无误 (乾、坤、谦、既济)', () {
      // 乾卦
      final qian = IChingRepository.instance.getById(1);
      expect(qian.name, '乾为天');
      expect(qian.guaci, '乾：元亨利贞。');
      expect(qian.yaos[0].text, '初九：潜龙勿用。');
      expect(qian.yaos[4].text, '九五：飞龙在天，利见大人。');
      expect(qian.yaos[5].text, '上九：亢龙有悔。');

      // 坤卦
      final kun = IChingRepository.instance.getById(2);
      expect(kun.name, '坤为地');
      expect(kun.yaos[0].text, '初六：履霜，坚冰至。');
      expect(kun.yaos[1].text, '六二：直，方，大，不习无不利。');

      // 谦卦
      final qianGua = IChingRepository.instance.getById(15);
      expect(qianGua.name, '地山谦');
      expect(qianGua.fortuneTier, '上上卦');
      expect(qianGua.yaos[0].text, '初六：谦谦君子，用涉大川，吉。');
      expect(qianGua.yaos[2].text, '九三：劳谦，君子有终，吉。');

      // 既济卦
      final jiJi = IChingRepository.instance.getById(63);
      expect(jiJi.name, '水火既济');
      expect(jiJi.yaos[0].text, '初九：曳其轮，濡其尾，无咎。');
      expect(jiJi.yaos[1].text, '六二：妇丧其茀，勿逐，七日得。');
    });
  });
}
