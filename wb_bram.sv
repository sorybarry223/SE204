//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre
// de mots de la mémoire : (2048 pour mem_adr_width=11)

module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );

logic [3:0][7:0] ram [0:2**mem_adr_width-1];
//on ignore les deux bits de poids faible pour se déplacer de 32 bits en 32 bits
wire [mem_adr_width-1:0] memory_slave = wb_s.adr[mem_adr_width+1:2];
logic [mem_adr_width-1:0] memory_slave_cpt;//permet de décaler la mémoire pendant les bursts
integer i;
//l'acquitement de la lecture a un cycle de retard il faut donc créer
//un signal ack_read
logic ack_read;



assign wb_s.ack = wb_s.stb && (wb_s.we || (!wb_s.we && ack_read));


//BLOCK READ
always_ff@(posedge wb_s.clk) begin
  ack_read<=0;
  if (wb_s.stb && !wb_s.we)begin
    ack_read<=1;
    // mode classique
    if (wb_s.cti == 0 || wb_s.cti ==7)begin 
      if(!ack_read) wb_s.dat_sm <= ram[memory_slave];
      else ack_read <= 0;
    end
    // mode constant address burst
    else if (wb_s.cti == 1)
      wb_s.dat_sm <= ram[memory_slave];
    // mode incremeting address burst
    else begin 
      // first step of the burst
      if(!ack_read) begin 
        wb_s.dat_sm <= ram[memory_slave];
        memory_slave_cpt <= memory_slave + 1;
      end
      // let's continue the burst
      else begin 
        wb_s.dat_sm <= ram[memory_slave_cpt];
        memory_slave_cpt <= memory_slave_cpt + 1;
      end
    end
  end
end

//BLOCK WRITE
always_ff@(posedge wb_s.clk)
begin
  if (wb_s.stb && wb_s.we)
    for (i = 0; i<4; i++)
      if(wb_s.sel[i])
        ram[memory_slave][i]<=wb_s.dat_ms[8*(i+1)-1 -: 8];
end

endmodule
