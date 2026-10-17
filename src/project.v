`default_nettype none

module tt_um_surchechil_synth (
    input  wire [7:0] ui_in,    // 8 кнопок клавиатуры
    output wire [7:0] uo_out,   // выходы звука и индикации
    input  wire [7:0] uio_in,   // не используются
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      // сигнал активности
    input  wire       clk,      // тактовый сигнал 10 МГц
    input  wire       rst_n     // сброс (0 = сброс, 1 = работа)
);

    // Отключаем неиспользуемые двунаправленные выводы
    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;
    wire _unused = &{ena, uio_in, 1'b0};

    // 1. Декодер нот: выбираем полупериод для ноты в зависимости от нажатой клавиши
    // Периоды для 10 МГц тактовой частоты (октава C4 - C5)
    reg [15:0] note_half_period;
    reg        key_pressed;

    always @(*) begin
        case (1'b1)
            ui_in[0]: begin note_half_period = 16'd19111; key_pressed = 1'b1; end // До (C4: 261.6 Гц)
            ui_in[1]: begin note_half_period = 16'd17026; key_pressed = 1'b1; end // Ре (D4: 293.7 Гц)
            ui_in[2]: begin note_half_period = 16'd15168; key_pressed = 1'b1; end // Ми (E4: 329.6 Гц)
            ui_in[3]: begin note_half_period = 16'd14317; key_pressed = 1'b1; end // Фа (F4: 349.2 Гц)
            ui_in[4]: begin note_half_period = 16'd12755; key_pressed = 1'b1; end // Соль (G4: 392.0 Гц)
            ui_in[5]: begin note_half_period = 16'd11364; key_pressed = 1'b1; end // Ля (A4: 440.0 Гц)
            ui_in[6]: begin note_half_period = 16'd10124; key_pressed = 1'b1; end // Си (B4: 493.9 Гц)
            ui_in[7]: begin note_half_period = 16'd9556;  key_pressed = 1'b1; end // До 2 (C5: 523.3 Гц)
            default:  begin note_half_period = 16'd0;     key_pressed = 1'b0; end // Кнопки отпущены
        endcase
    end

    // 2. Генератор звукового меандра (Square-wave generator)
    reg [15:0] counter;
    reg        audio_wave;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 16'd0;
            audio_wave <= 1'b0;
        end else if (key_pressed) begin
            if (counter >= note_half_period - 1) begin
                counter    <= 16'd0;
                audio_wave <= ~audio_wave; // инвертируем сигнал (создаём звуковую волну)
            end else begin
                counter    <= counter + 1'b1;
            end
        end else begin
            counter    <= 16'd0;
            audio_wave <= 1'b0;
        end
    end

    // Выходы:
    // uo_out[7] и uo_out[6] — стандартный стерео/моно выход для Tiny Tapeout Audio PMOD
    // uo_out[0] — дублирующий выход звука
    // uo_out[1] — индикатор нажатия кнопки
    assign uo_out[7]   = audio_wave;
    assign uo_out[6]   = audio_wave;
    assign uo_out[5:2] = 4'b0000;
    assign uo_out[1]   = key_pressed;
    assign uo_out[0]   = audio_wave;

endmodule
