import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_audio_synth(dut):
    dut._log.info("Starting Audio PMOD Synthesizer Test")

    # Тактовая частота 10 МГц (100 нс)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Сброс схемы (Reset)
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # 1. Проверяем покой: на выходе тишина
    assert dut.uo_out[7].value == 0
    assert dut.uo_out[1].value == 0

    # 2. Нажимаем клавишу ноты Ля (ui_in[5] = 1, маска 0x20)
    dut.ui_in.value = 0x20
    await ClockCycles(dut.clk, 100)

    # Загорелся светодиод активности
    assert dut.uo_out[1].value == 1

    # Ждем переключения звуковой волны
    await ClockCycles(dut.clk, 12000)
    assert dut.uo_out[7].value == 1

    dut._log.info("Audio Synthesizer test passed successfully!")
