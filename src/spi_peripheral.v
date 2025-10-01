// spi_peripheral.v
// SPI peripheral for UWASIC onboarding
// Samples COPI on SCLK rising edge (Mode 0). No CIPO (write-only).
`default_nettype none

module spi_peripheral (
    input  wire       clk,       // 10 MHz system clock
    input  wire       rst_n,     // active low reset
    // physical SPI pins (from tiny tapeout / top)
    input  wire       ui_in_sclk, // ui_in[0]
    input  wire       ui_in_copi, // ui_in[1]
    input  wire       ui_in_ncs,  // ui_in[2]
    // outputs: register wires (exported to top)
    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    // localparams
    localparam MAX_ADDR = 7'h04; // 0..4 valid

    // Synchronizers (2-stage) for SCLK, COPI, nCS
    reg sclk_sync_0, sclk_sync_1;
    reg copi_sync_0, copi_sync_1;
    reg ncs_sync_0, ncs_sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync_0 <= 1'b0;
            sclk_sync_1 <= 1'b0;
            copi_sync_0 <= 1'b0;
            copi_sync_1 <= 1'b0;
            ncs_sync_0  <= 1'b1; // idle deasserted high
            ncs_sync_1  <= 1'b1;
        end else begin
            sclk_sync_0 <= ui_in_sclk;
            sclk_sync_1 <= sclk_sync_0;
            copi_sync_0 <= ui_in_copi;
            copi_sync_1 <= copi_sync_0;
            ncs_sync_0  <= ui_in_ncs;
            ncs_sync_1  <= ncs_sync_0;
        end
    end

    // Edge detection on SCLK (rising) and nCS edges (falling->start, rising->end)
    reg sclk_sync_1_d;
    reg ncs_sync_1_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync_1_d <= 1'b0;
            ncs_sync_1_d  <= 1'b1;
        end else begin
            sclk_sync_1_d <= sclk_sync_1;
            ncs_sync_1_d  <= ncs_sync_1;
        end
    end

    wire sclk_rising = (sclk_sync_1 == 1'b1) && (sclk_sync_1_d == 1'b0);
    wire ncs_falling = (ncs_sync_1 == 1'b0) && (ncs_sync_1_d == 1'b1);
    wire ncs_rising  = (ncs_sync_1 == 1'b1) && (ncs_sync_1_d == 1'b0);

    // Shift register and counter: capture on SCLK rising when transaction active (nCS low)
    reg [15:0] shift_reg;
    reg [4:0]  bit_count; // need up to 16
    reg        in_transaction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 16'b0;
            bit_count      <= 5'd0;
            in_transaction <= 1'b0;
        end else begin
            // Start a new transaction on nCS falling: reset counter/shiftreg
            if (ncs_falling) begin
                in_transaction <= 1'b1;
                bit_count <= 5'd0;
                shift_reg <= 16'b0;
            end

            // During transaction, on each sclk rising, shift in COPI (MSB-first)
            if (in_transaction && sclk_rising) begin
                // shift left and insert newest bit as LSB or MSB depending on convention.
                // We'll collect bits MSB-first: first bit becomes shift_reg[15]
                shift_reg <= { shift_reg[14:0], copi_sync_1 };
                bit_count <= bit_count + 1'b1;
            end

            // Transaction ends on nCS rising; we will process then and leave in_transaction low.
            if (ncs_rising) begin
                in_transaction <= 1'b0;
            end
        end
    end

    // Transaction processing handshake flags to avoid conflicting writes
    reg transaction_ready;
    reg transaction_processed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_ready     <= 1'b0;
            transaction_processed <= 1'b0;
        end else begin
            // When nCS rises, mark transaction ready if exactly 16 bits captured
            if (ncs_rising) begin
                if (bit_count == 5'd16) begin
                    transaction_ready <= 1'b1;
                    transaction_processed <= 1'b0;
                end else begin
                    // incomplete -> ignore
                    transaction_ready <= 1'b0;
                    transaction_processed <= 1'b0;
                end
            end else if (transaction_processed) begin
                // clear once processed
                transaction_ready <= 1'b0;
                transaction_processed <= 1'b0;
            end
        end
    end

    // Process the captured transaction in a separate sequential block (safe single-writer)
    // shift_reg contains bits in arrival order with first bit in shift_reg[15] (MSB)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0    <= 8'h00;
            en_reg_out_15_8   <= 8'h00;
            en_reg_pwm_7_0    <= 8'h00;
            en_reg_pwm_15_8   <= 8'h00;
            pwm_duty_cycle    <= 8'h00;
        end else begin
            if (transaction_ready && !transaction_processed) begin
                // Extract fields
                // bit layout: [15] = first bit (R/W), [14:8] = 7-bit addr, [7:0] = data
                wire rw_bit;
                wire [6:0] addr;
                wire [7:0] data;
                assign rw_bit = shift_reg[15];
                assign addr   = shift_reg[14:8];
                assign data   = shift_reg[7:0];

                if (rw_bit == 1'b1) begin
                    // only do writes, ignore reads
                    if (addr <= MAX_ADDR) begin
                        case (addr)
                            7'h00: en_reg_out_7_0  <= data;
                            7'h01: en_reg_out_15_8 <= data;
                            7'h02: en_reg_pwm_7_0  <= data;
                            7'h03: en_reg_pwm_15_8 <= data;
                            7'h04: pwm_duty_cycle  <= data;
                            default: begin end
                        endcase
                    end
                end
                // mark processed
                transaction_processed <= 1'b1;
            end
        end
    end

endmodule
