import 'package:flutter/material.dart';

/// K 线图主题配置
class CandlestickThemeConfig {
  /// 涨跌 K 线颜色
  final Color bullishColor; // 上涨 K 线颜色
  final Color bearishColor; // 下跌 K 线颜色

  /// 影线（蜡烛线的上下影线）
  final double wickWidth; // 影线宽度 1倍时

  /// 蜡烛图样式
  final double candleWidth; // 蜡烛宽度 1倍时
  final double candleMargin; // 蜡烛边距 1倍时(左右均为该值)

  /// 背景 & 网格
  final Color backgroundColor; // 图表背景颜色
  final Color gridColor; // 网格线颜色
  final int gridCount; // 时间网格线数量
  final double gridLineWidth; // 网格线宽度
  final bool gridVisibility; // 是否显示网格

  /// 坐标轴 & 文字
  final TextStyle timeLabelStyle; // 时间轴字体样式
  final TextStyle priceLabelStyle; // 价格轴字体样式

  /// 十字光标 & 交互
  final Color crosshairColor; // 十字光标颜色
  // final double crosshairLineWidth; // 十字光标线条宽度
  // final Color crosshairLabelBackgroundColor; // 十字光标标签背景颜色
  // final TextStyle crosshairLabelTextStyle; // 十字光标标签字体样式

  /// 交易量显示
  // final Color volumeUpColor; // 成交量柱状图上涨颜色
  // final Color volumeDownColor; // 成交量柱状图下跌颜色
  // final double volumeBarWidth; // 成交量柱状图宽度

  /// 指标线（如均线）
  // final Color indicatorLineColor; // 均线/指标线颜色
  // final double indicatorLineWidth; // 均线/指标线宽度

  /// 提示框（悬浮信息框）
  // final Color tooltipBackgroundColor; // 悬浮提示框背景颜色
  // final TextStyle tooltipTextStyle; // 悬浮提示框字体样式

  /// 安全区域
  final double topSafeAreaHeight; // 顶部安全区域高度
  final double bottomSafeAreaHeight; // 底部安全区域高度
  final double bottomTimeLabelHeight; // 底部时间轴高度
  final double latestCandleRightMargin; //最新蜡烛距右侧区域

  /// 缩放相关
  final double minCandlestickWidth; // 最小蜡烛宽度，默认为 2px/
  final double maxScale; // 最大缩放倍数
  final double scaleYAreaWidth; // 纵向缩放响应区域宽度
  final double minScaleY; // 纵向最小缩放倍数
  final double maxScaleY; // 纵向最大缩放倍数
  /// 动画相关
  final Duration animationDuration;

  /// 最高最低价标记
  final TextStyle extremePriceStyle; // 最高最低价文字样式
  final Color extremePriceLineColor; // 最高最低价线条颜色
  final double extremePriceLineWidth; // 最高最低价线条宽度

  /// 历史数据加载
  final double historyLoadThreshold; // 历史数据触发阈值

  /// 构造函数
  const CandlestickThemeConfig({
    this.bullishColor = Colors.green,
    this.bearishColor = Colors.redAccent,
    this.wickWidth = 1.0,
    this.candleWidth = 8.0,
    this.candleMargin = 0.5,
    this.backgroundColor = const Color(0xfffefefe),
    this.gridColor = const Color(0xffeeeeee),
    this.gridCount = 6,
    this.gridLineWidth = 0.5,
    this.gridVisibility = true,
    this.timeLabelStyle = const TextStyle(color: Colors.grey, fontSize: 8),
    this.priceLabelStyle = const TextStyle(color: Colors.black54, fontSize: 8),
    this.topSafeAreaHeight = 24.0, // 默认值为24
    this.bottomSafeAreaHeight = 24.0,
    this.bottomTimeLabelHeight = 16.0,
    this.minCandlestickWidth = 1.0,
    this.maxScale = 3.0,
    this.scaleYAreaWidth = 100.0, // 默认值为100
    this.minScaleY = 0.1, // 默认最小缩放为0.5倍
    this.maxScaleY = 10.0, // 默认最大缩放为2倍
    this.latestCandleRightMargin = 100.0, // 默认100
    this.animationDuration = const Duration(milliseconds: 300), // 默认300毫秒
    this.crosshairColor = Colors.black87,
    this.extremePriceStyle = const TextStyle(color: Colors.black, fontSize: 12),
    this.extremePriceLineColor = Colors.black,
    this.extremePriceLineWidth = 0.4,

    /// 历史数据加载
    this.historyLoadThreshold = 50.0, // 默认50像素
  });

  CandlestickThemeConfig copyWith({
    Color? bullishColor,
    Color? bearishColor,
    double? wickWidth,
    double? candleWidth,
    double? candleMargin,
    Color? backgroundColor,
    Color? gridColor,
    int? gridCount,
    double? gridLineWidth,
    bool? gridVisibility,
    TextStyle? timeLabelStyle,
    TextStyle? priceLabelStyle,
    TextStyle? extremePriceStyle,
    Color? extremePriceLineColor,
    double? extremePriceLineWidth,
    double? topSafeAreaHeight,
    double? bottomSafeAreaHeight,
    double? bottomTimeLabelHeight,
    double? minCandlestickWidth,
    double? maxScale,
    double? scaleYAreaWidth,
    double? minScaleY,
    double? maxScaleY,
    double? latestCandleRightMargin,
    Duration? animationDuration,
    Color? crosshairColor,
    double? historyLoadThreshold,
  }) {
    return CandlestickThemeConfig(
      bullishColor: bullishColor ?? this.bullishColor,
      bearishColor: bearishColor ?? this.bearishColor,
      wickWidth: wickWidth ?? this.wickWidth,
      candleWidth: candleWidth ?? this.candleWidth,
      candleMargin: candleMargin ?? this.candleMargin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      gridCount: gridCount ?? this.gridCount,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      gridVisibility: gridVisibility ?? this.gridVisibility,
      timeLabelStyle: timeLabelStyle ?? this.timeLabelStyle,
      priceLabelStyle: priceLabelStyle ?? this.priceLabelStyle,
      extremePriceStyle: extremePriceStyle ?? this.extremePriceStyle,
      extremePriceLineColor: extremePriceLineColor ?? this.extremePriceLineColor,
      extremePriceLineWidth: extremePriceLineWidth ?? this.extremePriceLineWidth,
      topSafeAreaHeight: topSafeAreaHeight ?? this.topSafeAreaHeight,
      bottomSafeAreaHeight: bottomSafeAreaHeight ?? this.bottomSafeAreaHeight,
      bottomTimeLabelHeight: bottomTimeLabelHeight ?? this.bottomTimeLabelHeight,
      minCandlestickWidth: minCandlestickWidth ?? this.minCandlestickWidth,
      maxScale: maxScale ?? this.maxScale,
      scaleYAreaWidth: scaleYAreaWidth ?? this.scaleYAreaWidth,
      minScaleY: minScaleY ?? this.minScaleY,
      maxScaleY: maxScaleY ?? this.maxScaleY,
      latestCandleRightMargin: latestCandleRightMargin ?? this.latestCandleRightMargin,
      animationDuration: animationDuration ?? this.animationDuration,
      crosshairColor: crosshairColor ?? this.crosshairColor,
      historyLoadThreshold: historyLoadThreshold ?? this.historyLoadThreshold,
    );
  }
}
