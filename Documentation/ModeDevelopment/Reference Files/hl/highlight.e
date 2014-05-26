<'

extend TB_NAME_T : [ ETRC ];

extend fifo {
  keep soft testbench == ETRC;
};

extend ETRC fifo {

  keep direction == POP;
  keep soft type == CLASSIC;

  keep    PORT_DATAOUT          == appendf("esa_data[%d]"  , id);
  keep    PORT_POP_EMPTY        == appendf("fifo_empty[%d]", id);
  keep    PORT_POP_ALMOST_EMPTY == appendf("ESA_PopAE[%d]" , id);
  keep    PORT_POP_ALMOST_FULL  == appendf("ESA_PopAF[%d]"  , id);
  keep    PORT_POP_FULL         == "";
  keep    PORT_POP_ERROR        == "";
  keep    PORT_POP_REQ          == appendf("etrc_popreq_n[%d]"  , id); 
  keep    soft PORT_POP_CLK          == "sysclk";
  keep    soft PORT_PUSH_CLK         == "sysclk";
    
//  keep logger.verbosity == HIGH;  


  reset_sig() is {
    injector.reset_sig();
    '(PORT_DATAOUT)' = 0;
    '(PORT_POP_EMPTY)' = 0;
    '(PORT_POP_ALMOST_EMPTY)' = 0;
    '(PORT_POP_ALMOST_FULL)' = 0;
    '(PORT_POP_REQ)' = 0;
    '(PORT_POP_CLK)' = 0;
    '(PORT_POP_CLK)' = 1;    
  };

  event clkSys is rise('sysclk');
  event bug001 is true('pkdescnt[0]' == 1)@clkSys;

  on bug001
  {
    dut_error("Bug 001 found ... crash!");
  };

};



extend ETRC FIFO_INJECTOR {

  pkt_desc_if : pkt_desc_if is instance;
    keep pkt_desc_if.MAC_uid == id;

  add_new_pkt_desc() is also {
    pkt_desc_if.indicate_one_pck_desc_is_come_in_FIFO();
  };

  reset_sig() is {
    pkt_desc_if.reset_sig();
  };

};

extend ETRC CLASSIC fifo
{

  keep ae_seuil == 1;                          
  keep af_seuil == 46;                         
  keep fifo_size == 56;     


  
  setState() is also
  { 
    if (fifo_plot &&(sys.time > 200000)  && // avoid fifo plot before beginning of operation of RAMC
       !((injector.generated_packet_nb == injector.max_generated_packets && injector.stream.size() == 0)
       || injector.generated_packet_nb == 0))
    {
      if (fifo_use_logger) { 
        messagef(HIGH, "ETRC[%d] : %d\n", id,  fifo.size()); 
      }
      else {
        out("__fifo_plot: ", sys.time, "  ", fifo.size() ); 
      };
    };
  };
};

'>
