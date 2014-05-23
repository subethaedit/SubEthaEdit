<?php

function Vegra_Initialise() {
    global $Vegra_Version;
    Library_Initialise('Mysql',1);
    Library_Initialise('Message',1);
    $Vegra_Version = 1;
}

function html_productname($ProductName){
  return str_replace('_','&nbsp;',htmlspecialchars($ProductName));
}

function tag_options($Options=array()) {
  $Result='';
  foreach($Options as $Name => $Value) {
    $Result .= ' '.$Name.'="'.htmlspecialchars($Value).'"';
  }
  return $Result;
}

function content_tag($Tag, $Content, $Options=array()) {
  return '<'.$Tag.tag_options($Options).'>'.$Content.'</'.$Tag.'>';
}

function koi2utf8($s) {
    $s=convert_cyr_string($s,'k','w');
   for($i=0, $m=strlen($s); $i<$m; $i++)    { 
       $c=ord($s[$i]); 
       if ($c<=127) {$t.=chr($c); continue; } 
       if ($c>=192 && $c<=207)    {$t.=chr(208).chr($c-48); continue; } 
       if ($c>=208 && $c<=239) {$t.=chr(208).chr($c-48); continue; } 
       if ($c>=240 && $c<=255) {$t.=chr(209).chr($c-112); continue; } 
       if ($c==184) { $t.=chr(209).chr(209); continue; }; 
   if ($c==168) { $t.=chr(208).chr(129);  continue; }; 
   } 
   return $t; 
} 

function file_put_contents($Filename, $Data) {
    $Handle=fopen($Filename,"w");
    if (!$Handle) {
        return 0;
    }
    $Result=fwrite($Handle,$Data);
    fclose($Handle);
    return $Result;
}

function sendGenericEmail() {
    $Subject=Environment_Read('Subject');

    $FieldOrder=Environment_Read('FieldOrder');
    $Fields=explode(',',$FieldOrder);
    $Text='';
    $HTMLText='';
    $From='';
    foreach($Fields as $Field) {
         if ($Field=="-") {
            $Text.="----------------------------------------------\n";
            $HTMLText.="<hr />";
        } else {
            $Text.=$Field.': '.Environment_Read($Field)."\n";
            $HTMLText.=$Field.":&nbsp;<strong>";
            if (strtolower($Field)=='email') {
                $HTMLText.='<a href="mailto:'.Environment_Read($Field).'">'.Environment_Read($Field)."</a>";
            } else {
                $HTMLText.=Environment_Read($Field);
            }
            $HTMLText.="</strong><br />";
        }
        if (strtolower($Field)=='email') {
          $From=Environment_Read($Field);
        }
    }
    // mail("info@vegra.de","Zur Sicherheit nochmal nur-text:".$Subject,$Text,$From?'From: '.$From."\n\r":$From);
    if (strstr($_SERVER["HTTP_REFERER"],"/ru/") || strstr($_SERVER["HTTP_REFERER"],"/atru/")) {
        global  $Vegra_FileBase;
        HTMLMail($From,"internet@vegra.de",$Subject,$HTMLText,false,false,"utf-8");
        $HTMLFile='<html><head><meta http-equiv="content-type" content="text/html; charset=utf-8" /></head><body>'.$HTMLText.'</body></html>';
        file_put_contents($Vegra_FileBase.'/ru/requests/'.date('Y-m-d_G-i-s').'.html',$HTMLFile);
    } else {
        HTMLMail($From,"internet@vegra.de",$Subject,$HTMLText);
    }
}

function HTMLMail($From,$To,$Subject,$HTMLMessage,$AdditionalHeaders=false,$PlainTextAlternative=false,$Charset="iso-8859-1") {
    $Headers ="MIME-Version: 1.0\r\n";
    if ($AdditionalHeaders) {
        $Headers.=$AdditionalHeaders;
    }
    if ($From) $Headers.="From: ".$From."\r\n";
    if ($PlainTextAlternative) {
        $Boundary=uniqid("MyBoundary");
        $Headers.="Content-Type: multipart/alternative; boundary = ".$Boundary."\r\n\r\n";
    } else {
        $Headers.="Content-type: text/html; charset=".$Charset."\r\n";
        $Headers.="Bcc: veg-emails@int-mark.de, dom@dasgenie.com\r\n";
        $Body=$HTMLMessage;
    }
    mail($To,$Subject,$Body,$Headers);
}

function CachedPDFPath($Type,$Id,$Language) {
    global $Vegra_FileBase;
    return $Vegra_FileBase.'/Caches/PDF/'.$Language.'_'.$Type.'_'.$Id.'.pdf';
}

function delete_with_wildcards($dir, $pattern = "*.*") {
    $deleted = false;
    $pattern = str_replace(array("\*","\?"), array(".*","."), preg_quote($pattern));
    if (substr($dir,-1) != "/") $dir.= "/";
    if (is_dir($dir)) {
        $d = opendir($dir);
        while ($file = readdir($d)) {
            if (is_file($dir.$file) && ereg("^".$pattern."$", $file)) {
                if (unlink($dir.$file)) $deleted[] = $file;
            }
        }
        closedir($d);
        return $deleted;
    }
    else return 0;
}

function ChangedTables() {
    global $Vegra_FileBase;
    delete_with_wildcards($Vegra_FileBase.'/Caches/PDF/','*_Category_*.pdf');
}


function ChangedTableData($Language) {
    global $Vegra_FileBase;
    delete_with_wildcards($Vegra_FileBase.'/Caches/PDF/',$Language.'_Category_*.pdf');
}

function ChangedContent($Type,$Id,$Language) {
    $FilePath=CachedPDFPath($Type,$Id,$Language);
    if (is_readable($FilePath)) {
//        error_log("no readable file at: $FilePath");
        unlink($FilePath);
    } else {
//        error_log("no readable file at: $FilePath");
    }
}

function getToken($Token,$Language) {
    $Return='';
    $Result=mysql_query("SELECT Value FROM CustomLanguage ".
                        "WHERE Language='".$Language."' AND Token='".addslashes($Token)."'");
    if ($Result) {
        list($Value)=mysql_fetch_row($Result);
        if ($Value) {
            $Return=$Value;
        }
    }
    return $Return;
}

function setToken($Token,$Language,$Value) {
    $Result=mysql_query("SELECT Value FROM CustomLanguage ".
                        "WHERE Language='".$Language."' AND Token='".addslashes($Token)."'");
    if ($Result && mysql_num_rows($Result)>0) {
        if ($Value) {
            mysql_query("UPDATE CustomLanguage SET Value='".addslashes($Value)."' ".
                            "WHERE Language='".$Language."' AND Token='".addslashes($Token)."'");
        } else {
            mysql_query("DELETE FROM CustomLanguage ".
                        "WHERE Language='".$Language."' AND Token='".addslashes($Token)."'");
        }
    } else {
        if ($Value) {
            mysql_query("INSERT INTO CustomLanguage (Token,Language,Value) ".
                            "VALUES ('".addslashes($Token)."','".$Language."','".addslashes($Value)."')");
        }
    }
}

function Brake($String, $Width, $Target="HTML") {
    if ($Target=="HTML") {
        $NL  ="<br />";
        $NBSP="&nbsp;";
    } else {
        $NL  ="\n";
        $NBSP=" ";
    }
    $String=trim($String);
    $Broken=array();
    while (strlen($String)>0) {
        if (strlen($String)>$Width) {
            for ($i=$Width;$i<strlen($String);$i++) {
                if ($String[$i]==" ") break;
                if ($String[$i]=="\n") break;
                $Left=$Width-$i+$Width;
                if ($Left>0) {
                    if ($String[$Left]==" " || $String[$Left]=="\n") {
                        $i=$Left;
                        break;
                    }
                }
            }
            $Broken[]=substr($String,0,$i);
            $String=trim(substr($String,$i));
        } else {
            $Broken[]=$String;
            $String="";
        }
    }
    $Return=implode($NL,$Broken);
    $Return=str_replace('_',$NBSP,$Return);
    return $Return;
}

function ParagraphParser($String,$HTMLEntities=false) {

    if ($HTMLEntities) {
        $EntityFunction='htmlentities';
    } else {
        $EntityFunction='htmlspecialchars';
    }

    $ListStart='<ul class="liste2">';
    $ListItemStart='<li>';
    $ListItemEnd='</li>';
    $ListEnd='</ul>';

    $ListStart='<table cellspacing="0" cellpadding="0" border="0">';
    $ListItemStart='<tr valign="baseline"><td width="10">-</td><td>';
    $ListItemEnd='</td></tr>';
    $ListEnd='</table>';

    $Lines=explode("\n",$String);
    $LineCount=count($Lines);
    $LineI=0;
    $InList=false;
    foreach ($Lines as $Line) {
        if (substr($Line,0,2)=="- ") {
            if (!$InList) {
                $Return.=$ListStart.$ListItemStart;
                $InList=true;
            } else {
                $Return.=$ListItemEnd.$ListItemStart;
            }
            $Line=substr($Line,2);
        } else if ($InList and substr($Line,0,2)=="  " and $Line!="") {
            // nothing
        } else {
            if ($InList) {
                $Return.=$ListItemEnd.$ListEnd;
                $InList=false;
            }
        }
        $Bolds=explode("##",$Line);
        $Return.=str_replace('_','&nbsp;',$EntityFunction($Bolds[0],ENT_NOQUOTES));
        for ($i=1;$i<count($Bolds);$i++) {
            if ($i%2==1) $Return.='<b>';
            $Return.=str_replace('_','&nbsp;',$EntityFunction($Bolds[$i],ENT_NOQUOTES));
            if ($i%2==1) $Return.='</b>';
        }
        if (++$LineI<$LineCount) {
            $Return.='<br />';
        }
    }
    if ($InList) {
        $Return.=$ListItemEnd.$ListEnd;
    }

    return $Return;
}

function NumberSelector($Name,$SelectedNumber,$Start,$End) {
    $Return.='<select name="'.$Name.'">';
        for($i=$Start;$i<=$End;$i++) {
            $Return.="<option value='$i'".($SelectedNumber==$i?' selected':'').">$i</option>";
        }
    $Return.='</select>';
    return $Return;
}

