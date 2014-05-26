<%@ Language=VBScript %>
<!--#include file="atacado_util.asp" -->
<!--#include file="televendas_util.asp" -->
<!--#include file="site_desativado.txt" -->
<!--#INCLUDE FILE="../util.asp" -->
<%

'---------------------------------------------------------------------------------
' Mostra barra esquerda com os links da seção "Contato".
'---------------------------------------------------------------------------------
function MostraBarraPrincipal(subsecaoatual)
	dim SubSections
	dim Key
	dim Link
	dim i
	dim SubSubSection
	
	SubSubSection = 1
	if (SubSubSection = 1) then	SubSubSection = 2
	
	set SubSections = Server.CreateObject("Scripting.Dictionary")
	SubSections.Add "MEUS_PEDIDOS","&rsaquo; Meus Pedidos*meuspedidos.asp"
	SubSections.Add "MEU_CADASTRO","&rsaquo; Meu Cadastro*meucadastro.asp"
	SubSections.Add "DEVOLUCAO","&rsaquo; Devoluções e Troca*ajuda_politicadevolucao.asp"
	SubSections.Add "PAGAMENTO","&rsaquo; Formas de Pagamento*ajuda_faq.asp#pagamento"
	SubSections.Add "PRIVACIDADE","&rsaquo; Política de Privacidade*ajuda_privacidade.asp"
	SubSections.Add "ATACADO","&rsaquo; Atacado*ajuda_faq.asp#atacado"
	SubSections.Add "QUEM_SOMOS","&rsaquo; Quem Somos*ajuda_privacidade.asp#quemsomos"
	SubSections.Add "CONTATO","&rsaquo; Contato*contato.asp"

	Response.Write	"<!-- BARRA ESQUERDA -->" & vbcrlf &_	
					"<div id=""menu_secoes"">"&_
					"<div id=""titulo_secao"">" &_
					"<div id=""texto_titulo_secao_sombra"">NAVEGAÇÃO</div>" &_
					"<div id=""texto_titulo_secao"">NAVEGAÇÃO</div>" &_
					"</div>" &_
					"<div id=""nav_lateral_subcat"">" &_
					"<ul>" & vbcrlf

	i = 0
	for each Key in SubSections.Keys
		Link = split(SubSections(Key),"*")
		if subsecaoatual = Key then
			Response.Write "<li><a class=""cat_selecionada"" href=""" & Link(1) & """>" & Link(0) & "</a></li>"
		else
			Response.Write "<li><a href=""" & Link(1) & """>" & Link(0) & "</a></li>"
		end if
		i = i + 1
	next

	SubSections.RemoveAll
	set SubSections = Nothing

	Response.Write	"</ul>" &_
					"</div>"  &_
					"</div>" &_
					"<!-- FIM BARRA ESQUERDA -->" & vbcrlf & vbcrlf

	Response.Write	"<!-- CONTEUDO -->" & vbcrlf &_
					"<div id=""corpo"">" & vbcrlf
	MostraBarraPrincipal = true
end function


%>