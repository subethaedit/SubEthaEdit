*current sink p-type inverter - dc sweep of voltage I/O 
*file:invcsp0.sp

*parameters
.PARAM ww=38.5                  $ parameter for width which will be swept

*circuit net list
Vdd  vdd  GND  dc  5.0
Vbias bias GND dc 2.5
Vin  src  GND  dc  0.0
Mn  out  bias  GND  GND  nmosl1  W=16    L=8
Mp  out  in     vdd  vdd  pmosl1   W=ww  L=8
Cl  out  GND  0.01P
Rs  src   in     10K

*options & analysis
.OPTIONS POST=2 SCALE=1U   $ output results for plot; scale mosfet L & W dimensions
.DC Vin 0 5 0.1 $sweep I/P voltage 
.MEASURE DC vin_bal WHEN V(out)=2.5

*output
.plot DC v(src) v(in) v(out) 

*mosfet models - level 1
.INC 'l1typ.inc'

$ a comment
* another comment

.END


