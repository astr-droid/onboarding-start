// pwm_peripheral.v
`default_nettype none
module pwm_peripheral (
    input  wire        clk,            // 10 MHz
    input  wire        rst_n,
    input  wire        ena,
    input  wire [7:0]  en_reg_out_7_0,
    input  wire [7:0]  en_reg_out_15_8,
    input  wire [7:0]  en_reg_pwm_7_0,
    input  wire [7:0]  en_reg_pwm_15_8,
    input  wire [7:0]  pwm_duty_cycle, // 0..255
    output reg  [15:0] out             // {uio_out[7:0], uo_out[7:0]}
);

    // derive ~3kHz from 10 MHz. Choose divider N so freq = clk / N
    // We'll choose N = 3334 -> 10_000_000 / 3334 = 2999.4001 Hz (within 1%).
    localparam integer DIV_MAX = 3334;

    reg [11:0] clk_div; // needs to hold up to DIV_MAX
    reg        pwm_tick;

    // prescaler to create pwm period tick
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 12'd0;
            pwm_tick <= 1'b0;
        end else begin
            if (clk_div == (DIV_MAX - 1)) begin
                clk_div <= 12'd0;
                pwm_tick <= 1'b1;
            end else begin
                clk_div <= clk_div + 1'b1;
                pwm_tick <= 1'b0;
            end
        end
    end

    // PWM counter runs from 0..255 each pwm_tick (8-bit resolution)
    reg [7:0] pwm_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 8'd0;
        end else if (pwm_tick) begin
            pwm_counter <= pwm_counter + 8'd1;
        end
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 16'h0000;
        end else begin
            // Compute PWM outputs every clock; comparisons based on current pwm_counter
            for (i = 0; i < 8; i = i + 1) begin
                // choose which outputs are PWM-enabled, otherwise static enabled value
                // Lower byte = uo_out[7:0], Upper byte = uio_out[7:0]
                // static enable: en_reg_out_* bit => output 1 else 0
                // if PWM enable bit is set and static enable is also set -> output PWM (PWM mode bit)
                // but spec says: Output Enable takes precedence over PWM Mode
                // Interpreting: If output enable bit = 0 -> output 0. If output enable =1 and PWM enable =0 -> 1 (static).
                // If both 1 -> PWM behavior.
                // We'll implement that.
                // uo_out bit index i -> out[i]
                // uio_out bit index i -> out[8 + i]
                // compute uo
                if (en_reg_out_7_0[i] == 1'b0) begin
                    out[i] <= 1'b0;
                end else begin
                    if (en_reg_pwm_7_0[i] == 1'b1) begin
                        // PWM mode
                        if (pwm_duty_cycle == 8'hFF) begin
                            out[i] <= 1'b1;
                        end else begin
                            out[i] <= (pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
                        end
                    end else begin
                        // static on
                        out[i] <= 1'b1;
                    end
                end

                // uio_out
                if (en_reg_out_15_8[i] == 1'b0) begin
                    out[8 + i] <= 1'b0;
                end else begin
                    if (en_reg_pwm_15_8[i] == 1'b1) begin
                        if (pwm_duty_cycle == 8'hFF) begin
                            out[8 + i] <= 1'b1;
                        end else begin
                            out[8 + i] <= (pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
                        end
                    end else begin
                        out[8 + i] <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