function ProductSelector($Name, $SelectedProductId) {
    $Return='';
    $Categories=FetchCategories('de');
    $CategoriesPlain=array();
    foreach ($Categories as $SubCategories) {
        foreach ($SubCategories as $Category) {
            $CategoriesPlain[$Category['CategoryId']]=$Category;
        }
    }
    $Result=mysql_query($Query="SELECT Product.CategoryId,ProductLanguage.ProductId, ProductLanguage.Name FROM Category, Product,  ProductLanguage ".
                        "WHERE Product.CategoryId=Category.CategoryId AND Product.ProductId=ProductLanguage.ProductId AND ProductLanguage.Language='de' ".
                    "ORDER BY Category.ParentId ASC, Category.Position ASC, Product.Position ASC");

    $ProductIds=array();
    if (!$Result) {
        error_log("ProductSelector($Name, $SelectedProductId) failed: $Query");
    } else {
        $CurrentCategory=array();
        while ($Row=mysql_fetch_assoc($Result)) {
            if ($CurrentCategory!=$Row['CategoryId']) {
                $CurrentCategory=$Row['CategoryId'];
                $ProductIds[]='Category'.$Row['CategoryId'];
                $ProductNames['Category'.$Row['CategoryId']]='--- '.($CategoriesPlain[$Row['CategoryId']]['Name']).' ---';
            }
            $ProductIds[]=$Row['ProductId'];
            $ProductNames[$Row['ProductId']]=$Row['Name'];
        }
    }

    $Return.='<select name="'.$Name.'">';
        foreach ($ProductIds as $ProductId) {
            $Return.='<option value="'.$ProductId.'"'.($ProductId==$SelectedProductId?' selected':'').'>'.str_replace('_','&nbsp;',htmlentities($ProductNames[$ProductId])).'</option>';
        }
    $Return.='</select>';
    return $Return;
}

function DisplayProductTableFootnotes($Footnotes) {
    $i=1;
    foreach ($Footnotes as $Footnote) {
        Print_S(($i++).') '.ParagraphParser($Footnote['Name']).'<br>');
    }
}

function EditProductTableFootnotes($Baselink,$ProductTableId,$Language,$LanguageFrom='de',$AdminLanguage=array()) {

    if (is_array($AdminLanguage)) $AdminLanguage=$Language;

    if (Environment_Read('Action')=='ChangeFootnoteInt') {
        mysql_query($Query="DELETE FROM ProductTableFootnoteLanguage ".
                    "       WHERE FootnoteId=".Environment_Read('FootnoteId').
                                " AND Language='".$Language."'");
        //echo "<pre>$Query</pre>";
        mysql_query($Query="INSERT INTO ProductTableFootnoteLanguage (FootnoteId, Language, Name) ".
                    "VALUES (".Environment_Read('FootnoteId').",'".$Language."','".Environment_Read('Footnote','pg',Environment_Quoted)."') ");
        //echo "<pre>$Query</pre>";
    }

    if (Environment_Read('Action')=='AddFootnote') {
        if (($NewFootnote=Environment_Read('NewFootnote'))!='') {
            mysql_query("INSERT INTO ProductTableFootnote (ProductTableId, Position, Description) ".
                        "VALUES (".$ProductTableId.",".Environment_Read('Position').",'".addslashes($NewFootnote)."')");
            $FootnoteId=mysql_insert_id();
            mysql_query("INSERT INTO ProductTableFootnoteLanguage (FootnoteId, Language, Name) ".
                        "VALUES (".$FootnoteId.",'".$Language."','".$NewFootnote."') ");
        }
    }

    if (Environment_Read('Action')=='ChangeFootnote') {
        mysql_query("UPDATE ProductTableFootnote ".
                        "SET Description='".Environment_Read('Footnote','pg',Environment_Quoted)."' ".
                        "WHERE FootnoteId=".Environment_Read('FootnoteId') );
        mysql_query($Query="UPDATE ProductTableFootnoteLanguage ".
                    "SET Name='".Environment_Read('Footnote','pg',Environment_Quoted)."' ".
                        "WHERE FootnoteId=".Environment_Read('FootnoteId') );
    }

    if (Environment_Read('Action')=='RemoveFootnote') {
        mysql_query("UPDATE ProductTableData SET FootnoteId=NULL WHERE FootnoteId=".Environment_Read('FootnoteId'));
        mysql_query("DELETE FROM ProductTableFootnote WHERE FootnoteId=".Environment_Read('FootnoteId'));
        mysql_query("DELETE FROM ProductTableFootnoteLanguage WHERE FootnoteId=".Environment_Read('FootnoteId'));
    }

    $ProductTableFootnotes  =FetchProductTableFootnotes($ProductTableId, $Language);
    $ProductTableFootnotesDe=FetchProductTableFootnotes($ProductTableId, $LanguageFrom);
    $Footnotes=array();
    foreach ($ProductTableFootnotes as $Footnote) {
        $Footnotes[$Footnote['FootnoteId']]=$Footnote['Name'];
    }
    $i=1;
    foreach ($ProductTableFootnotesDe as $Footnote) {
        if (Environment_Read('Action')=='EditFootnote' && $Footnote['FootnoteId']==Environment_Read('FootnoteId')) {
            Print_S('<form name="f" action="'.Environment_AddToUrl($Baselink,'Action','ChangeFootnote').'" method="post">');

            Print_S($i.') '.
                    '<input type="text" value="'.htmlspecialchars($Footnote['Name'],ENT_COMPAT).'" name="Footnote" size="'.max(60,strlen($Footnote['Name'])).'">'.
                      '<input type="hidden" name="FootnoteId" value="'.$Footnote['FootnoteId'].'">'.
                    '<input type="submit" value="&auml;ndern"><br />');
            Print_S('<script>document.f.Footnote.focus();</script>'.'</form>');
        }
        else if (Environment_Read('Action')=='DeleteFootnote' &&
                   $Footnote['FootnoteId']==Environment_Read('FootnoteId')) {
            Print_S($i.') '.ParagraphParser($Footnote['Name']).'<br />');

            $Result=mysql_query('SELECT COUNT(FootnoteId) FROM ProductTableData WHERE FootnoteId='.$Footnote['FootnoteId']);
            list($Count)=mysql_fetch_row($Result);
            if ($Count>0) {
                Print_S("<b>Achtung, diese Fu&szlig;note wird in ".$Count." Eintr&uuml;gen verwendet</b>");
            }
            Print_S('<a href="'.Environment_AddToUrl( Environment_AddToUrl($Baselink, 'Action','RemoveFootnote'),
                                                                'FootnoteId',$Footnote['FootnoteId']).'">'.
                      '<b>endg&uuml;ltig l&ouml;schen</b></a><br />');
        }
        else {
            Print_S($i.') '.ParagraphParser($Footnote['Name']));
            if ($Language=='de') {
                Print_S(' <a href="'.Environment_AddToUrl( Environment_AddToUrl($Baselink, 'Action','EditFootnote'),
                                                                    'FootnoteId',$Footnote['FootnoteId']).'">&auml;ndern</a>'.
                     ' <a href="'.Environment_AddToUrl( Environment_AddToUrl($Baselink, 'Action','DeleteFootnote'),
                                                                    'FootnoteId',$Footnote['FootnoteId']).'">l&ouml;schen</a>');
            } else {
                Print_S('<br />');
                Print_S('<form name="f" action="'.Environment_AddToUrl($Baselink,'Action','ChangeFootnoteInt').'" method="post">');

                Print_S($i.') '.
                        '<input type="text" value="'.htmlspecialchars($Footnotes[$Footnote['FootnoteId']],ENT_COMPAT).'"'.
                                           ' name="Footnote" size="'.max(60,strlen($Footnotes[$Footnote['FootnoteId']])).'">'.
                          '<input type="hidden" name="FootnoteId" value="'.$Footnote['FootnoteId'].'">'.
                        '<input type="submit" value="'.htmlspecialchars(Message_Get($AdminLanguage,"AdminChange")).'"><br />');
                Print_S('<script>document.f.Footnote.focus();</script>'.'</form>');
            }
            Print_S('<br />');
        }
        $i++;
    }
    if (Environment_Read('Action')=='NewFootnote') {
        Print_S('<form name="f" action="'.Environment_AddToUrl($Baselink, 'Action','AddFootnote').'" method=post>');
        Print_S('<input type="hidden" name="Position" value="'.$i.'">');
        Print_S($i.'): '.'<input type="text" name="NewFootnote" size=60>');
        Print_S('<input type="Submit" value="hinzuf&uuml;gen">');
        Print_S('<script>document.f.NewFootnote.focus();</script>');
        Print_S('</form>');
    }
    else if ($Language=='de') {
        Print_S('<a href="'.Environment_AddToUrl($Baselink, 'Action','NewFootnote').'">neue Fu&szlig;note</a><br>');
    }
}

function SearchField($Language='de') {
    global $Vegra_FileBase,$Vegra_URLBase;
    $Search='Suche';
    if (is_readable($Vegra_FileBase.'/Pictures/Table/'.md5($Search).'.png')) {
        $Size=getimagesize($Vegra_FileBase.'/Pictures/Table/'.md5($Search).'.png');
        $String='<input type="image" border="0" name="Go" src="'.$Vegra_URLBase.'/Pictures/Table/'.md5($Search).'.png" '.$Size[3].'>';
    } else {
        $String='<input type="image" border="0" name="Go" src="'.$Vegra_URLBase.'/Utilities/TableTTFText.php?Text='.urlencode($Search);
        $String.='" alt="'.htmlspecialchars($Search).'">';
    }
    Print_S($String);
}

