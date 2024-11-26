

module TOP_interconnect();
    parameter num_slaves = 3;
    parameter num_masters = 3;
    parameter buswidth = 32;

    wire [num_slaves-1:0] crossbar [num_masters-1:0];
    //Write address channel signals master side
    wire [3:0] MAWID [num_masters-1:0];
    wire [31:0] MAWADDR [num_masters-1:0];
    wire [3:0] MAWLEN [num_masters-1:0];
    wire [2:0] MAWSIZE [num_masters-1:0];
    wire [1:0] MAWBURST [num_masters-1:0];
    wire [1:0] MAWLOCK [num_masters-1:0];
    wire [3:0] MAWCACHE [num_masters-1:0];
    wire [2:0] MAWPROT [num_masters-1:0];
    wire MAWVALID [num_masters-1:0];
    wire MAWREADY [num_masters-1:0];
    //Write address channel signals slave side
    wire [3:0] SAWID [num_masters-1:0];
    wire [31:0] SAWADDR [num_masters-1:0];
    wire [3:0] SAWLEN [num_masters-1:0];
    wire [2:0] SAWSIZE [num_masters-1:0];
    wire [1:0] SAWBURST [num_masters-1:0];
    wire [1:0] SAWLOCK [num_masters-1:0];
    wire [3:0] SAWCACHE [num_masters-1:0];
    wire [2:0] SAWPROT [num_masters-1:0];
    wire SAWVALID [num_masters-1:0];
    wire SAWREADY [num_masters-1:0];
    //Write data channel signals master side
    wire [3:0] MWID [num_masters-1:0];
    wire [buswidth-1:0] MWDATA [num_masters-1:0];
    wire [3:0] MWSTRB [num_masters-1:0];
    wire MWLAST [num_masters-1:0];
    wire MWVALID [num_masters-1:0];
    wire MWREADY [num_masters-1:0];
    //Write data channel signals slave side
    wire [3:0] SWID [num_masters-1:0];
    wire [buswidth-1:0] SWDATA [num_masters-1:0];
    wire [3:0] SWSTRB [num_masters-1:0];
    wire SWLAST [num_masters-1:0];
    wire SWVALID [num_masters-1:0];
    wire SWREADY [num_masters-1:0];
    //Write response channel signals master side
    wire [3:0] MBID [num_masters-1:0];
    wire [1:0] MBRESP [num_masters-1:0];
    wire MBVALID [num_masters-1:0];
    wire MBREADY [num_masters-1:0];
    //Write response channel signals slave side
    wire [3:0] SBID [num_masters-1:0];
    wire [1:0] SBRESP [num_masters-1:0];
    wire SBVALID [num_masters-1:0];
    wire SBREADY [num_masters-1:0];
    //Read address channel signals master side
    wire [3:0] MARID [num_masters-1:0];
    wire [31:0] MARADDR [num_masters-1:0];
    wire [3:0] MARLEN [num_masters-1:0];
    wire [2:0] MARSIZE [num_masters-1:0];
    wire [1:0] MARBURST [num_masters-1:0];
    wire [1:0] MARLOCK [num_masters-1:0];
    wire [3:0] MARCACHE [num_masters-1:0];
    wire [2:0] MARPROT [num_masters-1:0];
    wire MARVALID [num_masters-1:0];
    wire MARREADY [num_masters-1:0];
    //Read address channel signals slave side
    wire [3:0] SARID [num_masters-1:0];
    wire [31:0] SARADDR [num_masters-1:0];
    wire [3:0] SARLEN [num_masters-1:0];
    wire [2:0] SARSIZE [num_masters-1:0];
    wire [1:0] SARBURST [num_masters-1:0];
    wire [1:0] SARLOCK [num_masters-1:0];
    wire [3:0] SARCACHE [num_masters-1:0];
    wire [2:0] SARPROT [num_masters-1:0];
    wire SARVALID [num_masters-1:0];
    wire SARREADY [num_masters-1:0];
    //Write data channel signals master side
    wire [3:0] MRID [num_masters-1:0];
    wire [buswidth-1:0] MRDATA [num_masters-1:0];
    wire [3:0] MRRESP [num_masters-1:0];
    wire MRLAST [num_masters-1:0];
    wire MRVALID [num_masters-1:0];
    wire MRREADY [num_masters-1:0];
    //Write data channel signals slave side
    wire [3:0] SRID [num_masters-1:0];
    wire [buswidth-1:0] SRDATA [num_masters-1:0];
    wire [3:0] SRRESP [num_masters-1:0];
    wire SRLAST [num_masters-1:0];
    wire SRVALID [num_masters-1:0];
    wire SRREADY [num_masters-1:0];

    genvar k;
    genvar i;
    genvar j;
    generate
        for(i = 0; i<=num_slaves; i = i + 1)
        begin
            for(j = 0; j<=num_masters; j = j + 1)
            begin
                for(k = 0; k<=buswidth; k = k + 1)
                begin
                    nmos(SWDATA[i][k],MWDATA[j][k],crossbar[i][j]);
                    nmos(SRDATA[i][k],MRDATA[j][k],crossbar[i][j]);
                end
                for(k = 0; k<=31; k = k + 1)
                begin
                    nmos(SAWADDR[i][k],MAWADDR[j][k],crossbar[i][j]);
                    nmos(SARADDR[i][k],MARADDR[j][k],crossbar[i][j]);
                end
                for(k = 0; k<=3; k = k + 1)
                begin
                    nmos(SBID[i][k],MBID[j][k],crossbar[i][j]);
                    nmos(SWSTRB[i][k],MWSTRB[j][k],crossbar[i][j]);
                    nmos(SWID[i][k],MWID[j][k],crossbar[i][j]);
                    nmos(SRID[i][k],MRID[j][k],crossbar[i][j]);
                    nmos(SAWID[i][k],MAWID[j][k],crossbar[i][j]);
                    nmos(SARID[i][k],MARID[j][k],crossbar[i][j]);
                    nmos(SAWLEN[i][k],MAWLEN[j][k],crossbar[i][j]);
                    nmos(SARLEN[i][k],MARLEN[j][k],crossbar[i][j]);
                    nmos(SAWCACHE[i][k],MAWCACHE[j][k],crossbar[i][j]);
                    nmos(SARCACHE[i][k],MARCACHE[j][k],crossbar[i][j]);
                end
                for(k = 0; k<=2; k = k + 1)
                begin
                    nmos(SAWSIZE[i][k],MAWSIZE[j][k],crossbar[i][j]);
                    nmos(SAWPROT[i][k],MAWPROT[j][k],crossbar[i][j]);
                    nmos(SARSIZE[i][k],MARSIZE[j][k],crossbar[i][j]);
                    nmos(SARPROT[i][k],MARPROT[j][k],crossbar[i][j]);
                end
                for(k = 0; k<=1; k = k + 1)
                begin
                    nmos(SAWLOCK[i][k],MAWLOCK[j][k],crossbar[i][j]);
                    nmos(SARLOCK[i][k],MARLOCK[j][k],crossbar[i][j]);
                    nmos(SBRESP[i][k],MBRESP[j][k],crossbar[i][j]);
                    nmos(SRRESP[i][k],MRRESP[j][k],crossbar[i][j]);
                end
                for(k = 0; k<=0; k = k + 1)
                begin
                    nmos(SAWVALID[i][k],MAWVALID[j][k],crossbar[i][j]);
                    nmos(SAWREADY[i][k],MAWREADY[j][k],crossbar[i][j]);
                    nmos(SARVALID[i][k],MARVALID[j][k],crossbar[i][j]);
                    nmos(SARREADY[i][k],MARREADY[j][k],crossbar[i][j]);
                    nmos(SWLAST[i][k],MWLAST[j][k],crossbar[i][j]);
                    nmos(SWVALID[i][k],MWVALID[j][k],crossbar[i][j]);
                    nmos(SWREADY[i][k],MWREADY[j][k],crossbar[i][j]);
                    nmos(SRLAST[i][k],MRLAST[j][k],crossbar[i][j]);
                    nmos(SRVALID[i][k],MRVALID[j][k],crossbar[i][j]);
                    nmos(SRREADY[i][k],MRREADY[j][k],crossbar[i][j]);
                    nmos(SBVALID[i][k],MBVALID[j][k],crossbar[i][j]);
                    nmos(SBREADY[i][k],MBREADY[j][k],crossbar[i][j]);
                end
            end    
        end
    endgenerate
endmodule