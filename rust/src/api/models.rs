use flutter_rust_bridge::frb;

/// 数据模型原型参考 https://www.okx.com/docs-v5/zh/?python#public-data-rest-api-get-index-candlesticks     
/// 单根蜡烛的于接口内的数据为 [ts,o,h,l,c,confirm]    
/// ts	      String	开始时间，Unix时间戳的毫秒数格式，如 1597026383085    
/// o	      String	开盘价格    
/// h	      String	最高价格    
/// l	      String	最低价格    
/// c	      String	收盘价格    
/// confirm	String	K线状态 (0 代表 K 线未完结，1 代表 K 线已完结。)    
#[frb]
#[derive(Debug, Clone)]
pub struct Candlestick {
    pub timestamp: i64, // Unix 时间戳（毫秒）
    pub open: f64,
    pub high: f64,
    pub low: f64,
    pub close: f64,
    pub is_confirmed: bool,
}

impl Candlestick {
    /// 从 `Vec<String>` 创建 `Candlestick`
    pub fn from_service_data(data: Vec<String>) -> Self {
        Self {
            timestamp: data.get(0).and_then(|s| s.parse::<i64>().ok()).unwrap_or(0),
            open: data
                .get(1)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(0.0),
            high: data
                .get(2)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(0.0),
            low: data
                .get(3)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(0.0),
            close: data
                .get(4)
                .and_then(|s| s.parse::<f64>().ok())
                .unwrap_or(0.0),
            is_confirmed: data.get(5).map(|s| s == "1").unwrap_or(false),
        }
    }

    /// 从 `Vec<Vec<String>>` 创建 `Vec<Candlestick>`
    pub fn list_from_service_data(data: Vec<Vec<String>>) -> Vec<Self> {
        data.iter()
            .map(|d| Self::from_service_data(d.clone()))
            .collect()
    }

    /// 将 `is_confirmed` 设置为 `true`
    pub fn mark_as_confirmed(&self) -> Self {
        Self {
            is_confirmed: true,
            ..self.clone()
        }
    }
}

#[frb]
#[derive(Debug, Clone)]
pub struct PriceCalculator {
    /// 视图高度
    pub viewport_height: f64,
    /// 视图宽度
    pub viewport_width: f64,
    /// 横向偏移度
    pub offset_x: f64,
    /// 横向缩放度
    pub scale_x: f64,
    /// 蜡烛宽度
    pub candle_width: f64,
    /// 蜡烛边距
    pub candle_spacing: f64,
    /// 蜡烛列表，入参时由[新～旧]排序
    pub candlesticks: Vec<Candlestick>,
    /// 顶部边距
    pub top_safe_area_height: f64,
    /// 底部边距
    pub bottom_safe_area_height: f64,
    /// 底部时间轴高度
    pub bottom_time_label_height: f64,
    /// 时间网格线条数
    pub grid_time_count: i8,
    /// 纵向缩放度
    pub scale_y: f64,
    /// 十字光标源
    pub crosshair_offset: Option<(f64, f64)>,
}

