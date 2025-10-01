/*
 * Copyright (c) 2025 Aadhya Anand
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * Copyright (c) 2025 Aadhya Anand
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none

module tt_um_uwasic_onboarding_aadhya_anand (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,   // SPI inputs: ui_in[0]=SCLK, ui_in[1]=COPI, ui_in[2]=nCS
    input  wire       ena,
    output wire [7:0] uo_out,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    // ----------------------------------------
    // 1. Set all IOs to output
    // ----------------------------------------
    assign uio_oe = 8'hFF;

    // ----------------------------------------
    // 2. Wires for SPI-controlled registers
    // ----------------------------------------
    wire [7:0] en_reg_out_7_0;
    wire [7:0] en_reg_out_15_8;
    wire [7:0] en_reg_pwm_7_0;
    wire [7:0] en_reg_pwm_15_8;
    wire [7:0] pwm_duty_cycle;

    // ----------------------------------------
    // 3. Instantiate SPI peripheral
    // ----------------------------------------
    spi_peripheral spi_inst (
        .clk(clk),
        .rst_n(rst_n),
        .nCS(ui_in[2]),
        .SCLK(ui_in[0]),
        .COPI(ui_in[1]),
        .en_reg_out_7_0(en_reg_out_7_0),
        .en_reg_out_15_8(en_reg_out_15_8),
        .en_reg_pwm_7_0(en_reg_pwm_7_0),
        .en_reg_pwm_15_8(en_reg_pwm_15_8),
        .pwm_duty_cycle(pwm_duty_cycle)
    );

    // ----------------------------------------
    // 4. Instantiate PWM peripheral
    // ----------------------------------------
    pwm_peripheral pwm_peripheral_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en_reg_out_7_0(en_reg_out_7_0),
        .en_reg_out_15_8(en_reg_out_15_8),
        .en_reg_pwm_7_0(en_reg_pwm_7_0),
        .en_reg_pwm_15_8(en_reg_pwm_15_8),
        .pwm_duty_cycle(pwm_duty_cycle),
        .out({uio_out, uo_out})
    );

    // ----------------------------------------
    // 5. Prevent warnings for unused signals
    // ----------------------------------------
    wire _unused = &{ena, ui_in[7:3], 1'b0};

endmodule
