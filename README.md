# RISC-V SoC with Custom Peripherals

## 📌 專案簡介

本專案實作一個以 **自製RISC-V Core** 為主體的 SoC，並透過 **Verilog RTL** 撰寫與驗證，逐步加入週邊控制器與匯流排架構。
此設計可支援後續移植 Linux Kernel (如 v4.20)，並能進一步開發自製 driver 以支援 UART / SPI / DMA 等客製化週邊。

## 🔧 開發環境

* **HDL 語言**: Verilog
* **模擬工具**: ModelSim
* **目標平台**: 可延伸至 FPGA 實作 (後續規劃)
* **Bus 架構**: AXI / APB 為主
* **模組設計**: 自行開發客製化控制模組 (UART, SPI, etc.)

## ✅ 目前進度

* [x] RISC-V CPU Core RTL 開發完成度：**約 90%**
* [x] ModelSim 模擬驗證 (基本指令集測試)
* [ ] 匯流排 (AXI / APB) 整合中
* [ ] 週邊模組實作（UART, SPI, DMA）
* [ ] Linux Driver 驅動支援

## 📂 專案架構 (暫定)

```
riscv_soc/
 ├── riscv32i_core/             # RISC-V CPU RTL (Verilog)
 ├── bus/              # AXI/APB 匯流排與仲裁器
 ├── peripherals/      # UART, SPI, DMA, MAC 等週邊
 ├── memory/           # Boot ROM, SRAM, DRAM Controller
 ├── sim/              # ModelSim 測試平台與 testbench
 └── doc/              # 架構圖與技術文件
```



---

## 🎯 未來計畫

* 完成 AXI/APB 匯流排整合
* 新增中斷控制器 (PLIC/CLINT)
* 增加 SoC 週邊 (UART, SPI, DMA, Ethernet MAC)
* 驗證 Linux Kernel 移植可行性

---