impl PriceCalculator {
    #[frb(sync)]
    pub fn new(
        viewport_height: f64,
        viewport_width: f64,
        offset_x: f64,
        scale_x: f64,
        candle_width: f64,
        candle_spacing: f64,
        candlesticks: Vec<Candlestick>,
        top_safe_area_height: f64,
        bottom_safe_area_height: f64,
        bottom_time_label_height: f64,
        grid_time_count: i8,
        scale_y: f64,
        crosshair_offset: Option<(f64, f64)>,
    ) -> Self {
        Self {
            viewport_height,
            viewport_width,
            offset_x,
            scale_x,
            candle_width,
            candle_spacing,
            candlesticks: candlesticks.iter().rev().cloned().collect(),
            top_safe_area_height,
            bottom_safe_area_height,
            bottom_time_label_height,
            grid_time_count,
            scale_y,
            crosshair_offset,
        }
    }
    /// 仅需一个函数，把所有绘制信息统统搞定
    /// 返回值：
    /// 1. 蜡烛图绘制信息，包括蜡烛数据、蜡烛矩形的四个顶点坐标和影线的信息
    /// 2. 纵向网格线信息，包括x坐标和对应的时间戳（如果有）
    /// 3. 横向价格线信息，包括Y坐标和对应的价格
    /// 4. 实时价格线信息
    /// 5. 最高价信息
    /// 6. 最低价信息
    #[frb(sync)]
    pub fn get_candlestick_print_info(
        &self,
    ) -> (
        Vec<CandlestickPrintInfo>,
        Vec<GridTimePrintInfo>,
        Vec<GridPricePrintInfo>,
        Option<LivePricePrintInfo>,
        Option<HighPrintInfo>,
        Option<LowPrintInfo>,
        Option<CrosshairPrintInfo>, // 添加新返回值
    ) {
        let (high_candle, low_candle, price_density, top_price, bottom_price, visible_candlesticks) =
            self.calculate_price_metrics();

        let mut candlestick_print_info: Vec<CandlestickPrintInfo> = vec![];
        let mut grid_time_print_info: Vec<GridTimePrintInfo> = vec![];

        for i in 0..=(self.grid_time_count - 1) {
            let x = i as f64 * self.viewport_width / (self.grid_time_count - 1) as f64;
            grid_time_print_info.push(GridTimePrintInfo { timestamp: None, x });
        }

        // 使用引用遍历以避免所有权移动
        for candlestick in &visible_candlesticks {
            let open_y = Self::price_to_y(candlestick.candlestick.open, top_price, price_density);
            let close_y = Self::price_to_y(candlestick.candlestick.close, top_price, price_density);
            let shadow = (
                (candlestick.content_start_x + candlestick.content_end_x) / 2_f64,
                Self::price_to_y(candlestick.candlestick.low, top_price, price_density),
                Self::price_to_y(candlestick.candlestick.high, top_price, price_density),
            );

            //如果 timestamp 落在某个网格线的范围内，则将 timestamp 赋值给该网格线
            for grid_time in grid_time_print_info.iter_mut() {
                if candlestick.start_x < grid_time.x && candlestick.end_x > grid_time.x {
                    grid_time.timestamp = Some(candlestick.candlestick.timestamp);
                }
            }

            candlestick_print_info.push(CandlestickPrintInfo {
                candlestick: candlestick.candlestick.clone(),
                open_y,
                close_y,
                content_start_x: candlestick.content_start_x,
                content_end_x: candlestick.content_end_x,
                shadow,
            })
        }

        let live_price_info = if let Some(latest) = self.get_now_candlestick() {
            let y = Self::price_to_y(latest.close, top_price, price_density);

            // 查找最新蜡烛是否在可视列表内
            let (start_x, end_x) = visible_candlesticks
                .iter()
                .find(|c| c.candlestick.timestamp == latest.timestamp)
                .map(|c| (c.content_end_x, self.viewport_width))
                .unwrap_or((0.0, self.viewport_width));

            Some(LivePricePrintInfo {
                price: latest.close,
                x: if start_x > self.viewport_width {
                    0.0
                } else {
                    start_x
                },
                end_x,
                y,
                timestamp: latest.timestamp,
                is_visible: visible_candlesticks
                    .iter()
                    .any(|c| c.candlestick.timestamp == latest.timestamp),
            })
        } else {
            None
        };

        let grid_price_print_info =
            self.calculate_price_grid(top_price, bottom_price, price_density);

        // 计算最高点和最低点的打印信息
        let (high_print_info, low_print_info) = if !visible_candlesticks.is_empty() {
            let high_candlestick = visible_candlesticks
                .iter()
                .find(|c| c.candlestick.high == high_candle.high);

            let low_candlestick = visible_candlesticks
                .iter()
                .find(|c| c.candlestick.low == low_candle.low);

            let high_info = high_candlestick.map(|c| {
                let x = (c.content_start_x + c.content_end_x) / 2.0;
                let extend_right = x < self.viewport_width / 2.0;
                HighPrintInfo {
                    price: c.candlestick.high,
                    x,
                    end_x: if extend_right { x + 24.0 } else { x - 24.0 },
                    y: Self::price_to_y(c.candlestick.high, top_price, price_density),
                }
            });

            let low_info = low_candlestick.map(|c| {
                let x = (c.content_start_x + c.content_end_x) / 2.0;
                let extend_right = x < self.viewport_width / 2.0;
                LowPrintInfo {
                    price: c.candlestick.low,
                    x,
                    end_x: if extend_right { x + 24.0 } else { x - 24.0 },
                    y: Self::price_to_y(c.candlestick.low, top_price, price_density),
                }
            });

            (high_info, low_info)
        } else {
            (None, None)
        };

        // 处理十字光标
        let crosshair_info = if let Some((x, y)) = self.crosshair_offset {
            // 单根蜡烛宽度
            let single_candle_width = (self.candle_width + self.candle_spacing * 2.0) * self.scale_x;

            // 获取可视区域第一根蜡烛
            let first = candlestick_print_info.first().unwrap().clone();
            // 获取可视区域第一根蜡烛（最早的）和时间步长
            let (first_timestamp, time_interval) = if candlestick_print_info.len() > 1 {
                let second = candlestick_print_info.get(1).unwrap().candlestick.clone();
                (first.candlestick.timestamp, second.timestamp - first.candlestick.timestamp)
            } else {
                (0, 0)
            };

            // 计算目标位置距离第一根蜡烛的距离数（可能为负）
            let distance =  (x - first.shadow.0)  / single_candle_width;
            let target_index = distance.floor() as i64;

            // 计算目标时间戳
            let timestamp = first_timestamp + (time_interval * target_index);

            // 计算中心点x坐标
            let center_x = (target_index as f64 * single_candle_width) + first.shadow.0;

            // 计算该位置对应的价格
            let price = Self::y_to_price(y, top_price, price_density);

            // 查找该位置是否有对应的蜡烛
            let target_candlestick = candlestick_print_info
                .iter()
                .find(|c| c.candlestick.timestamp == timestamp)
                .map(|c| c.candlestick.clone());

            Some(CrosshairPrintInfo {
                candlestick: target_candlestick,
                x: center_x,
                y,
                price,
                timestamp,
            })
        } else {
            None
        };

        (
            candlestick_print_info,
            grid_time_print_info,
            grid_price_print_info,
            live_price_info,
            high_print_info,
            low_print_info,
            crosshair_info, // 添加到返回值中
        )
    }

