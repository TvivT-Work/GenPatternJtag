#!/usr/bin/perl -w
# use strict;
 
use utf8;
use POSIX;
use Switch;

#============================= CMD HASH ==================================
 
$cmd_hash{'wait'}                    = "6'h00" ;
$cmd_hash{'jtag_test_req'}           = "6'h30" ;
$cmd_hash{'jtag_idcode'}             = "6'h31" ;
$cmd_hash{'jtag_read_expect'}        = "6'h08" ;
$cmd_hash{'jtag_write_single'}       = "6'h09" ;
$cmd_hash{'jtag_trans_single'}       = "6'h19" ;
$cmd_hash{'jtag_flash_read'}         = "6'h06" ;
$cmd_hash{'jtag_flash_write'}        = "6'h07" ;
$cmd_hash{'jtag_flash_erase_all'}    = "6'h01" ;
$cmd_hash{'jtag_flash_chip_erase'}   = "6'h03" ;
$cmd_hash{'jtag_flash_block_erase'}  = "6'h04" ;
$cmd_hash{'jtag_flash_sector_erase'} = "6'h05" ;
$cmd_hash{'jtag_flash_trans'}        = "6'h17" ;

#---------------------------------------------------------------------------------------------------------------
#======================= Extract Define File =============================
open (fh_def,"<",$ARGV[0]);

@lines_def=<fh_def>;

foreach my $current_line(@lines_def){

  # Replace Space
  $current_line =~ s/\s//g;

  # Replace Comment 
  $current_line =~ s/\/\/[\s\S]*//g;

  # Skip empty lines
  if ($current_line =~ /^\s*$/) {
    next;
  }

  @line_def = split(/,/,$current_line);

  $def_name = $line_def[0] ;
  $def_val  = $line_def[1] ;

  $def_hash{$def_name} = $def_val ;

}

close fh_def ;


#======================= Trans JTAG Command File =============================
$script_line = "FORMAT  w tck tms tdi tdo \n" ;

open (fh_cmd,"<",$ARGV[1]);

@lines_cmd=<fh_cmd>;

foreach my $current_line(@lines_cmd){

  # Replace Space
  $current_line =~ s/\s//g;

  # Replace Comment 
  $current_line =~ s/\/\/[\s\S]*//g;

  # Skip empty lines
  if ($current_line =~ /^\s*$/) {
    next;
  }

  $current_line =~ /\((.*)\)/;
  $cmd_name_str = $`;

  $cmd_argv_str = $&;
  $cmd_argv_str =~ s/[\(\)]//g; # Replace "(",")" 

  # print"cmd_name : $cmd_name_str \n";
  # print"cmd_argv : $cmd_argv_str \n";

  @cmd_argvs = split(/,/,$cmd_argv_str);

  switch($cmd_name_str) {
    case "wait"                    { wait_line($cmd_argvs[0]                        )      ; }
    case "jtag_test_req"           { jtag_test_req(                                 )      ; }
    case "jtag_idcode"             { jtag_idcode(                                   )      ; }
    case "jtag_read_expect"        { jtag_read_expect($cmd_argvs[0], $cmd_argvs[1]  )      ; }
    case "jtag_write_single"       { jtag_write_single($cmd_argvs[0], $cmd_argvs[1] )      ; }
    case "jtag_trans_single"       { jtag_trans_single($cmd_argvs[0], $cmd_argvs[1] )      ; }
    case "jtag_flash_read"         { jtag_flash_read($cmd_argvs[0]                  )      ; }
    case "jtag_flash_write"        { jtag_flash_write($cmd_argvs[0], $cmd_argvs[1]  )      ; }
    case "jtag_flash_erase_all"    { jtag_flash_erase_all(                          )      ; }
    case "jtag_flash_chip_erase"   { jtag_flash_chip_erase(                         )      ; }
    case "jtag_flash_block_erase"  { jtag_flash_block_erase($cmd_argvs[0]           )      ; }
    case "jtag_flash_sector_erase" { jtag_flash_sector_erase($cmd_argvs[0]          )      ; }
    case "jtag_flash_trans"        { jtag_flash_trans($cmd_argvs[0], $cmd_argvs[1]  )      ; }
    else                           { $script_line .= "\n[ERROR] NO SUCH COMMAND : $cmd_name_str !!!\n" ; }
  }

}
close fh_cmd ;

# print $script_line;

#========================== Output JTAG WaveTXT =================================
open (write_file, ">", "jtag_io_wave.txt");
print write_file $script_line;
close write_file;
 
#---------------------------------------------------------------------------------------------------------------
#========================== HEX/DEC 2 BIN =================================
# hex/dec 2 bin
sub base2bin {                
  # $argv_num = scalar(@_) ;

  $base_str = $_[0]      ;
  $base_len = $_[1]      ;
  $base_str =~ s/\_//g   ;

  if($base_str =~/'h/ ) {
    $base_str =~ m/'h/;
    $base_len = $`;
    $base_val = $';

    $base_hex = $base_val                                   ;
    $base_dec = hex($base_hex)                              ;
    $base_bin = sprintf("%0b", $base_dec)                   ;
    $base_bin = "0"x($base_len-length($base_bin)).$base_bin ;
  }
  elsif($base_str =~/'d/ ) {
    $base_str =~ m/'d/;
    $base_len = $`;
    $base_val = $';

    $base_dec = $base_val                                   ;
    $base_hex = sprintf("%0x", $base_dec)                   ;
    $base_bin = sprintf("%0b", $base_dec)                   ;
    $base_bin = "0"x($base_len-length($base_bin)).$base_bin ;
  }
  elsif($base_str =~/'b/ ) {
    $base_str =~ m/'d/;
    $base_len = $`;
    $base_val = $';

    $base_bin = $base_val                                   ;
    $base_bin = "0"x($base_len-length($base_bin)).$base_bin ;
    $base_dec = oct("0b".$base_bin)                         ;
    $base_hex = sprintf("%0x", $base_dec)                   ;
  }
  else{
    $base_hex = $base_str                                   ;
    $base_dec = hex($base_hex)                              ;
    $base_bin = sprintf("%0b", $base_dec)                   ;
    $base_bin = "0"x($base_len-length($base_bin)).$base_bin ;
  }

  return $base_bin ;

}  

