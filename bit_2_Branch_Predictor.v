module bit_2_predictor(clk,PC,effective_address);

input clk;                       //Clock signal
input [4:0] PC;                  //PC given as input to the predictor by the processor
input [4:0] effective_address;   //Caclculated effective address to check whether the predicted outcome is correct or not

reg [1:0] BHT [0:3];             //Branch History Table
reg [2:0] BTB_tag [0:3];         //Tags stored in Branch History Buffer
reg [4:0] BTB_addr [0:3];        //Target Address stored in Branch History Buffer

reg [1:0] index;                 //to index into the BTB and BHT--- some bits of PC provides the index
reg [2:0] tag;                   //Apart from the index, the rest of the bits of the PC is the tag
reg hit;                         //If tag matches with that of the BTB
reg [4:0] right;                 //Counter to count the no. of times the predictions made are correct

reg [4:0] predicted_next_PC;     //next PC predicted by the Branch predictor
//reg [4:0] actual_next_PC;


initial
begin
    BHT[0]=0; BHT[1]=0; BHT[2]=0; BHT[3]=0; right=0;  
    BTB_addr[0]=9; BTB_tag[0]=3'b011;               //initially some values are stored in the BTB
end

always@(posedge clk && PC)
begin
    index=PC[1:0];                          //get the index from the last 2 bits oF PC
    tag=PC[4:2];                            //get the tag from the rest of the bits of the PC

    if(tag==BTB_tag[index])                 //if tag is matched, the it's a BTB "hit"
    begin
      hit=1;
      if(BHT[index]==0)                                 //If the predictor is in the SNT state 
      begin
        predicted_next_PC=PC+4;                         //prediction--- branch won't be taken
        if(predicted_next_PC==effective_address)        //if prediction is correct
        begin
          BHT[index]<=0;                                //remain in SNT state
          right<=right+1;                               //it's a correct prediction
        end  
        else
          BHT[index]<=1;                                //if preiction is wrong, then go to the WNT state
      end  
      else if(BHT[index]==1)                            //If the predictor is in the WNT state
      begin 
        predicted_next_PC=PC+4;                         //prediction--- branch won't be taken
         if(predicted_next_PC==effective_address)       //if prediction is correct
         begin
          BHT[index]<=0;                                //go back to the SNT state
          right<=right+1;                                //it's a correct prediction
         end  
        else
          BHT[index]<=2;                                //if preiction is wrong, then go to the WT state
      end  
      else if(BHT[index]==2)                            //If the predictor is in the WT state 
      begin 
        predicted_next_PC=BTB_addr[index];              //prediction----branch will be taken
         if(predicted_next_PC==effective_address)       //if prediction is correct
         begin
          BHT[index]<=3;                                //go to ST state
          right<=right+1;                               //it's a correct prediction
         end  
        else
          BHT[index]<=1;                                //if preiction is wrong, then go to the WNT state
      end  
      else if(BHT[index]==3)                            //If the predictor is in the ST state 
      begin 
        predicted_next_PC=BTB_addr[index];              //prediction----branch will be taken
         if(predicted_next_PC==effective_address)       //if prediction is correct
         begin
          BHT[index]<=3;                                //remain in the ST state
          right<=right+1;                               //it's a correct prediction
         end 
        else
          BHT[index]<=2;                                //if preiction is wrong, then go to the WT state
      end  
    end  

    else
    begin
      hit=0;                                           //If the tag doesn't match with those present in the BTB
      predicted_next_PC=PC+4;                          //predicted target address = PC+4
      if(predicted_next_PC==effective_address)         //If actual address matches with that of the predicted address
         right<=right+1;
      else
      begin                                            //If actual address doesn't match with that of the predicted address
          BTB_tag[index]<=tag;                         //Store the tag from the current PC in the BTB
          BTB_addr[index]<=effective_address;          //Store the actual target address corresponding to the tag 
      end 
    end  
end

endmodule