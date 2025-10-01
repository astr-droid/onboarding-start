`default_nettype none

module pwm_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] en_reg_out_7_0,
    input  wire [7:0] en_reg_out_15_8,
    input  wire [7:0] en_reg_pwm_7_0,
    input  wire [7:0] en_reg_pwm_15_8,
    input  wire [7:0] pwm_duty_cycle,
    output reg [15:0] out
);

    // Clock divider
    localparam clk_div_trig = 12;
    reg [10:0] clk_counter;
    reg [7:0] pwm_counter;

    // PWM combinational
    wire pwm_signal = (pwm_duty_cycle == 8'hFF) ? 1'b1 : (pwm_counter < pwm_duty_cycle);
    reg [15:0] pwm_out;

    always @* begin
        // Lower 8 bits
        pwm_out[7:0] = 0;
        for (int i = 0; i < 8; i=i+1)
            pwm_out[i] = en_reg_pwm_7_0[i] ? (pwm_signal & en_reg_out_7_0[i]) : en_reg_out_7_0[i];

        // Upper 8 bits
        pwm_out[15:8] = 0;
        for (int i = 0; i < 8; i=i+1)
            pwm_out[i+8] = en_reg_pwm_15_8[i] ? (pwm_signal & en_reg_out_15_8[i]) : en_reg_out_15_8[i];
    end

    // Counter and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 16'b0;
            clk_counter <= 0;
            pwm_counter <= 0;
        end else begin
            clk_counter <= clk_counter + 1;
            if (clk_counter == clk_div_trig) begin
                pwm_counter <= pwm_counter + 1;
                clk_counter <= 0;
            end
            out <= pwm_out;
        end
    end

endmodule
