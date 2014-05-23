{*
  This is the header which is displayed on top of every page
  $Id: header.tpl,v 2.25 2011/02/11 07:42:10 andig2 Exp $
*}
{include file="xml.tpl"}

<body>
<a name="top"></a>

<div class="tablemenu">

	<a href="http://www.videodb.net" class="logo">videoDB</a>
	<div style="height:7px; font-size:1px;"></div>

	{if $header.browse}<span class="{if $header.active == 'browse'}tabActive{else}tabInactive{/if}"><a href="{$header.browse}{if $browseid}#{$browseid}{/if}" accesskey="i">{$lang.browse}</a></span>{/if}

	{if $header.trace}<span class="{if $header.active == 'trace'}tabActive{else}tabInactive{/if}"><a href="{$header.trace}">{$lang.imdbbrowser}</a></span>{/if}

	{if $header.random}<span class="{if $header.active == 'random'}tabActive{else}tabInactive{/if}"><a href="{$header.random}">{$lang.random}</a></span>{/if}

	{if $header.search}<span class="{if $header.active == 'search'}tabActive{else}tabInactive{/if}"><a href="{$header.search}">{$lang.search}</a></span>{/if}

	{if $header.new}<span class="{if $header.active == 'new'}tabActive{else}tabInactive{/if}"><a href="{$header.new}" accesskey="n">{$lang.n_e_w}</a></span>{/if}

	{if $header.active == 'show'}<span class="tabActive"><a href="{php}echo $_SERVER['REQUEST_URI'];{/php}">{$lang.view}</a></span> {/if}

	{if $header.active == 'edit'}<span class="tabActive"><a href="{$header.edit}">{$lang.edit}</a></span> {/if}

	{if $header.borrow}<span class="{if $header.active == 'borrow'}tabActive{else}tabInactive{/if}"><a href="{$header.borrow}">{$lang.borrow}</a></span>{/if}

	{if $header.stats}<span class="{if $header.active == 'stats'}tabActive{else}tabInactive{/if}"><a href="{$header.stats}">{$lang.statistics}</a></span>{/if}

 	{if $header.contrib}<span class="{if $header.active == 'contrib'}tabActive{else}tabInactive{/if}"><a href="{$header.contrib}">{$lang.contrib}</a></span>{/if}

	{if $header.setup}<span class="{if $header.active == 'setup'}tabActive{else}tabInactive{/if}"><a href="{$header.setup}">{$lang.setup}</a></span>{/if}

	{if $header.profile}<span class="{if $header.active == 'profile'}tabActive{else}tabInactive{/if}"><a href="{$header.profile}">{$lang.profile}</a></span>{/if}

	{if $header.help}<span class="{if $header.active == 'help'}tabActive{else}tabInactive{/if}"><a href="{$header.help}">{$lang.help}</a></span>{/if}

	{if $header.login}<span class="{if $header.active == 'login'}tabActive{else}tabInactive{/if}"><a href="{$header.login}">{if $loggedin}{$lang.logout}{else}{$lang.login}{/if}</a></span>{/if}

</div>