function LocalizeTableHeadings($LanguageFrom,$LanguageTo,$Baselink,$AdminLanguage=array()) {

    if (is_array($AdminLanguage)) $AdminLanguage=$LanguageFrom;

    if (Environment_Read('Action')=='ChangeHeading') {
        mysql_query("DELETE FROM ProductTableEntryLanguage ".
                        "WHERE Language='".$LanguageTo."' AND EntryId=".Environment_Read('EntryId'));
        mysql_query("INSERT INTO ProductTableEntryLanguage (EntryId,Language,Name) ".
                        "VALUES (".Environment_Read('EntryId').",'".$LanguageTo."','".Environment_Read('Name','pg',Environment_Quoted)."')");
        ChangedTableData($LanguageTo);
    }

    $Result=mysql_query("SELECT * FROM ProductTableEntryLanguage ".
                        "WHERE Language='".$LanguageTo."' OR Language='".$LanguageFrom."'");
    $EntryLanguage=array($LanguageFrom=>array(),$LanguageTo=>array());
    while ($Row=mysql_fetch_assoc($Result)) {
        $EntryLanguage[$Row['Language']][$Row['EntryId']]=$Row['Name'];
    }

    Layout_TableStart();
        Layout_TableRow(1);
            Layout_TableData(1);
                Print_S(htmlentities(Message_Get($AdminLanguage,'AdminTable')));
            Layout_TableData(1);
                Print_S($LanguageFrom);
            Layout_TableData(1);
                Print_S($LanguageTo);

    $Result=mysql_query("SELECT * FROM ProductTable");
    while ($Row=mysql_fetch_assoc($Result)) {
        $First=true;
        $ProductTableName=$Row['Description'];
        $ProductTableId  =$Row['ProductTableId'];

        $EntryIds=array();
        $Result2=mysql_query("SELECT * FROM ProductTableEntry WHERE ProductTableId=".$ProductTableId." ORDER BY Position");
        while ($Entry=mysql_fetch_assoc($Result2)) {
            Layout_TableRow();
            if ($First) {
                Layout_TableData(1);
                    Print_S(htmlentities($ProductTableName));
                $First=false;
            } else {
                Layout_TableData();
                    Print_S('&nbsp;');
            }
            Layout_TableData(0);
                Print_S(nl2br(htmlentities($EntryLanguage[$LanguageFrom][$Entry['EntryId']])));
            Layout_TableData(0);
                $URL=Environment_AddToUrl($Baselink,'EntryId',$Entry['EntryId']);
                print_s('<a name="Entry'.$Entry['EntryId'].'"></a>');
                if (Environment_Read('Action')=='EditHeading' && Environment_Read('EntryId')==$Entry['EntryId']) {
                    $URL=Environment_AddToUrl($URL,'Action','ChangeHeading');
                    Print_S('<form action="'.$URL.'#Entry'.$Entry['EntryId'].'" method="post" name=f>');
                    Print_S('<textarea rows=3 cols=50 name="Name">'.$EntryLanguage[$LanguageTo][$Entry['EntryId']].'</textarea>');
                    Print_S('<script>document.f.Name.focus();</script>');
                    Print_S('<input type="submit" value="'.htmlentities(Message_Get($AdminLanguage,'AdminChange')).'">');
                    Print_S('</form>');

                } else {
                    $URL=Environment_AddToUrl($URL,'Action','EditHeading');
                    Print_S(nl2br(htmlspecialchars($EntryLanguage[$LanguageTo]  [$Entry['EntryId']])));
                    Print_S(' <a href="'.$URL.'#Entry'.$Entry['EntryId'].'">'.htmlentities(Message_Get($AdminLanguage,'AdminChange')).'</a>');
                }
        }
    }
    Layout_TableEnd();
}

function DisplayHeading($Heading,$Upwards=false) {
    global $Vegra_FileBase,$Vegra_URLBase;
    $id=$Heading.($Upwards?'Up':'Right');
    if (is_readable($Vegra_FileBase.'/Caches/TableHeadings/'.md5($id).'.png')) {
        $Size=getimagesize($Vegra_FileBase.'/Caches/TableHeadings/'.md5($id).'.png');
        $String='<img src="'.$Vegra_URLBase.'/Caches/TableHeadings/'.md5($id).'.png" '.$Size[3].'>';

    } else {
        $String='<img src="'.$Vegra_URLBase.'/Utilities/TableTTFText.php?Text='.urlencode($Heading);
        if ($Upwards) $String.='&Orientation=Up';
        global $Language;
        if ($Language=='ru') $String.='&Language=ru';
        $String.='" alt="'.htmlspecialchars($Heading).'">';
    }
    Print_S($String);
}

function DisplayProductTableData($ProductTableId,$TypeId,$Data,$Language,$ProductLink) {
    static $Types=array();
    static $Footnotes=array();
    if (!is_array($Footnotes[$ProductTableId][$Language]))
        $Footnotes[$ProductTableId][$Language]=FetchProductTableFootnotes($ProductTableId,$Language);
    if (!is_array($Types[$Language]))
        $Types[$Language]=FetchProductTableTypes($Language);
    static $mist=true;
//		if ($mist) {echo "<pre>";print_r($Types);echo"</pre>";$mist=false;}
    $String='';
    $String.=$Types[$Language]['Values'][$Data['ValueId']];
    if ($TypeId=='NUMBER') {
        if (strlen($Data['DirectValue1'])>0) $String.=' '.$Data['DirectValue1'];
    } if ($TypeId=='TEXT') {
        $String=ParagraphParser($Data['Paragraph']);
    }
    if ($Data['isData'] && count($Data['FootnoteIds'])>0) {
        $FoundFootnotes=array();
        foreach ($Footnotes[$ProductTableId][$Language] as $Position=>$Footnote) {
            if (in_array($Footnote['FootnoteId'],$Data['FootnoteIds'])) $FoundFootnotes[]=($Position+1).')';
        }
        if (count($FoundFootnotes) > 0) {
            $String.=' '.implode(', ',$FoundFootnotes);
        }
    }
    if (strlen($String)==0) $String='&nbsp;';
    if ($TypeId!='TEXT') $String=nl2br($String);
    Print_S($String);
}

function DisplayProductTable($CategoryId, $Language,$ProductLink,$Active=false) {
    list($ProductTableId)=@mysql_fetch_row(mysql_query('SELECT ProductTableId FROM Category WHERE CategoryId='.$CategoryId));
    $ProductTable=FetchProductTable($ProductTableId, $Language);
    if (count($ProductTable)<1) return;
    $AdditionalProducts=FetchAdditionalProducts($CategoryId,$Language,$Active);
    $Products=FetchProducts($CategoryId,$Language,$Active);

       $TableLayout['Table']=array(         'cellpadding'=>1,
                                               'border'=>1,
                                          'cellspacing'=>0,
                                          'bordercolor'=>'#CCCCCC',
                                              'bgcolor'=>'#FFFFFF',
                                                                'align'=>'center');

     $TableLayout['Row']['Base']      =array('align'=>'left', 'valign'=>'center');
     $TableLayout['Row']['TopOdd']    =array('bgcolor'=>'#FEF3F2',
                                                          'class'=>'here');
     $TableLayout['Row']['TopEven']   =array('bgcolor'=>'#FEF3F2',
                                                          'class'=>'here');
     $TableLayout['Row']['NormalOdd'] =array('bgcolor'=>'#FFFFFF');
     $TableLayout['Row']['NormalEven']=array('bgcolor'=>'#F0F0F0');


      $TableLayout['Data']['Base']      =array('valign'=>'top', 'align'=>'left', 'nowrap'=>'nowrap');
      $TableLayout['Data']['TopOdd']    =array('bgcolor'=>'#FFFFFF');//array('bgcolor'=>'#F3F3F3');
      $TableLayout['Data']['TopEven']   =array('bgcolor'=>'#FFFFFF');//array('bgcolor'=>'#F3F3F3');
      $TableLayout['Data']['NormalOdd'] =array('bgcolor'=>'#FFFFFF');
      $TableLayout['Data']['NormalEven']=array('bgcolor'=>'#FFFFFF');


    global $Layout´DefaultLayout;
    $OldLayout=$Layout´DefaultLayout;
    $Layout´DefaultLayout=$TableLayout;

    $ProductTableTypes=FetchProductTableTypes($Language);

    $Globals=$ProductTableTypes['Types']['GLOBAL'];
    $UsedGlobals=array();

    Layout_TableStart();
        for ($i=1; $i<=$ProductTable['Height'];$i++) {
            Layout_TableRow(1);
                if ($i==1) {
                    Layout_TableData(1,array('rowspan'=>$ProductTable['Height'],
                                             'valign'=>'middle','style'=>'max-width: 200px; overflow: auto;'));
                        DisplayHeading(Message_Get($Language,'ProductName'));
                }
                foreach($ProductTable[$i] as $EntryId) {
                    Layout_TableData(1,array('rowspan'=>$ProductTable['Heights'][$EntryId],
                                             'colspan'=>$ProductTable['Widths'][$EntryId],
                                                     'align'  =>'center' ,
                                                     'valign' => (in_array($EntryId,$ProductTable['Leafs'])?'middle':'middle')  )
                                         );
                        DisplayHeading($ProductTable['Entries'][$EntryId]['Name'], in_array($EntryId,$ProductTable['Leafs']) and
                                                                                   ($ProductTable['Entries'][$EntryId]['TypeId']!="TEXT"));
                }
        }
        for ($i=0;$Product=$Products[$i];$i++) {
            Layout_TableRow();
                Layout_TableData(1,array('nowrap'=>'','style'=>'max-width: 200px; overflow: auto;'));
                    Print_S('<a href="'.$ProductLink.$Product['ProductId'].'" class="produktlink">'.Brake($Product['Name'],999999).'</a>');
                $ProductTableData=FetchMergedProductTableData($Product['LinkOfProductId']?$Product['LinkOfProductId']:$Product['ProductId'],$Language);
                foreach ($ProductTable['Leafs'] as $EntryId) {
                    if (in_array($ProductTableData[$EntryId]['ValueId'],$Globals) and
                       !in_array($ProductTableData[$EntryId]['ValueId'],$UsedGlobals))
                        $UsedGlobals[]=$ProductTableData[$EntryId]['ValueId'];
                    if ($ProductTable['Entries'][$EntryId]['TypeId']=="TEXT") {
                        $tmpStyle=array('align'=>'left','nowrap'=>'');
                    } else {
                        $tmpStyle=array('align'=>'center','nowrap'=>'nowrap');
                    }
                    Layout_TableData(0,$tmpStyle);
                        DisplayProductTableData($ProductTableId,$ProductTable['Entries'][$EntryId]['TypeId'],$ProductTableData[$EntryId],$Language,$ProductLink);
                }
        }
        for ($i=0;$Product=$AdditionalProducts[$i];$i++) {
            Layout_TableRow();
                Layout_TableData(1, array('bgcolor'=>"#F3F3F3",'class'=>"textgrau"));
                    Print_S('<a href="'.$ProductLink.$Product['ProductId'].'" class="textgrau">'.Brake($Product['Name'],25).'</a>');
                $ProductTableData=FetchMergedProductTableData($Product['LinkOfProductId']?$Product['LinkOfProductId']:$Product['ProductId'],$Language);
                foreach ($ProductTable['Leafs'] as $EntryId) {
                    if (in_array($ProductTableData[$EntryId]['ValueId'],$Globals) and
                       !in_array($ProductTableData[$EntryId]['ValueId'],$UsedGlobals))
                        $UsedGlobals[]=$ProductTableData[$EntryId]['ValueId'];
                    Layout_TableData(0, array('class'=>'textgrau', 'align'=>'center'));
                        DisplayProductTableData($ProductTableId,$ProductTable['Entries'][$EntryId]['TypeId'],$ProductTableData[$EntryId],$Language,$ProductLink);
                }
        }
    Layout_TableEnd();


//	Keys
    $DistinctEntryTypes=array();
    foreach($ProductTable['Leafs'] as $EntryId) {
        if (!in_array($ProductTable['Entries'][$EntryId]['TypeId'],$DistinctEntryTypes)) {
            $HasAtLeastOneKey=false;
            if (is_array($ProductTableTypes['Types'][$ProductTable['Entries'][$EntryId]['TypeId']])) {
                foreach ($ProductTableTypes['Types'][$ProductTable['Entries'][$EntryId]['TypeId']] as $ValueId) {
                    if ($ProductTableTypes['Keys'][$ValueId]!='')
                        $HasAtLeastOneKey=true;
                }
                if ($HasAtLeastOneKey)
                    $DistinctEntryTypes[]=$ProductTable['Entries'][$EntryId]['TypeId'];
            }
        }
    }
    $ProductTableTypes['Types']['usedglobals']=$UsedGlobals;
    if (count($UsedGlobals)>0) {
        $DistinctEntryTypes[]='usedglobals';
    }

//		echo "<pre>";print_r($DistinctEntryTypes);echo "</pre>";
    if (count($DistinctEntryTypes)>0) {
    Print_S('<br />');
    Print_S('<div align="left">');
        Print_I('<table cellspacing=0 cellpadding=0 border=0 width="100%">');
        $FirstRow=true;
        $KeyTableWidth=3;

        for ($i=0;$i<count($DistinctEntryTypes);) {
            Print_I('<tr valign="baseline" align="left">');
            Print_I('<td nowrap>');
            if ($FirstRow) {
                Print_S(htmlspecialchars(Message_Get($Language,'TableKey')).':');
            } else {
                Print_S('&nbsp;');
            }
            Print_O('</td>');
            for ($y=0;$y<$KeyTableWidth;$y++,$i++) {
                Print_I('<td nowrap>');
                    $First=true;
                    if (is_array($ProductTableTypes['Types'][$DistinctEntryTypes[$i]])) {
                        foreach($ProductTableTypes['Types'][$DistinctEntryTypes[$i]] as $ValueId) {
                            if ($ProductTableTypes['Keys'][$ValueId]!='') {
                                if ($First) $First=false;
                                else print_S('<br>');
                                print_S('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'.htmlspecialchars($ProductTableTypes['Values'][$ValueId]).' = '.htmlspecialchars($ProductTableTypes['Keys'][$ValueId]));
                            }
                        }
                    }
                    else {
                        print_S('&nbsp;');
                    }
                Print_O('</td>');
            }
            Print_O('</tr>');
        }

        Print_O('</table>');
        Print_S('</div>');
    }

//	Footnotes
    Print_S('<br />');
    Print_S('<div align="left">');

    DisplayProductTableFootnotes(FetchProductTableFootnotes($ProductTableId,$Language));
    Print_S('</div>');

    Print_S('<br />');

    $Layout´DefaultLayout=$OldLayout;
}

