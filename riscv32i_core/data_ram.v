`timescale 1ns / 1ps
module data_ram(
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] ram [0:1023]; // 1K word

    always @(*) begin
        // 簡易讀取，address >> 2
        data_out = ram[addr[31:2]];
    end

    always @(posedge clk) begin
        if (we) begin
            ram[addr[31:2]] <= data_in;
        end
    end
endmodule