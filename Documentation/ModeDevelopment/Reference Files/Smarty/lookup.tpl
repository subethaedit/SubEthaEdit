{*
  Search engine popup
  $Id: lookup.tpl,v 2.35 2009/04/04 16:21:34 andig2 Exp $
*}
{include file="xml.tpl"}

<body someattribute="{$sometag}">

<script language="JavaScript" type="text/javascript" src="javascript/lookup.js"></script>

<!-- {$smarty.template} -->

<div class="tablemenu">
	<div style="height:7px; font-size:1px;"></div>
    {foreach key=e item=eng from=$engines}
    <span class="{if $engine == $e}tabActive{else}tabInactive{/if}"><a href="{$eng.url}">{$eng.name}</a></span>
    {/foreach}
</div>


<table width="100%" cellspacing="0" cellpadding="0">
<tr>
    <td>
    <form action="lookup.php" id="lookup" name="lookup">
        <table width="100%" class="tablefilter" cellspacing="5">
        <tr>
            <td nowrap="nowrap">
                <input type="text" name="find" id="find" value="{$q_find}" size="31" style="width:200px" />
                {include file="lookup_engines.tpl"}
                <input type="submit" class="button" value="{$lang.l_search}" />

                <script language="JavaScript" type="text/javascript">
                document.lookup.find.focus();
                </script>
            </td>
        </tr>
        </table>
    </form>
    </td>
</tr>

<tr>
    <td>
        <br/>
        {if $http_error}
            <pre>{$http_error}</pre>
        {/if}

        {if $imdbresults}
        <b>{$lang.l_select}</b>
        {if $searchtype == 'image'}
            {foreach item=match from=$imdbresults}
                <div class="thumbnail">
                    <a href="javascript:void(returnImage('{$match.coverurl|escape:"javascript"}'));" title="Select image and close Window">
                        <img src="{$match.imgsmall}" align="left" width="60" height="90" /><br />
                        {$match.title}
                    </a>
                </div>
            {/foreach}
        {else}
            <ul>
            {foreach item=match from=$imdbresults}
                <li>
                    <a href="javascript:void(returnData('{$match.id}','{$match.title|escape:"javascript"|escape}','{$match.subtitle|escape:"javascript"|escape}', '{$engine}'));" title="add ID and close Window">{$match.title}{if $match.subtitle} - {$match.subtitle}{/if}</a>
                    {if $match.details or $match.imgsmall}
                    <br/>
                    <font size="-2">
                        {if $match.imgsmall}<img src="{$match.imgsmall}" align="left" width="25" height="35" />{/if}
                        {$match.details}
                    </font>
                    {/if}
                    <br clear="all" />
                </li>
            {/foreach}
            </ul>
        {/if}
        {else}
            <div align="center"><b>{$lang.l_nothing}</b></div>
            <br />
        {/if}

        <br clear="all" />
        <div align="right">
            [ <a href="{$searchurl}" target="_blank">{$lang.l_selfsearch}</a> ]
        </div>

    </td>
</tr>
</table>


</body>
</html>
