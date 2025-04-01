import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:candlestick_chart/candlestick_chart.dart';

/// 这个文件用于不断提供OKX的公共数据，不必关注内部实现
import 'request.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(MaterialApp(home: const ExampleApp()));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  CandlestickChartController chartController = CandlestickChartController();
  late final wsManager = WebSocketManager(
    onMessage: onMessage,
  );
  OkxArg currentCoin = OkxArg(channelName: 'index-candle', timeCode: "1m", instId: 'BTC-USD');

  @override
  void initState() {
    // no-live
    // getIndexCandles();
    // live
    getIndexCandles().then((_) => onSubscribe());
    super.initState();
  }

  Future<void> getIndexCandles() async {
    List<List<String>> data = ((await Request.fetchIndexCandles(
      instId: currentCoin.instId,
      bar: currentCoin.timeCode,
    )) as List)
        .cast<dynamic>()
        .map((innerList) {
      return (innerList as List).cast<String>();
    }).toList();
    await chartController.setList(await Candlestick.listFromServiceData(data: data));
    chartController.call('followLatest');
  }

  /// 开始订阅公共数据
  Future<void> onSubscribe() async {
    await wsManager.connect();
    wsManager.subscribe(currentCoin);
  }

  /// 订阅数据的回调
  Future<void> onMessage(String jsonString) async {
    var data = jsonDecode(jsonString);
    if (data['event'] != null) {
      logger.d("收到事件回调：\n$jsonString");
    } else {
      assert(data['data'] != null);
      // 安全类型转换
      final list = (data['data'] as List).cast<dynamic>().map((innerList) {
        return (innerList as List).cast<String>();
      }).toList();
      chartController.syncCurrentCandlestick(await Candlestick.listFromServiceData(data: list));
    }
  }

  Future<Candlesticks> getHistoryCandlesticks(Candlestick after) async {
    List<List<String>> data = ((await Request.fetchIndexCandles(
      instId: currentCoin.instId,
      bar: currentCoin.timeCode,
      after: after.timestamp.toString(),
    )) as List)
        .cast<dynamic>()
        .map((innerList) {
      return (innerList as List).cast<String>();
    }).toList();
    return await Candlestick.listFromServiceData(data: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: CandlestickChart(
          controller: chartController,
          onLoadHistory: getHistoryCandlesticks,
          buildLiveInfoWidget: (price, timestamp, inInScreen) => CandlestickWidgets.buildLatestPriceWidget(
            price,
            timestamp,
            inInScreen,
            () => chartController.call('followLatest'),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Text(
        currentCoin.instId,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(0xff181818),
      actions: [
        TextButton.icon(
          onPressed: () => getIndexCandles().then((_) => onSubscribe()),
          label: Text("Live", style: TextStyle(color: Colors.white)),
          icon: Icon(
            Icons.data_exploration,
            color: Colors.white,
          ),
        )
      ],
    );
  }
}
