<?php require('Libraries.php'); 
  if (!$_SESSION['LoggedIn']) {
    header("location: index.php");
    die();
  }

  //- mark handle changes
  if (Environment_Read('action')=='changeArticleAmountsAndComments') {
    foreach ($_POST['amount'] as $ArticleNumber => $NewAmount) {
      $_SESSION['Basket']->setAmountOfArticle($NewAmount,$ArticleNumber);
    }
    foreach ($_POST['comment'] as $ArticleNumber => $NewComment) {
      $_SESSION['Basket']->setCommentForArticleNumber($NewComment,$ArticleNumber);
    }
  }

  if (Environment_Read('action')=='deleteArticle') {
    $_SESSION['Basket']->setAmountOfArticle(0,Environment_Read('articlenumber'));
  }
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta content="<?php echo $heidernei; ?>" />
<meta content="<?php echo "text/html; charset=utf-8" ?>" />
<meta <?php echo "content=\"text/html; charset=utf-8\"" ?>" />
<unknowntag <?= "attributename" ?>="<?php echo $winning ?>"> Stuff like this doesn't work or did it? </unkowntag>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Euro Brasil Import KG - Gro&szlig;handel f&uuml;r Kristalle, Mineralien </title>
<script src="javascripts/prototype.js" language="JavaScript" type="text/javascript"></script>
<script type="text/JavaScript">
<!--
function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_openBrWindow(theURL,winName,features) { //v2.0
  window.open(theURL,winName,features);
}

function open_all_details() {
  $$('.article_detail_placeholder').each( function(element) {
      open_details(element, element.id.substring(15,element.id.length))
    }
  )
}

function close_all_details() {
  $$('.article_detail_placeholder').each( function(element) {
      // hide the tr
      Element.hide(element.parentNode)
    }
  )
}


function open_details(anElement, anArticleNumber) {
  var url = 'ProductDetailsAjax.php'
  var pars = 'artnr='+anArticleNumber
  var fieldName = 'article_detail_'+anArticleNumber
  var targetElement = $(fieldName)
  targetElement.innerHTML='<img src="bilder/loading.gif" />'
  if (targetElement.parentNode.style.display=='') {
    targetElement.parentNode.style.display='none'
  } else {
    targetElement.parentNode.style.display=''
    new Ajax.Updater(
      targetElement,
      url,
      { method: 'get',
        parameters: pars
      }
    )
  }
}

function check_form(event) {
  var abort = false
  var alert_text = ''

  if ($('payment_type').value=='') {
    abort = true;
    alert_text += "Bitte geben Sie die gewünschte Zahlungsart an!\n"
  }

  if ($('post_type').value=='') {
    abort = true;
    alert_text += "Bitte geben Sie die gewünschte Versandart an!\n"
  }
  
  if (!$('email_validation').checked && (!$F('new_email') || $F('new_email')=='')) {
    abort = true;
    alert_text += "Bitte bestätigen Sie Ihre Email oder geben Sie eine neue an!\n"
  }
  
  if (!$F('telefonnummer_rueckfragen') || $F('telefonnummer_rueckfragen') == '') {
    abort = true;
    alert_text += "Bitte geben Sie eine Telefonnummer für Rückfragen an!\n"
  }
  
  if (abort) {
    var event = event ? event : window.event
    alert(alert_text)
    Event.stop(event)
    return false
  }
}

function formatAsMoney(mnt) {
    mnt -= 0;
    mnt = (Math.round(mnt*100))/100;
    return (mnt == Math.floor(mnt)) ? mnt + '.00' 
              : ( (mnt*10 == Math.floor(mnt*10)) ? 
                       mnt + '0' : ''+mnt);
}

// comment? http://www.heise.de warum? nur für den kick für den augenblick?

function floatInMoney(myFloat) {
  return formatAsMoney(myFloat).replace('.',',');
}

function floatInEuro(myFloat) {
  return formatAsMoney(myFloat).replace('.',',') + '&nbsp;&euro;';
}

