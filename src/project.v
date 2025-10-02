// project.v
`default_nettype none
module tt_um_uwasic_onboarding_aadhya_anand (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] ui_in,    // [0]=SCLK, [1]=COPI, [2]=nCS, others unused
    input  wire [7:0] uio_in,
    output wire [7:0] uo_out,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    // set all uio to outputs per template
    assign uio_oe = 8'hFF;

    // Wires for registers exported from SPI peripheral
    wire [7:0] en_reg_out_7_0;
    wire [7:0] en_reg_out_15_8;
    wire [7:0] en_reg_pwm_7_0;
    wire [7:0] en_reg_pwm_15_8;
    wire [7:0] pwm_duty_cycle;

    // Instantiate spi_peripheral
    spi_peripheral spi_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in_sclk(ui_in[0]),
        .ui_in_copi(ui_in[1]),
        .ui_in_ncs(ui_in[2]),
        .en_reg_out_7_0(en_reg_out_7_0),
        .en_reg_out_15_8(en_reg_out_15_8),
        .en_reg_pwm_7_0(en_reg_pwm_7_0),
        .en_reg_pwm_15_8(en_reg_pwm_15_8),
        .pwm_duty_cycle(pwm_duty_cycle)
    );

    // Instantiate PWM peripheral
    wire [15:0] pwm_out;
    pwm_peripheral pwm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),                  // <-- always enabled
        .en_reg_out_7_0(en_reg_out_7_0),
        .en_reg_out_15_8(en_reg_out_15_8),
        .en_reg_pwm_7_0(en_reg_pwm_7_0),
        .en_reg_pwm_15_8(en_reg_pwm_15_8),
        .pwm_duty_cycle(pwm_duty_cycle),
        .out(pwm_out)
    );

    // split 16-bit pwm_out to uo_out (lower 8) and uio_out (upper 8)
    assign uo_out  = pwm_out[7:0];
    assign uio_out = pwm_out[15:8];

    // Avoid unused signal warnings
    wire _unused = &{uio_in, ui_in[7:3], 1'b0};

endmodule
