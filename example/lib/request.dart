import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';

Logger logger = Logger();

/// OKX参数
class OkxArg {
  final String channelName;
  final String timeCode;
  final String instId;

  OkxArg({required this.channelName, required this.timeCode, required this.instId});

  // 将 Args 对象解析为 WebSocket Map
  Map<String, String> toWebSocketMap() {
    return {
      "channel": "$channelName$timeCode",
      "instId": instId,
    };
  }

  @override
  String toString() {
    return 'OkxArg{channelName: $channelName, timeCode: $timeCode, instId: $instId}';
  }
}

///  封装 OKX 市场 WebSocket 连接的服务类
class WebSocketManager {
  late WebSocket _socket;
  final String url = "wss://ws.okx.com:8443/ws/v5/business"; //公共数据
  final List<OkxArg> _subscribedChannels = [];
  final void Function(String message) onMessage;

  /// 构造函数，传入 WebSocket URL 和消息回调函数
  WebSocketManager({required this.onMessage});

  /// 连接到 WebSocket 服务器
  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect(url);
      logger.d('WebSocket 已握手成功 $url');

      // 监听消息
      _socket.listen((data) {
        onMessage(data); // 处理接收到的消息
      });
    } catch (e) {
      logger.e("WebSocket 连接失败: $e");
    }
  }

  /// 订阅频道 instId 币种  channel 通道
  void subscribe(OkxArg arg) {
    if (_subscribedChannels.contains(arg)) {
      logger.e('已经订阅过 ${arg.toString()}');
      return;
    }

    final message = {
      "op": "subscribe",
      "args": [arg.toWebSocketMap()]
    };

    _socket.add(jsonEncode(message)); // 发送订阅请求
    _subscribedChannels.add(arg); // 记录订阅的频道
    logger.d('订阅成功 ${arg.toString()}');
  }

  /// 修改订阅，取消当前频道订阅并重新订阅新频道
  void modifySubscription({required OkxArg oldArg, required OkxArg newArg}) {
    unsubscribe(oldArg); // 取消旧频道的订阅
    subscribe(newArg); // 订阅新频道
  }

  /// 取消订阅频道
  void unsubscribe(OkxArg arg) {
    if (!_subscribedChannels.contains(arg)) {
      logger.e('没有这个订阅 ${arg.toString()}');
      return;
    }

    final message = {
      "op": "unsubscribe",
      "args": [arg.toWebSocketMap()]
    };

    _socket.add(jsonEncode(message)); // 发送取消订阅请求
    _subscribedChannels.remove(arg); // 从已订阅的频道中移除
    logger.d('已取消订阅 ${arg.toString()}');
  }

  /// 关闭 WebSocket 连接
  void close() {
    _socket.close();
    logger.d('地址 $url 已关闭连接');
  }
}

/// 用于封装 OKX 市场 REST API 请求的服务类
abstract class Request {
  static Future<T> _request<T>(String path, {Map<String, dynamic>? params}) async {
    try {
      // 代理地址
      final client = await _createHttpClientWithProxy();
      debugPrint('如果请求失败，搜索 [ _createHttpClientWithProxy ] 设置代理');
      // 构建 URI，处理 query 参数
      final uri = Uri.parse(path).replace(queryParameters: params);

      // 发送 GET 请求
      http.Response response = await client.get(uri);

      // 解析 JSON
      final Map<String, dynamic> data = jsonDecode(response.body);

      // 处理返回数据
      if (response.statusCode == 200) {
        if (data['code'] != "0") {
          throw data['msg'];
        } else {
          return data['data'] as T;
        }
      }

      throw "连接失败 OKX API 需要配置代理";
    } catch (e) {
      return Future.error('异常: $e\npath: $path\nparams: $params');
    }
  }

  static Future<http.Client> _createHttpClientWithProxy() async {
    final httpClient = HttpClient();
    // httpClient.findProxy = (uri) {
    //   return "PROXY 127.0.0.1:7890";
    // };
    // httpClient.badCertificateCallback = (cert, host, port) => true; // 允许自签名证书

    return IOClient(httpClient);
  }

  /// 获取指数K线数据
  ///
  /// [instId]：现货指数，例如 "BTC-USD"
  ///
  /// [after]：请求此时间戳之前（更旧数据）的分页内容，传的值为对应接口的时间戳
  ///
  /// [before]：请求此时间戳之后（更新数据）的分页内容，传的值为对应接口的时间戳
  ///
  /// [bar]：时间粒度，默认 "1m"，可选值：1m/3m/5m/15m/30m/1H/2H/4H/6H/12H/1D/1W/1M/3M
  ///
  /// [limit]：分页返回的结果集数量，最大为 100，不填默认返回 100 条
  static Future<List> fetchIndexCandles<List>({
    required String instId,
    String? after,
    String? before,
    String bar = '1m',
    String? limit,
  }) async {
    return _request<List>('https://www.okx.com/api/v5/market/index-candles', params: {
      'instId': instId,
      if (after != null) 'after': after,
      if (before != null) 'before': before,
      'bar': bar,
      if (limit != null) 'limit': limit,
    });
  }
}
