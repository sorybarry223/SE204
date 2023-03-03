module wshb_intercon (
	wshb_if.slave wshb_ifs_vga,
	wshb_if.slave wshb_ifs_mire,
	wshb_if.master wshb_ifm_sdram
);

logic jeton; //vaut 1 si vga a la main et 0 si la mire a la main

//Master
assign wshb_ifm_sdram.cyc = jeton ? wshb_ifs_vga.cyc : wshb_ifs_mire.cyc;
assign wshb_ifm_sdram.stb = jeton ? wshb_ifs_vga.stb : wshb_ifs_mire.stb;
assign wshb_ifm_sdram.adr = jeton ? wshb_ifs_vga.adr : wshb_ifs_mire.adr;
assign wshb_ifm_sdram.we = jeton ? wshb_ifs_vga.we : wshb_ifs_mire.we;
assign wshb_ifm_sdram.dat_ms = jeton ? wshb_ifs_vga.dat_ms : wshb_ifs_mire.dat_ms;
assign wshb_ifm_sdram.sel = jeton ? wshb_ifs_vga.sel : wshb_ifs_mire.sel;
assign wshb_ifm_sdram.cti = jeton ? wshb_ifs_vga.cti : wshb_ifs_mire.cti;
assign wshb_ifm_sdram.bte = jeton ? wshb_ifs_vga.bte : wshb_ifs_mire.bte;

//vga slave
assign wshb_ifs_vga.ack = jeton ? wshb_ifm_sdram.ack : 0;
assign wshb_ifs_vga.dat_sm = jeton ? wshb_ifm_sdram.dat_sm : 0;
assign wshb_ifs_vga.rty = jeton ? wshb_ifm_sdram.rty : 0;
assign wshb_ifs_vga.err = jeton ? wshb_ifm_sdram.err : 0;

//mire slave
assign wshb_ifs_mire.ack = ~jeton ? wshb_ifm_sdram.ack : 0;
assign wshb_ifs_mire.dat_sm = ~jeton ? wshb_ifm_sdram.dat_sm : 0;
assign wshb_ifs_mire.rty = ~jeton ? wshb_ifm_sdram.rty : 0;
assign wshb_ifs_mire.err = ~jeton ? wshb_ifm_sdram.err : 0;



//mise à jour du jeton de façon synchrone
always @(posedge wshb_ifm_sdram.clk or posedge wshb_ifm_sdram.rst)begin
	if (wshb_ifm_sdram.rst) begin
		jeton = 0;
	end
	else begin
		if (jeton) begin
	  		if (~wshb_ifs_vga.cyc)
	  			jeton <= 0;
		end
		else begin
	  		if (~wshb_ifs_mire.cyc)
	  			jeton <= 1;
		end
	end
end
endmodule