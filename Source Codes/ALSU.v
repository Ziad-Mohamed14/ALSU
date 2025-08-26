module ALSU #(
    parameter INPUT_PRIORITY = "A",  // "A" or "B"
    parameter FULL_ADDER = "ON"      // "ON" or "OFF"
)(
    input [2:0] A, B, opcode,
    input cin, serial_in, direction,
    input red_op_A, red_op_B,
    input bypass_A, bypass_B,
    input clk, rst,
    output reg [5:0] out,
    output reg [15:0] leds
);

    // Registers for input sampling
    reg [2:0] A_reg, B_reg, opcode_reg;
    reg cin_reg, serial_in_reg, direction_reg;
    reg red_op_A_reg, red_op_B_reg, bypass_A_reg, bypass_B_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A_reg <= 3'b0;
            B_reg <= 3'b0;
            opcode_reg <= 3'b0;
            cin_reg <= 1'b0;
            serial_in_reg <= 1'b0;
            direction_reg <= 1'b0;
            red_op_A_reg <= 1'b0;
            red_op_B_reg <= 1'b0;
            bypass_A_reg <= 1'b0;
            bypass_B_reg <= 1'b0;
            out <= 6'b0;
            leds <= 16'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            opcode_reg <= opcode;
            cin_reg <= cin;
            serial_in_reg <= serial_in;
            direction_reg <= direction;
            red_op_A_reg <= red_op_A;
            red_op_B_reg <= red_op_B;
            bypass_A_reg <= bypass_A;
            bypass_B_reg <= bypass_B;

            // Default to no blinking LEDs unless invalid
            leds <= 16'b0;

            // Invalid condition check (OPCODE = 110 OR OPCODE 111)
            if (
                (opcode_reg == 3'b110 || opcode_reg == 3'b111) ||
                ((red_op_A_reg || red_op_B_reg) && !(opcode_reg == 3'b000 || opcode_reg == 3'b001))
            ) begin
                leds <= 16'hFFFF; // Blink warning
                if (bypass_A_reg && bypass_B_reg) begin
                    out <= (INPUT_PRIORITY == "A") ? {3'b000, A_reg} : {3'b000, B_reg};
                end else if (bypass_A_reg) begin
                    out <= {3'b000, A_reg};
                end else if (bypass_B_reg) begin
                    out <= {3'b000, B_reg};
                end else begin
                    out <= 6'b0;
                end
            end

            // Handle valid cases
            else if (bypass_A_reg) begin
                out <= {3'b000, A_reg};
            end else if (bypass_B_reg) begin
                out <= {3'b000, B_reg};
            end else begin
                case (opcode_reg)
                    3'b000: begin // AND
                        if (red_op_A_reg)
                            out <= {5'b00000, &A_reg};
                        else if (red_op_B_reg)
                            out <= {5'b00000, &B_reg};
                        else
                            out <= {3'b000, A_reg & B_reg};
                    end

                    3'b001: begin // XOR
                        if (red_op_A_reg)
                            out <= {5'b00000, ^A_reg};
                        else if (red_op_B_reg)
                            out <= {5'b00000, ^B_reg};
                        else
                            out <= {3'b000, A_reg ^ B_reg};
                    end

                    3'b010: begin // ADD
                        if (FULL_ADDER == "ON")
                            out <= {3'b000, A_reg + B_reg + cin_reg};
                        else
                            out <= {3'b000, A_reg + B_reg};
                    end

                    3'b011: begin // MULTIPLICATION
                        out <= A_reg * B_reg;
                    end

                    3'b100: begin // SHIFT
                        if (direction_reg) // LEFT
                            out <= {A_reg, serial_in_reg};
                        else // RIGHT
                            out <= {serial_in_reg, A_reg};
                    end

                    3'b101: begin // ROTATE
                        if (direction_reg) // LEFT
                            out <= {A_reg[1:0], A_reg[2], 2'b00};
                        else // RIGHT
                            out <= {2'b00, A_reg[0], A_reg[2:1]};
                    end

                    default: begin
                        out <= 6'b0;
                    end
                endcase
            end
        end
    end
endmodule
