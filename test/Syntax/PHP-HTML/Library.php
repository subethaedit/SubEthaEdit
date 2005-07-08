<?php

   define(Layout_Key,1);    # %01
   define(Layout_Value,2);  # %10

   function Layout_Initialise() {

      global $Layout_Version,$Layout´DefaultState,$Layout_PrintLayout;

      Library_Initialise('Print',1);
      Library_Initialise('Environment',1);

      $Layout_Version=2; # /100

      $Layout_PrintLayout=array(
                 'Table'=>array('cellpadding'=>2,
                                     'border'=>0,
                                'cellspacing'=>1,
                                'bordercolor'=>'#000000',
                                    'bgcolor'=>'#FFFFFF'),
                 'Data'=>array(  'Base'=>array('align'=>'left','valign'=>'top','bgcolor'=>'#FFFFFF'),
                              'TopOdd'=>array('bgcolor'=>'#EFEFEF'),
                              'TopEven'=>array('bgcolor'=>'#EFEFEF')));

      $Layout_TableState=0;
      $Layout_TableStates=array();

   }

   function Layout´DefaultLayout() {
      global $Layout´DefaultLayout;
         $Layout´DefaultLayout['Table']=array('cellpadding'=>2,
                                                   'border'=>0,
                                              'cellspacing'=>1,
                                              'bordercolor'=>'#000000',
                                                  'bgcolor'=>'#FFFFFF');
         
         $Layout´DefaultLayout['Row']['Base']      =array('align'=>'left', 'valign'=>'center');
         $Layout´DefaultLayout['Row']['TopOdd']    =array('bgcolor'=>'#FEF3F2',
			                                                  'class'=>'here');
         $Layout´DefaultLayout['Row']['TopEven']   =array('bgcolor'=>'#FEF3F2',
			                                                  'class'=>'here');
         $Layout´DefaultLayout['Row']['NormalOdd'] =array('bgcolor'=>'#FFFFFF');
         $Layout´DefaultLayout['Row']['NormalEven']=array('bgcolor'=>'#F0F0F0');
         
         
          $Layout´DefaultLayout['Data']['Base']      =array('valign'=>'baseline', 'align'=>'left');
          $Layout´DefaultLayout['Data']['TopOdd']    =array('bgcolor'=>'#FEF3F2',
			                                                  'class'=>'here');
          $Layout´DefaultLayout['Data']['TopEven']   =array('bgcolor'=>'#FEF3F2',
			                                                  'class'=>'here');
          $Layout´DefaultLayout['Data']['NormalOdd'] =array('bgcolor'=>'#FFFFFF');
          $Layout´DefaultLayout['Data']['NormalEven']=array('bgcolor'=>'#F0F0F0');
   }

   # Todo: Tables in Tables
   function Layout´SaveTableState() {
      global $Layout´TableStates, $Layout´TableState;
      global $Layout´AtLeastSecondInTable, $Layout´TableOdd, $Layout´AtLeastSecondInRow;
      $Layout´TableStates[$Layout´TableState]=
         array( 'AtLeastSecondInTable'=>$Layout´AtLeastSecondInTable,
                'TableOdd'            =>$Layout´TableOdd,
                'AtLeastSecondInRow'  =>$Layout´AtLeastSecondInRow);
      $Layout´TableStates++;
   }

   function  Layout´RestoreTableState(){
      global $Layout´TableStates, $Layout´TableState;
      global $Layout´AtLeastSecondInTable, $Layout´TableOdd, $Layout´AtLeastSecondInRow;
      $Layout´TableState--;
      $Layout´AtLeastSecondInTable=$Layout´TableStates[$Layout´TableState]['AtLeastSecondInTable'];
      $Layout´AtLeastSecondInRow  =$Layout´TableStates[$Layout´TableState]['AtLeastSecondInRow'];
      $Layout´TableOdd            =$Layout´TableStates[$Layout´TableState]['TableOdd'];
   }


   function Layout_TableStart($Array=array()) {
      global $Layout´AtLeastSecondInTable, $Layout´TableOdd;
      Layout´SaveTableState();
      $Layout´AtLeastSecondInTable=false;
      $Layout´TableOdd=0;
      Print_I( Layout_TableStartTag($Array) );
   }


   function Layout_TableEnd($String='') {
      global $Layout´AtLeastSecondInTable, $Layout´AtLeastSecondInRow;

      if ($Layout´AtLeastSecondInRow) {
         Print_O( Layout_DataEndTag() );
         $Layout´AtLeastSecondInRow=false;
      }

      if ($Layout´AtLeastSecondInTable) {
         Print_O( Layout_RowEndTag() );
         $Layout´AtLeastSecondInTable=false;
      }

      if ($String!='') Print_S($String);
      Print_O( Layout_TableEndTag() );
      
      Layout´RestoreTableState();
   }

   function Layout_TableRow($Top=false,$Array=array()) {
      global $Layout´AtLeastSecondInTable, $Layout´AtLeastSecondInRow, $Layout´TableOdd;

      $Layout´TableOdd=1-$Layout´TableOdd;

      if ($Layout´AtLeastSecondInTable) {
          Print_O( Layout_DataEndTag() );
         Print_O( Layout_RowEndTag() );
      }
      else {
         $Layout´AtLeastSecondInTable=true;
      }
      $Layout´AtLeastSecondInRow=false;
      Print_I( Layout_RowStartTag($Top,$Layout´TableOdd,$Array) );
   }

   function Layout_TableData($Top=false,$Array=array()) {
      global $Layout´AtLeastSecondInRow, $Layout´TableOdd;
      
      if ($Layout´AtLeastSecondInRow) {
         Print_O( Layout_DataEndTag() );
      }
      else {
         $Layout´AtLeastSecondInRow=True;
      }
      Print_I( Layout_DataStartTag($Top,$Layout´TableOdd,$Array) );
   }

   function Layout_TableStartTag($Array=array()) {

      if (!is_array($GLOBALS['Layout´DefaultLayout'])) {
         Layout´DefaultLayout();
      }

      $Layout=(isset($Array['Layout'])?$Array['Layout']:$GLOBALS['Layout´DefaultLayout']);
      if (is_array($Layout['Table'])) extract($Layout['Table']);
      @extract($Array);

      if (isset($width)) {
         $TableWidth=' width="'.$width.'"';
      }
		if (isset($align)) {
			$TableWidth.=' align="'.$align.'"';
		}

      $Return='<table bgcolor="'.$bgcolor.'" cellpadding=0 cellspacing=0 border=0><tr><td>'; # Just for netscape
      $Return.='<table cellpadding="'.$cellpadding.'" border="'.$border.'" cellspacing="'.$cellspacing.'" '.
                     'bordercolor="'.$bordercolor.'" bgcolor="'.$bgcolor.'"'.$TableWidth.'>';

      return $Return;
   }

   function Layout_TableEndTag() {
      return '</table></td></tr></table>';
   }

   function Layout_RowStartTag($Top=false,$Odd=false,$Array=array()) {

      $Layout=(isset($Array['Layout'])?$Array['Layout']:$GLOBALS['Layout´DefaultLayout']);
      @extract($Layout['Row']['Base']);
      @extract($Layout['Row'][($Top?'Top':'Normal').($Odd?'Odd':'Even')]);
      extract($Array);

      $Return='<tr'.($align   !='' ? ' align="'.$align.'"'       :'').
                    ($bgcolor !='' ? ' bgcolor="'.$bgcolor.'"'   :'').
                    ($valign  !='' ? ' valign="'.$valign.'"'     :'').
                    ($border  !='' ? ' border="'.$border.'"'     :'').
                    ($class   !='' ? ' class="'.$class.'"'       :'').
                    ($nowrap  !='' ? ' nowrap'                   :'').
                  '>';

      return $Return;

   }

   function Layout_RowEndTag() {
      return '</tr>';
   }

   function Layout_DataStartTag($Top=false,$Odd=false,$Array=array()) {

      $Layout=(isset($Array['Layout'])?$Array['Layout']:$GLOBALS['Layout´DefaultLayout']);
      @extract($Layout['Data']['Base']);
      @extract($Layout['Data'][($Top?'Top':'Normal').($Odd?'Odd':'Even')]);
      extract($Array);

      $Return='<td'.($align   !=''    ? ' align="'.$align.'"'             :'').
                    ($bgcolor !=''    ? ' bgcolor="'.$bgcolor.'"'         :'').
                    ($valign  !=''    ? ' valign="'.$valign.'"'           :'').
                    ($border  !=''    ? ' border="'.$border.'"'           :'').
                    ($colspan !=''    ? ' colspan="'.$colspan.'"'         :'').
                    ($rowspan !=''    ? ' rowspan="'.$rowspan.'"'         :'').
                    ($bordercolor!='' ? ' bordercolor="'.$bordercolor.'"' :'').
                    ($width   !=''    ? ' width="'.$width.'"'             :'').
                    ($class   !=''    ? ' class="'.$class.'"'             :'').
                    ($nowrap  !=''    ? ' nowrap'                         :'').
                  '>';

      return $Return;

   }

   function Layout_DataEndTag() {
      return '</td>';
   }

   function Layout_TableColumns($Content, $Attributes=array()) {

      $Columns=count($Content);

      for ($Loop=0; $Loop<$Columns; $Loop++) {
         if ($Attributes['Color'][$Loop]=='Dark') {
            $Color[$Loop][0]=' bgcolor="#'.Main_GetChoice('BaseColorTableDarkTopBackground').'" class="LightHead"';
            $Color[$Loop][1]=' bgcolor="#'.Main_GetChoice('BaseColorTableLightTopBackground').'" class="LightHead"';
         }
         else {
            $Color[$Loop][1]=' bgcolor="#'.Main_GetChoice('BaseColorTableDarkBackground').'"';
            $Color[$Loop][0]=' bgcolor="#'.Main_GetChoice('BaseColorTableLightBackground').'"';
         }
      }

      if (isset($Attributes['Width']['Table'])) {
         $TableWidth=' width="'.$Attributes['Width']['Table'].'"';
      }

      $Counter=-1;
      while (isset($Attributes['Width'][++$Counter])) {
         $ColumnWidth[$Counter]=' width="'.$Attributes['Width'][$Counter].'"';
      }

      Print_I('<table cellpadding="5" border="0" cellspacing="1" bordercolor="#'.Main_GetChoice('BaseColorBorder').'" bgcolor="#'.Main_GetChoice('BaseColorTableDarkTopBackground').'"'.$TableWidth.'>');

      for ($Loop=0; $Loop<count($Content[0]); $Loop++) {
         Print_I('<tr>');
            for($InnerLoop=0; $InnerLoop<$Columns; $InnerLoop++) {
               Print_S('<td'.$ColumnWidth[$InnerLoop].$Color[$InnerLoop][$Loop%2].'>',false);
               Print_S($Content[$InnerLoop][$Loop]!=''?$Content[$InnerLoop][$Loop]:'&nbsp;',false);
               Print_S('</td>');
            }
         Print_O('</tr>');
      }
      Print_O('</table>');

   }

   function Layout_Table($Content, $Top=true, $Attributes=array()) {

      if (isset($Attributes['Width']['Table'])) {
         $TableWidth=' width="'.$Attributes['Width']['Table'].'"';
      }

      $Counter=-1;
      while (isset($Attributes['Width'][++$Counter])) {
         $ColumnWidth[$Counter]=' width="'.$Attributes['Width'][$Counter].'"';
      }

      Print_I('<table cellpadding="5" border="0" cellspacing="1" bordercolor="#'.Main_GetChoice('BaseColorBorder').'" bgcolor="#'.Main_GetChoice('BaseColorTableDarkTopBackground').'"'.$TableWidth.'>');
      reset($Content);
      if ($Top) {
         list(,$Headings)=each($Content);
         Print_I('<tr bgcolor="#'.Main_GetChoice('BaseColorTableDarkTopBackground').'">');
         foreach($Headings as $Heading) {
            Print_S('<td'.$ColumnWidth[$CellCount++].'><span class="LightHead">'.
                    ($Heading!=""?$Heading:"&nbsp;").'</span></td>');
         }
         Print_O('</tr>');
      }

      $Background[0]=Main_GetChoice('BaseColorTableDarkBackground');
      $Background[1]=Main_GetChoice('BaseColorTableLightBackground');

      while (list(,$Row)=each($Content)) {
         $Odd=1-$Odd;
         Print_I('<tr bgcolor="#'.$Background[$Odd].'">');
         foreach($Row as $Element) {
            Print_S('<td class="DarkText"'.$ColumnWidth[$CellCount++].'>'.
                     ($Element!=""?$Element:"&nbsp;").'</td>');
         }
         Print_O('</tr>');
      }
      Print_O('</table>');
   }

   function Layout_Heading($Heading) {
      Print_S ('<span class="HeadInDarkTable"><font size="4">'.$Heading.'</font></span>');
   }

   function Layout_Response($Response, $Attributes=array('Color'=>array('Dark'))) {
#      Layout_TableColumns( array( array(Main_GetMessage('Main_Msg/Response')),array($Response) ), $Attributes);
      Layout_TableStart(array('bgcolor'=>'#'.Main_GetChoice('BaseColorAlert')));
         Layout_TableRow();
            Layout_TableData(1,array('bgcolor'=>'#'.Main_GetChoice('BaseColorAlert')));
               Print_S(Main_GetMessage('Main_Msg/Response'));
            Layout_TableData(0);
               Print_S($Response);
      Layout_TableEnd();
   }

   function Layout_Navigation($Position, $MaxPerPage, $Count, $Baselink,$PositionName='Position', $MaxPages=22) {

      $Radius=ceil($MaxPages/2);

      if ($Count>$MaxPerPage) {
         if ($Position>=$MaxPerPage) {
            Print_S('<a href="'.Environment_AddToUrl($Baselink, $PositionName, (String)($Position-$MaxPerPage)).'">&lt;&lt;</a>&nbsp');   
         }
         else {
            Print_S('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
         }
         if ($Count/$MaxPerPage<$MaxPages) {
            for ($Loop=0;$Loop<$Count;$Loop+=$MaxPerPage) {
               if ($Loop!=$Position) {
                  Print_S('<a href="'.Environment_AddToUrl($Baselink, $PositionName, (String)$Loop).'">'.++$Page.'</a>&nbsp');
               }
               else {
                  Print_S('<b>'.++$Page.'</b>&nbsp;');
               }
            }
         }
         else {
            for ($Loop=0;$Loop<$Count && $Loop<=($Position+$MaxPerPage*$Radius);$Loop+=$MaxPerPage) {
               ++$Page;
               if ($Loop>=($Position-$MaxPerPage*$Radius)) {
                  if ($Loop!=$Position) {
                     Print_S('<a href="'.Environment_AddToUrl($Baselink, $PositionName, (String)$Loop).'">'.$Page.'</a>&nbsp');
                  }
                  else {
                     Print_S('<b>'.$Page.'</b>&nbsp;');
                  }
               }
            }
         }
         if ($Position+$MaxPerPage<$Count) {
            Print_S('<a href="'.Environment_AddToUrl($Baselink, $PositionName, (String)($Position+$MaxPerPage)).'">&gt;&gt;</a>&nbsp');
         }
      }
   }

   function Layout_DropDown($Array,$Name,$Selected=array(),$Attributes=array()) {

      if (!is_array($Attributes)) {
         $Attributes=array('tabindex'=>$Attributes);
      }

      if (!is_array($Selected)) {
         $Selected=array($Selected);
      }

      $Return='';

      if (count($Array)>0) {

         $Return.='<select name="'.$Name.'"';
         foreach ($Attributes as $Attribute=>$Value) {
            if (strtolower($Attribute)=='multiple') {
               $Multiple=true;
            }
            else {
               $Return.=' '.$Attribute.'="'.$Value.'"';
            }
         }
         $Return.=' class="NoUnderline"';
         if ($Multiple) $Return.=' multiple';
         $Return.='>'."\n";

         foreach($Array as $Key=>$Value) {
            $Return.='   <option value="'.$Key.'"'.(in_array($Key,$Selected)?' selected':'').'>'.$Value.'</option>'."\n";
         }

         $Return.='</select>'."\n";

      }
      else {
         Logger_Log('Error','Layout_DropDown('.$Name.','.$Selected.'): Array leer'); 
      }

      return $Return;
      
   }

   function Layout_HtmlEntities($ToHTML,$Options='Default') {

      if ($Options=='Default') {
         $Options=Layout_Key | Layout_Value;
      }

      if (is_array($ToHTML)) {
         $Return=array();
         foreach($ToHTML as $Key=>$Value) {
            $Return[($Options & Layout_Key)?htmlentities($Key):$Key]=($Options & Layout_Value)?Layout_HtmlEntities($Value,$Options):$Value;
         }
      }
      else {
         $Return=htmlentities($ToHTML);
      }

      return $Return;
   }

   function Layout_OpenCloseImage($Open) {
      return '<img src="'.Main_ResourceFileExternal('Shared','Layout',
                              ($Open?'Open':'Closed').'.gif').'" width="13" height="13" border="0" alt="'.Main_GetMessage('Main_Msg/'.($Open?'Open':'Close').'Image').'">';   
   }

   function Layout_LeftArrowImage($Alt='Left') {
      return '<img src="'.Main_ResourceFileExternal('Shared','Layout','Left.gif').'" width="15" height="10" border="0" alt="'.$Alt.'">';
   }

   function Layout_RightArrowImage($Alt='Right') {
      return '<img src="'.Main_ResourceFileExternal('Shared','Layout','Right.gif').'" width="15" height="10" border="0" alt="'.$Alt.'">';
   }

   function Layout_RadioImage($State,$Alt='') {
      if ($Alt=='') $Alt=($State?'On':'Off');
      return '<img src="'.Main_ResourceFileExternal('Shared','Layout','Radio'.($State?'On':'Off').'.gif').'" width="17" height="17" border="0" alt="'.$Alt.'">';
   }

   function Layout_BlindGif($Width,$Height) {
      return '<img src="'.$GLOBALS['Main_BlindGif'].'" border="0" width="'.$Width.'" height="'.$Height.'" alt="">';
   }

   function Layout_VSpace($Pixels=5) {
      return '<table border=0 cellspacing=0 cellpadding=0>'.
              '<tr><td>'.
              Layout_BlindGif(1,$Pixels).
              '</td></tr>'.
             '</table>';
   }

?>
