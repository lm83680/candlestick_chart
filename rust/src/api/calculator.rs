use std::collections::{HashMap, HashSet};

/// 从前 limit 个元素中查找 timestamps 重合的元素
pub fn find_candlestick_indices(
    list: &[crate::api::models::Candlestick],
    timestamps: HashSet<i64>,
    limit: usize,
) -> HashMap<i64, usize> {
    list.iter()
        .enumerate()
        .take(limit)
        .filter(|(_, c)| timestamps.contains(&c.timestamp))
        .map(|(i, c)| (c.timestamp, i))
        .collect()
}

/// 计算给定蜡烛图列表的价格范围    
/// Return (max_price, min_price)
pub fn find_candlesticks_price_range(candlesticks: &[crate::api::models::Candlestick]) -> (f64, f64) {
    if candlesticks.is_empty() {
        return (0.0, 0.0);
    }

    let max_price = candlesticks.iter().map(|c| c.high).fold(f64::MIN, f64::max);
    let min_price = candlesticks.iter().map(|c| c.low).fold(f64::MAX, f64::min);

    (max_price, min_price)
}

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}