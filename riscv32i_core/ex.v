`timescale 1ns / 1ps
`include "define.v"
module ex(
    //id_ex
    input wire [31:0] id_ex_instr_in,
    input wire [31:0] id_ex_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [4:0]  rd_addr_in,
    input wire reg_enable_in,

    // [新增] 擴充輸入
    input wire [31:0] imm_in,
    input wire [31:0] store_data_in,
    input wire mem_we_in,
    input wire mem_re_in,
    input wire [2:0] func3_in,
    input wire [6:0] opcode_in,

    //result or wb
    output reg [31:0] op_out,
    output reg [4:0]  rd_addr_out,
    output reg reg_enable_out,

    // [新增] 擴充輸出
    output reg [31:0] store_data_out,
    output reg mem_we_out,
    output reg mem_re_out,
    output reg [2:0] func3_out,
    // [新增] Branch/Jump 相關輸出
    output reg branch_taken,
    output reg [31:0] branch_target_addr
);
    /*
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  func3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  func7;
    wire [11:0] imm;

    assign opcode = id_ex_instr_in[6:0];
    assign rd     = id_ex_instr_in[11:7];
    assign func3  = id_ex_instr_in[14:12];
    assign rs1    = id_ex_instr_in[19:15];
    assign rs2    = id_ex_instr_in[24:20];
    assign func7  = id_ex_instr_in[31:25];
    assign imm    = id_ex_instr_in[31:20];
    */

    // Pass-through 訊號
    always @(*) begin
        reg_enable_out = reg_enable_in;
        mem_we_out = mem_we_in;
        mem_re_out = mem_re_in;
        store_data_out = store_data_in;
        rd_addr_out = rd_addr_in;
        func3_out = func3_in;
    end

    always@(*)begin
        op_out = 32'b0;
        branch_taken = 1'b0;
        branch_target_addr = 32'b0;

        case(opcode_in)// [修改] 改用 ID 解碼好的 opcode
            `INST_TYPE_I:begin
                case(func3_in)
                    `INST_ADDI: op_out = op1_in + op2_in;
                    `INST_SLTI: op_out = ($signed(op1_in) < $signed(op2_in)) ? 1 : 0;
                    `INST_ORI:  op_out = op1_in | op2_in;
                    `INST_ANDI: op_out = op1_in & op2_in;
                    `INST_XORI: op_out = op1_in ^ op2_in;
                    `INST_SLLI: op_out = op1_in << op2_in[4:0]; // Shift
                    default:    op_out = 5'b0;
                endcase
            end
            `INST_TYPE_R_M:begin
                case(func3_in)
                    `INST_ADD_SUB:begin
                        if(id_ex_instr_in[30]) // 判斷 bit 30 (func7)
                            op_out = op1_in - op2_in; // SUB
                        else
                            op_out = op1_in + op2_in; // ADD
                    end
                    `INST_OR:  op_out = op1_in | op2_in;
                    `INST_AND: op_out = op1_in & op2_in;
                    default:   op_out = 0;
                endcase
            end
            `INST_TYPE_L: begin // Load
                op_out = op1_in + op2_in; // 計算地址 (rs1 + imm)
            end
            `INST_TYPE_S: begin // Store
                op_out = op1_in + op2_in; // 計算地址 (rs1 + imm)
            end
            `INST_TYPE_B: begin // Branch
                branch_target_addr = id_ex_addr_in + imm_in; // PC + imm
                case(func3_in)
                    `INST_BEQ: branch_taken = (op1_in == op2_in);
                    `INST_BNE: branch_taken = (op1_in != op2_in);
                    // 其他 B-type 暫略
                    default: branch_taken = 0;
                endcase
            end
            default:begin
                op_out = 32'b0;
                rd_addr_out = 5'b0; 
            end
        endcase
    end

endmodule