sub laddr2faddr {                

  $logic_addr = $_[0]      ;

  $logic_addr_bin  = base2bin($logic_addr, 32)       ;
  $faddr_bin       = "21'b"                          ;
  $faddr_bin      .= substr($logic_addr_bin, 2 , 1 ) ;
  $faddr_bin      .= substr($logic_addr_bin, 12, 20) ;

  return $faddr_bin ;

}  



#========================= JTAG_SUBFUNCTION ===============================
sub wait_line {                
  $wait_num   = $_[0] ;

  $script_line .= "R"                         ;
  $script_line .= "$wait_num"                 ;
  $script_line .= " " x (7-length($wait_num)) ;
  $script_line .= "w  0   0   0   0   ;"      ;
  $script_line .= " // Wait\n"                ;

}

sub jtag_bit_send {                

  $jtag_tms = $_[0]                             ;
  $jtag_tdi = $_[1]                             ;
  $exp_tdo  = $_[2] ? ($_[3] ? "H" : "L") : "X" ;

  $script_line .= "R1      w  "  ;
  $script_line .= "0   "         ;
  $script_line .= "$jtag_tms   " ;
  $script_line .= "$jtag_tdi   " ;
  $script_line .= "X   "         ;
  $script_line .= ";\n"          ;

  $script_line .= "R1      w  "  ;
  $script_line .= "1   "         ;
  $script_line .= "$jtag_tms   " ;
  $script_line .= "$jtag_tdi   " ;
  $script_line .= "$exp_tdo   "  ;
  $script_line .= ";\n"          ;

}

sub jtag_bit_send_comment {                

  $jtag_tms = $_[0]                             ;
  $jtag_tdi = $_[1]                             ;
  $exp_tdo  = $_[2] ? ($_[3] ? "H" : "L") : "X" ;
  $comment  = $_[4]                             ;

  $script_line .= "R1      w  "  ;
  $script_line .= "0   "         ;
  $script_line .= "$jtag_tms   " ;
  $script_line .= "$jtag_tdi   " ;
  $script_line .= "X   "         ;
  $script_line .= ";"            ;
  $script_line .= " $comment"    ;
  $script_line .= "\n"           ;

  $script_line .= "R1      w  "  ;
  $script_line .= "1   "         ;
  $script_line .= "$jtag_tms   " ;
  $script_line .= "$jtag_tdi   " ;
  $script_line .= "$exp_tdo   "  ;
  $script_line .= ";"            ;
  $script_line .= "\n"           ;

}


