module vga (
    input wire pixel_clk,
    input wire pixel_rst,
    video_if.master video_ifm,
	wshb_if.master wshb_ifm
);

parameter HDISP = 800;
parameter VDISP = 480;
localparam HFP = 40;
localparam HPULSE = 48;
localparam HBP = 40;
localparam VFP = 13;
localparam VPULSE = 3;
localparam VBP = 29;

assign video_ifm.CLK = pixel_clk;



logic [$clog2(HFP+HPULSE+HBP+HDISP)-1:0] pixel_cpt;
logic [$clog2(VFP+VPULSE+VBP+VDISP)-1:0] line_cpt;
logic read, write, wfull;
logic [31:0] rdata;
logic wfull_first_time;
logic walmost_full;

async_fifo #(.DATA_WIDTH(32),.ALMOST_FULL_THRESHOLD(224)) async_fifo_inst( .rst(wshb_ifm.rst), .rclk(pixel_clk),
                                                  .read(read), .wclk(wshb_ifm.clk),
                                                  .wdata(wshb_ifm.dat_sm), .write(write),
                                                  .wfull(wfull), .rdata(rdata),
												  .walmost_full(walmost_full));

assign wshb_ifm.stb = ~wfull;
assign wshb_ifm.we = 1'b0;
assign wshb_ifm.cti = 3'b0;
assign wshb_ifm.bte = 2'b0;

assign write = wshb_ifm.ack && ~wfull;

//=======================================================
//  Lecture de la RAM  -  Envoi sur la FIFO
//=======================================================

//S'assure que la fifo n'est pas pleine
always_ff@(posedge wshb_ifm.clk)begin
	if (wfull)
		wshb_ifm.cyc <= 0;
	if (~walmost_full)
		wshb_ifm.cyc <= 1;
end

always_ff@(posedge wshb_ifm.clk or posedge wshb_ifm.rst)begin
	if (wshb_ifm.rst)
		wshb_ifm.adr = 32'b0;
	else begin 
		if (wshb_ifm.ack && ~wfull)
			if (wshb_ifm.adr == 4*HDISP*VDISP-4)
				wshb_ifm.adr <= 32'b0;
			else wshb_ifm.adr <= wshb_ifm.adr + 4;
	end
end

//==========================================================
// Lecture de la FIFO  -  Envoi vers le module vidéo
//==========================================================

logic bascule2;
logic wfull_sync;

always_ff@(posedge pixel_clk or posedge pixel_rst)
    if (pixel_rst)begin
        bascule2 <= 0;
        wfull_sync <= 0;
    end
    else begin
        bascule2 <= wfull;
        wfull_sync <= bascule2;
    end

always_ff@(posedge pixel_clk or posedge pixel_rst)begin
	if (pixel_rst)
		wfull_first_time <= 0;
	else begin
		if (wfull_sync)
			wfull_first_time <= 1;
		else
			wfull_first_time <= wfull_first_time;
	end
end




//Calcul des valeurs des compteurs
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  line_cpt <= 0;
  pixel_cpt <= 0;
end
else
begin
  if (pixel_cpt == HFP+HPULSE+HBP + HDISP - 1)
  begin
    pixel_cpt <= 0;

    if (line_cpt == VFP+VPULSE+VBP + VDISP - 1)
      line_cpt <= 0;
    else
      line_cpt <= line_cpt + 1;

  end
  else
    pixel_cpt <= pixel_cpt + 1;

end


assign video_ifm.RGB = rdata[23:0];
assign read = video_ifm.BLANK;

//Utilisation des compteurs pour la synchronisation
always_ff @(posedge pixel_clk or posedge pixel_rst) begin
	if(pixel_rst) begin
		video_ifm.BLANK <= 0;
  		video_ifm.VS <= 1;
  		video_ifm.HS <= 1;
	end
	else begin 
		//Mise à jour de HS et VS
		if (pixel_cpt<HFP || pixel_cpt >= HFP+HPULSE)
			video_ifm.HS <= 1;
		if (pixel_cpt>=HFP && pixel_cpt < HFP + HPULSE)
			video_ifm.HS <= 0;
		if (line_cpt<VFP || line_cpt >= VFP+VPULSE)
			video_ifm.VS <= 1;
		if (line_cpt >= VFP && line_cpt < VFP+VPULSE)
			video_ifm.VS <= 0;

		// Mise à jour de BLANK
		video_ifm.BLANK <= line_cpt >= VFP+VPULSE+VBP && pixel_cpt >= HFP+HPULSE+HBP;
	end 
end

endmodule 