function DisplaySpecialType($SpecialType, $Type, $Id, $Language, $Active=false) {
    switch ($SpecialType) {
        case 'InfoPages':
            $InfoPages=FetchInfoPagesFor($Type,Environment_Read($Type.'Id'),$Language,$Active);
            if (count($InfoPages)>0) {
                Print_S('<span class="headfein"><b>'.htmlspecialchars(Message_Get($Language,'AdditionalInformation')).':</b></span><br />');
                $InfoPagesToImplode=array();
                for ($i=0;$InfoPage=$InfoPages[$i];$i++) {
                    $InfoPagesToImplode[]='<a href="Info.php?InfoId='.$InfoPage['InfoId'].'" class="produktlink">'.htmlspecialchars($InfoPage['Name']).'</a>';
                }
                Print_S(implode(", ",$InfoPagesToImplode).'<br /><br />');
            }
            break;
        case 'InterestingProducts':
            $Products=FetchInterestingProducts($Type,Environment_Read($Type.'Id'),$Language,$Active);
            error_log($Type." Count of Products:".count($Products));
            if (count($Products)>0) {
                Print_S('<span class="headfein"><b>'.htmlspecialchars(Message_Get($Language,'AdditionalProducts')).'</b><br /></span>');
                $ProductsToImplode=array();
                for ($i=0;$Product=$Products[$i];$i++) {
                    $ProductsToImplode[]='<a href="Product.php?ProductId='.$Product['ProductId'].'" class="produktlink">'.str_replace('_','&nbsp;',$Product['Name']).'</a>';
                }
                Print_S(implode(", ",$ProductsToImplode).'<br /><br />');
            }
            break;
        case 'CategoryProducts':
             Print_S(htmlspecialchars(Message_Get($Language,'CategoryProducts')).':<br>');
            $ProductsToImplode=array();
            $Products=FetchProducts(Environment_Read('CategoryId'),$Language,$Active);
            for ($i=0;$Product=$Products[$i];$i++) {
                 $ProductsToImplode[]='<a href="Product.php?ProductId='.$Product['ProductId'].'" class="produktlink">'.str_replace('_','&nbsp;',$Product['Name']).'</a>';
            }
            Print_S(implode(", ",$ProductsToImplode).'<br /><br />');
            break;
        case 'CategoryTable':
            Print_S('<br clear=all />');
            Print_S('<div align="left">');
            DisplayProductTable(Environment_Read('CategoryId'),$Language,'Product.php?ProductId=',$Active);
            Print_S('</div>');
            break;
        case 'DownloadPDF':
            global $Vegra_URLBase;
            Print_I('<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td>');
            Print_I('<table width="500" border="0" cellspacing="0" cellpadding="0" align="left">');
             Print_I('<tr>');
                  if ($Type=='Product') {
                    $PDFLink='/Utilities/CreateProductPDF.php?ProductId='.Environment_Read('ProductId');
                } else if ($Type=='Info') {
                    $PDFLink='/Utilities/CreateInfoPDF.php?InfoId='.Environment_Read('InfoId');
                } else if ($Type=='Category') {
                    $PDFLink='/Utilities/CreateCategoryPDF.php?CategoryId='.Environment_Read('CategoryId');
                }
                $PDFLink.='&Language='.$Language.'&Active='.$Active;
              Print_I('<td width="50" align="left">');
               Print_S('<a href="'.$PDFLink.'" target="_blank"><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/pdf_kl.gif" width="28" height="25" border="0"></a>');
              Print_O('</td>');
              Print_I('<td align="left">');
               Print_S('<a href="'.$PDFLink.'" class="underl" target="_blank">'.htmlspecialchars(Message_Get($Language,'DownloadPDF')).'</a>');
              Print_O('</td>');
             Print_O('</tr>');
            Print_O('</table>');
            Print_O('</td></tr></table>');
            break;
        case 'SecureSheet':
            global $Vegra_URLBase;
            Print_I('<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td>');
            Print_I('<table width="500" border="0" cellspacing="0" cellpadding="0" align="left">');
             Print_I('<tr>');
              Print_I('<td width="50" align="left">');
               Print_S('<a href="SecureSheet.php?CategoryId='.Environment_Read('CategoryId').'"><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/sicherheitsdatenblatt.gif" width="17" height="25" hspace="6" border="0"></a>');
              Print_O('</td>');
              if ($Type=='Product') {
                    $ProductData=FetchProductData(Environment_Read('ProductId'));
                    $SecureLink='SecureSheet.php?CategoryId='.$ProductData['CategoryId'].'&'.
                                    'ProductId='.Environment_Read('ProductId');
                } else {
                    $SecureLink='SecureSheet.php?CategoryId='.Environment_Read('CategoryId');
                }
              Print_I('<td align="left">');
               Print_S('<a href="'.$SecureLink.'" class="underl">'.htmlspecialchars(Message_Get($Language,'SecureSheet')).'</a>');
              Print_O('</td>');
             Print_O('</tr>');
            Print_O('</table>');
            Print_O('</td></tr></table>');
            break;
        case 'DownloadPDFAndSheet':
            global $Vegra_URLBase;
            Print_I('<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td>');
            Print_I('<table width="500" border="0" cellspacing="0" cellpadding="0" align="left">');
             Print_I('<tr>');
              Print_I('<td>');
               Print_S('<a href=""><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/pdf_kl.gif" width="28" height="25" border="0"></a>');
              Print_O('</td>');
              Print_I('<td>');
               Print_S('<a href="" class="underl">Download &Uuml;bersichtstabelle als PDF &gt;&gt;</a>');
              Print_O('</td>');
             Print_O('</tr>');
             Print_I('<tr>');
              Print_I('<td>');
               Print_S('<a href="SecureSheet.php?CategoryId='.Environment_Read('CategoryId').'"><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/sicherheitsdatenblatt.gif" width="17" height="25" hspace="6" border="0"></a>');
              Print_O('</td>');
              Print_I('<td>');
               Print_S('<a href="SecureSheet.php?CategoryId='.Environment_Read('CategoryId').'" class="underl">Sicherheitsdatenblatt anfordern (bitte ersetzen) &gt;&gt;</a>');
              Print_O('</td>');
             Print_O('</tr>');
            Print_O('</table>');
            Print_O('</td></tr></table>');
            Print_S('<br />');
            break;
        case 'DownloadPDFAndSheetProduct':
            global $Vegra_URLBase;
            Print_I('<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td>');
            Print_I('<table width="500" border="0" cellspacing="0" cellpadding="0" align="left">');
             Print_I('<tr>');
              Print_I('<td>');
               Print_S('<a href=""><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/pdf_kl.gif" width="28" height="25" border="0"></a>');
              Print_O('</td>');
              Print_I('<td>');
               Print_S('<a href="/Utilities/CreateProductPDF.php?ProductId='.Environment_Read('ProductId').'" class="underl">Download als PDF &gt;&gt;</a>');
              Print_O('</td>');
             Print_O('</tr>');
             Print_I('<tr>');
              Print_I('<td>');
                  $ProductData=FetchProductData(Environment_Read('ProductId'));
                  $SecureLink='SecureSheet.php?CategoryId='.$ProductData['CategoryId'].'&'.
                               'ProductId='.Environment_Read('ProductId');
               Print_S('<a href="'.$SecureLink.'"><img src="'.$Vegra_URLBase.'/images/bilder_dynamic/sicherheitsdatenblatt.gif" width="17" height="25" hspace="6" border="0"></a>');
              Print_O('</td>');
              Print_I('<td>');
               Print_S('<a href="'.$SecureLink.'" class="underl">Sicherheitsdatenblatt anfordern (bitte ersetzen) &gt;&gt;</a>');
              Print_O('</td>');
             Print_O('</tr>');
            Print_O('</table>');
            Print_O('</td></tr></table>');
            Print_S('<br />');
            break;
    }
}