sub jtag_ir_send {                

  $cmd_ir_str = $_[0];
  $cmd_ir     = base2bin($cmd_hash{$cmd_ir_str}, 6);

  jtag_bit_send( 0, 0, 0, 0 );  # Current:Test-Logic-Reset ; Next: Run-Test/Idle
  jtag_bit_send( 0, 0, 0, 0 );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle
  jtag_bit_send( 0, 0, 0, 0 );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle
  jtag_bit_send( 0, 0, 0, 0 );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle
  jtag_bit_send( 0, 0, 0, 0 );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle

  jtag_bit_send_comment( 0, 0, 0, 0, "// JTAG_CMD: $cmd_name_str          " );  
  jtag_bit_send_comment( 0, 0, 0, 0, "// Run-Test-Idle  --> Run-Test-Idle " );  # Current:Run-Test/Idle    ; Next: Select-DR-Scan
  jtag_bit_send_comment( 1, 0, 0, 0, "// Run-Test-Idle  --> Select-DR-Scan" );  # Current:Run-Test/Idle    ; Next: Select-DR-Scan
  jtag_bit_send_comment( 1, 0, 0, 0, "// Select-DR-Scan --> Select-IR-Scan" );  # Current:Select-DR-Scan   ; Next: Select-IR-Scan
  jtag_bit_send_comment( 0, 0, 0, 0, "// Select-IR-Scan --> Capture-IR    " );  # Current:Select-IR-Scan   ; Next: Capture-IR
  jtag_bit_send_comment( 0, 0, 0, 0, "// Capture-IR     --> Shift-IR      " );  # Current:Capture-IR       ; Next: Shift-IR

  jtag_bit_send_comment( 0, substr($cmd_ir, -1, 1), 0, 0, "// IR[0]      " );  # Current:Shift-IR         ; Next: Shift-IR
  jtag_bit_send_comment( 0, substr($cmd_ir, -2, 1), 0, 0, "// IR[1]      " );  # Current:Shift-IR         ; Next: Shift-IR
  jtag_bit_send_comment( 0, substr($cmd_ir, -3, 1), 0, 0, "// IR[2]      " );  # Current:Shift-IR         ; Next: Shift-IR
  jtag_bit_send_comment( 0, substr($cmd_ir, -4, 1), 0, 0, "// IR[3]      " );  # Current:Shift-IR         ; Next: Shift-IR
  jtag_bit_send_comment( 0, substr($cmd_ir, -5, 1), 0, 0, "// IR[4]      " );  # Current:Shift-IR         ; Next: Shift-IR
  jtag_bit_send_comment( 1, substr($cmd_ir, -6, 1), 0, 0, "// IR[5]      " );  # Current:Shift-IR         ; Next: Exit1-IR
                            
  jtag_bit_send_comment( 1, 0, 0, 0, "// Exit1-IR       --> Update-IR     " );  # Current:Exit1-IR         ; Next: Update-IR
  jtag_bit_send_comment( 0, 0, 0, 0, "// Update-IR      --> Run-Test-Idle " );  # Current:Exit1-IR         ; Next: Update-IR
  jtag_bit_send_comment( 0, 0, 0, 0, "// Run-Test-Idle  --> Run-Test-Idle " );  # Current:Run-Test/Idle    ; Next: Select-DR-Scan
                            
}

