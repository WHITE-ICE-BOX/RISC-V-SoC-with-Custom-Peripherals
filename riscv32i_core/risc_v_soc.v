`timescale 1ns / 1ps
//`include "top.v"
//`include "rom.v"
//`include "data_ram.v" // [新增] 引入 RAM 模組

module risc_v_soc(
    input wire clk,
    input wire reset,

    output wire [31:0] debug_pc_out// For debugging purpose
);
    wire [31:0] instr;
    wire [31:0] instr_addr;

    // [新增] Data RAM 連接訊號
    wire [31:0] ram_addr;
    wire [31:0] ram_wdata;
    wire ram_we;
    wire [31:0] ram_rdata;

    assign debug_pc_out = instr_addr;

    top top_1(
        .clk(clk),
        .reset(reset),
        .instr_in(instr),
        .instr_addr_out(instr_addr), // [修改] 變數名稱對齊
        // [新增] 連接 Data Memory 介面
        .ram_rdata(ram_rdata),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_we(ram_we)
    );
    rom rom_1(
        .addr_if_in(instr_addr),
        .instr_rom_out(instr)
    );
    data_ram dram_1(
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_wdata),
        .data_out(ram_rdata)
    );
endmodule