function DisplayTextData($Type, $Id, $Language, $ShowSpecials=true, $Active=false, $ResolveLinkElements=true) {

    $IsLatin=($Language!='ru');

    $TextData=FetchTextData($Type, $Id,$Language,$ResolveLinkElements);

    if ($ResolveLinkElements==false) {
        $ParagraphCount=0;
    }

    $CurrentData=array('ParagraphId'=>'-1');
    while (is_array($TextData[$CurrentData['ParagraphId']])) {
        if ($ResolveLinkElements==false) {
            Print_S('<span style="font-size: 20px;">'.($ParagraphCount++).'</span>');
        }
        $CurrentData=$TextData[$CurrentData['ParagraphId']];
        if (!$CurrentData['SpecialType']) {
            if ($CurrentData['ParentParagraph']==-1) {
                Print_S('<span class="head">'.ParagraphParser($CurrentData['Heading'],$IsLatin).'</span><br><br>');
                Print_S(ParagraphParser($CurrentData['Paragraph'],$IsLatin).'<br><br>');
            } else {
                Print_S('<span class="headfein">'.ParagraphParser($CurrentData['Heading'],$IsLatin).'</span>');
                if ($CurrentData['Heading']!='') Print_S('<br>');
                $Paragraph=ParagraphParser($CurrentData['Paragraph'],$IsLatin);
                Print_S($Paragraph);
                if (substr($Paragraph,-8)!='</table>') {
                    Print_S('<br>');
                }
                if ($CurrentData['Paragraph']!='') Print_S('<br>');
            }
        } else {
            if ($ShowSpecials) {
                DisplaySpecialType($CurrentData['SpecialType'], $Type, $Id, $Language,$Active);
            } else {
                Print_S('&lt;'.$CurrentData['SpecialType'].'&gt;<br /><br />');
            }
        }
    }
}


function EditTextData($Type, $Id, $Language, $ShowSpecials=true, $AdminLanguage=array(), $MaxFormFieldWidth=80) {
    $IsLatin=($Language!='ru');

    if (is_array($AdminLanguage)) $AdminLanguage=$Language;


    $Table=$Type.'TextData';
    $Key=$Type.'Id';

    switch ($Type) {
        case 'Product':
            $PossibleSpecials=array('InterestingProducts','InfoPages','DownloadPDF','SecureSheet'); // include 'TextFromOtherProduct' again if you want to activate this feature
            $Result=mysql_query($Query="SELECT ProductId FROM ProductTextData WHERE Language='$Language' AND Heading LIKE '$Id' AND SpecialType = 'TextFromOtherProduct'");
            if ($Result and mysql_num_rows($Result)>0) {
                Print_S('Achtung: Produkttext wird referenziert von: ');
                $ReferencingProductIds=array();
                while ($Row=mysql_fetch_assoc($Result)) {
                    $ReferencingProductIds[]=$Row['ProductId'];
                }
                $ReferencingProducts=FetchProductsWithIds($ReferencingProductIds,$Language,false);
                $ProductHTML = array();
                foreach($ReferencingProducts as $ProductHash) {
                    error_log("hurz");
                    $ProductHTML[]='<a href="Product.php?ProductId='.$ProductHash['ProductId'].'">'.str_replace('_','&nbsp;',htmlentities($ProductHash['ProductName'])).'</a>';
                }
                Print_S(@implode(', ',$ProductHTML).'<br />');
            }
            break;
        case 'Category':
            $PossibleSpecials=array('InterestingProducts','CategoryTable','InfoPages','CategoryProducts','DownloadPDF','SecureSheet');
            break;
        case 'Info':
            $PossibleSpecials=array('DownloadPDF');
            break;
        default:
            $PossibleSpecials=array();
            break;
    }



    $Baselink='?'.$Key.'='.$Id;

    if (Environment_Read('Action')=='ChangeParagraph') {
        $Query='UPDATE '.$Table." SET Heading='".Environment_Read('Heading','pg',Environment_Quoted)."'".",".
                                     "Paragraph='".Environment_Read('Paragraph','pg',Environment_Quoted)."' ".
                                       " WHERE ParagraphId=".Environment_Read('ParagraphId');
        if (!mysql_query($Query)) {
            Print_S('<b>Fehler bei: <pre>'.$Query.'</pre></b>');
        }
    }

    if (Environment_Read('Action')=='ChangeTextFromOtherProduct') {
        $Query='UPDATE '.$Table." SET Heading='".Environment_Read('ProductIdOfOtherProduct','pg',Environment_Quoted)."'".",".
                                     "Paragraph='".Environment_Read('BeginningFromParagraphNumber','pg',Environment_Quoted)."' ".
                                       " WHERE ParagraphId=".Environment_Read('ParagraphId');
        if (!mysql_query($Query)) {
            Print_S('<b>Fehler bei: <pre>'.$Query.'</pre></b>');
        }
    }

    if (Environment_Read('Action')=='AddParagraph') {
        $Query='INSERT INTO '.$Table.' ('.$Key.',Language,ParentParagraph,Heading,Paragraph) '.
               'VALUES ('.$Id.','.
                           "'".$Language."'".",".
                              Environment_Read('ParentParagraph').",".
                              "'".Environment_Read('Heading','pg',Environment_Quoted)."'".",".
                              "'".Environment_Read('Paragraph','pg',Environment_Quoted)."'".")";
        if (!mysql_query($Query)) {
            Print_S('<b>Fehler bei: <pre>'.$Query.'</pre></b>');
        }
    }

    if (Environment_Read('Action')=='AddSpecial') {
        $Query='INSERT INTO '.$Table.' ('.$Key.',Language,ParentParagraph,Heading,Paragraph,SpecialType) '.
               'VALUES ('.$Id.','.
                           "'".$Language."'".",".
                              Environment_Read('ParentParagraph').",".
                              "''".",".
                              "''".",".
                              "'".Environment_Read('SpecialType')."'".")";
        if (!mysql_query($Query)) {
            Print_S('<b>Fehler bei: <pre>'.$Query.'</pre></b>');
        }
    }


    if (Environment_Read('Action')=='MoveDown') {
        if ($Result=mysql_query('SELECT * FROM '.$Table.' WHERE ParagraphId='.Environment_Read('ParagraphId'))) {
            $Entry1=mysql_fetch_assoc($Result);
            if ($Entry1['ParentParagraph']!=-1) {
                if ($Result=mysql_query('SELECT * FROM '.$Table.' '.
                                         'WHERE ParentParagraph='.Environment_Read('ParagraphId'))) {
                    if ($Entry2=mysql_fetch_assoc($Result)) {
                        mysql_query('UPDATE '.$Table.' SET ParentParagraph='.$Entry1['ParagraphId'].' '.
                                     'WHERE ParentParagraph='.$Entry2['ParagraphId']);
                        mysql_query('UPDATE '.$Table.' SET ParentParagraph='.$Entry2['ParagraphId'].' '.
                                     'WHERE ParagraphId='.$Entry1['ParagraphId']);
                        mysql_query('UPDATE '.$Table.' SET ParentParagraph='.$Entry1['ParentParagraph'].' '.
                                     'WHERE ParagraphId='.$Entry2['ParagraphId']);
                    }
                }
            }
        }
    }

    if (Environment_Read('Action')=='RemoveParagraph') {
        if ($Result=mysql_query('SELECT * FROM '.$Table.' WHERE ParagraphId='.Environment_Read('ParagraphId'))) {
            if ($Entry=mysql_fetch_assoc($Result)) {
                mysql_query('UPDATE '.$Table.' SET ParentParagraph='.$Entry['ParentParagraph'].' '.
                             'WHERE ParentParagraph='.$Entry['ParagraphId']);
                mysql_query('DELETE FROM '.$Table.' WHERE ParagraphId='.$Entry['ParagraphId']);
            }
        }
    }

    $TextData=FetchTextData($Type, $Id,$Language,false);

    if (!is_array($TextData['-1'])) {
        $Query='INSERT INTO '.$Table.' ('.$Key.',Language,ParentParagraph,Heading,Paragraph) '.
               'VALUES ('.$Id.','.
                           "'".$Language."'".",".
                              "-1,".
                              "'--'".",".
                              "'')";
        if (!mysql_query($Query)) {
            Print_S('<b>Fehler bei: <pre>'.$Query.'</pre></b>');
        }
        $TextData    =FetchTextData($Type, $Id,$Language);
    }

    Layout_TableStart();
        Layout_TableRow();
            Layout_TableData();
            Layout_TableData();

//		$CurrentData=$TextData['-1'];

    $CurrentData=array('ParagraphId'=>'-1');

    while (is_array($TextData[$CurrentData['ParagraphId']])) {
        $CurrentData=$TextData[$CurrentData['ParagraphId']];
        layout_TableRow();
            Layout_TableData(0,array('align'=>'right','nowrap'=>'nowrap'));
                if (Environment_Read('Action')    =='DeleteParagraph' &&
                    Environment_Read('ParagraphId')==$CurrentData['ParagraphId']) {
                    $ControlString='<a href="'.$Baselink.'">'.htmlentities(Message_Get($AdminLanguage,"AdminDontRemove")).'</a>';
                    $ControlString.='<br><a href="'.$Baselink.'&Action=RemoveParagraph'.
                                                                        '&ParagraphId='.$CurrentData['ParagraphId'].
                                                                        '">'.htmlentities(Message_Get($AdminLanguage,"AdminReallyRemove")).'</a>';
                }
                else {
                    $ControlString='';
                    if ($CurrentData['ParentParagraph']!=-1) {
                        $ControlString.='<a href="'.$Baselink.'&Action=MoveDown'.
                                                                '&ParagraphId='.$CurrentData['ParentParagraph'].
                                                                '">^</a>';
                        $ControlString.='/';
                        $ControlString.='<a href="'.$Baselink.'&Action=MoveDown'.
                                                                '&ParagraphId='.$CurrentData['ParagraphId'].
                                                                '">v</a>';
                    }
                    $ControlString.='&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                    if (!$CurrentData['SpecialType']) {
                        $ControlString.='<a href="'.$Baselink.'&Action=EditParagraph'.
                                                                            '&ParagraphId='.$CurrentData['ParagraphId'].
                                                                            '">'.htmlentities(Message_Get($AdminLanguage,"AdminChange")).'</a>';
                    }
                    else {
                        $ControlString.='&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                        $ControlString.='&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                        $ControlString.='&nbsp;&nbsp;&nbsp;';
                    }
                    if ($CurrentData['ParentParagraph']!=-1) {
                        $ControlString.='<br><a href="'.$Baselink.'&Action=DeleteParagraph'.
                                                                            '&ParagraphId='.$CurrentData['ParagraphId'].
                                                                            '">'.htmlentities(Message_Get($AdminLanguage,"AdminRemove")).'</a>';
                    }
                }
                Print_S($ControlString);
            layout_TableData(0,array('bgcolor'=>'#FFFFF'));
                if ($CurrentData['SpecialType']) {
                    if ($CurrentData['SpecialType']=='TextFromOtherProduct') {
                        $OtherProductId=$CurrentData['Heading'];
                        $StartParagraph=$CurrentData['Paragraph'];
                        Print_I('<form name="f" method="post" action="'.$Baselink.'&Action=ChangeTextFromOtherProduct">');
                        Print_S('<input type="hidden" name="ParagraphId" value="'.$CurrentData['ParagraphId'].'">');
                        // show product selector
                        Print_S(htmlentities(Message_Get($AdminLanguage,"AdminProductIdOfOtherProduct")).'(Produktquelle): '.ProductSelector('ProductIdOfOtherProduct',$OtherProductId));
                        // show paragraph selector for that product
                        Print_S(htmlentities(Message_Get($AdminLanguage,"AdminBeginningFromParagraphNumber")).'(Ab Absatz Nummer): '.NumberSelector('BeginningFromParagraphNumber',$StartParagraph,1,40));
                        // show textdata for that product
                        Print_S('<input type="submit" name="submit" value="'.htmlentities(Message_Get($AdminLanguage,"AdminChange")).'">');
                        Print_O('</form>');
                        Print_S('<a href="Product.php?ProductId='.$OtherProductId.'" target="_blank">(zeige Produkt)</a><br />');
                        DisplayTextData('Product',$OtherProductId,$Language,false,false,false);
                    } else {
                        if ($ShowSpecials) {
                            DisplaySpecialType($CurrentData['SpecialType'],$Type,$Id,$Language);
                        } else {
                            Print_S('&lt;'.$CurrentData['SpecialType'].'&gt;');
                        }
                    }
                    $PossibleSpecials=array_diff($PossibleSpecials,array($CurrentData['SpecialType']));
                } else if (Environment_Read('Action')=='EditParagraph' &&
                      Environment_Read('ParagraphId')==$CurrentData['ParagraphId']) {
                    Print_I('<form name="f" method="post" action="'.$Baselink.'&Action=ChangeParagraph">');
                        Print_S('<input type="hidden" name="ParagraphId" value="'.$CurrentData['ParagraphId'].'">');
                        Print_S(htmlentities(Message_Get($AdminLanguage,"AdminHeading")).': <input type="text" name="Heading" size="'.min($MaxFormFieldWidth-10,max($MaxFormFieldWidth-30,strlen($CurrentData['Heading']))).'" value="'.str_replace('"','""',$CurrentData['Heading']).'"><br>');
                        Print_S(htmlentities(Message_Get($AdminLanguage,"AdminParagraph")).':<br><textarea rows='.max(5,
                                                                  intval(strlen($CurrentData['Paragraph'])/$MaxFormFieldWidth),
                                                                                substr_count($CurrentData['Paragraph'],"\n") ).
                                                                      ' cols="'.$MaxFormFieldWidth.'" name="Paragraph" wrap>'.$CurrentData['Paragraph'].'</textarea><br>');
                        Print_S('<input type="submit" name="submit" value="'.htmlentities(Message_Get($AdminLanguage,"AdminChange")).'">');
                    Print_O('</form>');
                    Print_S('<script>document.f.Heading.scrollIntoView();</script>');
                    Print_S('<script>document.f.Heading.focus();</script>');
                } else if ($CurrentData['ParentParagraph']==-1) {
                    Print_S('<span class="head">'.ParagraphParser($CurrentData['Heading'],$IsLatin).'</span><br><br>');
                    Print_S(ParagraphParser($CurrentData['Paragraph'],$IsLatin).'<br><br>');
                } else {
                    Print_S('<span class="headfein">'.ParagraphParser($CurrentData['Heading'],$IsLatin).'</span>');
                    if ($CurrentData['Heading']!='') Print_S('<br>');
                    Print_S(ParagraphParser($CurrentData['Paragraph'],$IsLatin).'<br>');
                    if ($CurrentData['Paragraph']!='') Print_S('<br>');
                }
    }

    Layout_TableRow();
        Layout_TableData();
            if (Environment_Read('Action')=='NewParagraph') {
                Print_S(htmlentities(Message_Get($AdminLanguage,"AdminNewParagraph")).':');
            }
        Layout_TableData();

            if (Environment_Read('Action')=='NewParagraph') {
                Print_I('<form method="post" action="'.$Baselink.'&Action=AddParagraph" name=f>');
                    Print_S('<input type="hidden" name="ParentParagraph" value="'.$CurrentData['ParagraphId'].'">');
                    Print_S(htmlentities(Message_Get($AdminLanguage,"AdminHeading")).': <input type="text" name="Heading" size="'.($MaxFormFieldWidth-20).'"><br>');
                    Print_S('<script>document.f.Heading.focus();</script>');
                    Print_S(htmlentities(Message_Get($AdminLanguage,"AdminParagraph")).':<br><textarea rows=5 cols="'.$MaxFormFieldWidth.'" name="Paragraph" wrap></textarea><br>');
                    Print_S('<input type="submit" name="submit" value="'.htmlentities(Message_Get($AdminLanguage,"AdminAdd")).'">');
                Print_O('</form>');
            }
            else {
                Print_S('<a href="'.$Baselink.'&Action=NewParagraph">'.htmlentities(Message_Get($AdminLanguage,"AdminNewParagraph")).'</a><br>');
                if (count($PossibleSpecials)>0) {
                    foreach($PossibleSpecials as $Special) {
                        Print_S('<a href="'.$Baselink.'&Action=AddSpecial&SpecialType='.$Special.'&ParentParagraph='.$CurrentData['ParagraphId'].'">'.htmlentities(Message_Get($AdminLanguage,"AdminAddThing",array($Special))).'</a><br>');
                    }
                }
            }

    Layout_TableEnd();
}