sub jtag_dr_send {                

  $dr_tdi_str     = $_[0];
  $dr_tdi_num     = $_[1];
  $dr_tdo_exp_en  = $_[2];
  $dr_tdo_exp_str = $_[3];


  if ( exists($def_hash{$dr_tdi_str}) ) {
    $dr_tdi_str = $def_hash{$dr_tdi_str};
  }
  $dr_tdi     = base2bin($dr_tdi_str    , $dr_tdi_num) ;
  $dr_tdo_exp = base2bin($dr_tdo_exp_str, $dr_tdi_num) ;

  jtag_bit_send( 0, 0, 0, 0 );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle

  jtag_bit_send_comment( 0, 0, 0, 0, "// DR_SEND  : $dr_tdi_str           " );  
  if($dr_tdo_exp_en) {
  jtag_bit_send_comment( 0, 0, 0, 0, "// DR_EXPECT: $dr_tdo_exp_str       " );  
  }
  jtag_bit_send_comment( 0, 0, 0, 0, "// Run-Test-Idle  --> Run-Test-Idle " );  # Current:Run-Test/Idle    ; Next: Select-DR-Scan
  jtag_bit_send_comment( 1, 0, 0, 0, "// Run-Test-Idle  --> Select-DR-Scan" );  # Current:Run-Test/Idle    ; Next: Select-DR-Scan
  jtag_bit_send_comment( 0, 0, 0, 0, "// Select-DR-Scan --> Capture-DR    " );  # Current:Select-IR-Scan   ; Next: Capture-IR
  jtag_bit_send_comment( 0, 0, 0, 0, "// Capture-DR     --> Shift-DR      " );  # Current:Capture-IR       ; Next: Shift-IR

  for( $i = 1; $i <= $dr_tdi_num; $i = $i + 1 ) {
    $dr_bit_num = $dr_tdi_num - $i ;
    if( $i == $dr_tdi_num - 1 ) {
      jtag_bit_send_comment( 1, substr($dr_tdi, -$i, 1), $dr_tdo_exp_en, substr($dr_tdo_exp, -$i, 1), "// DR[$dr_bit_num]" );   # Current:Shift-DR         ; Next: Exit1-DR
    }
    else { 
      jtag_bit_send_comment( 0, substr($dr_tdi, -$i, 1), $dr_tdo_exp_en, substr($dr_tdo_exp, -$i, 1), "// DR[$dr_bit_num]" );   # Current:Shift-DR         ; Next: Shift-DR
    }
  }

  jtag_bit_send_comment( 1, 0, 0, 0, "// Exit1-DR       --> Update-DR"     );  # Current:Exit1-DR         ; Next: Update-DR
  jtag_bit_send_comment( 0, 0, 0, 0, "// Update-DR      --> Run-Test-Idle" );  # Current:Update-DR        ; Next: Run-Test/Idle
  jtag_bit_send_comment( 0, 0, 0, 0, "// Run-Test-Idle  --> Run-Test-Idle" );  # Current:Run-Test/Idle    ; Next: Run-Test/Idle

}

sub jtag_test_req {
  jtag_ir_send("jtag_test_req");
  jtag_dr_send("0000_0000", 32, 0, 0);
  jtag_dr_send("0000_0000", 32, 0, 0);
}

sub jtag_idcode {
  jtag_ir_send("jtag_idcode");
  jtag_dr_send("0000_0000", 32, 0, 0);
}

sub jtag_read_expect {
  jtag_ir_send("jtag_read_expect" );
  jtag_dr_send($_[0], 32, 0, 0    );
  jtag_dr_send($_[0], 32, 1, $_[1]);
}

sub jtag_write_single {
  jtag_ir_send("jtag_write_single");
  jtag_dr_send($_[0], 32, 0, 0    );
  jtag_dr_send($_[1], 32, 0, 0    );
}

sub jtag_trans_single {
  jtag_ir_send("jtag_trans_single");
  jtag_dr_send($_[0], 32, 0, 0    );
  jtag_dr_send($_[1], 32, 0, 0    );
}

sub jtag_flash_read {
  $laddr     = $_[0]               ;
  $faddr_bin = laddr2faddr($laddr) ;

  jtag_ir_send("jtag_flash_read"    );
  jtag_dr_send($faddr_bin, 21, 0, 0 );
  jtag_dr_send("32'h0"   , 32, 0, 0 );
}

sub jtag_flash_write {
  $laddr     = $_[0]               ;
  $faddr_bin = laddr2faddr($laddr) ;

  jtag_ir_send("jtag_flash_write"   );
  jtag_dr_send($faddr_bin, 21, 0, 0 );
  jtag_dr_send($_[1]     , 32, 0, 0 );
}

sub jtag_flash_erase_all {
  jtag_ir_send("jtag_flash_erase_all");
}

sub jtag_flash_chip_erase {
  jtag_ir_send("jtag_flash_chip_erase");
}

sub jtag_flash_block_erase {
  $laddr     = $_[0]               ;
  $faddr_bin = laddr2faddr($laddr) ;

  jtag_ir_send("jtag_flash_block_erase");
  jtag_dr_send($faddr_bin, 21, 0, 0 );
}

sub jtag_flash_sector_erase {
  $laddr     = $_[0]               ;
  $faddr_bin = laddr2faddr($laddr) ;

  jtag_ir_send("jtag_flash_sector_erase");
  jtag_dr_send($faddr_bin, 21, 0, 0 );
}

sub jtag_flash_trans {
  $laddr     = $_[1]               ;
  $faddr_bin = laddr2faddr($laddr) ;

  jtag_ir_send("jtag_flash_trans");
  jtag_dr_send($_[0]     , 32, 0, 0 );
  jtag_dr_send($faddr_bin, 21, 0, 0 );
}



