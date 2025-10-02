# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.types import LogicArray

# Constants
PWM_TARGET_HZ = 3000
FREQ_TOL = 0.01   # ±1%
DUTY_TOL = 0.01   # ±1%
CLK_PERIOD_NS = 100  # 10 MHz

# -------------------------
# Helper Functions
# -------------------------
async def await_half_sclk(dut):
    """Wait for half an SCLK period (~5 us for 100 kHz SPI SCLK)."""
    await ClockCycles(dut.clk, 50)

def ui_in_logicarray(ncs, bit, sclk):
    """Pack NCS, bit, and SCLK into ui_in as a LogicArray."""
    return LogicArray(f"00000{ncs}{bit}{sclk}")

async def send_spi_transaction(dut, r_w, address, data):
    """Send an SPI transaction (1-bit RW + 7-bit addr + 8-bit data)"""
    first_byte = (int(r_w) << 7) | address
    ncs = 0
    sclk = 0
    bit = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 1)

    # Send first byte
    for i in range(8):
        bit = (first_byte >> (7-i)) & 0x1
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

    # Send second byte (data)
    for i in range(8):
        bit = (data >> (7-i)) & 0x1
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)

    # End transaction
    ncs = 1
    sclk = 0
    bit = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await Timer(10_000, units="ns")  # GL-safe wait for propagation

# -------------------------
# SPI TEST
# -------------------------
@cocotb.test()
async def test_spi(dut):
    dut._log.info("Start SPI test")

    # Clock
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # Write transaction: 0x00 → 0xF0
    await send_spi_transaction(dut, 1, 0x00, 0xF0)
    await Timer(5_000, units="ns")
    val = dut.uo_out.value.integer
    assert val == 0xF0, f"Expected 0xF0, got {val:#02x}"

    # Write transaction: 0x01 → 0xCC
    await send_spi_transaction(dut, 1, 0x01, 0xCC)
    await Timer(5_000, units="ns")
    val = dut.uio_out.value.integer
    assert val == 0xCC, f"Expected 0xCC, got {val:#02x}"

    # Invalid write: 0x30 → 0xAA
    await send_spi_transaction(dut, 1, 0x30, 0xAA)
    await Timer(5_000, units="ns")

    # Read (invalid)
    await send_spi_transaction(dut, 0, 0x30, 0xBE)
    await Timer(5_000, units="ns")
    val = dut.uo_out.value.integer
    assert val == 0xF0, f"Expected 0xF0, got {val:#02x}"

    # Write PWM duty cycle register
    await send_spi_transaction(dut, 1, 0x04, 0xFF)
    await Timer(10_000, units="ns")  # allow PWM to stabilize

    dut._log.info("SPI test completed successfully")

# -------------------------
# PWM FREQUENCY TEST
# -------------------------
@cocotb.test()
async def test_pwm_freq(dut):
    dut._log.info("Start PWM frequency test")

    # Wait for PWM to stabilize (GL-safe)
    await Timer(50_000, units="ns")

    # Use a safe wire instead of bit-select
    pwm_out = dut.uo_out
    rising1 = await RisingEdge(pwm_out)
    rising2 = await RisingEdge(pwm_out)

    period_ns = rising2.time - rising1.time
    freq = 1e9 / period_ns  # Hz
    assert abs(freq - PWM_TARGET_HZ)/PWM_TARGET_HZ < FREQ_TOL, f"PWM frequency out of tolerance: {freq} Hz"

    dut._log.info(f"PWM frequency OK: {freq} Hz")

# -------------------------
# PWM DUTY CYCLE TEST
# -------------------------
@cocotb.test()
async def test_pwm_duty(dut):
    dut._log.info("Start PWM duty cycle test")

    pwm_out = dut.uo_out  # GL-safe reference

    for duty_value in [0x00, 0x80, 0xFF]:
        await send_spi_transaction(dut, 1, 0x04, duty_value)
        await Timer(50_000, units="ns")  # GL-safe wait

        rising = await RisingEdge(pwm_out)
        falling = await FallingEdge(pwm_out)
        next_rising = await RisingEdge(pwm_out)

        high_time = falling.time - rising.time
        period = next_rising.time - rising.time
        measured_duty = high_time / period
        expected_duty = duty_value / 255.0

        assert abs(measured_duty - expected_duty) < DUTY_TOL, f"Duty mismatch: expected {expected_duty}, got {measured_duty}"
        dut._log.info(f"Duty {expected_duty*100:.1f}% OK, measured {measured_duty*100:.1f}%")

    dut._log.info("PWM duty cycle test completed successfully")
