`default_nettype none

module spi_peripheral (
    input  wire       clk,       // System clock
    input  wire       rst_n,     // Active-low reset
    input  wire       nCS,       // Chip Select (active low)
    input  wire       SCLK,      // SPI Clock
    input  wire       COPI,      // Controller Out Peripheral In
    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    // -------------------------------
    // 1. Synchronize asynchronous signals
    // -------------------------------
    reg [1:0] nCS_sync, SCLK_sync, COPI_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nCS_sync  <= 2'b11;
            SCLK_sync <= 2'b00;
            COPI_sync <= 2'b00;
        end else begin
            nCS_sync  <= {nCS_sync[0], nCS};
            SCLK_sync <= {SCLK_sync[0], SCLK};
            COPI_sync <= {COPI_sync[0], COPI};
        end
    end

    wire nCS_s  = nCS_sync[1];
    wire SCLK_s = SCLK_sync[1];
    wire COPI_s = COPI_sync[1];

    // -------------------------------
    // 2. Detect rising edge of SCLK
    // -------------------------------
    reg SCLK_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            SCLK_prev <= 1'b0;
        else
            SCLK_prev <= SCLK_s;
    end

    wire SCLK_rising = SCLK_s & ~SCLK_prev;

    // -------------------------------
    // 3. Shift register to capture SPI bits
    // -------------------------------
    reg [15:0] shift_reg;
    reg [4:0]  bit_count; // counts 0-15

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'b0;
            bit_count <= 0;
        end else if (~nCS_s) begin  // active transaction
            if (SCLK_rising) begin
                shift_reg <= {shift_reg[14:0], COPI_s};
                bit_count <= bit_count + 1;
            end
        end else begin
            bit_count <= 0; // reset count when transaction ends
        end
    end

    // -------------------------------
    // 4. Capture transaction on nCS rising edge
    // -------------------------------
    reg [15:0] transaction;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            transaction <= 16'b0;
        else if (nCS_s & ~nCS_sync[0]) // rising edge of nCS
            transaction <= shift_reg;
    end

    // -------------------------------
    // 5. Decode transaction and write registers
    // -------------------------------
    wire       rw_bit = transaction[15];      // 1 = write, 0 = read (ignored)
    wire [6:0] addr   = transaction[14:8];
    wire [7:0] data   = transaction[7:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0  <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0  <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle  <= 8'h00;
        end else if (nCS_s & ~nCS_sync[0] & rw_bit) begin
            case(addr)
                7'h00: en_reg_out_7_0  <= data;
                7'h01: en_reg_out_15_8 <= data;
                7'h02: en_reg_pwm_7_0  <= data;
                7'h03: en_reg_pwm_15_8 <= data;
                7'h04: pwm_duty_cycle  <= data;
                default: ; // ignore invalid addresses
            endcase
        end
    end

endmodule
