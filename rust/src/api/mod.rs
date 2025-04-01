mod calculator_private;  // 私有计算模块
mod models_private;     // 私有模型模块
pub mod calculator;     // 公开计算函数
pub mod models;         // 公开数据模型

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Rust 工具链初始化
    flutter_rust_bridge::setup_default_user_utils();
}