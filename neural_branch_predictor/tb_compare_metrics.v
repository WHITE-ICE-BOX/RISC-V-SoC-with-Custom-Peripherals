`timescale 1ns/1ps

module tb_compare_metrics;

    reg clk;
    reg reset;

    // baseline counters
    integer base_total_branches;
    integer base_correct_predictions;
    integer base_mispredict_count;

    // innovation counters
    integer bp_total_branches;
    integer bp_correct_predictions;
    integer bp_mispredict_count;
    integer bp_neural_used_count;
    integer bp_total_used_steps;

    integer base_accuracy_x10000;
    integer bp_accuracy_x10000;
    integer accuracy_improvement_x10000;
    integer bp_neural_ratio_x10000;
    integer bp_avg_steps_x10000;

    // baseline wires
    wire [31:0] base_pc;
    wire [6:0]  base_ex_opcode;
    wire        base_actual_taken;
    wire        base_cond_branch;
    wire        base_pred_taken;

    // innovation wires
    wire [31:0] bp_pc;
    wire        bp_cond_branch;
    wire        bp_pred_taken;
    wire        bp_actual_taken;
    wire        bp_mispredict;
    wire        bp_use_neural;
    wire [3:0]  bp_used_steps;

    assign base_pc           = tb_compare_metrics.u_base.top_1.pc_now;
    assign base_ex_opcode    = tb_compare_metrics.u_base.top_1.ex_opcode;
    assign base_actual_taken = tb_compare_metrics.u_base.top_1.branch_taken;
    assign base_cond_branch  = (base_ex_opcode == 7'b1100011);
    assign base_pred_taken   = 1'b0;

    assign bp_pc           = tb_compare_metrics.u_bp.top_1.pc_now;
    assign bp_cond_branch  = tb_compare_metrics.u_bp.top_1.ex_is_cond_branch;
    assign bp_pred_taken   = tb_compare_metrics.u_bp.top_1.ex_pred_taken;
    assign bp_actual_taken = tb_compare_metrics.u_bp.top_1.branch_taken;
    assign bp_mispredict   = tb_compare_metrics.u_bp.top_1.ex_mispredict;
    assign bp_use_neural   = tb_compare_metrics.u_bp.top_1.ex_use_neural;
    assign bp_used_steps   = tb_compare_metrics.u_bp.top_1.ex_used_steps;

    always #4 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        base_total_branches      = 0;
        base_correct_predictions = 0;
        base_mispredict_count    = 0;

        bp_total_branches        = 0;
        bp_correct_predictions   = 0;
        bp_mispredict_count      = 0;
        bp_neural_used_count     = 0;
        bp_total_used_steps      = 0;

        base_accuracy_x10000        = 0;
        bp_accuracy_x10000          = 0;
        accuracy_improvement_x10000 = 0;
        bp_neural_ratio_x10000      = 0;
        bp_avg_steps_x10000         = 0;

        $display("\n======================================================================");
        $display(" Compare Baseline CPU vs Innovation CPU");
        $display("======================================================================");

        #10;
        reset = 0;
    end

    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
          u_base.rom_1.rom_mem);
    end

    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
          u_bp.rom_1.rom_mem);
    end

    risc_v_soc u_base(
        .clk(clk),
        .reset(reset)
    );

    risc_v_soc_bp u_bp(
        .clk(clk),
        .reset(reset)
    );

    always @(posedge clk) begin
        if (!reset) begin
            if (base_cond_branch) begin
                base_total_branches = base_total_branches + 1;

                if (base_pred_taken == base_actual_taken)
                    base_correct_predictions = base_correct_predictions + 1;
                else
                    base_mispredict_count = base_mispredict_count + 1;

                $display("[BASE] t=%0d pc=%0d pred=%0d actual=%0d total=%0d correct=%0d mis=%0d",
                         $time, base_pc, base_pred_taken, base_actual_taken,
                         base_total_branches, base_correct_predictions, base_mispredict_count);
            end
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            if (bp_cond_branch) begin
                bp_total_branches = bp_total_branches + 1;

                if (bp_pred_taken == bp_actual_taken)
                    bp_correct_predictions = bp_correct_predictions + 1;
                else
                    bp_mispredict_count = bp_mispredict_count + 1;

                if (bp_use_neural)
                    bp_neural_used_count = bp_neural_used_count + 1;

                bp_total_used_steps = bp_total_used_steps + bp_used_steps;

                $display("[BP  ] t=%0d pc=%0d pred=%0d actual=%0d neural=%0d steps=%0d total=%0d correct=%0d mis=%0d",
                         $time, bp_pc, bp_pred_taken, bp_actual_taken, bp_use_neural, bp_used_steps,
                         bp_total_branches, bp_correct_predictions, bp_mispredict_count);
            end
        end
    end

    initial begin
        #4000;

        if (base_total_branches != 0)
            base_accuracy_x10000 = (base_correct_predictions * 10000) / base_total_branches;
        else
            base_accuracy_x10000 = 0;

        if (bp_total_branches != 0)
            bp_accuracy_x10000 = (bp_correct_predictions * 10000) / bp_total_branches;
        else
            bp_accuracy_x10000 = 0;

        accuracy_improvement_x10000 = bp_accuracy_x10000 - base_accuracy_x10000;

        if (bp_total_branches != 0)
            bp_neural_ratio_x10000 = (bp_neural_used_count * 10000) / bp_total_branches;
        else
            bp_neural_ratio_x10000 = 0;

        if (bp_total_branches != 0)
            bp_avg_steps_x10000 = (bp_total_used_steps * 10000) / bp_total_branches;
        else
            bp_avg_steps_x10000 = 0;

        $display("----------------------------------------------------------------------");
        $display("FINAL COMPARISON");
        $display("----------------------------------------------------------------------");
        $display("Baseline Total Branches      : %0d", base_total_branches);
        $display("Baseline Correct             : %0d", base_correct_predictions);
        $display("Baseline Mispredict          : %0d", base_mispredict_count);
        $display("Baseline Accuracy (x10000)   : %0d", base_accuracy_x10000);

        $display("----------------------------------------------------------------------");
        $display("Innovation Total Branches    : %0d", bp_total_branches);
        $display("Innovation Correct           : %0d", bp_correct_predictions);
        $display("Innovation Mispredict        : %0d", bp_mispredict_count);
        $display("Innovation Accuracy (x10000) : %0d", bp_accuracy_x10000);
        $display("Innovation Neural Used       : %0d", bp_neural_used_count);
        $display("Innovation Neural Ratio      : %0d", bp_neural_ratio_x10000);
        $display("Innovation Avg Steps         : %0d", bp_avg_steps_x10000);

        $display("----------------------------------------------------------------------");
        $display("Accuracy Improvement         : %0d", accuracy_improvement_x10000);
        $display("Mispredict Reduction         : %0d", base_mispredict_count - bp_mispredict_count);
        $display("----------------------------------------------------------------------");
        $finish;
    end

endmodule