    /// 将价格转换为Y坐标
    pub fn price_to_y(price: f64, top_price: f64, price_density: f64) -> f64 {
        (top_price - price) / price_density
    }
    /// 将坐标转为为价格
    pub fn y_to_price(y: f64, top_price: f64, price_density: f64) -> f64 {
        top_price - (y * price_density)
    }
}

#[frb]
#[derive(Clone)]
/// 蜡烛图绘制信息，包括蜡烛数据、蜡烛矩形的四个顶点坐标和影线的信息
pub struct CandlestickPrintInfo {
    pub candlestick: Candlestick,
    /// 开盘价Y坐标 open
    pub open_y: f64,
    /// 收盘价Y坐标 close
    pub close_y: f64,
    /// 绘制起点
    pub content_start_x: f64,
    /// 绘制终点
    pub content_end_x: f64,
    /// 影线 (x坐标,最低点y坐标,最高点y坐标)
    pub shadow: (f64, f64, f64),
}

#[frb]
#[derive(Clone)]
/// 纵向网格线信息，包括x坐标和对应的时间戳（如果有）
pub struct GridTimePrintInfo {
    pub timestamp: Option<i64>,
    pub x: f64,
}

#[frb]
#[derive(Clone)]
/// 横向网格线信息，包括y坐标和对应的价格线
pub struct GridPricePrintInfo {
    pub price: f64,
    pub y: f64,
}

#[frb]
#[derive(Clone)]
/// 实时价格线信息
pub struct LivePricePrintInfo {
    /// close_y
    pub price: f64,
    /// 起始
    pub x: f64,
    /// 结尾坐标
    pub end_x: f64,
    pub y: f64,
    /// 本周期结束时间
    pub timestamp: i64,
    /// 是否可见
    pub is_visible: bool,
}

#[frb]
#[derive(Clone)]
/// 价格最高点标记
pub struct HighPrintInfo {
    pub price: f64,
    pub x: f64,
    pub end_x: f64,
    pub y: f64,
}

#[frb]
#[derive(Clone)]
/// 价格最低点标记
pub struct LowPrintInfo {
    pub price: f64,
    pub x: f64,
    pub end_x: f64,
    pub y: f64,
}

#[frb]
#[derive(Clone)]
/// 十字光标信息
pub struct CrosshairPrintInfo {
    pub candlestick: Option<Candlestick>,
    pub timestamp: i64,
    pub price: f64,
    pub x: f64,
    pub y: f64,
}
