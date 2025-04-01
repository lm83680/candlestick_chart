import 'package:flutter/material.dart';

import 'painters.dart';
import 'index.dart';

class CandlestickChart extends StatefulWidget {
  const CandlestickChart({
    super.key,
    required this.controller,
    this.theme = const CandlestickThemeConfig(),
    this.buildLiveInfoWidget,
    this.buildCrosshairTimeWidget,
    this.buildCrosshairCandleInfoWidget,
    this.onLoadHistory, // 添加历史数据加载回调
  });

  final CandlestickChartController controller;
  final CandlestickThemeConfig theme;

  /// 提供价格，周期结束时间戳，是否处于屏幕内，要求渲染最新价格浮窗
  final Widget Function(double, int, bool)? buildLiveInfoWidget;
  final Widget Function(int)? buildCrosshairTimeWidget;
  final Widget Function(Candlestick)? buildCrosshairCandleInfoWidget;

  /// 历史数据加载回调
  final Future<Candlesticks> Function(Candlestick)? onLoadHistory;

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  CandlestickChartController get controller => widget.controller;
  CandlestickThemeConfig get theme => widget.theme;
  BoxConstraints? boxConstraints;
  // 添加状态跟踪横向偏移
  double _offsetX = 0.0;

  // 添加状态跟踪纵向偏移
  double _offsetY = 0.0;

  // 横向缩放因子
  double _scaleX = 1.0;

  // 纵向缩放因子
  double _scaleY = 1.0;

  // 追加history后要将_offsetX 便宜 len * _singleCandleWidth 个单位
  // 计算单个蜡烛总宽度（包含间距）(包含缩放因子)
  double get _singleCandleWidth => (theme.candleWidth + theme.candleMargin * 2) * _scaleX;

  // 获取当前单根蜡烛是否小于最小宽度
  // bool get _isLineModeActive => _singleCandleWidth < theme.minCandlestickWidth;

  // 计算整个数据集的总宽度 (包含缩放因子)
  double get _totalDataWidth => _singleCandleWidth * controller.candlesticks.length;

  // 添加加载状态标记
  bool _isLoadingHistory = false;

  // 计算滑动边界
  double _calculateBoundedOffset(double newOffset, double viewportWidth) {
    final minOffset = -viewportWidth / 2;
    final maxOffset = _totalDataWidth - viewportWidth / 2;

    final boundedOffset = newOffset.clamp(minOffset, maxOffset);

    // 检查是否需要加载历史数据
    if (!_isLoadingHistory && widget.onLoadHistory != null && boundedOffset <= theme.historyLoadThreshold) {
      _loadHistory();
    }

    return boundedOffset;
  }

  bool _userInteracted = false; // 用户正在横移

  // 更新自动跟随位置
  void _updateAutoFollow(BoxConstraints constraints, {bool force = false}) {
    if (!controller.autoFollow || _userInteracted) return;
    double targetOffest = (_totalDataWidth - _offsetX - constraints.maxWidth + theme.latestCandleRightMargin).abs();
    if ((targetOffest <= _singleCandleWidth * 2) || force) {
      _offsetX = _totalDataWidth + theme.latestCandleRightMargin - constraints.maxWidth - _singleCandleWidth;
    }
  }

