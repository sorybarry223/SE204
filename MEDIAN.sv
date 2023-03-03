
module MEDIAN #(parameter width = 8)
  (input logic [width-1:0] DI,
  input logic DSI,
  input logic nRST,
  input logic CLK,
  output [width-1:0] DO,
  output logic DSO);

  logic BYP;
  logic DSI_S;
  logic [width-1:0] DI_S;



  MED #(.width(width))med0(.DI(DI_S),.DSI(DSI_S),.CLK(CLK),.BYP(BYP),.DO(DO));
  enum logic [3:0] {ATTENTE, CHARGEMENT, S1, S2, S3, S4, S5} state;
  logic [4:0] cpt;

  always @(posedge CLK or negedge nRST)begin
    if (!nRST) begin
      state <= ATTENTE;
      cpt <= 0;
      DSI_S<=0;
      DI_S<=0;
    end
    else begin
      DI_S<=DI;
      DSI_S<=DSI;
      case (state)

        ATTENTE: if (DSI) begin
          state <= CHARGEMENT;
        end

        CHARGEMENT: if (~DSI) begin
          state <= S1;
          cpt <= 0;
        end

        S1: begin
          if (cpt<8) begin
            cpt <= cpt+1;
          end
          if (cpt==8) begin
            cpt <= 0;
            state <= S2;
          end
        end

        S2: begin
          if (cpt <8)begin
            cpt <= cpt+1;
          end
          if (cpt==8) begin
            cpt <= 0;
            state <= S3;
          end
        end

        S3: begin
          if (cpt <8)begin
            cpt <= cpt+1;
          end
          if (cpt==8) begin
            cpt <= 0;
            state <= S4;
          end
        end

        S4: begin
          if (cpt <8)begin
            cpt <= cpt+1;
          end
          if (cpt==8) begin
            cpt <= 0;
            state <= S5;
          end
        end

        S5: begin
          if (cpt == 4)begin
            state <= ATTENTE;
          end
          else begin
            cpt <= cpt + 1;
          end
        end
      endcase
    end
  end

  always_comb begin
		DSO = 0 ;
		BYP = 0 ;
		case (state)
			CHARGEMENT :
				BYP = 1 ;
			S1 :
				if (cpt == 8)
					BYP = 1 ;
			S2 :
				if (cpt >= 7 )
					BYP = 1 ;
			S3 :
				if (cpt >= 6)
					BYP = 1 ;
			S4 :
				if (cpt >= 5)
					BYP = 1 ;
			S5 :
				if (cpt == 4)
					DSO = 1 ;

		endcase
	end



endmodule
