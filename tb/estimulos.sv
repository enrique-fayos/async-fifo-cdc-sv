`timescale 1ns/1ps

program automatic estimulos(fifo_if.TB vif);

// -------------------------
// Reset inicial
// -------------------------
task automatic aplicar_reset();
    begin
        // valores por defecto
        //Reset
        vif.wr_driver.wr_rst_n <= 0;
        vif.rd_driver.rd_rst_n <= 0;
        // deshabilitar escritura y lectura
        vif.wr_driver.wr_en <= 0;
        vif.rd_driver.rd_en <= 0;
        vif.wr_driver.din <= '0;
        // mantener ciclos
        repeat (4) @(vif.wr_driver);
        repeat (4) @(vif.rd_driver);
        // liberar reset
        vif.wr_driver.wr_rst_n <= 1;
        vif.rd_driver.rd_rst_n <= 1;
        $display("[%0t] RESET aplicado", $time);
    end
endtask

// -------------------------
// Escritura de una palabra
// -------------------------
task automatic escribir(input logic[7:0] data);
    begin
        @(vif.wr_driver);
        vif.wr_driver.din   <= data;
        vif.wr_driver.wr_en <= 1;
        @(vif.wr_driver);
        vif.wr_driver.din   <= '0;
        vif.wr_driver.wr_en <=  0;
        $display("[%0t] Escribir -> dato = 0x%02h", $time, data);
    end
endtask

// -------------------------
// Lectura de una palabra
// -------------------------
task automatic leer(output logic[7:0] data);
    begin
        data = '0;
        @(vif.rd_driver);
        vif.rd_driver.rd_en <= 1;
        @(vif.rd_driver);
        data = vif.rd_driver.dout;
        vif.rd_driver.rd_en <= 0;
        $display("[%0t] Leer -> dato = 0x%02h", $time, data);
    end
endtask

// -------------------------
// ZONA DE TESTEO PRINCIPAL
// -------------------------
initial begin : test_principal

    logic [7:0] dato_leido;
    $display("----------------------------");
    $display("| Iniciando test principal |");
    $display("----------------------------");

    aplicar_reset();
    
    // esperamos tras el reset
    repeat (2) @(vif.wr_driver);
    repeat (2) @(vif.rd_driver);

    // aplicamos estímulos simples
    escribir(8'hA5);
    repeat (5) @(vif.rd_driver);
    leer(dato_leido);

    escribir(8'h00);
    escribir(8'h01);
    escribir(8'h02);
    repeat (5) @(vif.rd_driver);
    leer(dato_leido);
    leer(dato_leido);

    repeat (10) @(vif.wr_driver);
    $display("-----------------------------");
    $display("| Finalizado test principal |");
    $display("-----------------------------");
    $finish;
end
endprogram