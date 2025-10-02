// pwm_peripheral.v
`default_nettype none
module pwm_peripheral (
    input  wire        clk,            
    input  wire        rst_n,
    input  wire        ena,
    input  wire [7:0]  en_reg_out_7_0,
    input  wire [7:0]  en_reg_out_15_8,
    input  wire [7:0]  en_reg_pwm_7_0,
    input  wire [7:0]  en_reg_pwm_15_8,
    input  wire [7:0]  pwm_duty_cycle,
    output reg  [15:0] out
);

    localparam integer DIV_MAX = 3334;

    reg [11:0] clk_div;
    reg        pwm_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 12'd0;
            pwm_tick <= 1'b0;
        end else if (ena) begin
            if (clk_div == (DIV_MAX-1)) begin
                clk_div <= 12'd0;
                pwm_tick <= 1'b1;
            end else begin
                clk_div <= clk_div + 1'b1;
                pwm_tick <= 1'b0;
            end
        end
    end

    reg [7:0] pwm_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 8'd0;
        end else if (pwm_tick && ena) begin
            pwm_counter <= pwm_counter + 8'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 16'h0000;
        end else if (ena) begin
            // Lower byte: uo_out[7:0]
            out[0] <= (en_reg_out_7_0[0] && en_reg_pwm_7_0[0]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[0];
            out[1] <= (en_reg_out_7_0[1] && en_reg_pwm_7_0[1]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[1];
            out[2] <= (en_reg_out_7_0[2] && en_reg_pwm_7_0[2]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[2];
            out[3] <= (en_reg_out_7_0[3] && en_reg_pwm_7_0[3]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[3];
            out[4] <= (en_reg_out_7_0[4] && en_reg_pwm_7_0[4]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[4];
            out[5] <= (en_reg_out_7_0[5] && en_reg_pwm_7_0[5]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[5];
            out[6] <= (en_reg_out_7_0[6] && en_reg_pwm_7_0[6]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[6];
            out[7] <= (en_reg_out_7_0[7] && en_reg_pwm_7_0[7]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_7_0[7];

            // Upper byte: uio_out[7:0]
            out[8]  <= (en_reg_out_15_8[0] && en_reg_pwm_15_8[0]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[0];
            out[9]  <= (en_reg_out_15_8[1] && en_reg_pwm_15_8[1]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[1];
            out[10] <= (en_reg_out_15_8[2] && en_reg_pwm_15_8[2]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[2];
            out[11] <= (en_reg_out_15_8[3] && en_reg_pwm_15_8[3]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[3];
            out[12] <= (en_reg_out_15_8[4] && en_reg_pwm_15_8[4]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[4];
            out[13] <= (en_reg_out_15_8[5] && en_reg_pwm_15_8[5]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[5];
            out[14] <= (en_reg_out_15_8[6] && en_reg_pwm_15_8[6]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[6];
            out[15] <= (en_reg_out_15_8[7] && en_reg_pwm_15_8[7]) ? (pwm_counter < pwm_duty_cycle) : en_reg_out_15_8[7];
        end
    end

endmodule
