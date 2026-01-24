`timescale 1ns / 1ps
`include "define.v"
module id(
    //if_id
    input wire [31:0] if_id_addr_in,
    input wire [31:0] if_id_instr_in,

    //reg_file
    input wire [31:0] rs1_data_in,
    input wire [31:0] rs2_data_in,
    output reg [4:0] rs1_addr_out,
    output reg [4:0] rs2_addr_out,

    //ex
    output reg [31:0] id_instr_out,
    output reg [31:0] id_addr_out,
    output reg [31:0] id_op1_data_out,
    output reg [31:0] id_op2_data_out,
    output reg [31:0] id_imm_out,   // 新增: 傳遞立即數
    output reg [31:0] id_store_data_out, // 新增: Store 用資料 (rs2)
    output reg [4:0] id_rd_addr_out,

    //Control Signals
    output reg reg_enable,
    output reg mem_we,     // Memory Write Enable
    output reg mem_re,     // Memory Read Enable
    output reg branch_flag,// Branch/Jump flag
    output reg [2:0] func3_out,
    output reg [6:0] opcode_out
);
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  func3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    
    wire [6:0]  func7;
    wire [11:0] imm;

    assign opcode = if_id_instr_in[6:0];
    assign rd     = if_id_instr_in[11:7];
    assign func3  = if_id_instr_in[14:12];
    assign rs1    = if_id_instr_in[19:15];
    assign rs2    = if_id_instr_in[24:20];
    assign func7  = if_id_instr_in[31:25];
    assign imm    = if_id_instr_in[31:20];

    always@(*)begin
        id_instr_out = if_id_instr_in;
        id_addr_out  = if_id_addr_in;

        opcode_out  = opcode;
        func3_out   = func3;
        
        branch_flag = 1'b0; 
        mem_we      = 1'b0;
        mem_re      = 1'b0; 
        case(opcode)
            `INST_TYPE_I:begin
                case(func3)
                    `INST_ADDI:begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = {{20{imm[11]}},imm[11:0]}; //擴展符號位到32bits
                        reg_enable      = 1'b1;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = 5'b0; //不需要
                    end
                    default:begin
                        id_op1_data_out = 32'b0;
                        id_op2_data_out = 32'b0;
                        reg_enable      = 1'b0;
                        id_rd_addr_out  = 5'b0;
                        rs1_addr_out    = 5'b0;
                        rs2_addr_out    = 5'b0; 
                    end
                endcase
            end
            `INST_TYPE_R_M:begin
                case(func3)
                    `INST_ADD_SUB:begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = rs2_data_in;
                        reg_enable      = 1'b1;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = rs2;
                    end
                    // ★★★ [新增] 補上 OR 指令 ★★★
                    `INST_OR: begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = rs2_data_in;
                        reg_enable      = 1'b1; // 要寫回
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = rs2;
                    end

                    // ★★★ [新增] 補上 AND 指令 ★★★
                    `INST_AND: begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = rs2_data_in;
                        reg_enable      = 1'b1; // 要寫回
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = rs2;
                    end
                    default:begin
                        id_op1_data_out = 32'b0;
                        id_op2_data_out = 32'b0;
                        reg_enable      = 1'b0;
                        id_rd_addr_out  = 5'b0;
                        rs1_addr_out    = 5'b0;
                        rs2_addr_out    = 5'b0; 
                    end
                endcase
            end 
            `INST_TYPE_L: begin // Load 指令
                id_op1_data_out = rs1_data_in;
                id_op2_data_out = {{20{imm[11]}}, imm[11:0]}; // 用 ALU 算地址: rs1 + imm
                reg_enable      = 1'b1; // 要寫回暫存器
                mem_re          = 1'b1; // 開啟記憶體讀取
                mem_we          = 1'b0;
                id_rd_addr_out  = rd;
                rs1_addr_out    = rs1;
                rs2_addr_out    = 5'b0;
            end

            `INST_TYPE_S: begin // Store 指令
                id_op1_data_out = rs1_data_in;
                id_op2_data_out = {{20{imm[11]}}, imm[11:0]}; // 用 ALU 算地址
                id_store_data_out = rs2_data_in; // 存入的值
                reg_enable      = 1'b0;
                mem_re          = 1'b0;
                mem_we          = 1'b1; // 開啟記憶體寫入
                id_rd_addr_out  = 5'b0;
                rs1_addr_out    = rs1;
                rs2_addr_out    = rs2;
            end

            `INST_TYPE_B: begin // Branch 指令
                id_op1_data_out = rs1_data_in;
                id_op2_data_out = rs2_data_in;
                // Branch 比較需要 rs1 和 rs2，不用寫回
                reg_enable      = 1'b0;
                mem_we          = 1'b0;
                mem_re          = 1'b0;
                branch_flag     = 1'b1; // 告訴 Control Unit 這是分支指令 (雖然你目前的 ctrl.v 好像沒用到這個 flag，但 ex.v 會算)
                id_imm_out = {{19{if_id_instr_in[31]}}, if_id_instr_in[31], if_id_instr_in[7], if_id_instr_in[30:25], if_id_instr_in[11:8], 1'b0};
                
                id_rd_addr_out  = 5'b0;
                rs1_addr_out    = rs1;
                rs2_addr_out    = rs2;
            end
            default:begin
                id_op1_data_out = 32'b0;
                id_op2_data_out = 32'b0;
                reg_enable      = 1'b0;
                id_rd_addr_out  = 5'b0;
                rs1_addr_out    = 5'b0;
                rs2_addr_out    = 5'b0; 
            end
        endcase
    end


endmodule