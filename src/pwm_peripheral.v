// pwm_peripheral.v
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

    // derive ~3kHz from 10 MHz. Choose divider N so freq = clk / N
    localparam [11:0] DIV_MAX = 12'd3334; // explicitly 12-bit

    reg [11:0] clk_div; 
    reg        pwm_tick;

    // prescaler to create pwm period tick
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div  <= 12'd0;
            pwm_tick <= 1'b0;
        end else if (!ena) begin
            clk_div  <= clk_div; // hold value
            pwm_tick <= 1'b0;
        end else begin
            if (clk_div == (DIV_MAX - 1)) begin
                clk_div  <= 12'd0;
                pwm_tick <= 1'b1;
            end else begin
                clk_div  <= clk_div + 1'b1;
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
        end else if (!ena) begin
            out <= 16'h0000;
        end else begin
            // Compute PWM outputs every clock; comparisons based on current pwm_counter
            for (i = 0; i < 8; i = i + 1) begin
                // Lower byte = uo_out[7:0]
                if (en_reg_out_7_0[i] == 1'b0) begin
                    out[i] <= 1'b0;
                end else begin
                    if (en_reg_pwm_7_0[i] == 1'b1) begin
                        out[i] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
                    end else begin
                        out[i] <= 1'b1;
                    end
                end

                // Upper byte = uio_out[7:0]
                if (en_reg_out_15_8[i] == 1'b0) begin
                    out[8 + i] <= 1'b0;
                end else begin
                    if (en_reg_pwm_15_8[i] == 1'b1) begin
                        out[8 + i] <= (pwm_duty_cycle == 8'hFF || pwm_counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
                    end else begin
                        out[8 + i] <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
