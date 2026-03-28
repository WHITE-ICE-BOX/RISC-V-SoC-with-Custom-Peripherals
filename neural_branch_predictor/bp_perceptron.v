`timescale 1ns / 1ps

module bp_perceptron #(
    parameter INDEX_BITS = 4,
    parameter HIST_LEN   = 8,
    parameter W_BITS     = 4,
    parameter SUM_BITS   = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // predict
    input  wire [INDEX_BITS-1:0]    pc_index,
    input  wire [HIST_LEN-1:0]      ghr,
    output reg                      pred_taken,
    output reg [$clog2(HIST_LEN+1)-1:0] used_steps,
    output reg signed [SUM_BITS-1:0] pred_sum,

    // update
    input  wire                     update_en,
    input  wire [INDEX_BITS-1:0]    update_index,
    input  wire [HIST_LEN-1:0]      update_ghr,
    input  wire                     actual_taken,
    input  wire                     was_mispredict
);

    localparam ENTRIES = (1 << INDEX_BITS);
    localparam signed [W_BITS-1:0] WMAX = (1 << (W_BITS-1)) - 1;
    localparam signed [W_BITS-1:0] WMIN = -(1 << (W_BITS-1));

    reg signed [W_BITS-1:0] bias_mem [0:ENTRIES-1];
    reg signed [W_BITS-1:0] w_mem    [0:ENTRIES-1][0:HIST_LEN-1];

    integer i, j;

    function signed [W_BITS-1:0] sat_inc;
        input signed [W_BITS-1:0] val;
        begin
            if (val >= WMAX) sat_inc = WMAX;
            else             sat_inc = val + 1'sb1;
        end
    endfunction

    function signed [W_BITS-1:0] sat_dec;
        input signed [W_BITS-1:0] val;
        begin
            if (val <= WMIN) sat_dec = WMIN;
            else             sat_dec = val - 1'sb1;
        end
    endfunction

    reg signed [SUM_BITS-1:0] sum_acc;
    reg signed [SUM_BITS-1:0] remain_bound;
    reg early_stop;

    always @(*) begin
        sum_acc      = bias_mem[pc_index];
        pred_sum     = bias_mem[pc_index];
        pred_taken   = 1'b0;
        used_steps   = HIST_LEN[$clog2(HIST_LEN+1)-1:0];
        early_stop   = 1'b0;

        for (i = 0; i < HIST_LEN; i = i + 1) begin
            if (!early_stop) begin
                if (ghr[i])
                    sum_acc = sum_acc + w_mem[pc_index][i];
                else
                    sum_acc = sum_acc - w_mem[pc_index][i];

                remain_bound = (HIST_LEN - 1 - i) * WMAX;

                if (sum_acc >= remain_bound) begin
                    early_stop = 1'b1;
                    used_steps = i + 1;
                end
                else if (sum_acc <= -remain_bound) begin
                    early_stop = 1'b1;
                    used_steps = i + 1;
                end
            end
        end

        pred_sum   = sum_acc;
        pred_taken = (sum_acc >= 0);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                bias_mem[i] <= {W_BITS{1'b0}};
                for (j = 0; j < HIST_LEN; j = j + 1)
                    w_mem[i][j] <= {W_BITS{1'b0}};
            end
        end
        else if (update_en && was_mispredict) begin
            // bias update
            if (actual_taken)
                bias_mem[update_index] <= sat_inc(bias_mem[update_index]);
            else
                bias_mem[update_index] <= sat_dec(bias_mem[update_index]);

            // weight update: wi <- wi + t*xi
            for (j = 0; j < HIST_LEN; j = j + 1) begin
                if (actual_taken == update_ghr[j])
                    w_mem[update_index][j] <= sat_inc(w_mem[update_index][j]);
                else
                    w_mem[update_index][j] <= sat_dec(w_mem[update_index][j]);
            end
        end
    end

endmodule
