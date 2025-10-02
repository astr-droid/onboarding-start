// pwm_peripheral.v  (synthesis-friendly, unrolled outputs)
`default_nettype none
module pwm_peripheral (
    input  wire        clk,            // 10 MHz
    input  wire        rst_n,
    input  wire        ena,            // enable input from top
    input  wire [7:0]  en_reg_out_7_0,
    input  wire [7:0]  en_reg_out_15_8,
    input  wire [7:0]  en_reg_pwm_7_0,
    input  wire [7:0]  en_reg_pwm_15_8,
    input  wire [7:0]  pwm_duty_cycle, // 0..255
    output reg  [15:0] out             // {uio_out[7:0], uo_out[7:0]}
);

    // explicit width for divider constant
    localparam [11:0] DIV_MAX = 12'd3334; // 10_000_000 / 3334 ~ 2999.4 Hz

    reg [11:0] clk_div;
    reg        pwm_tick;

    // prescaler to create pwm period tick
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div  <= 12'd0;
            pwm_tick <= 1'b0;
        end else begin
            if (!ena) begin
                // deterministic behavior when disabled: hold counters at zero
                clk_div  <= 12'd0;
                pwm_tick <= 1'b0;
            end else if (clk_div == (DIV_MAX - 1)) begin
                clk_div  <= 12'd0;
                pwm_tick <= 1'b1;
            end else begin
                clk_div  <= clk_div + 12'd1;
                pwm_tick <= 1'b0;
            end
        end
    end

    // PWM counter runs 0..255 on pwm_tick
    reg [7:0] pwm_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 8'd0;
        end else begin
            if (!ena) begin
                pwm_counter <= 8'd0;
            end else if (pwm_tick) begin
                pwm_counter <= pwm_counter + 8'd1;
            end
        end
    end

    // Unrolled output assignments (fully explicit, synthesizable)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 16'h0000;
        end else if (!ena) begin
            out <= 16'h0000;
        end else begin
            // Lower byte uo_out[7:0]
            // bit 0
            if (en_reg_out_7_0[0] == 1'b0) out[0] <= 1'b0;
            else if (en_reg_pwm_7_0[0] == 1'b1)
                out[0] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[0] <= 1'b1;

            // bit 1
            if (en_reg_out_7_0[1] == 1'b0) out[1] <= 1'b0;
            else if (en_reg_pwm_7_0[1] == 1'b1)
                out[1] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[1] <= 1'b1;

            // bit 2
            if (en_reg_out_7_0[2] == 1'b0) out[2] <= 1'b0;
            else if (en_reg_pwm_7_0[2] == 1'b1)
                out[2] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[2] <= 1'b1;

            // bit 3
            if (en_reg_out_7_0[3] == 1'b0) out[3] <= 1'b0;
            else if (en_reg_pwm_7_0[3] == 1'b1)
                out[3] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[3] <= 1'b1;

            // bit 4
            if (en_reg_out_7_0[4] == 1'b0) out[4] <= 1'b0;
            else if (en_reg_pwm_7_0[4] == 1'b1)
                out[4] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[4] <= 1'b1;

            // bit 5
            if (en_reg_out_7_0[5] == 1'b0) out[5] <= 1'b0;
            else if (en_reg_pwm_7_0[5] == 1'b1)
                out[5] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[5] <= 1'b1;

            // bit 6
            if (en_reg_out_7_0[6] == 1'b0) out[6] <= 1'b0;
            else if (en_reg_pwm_7_0[6] == 1'b1)
                out[6] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[6] <= 1'b1;

            // bit 7
            if (en_reg_out_7_0[7] == 1'b0) out[7] <= 1'b0;
            else if (en_reg_pwm_7_0[7] == 1'b1)
                out[7] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[7] <= 1'b1;

            // Upper byte uio_out[7:0] -> out[8..15]
            if (en_reg_out_15_8[0] == 1'b0) out[8]  <= 1'b0;
            else if (en_reg_pwm_15_8[0] == 1'b1)
                out[8]  <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[8]  <= 1'b1;

            if (en_reg_out_15_8[1] == 1'b0) out[9]  <= 1'b0;
            else if (en_reg_pwm_15_8[1] == 1'b1)
                out[9]  <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[9]  <= 1'b1;

            if (en_reg_out_15_8[2] == 1'b0) out[10] <= 1'b0;
            else if (en_reg_pwm_15_8[2] == 1'b1)
                out[10] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[10] <= 1'b1;

            if (en_reg_out_15_8[3] == 1'b0) out[11] <= 1'b0;
            else if (en_reg_pwm_15_8[3] == 1'b1)
                out[11] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[11] <= 1'b1;

            if (en_reg_out_15_8[4] == 1'b0) out[12] <= 1'b0;
            else if (en_reg_pwm_15_8[4] == 1'b1)
                out[12] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[12] <= 1'b1;

            if (en_reg_out_15_8[5] == 1'b0) out[13] <= 1'b0;
            else if (en_reg_pwm_15_8[5] == 1'b1)
                out[13] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[13] <= 1'b1;

            if (en_reg_out_15_8[6] == 1'b0) out[14] <= 1'b0;
            else if (en_reg_pwm_15_8[6] == 1'b1)
                out[14] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[14] <= 1'b1;

            if (en_reg_out_15_8[7] == 1'b0) out[15] <= 1'b0;
            else if (en_reg_pwm_15_8[7] == 1'b1)
                out[15] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
            else out[15] <= 1'b1;
        end
    end

endmodule