  // 添加历史数据加载方法
  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      Candlesticks? historyList = await widget.onLoadHistory?.call(controller.candlesticks.last);
      if (historyList != null) {
        controller.backappendHistoryList(historyList);
        _offsetX += _singleCandleWidth * historyList.length;
      }
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        boxConstraints = constraints;
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.candlesticks.isEmpty) return SizedBox();
            return _widgetCanvas(constraints);
          },
        );
      },
    );
  }

  // 添加十字光标位置状态
  Offset? _crosshairPosition;

  Widget _widgetCanvas(BoxConstraints constraints) {
    _updateAutoFollow(constraints);
    final calculator = PriceCalculator(
      viewportHeight: constraints.maxHeight,
      viewportWidth: constraints.maxWidth,
      candleWidth: theme.candleWidth,
      candleSpacing: theme.candleMargin,
      candlesticks: controller.candlesticks,
      offsetX: _offsetX,
      scaleX: _scaleX,
      scaleY: _scaleY,
      topSafeAreaHeight: theme.topSafeAreaHeight,
      bottomSafeAreaHeight: theme.bottomSafeAreaHeight,
      bottomTimeLabelHeight: theme.bottomTimeLabelHeight,
      gridTimeCount: theme.gridCount,
      crosshairOffset: _crosshairPosition != null ? (_crosshairPosition!.dx, _crosshairPosition!.dy) : null,
    );
    var info = calculator.getCandlestickPrintInfo();
    List<CandlestickPrintInfo> candlesticks = info.$1;
    List<GridTimePrintInfo> gridTimes = info.$2;
    List<GridPricePrintInfo> gridPrices = info.$3;
    LivePricePrintInfo? livePricePrintInfo = info.$4;
    HighPrintInfo? highPrintInfo = info.$5;
    LowPrintInfo? lowPrintInfo = info.$6;
    CrosshairPrintInfo? crosshairPrintInfo = info.$7;
    return Stack(
      children: [
        GestureDetector(
          onTapDown: (details) {
            setState(() {
              // 如果已经有光标，点击则取消显示
              if (_crosshairPosition != null) {
                _crosshairPosition = null;
              } else {
                // 否则显示光标在点击位置
                _crosshairPosition = details.localPosition;
              }
            });
          },
          onLongPressStart: (details) {
            setState(() {
              _crosshairPosition = details.localPosition;
            });
          },
          onLongPressMoveUpdate: (details) {
            setState(() {
              _crosshairPosition = details.localPosition;
            });
          },
          onHorizontalDragStart: (details) {
            setState(() {
              _crosshairPosition = null;
              _userInteracted = true;
            });
          },
          onHorizontalDragEnd: (_) {
            _userInteracted = false;
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              final newOffset = _offsetX - details.delta.dx;
              _offsetX = _calculateBoundedOffset(newOffset, constraints.maxWidth);
            });
          },
          onVerticalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            // 确保触摸点在画布区域内，并且在右侧指定范围内
            if (localPosition.dx >= 0 &&
                localPosition.dx <= constraints.maxWidth &&
                localPosition.dy >= 0 &&
                localPosition.dy <= constraints.maxHeight &&
                localPosition.dx >= constraints.maxWidth - theme.scaleYAreaWidth) {
              setState(() {
                final scaleChange = -details.delta.dy * 0.01;
                final newScale = (_scaleY + scaleChange).clamp(theme.minScaleY, theme.maxScaleY);
                _scaleY = newScale;
              });
            }
          },
          child: Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            color: theme.backgroundColor,
            child: CustomPaint(
              painter: CandlestickChartPainter(
                controller: controller,
                theme: theme,
                offsetX: _offsetX,
                viewportWidth: constraints.maxWidth,
                totalDataWidth: _totalDataWidth,
                livePricePrintInfo: livePricePrintInfo,
                gridTimePrintInfoList: gridTimes,
                gridPricePrintInfoList: gridPrices,
                candlestickPrintInfoList: candlesticks,
                highPrintInfo: highPrintInfo,
                lowPrintInfo: lowPrintInfo,
                crosshairPrintInfo: crosshairPrintInfo,
              ),
            ),
          ),
        ),
        if (widget.buildLiveInfoWidget != null && livePricePrintInfo != null)
          Positioned(
            right: 20,
            top: (livePricePrintInfo.y - 20).clamp(0, constraints.maxHeight - 46),
            child: widget.buildLiveInfoWidget!(
              livePricePrintInfo.price,
              livePricePrintInfo.timestamp,
              livePricePrintInfo.isVisible,
            ),
          ),
        if (crosshairPrintInfo != null)
          Positioned(
            bottom: 2,
            left: crosshairPrintInfo.x,
            child: FractionalTranslation(
              translation: Offset(-0.5, 0), // 水平向左移动50%
              child: widget.buildCrosshairTimeWidget != null
                  ? widget.buildCrosshairTimeWidget!(crosshairPrintInfo.timestamp)
                  : CandlestickWidgets.buildCrosshairTimeWidget(crosshairPrintInfo.timestamp),
            ),
          ),
        if (crosshairPrintInfo != null && crosshairPrintInfo.candlestick != null)
          Positioned(
            top: theme.topSafeAreaHeight,
            left: crosshairPrintInfo.x > constraints.maxWidth / 2 ? 40 : null,
            right: crosshairPrintInfo.x > constraints.maxWidth / 2 ? null : 40,
            child: widget.buildCrosshairCandleInfoWidget != null
                ? widget.buildCrosshairCandleInfoWidget!(crosshairPrintInfo.candlestick!)
                : CandlestickWidgets.buildCrosshairCandleInfoWidget(crosshairPrintInfo.candlestick!),
          ),
      ],
    );
  }

  // ########### 注册控制器方法 ############
  @override
  void initState() {
    super.initState();
    controller.registerCallback('followLatest', () => _handleFollowLatest());
  }

  // 处理控制器回调的方法
  void _handleFollowLatest() {
    assert(boxConstraints != null, "LayoutBuilder not built yet");
    setState(() {
      _updateAutoFollow(boxConstraints!, force: true);
    });
  }
}

class CandlestickWidgets {
  static Widget buildLatestPriceWidget(double price, int timestamp, bool isInScreen, void Function() onTap) {
    return GestureDetector(
      onTap: isInScreen ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey, width: 0.4),
        ),
        padding: EdgeInsets.only(left: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price.toString(),
                  style: TextStyle(fontSize: 12, height: 1),
                ),
                Text(
                  formatDuration(timestamp - DateTime.now().millisecondsSinceEpoch),
                  style: TextStyle(fontSize: 10, height: 1),
                ),
              ],
            ),
            SizedBox(width: 4),
            if (!isInScreen) Icon(Icons.navigate_next_outlined, size: 12),
          ],
        ),
      ),
    );
  }

  static Widget buildCrosshairTimeWidget(int timestamp) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey, width: 0.4),
      ),
      child: Text(
        formatTimestamp(timestamp),
        style: TextStyle(fontSize: 10, height: 1, color: Colors.white),
      ),
    );
  }

  static Widget buildCrosshairCandleInfoWidget(Candlestick item) {
    TextStyle style = TextStyle(fontSize: 10, height: 1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey, width: 0.4),
      ),
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '开盘: ${item.open}',
            style: style,
          ),
          Text(
            '收盘: ${item.close}',
            style: style,
          ),
          Text(
            '最高: ${item.high}',
            style: style,
          ),
          Text(
            '最低: ${item.low}',
            style: style,
          ),
          Text(
            '时间：${formatTimestamp(item.timestamp)}',
            style: style,
          )
        ],
      ),
    );
  }
}
