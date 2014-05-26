{*
  Template for the search interface
  $Id: search.tpl,v 2.27 2005/10/13 19:30:55 andig2 Exp $
*}

<script language="JavaScript" type="text/javascript" src="javascript/search.js"></script>

<div>

    {include file="searchengines.tpl"}

    <form action="search.php" id="search" name="search" method="get">
    <table width="100%" class="tablefilter" cellspacing="5">
    <tr>
        <td width="40%">
            <table width="100%" cellpadding="5" cellspacing="0">
                <tr>
                    <td width="20%">
                        <span class="filterlink">{$lang.keywords}:</span>
                        <br/>
                        <input type="text" name="q" id="q" value='{$q_q}' size="45" maxlength="300"/>
                        <br/>
                        {include file="searchradios.tpl"}
                        <input type="button" value="{$lang.l_search}" onClick="submitSearch(this)" class="button" />
                    </td>
                </tr>
                <tr>
                    <td>{$lang.keywords_desc}</td>
                </tr>
            </table>
        </td>
        <td nowrap="nowrap">
            <span class="filterlink">{$lang.fieldselect}:</span><br />
            <select name="fields[]" size="8" multiple="multiple">
            {html_options options=$search_fields selected=$selected_fields}
            </select><br />
            <span class="filterlink" style="font-size:10px; font-weight: bold;"><a href="javascript:selectAllFields()">{$lang.selectall}</a></span>
        </td>
        <td width="60%" rowspan="2">
            {if $owners}
            <span class="filterlink">{$lang.owner}:</span>
            {html_options name=owner options=$owners selected=$owner}<br/>
            {/if}
            <span class="filterlink">{$lang.genre_desc}:</span>
            {$genreselect}
        </td>
        {if $imgurl}
        <td>
{*
            <a href='http://uk.imdb.com/Name?{$q_q|replace:"&quot;|\"":""|escape:url}'>{html_image file=$imgurl}</a>
*}
            <a href='http://uk.imdb.com/Name?{$q|replace:"&quot;|\"":""|escape:url}'>{html_image file=$imgurl}</a>
            <!--<img align=left src="{$imgurl}" width="97" height="144"/>-->
        </td>
        {/if}
    </tr>
    </table>
    </form>

</div>

<script language="JavaScript" type="text/javascript">
    selectField(document.search.q);
</script>