function InfoIds($Type, $Id, $Language,$Active=false) {
    // error_log("InfoIds: ".$Type.$Id.$Language.($Active?"true":"false"));
    $Return=array();
    $TextData=FetchTextData($Type,$Id,$Language);
    $CurrentData=array('ParagraphId'=>'-1');

    while (is_array($TextData[$CurrentData['ParagraphId']])) {
        $CurrentData=$TextData[$CurrentData['ParagraphId']];
        if ($CurrentData['SpecialType']=='InfoPages') {
         error_log("found InfoPages");
            $InfoPages=FetchInfoPagesFor($Type,$Id,$Language,$Active);
            foreach ($InfoPages as $InfoPage) {
            //    error_log("found page:".$InfoPage['InfoId']." withName:".$InfoPage['Name']);
                $Return[$InfoPage['InfoId']." "]=$InfoPage['Name'];
            }
        }
    }
    return $Return;
}


// TextData Data structure
//  $Result[<Id of ParentParagraph>] => <ChildParagraph>
//  $Result['ParagraphIndexes']      => <Array with all the paragraph indexes in order>
//  '-1' is the parent Id of the first paragraph

function FetchTextData($Type, $Id, $Language, $ResolveLinkElements = true) {
    $Table=$Type.'TextData';
    $Key=$Type.'Id';
    $Return=array();
    $Result=mysql_query($Query='SELECT * FROM '.$Table.' '.
                         'WHERE '.$Key.'='.$Id." AND Language='".$Language."'");
    if ($Result) {
        while ($Row=mysql_fetch_assoc($Result)) {
            $Return[$Row['ParentParagraph']]=$Row;
        }
    
        $ParagraphIndexes=array();
        
        $ParagraphIndex="-1";
        $Data=$Return[$ParagraphIndex];
        do {
            if ($Data['SpecialType']=='TextFromOtherProduct' and 
                $ResolveLinkElements) {
                //error_log('Found TextFromOtherProduct');
                $OtherProductData = FetchTextData($Type, $Data['Heading'],$Language,false);
                $OtherIndexes=$OtherProductData['ParagraphIndexes'];
                $StartIndex=$Data['Paragraph'];
                $SubIndex=$OtherIndexes[$StartIndex];
                //error_log(@implode(',',$OtherIndexes));
                //error_log("Found ".$Data['Heading']." $OtherProductData $OtherIndexes $StartIndex and $SubIndex");
                if ($StartIndex and $SubIndex) {
                    $InnerData=$OtherProductData[$SubIndex];
                    $InnerData['ParentParagraph']=$ParagraphIndex;
                    while (is_array($InnerData)) {
                        $InnerIndex=$InnerData['ParentParagraph'];
                        $Return[$InnerIndex]=$InnerData;
                        $ParagraphIndexes[]=$InnerIndex;
                        $InnerData=$OtherProductData[$InnerData['ParagraphId']];
                    }
                    
                }
                $ParagraphIndex=$Data['ParagraphId'];
                $Data=$Return[$ParagraphIndex];
                if (is_array($Data)) {
                    unset($Return[$ParagraphIndex]);
                    $Data['ParentParagraph']=$Return[$InnerIndex]['ParagraphId'];
                    $ParagraphIndex=$Data['ParentParagraph'];
                    $Return[$ParagraphIndex]=$Data;
                }
            } else {
                $ParagraphIndexes[]=$ParagraphIndex;
                $ParagraphIndex=$Data['ParagraphId'];
                $Data=$Return[$ParagraphIndex];
            }
        } while (is_array($Data));
        
        //error_log(@implode(',',$ParagraphIndexes).' keys '.@implode(',',array_keys($Return)));
        $Return['ParagraphIndexes']=$ParagraphIndexes;
    } else {
        error_log("FetchTextData($Type, $Id, $Language,$ResolveLinkElements) did encounter invalid result for $Query");
    }
    return $Return;
}

//- mark -
function IconLocationForCategoryId_AsURL($CategoryId,$isURL=true) {
    global $Vegra_FileBase;
    $URLBase='/Pictures/';
    $Name='CategoryIcon'.$CategoryId.'.jpg';
    $Path=$Vegra_FileBase.$URLBase.$Name;
    if (!$isURL) {
        return $Path;
    } else {
        if (is_readable($Path)) {
            return $URLBase.$Name;
        } else {
            return '';
        }
    }
}

function IconImageTagForCategoryId($CategoryId) {
    $URL=IconLocationForCategoryId_AsURL($CategoryId,true);
    $Result='';
    if ($URL) {
        $Result='<img src="'.$URL.'" alt="CategoryIcon'.$CategoryId.'" />';
    }
    return $Result;
}

