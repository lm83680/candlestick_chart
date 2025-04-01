import 'package:flutter/material.dart';
import 'index.dart';

class CandlestickChartPainter extends CustomPainter {
  final CandlestickChartController controller;
  final CandlestickThemeConfig theme;
  final double offsetX;
  final double viewportWidth;
  final double totalDataWidth;
  final List<CandlestickPrintInfo> candlestickPrintInfoList;
  final List<GridTimePrintInfo> gridTimePrintInfoList;
  final List<GridPricePrintInfo> gridPricePrintInfoList;
  final LivePricePrintInfo? livePricePrintInfo;
  final HighPrintInfo? highPrintInfo;
  final LowPrintInfo? lowPrintInfo;
  final CrosshairPrintInfo? crosshairPrintInfo;

  CandlestickChartPainter({
    required this.controller,
    required this.theme,
    required this.offsetX,
    required this.viewportWidth,
    required this.totalDataWidth,
    required this.candlestickPrintInfoList,
    required this.gridTimePrintInfoList,
    required this.gridPricePrintInfoList,
    required this.livePricePrintInfo,
    this.highPrintInfo,
    this.lowPrintInfo,
    this.crosshairPrintInfo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    _drawTimeBox(canvas, size);

    // 蜡烛
    for (final candlestickPrintInfo in candlestickPrintInfoList) {
      final candle = candlestickPrintInfo.candlestick;
      final color = candle.close >= candle.open ? theme.bullishColor : theme.bearishColor;

      // 绘制影线
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = theme.wickWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(candlestickPrintInfo.shadow.$1, candlestickPrintInfo.shadow.$3),
        Offset(candlestickPrintInfo.shadow.$1, candlestickPrintInfo.shadow.$2),
        wickPaint,
      );
      // 绘制蜡烛实体
      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(
          candlestickPrintInfo.contentStartX,
          candlestickPrintInfo.openY,
          candlestickPrintInfo.contentEndX,
          candlestickPrintInfo.closeY,
        ),
        bodyPaint,
      );
    }

    _drawPriceBox(canvas, size, gridPricePrintInfoList);
    // 绘制实时价格
    if (livePricePrintInfo != null) {
      final livePricePaint = Paint()
        ..color = theme.crosshairColor
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      _drawDashedLine(
        canvas,
        Offset(livePricePrintInfo!.x, livePricePrintInfo!.y),
        Offset(livePricePrintInfo!.endX, livePricePrintInfo!.y),
        livePricePaint,
      );
    }
    // 绘制最高最低价标记
    _drawExtremePrices(canvas, size);

