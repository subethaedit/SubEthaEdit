{*
  Template for the borrowing a single disk
  $Id: borrow.tpl,v 2.17 2008/03/09 14:57:23 andig2 Exp $
*}

{if $diskid && $editable}
<div>

    <table width="100%" class="tablefilter">
    <tr>
      <td class="center">
        <form action="borrow.php" id="borrow" name="borrow" method="post">
          <input type="hidden" name="diskid" id="diskid" value="{$diskid}" />
          {if $who}
            <br />
            {$lang.diskid} {$diskid}
            {$lang.lentto} {$who} ({$dt})
            <br />
            <input type="hidden" name="return" value="1" />
            <input type="submit" value="{$lang.returned}" class="button" />
          {else}
            <br />
            {$lang.diskid} {$diskid} {$lang.available}
            <br />
            {$lang.borrowto}:
            <input type="text" size="40" maxlength="255" id="who" name="who" />
            <input type="submit" value="{$lang.okay}" class="button" />
          {/if}
          <br />
        </form>
      </td>
    </tr>
    </table>

    <script language="JavaScript" type="text/javascript">
        if (document.forms['borrow'].who) document.forms['borrow'].who.focus();
    </script>

</div>
{else}
    <div id="topspacer"></div>
{/if}

<br/>
{if $config.multiuser}
<table>
    <tr>
        <td class="show_title">{$lang.curlentfrom}</td>
        <td><form action="borrow.php">{html_options name=owner options=$owners selected=$owner onchange="submit()"}</form></td>
        <td>:</td>
    </tr>
</table><br/>
{else}
<h3>{$lang.curlent}</h3>
{/if}

{if $borrowlist}
  <table width="90%" class="tableborder">
    <tr class="{cycle values="even,odd"}">
        <th>{$lang.diskid}</th>
        {if $config.multiuser}<th>{$lang.owner}</th>{/if}
        <th>{$lang.title}</th>
        <th>{$lang.lentto}</th>
        <th>{$lang.date}</th>
        <th></th>
    </tr>

    {foreach item=disk from=$borrowlist}
      <tr class="{cycle values="even,odd"}">
        <td class="center"><a href="search.php?q={$disk.diskid}&fields=diskid&nowild=1">{$disk.diskid}</a></td>
        {if $config.multiuser}
          <td class="center">{$disk.owner}</td>
        {/if}
        <td class="center">
          <a href="show.php?id={$disk.id}">{$disk.title}</a>
          {if $disk.count > 1} ... {/if}
        </td>
        <td class="center">{$disk.who}</td>
        <td class="center">{$disk.dt}</td>
        <td class="center">
            {if $disk.editable}
            <form action="borrow.php" method="get">
                <input type="hidden" name="diskid" value="{$disk.diskid}" />
                <input type="hidden" name="return" value="1" />
                <input type="submit" value="{$lang.returned}" class="button"/>
            </form>
            {/if}
        </td>
      </tr>
    {/foreach}
    </table>
{else}
    {$lang.l_nothing}
    <br/><br/>
{/if}