//- mark -
//- mark ProductTable

function FetchProductTableTypes($Language) {
    $Result=mysql_query('SELECT * FROM ProductTableEntryTypeValue, ProductTableEntryTypeValueLanguage '.
                        'WHERE ProductTableEntryTypeValue.ValueId=ProductTableEntryTypeValueLanguage.ValueId '.
                                    "AND Language='".$Language."' ".
                              'ORDER BY TypeId ASC,Position ASC');
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return['Types'][$Row['TypeId']][]=$Row['ValueId'];
    }
    $Result=mysql_query('SELECT * FROM ProductTableEntryTypeValueLanguage '.
                        "WHERE Language='".$Language."' ");
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return['Values'][$Row['ValueId']]=$Row['Name'];
    }
    $Result=mysql_query('SELECT * FROM ProductTableEntryTypeKeyLanguage '.
                        "WHERE Language='".$Language."' ");
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return['Keys'][$Row['ValueId']]=$Row['Name'];
    }
    return $Return;
}



function FetchProductTableFootnotes($ProductTableId,$Language) {
    $Return=array();
    $Result=mysql_query('SELECT ProductTableFootnote.FootnoteId, Name '.
                          'FROM ProductTableFootnote,ProductTableFootnoteLanguage '.
                                'WHERE ProductTableId='.$ProductTableId." AND Language='".$Language."'".' '.
                                      'AND ProductTableFootnote.FootnoteId=ProductTableFootnoteLanguage.FootnoteId '.
                            'ORDER BY Position ASC');
    if ($Result) {
        while ($Row=mysql_fetch_assoc($Result)) {
            $Return[]=$Row;
        }
    }
    return $Return;
}



function FetchProductTableData($ProductId) {
    $Result=mysql_query('SELECT * FROM ProductTableData WHERE ProductId='.$ProductId);
    $Return=array();
    while ($Row=mysql_fetch_assoc($Result)) {
        $Row['isData']=true;
        $Return[$Row['EntryId']]=$Row;
    }
    return $Return;
}

function FetchProductTableTextData($ProductId,$Language) {
    $Result=mysql_query('SELECT * FROM ProductTableTextData WHERE ProductId='.$ProductId." AND Language='".$Language."'");
    $Return=array();
    while ($Row=mysql_fetch_assoc($Result)) {
        $Row['isText']=true;
        $Return[$Row['EntryId']]=$Row;
    }
    return $Return;
}

function FetchProductTableDataToFootnotes($ProductId, $ProductArray=array()) {
    $Result=mysql_query('SELECT * FROM ProductTableDataToFootnote as dtf, ProductTableFootnote as f WHERE f.FootnoteId=dtf.FootnoteId AND dtf.ProductId='.$ProductId.' ORDER BY Position ASC');
    foreach($ProductArray as $EntryId => $Value) {
        $ProductArray[$EntryId]['FootnoteIds']=array();
    }
    if ($Result) {
        while ($Row=mysql_fetch_assoc($Result)) {
            if ($ProductArray[$Row['EntryId']]) {
                $ProductArray[$Row['EntryId']]['FootnoteIds'][]=$Row['FootnoteId'];
            }
        }
    }
    return $ProductArray;
}

function FetchMergedProductTableData($ProductId,$Language) {
    $TableData    =FetchProductTableData($ProductId);
    $TableData    =FetchProductTableDataToFootnotes($ProductId, $TableData);
    $TableTextData=FetchProductTableTextData($ProductId,$Language);
    foreach ($TableTextData as $Id => $Data) {
        if ($TableData[$Id]) {
            $TableData[$Id] = array_merge($TableData[$Id], $Data);
        } else {
            $TableData[$Id] = $Data;
        }
    }
    return $TableData;
}

function FetchProductTable($ProductTableId,$Language) {
    $Result=mysql_query('SELECT * FROM ProductTableEntry, ProductTableEntryLanguage '.
                              " WHERE ProductTableEntry.EntryId=ProductTableEntryLanguage.EntryId ".
                                     "AND ProductTableId=".$ProductTableId." AND Language='".$Language."' ".
                            "ORDER BY Position ASC");
    if (!$Result) return array('Leafs'=>array(),'Entries'=>array());
    $Leafs=array();
    $Entries=array();
    while ($Row=mysql_fetch_assoc($Result)) {
        $Entries[$Row['EntryId']]=$Row;
          $Width[$Row['EntryId']]=0;
        $Children[$Row['FatherEntryId']][]=$Row['EntryId'];
        if ($Row['TypeId']!='') {
           $Width[$Row['EntryId']]=1;
            $Leafs[$Row['Position']]=$Row['EntryId'];
        }
    }

    $LevelArray=$Leafs;
    $MaxLevel=0;
    while (count($LevelArray)>0) {
        $NewLevelArray=array();
        foreach($LevelArray as $EntryId) {
            if ($Entries[$EntryId]['FatherEntryId']!=-1) {
                $NewLevelArray[$Entries[$EntryId]['FatherEntryId']]=++$blah;
                $Width[$Entries[$EntryId]['FatherEntryId']]+=$Width[$EntryId];
            }
        }
        $LevelArray=array_flip($NewLevelArray);
        $MaxLevel++;
    }

    $Return['Height'] =$MaxLevel;
    $Return['Entries']=$Entries;
    $Return['Widths'] =$Width;
    $Return['Leafs']  =$Leafs;

    $LevelArray=$Children['-1'];

    for ($i=1;$i<=$MaxLevel;$i++) {
        $NewLevelArray=array();
        foreach($LevelArray as $EntryId) {
            if (is_array($Children[$EntryId])) $NewLevelArray=array_merge($NewLevelArray,$Children[$EntryId]);
            if (!is_array($Children[$EntryId]) || count($Children[$EntryId])==0) {
                $Height[$EntryId]=$MaxLevel-$i+1;
            }
            else {
                $Height[$EntryId]=1;
            }
            $Return[$i][$Entries[$EntryId]['Position']]=$EntryId;
        }
        $LevelArray=$NewLevelArray;
    }
    $Return['Heights']=$Height;
    return $Return;
}

function FetchCategoryWithId($CategoryId,$Language,$Active=false) {
    $Query="SELECT Category.CategoryId,Position,Name,ParentId ".
                              "  FROM Category, CategoryLanguage ";
    if ($Active) $Query.=',CategoryStatus ';
    $Query.=" WHERE CategoryLanguage.Language='".$Language."' and Category.CategoryId = CategoryLanguage.CategoryId ";
    if ($Active) $Query.=" AND CategoryStatus.CategoryId=Category.CategoryId AND CategoryStatus.Language='".$Language."' AND CategoryStatus.Active=1";
    $Query.=" AND Category.CategoryId=".$CategoryId;
    $Result=mysql_query($Query);
    $Row=@mysql_fetch_assoc($Result);
    return is_array($Row)?$Row:array();
}

function IrrelevantDisplayCompareFunction($a,$b) {
    $aValue=$a['DisplayPosition'];
    $bValue=$b['DisplayPosition'];
    if ($aValue==$bValue) return 0;
    if ($aValue<$bValue) return -1;
    return 1;
}

function FetchCategories($Language,$Active=false) {
    $Query="SELECT Category.CategoryId,Position,Name,ParentId,DisplayPosition ".
                              "  FROM Category, CategoryLanguage ";
    if ($Active) $Query.=',CategoryStatus ';
    $Query.=" WHERE CategoryLanguage.Language='".$Language."' and Category.CategoryId = CategoryLanguage.CategoryId ";
    if ($Active) $Query.=" AND CategoryStatus.CategoryId=Category.CategoryId AND CategoryStatus.Language='".$Language."' AND CategoryStatus.Active=1";
    $Query.=" ORDER BY Position ASC";
    $Result=mysql_query($Query);
    $Categories=array();
    while ($Row=mysql_fetch_assoc($Result)) {
        $Categories[$Row['ParentId']][]=$Row;
        $Categories['ById'][$Row['CategoryId']]=$Row;
    }
    $DisplayCategories=$Categories['-1'];
    usort($DisplayCategories,'IrrelevantDisplayCompareFunction');
    $Categories['DisplayCategories']=$DisplayCategories;
    return $Categories;
}

function FetchProductData($ProductId) {
    $Result=mysql_query("SELECT * FROM Product WHERE ProductId=".$ProductId);
    $Row=@mysql_fetch_assoc($Result);
    return $Row?$Row:array();
}

function NormalizedProductIdForProductId($ProductId) {
  static $LinkedProducts = NULL;
  if ($LinkedProducts === NULL) {
    $LinkedProducts = array();
    $Query='SELECT ProductId,LinkOfProductId FROM Product WHERE LinkOfProductId IS NOT NULL';
    $Result = mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
      $LinkedProducts[$Row['ProductId']]=$Row['LinkOfProductId'];
    }
  }
  while ($LinkedProducts[$ProductId]) {
    $ProductId = $LinkedProducts[$ProductId];
  }
  return $ProductId;
}

function FetchProducts($CategoryId, $Language, $Active=true, $ProductIdArray=array()) {
    $Return=array();
    $Query='SELECT Product.ProductId,Product.LinkOfProductId,CategoryId,Position,Name '.
                          'FROM Product, ProductLanguage ';
    if ($Active) $Query.=',ProductStatus ';
    $Query.='WHERE CategoryId='.$CategoryId.' AND Product.ProductId=ProductLanguage.ProductId '.
                                      " AND ProductLanguage.Language='".$Language."' ";
    if ($Active) $Query.=" AND ProductStatus.ProductId=Product.ProductId AND ProductStatus.Language='".$Language."' AND ProductStatus.Active=".($Active?1:0)." ";
    $Query.='ORDER BY Position ASC';
    $Result=mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
        if (in_array($Row['ProductId'],$ProductIdArray) || count($ProductIdArray)==0) {
            $Return[]=$Row;
            $Return['ById'][$Row['ProductId']]=$Row;
            // if (count($ProductIdArray)>0) error_log("Product ".$Row['ProductId']." returned");
        }
    }
    return $Return;
}

