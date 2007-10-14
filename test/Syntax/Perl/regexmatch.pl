
(1) if( ($x =~ /^\s/) || ($x =~ /^$/) ) 
(2) if( $x =~ /(<xml="(.*?[^"]*)"[^>]*>(.*?)<\/xml>)/ ) 

Expected Results: 
on example (1) and (2) no text highlight should be done due to the regex. 

Actual Results: 
(1) the part {s/) || ($x =~ /^$} becomes red (text highlight)  
(2) the parts {"(.*?[^"} and {"[^>]*>(.*?)<\/xml>)/ )} become red (text highlight)  