function update_postage_sum() {
  var cost = cost_table[$('post_type').value]
  if (!cost) cost = 0
  if ($('payment_type').value[0]==2) {
    var nncost = cost_table[$('post_type').value+'nn']
    if (nncost) cost += nncost
  }
  $('post_cost').innerHTML=floatInEuro(cost)
  var total_sum = cost+cost_table['lowQuantityCharge']+cost_table['netSum']
  $('total_sum').innerHTML=floatInEuro(total_sum)
  $('vat').innerHTML = floatInEuro(total_sum*cost_table['vatPercentage']/100.)
  $('gross_sum').innerHTML = floatInEuro(total_sum*(cost_table['vatPercentage']+100)/100.)
}

var cost_table = { <?php 
  $postage_array = array();
  list($postage_array['u1'], $NumberOfPackages_u) = $_SESSION['Basket']->postCost('u',1,$_SESSION['Basket']->postageWeight());
  list($postage_array['p0'], $NumberOfPackages_p) = $_SESSION['Basket']->postCost('p',0,$_SESSION['Basket']->postageWeight());
  list($postage_array['p'.$_SESSION['LoginData']['postzone']]) = $_SESSION['Basket']->postCost('p',$_SESSION['LoginData']['postzone'],$_SESSION['Basket']->postageWeight());
  list($postage_array['u'.$_SESSION['LoginData']['upszone']] ) = $_SESSION['Basket']->postCost('u',$_SESSION['LoginData']['upszone'],$_SESSION['Basket']->postageWeight());
  $json = array();
  foreach ($postage_array as $Key => $Value) {
    $json[]="'$Key': $Value";
    $Packages=${"NumberOfPackages_".$Key[0]};
    $nn=($_SESSION['Basket']->nnCost($Key[0],substr($Key,1)))*$Packages;
    if ($nn===NULL) $nn = 0;
    $json[]="'$Key"."nn': ". $nn;
  }
  $json[]="netSum : ".$_SESSION['Basket']->netSum();
  $json[]="lowQuantityCharge : ".$_SESSION['Basket']->lowQuantityCharge();
  $json[]="vatPercentage : ".$_SESSION['Basket']->vatPercentage();
  echo join($json,', ');
?>
}

//-->
</script>
<style type="text/css">
h4 {
  padding:0;
  margin:0;
}
</style>
<link href="stylesheets/eurobrasil.css" rel="stylesheet" type="text/css" />
<body>
<div id="centerbox">
<div id="header_bestellung">
  <div id="navcontainer1">
    <?php include('NavigationHeader.php'); ?>
  </div>
  <div id="navcontainer2">
<?php 
  $NavArray = array();
  foreach (Category::TopLevelCategories() as $Category) {
    $NavArray[]=content_tag('a',htmlentities($Category->descriptions['de']), 
                            array('href'=> 'category.php?sel_path='.$Category->id));
  }
  echo implode($NavArray, ' | ');
?>
  </div>
  
  <?php include('OrderOverviewHeader.php'); ?>
  <?php include('SearchBox.html'); ?>

</div>