function SearchFor($String,$Language,$Active=false) {
    $Return=array();
    $String=addslashes($String);
    $String=str_replace('%','\%',$String);
    $Words=explode(" ",$String);

    $ReallyFoundProduct=array();

    $First=true;
    foreach($Words as $Word) {
        $FoundProducts=array();

        $SearchExpression="'%".$Word."%'";

        $Result=mysql_query($Query="SELECT DISTINCT ProductId FROM ProductTextData ".
                                 "WHERE Language='".$Language."' AND ".
                                 "(Heading LIKE ".$SearchExpression." OR Paragraph LIKE ".$SearchExpression.")");
//			echo '<pre>'.$Query.'</pre>';
        if ($Result) {
            while (list($ProductId)=mysql_fetch_row($Result)) {
                $FoundProducts[$ProductId]='YES';
            }
        }

        $Result=mysql_query($Query="SELECT DISTINCT ProductId FROM ProductLanguage ".
                                 "WHERE Language='".$Language."' AND ".
                                 "Name LIKE ".$SearchExpression);
//			echo '<pre>'.$Query.'</pre>';
        if ($Result) {
            while (list($ProductId)=mysql_fetch_row($Result)) {
                $FoundProducts[$ProductId]='YES';
            }
        }

        if ($First) {
            $ReallyFoundProducts=$FoundProducts;
            $First=false;
        } else {
            $FoundProductsOld=$ReallyFoundProducts;
            $ReallyFoundProducts=array();
            foreach ($FoundProducts as $ProductId=>$DontCare) {
                if ($FoundProducts[$ProductId]=='YES' and $FoundProductsOld[$ProductId]=='YES')
                    $ReallyFoundProducts[$ProductId]='YES';
            }
        }
    }

    if (count($ReallyFoundProducts)>0) {
        $Return=FetchProductsWithIds(array_keys($ReallyFoundProducts), $Language,$Active);
    }
    return $Return;
}

function FetchProductsWithIds($ProductIds, $Language, $Active=true) {
    $Return=array();

    $Query='SELECT c1l.name,c1.CategoryId,c2l.name,c2.CategoryId,pl.Name,p.ProductId '.
                          ' FROM Product as p, ProductLanguage as pl, Category as c1, CategoryLanguage as c1l, Category as c2, CategoryLanguage as c2l';
    if ($Active) $Query.=', ProductStatus as ps';
    $Query.=             ' WHERE p.ProductId IN ('.implode(",",$ProductIds).') '.
                                      " AND pl.Language='".$Language."' AND c1l.Language='".$Language."'AND c2l.Language='".$Language."' ".
                                        " AND p.ProductId=pl.ProductId AND c1.CategoryId=c1l.CategoryId AND c2.CategoryId=c2l.CategoryId ".
                                        " AND p.CategoryId=c2.CategoryId AND c2.ParentId=c1.CategoryId ";
    if ($Active) $Query.=" AND ps.ProductId=p.ProductId AND ps.Language='".$Language."' AND ps.Active=1 ";
    $Query.=            'ORDER BY c1.Position ASC,c2.Position ASC,p.Position ASC';

    $Result=mysql_query($Query);
    // error_log("$Query");
    while ($Row=mysql_fetch_row($Result)) {
        $Return[]=array('MainCategoryName'=>$Row[0],
                             'MainCategoryId'  =>$Row[1],
                             'SubCategoryName'=>$Row[2],
                             'SubCategoryId'  =>$Row[3],
                             'ProductName'    =>$Row[4],
                             'ProductId'      =>$Row[5]);
    }

    return $Return;
}

function EditTranslationStatus($BaseUrl,$Type,$Id,$Language,$AdminLanguage=array()) {

    if (is_array($AdminLanguage)) $AdminLanguage=$Language;

    if (Environment_Read('Action')=='ChangeStatus'.$Type.$Id) {
        $NewStatus=array('Translated'=>(Environment_Read('Translated'.$Type.$Id)?1:0),
                             'Active'=>(Environment_Read('Active'    .$Type.$Id)?1:0));
        UpdateStatus($Type,$Id,$Language,$NewStatus);
    }

    $Status=array('Active'=>0,'Translated'=>0,'Required'=>0);
    $Result=@mysql_query($Query="Select * from ".$Type."Status WHERE ".$Type."Id=".$Id." AND Language='".$Language."'");
    while ($Row=mysql_fetch_assoc($Result)) {
        $Status=$Row;
    }

    $String.='<form action="'.$BaseUrl.'" method="post">';
      $String.='<input type="hidden" name="Action" value="ChangeStatus'.$Type.$Id.'">';
      $String.=htmlentities(Message_Get($AdminLanguage,'AdminStatus')).': ';
      $String.=htmlentities(Message_Get($AdminLanguage,'AdminTranslated')).'? <input type="checkbox" name="Translated'.$Type.$Id.'" value="YES"'.($Status['Translated']?' checked':'').'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      $String.=htmlentities(Message_Get($AdminLanguage,'AdminOnline')).'? <input type="checkbox" name="Active'.$Type.$Id.'" value="YES"'.($Status['Active']?' checked':'').'>&nbsp;&nbsp;&nbsp;';
      $String.='<input type="submit" value="'.htmlentities(Message_Get($AdminLanguage,"AdminChange")).'">';
    $String.='</form>';
    Print_S($String);
}

function UpdateStatus($Type,$Id,$Language,$ItemsToChange) {
    $New=true;
    $ItemState=array('Active'=>0,'Translated'=>0,'Required'=>0);
    $Result=@mysql_query($Query="Select * from ".$Type."Status WHERE ".$Type."Id=".$Id." AND Language='".$Language."'");
//		echo "<pre>".$Query."</pre>";
    while ($Row=mysql_fetch_assoc($Result)) {
        $New=false;
        $ItemState=$Row;
    }
    if ($Type == 'Product') {
        $Clearcache = $New;
        if (!$New) {
            foreach ($ItemsToChange as $Key => $Value) {
                if ($ItemState[$Key] != $Value) {
                    // error_log("$Key: $ItemState[$Key] != $Value"); //DEBUG
                    $Clearcache = true;
                }
            }
        }
        if ($Clearcache) {
            list($CategoryId)=@mysql_fetch_row(@mysql_query('SELECT CategoryId FROM Product WHERE ProductID='.$Id));
            ChangedContent('Product',$Id,$Language);
            ChangedContent('Category',$CategoryId,$Language);
            //error_log('Cleared cache for Cateogry Id: '.$CategoryId.' Language:'.$Language.' Product:'.$Id); //DEBUG
        }
    }
    $ItemState=array_merge($ItemState,$ItemsToChange);
    if ($New) {
        $Query="INSERT INTO ".$Type."Status (".$Type."Id,Language,Required,Translated,Active) ".
               "VALUES (".$Id.", '".$Language."', ".$ItemState['Required'].",
                          ".$ItemState['Translated'].", ".$ItemState['Active'].");";
    } else {
        $Query="UPDATE ".$Type."Status SET Required=".$ItemState['Required']." , Translated=".$ItemState['Translated'].", Active=".$ItemState['Active']." ".
               "WHERE ".$Type."Id=".$Id." AND Language='".$Language."'";
    }
    //if ($Type=='Category')	echo "<pre>$Query</pre>";
    mysql_query($Query);
}

function FetchStatus($Type) {
    $Query="SELECT * FROM ".$Type."Status";
    $Return=array();
    $NameOfId=$Type.'Id';
    $Result=mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return[$Row['Language']][$Row[$NameOfId]]=$Row;
    }
    return $Return;
}

function FetchInfoPages($Language,$Active=false) {
    $Return=array();
    if ($Active) {
        $Query="SELECT InfoLanguage.* FROM InfoLanguage,InfoStatus ".
               "WHERE InfoLanguage.Language='".$Language."' AND InfoStatus.Language='".$Language."' AND InfoActive.InfoId=InfoLanguage.InfoId".
                 "ORDER BY Name";
    } else {
        $Query="SELECT * FROM InfoLanguage WHERE Language='".$Language."' ORDER BY Name";
    }
    $Result=mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return[]=$Row;
        $Return['ById'][$Row['InfoId']]=$Row;
    }
    return $Return;
}

function FetchInfoPagesFor($Type,$Id,$Language,$Active=false) {
    $Return=array();
    $Query="SELECT * FROM InfoLanguage,".$Type."InfoPages ";
    if ($Active) $Query.=",InfoStatus ";
    $Query.="WHERE InfoLanguage.Language='".$Language."' AND ".$Type."Id=".$Id." AND InfoLanguage.InfoId=".$Type."InfoPages.InfoId ";
    if ($Active) $Query.="AND InfoStatus.Language='".$Language."' AND InfoStatus.InfoId=".$Type."InfoPages.InfoId AND InfoStatus.Active=1 ";
    $Query.="ORDER BY ".$Type."InfoPages.Position ASC";
    // error_log("Fetch Info Pages For: ".$Query);
    $Result=mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return[]=$Row;
    }
    return $Return;
}

function FetchInterestingProducts($Type,$Id, $Language,$Active=false) {
    $Return=array();
    $Query='SELECT Product.ProductId,Product.CategoryId,'.$Type.'InterestingProducts.Position,Name '.
                          'FROM Product, ProductLanguage, '.$Type.'InterestingProducts ';
    if ($Active) $Query.=',ProductStatus ';
    $Query.='WHERE '.$Type.'InterestingProducts.'.$Type.'Id='.$Id.' '.
                "AND ".$Type."InterestingProducts.InterestingProductId=Product.ProductId ".
                "AND Product.ProductId=ProductLanguage.ProductId ".
                "AND ProductLanguage.Language='".$Language."' ";
    if ($Active) $Query.=" AND ProductStatus.ProductId=Product.ProductId AND ProductStatus.Language='".$Language."' AND ProductStatus.Active=1";
    $Query.=' ORDER BY '.$Type.'InterestingProducts.'.$Type.'Id ASC, '.$Type.'InterestingProducts.Position ASC';

    $Result=@mysql_query($Query);
    while ($Row=@mysql_fetch_assoc($Result)) {
        $Return[]=$Row;
    }
    error_log($Query);
    return $Return;
}

function FetchAdditionalProducts($CategoryId, $Language,$Active=false) {
    $Return=array();
    $Query='SELECT Product.ProductId,ProductToCategory.CategoryId,ProductToCategory.Position,Name '.
                          'FROM Product, ProductLanguage, ProductToCategory ';
    if ($Active) $Query.=',ProductStatus ';
    $Query.='WHERE ProductToCategory.CategoryId='.$CategoryId.' AND ProductToCategory.ProductId=Product.ProductId'.
                ' AND Product.ProductId=ProductLanguage.ProductId '.
                " AND ProductLanguage.Language='".$Language."' ";
    if ($Active) $Query.=" AND ProductStatus.ProductId=Product.ProductId AND ProductStatus.Language='".$Language."' AND ProductStatus.Active=1 ";
    $Query.='ORDER BY ProductToCategory.Position ASC';
    $Result=mysql_query($Query);
    while ($Row=mysql_fetch_assoc($Result)) {
        $Return[]=$Row;
    }
    return $Return;
}

?>
