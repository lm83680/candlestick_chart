import 'package:flutter/material.dart';

import '../rust/api/calculator.dart';
import '../rust/api/models.dart';

/// 服务器接口中单根蜡烛的描述方式 `List<String>`
/// [ts,o,h,l,c,confirm]`
typedef ServiceCandleItem = List<String>;

/// 蜡烛列表集合
typedef Candlesticks = List<Candlestick>;

class CandlestickChartController extends ChangeNotifier {
  final Candlesticks _candlesticks = [];
  bool _autoFollow = true; // 是否自动跟随
  bool get autoFollow => _autoFollow;

  set autoFollow(bool value) {
    if (_autoFollow != value) {
      _autoFollow = value;
      notifyListeners();
    }
  }

  Candlesticks get candlesticks => _candlesticks;
  double get nowPrice => _candlesticks.isEmpty ? 0 : _candlesticks.last.close;

  /// 根据下标获取某一段蜡烛
  Candlestick get(int index) {
    assert(index >= 0 && index < _candlesticks.length);
    return _candlesticks[index];
  }

  /// 初始化列表，第一批数据
  /// 或者重置列表，替换为新的数据
  Future<void> setList(Candlesticks newList) async {
    _candlesticks.clear();
    _candlesticks.addAll(newList);
    notifyListeners();
  }

  /// 向后追加更多历史数据
  /// 手动追加历史数据时无法将offsetX 移动到正确位置，请使用 onLoadHistory 回调
  Future<void> backappendHistoryList(Candlesticks historyList) async {
    if (_candlesticks.isEmpty) {
      return setList(historyList);
    }
    if (historyList.first.timestamp < _candlesticks.last.timestamp) {
      _candlesticks.addAll(historyList);
      notifyListeners();
    }
  }

  /// 同步最新的蜡烛
  Future<void> syncCurrentCandlestick(Candlesticks newCandlesticks) async {
    if (newCandlesticks.isEmpty) return;

    // 处理空列表情况
    if (_candlesticks.isEmpty) {
      _candlesticks.addAll(newCandlesticks);
      notifyListeners();
      return;
    }

    // 快速路径：单数据更新
    if (newCandlesticks.length == 1) {
      final newCandle = newCandlesticks.first;
      final currentFirst = _candlesticks.first;

      if (newCandle.timestamp == currentFirst.timestamp) {
        _candlesticks[0] = newCandle;
      } else if (newCandle.timestamp > currentFirst.timestamp) {
        _candlesticks[0] = await currentFirst.markAsConfirmed();
        _candlesticks.insert(0, newCandle);
      }
      notifyListeners();
      return;
    }

    // 批量处理（优化正向遍历）
    final searchResult = await findCandlestickIndices(
      list: _candlesticks,
      timestamps: newCandlesticks.map((c) => c.timestamp).toSet(),
      limit: BigInt.from(newCandlesticks.length),
    );

    final updates = <int, Candlestick>{};
    final inserts = <Candlestick>[];

    // 确保按时间戳降序处理新数据（从最新到最旧）
    final sortedNewCandlesticks = List<Candlestick>.from(newCandlesticks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final newCandle in sortedNewCandlesticks) {
      if (searchResult.containsKey(newCandle.timestamp)) {
        updates[searchResult[newCandle.timestamp]!.toInt()] = newCandle;
      } else if (newCandle.timestamp > _candlesticks.first.timestamp) {
        inserts.add(newCandle);
      }
    }

    // 批量更新现有数据
    updates.forEach((index, candle) => _candlesticks[index] = candle);

    // 批量插入新数据（已按时间降序排序）
    if (inserts.isNotEmpty) {
      if (!_candlesticks.first.isConfirmed) {
        _candlesticks[0] = await _candlesticks[0].markAsConfirmed();
      }
      _candlesticks.insertAll(0, inserts);
    }

    notifyListeners();
  }

  // 获得最大最小价格
  Future<(double, double)> getPriceRange() async {
    if (_candlesticks.isEmpty) return (0.0, 0.0);
    var result = await findCandlesticksPriceRange(candlesticks: _candlesticks);
    return result;
  }

  final Map<String, Function> _stateCallbacks = {};

  // 注册命名回调
  void registerCallback(String name, Function callback) {
    _stateCallbacks[name] = callback;
  }

  // 移除指定回调
  void unregisterCallback(String name) {
    _stateCallbacks.remove(name);
  }

  // 清除所有回调
  void clearCallbacks() {
    _stateCallbacks.clear();
  }

  /// 触发指定回调
  ///
  /// followLatest - 立即跟随最新蜡烛
  void call(String name, [List<dynamic>? args]) {
    if (_stateCallbacks.containsKey(name)) {
      Function.apply(_stateCallbacks[name]!, args ?? []);
    }
  }

  @override
  void dispose() {
    clearCallbacks();
    super.dispose();
  }
}
