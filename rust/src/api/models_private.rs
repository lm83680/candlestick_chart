use super::models::{Candlestick, GridPricePrintInfo, PriceCalculator};

#[derive(Clone)]
/// final double startX; // 当前蜡烛占用区的起始X坐标   
/// final double endX; // 当前蜡烛占用区的结束X坐标    
/// final double contentStartX; // 蜡烛矩形的起始X坐标    
/// final double contentEndX; // 蜡烛矩形的结束X坐标    
/// final Candlestick candlestick; // 对应的蜡烛数据    
pub(crate) struct CandlestickPrintInfoStep1 {
    pub start_x: f64,
    pub end_x: f64,
    pub content_start_x: f64,
    pub content_end_x: f64,
    pub candlestick: Candlestick,
}

impl PriceCalculator {
    pub(crate) fn visible_candlesticks_printer_info(&self) -> Vec<CandlestickPrintInfoStep1> {
        let mut visible_print_candlesticks = vec![];
        let single_candle_width: f64 = self.candle_width + (self.candle_spacing * 2_f64);
        let start_index: f64 = (self.offset_x / single_candle_width).floor();
        let end_index: f64 = ((self.offset_x + self.viewport_width) / single_candle_width).ceil();
        let valid_start_index: usize =
            start_index.clamp(0_f64, self.candlesticks.len() as f64 - 1_f64) as usize;
        let valid_end_index: usize =
            end_index.clamp(0_f64, self.candlesticks.len() as f64) as usize;

        for i in valid_start_index..valid_end_index {
            let start_x: f64 = (i as f64 * single_candle_width) - self.offset_x;
            let end_x: f64 = start_x + single_candle_width;
            let content_start_x: f64 = start_x + self.candle_spacing;
            let content_end_x: f64 = end_x - self.candle_spacing;
            let candlestick: Candlestick = self.candlesticks[i].clone();
            visible_print_candlesticks.push(CandlestickPrintInfoStep1 {
                start_x,
                end_x,
                content_start_x,
                content_end_x,
                candlestick,
            });
        }
        visible_print_candlesticks
    }

    /// 计算价格密度
    /// high_candle - low_candle - Density - topPrice - bottomPrice - visibleCandlesticks
    /// 最高价蜡烛 - 最低价蜡烛 - 密度（每1像素的价格范围） - 绘制区顶部价 - 绘制区底部价 - 可见蜡烛列表
    pub(crate) fn calculate_price_metrics(
        &self,
    ) -> (Candlestick, Candlestick, f64, f64, f64, Vec<CandlestickPrintInfoStep1>) {
        let visible_candlesticks: Vec<CandlestickPrintInfoStep1> =
            self.visible_candlesticks_printer_info();
            
        // 找到最高价和最低价对应的蜡烛
        let (high_candle, low_candle) = visible_candlesticks.iter().fold(
            (Option::<&Candlestick>::None, Option::<&Candlestick>::None),
            |(high_acc, low_acc), current| {
                let high = match high_acc {
                    None => Some(&current.candlestick),
                    Some(h) if current.candlestick.high > h.high => Some(&current.candlestick),
                    Some(h) => Some(h),
                };
                
                let low = match low_acc {
                    None => Some(&current.candlestick),
                    Some(l) if current.candlestick.low < l.low => Some(&current.candlestick),
                    Some(l) => Some(l),
                };
                
                (high, low)
            },
        );
        
        let high_candle = high_candle.unwrap_or(&visible_candlesticks[0].candlestick);
        let low_candle = low_candle.unwrap_or(&visible_candlesticks[0].candlestick);
        
        // 蜡烛安全区 + 时间标签高度
        let bootom_margin_height = self.bottom_safe_area_height + self.bottom_time_label_height;
        // 计算有效绘制高度
        let effective_height =
            self.viewport_height - self.top_safe_area_height - bootom_margin_height;

        let price_density = (high_candle.high - low_candle.low) / effective_height;
        let zero_price = low_candle.low - (bootom_margin_height * price_density);
        let top_price = zero_price + (self.viewport_height * price_density);
        
        (
            high_candle.clone(),
            low_candle.clone(),
            price_density,
            top_price,
            zero_price,
            visible_candlesticks,
        )
    }

    /// 获取最新的1根蜡烛
    pub(crate) fn get_now_candlestick(&self) -> Option<Candlestick> {
        if self.candlesticks.is_empty() {
            return None;
        }
        Some(self.candlesticks.last().unwrap().clone())
    }

    pub(crate) fn calculate_price_grid(
        &self,
        top_price: f64,
        bottom_price: f64,
        price_density: f64,
    ) -> Vec<GridPricePrintInfo> {
        let mut grid_price_print_info = Vec::new();
        let price_range = top_price - bottom_price;

        if price_range <= 0.0 || price_density <= 0.0 {
            return grid_price_print_info;
        }

        // 计算期望的网格数量（基于价格密度）
        let grid_count = (price_range * price_density).ceil().max(1.0).min(12.0) as i32;

        // 计算理想步长并调整为整洁数值
        let ideal_step = price_range / grid_count as f64;
        let adjusted_step = Self::calculate_nice_step(ideal_step);

        if adjusted_step <= 0.0 {
            return grid_price_print_info;
        }

        // 计算起始价格（确保覆盖顶部可能的空间）
        let start_price = ((top_price / adjusted_step).ceil() * adjusted_step).max(top_price);

        // 生成价格线并计算坐标
        let mut current_price = start_price;
        while current_price >= (bottom_price - adjusted_step){
            // 计算当前价格的小数位数
            let decimal_places = Self::calculate_decimal_places(adjusted_step);
            let rounded_price = Self::round_to_decimal(current_price, decimal_places);

            // 计算y坐标（从顶部到底部的线性插值）
            let y = Self::price_to_y(current_price, top_price, price_density);

            grid_price_print_info.push(GridPricePrintInfo {
                price: rounded_price,
                y,
            });

            current_price -= adjusted_step;
        }

        grid_price_print_info
    }

    // 计算整洁的步长（1, 2, 5系列）
    fn calculate_nice_step(ideal_step: f64) -> f64 {
        if ideal_step <= 0.0 {
            return 0.0;
        }

        let exponent = ideal_step.log10().floor();
        let factor = 10f64.powf(exponent);
        let normalized = ideal_step / factor;

        let nice_normalized = match normalized {
            n if n < 1.5 => 1.0,
            n if n < 3.0 => 2.0,
            n if n < 7.0 => 5.0,
            _ => 10.0,
        };

        (nice_normalized * factor).max(f64::EPSILON)
    }

    // 计算步长对应的小数位数
    fn calculate_decimal_places(step: f64) -> i32 {
        let eps = 1e-10;
        let mut step = step.abs();
        step += eps; // 防止浮点精度问题

        let mut places = 0;
        while (step * 10f64.powi(places)).fract().abs() > eps && places < 10 {
            places += 1;
        }
        places
    }

    // 四舍五入到指定小数位
    fn round_to_decimal(value: f64, places: i32) -> f64 {
        let factor = 10f64.powi(places);
        (value * factor).round() / factor
    }
}
