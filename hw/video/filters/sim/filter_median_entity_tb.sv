//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//-----------------------------------------------------------------------

`timescale 1ns / 1ps

module filter_median_entity_tb #(
    parameter KERNEL_SIZE = 49,
    parameter DWIDTH = 8
);


//***********************************
//System clock gen
//***********************************
reg sys_rst = 1'b0;
reg sys_clk = 1'b1;

always #5 sys_clk = ~sys_clk;
task tick;
    begin : blk_clkgen
        @(posedge sys_clk);#0;
    end : blk_clkgen
endtask : tick


logic [DWIDTH-1:0] xi [(KERNEL_SIZE)-1:0];
logic [DWIDTH-1:0] xo [(KERNEL_SIZE)-1:0];
logic [(DWIDTH*KERNEL_SIZE)-1:0] xinput;
logic [(DWIDTH*KERNEL_SIZE)-1:0] xoutput;
integer i,x,a,trn_cnt;
integer nval, nval_set;
integer set_err1;


initial begin : sim_main

    set_err1 = 0;
    nval_set = 0;
    //set new random value
    for (i=0; i<KERNEL_SIZE; i++) begin
        xi[i] = $urandom;
    end
    //check all value of xi array. if exist equal values than change one of them
    for (i=0; i<KERNEL_SIZE; i++) begin
        nval_set = 0;
        for (x=0; x<=i; x++) begin
            for (a=x; a<(i); a++) begin
                // $display("i[%02d]; x[%02d]; a[%02d]: xi[%02d] xi[%02d]", i, x, a, x, a+1);
                if (xi[x] == xi[a+1]) begin
                    nval = $urandom;
                    while (xi[x] == nval) begin
                        nval = $urandom;
                    end
                    // $display("\txi[%02d]=%03d == xi[%02d]=%03d : nval xi[%02d]=%03d", x, xi[x], a+1, xi[a+1], x, nval[7:0]);
                    xi[x] = nval;
                end
            end
            if (nval_set) break;
        end
    end

    sys_rst = 1'b0;
    #500
    sys_rst = 1'b1;
    #500
    sys_rst = 1'b0;

    for (trn_cnt=0; trn_cnt<4096; trn_cnt++) begin
        @(posedge sys_clk)
        //set new random value
        for (i=0; i<KERNEL_SIZE; i++) begin
            xi[i] = $urandom;
        end
        //check all value of xi array. if exist equal values than change one of them
        for (i=0; i<KERNEL_SIZE; i++) begin
            nval_set = 0;
            for (x=0; x<=i; x++) begin
                for (a=x; a<(i); a++) begin
                    // $display("i[%02d]; x[%02d]; a[%02d]: xi[%02d] xi[%02d]", i, x, a, x, a+1);
                    if (xi[x] == xi[a+1]) begin
                        nval = $urandom;
                        while (xi[x] == nval[DWIDTH-1:0]) begin
                            nval = $urandom;
                        end
                        // $display("\txi[%02d]=%03d == xi[%02d]=%03d : nval xi[%02d]=%03d", x, xi[x], a+1, xi[a+1], x, nval[7:0]);
                        xi[x] = nval;
                    end
                end
                if (nval_set) break;
            end
        end
        //check all value of xi array. if exist equal values than change one of them
        for (i=0; i<KERNEL_SIZE; i++) begin
            nval_set = 0;
            for (x=0; x<=i; x++) begin
                for (a=x; a<(i); a++) begin
                    // $display("i[%02d]; x[%02d]; a[%02d]: xi[%02d] xi[%02d]", i, x, a, x, a+1);
                    if (xi[x] == xi[a+1]) begin
                        nval = $urandom;
                        while (xi[x] == nval[DWIDTH-1:0]) begin
                            nval = $urandom;
                        end
                        // $display("\txi[%02d]=%03d == xi[%02d]=%03d : nval xi[%02d]=%03d", x, xi[x], a+1, xi[a+1], x, nval[7:0]);
                        xi[x] = nval;
                    end
                end
                if (nval_set) break;
            end
        end
        #2000;

        @(posedge sys_clk)
        for (i=0; i<KERNEL_SIZE-1; i++) begin
            if (xo[i] > xo[i+1]) begin
                $display("error: xo[%02d]=%03d > xo[%02d]=%03d", i, xo[i], (i+1), xo[(i+1)]);
                set_err1 = 1;
                break;
            end
        end
        if (!set_err1) begin
            for (i=0; i<KERNEL_SIZE; i++) begin
                for (x=0; x<i; x++) begin
                    for (a=x; a<=i; a++) begin
                        if (xo[a+1] == xo[x]) begin
                            $display("error: xo[%02d]=%03d == xo[%02d]=%03d", a+1, xo[a+1], x, xo[x]);
                            $display("Simulation time complete.");
                            $stop;
                            set_err1 = 1;
                            break;
                        end
                    end
                    if (set_err1) break;
                end
                if (set_err1) break;
            end
        end
        if (set_err1) begin
            $display("Simulation time complete.");
            $stop;
        end else begin
            $display("trn[%04d] - checked", trn_cnt);
        end
    end

end : sim_main

genvar k;
generate
    for (k=0; k<KERNEL_SIZE; k=k+1) begin
        assign xinput[k*8 +: DWIDTH] = xi[k];
        assign xo[k] = xoutput[k*8 +: DWIDTH];
    end
endgenerate

// filter_median_5x5_entity #(
//     .KERNEL_SIZE(KERNEL_SIZE), //KERNEL_SIZE have to be 25!!!!
//     .PIXEL_WIDTH(DWIDTH)
// ) main (
//     .xi(xinput),
//     .xo(xoutput),
//     .rst(sys_rst),
//     .clk(sys_clk)
// );

filter_median_7x7_entity #(
    .KERNEL_SIZE(KERNEL_SIZE), //KERNEL_SIZE have to be 49!!!!
    .PIXEL_WIDTH(DWIDTH)
) main (
    .xi(xinput),
    .xo(xoutput),
    .rst(sys_rst),
    .clk(sys_clk)
);

endmodule : filter_median_entity_tb