<div id="hg_content">
  <div id="content_bestellung">
  <?php if (Environment_isSet('requestOrder')) {
    $_SESSION['Basket']->Nachname=($_POST['payment_type'][0]==2);
    $_SESSION['Basket']->Service=$_POST['post_type'][0];
    $_SESSION['Basket']->Zone=substr(Environment_Read('post_type'),1);
    $HTMLMail =content_tag("h2",'Vielen Dank f&uuml;r Ihre Bestellung!');
    $HTMLMail.=content_tag("h3",'Kundennummer: '.$_SESSION['LoginData']['kundennummer']);
    $TableRows='';
    $TableRow ='';
    foreach (array("Bezeichnung","Artikel-Nr","Einheit","Preis<br/>pro Einheit","Bestellmenge<br />in Einheiten","Preis<br/>gesamt") as $Titel) {
      $TableRow.=content_tag('th',$Titel);
    }
    $TableRows.=content_tag('tr',$TableRow);
    $Items = $_SESSION['Basket']->items();
    foreach ($Items as $Item) {
      $Article = $Item->article;
      $TableRow = '';
      $TableRow.=content_tag('td',$Article->title('de'));
      $TableRow.=content_tag('td',$Article->articlenumber());
      $TableRow.=content_tag('td',$Article->unit('de'));
      $TableRow.=content_tag('td',$Article->displayPrice('de'), array('align'=>'right'));
      $TableRow.=content_tag('td',$Item->amount, array('align'=>'center'));
      $TableRow.=content_tag('td',$Item->displaySum('de'), array('align'=>'right'));
      $TableRows.=content_tag('tr',$TableRow);
      if (strlen($Item->comment)>0) {
        $TableRows.=content_tag('tr',content_tag('td','Kommentar:',array('align'=>'right')).content_tag('td',htmlentities($Item->comment),array('colspan'=>5)));
      }
    }
    $TableRows.=content_tag('tr',
                content_tag('th','Warenpreis',array('align'=>'right', 'colspan'=>'5')).
                content_tag('th',format_as_money($_SESSION['Basket']->netSum(),'de'),array('align'=>'right')));
    if ($_SESSION['Basket']->lowQuantityCharge()) {
      $TableRows.=content_tag('tr',
                  content_tag('th','Mindermengenzuschlag (bis '.format_as_money($_SESSION['Basket']->iniRow('mindestbestellwert'),'de').')',array('align'=>'right', 'colspan'=>'5')).
                  content_tag('th',format_as_money($_SESSION['Basket']->lowQuantityCharge(),'de'),array('align'=>'right')));
    }
    $TableRows.=content_tag('tr',
                content_tag('th','Versandkosten für: '.format_as_weight($_SESSION['Basket']->totalWeight(),'de'),array('align'=>'right', 'colspan'=>'5')).
                content_tag('th',format_as_money($_SESSION['Basket']->shippingCost(),'de'),array('align'=>'right')));
    $TableRows.=content_tag('tr',
                content_tag('th','Nettogesamtpreis',array('align'=>'right', 'colspan'=>'5')).
                content_tag('th',format_as_money($_SESSION['Basket']->totalSum(),'de'),array('align'=>'right')));
    $TableRows.=content_tag('tr',
                content_tag('th',$_SESSION['Basket']->vatPercentage().'% MWSt',array('align'=>'right', 'colspan'=>'5')).
                content_tag('th',format_as_money($_SESSION['Basket']->vat(),'de'),array('align'=>'right')));
    $TableRows.=content_tag('tr',
                content_tag('th','Bruttogesamtpreis',array('align'=>'right', 'colspan'=>'5')).
                content_tag('th',format_as_money($_SESSION['Basket']->grossSum(),'de'),array('align'=>'right')));
    $HTMLMail.=content_tag('table',$TableRows,array('cellpadding'=>'3'));
    $HTMLMail.=tag('br');
    $post_type = Environment_Read('post_type');
    if ($post_type[0]=='u') {
      $post_type="UPS Standard (Zone ".substr($post_type,1).")";
    } else if ($post_type[0]=='p'){
      $post_type="UPS Standard (Zone ".substr($post_type,1).")";
    }
    $HTMLMail.=content_tag('strong','Versandart: ').$post_type.tag('br');
    $HTMLMail.=content_tag('strong','Zahlungsart: ').Environment_Read('payment_type').tag('br');
    $HTMLMail.=content_tag('strong','Email-Adresse bestätigt: ').$_SESSION['LoginData']['email'].' '.(Environment_IsSet('email_validation')?'ja':'nein').tag('br');
    $EmailAddress = $_SESSION['LoginData']['email'];
    if (strlen(Environment_Read('new_email'))>0) {
      $HTMLMail.=content_tag('strong','Neue Email-Adresse: ').Environment_Read('new_email').tag('br');
      $EmailAddress = Environment_Read('new_email');
    }
    if (strlen(Environment_Read('new_address'))>0) {
      $HTMLMail.=content_tag('strong','Neue Adresse:').tag('br').content_tag('pre',Environment_Read('new_address'));
    }
    if (strlen(Environment_Read('telefonnummer_rueckfragen'))>0) {
      $HTMLMail.=content_tag('strong','Telefonnummer für Rückfragen: ').content_tag('code',Environment_Read('telefonnummer_rueckfragen')).tag('br');
    }
    if (strlen(Environment_Read('global_comment'))>0) {
      $HTMLMail.=content_tag('strong','Allgemeiner Kommentar:').tag('br').content_tag('pre',Environment_Read('global_comment'));
    }
    echo content_tag('div',$HTMLMail,array('style'=>'margin:0 auto; padding-left:30px;'));
    $HTMLMail = '<html><head><meta http-equiv="content-type" content="text/html; charset=iso-8859-1" /></head><body>'.$HTMLMail.'</body></html>';
    $HTMLSubject = 
    HTMLMail($EmailAddress,"automail283@eurobrasil.de","www.eurobrasil.de : Bestellung von Kundennummer ".$_SESSION['LoginData']['kundennummer'],$HTMLMail);
    HTMLMail("info@eurobrasil.de",$EmailAddress,"Ihre Bestellung auf www.eurobrasil.de",$HTMLMail);
    $_SESSION['Basket'] = new ShoppingBasket();
    EBLog('order placed');
  } else { ?>
    <h3>Ihre Bestellung - Kundennummer: <?php echo $_SESSION['LoginData']['kundennummer'];?></h3>
    <table width="100%" border="0" cellspacing="0" cellpadding="4">

      <tr class="alternate">
        <td width="300" height="35">Bezeichnung</td>
        <td width="89">Artikel-Nr</td>
        <td width="82" align="center">Verf&uuml;gbarkeit</td>
        <td width="40">Einheit</td>
        <td width="64">Preis <br />
          pro  Einheit</td>
        <td width="85">Bestellmenge <br />
          in Einheiten</td>
        <td width="49">Preis<br />
          gesamt</td>
        <td width="61">Bestellung<br />
          l&ouml;schen</td>
        <td width="88">Bestellung<br />
          &auml;ndern</td>
      </tr>
<?php
    echo '<form action="?" method="post">';
    echo '<input type="hidden" name="action" value="changeArticleAmountsAndComments" />';
    $Items = $_SESSION['Basket']->items();
    $isAlternate = true;
    foreach ($Items as $Item) {
      $isAlternate = !$isAlternate;
      $Article = $Item->article;
      $DetailURL= "ProductDetails.php?artnr=".$Article->articlenumber();
      echo content_tag('tr',
        content_tag('td',link_to ($Article->title('de'),'#',array('onclick'=>"open_details(this, ".$Article->articlenumber()."); return false;"))).
        content_tag('td',$Article->articlenumber()).
        content_tag('td','<a href="#" onclick="return false;"><img src="bilder/bilder_index/verfuegbarkeit_'.$Article->availability().'.gif" onclick="MM_openBrWindow(\'verfuegbarkeit.html\',\'\',\'width=400,height=230\')"/></a>', 
          array('align'=>'center')).
        content_tag('td',$Article->unit('de')).
        content_tag('td',$Article->displayPrice('de'), array('align'=>'right')).
        content_tag('td','<input name="amount['.$Article->articlenumber().']" type="text" size="8" value="'.$Item->amount.'" style="text-align:center;"/>', array('align'=>'center')).
        content_tag('td',$Item->displaySum('de'), array('align'=>'right')).
        content_tag('td',
                    content_tag('a',
                                tag('img',array('src'=>'bilder/bilder_bestellung/bestellung_loeschen.gif','border'=>0,'width'=>14,'height'=>'14')),
                                array('href'=>'?action=deleteArticle&articlenumber='.$Article->articlenumber())), 
                    array('align'=>'center')).
        content_tag('td','<input type="image" name="modifyAmount" src="bilder/bilder_bestellung/bestellung_aendern.gif" width="14" height="14" style="border: none;"/>', array('align'=>'center')),
        $isAlternate ? array('class'=>'alternate') : array() );
?>
      <tr <?php if ($isAlternate) echo 'class="alternate"'; ?>>
        <td><div align="right">Kommentar:</div></td>
        <td colspan="6"><?php
            echo tag('input',array('class'=>'box_mit_rand kommentar', 'name'=>'comment['.$Article->articlenumber().']','size'=>100,'value'=>$Item->comment));
        ?></td>
        <td><div align="center"></div></td>
        <td><div align="center"></div></td>
      </tr>
<?php
	// www.heise.de 
      echo content_tag('tr', content_tag('td', '', array('colspan'=>9, 'id' => 'article_detail_'.$Article->articlenumber(), 'class'=>'article_detail_placeholder')), array_merge(($isAlternate ? array('class'=>'alternate') : array()), array('style'=>'display:none;')));

    }
?>
    </table>
    <!-- import http://www.heise.de heise.de dom@codingmonkeys.org -->
    <table width="100%" border="0" cellspacing="0" cellpadding="4">
      <tr class="alternate">
        <td width="142" height="10" >&nbsp;</td>
        <td width="540" >&nbsp;</td>
        <td width="78" >&nbsp;</td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4>Warenpreis</h4>
        </div></td>
        <td width="78" >
          <h4 align="right"><?php echo format_as_money($_SESSION['Basket']->netSum(),'de');?></h4>        </td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
    <?php
    if ($_SESSION['Basket']->lowQuantityCharge()) { ?>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4>Mindermengenzuschlag (bis <?php echo format_as_money($_SESSION['Basket']->iniRow('mindestbestellwert'),'de'); ?>)</h4>
        </div></td>
        <td width="78" >
          <h4 align="right"><?php echo format_as_money($_SESSION['Basket']->lowQuantityCharge(),'de');?></h4></td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
    <?php
    }
    ?>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4>Versandkosten für: <?php echo format_as_weight($_SESSION['Basket']->totalWeight(),'de');?></h4>
        </div></td>
        <td width="78" >
          <h4 align="right" id="post_cost"><?php echo format_as_money($_SESSION['Basket']->shippingCost(),'de');?></h4></td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4>Nettogesamtpreis</h4>
        </div></td>
        <td width="78" >
          <h4 align="right" id="total_sum"><?php echo format_as_money($_SESSION['Basket']->totalSum(),'de');?></h4>        </td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4><?php echo $_SESSION['Basket']->vatPercentage(); ?>% MWSt</h4>
        </div></td>
        <td width="78" >
          <h4 align="right" id="vat"><?php echo format_as_money($_SESSION['Basket']->vat(),'de');?></h4>        </td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td width="540" ><div align="right">
          <h4>Bruttogesamtpreis</h4>
        </div></td>
        <td width="78" >
          <h4 align="right" id="gross_sum"><?php echo format_as_money($_SESSION['Basket']->grossSum(),'de');?></h4>        </td>
        <td width="63" >&nbsp;</td>
        <td width="67" >&nbsp;</td>
      </tr>
      <tr class="alternate">
        <td >&nbsp;</td>
        <td >&nbsp;</td>
        <td >&nbsp;</td>
        <td >&nbsp;</td>
        <td >&nbsp;</td>
      </tr>
    </table>
    <br />
    <table width="100%" border="0" cellspacing="0" cellpadding="4">
      <tr>
        <td height="5" colspan="5" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99"><div align="right">Versandart: </div>
            <label></label></td>
        <td width="219" bgcolor="#FFFF99"><select name="post_type" id="post_type" onchange="update_postage_sum();">
            <option selected="selected" value="">Auswahl:</option>
            <option value="u<? echo $_SESSION['LoginData']['upszone']?>">UPS Standard (Zone <? echo $_SESSION['LoginData']['upszone']?>)</option>
            <option value="p<? echo $_SESSION['LoginData']['postzone']?>">Post (Zone <? echo $_SESSION['LoginData']['postzone']?>)</option>
            <option value="u1">UPS Standard (DE) </option>
            <option value="p0">Post (DE) </option>
            <option value="Abholung">Abholung</option>
        </select></td>
        <td width="605" bgcolor="#FFFF99"><a href="#" onclick="MM_openBrWindow('versandkosten.html','','width=400,height=400')">&gt;&gt; 
          f&uuml;r weitere Informationen zu den Versandkosten klicken Sie bitte 
          hier</a></td>
      </tr>
      <tr>
        <td width="10" bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99"><div align="right">
            <label>Zahlungsart:</label>
        </div></td>
        <td bgcolor="#FFFF99">
        <?php 
          $ChoicesArray = array(array("Auswahl:",""),
                                array("Barzahlung", "0 Barzahlung"),
                                array("Vorauskasse","1 Vorauskasse"),
                                array("Nachnahme",  "2 Nachnahme"),
                                array("Abbuchung",  "3 Abbuchung"),
                                array("Rechnung",   "4 Rechnung"));
          echo select("payment_type",array_slice($ChoicesArray,0,2+$_SESSION['LoginData']['zahlungsbedingungen']), array('onchange'=>'update_postage_sum();'));
        ?>
        </td>
        <td bgcolor="#FFFF99"></td>
      </tr>
    </table>
    <table width="100%" border="0" cellspacing="0" cellpadding="4">
      <?php if ($_SESSION['LoginData']['email'] && $_SESSION['LoginData']['email']!="") { ?>
        <tr>
          <td width="10" bgcolor="#FFFF99">&nbsp;</td>
          <td width="553" bgcolor="#FFFF99">Ist Ihre E-mail-Adresse noch korrekt?          Bitte best&auml;tigen Sie die Richtigkeit Ihrer E-mail-Adresse:</td>
          <td width="23" bgcolor="#FFFF99"><span class="hinweis_rot">
            <input id="email_validation" type="checkbox" name="email_validation" value="true" />
          </span></td>
          <td width="312" bgcolor="#FFFF99"><span class="hinweis_rot"><?php echo $_SESSION['LoginData']['email']; ?></span></td>
        </tr>
        <tr>
          <td bgcolor="#FFFF99">&nbsp;</td>
          <td bgcolor="#FFFF99">Falls Sie eine neue E-mail-Adresse haben, geben Sie diese bitte hier ein: </td>
          <td colspan="2" bgcolor="#FFFF99"><input id="new_email" name="new_email" type="text" class="box_mit_rand" size="30" /></td>
        </tr>
        <tr>
          <td bgcolor="#FFFF99">&nbsp;</td>
          <td bgcolor="#FFFF99">Telefonnummer für Rückfragen:</td>
          <td colspan="2" bgcolor="#FFFF99"><input id="telefonnummer_rueckfragen" name="telefonnummer_rueckfragen" type="text" class="box_mit_rand" size="30" /></td>
        </tr>
      <?php } else { ?>
      </table>
      <table width="100%" border="0" cellspacing="0" cellpadding="4">
        <tr>
          <td bgcolor="#FFFF99" width="10">&nbsp;<input id="email_validation" type="checkbox" name="email_validation" value="true" style="display:none;"/></td>
          <td bgcolor="#FFFF99" width="260">Geben Sie bitte hier eine E-mail-Adresse ein: </td>
          <td bgcolor="#FFFF99"><input id="new_email" name="new_email" type="text" class="box_mit_rand" size="30" /></td>
        </tr>
        <tr>
          <td bgcolor="#FFFF99">&nbsp;</td>
          <td bgcolor="#FFFF99">Telefonnummer für Rückfragen:</td>
          <td bgcolor="#FFFF99"><input id="telefonnummer_rueckfragen" name="telefonnummer_rueckfragen" type="text" class="box_mit_rand" size="30" /></td>
        </tr>
      <?php } ?>
      </table>
      <table width="100%" border="0" cellspacing="0" cellpadding="4">
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">Falls sie eine abweichende Lieferanschrift oder eine neue Adresse haben, geben sie diese bitte hier an:</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99"><textarea name="new_address" cols="90" rows="3" class="box_mit_rand"></textarea></td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">Allgemeine Kommentare, besondere W&uuml;nsche: </td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99"><textarea  class="box_mit_rand" name="global_comment" cols="200" rows="4" id="textarea" type="text"> </textarea></td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99"><input type="submit" class="box_mit_rand" name="requestOrder" value="Bestellung abschicken" onclick="check_form(event);" <?php if ($_SESSION['Basket']->netSum()<=0) echo 'disabled="disabled"'; ?>/></td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      <tr>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td bgcolor="#FFFF99">&nbsp;</td>
        <td colspan="2" bgcolor="#FFFF99">&nbsp;</td>
      </tr>
      </form>
    </table>
    <?php } ?>
  </div>
</div>
  <div id="footer"></div>
</div>
</body>
</html>
