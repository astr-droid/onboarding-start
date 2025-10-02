// spi_peripheral.v
// SPI peripheral for UWASIC onboarding
// Samples COPI on SCLK rising edge (Mode 0). No CIPO (write-only).
`default_nettype none

module spi_peripheral (
    input  wire       clk,       // 10 MHz system clock
    input  wire       rst_n,     // active low reset
    input  wire       ui_in_sclk,
    input  wire       ui_in_copi,
    input  wire       ui_in_ncs,
    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    localparam MAX_ADDR = 7'h04; // 0..4 valid

    // Synchronizers
    reg sclk_sync_0, sclk_sync_1;
    reg copi_sync_0, copi_sync_1;
    reg ncs_sync_0, ncs_sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync_0 <= 1'b0; sclk_sync_1 <= 1'b0;
            copi_sync_0 <= 1'b0; copi_sync_1 <= 1'b0;
            ncs_sync_0  <= 1'b1; ncs_sync_1  <= 1'b1;
        end else begin
            sclk_sync_0 <= ui_in_sclk;
            sclk_sync_1 <= sclk_sync_0;
            copi_sync_0 <= ui_in_copi;
            copi_sync_1 <= copi_sync_0;
            ncs_sync_0  <= ui_in_ncs;
            ncs_sync_1  <= ncs_sync_0;
        end
    end

    // Edge detection
    reg sclk_sync_1_d, ncs_sync_1_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync_1_d <= 1'b0;
            ncs_sync_1_d  <= 1'b1;
        end else begin
            sclk_sync_1_d <= sclk_sync_1;
            ncs_sync_1_d  <= ncs_sync_1;
        end
    end

    wire sclk_rising = sclk_sync_1 & ~sclk_sync_1_d;
    wire ncs_falling = ~ncs_sync_1 & ncs_sync_1_d;
    wire ncs_rising  = ncs_sync_1 & ~ncs_sync_1_d;

    // Shift register and counter
    reg [15:0] shift_reg;
    reg [4:0]  bit_count;
    reg        in_transaction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'b0;
            bit_count <= 5'd0;
            in_transaction <= 1'b0;
        end else begin
            if (ncs_falling) begin
                in_transaction <= 1'b1;
                shift_reg <= 16'b0;
                bit_count <= 5'd0;
            end
            if (in_transaction && sclk_rising) begin
                shift_reg <= { shift_reg[14:0], copi_sync_1 };
                bit_count <= bit_count + 1'b1;
            end
            if (ncs_rising) in_transaction <= 1'b0;
        end
    end

    // Transaction ready flags
    reg transaction_ready;
    reg transaction_processed;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_ready <= 1'b0;
            transaction_processed <= 1'b0;
        end else begin
            if (ncs_rising && bit_count == 16) begin
                transaction_ready <= 1'b1;
                transaction_processed <= 1'b0;
            end else if (transaction_processed) begin
                transaction_ready <= 1'b0;
                transaction_processed <= 1'b0;
            end
        end
    end

    // Transaction processing
    reg rw_bit;
    reg [6:0] addr;
    reg [7:0] data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0    <= 8'h00;
            en_reg_out_15_8   <= 8'h00;
            en_reg_pwm_7_0    <= 8'h00;
            en_reg_pwm_15_8   <= 8'h00;
            pwm_duty_cycle    <= 8'h00;
            rw_bit <= 1'b0;
            addr <= 7'b0;
            data <= 8'b0;
        end else begin
            if (transaction_ready && !transaction_processed) begin
                rw_bit <= shift_reg[15];
                addr   <= shift_reg[14:8];
                data   <= shift_reg[7:0];

                if (rw_bit && addr <= MAX_ADDR) begin
                    case (addr)
                        7'h00: en_reg_out_7_0  <= data;
                        7'h01: en_reg_out_15_8 <= data;
                        7'h02: en_reg_pwm_7_0  <= data;
                        7'h03: en_reg_pwm_15_8 <= data;
                        7'h04: pwm_duty_cycle  <= data;
                        default: ;
                    endcase
                end
                transaction_processed <= 1'b1;
            end
        end
    end

endmodule