    // 绘制十字光标
    _drawCrosshair(canvas, size);
  }

  // 添加十字光标绘制方法
  void _drawCrosshair(Canvas canvas, Size size) {
    if (crosshairPrintInfo == null) return;

    final crosshairPaint = Paint()
      ..color = theme.crosshairColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 绘制横向虚线
    _drawDashedLine(
      canvas,
      Offset(0, crosshairPrintInfo!.y),
      Offset(size.width, crosshairPrintInfo!.y),
      crosshairPaint,
    );

    // 绘制纵向虚线
    _drawDashedLine(
      canvas,
      Offset(crosshairPrintInfo!.x, 0),
      Offset(crosshairPrintInfo!.x, size.height - theme.bottomTimeLabelHeight + 4),
      crosshairPaint,
    );

    // 绘制中心点
    final centerPointPaint = Paint()
      ..color = theme.crosshairColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(crosshairPrintInfo!.x, crosshairPrintInfo!.y),
      3, // 半径为0.5，形成1*1的圆点
      centerPointPaint,
    );
  }

  // 绘制最高最低价标记
  void _drawExtremePrices(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = theme.extremePriceLineColor
      ..strokeWidth = theme.extremePriceLineWidth
      ..style = PaintingStyle.stroke;

    // 绘制最高价
    if (highPrintInfo != null) {
      canvas.drawLine(
        Offset(highPrintInfo!.x, highPrintInfo!.y),
        Offset(highPrintInfo!.endX, highPrintInfo!.y),
        linePaint,
      );

      final priceText = TextPainter(
        text: TextSpan(
          text: highPrintInfo!.price.toString(),
          style: theme.extremePriceStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bool isExtendRight = highPrintInfo!.endX > highPrintInfo!.x;
      final textX = !isExtendRight ? highPrintInfo!.endX - priceText.width - 4 : highPrintInfo!.endX + 4;
      priceText.paint(
        canvas,
        Offset(textX, highPrintInfo!.y - priceText.height / 2),
      );
    }

    // 绘制最低价
    if (lowPrintInfo != null) {
      canvas.drawLine(
        Offset(lowPrintInfo!.x, lowPrintInfo!.y),
        Offset(lowPrintInfo!.endX, lowPrintInfo!.y),
        linePaint,
      );

      final priceText = TextPainter(
        text: TextSpan(
          text: lowPrintInfo!.price.toString(),
          style: theme.extremePriceStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bool isExtendRight = lowPrintInfo!.endX > lowPrintInfo!.x;
      final textX = !isExtendRight ? lowPrintInfo!.endX - priceText.width - 4 : lowPrintInfo!.endX + 4;

      priceText.paint(
        canvas,
        Offset(textX, lowPrintInfo!.y - priceText.height / 2),
      );
    }
  }

  // 网格（价格和时间）
  void _drawTimeBox(Canvas canvas, Size size) {
    // 绘制时间网格线和标签
    final gridPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = theme.gridLineWidth
      ..style = PaintingStyle.stroke;

    // 价格线
    for (final gridPricePrintInfo in gridPricePrintInfoList) {
      canvas.drawLine(
        Offset(0, gridPricePrintInfo.y),
        Offset(
          size.width,
          gridPricePrintInfo.y,
        ),
        gridPaint,
      );
    }
    // 绘制时间区
    final bodyPaint = Paint()
      ..color = theme.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        0,
        size.height,
        size.width,
        size.height - theme.bottomTimeLabelHeight,
      ),
      bodyPaint,
    );
    // 时间线
    for (final gridTimePrintInfo in gridTimePrintInfoList) {
      canvas.drawLine(
        Offset(gridTimePrintInfo.x, 0),
        Offset(
          gridTimePrintInfo.x,
          size.height -
              (gridTimePrintInfo == gridTimePrintInfoList.first || gridTimePrintInfo == gridTimePrintInfoList.last
                  ? 0
                  : theme.bottomTimeLabelHeight),
        ),
        gridPaint,
      );
      if (gridTimePrintInfo.timestamp != null) {
        final timeText = TextPainter(
          text: TextSpan(
            text: formatTimestamp(gridTimePrintInfo.timestamp!),
            style: theme.timeLabelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        timeText.paint(
          canvas,
          Offset(
            gridTimePrintInfo.x - timeText.width / 2,
            size.height - theme.bottomTimeLabelHeight / 2 - timeText.height / 2,
          ),
        );
      }
    }
    // 画布区顶部横线
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      gridPaint,
    );
    // 画布区底部横线
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );
    // 价格区域顶部横线
    canvas.drawLine(
      Offset(0, size.height - theme.bottomTimeLabelHeight),
      Offset(size.width, size.height - theme.bottomTimeLabelHeight),
      gridPaint,
    );
  }

  // 价格描述应该在最顶级
  void _drawPriceBox(Canvas canvas, Size size, List<GridPricePrintInfo> prices) {
    // 价格线
    for (final gridPricePrintInfo in prices) {
      final timeText = TextPainter(
        text: TextSpan(
          text: gridPricePrintInfo.price.toString(),
          style: theme.priceLabelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      timeText.paint(
        canvas,
        Offset(
          size.width - timeText.width - 4,
          gridPricePrintInfo.y - timeText.height,
        ),
      );
    }
  }

  // 绘制虚线的辅助方法
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double dashWidth = 4;
    final double dashSpace = 4;
    final double distance = (end - start).distance;
    final double dash = dashWidth + dashSpace;
    final int count = (distance / dash).floor();

    for (int i = 0; i < count; i++) {
      final double startFraction = i * dash / distance;
      final double endFraction = (i * dash + dashWidth) / distance;
      canvas.drawLine(
        Offset.lerp(start, end, startFraction)!,
        Offset.lerp(start, end, endFraction)!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickChartPainter oldDelegate) {
    return true;
    // return oldDelegate.controller != controller ||
    //     oldDelegate.theme != theme ||
    //     oldDelegate.offsetX != offsetX ||
    //     oldDelegate.viewportWidth != viewportWidth ||
    //     oldDelegate.totalDataWidth != totalDataWidth ||
    //     oldDelegate.calculator != calculator;
  }
}
