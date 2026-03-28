# RISC-V SoC with Custom Peripherals

## 📌 專案簡介

本專案實作一個以 RISC-V Core (RISCV32I)為主體的 SoC，透過 Verilog RTL 撰寫與驗證，將逐步加入週邊控制器與匯流排架構。

## 🔧 開發環境

* **HDL 語言**: Verilog
* **模擬工具**: vivado/Modelsim
* **目標平台**: 可延伸至 FPGA 實作 (後續規劃)
* **Bus 架構**: AXI / APB 為主
* **模組設計**: 自行開發客製化控制模組 (UART, SPI, etc.)

## ✅ 目前進度

* [x] RISC-V CPU Core RTL 開發完成度：**約 70%**
* [x] vivado / ModelSim 模擬驗證 (基本指令集測試)
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

---


## testbench介紹
1. x1 = 10                                               (00000000101000000000000010010011)

2. x2 = 20                                               (00000001010000000000000100010011)

3. 將 x1 (10) 存入記憶體地址 0 (SW)                         (00000000000100000010000000100011)

4. 從記憶體地址 0 讀取到 x3 (LW, x3 應為 10)                 (00000000000000000010000110000011)

5. 檢查 x1 是否等於 x3 (BEQ)                               (00000000001100001000001001100011)

6. 如果相等，跳過下一行指令 (ADD x4)，直接執行再下一行 (ADD x5)。(00000000000100000000001000010011)
   
7. x4 應保持 0，x5 應變為 5。                               (00000000010100000000001010010011)
