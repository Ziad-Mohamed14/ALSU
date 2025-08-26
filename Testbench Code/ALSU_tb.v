module ALSU_tb();

    reg [2:0] A_tb, B_tb, opcode_tb;
    reg cin_tb, serial_in_tb, direction_tb;
    reg red_op_A_tb, red_op_B_tb;
    reg bypass_A_tb, bypass_B_tb;
    reg clk, rst;

    wire [5:0] out_dut;
    wire [15:0] leds_dut;

    ALSU dut (
        .A(A_tb), .B(B_tb), .opcode(opcode_tb),
        .cin(cin_tb), .serial_in(serial_in_tb),
        .direction(direction_tb), .red_op_A(red_op_A_tb), .red_op_B(red_op_B_tb),
        .bypass_A(bypass_A_tb), .bypass_B(bypass_B_tb),
        .clk(clk), .rst(rst),
        .out(out_dut), .leds(leds_dut)
    );

    // Generate clock
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    integer i;
    reg [5:0] expected_out;
    reg [15:0] expected_leds;

    initial begin
        // 2.1 Reset
        rst = 1;
        A_tb = 0; B_tb = 0; opcode_tb = 0; cin_tb = 0;
        serial_in_tb = 0; direction_tb = 0;
        red_op_A_tb = 0; red_op_B_tb = 0;
        bypass_A_tb = 0; bypass_B_tb = 0;
        @(negedge clk);
        expected_out = 0; expected_leds = 0;
        if (out_dut !== expected_out || leds_dut !== expected_leds)
            $display("Reset error: out=%b, leds=%b", out_dut, leds_dut);
        rst = 0;

        // 2.2 Bypass
        bypass_A_tb = 1; bypass_B_tb = 1; // Both bypass
        red_op_A_tb = 0; red_op_B_tb = 0;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random; opcode_tb = $urandom_range(0, 5);
            cin_tb = 0; serial_in_tb = 0; direction_tb = 0;
            @(negedge clk); @(negedge clk);
            // As per INPUT_PRIORITY default = "A" in your module:
            expected_out = {3'b000, A_tb};
            if (out_dut !== expected_out)
                $display("Bypass error at iter %0d: OUT=%b, expected=%b", i, out_dut, expected_out);
        end

        // 2.3 Opcode 0 AND/Reduce
        bypass_A_tb = 0; bypass_B_tb = 0; opcode_tb = 0;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random;
            red_op_A_tb = $random; red_op_B_tb = $random; // random each time
            cin_tb = 0; serial_in_tb = 0; direction_tb = 0;
            @(negedge clk); @(negedge clk);
            if (red_op_A_tb)
                expected_out = {5'b00000, &A_tb};
            else if (red_op_B_tb)
                expected_out = {5'b00000, &B_tb};
            else
                expected_out = {3'b000, A_tb & B_tb};
            if (out_dut !== expected_out)
                $display("Opcode0(AND/RED) error at %0d: OUT=%b, expected=%b", i, out_dut, expected_out);
        end

        // 2.4 Opcode 1 XOR/Reduce
        opcode_tb = 1;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random;
            red_op_A_tb = $random; red_op_B_tb = $random;
            cin_tb = 0; serial_in_tb = 0; direction_tb = 0;
            @(negedge clk); @(negedge clk);
            if (red_op_A_tb)
                expected_out = {5'b00000, ^A_tb};
            else if (red_op_B_tb)
                expected_out = {5'b00000, ^B_tb};
            else
                expected_out = {3'b000, A_tb ^ B_tb};
            if (out_dut !== expected_out)
                $display("Opcode1(XOR/RED) error at %0d: OUT=%b, expected=%b", i, out_dut, expected_out);
        end

        // 2.5 Opcode 2 ADD
        opcode_tb = 2; red_op_A_tb = 0; red_op_B_tb = 0;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random; cin_tb = $random;
            serial_in_tb = 0; direction_tb = 0;
            @(negedge clk); @(negedge clk);
            expected_out = {3'b000, A_tb + B_tb + cin_tb}; // because FULL_ADDER="ON" by default
            if (out_dut !== expected_out)
                $display("Opcode2(ADD) error at %0d: OUT=%b, expected=%b", i, out_dut, expected_out);
        end

        // 2.6 Opcode 3 MUL
        opcode_tb = 3;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random;
            cin_tb = 0; serial_in_tb = 0; direction_tb = 0;
            red_op_A_tb = 0; red_op_B_tb = 0;
            @(negedge clk); @(negedge clk);
            expected_out = A_tb * B_tb;
            if (out_dut !== expected_out)
                $display("Opcode3(MUL) error at %0d: OUT=%b, expected=%b", i, out_dut, expected_out);
        end

        // 2.7 Opcode 4 SHIFT
        opcode_tb = 4;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random; 
            direction_tb = $random; serial_in_tb = $random;
            cin_tb = 0; red_op_A_tb = 0; red_op_B_tb = 0;
            @(negedge clk); @(negedge clk);
        end

        // 2.8 Opcode 5 ROTATE
        opcode_tb = 5;
        for (i = 0; i < 100; i = i + 1) begin
            A_tb = $random; B_tb = $random;
            direction_tb = $random; serial_in_tb = $random;
            cin_tb = 0; red_op_A_tb = 0; red_op_B_tb = 0;
            @(negedge clk); @(negedge clk);
        end

        $display("Testbench completed.");
        $stop;
    end

    initial begin
    $monitor("A=%b | B=%b | opcode=%b | cin=%b | serial_in=%b | direction=%b | red_op_A=%b | red_op_B=%b | bypass_A=%b | bypass_B=%b | out=%b | leds=%b",
        A_tb, B_tb, opcode_tb, cin_tb, serial_in_tb, direction_tb,
        red_op_A_tb, red_op_B_tb, bypass_A_tb, bypass_B_tb, out_dut, leds_dut);
    end
endmodule
