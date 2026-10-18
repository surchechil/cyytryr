`default_nettype none

module tt_um_surchechil_synth #(
    // Частота по умолчанию для Tiny Tapeout — 10 МГц.
    // Если запускаете на FPGA (например, 50 МГц), достаточно просто изменить этот параметр.
    parameter CLK_FREQ = 10_000_000
)(
    input  wire [7:0] ui_in,    // Кнопки нот (по умолчанию: 1 = нажата)
    output wire [7:0] uo_out,  
    input  wire [7:0] uio_in,  
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     // Сброс (Active-Low: 0 = сброс, 1 = работа)
);

    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;
    wire _unused = &{ena, uio_in, 1'b0};

    // -------------------------------------------------------------
    // 1. Синхронизатор входов (защита от метастабильности на кнопках)
    // -------------------------------------------------------------
    reg [7:0] ui_sync_1, ui_sync_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ui_sync_1 <= 8'b0;
            ui_sync_2 <= 8'b0;
        end else begin
            ui_sync_1 <= ui_in;
            ui_sync_2 <= ui_sync_1;
        end
    end

    // ЕСЛИ кнопки на вашей плате при нажатии замыкаются на 0 (Active-Low),
    // раскомментируйте инверсию ниже:
    // wire [7:0] keys = ~ui_sync_2;
    wire [7:0] keys = ui_sync_2;

    // -------------------------------------------------------------
    // 2. Расчет полупериодов нот (4-я октава)
    // -------------------------------------------------------------
    // Формула: CLK_FREQ / (2 * freq_Hz)
    localparam C4 = CLK_FREQ / (2 * 262); // До   (~261.63 Гц)
    localparam D4 = CLK_FREQ / (2 * 294); // Ре   (~293.66 Гц)
    localparam E4 = CLK_FREQ / (2 * 330); // Ми   (~329.63 Гц)
    localparam F4 = CLK_FREQ / (2 * 349); // Фа   (~349.23 Гц)
    localparam G4 = CLK_FREQ / (2 * 392); // Соль (~392.00 Гц)
    localparam A4 = CLK_FREQ / (2 * 440); // Ля   ( 440.00 Гц)
    localparam B4 = CLK_FREQ / (2 * 494); // Си   (~493.88 Гц)
    localparam C5 = CLK_FREQ / (2 * 523); // До 2 (~523.25 Гц)

    reg [19:0] note_half_period;
    reg        key_pressed;

    always @(*) begin
        case (1'b1)
            keys[0]: begin note_half_period = C4; key_pressed = 1'b1; end
            keys[1]: begin note_half_period = D4; key_pressed = 1'b1; end
            keys[2]: begin note_half_period = E4; key_pressed = 1'b1; end
            keys[3]: begin note_half_period = F4; key_pressed = 1'b1; end
            keys[4]: begin note_half_period = G4; key_pressed = 1'b1; end
            keys[5]: begin note_half_period = A4; key_pressed = 1'b1; end
            keys[6]: begin note_half_period = B4; key_pressed = 1'b1; end
            keys[7]: begin note_half_period = C5; key_pressed = 1'b1; end
            default: begin note_half_period = 20'd0; key_pressed = 1'b0; end
        endcase
    end

    // -------------------------------------------------------------
    // 3. Генератор прямоугольного сигнала (меандра)
    // -------------------------------------------------------------
    reg [19:0] counter;
    reg        audio_wave;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 20'd0;
            audio_wave <= 1'b0;
        end else if (key_pressed) begin
            if (counter >= note_half_period - 1'b1) begin
                counter    <= 20'd0;
                audio_wave <= ~audio_wave;
            end else begin
                counter    <= counter + 1'b1;
            end
        end else begin
            counter    <= 20'd0;
            audio_wave <= 1'b0;
        end
    end

    // -------------------------------------------------------------
    // 4. Выходы
    // -------------------------------------------------------------
    // uo_out[7] — стандартный пин для TT Audio Pmod
    assign uo_out[7]   = audio_wave; 
    assign uo_out[6]   = audio_wave; 
    assign uo_out[5:2] = 4'b0000;
    assign uo_out[1]   = key_pressed; // Индикатор: горит, если любая нота нажата
    assign uo_out[0]   = audio_wave;

endmodule
