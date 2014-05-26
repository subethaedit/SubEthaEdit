<%@ Language=VBScript %>
<!--#INCLUDE FILE="utiladmin.asp" -->
<!--#INCLUDE FILE="etiqueta_util.asp" -->
<!--#INCLUDE FILE="produtos_util.asp" -->
<!--#INCLUDE FILE="../cript.asp" -->
<!--#INCLUDE FILE="../forms.asp" -->
<!--#INCLUDE FILE="../sp.asp" -->
<!--#INCLUDE FILE="../util.asp" -->
<%
' (c) 2000 InterGate Informática Ltda.
dim Eu
dim Conexao
dim Terminou
dim Prod, Acao
dim AlterarBasico, AlterarAvancado, AlterarAdmin

ChecaSenha
Cabecalho "Cadastro de produtos"

' Verifica nivel de acesso.
if not VerificaACL(ACL_Produtos_ASP) then
	Erro "Infelizmente você não tem acesso a esta área."
	Rodape
end if
AlterarBasico = VerificaACL(ACL_ProdutosAlterarBasico)
AlterarAvancado = VerificaACL(ACL_ProdutosAlterarAvancado)
AlterarAdmin = VerificaACL(ACL_ProdutosAlterarAdmin)

Eu = Request.ServerVariables("SCRIPT_NAME")
Conexao = NULL

' Obtem o item atual (ou -1 caso nenhum item tenha ido definido)
' e a acao a ser realizada.
Prod = -1
Acao = ""
if Request.ServerVariables("QUERY_STRING") <> "" then
	if not isEmpty(Request("prod")) then Prod = Request("prod")
	if not isEmpty(Request("acao")) then Acao = Request("acao")
end if

' Javascript para garantir a consistência entre "Preço de venda"
' e "Preço não-promocional" ou "Preço normal"
%>
<script language="Javascript">
<!--
function AlteraPrecoPromocional
{
	var promocao;

	promocao = document.f.eh_promocao[0].checked;
	if ( !promocao ) {
		document.f.preco_nao_promocional.value = document.f.preco.value;
		document.f.preco_nao_promocional.disabled = true;
	} else
	{
		document.f.preco_nao_promocional.disabled = false;
	}
}

function CopiaNomeParaFornecedor()
{
	document.f.nome_fornecedor.value = document.f.nome.value;
}

function DoisDigitos(numero)
{
	numero = numero + ''; // Transforma em string.
	if (numero.length == 1) { numero = '0' + numero; }
	return numero;
	
}

function AjustaDataLancamentoAgora()
{
	var now = new Date();
	
	document.f.data_lancamento.value = DoisDigitos(now.getDate()) + '-' + DoisDigitos(now.getMonth()+1) + '-' + now.getFullYear() +
										' ' + DoisDigitos(now.getHours()) + ':' + DoisDigitos(now.getMinutes()) + ':' + DoisDigitos(now.getSeconds());
}

function mostraAlteracoes(){
	var dv_tm = document.getElementById('alteracao_tm');
	var bt_tm = document.getElementById('botao_tm');
	
	if(dv_tm.style.height == 'auto'){
		dv_tm.style.height = '17px';
		bt_tm.innerHTML = 'Ver todas as alterações'
	}else{
		dv_tm.style.height = 'auto';
		bt_tm.innerHTML = 'Esconder todas as alterações'
	}
}


// Limita tamanho do texto digitado no campo "detalhes" do produto.
var tamanho_texto_x = 0;
var tamanho_texto_y = 0;
var time_machine_texto = "";
function limita_descricao() {
	var texto;
	var CLinha;
	var tamanho_max = 1000;
	var mostra_alerta = false;
	
	texto = document.getElementById("detalhes");
	if (texto.value.length>tamanho_max) {
		texto.value = time_machine_texto;
		mostra_alerta = true;
	}
	time_machine_texto = texto.value;

	CLinha = document.getElementById("conta_detalhes");
	CLinha.innerHTML=texto.value.length;
	if (texto.value.length>=tamanho_max) {
		CLinha.style.color = "#CC0000";
	} else
	{
		CLinha.style.color = "#000000";
	}
	return !mostra_alerta;
}
//-->
</script>
<%


' Efetua procedimentos diferentes, dependendo da acao.
do ' while !Terminou
	Terminou = TRUE
	select case Acao
		case ""
			MenuPrincipal

		' PESQUISA DE UM ITEM	
		case "procurar"
			Acao = ""
			Terminou = FALSE
			if Request("procurar").Count>0 then
				Terminou = ProcuraProdutos
			end if

		' INCLUSAO DE UM NOVO ITEM
		case "incluir"
			' Verifica se o formulario foi preenchido (neste caso, existe o campo "codigo").
			if Request("incluir").Count>0 and Request("codigo").Count>0 then
				' Tenta incluir efetivamente o novo item.
				if IncluiProduto then
					Response.Write "Produto <b>" & Request("nome") & "</b> (" & Request("codigo") & ") incluido com sucesso.<br />" & vbcrlf
					FormularioIncluiProduto FALSE,TRUE
				else
					FormularioIncluiProduto FALSE,FALSE
				end if
			else
				FormularioIncluiProduto FALSE,TRUE
			end if
			
		' ALTERACAO DE UM ITEM
		case "alterar"
			if Prod <> "" then
				if Request("alterar").Count>0 then
					' Tenta alterar efetivamente os dados do item.
					select case AlteraProduto
						case 0 ' Alteração com sucesso
							Response.Write "Produto <b>" & Request("nome") & "</b> (" &_
											Request("codigo") & ") " & "alterado com sucesso. " & vbcrlf
							LinkVolta Request("volta")
							FormularioAlteraProduto Prod,TRUE,FALSE
						case 1 ' Erro em algum campo						
							FormularioAlteraProduto Prod,FALSE,FALSE
						case 2 ' Formulário alterado por outra janela ou pessoa (neste caso, desabilita envio do formulário)
							LinkVolta Request("volta")
							FormularioAlteraProduto Prod,FALSE,TRUE
					end select
				else
					FormularioAlteraProduto Prod,TRUE,FALSE
				end if
			else
				Acao = ""
				Terminou = FALSE
			end if
		
		' EXCLUSAO DE UM ITEM
		case "remover"
			if Prod <> "" then
				if Request("remover").Count>0 then
					' Tenta alterar efetivamente os dados do item.
					if RemoveProduto then
						Response.Write "Produto <b>" & Request("nome") & "</b> ("
						Response.Write Request("codigo") & ") "
						Response.Write "removido com sucesso. " & vbcrlf
						LinkVolta Request("volta")
					else
						FormularioRemoveProduto Prod
					end if
				else
					FormularioRemoveProduto Prod
				end if
			else
				Acao = ""
				Terminou = FALSE
			end if

		' HISTÓRICO (TIME MACHINE) DE UM ITEM
		case "timemachine"
			if Prod <> "" and Request("ord").Count>0 then
				MostraTimeMachine Request("ord"),Prod
			end if
		
	end select
loop while not Terminou

FechaConexao
LinkMenu
Rodape

'---------------------------------------------------
' FIM DO SCRIPT PRINCIPAL
'---------------------------------------------------

' Mostra o menu principal de opcoes
sub MenuPrincipal
	FormularioProcuraProdutos
	' Formulario de insercao de novo item
	if AlterarBasico or AlterarAvancado or AlterarAdmin then
		FormularioIncluiProduto TRUE,TRUE
	end if
end sub

'---------------------------------------------------

' Cria uma combobox ou um campo "hidden" do formulário,
' conforme a flag MostraCombo.
sub CriaComboOuHidden(Nome,Itens,Selecionado,MostraCombo)
	dim Key

	if MostraCombo then
		CriaCombo Nome,Itens,Selecionado
	else
		' Mostra nome do item selecionado.
		for each Key in Itens.Keys
			if Itens(Key) = Selecionado then Response.Write Key
		next
		' Mostra campo hidden.
		Response.Write "<input type=""hidden"" name=""" & Nome & """ value=""" & Selecionado & """>"
	end if
end sub

'---------------------------------------------------

' Mostra uma lista de radio buttons ou um campo "hidden" do formulário,
' conforme a flag MostraRadio.
sub CriaRadioOuHidden(Nome,Itens,Selecionado,Separador,MostraRadio)
	dim Key
	
	if MostraRadio then
		CriaRadio Nome,Itens,Selecionado,Separador
	else
		' Mostra nome do item selecionado.
		for each Key in Itens.Keys
			if Itens(Key) = Selecionado then Response.Write Key
		next
		' Mostra campo hidden.
		Response.Write "<input type=""hidden"" name=""" & Nome & """ value=""" & Selecionado & """>"
	end if
end sub

'---------------------------------------------------

' Apresenta o formulario para criar um produto atributo.
sub FormularioIncluiAtributo(Limpa,NovoCod,Atributo_de)
	dim R
	dim Cod
	dim SN
	dim Cats, CatsRev
	dim Sel
	dim F, H
	dim Agrupador
	dim Cor, Cor1, Cor2, TrocaCor
	dim RecFornecedor, Query, MargemVenda,DescontoLojas
	
	set R = Request
	set Agrupador=ProcuraProdutoPorCodigo(Atributo_de)
			
	set SN = Server.CreateObject("Scripting.Dictionary")
	SN.Add "Sim",1
	SN.Add "Não",0
	
	TrocaCor = 0
	Cor1 = "formescuro"
	Cor2 = "formclaro"
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)

	' Mostra formulario para inclusao	
	Response.Write "<table id=""padding3px"" style=""width:100%;"">" & vbcrlf
	
	Cod = R("codigo")
	Response.Write "<tr class=""" & Cor & """><td class=""direita"" style=""width:150px;"">"
	Response.Write "Código:</td><td>"
	Response.Write "<input type=""text"" size=""7"" maxlength=""7"" name=""codigo"" value="""
	Response.Write NovoCod
	Response.Write """></td></tr>"

	H = Agrupador("nome")
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Nome:</td><td>"
	Response.Write "<input type=""hidden"" name=""nome"" value="""
	Response.Write ConverteFormulario(H)
	Response.Write """><b>"
	Response.Write H
	Response.Write "</b></td></tr>"
	
	ObtemListaCategorias Cats, CatsRev
	Cats.Add "N/C","0"
	Sel=cstr(Agrupador("categoria"))
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Seção:</td><td>"
	CriaCombo "categoria",Cats,Sel
	Response.Write "</td></tr>"
	
	Sel=cstr(Agrupador("categoria2"))
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Seção2:</td><td>"
	CriaCombo "categoria2",Cats,Sel
	Response.Write "</td></tr>"
	
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Tem atributos:</td><td>"
	Response.Write "<input type=""hidden"" name=""tenho_atributos"" value=""0""><b>"
	Response.Write "Não"
	Response.Write "</b></td></tr>"
	
	Sel = R("sou_atributo_de")
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "É um atributo de:</td><td>"
	Response.Write "<input type=""hidden"" name=""sou_atributo_de"" value="""
	Response.Write Sel
	Response.Write """><b>"
	Response.Write Sel
	Response.Write "</b></td></tr>"
	
	' Se apertou o botao de avancar, limpa o restante do formulario
	if R("avancar").Count>0 then Limpa = TRUE
	
	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)	
	Sel = 0
	if Limpa then
		if Agrupador("disponivel") then Sel = 1
	else
		if R("disponivel") then Sel = 1
	end if
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Disponível:</td><td>"
	CriaRadio "disponivel",SN,Sel," " & vbcrlf
	Response.Write "</td></tr>"
	
	Sel = 0
	if Agrupador("eh_destaque") then Sel = 1
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Em destaque:</td><td class=""bold"">"
	Response.Write "<input type=""hidden"" name=""eh_destaque"" value="""
	Response.Write Sel & """>"
	if Sel=1 then
		Response.Write "Sim"
	else
		Response.Write "Não"
	end if
	Response.Write "</td></tr>"
	
	Sel = 0
	if Agrupador("eh_novo") then Sel = 1
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "É novo:</td><td>"
	Response.Write "<input type=""hidden"" name=""eh_novo"" value="""
	Response.Write Sel & """>"
	if Sel=1 then
		Response.Write "Sim"
	else
		Response.Write "Não"
	end if
	Response.Write "</td></tr>"
	
	H = Agrupador("data_lancamento")
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Data de lançamento:</td><td>"
	Response.Write "<input type=""hidden"" name=""data_lancamento"" value="""
	Response.Write FormatDateTime(H,0) & """>" & FormatDateTime(H,0)
	Response.Write "</td></tr>"
	
	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)	
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Descrição do atrib.:</td><td>"
	Response.Write "<input type=""text"" size=""40"" maxlength=""50"" name=""descricao"" value="""
	if not Limpa and R("avancar").Count<=0 then Response.Write ConverteFormulario(R("descricao"))
	Response.Write """></td></tr>"
	if Trim(R("descricao"))="" then FocoFormulario "f","descricao"
	
	H = Agrupador("peso")
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Peso:</td><td>" & H & " gramas"
	Response.Write "<input type=""hidden"" name=""peso"" value=""" & H & """>"
	Response.Write "</td></tr>"

	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Custo tabela (R$):</td><td>"
	Response.Write "<input type=""text"" size=""8"" maxlength=""8"" name=""custo_tabela"" value="""
	if Limpa then
		Response.Write FormataDinheiro(Agrupador("custo_tabela"))
	else
		Response.Write FormataDinheiro(R("custo_tabela"))
	end if
	Response.Write """ class=""direita"" style=""width:60px;""> <span class=""pequeno"">(preço de tabela do fornecedor)</span></td></tr>"

	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Custo atacado (R$):</td><td>"
	Response.Write "<input type=""text"" size=""8"" maxlength=""8"" name=""custo_atacado"" value="""
	if Limpa then
		Response.Write FormataDinheiro(Agrupador("custo_atacado"))
	else
		Response.Write FormataDinheiro(R("custo_atacado"))
	end if
	Response.Write """ class=""direita"" style=""width:60px;""> <span class=""pequeno"">(considerar apenas o desconto fixo para atacado)</span></td></tr>"
	
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Custo final (R$):</td><td>"
	Response.Write "<input type=""text"" size=""8"" maxlength=""8"" name=""custo_final"" value="""
	if Limpa then
		Response.Write FormataDinheiro(Agrupador("custo_final"))
	else
		if Trim(R("custo_final"))="" then
			Response.Write FormataDinheiro(0)
		else
			Response.Write FormataDinheiro(R("custo_final"))
		end if
	end if
	Response.Write """ class=""direita"" style=""width:60px;"">"
	Response.Write " <span class=""pequeno"" style=""display:inline-block;width:300px;vertical-align:top;"">(preço real pago por unidade nesta compra, incluindo frete e descontos)</span></td></tr>"

	' Obtem margens de venda no cadastro do fornecedores
	TrocaCor = TrocaCor + 1
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)
	MargemVenda = 0
	DescontoLojas = 0
	if Agrupador("fornecedor")<>0 then
		Query = "SELECT margem_venda, desconto_lojas FROM Fornecedores WHERE codigo=" & Agrupador("fornecedor")
		set RecFornecedor = Server.CreateObject("ADODB.Recordset")
		RecFornecedor.CursorLocation = adUseClient
		RecFornecedor.Open Query,Conexao,adOpenForwardOnly,adLockReadOnly,adCmdText
		MargemVenda = RecFornecedor("margem_venda")
		DescontoLojas = RecFornecedor("desconto_lojas")
		RecFornecedor.Close
		set RecFornecedor = Nothing

		Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
		Response.Write "Margem de venda:</td><td>" & FormataDinheiro(MargemVenda) & "%" 
		Response.Write " <span class=""pequeno"">(conforme o cadastro do fornecedor)</span></td></tr>"	
	
		Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
		Response.Write "Desconto p/ lojas:</td><td>" & FormataDinheiro(DescontoLojas) & "%" 
		Response.Write " <span class=""pequeno"">(conforme o cadastro do fornecedor)</span></td></tr>"	
	else
		Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
		Response.Write "Margem de venda:</td><td>Não consta</td></tr>"	
	
		Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
		Response.Write "Desconto p/ loja:</td><td>Não consta</td></tr>"	
	end if

	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)
	H = FormataDinheiro(Agrupador("preco_atacado"))
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Preço atacado (R$):</td><td>"
	Response.Write "<input type=""hidden"" name=""preco_atacado"" value="""
	Response.Write H
	Response.Write """><b>"
	Response.Write H
	Response.Write "</b> <span class=""pequeno"">(preço diferenciado para vendas em atacado)</span>"
	Response.Write "</td></tr>"
		
	Sel = 0
	if Agrupador("eh_promocao") then Sel = 1
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Em promoção:</td><td class=""bold"">"
	Response.Write "<input type=""hidden"" name=""eh_promocao"" value="""
	Response.Write Sel & """>"
	if Sel=1 then
		Response.Write "Sim"
	else
		Response.Write "Não"
	end if
	Response.Write "</td></tr>"

	H = FormataDinheiro(Agrupador("preco_nao_promocional"))
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Preço normal varejo (R$):</td><td>"
	Response.Write "<input type=""hidden"" name=""preco_nao_promocional"" value="""
	Response.Write H
	Response.Write """><b>"
	Response.Write H
	Response.Write "</b> <span class=""pequeno"">(valor não-promocional, mostrado se estiver na promoção)</span>"
	Response.Write "</td></tr>"
	
	H = FormataDinheiro(Agrupador("preco"))
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Preço venda varejo (R$):</td><td>"
	Response.Write "<input type=""hidden"" name=""preco"" value="""
	Response.Write H
	Response.Write """><b>"
	Response.Write H
	Response.Write "</b> <span class=""pequeno"">(preço final de venda, independente se é promoção ou não)</span>"
	Response.Write "</td></tr>"

	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)	
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Estoque:</td><td>"
	Response.Write "<input type=""text"" size=""4"" maxlength=""4"" name=""estoque"" value="""
	if not Limpa then
		Response.Write R("estoque")
	else
		Response.Write ""
	end if
	Response.Write """ style=""margin-right:20px;""> Etiquetas: <input type=""text"" size=""4"" maxlength=""4"" name=""etiquetas"" value="""
	Response.Write Request("etiquetas") & """>"
	Response.Write "</td></tr>"
	
	Sel = 0
	if Limpa then
		Sel = 1
	else
		if R("precisa_estoque") then Sel = 1
	end if
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Só vende com estoque:</td><td>"
	CriaRadio "precisa_estoque",SN,Sel," " & vbcrlf
	Response.Write "</td></tr>"
		
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Ponto de pedido:</td><td>"
	Response.Write "<input type=""text"" size=""4"" maxlength=""4"" name=""ponto_pedido"" value="""
	if Limpa then
		Response.Write Agrupador("ponto_pedido")
	else
		Response.Write R("ponto_pedido")
	end if
	Response.Write """> <span class=""pequeno"">(preencher ""-1"" caso este produto tenha saído de linha)</td></tr>"
	
	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)	
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Código p/ fornecedor:</td><td>"
	Response.Write "<input type=""text"" size=""10"" maxlength=""10"" name=""codigo_fornecedor"" value="""
	if Limpa then
		Response.Write Agrupador("codigo_fornecedor")
	else
		Response.Write R("codigo_fornecedor")
	end if
	Response.Write """></td></tr>"

	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Nome p/ fornecedor:</td><td>"
	Response.Write "<input type=""text"" size=""40"" maxlength=""50"" name=""nome_fornecedor"" value="""
	if Limpa then
		Response.Write Agrupador("nome_fornecedor")
	else
		Response.Write R("nome_fornecedor")
	end if
	Response.Write """> &nbsp;<a href=""javascript://"" align=""right"" onClick=""CopiaNomeParaFornecedor();"" class=""botaopeq"">Copiar nome</a>"
	Response.Write "</td></tr>"
		
	set F = ObtemListaFornecedores
	F.Add "N/C","0"
	Sel = "0"
	if Limpa then
		Sel = cstr(Agrupador("fornecedor"))
	else
		Sel = cstr(R("fornecedor"))
	end if
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Fornecedor:</td><td>"
	CriaCombo "fornecedor",F,Sel
	Response.Write "</td></tr>"
	
	H = Agrupador("imagem") 
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Imagem pequena:</td><td class=""bold"">"
	Response.Write "<input type=""hidden"" name=""imagem"" value="""
	Response.Write H & """>"
	if H = "" then
		Response.Write "<span class=""pequeno"">(nenhuma imagem definida)</span>"
	else
		Response.Write H
	end if
	Response.Write "</td></tr>"
		
	H = Agrupador("imagem_zoom") 
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "Imagem grande:</td><td class=""bold"">"
	Response.Write "<input type=""hidden"" name=""imagem_zoom"" value="""
	Response.Write H & """>"
	if H = "" then
		Response.Write "<span class=""pequeno"">(nenhuma imagem definida)</span>"
	else
		Response.Write H
	end if
	Response.Write "</td></tr>"
	
	TrocaCor = TrocaCor + 1
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)
	H = HTMLEncode(R("obs"))
	if instr(H,chr(13))=1 or instr(H,chr(10))=1 then H = "&#13;&#10;" & H
	Response.Write "<tr class=""" & Cor & """><td class=""direita"">"
	Response.Write "OBS:</td><td>"
	Response.Write "<textarea name=""obs"" rows=""6"" style=""width:380px"">"
	if not Limpa then Response.Write H
	Response.Write "</textarea></td></tr>"

		
	TrocaCor = TrocaCor + 1		
	Cor = AlternaCorTabela(TrocaCor,Cor1,Cor2)	
	Response.Write "<tr class=""" & Cor & """><td></td><td>"
	Response.Write "<input type=""submit"" name=""incluir"" value=""Incluir novo atributo"" style=""width:200px;margin:4px 0px 4px 0px;""></td>"

	Response.Write "</tr></table>" & vbcrlf
	
	' Armazena URL da pagina anterior.
	Response.Write "<input type=""hidden"" name=""volta"" value="""
	if Request("volta")<> "" then
		Response.Write Request("volta")
	else
		Response.Write Request.ServerVariables("HTTP_REFERER")
	end if
	Response.Write """>"
	
	Agrupador.Close
	set Agrupador = Nothing
	SN.RemoveAll
	set SN = Nothing
	Cats.RemoveAll
	set Cats = Nothing
	CatsRev.RemoveAll
	set CatsRev = Nothing
	F.RemoveAll
	set F = Nothing
end sub

'---------------------------------------------------

' Inclui um novo item
function IncluiProduto()
	dim R,Query
	dim Key, Value
	dim Agora
	dim Cod
	dim Estoque
	dim SouAtributoDe
	dim Campo
	dim Numericos,Completo
	
	Agora = Now()
	
	' Valida os dados.
	IncluiProduto = FALSE
	if Trim(Request("codigo")) = "" then
		Erro "É necessário fornecer um código!"
		exit function
	end if
	Cod = Trim(Request("codigo"))
	if Trim(Request("nome")) = "" then
		Erro "É necessário fornecer um nome!"
		exit function
	end if
	if Trim(Request("sou_atributo_de")) <> "" and Trim(Request("descricao")) = "" then
		Erro "É necessário fornecer uma descrição para o atributo!"
		exit function
	end if
	if ExisteProduto(Cod) then
		Erro "Já existe um produto com esse código (" & Cod & ") !"
		exit function
	end if
	Estoque = Trim(Request("estoque"))
	if not isNumeric(Estoque) then
		Erro "É necessário inserir um valor válido para o estoque !"
		exit function
	end if
	Estoque = clng(Estoque)
	if not isNumeric(Request("ponto_pedido")) then
		Erro "É necessário inserir um valor válido para o ponto de pedido !"
		exit function
	end if
	SouAtributoDe = Trim(Request("sou_atributo_de"))
	if SouAtributoDe<>"" then
		if not ExisteProduto(SouAtributoDe) then
			Erro "Não existe produto agrupador com o código <b>" & SouAtributoDe & "</b> !"
			exit function
		end if
	end if
	
	' Verifica se os campos numéricos foram corretamente digitados
	Numericos = Array("peso","custo_tabela","custo_atacado","custo_final","preco_atacado","preco","ponto_pedido")
	Completo = True
	for each Campo in Numericos
		if Request(Campo).Count>0 then
			if not isnumeric(Replace(trim(Request(Campo)),".",",")) then
				Completo = False
			end if
		else
			Completo = False
		end if
	next
	if not Completo then
		Erro "Você usou caracteres inválidos ao preencher algum dos campos numéricos."
		exit function
	end if
	
	' Não deixa cadastrar produto com custo zero.
	if cdbl(Request("custo_final"))=0 then
		Erro "Não é possível incluir um produto com custo final zero!"
		exit function
	end if

	' Obtem os nomes dos campos e valores a serem inseridos
	AbreConexao
	set R = Server.CreateObject("ADODB.Recordset")
	R.CursorLocation = adUseServer
	R.Open "Produtos",Conexao,adOpenForwardOnly,adLockOptimistic,adCmdTable
	R.AddNew
	for each Key in Request.Form
		if Key <> "volta" and Key <> "incluir" and Key <> "etiquetas" then
			Value = Trim(Request(Key))
			select case Key
				' Inicializa custo medio com o custo final.
				case "custo_final"
					Value = FormataDinheiro(Value)
					R("custo_medio") = Value
				case "detalhes", "descricao", "nome"
					Value = ConverteSimboloCopyright(Value)
				case "peso","custo_tabela","custo_atacado","custo_final","custo_medio","preco","preco_nao_promocional","preco_atacado"
					Value = FormataDinheiro(Value)
			end select
			R(Key) = Value
		end if
	next
	R("unidades_compradas") = Estoque
	R("unidades_vendidas") = 0
	R("data_ultima_compra") = Agora
	' Se o campo "preco_nao_promocional" estiver desabilitado, iguala-o ao preço de venda.
	if Request("preco_nao_promocional").Count=0 then R("preco_nao_promocional") = FormataDinheiro(Request("preco"))
	R.Update
	R.Close
	
	' Cria o texto para o mecanismo de busca (tabela ProdutosBusca).
	R.Open "ProdutosBusca",Conexao,adOpenForwardOnly,adLockOptimistic,adCmdTable
	R.AddNew
	R("codigo") = Trim(Request("codigo"))
	R("texto") = Trim(Request("nome")) & " " & Trim(Request("descricao")) & " " & Trim(Request("detalhes"))
	R.Update
	R.Close
		
	' Se é um atributo, seta o campo "tenho_atributos" do produto agrupador
	' e ajusta a data da última compra.
	if SouAtributoDe<>"" then
		' Refaz calculo de estoque e estatisticas do produto agrupador.
		RecalculaDadosAgrupador(SouAtributoDe)
	end if

	' Cria um registro histórico (snapshot) do produto.
	CriaTimeMachineProduto(Cod)
	
	' Gera etiquetas, se solicitado.	
	if isNumeric(Request("etiquetas")) then
		if clng(Request("etiquetas"))>0 then GeraEtiquetasProdutos Cod,Request("etiquetas")
	end if

	' Registra alteração.
	if Estoque=1 then
		RegistraAcao "Incluiu o produto " & Cod & " (1 unidade)."
	else
		RegistraAcao "Incluiu o produto " & Cod & " (" & Estoque & " unidades)."
	end if

	set R = Nothing
	' Item incluido com sucesso
	IncluiProduto = TRUE	
end function

'---------------------------------------------------

' Obtem proximo codigo livre, conforme a categoria e conforme
' o codigo do produto agrupador (no caso deste produto representar
' apenas um atributo).
function CodigoLivre(Categoria,ProdutoAgrupador)
	dim R, Query
	dim NovoCod
	dim Cod
	
	AbreConexao
	set R = Server.CreateObject("ADODB.Recordset")
	R.CursorLocation = adUseClient

	' Valida produto agrupador
	if ProdutoAgrupador<>"" then
		' No caso deste produto ser um atributo, pesquisa os outros atributos
		' do mesmo produto.
		ProdutoAgrupador = right("000000" & ProdutoAgrupador,7)
		Query = "SELECT codigo FROM Produtos WHERE codigo LIKE '" & left(ProdutoAgrupador,6) & "%' ORDER BY codigo"
		R.Open Query,Conexao,adOpenForwardOnly,adLockReadOnly,adCmdText
	else
		' No caso deste produto ser um produto sem atributos ou um produto
		' agrupador, pesquisa todos os produtos (nao atributos) da mesma
		' categoria.
		Query = "SELECT codigo FROM Produtos WHERE codigo LIKE '" & FormataCodigo(Categoria,4) & "%A' ORDER BY codigo"
		R.Open Query,Conexao,adOpenForwardOnly,adLockReadOnly,adCmdText
	end if

	' Fecha a conexao o mais breve possivel
	R.ActiveConnection = Nothing
	
	if ProdutoAgrupador<>"" then
		' Calcula novo codigo no caso deste produto ser um atributo.
		' O novo codigo e' igual ao produto agrupador, mas com a letra
		' final diferente.
		NovoCod = ASC("A")
		do while not R.EOF
			Cod = asc(right(R("codigo"),1))
			if Cod > NovoCod then exit do
			if Cod = NovoCod then NovoCod = Cod + 1
			R.MoveNext
		loop
		NovoCod = left(ProdutoAgrupador,6) & chr(NovoCod)
	else
		' Calcula novo codigo no caso deste produto ser um produto agrupador.
		' O novo codigo sempre termina com a letra "A", indicando ser um
		' produto sem atributos ou um produto agrupador.
		NovoCod = 1
		do while not R.EOF
			Cod = cint(mid(R("codigo"),5,2))
			if Cod > NovoCod then exit do
			if Cod = NovoCod then NovoCod = Cod + 1
			R.MoveNext
		loop
		NovoCod = FormataCodigo(Categoria,4) & FormataCodigo(NovoCod,2) & "A"
	end if
	
	' Fecha recordeset.
	R.Close
	set R = Nothing
	CodigoLivre = NovoCod
end function

'---------------------------------------------------

' Verifica se ja' existe um item com um certo codigo
function ExisteProduto(Cod)
	dim R, Query
	
	' Busca os itens
	AbreConexao
	Query = "SELECT codigo FROM Produtos WHERE codigo = '" & Cod & "'"
	set R = Server.CreateObject("ADODB.Recordset")
	R.CursorLocation = adUseClient
	R.Open Query,Conexao,adOpenForwardOnly,adLockReadOnly,adCmdText
	
	ExisteProduto = FALSE
	if not R.EOF and not R.BOF then ExisteProduto = TRUE
	
	R.Close
	set R =	Nothing
end function


'---------------------------------------------------

' Verifica se existem produtos que apontam este código como sendo seu agrupador.
function PossuiAtributos(Cod)
	dim R, Query
	
	' Busca os itens
	AbreConexao
	Query = "SELECT count(codigo) as total FROM Produtos WHERE sou_atributo_de = '" & Cod & "'"
	set R = Server.CreateObject("ADODB.Recordset")
	R.CursorLocation = adUseClient
	R.Open Query,Conexao,adOpenForwardOnly,adLockReadOnly,adCmdText
	
	PossuiAtributos = 0
	if not R.EOF and not R.BOF then PossuiAtributos = R("total")
	
	R.Close
	set R =	Nothing
end function

'---------------------------------------------------

' Mostra formulario para upload das imagens de um produto
sub FormularioUpload(Cod)
	dim R
	
	if not AlterarAdmin then
		exit sub
	end if

	' Mostra formulario
	CabecalhoTabela "Enviar as imagens deste produto (" & Cod & ")"
	Response.Write "<form method=""post"" action=""" & Application("URL_Seguro") & "admin/upload_imagens.asp"" enctype=""multipart/form-data"" class=""nomargnopad"">"
	Response.Write "<p style=""margin-bottom:8px""><b>Atenção:</b> as alterações feitas no formulário acima serão perdidos se não for pressionado o botão ""Alterar dados"" <b>antes</b> de enviar as imagens!</P>"
	Response.Write "<table id=""padding3px"">" & vbcrlf
	
	Response.Write "<tr><td class=""direita"">"
	Response.Write "Imagem pequena:</td><td>"
	Response.Write "<input type=""file"" size=""30"" name=""imagem"" value="""">"
	Response.Write "</td></tr>"
	
	Response.Write "<tr><td class=""direita"">"
	Response.Write "Imagem grande (detalhe):</td><td>"
	Response.Write "<input type=""file"" size=""30"" name=""imagem_zoom"" value="""">"
	Response.Write "</td></tr>"
	
	Response.Write "<tr><td></td><td>"
	Response.Write "<input type=""hidden"" name=""prod"" value=""" & Cod & """>"
	Response.Write "<input type=""submit"" name=""enviar"" value=""Enviar imagens""></td>"
	Response.Write "</tr></table>" & vbcrlf
	
	' Armazena URL desta pagina.
	Response.Write "<input type=""hidden"" name=""volta"" value="""
	Response.Write Eu & "?" & Request.ServerVariables("QUERY_STRING")
	Response.Write """>"
	
	Response.Write "</form>"
	
	RodapeTabela

end sub

'---------------------------------------------------

' Mostra formulario de alteracao de um item
sub FormularioAlteraProduto(Cod,UsarBaseDeDados,ApenasMostra)
	dim R

	' Obtem recordset do item a ser alterado
	set R = ProcuraProdutoPorCodigo(Cod)
	if R.EOF then
		Erro "Produto " & Cod & " não encontrado!"
		exit sub
	end if

	' Verifica se pode alterar o cadastro do pedido
	if not AlterarBasico and not AlterarAvancado and not AlterarAdmin then ApenasMostra = true

	' Mostra formulario
	CabecalhoTabela "Alterar um produto"
	if not ApenasMostra then Response.Write "<form method=""post"" action=""" & Eu & "?acao=alterar&prod=" & Cod & """ name=""f"" class=""nomargnopad"" >"

	MostraImagemProduto R("imagem_zoom"),R("imagem")
	Response.Write "<table id=""padding3px"" style=""width:556px;"">" & vbcrlf
	
	if UsarBaseDeDados then
		MostraDadosProduto R,R
	else
		MostraDadosProduto Request.Form,R
	end if
		
	if not ApenasMostra then
		Response.Write "<tr><td></td><td>"
		Response.Write "<input type=""submit"" name=""alterar"" value=""Alterar dados"" style=""width:200px;margin-top:8px;"">"
		Response.Write "</td></tr></table>" & vbcrlf
		
		' Armazena URL da pagina anterior.
		Response.Write "<input type=""hidden"" name=""volta"" value="""
		if Request("volta")<> "" then
			Response.Write Request("volta")
		else
			Response.Write Request.ServerVariables("HTTP_REFERER")
		end if
		Response.Write """>"

		RegistraDadosAtuais R
		Response.Write "</form>"

		Response.Write  vbcrlf & "<script language=""Javascript"">" & vbcrlf
		Response.Write "AlteraPrecoPromocional();" & vbcrlf
		Response.Write "</script>" & vbcrlf
	else
		Response.Write "</table>" & vbcrlf
	end if

	RodapeTabela

	' Só permite  alterar as imagens se não for um atributo.
	if not ApenasMostra and R("sou_atributo_de")="" then FormularioUpload(Cod)

	' Fecha recordeset.
	R.Close
	set R = Nothing
end sub

'---------------------------------------------------

' Registra os dados atuais do cadastro para que sejam comparados posteriormente pela função DadosMudaramEmBackground.
sub RegistraDadosAtuais(R)
	dim Compara
	dim Campo, Conteudo
	
	Compara = Array(	"codigo", _
						"nome", "categoria", _
						"categoria2", "tenho_atributos", _
						"sou_atributo_de", "disponivel", _
						"eh_destaque", "eh_promocao", _
						"eh_novo", "data_lancamento", "descricao", _
						"detalhes",	"peso", _
						"custo_tabela", "custo_atacado", _
						"custo_final", "custo_medio", _
						"preco", "preco_nao_promocional", _
						"preco_atacado", "precisa_estoque", _
						"ponto_pedido", "codigo_fornecedor", _
						"nome_fornecedor", "fornecedor", _
						"imagem", "imagem_zoom", _
						"obs")

	for each Campo in Compara
		Conteudo = R(Campo)
		select case Campo
			case "obs","detalhes"
				Conteudo = HTMLEncode(Conteudo)
				if instr(Conteudo,chr(13))=1 or instr(Conteudo,chr(10))=1 then Conteudo = "&#13;&#10;" & Conteudo
				Response.Write "<textarea style=""display:none"" name=""z_" & Campo & """>" & Conteudo & "</textarea>"

			case "data_lancamento"
				Conteudo = FormataDataSQL(Conteudo) & " " & FormataHora(Conteudo)
				Response.Write "<input type=""hidden"" name=""z_" & Campo & """ value=""" & Conteudo & """>"

			case else		
				Response.Write "<input type=""hidden"" name=""z_" & Campo & """ value=""" & HTMLEncode(Conteudo) & """>"
		end select
	next
end sub

'---------------------------------------------------

' Verifica se uma segunda pessoa alterou o cadastro em background.
function DadosMudaramEmBackground(R)
	dim Cmd, Key, Value
	
	AbreConexao
	set Cmd = Server.CreateObject("ADODB.Command")
	Cmd.ActiveConnection = Conexao
	Cmd.CommandType = adCmdStoredProc
	Cmd.CommandText = "erosmania_ComparaProduto"
	Cmd.Parameters.Refresh
	Cmd("@codigo")= R("codigo")
	for each Key in Request.Form
		if left(Key,2)="z_" then
			Value = Trim(Request(Key))
			Cmd("@" & Mid(Key,3)) = Value
		end if
	next
	Cmd.Execute ,, adExecuteNoRecords
	if Cmd(0)=0 then 'Cmd(0) = RetVal
		DadosMudaramEmBackground = true
	else
		DadosMudaramEmBackground = false
	end if

	set Cmd = Nothing
end function

'---------------------------------------------------

' Remove um item
function LastFunction()
	dim Query
	dim Cod
	dim CodParcial
	
	' Valida os dados se naum for a primeira chamada
	' (na primeira chamada, nao haveria o campo "codigo".
	RemoveProduto = FALSE
	if Trim(Request("codigo")) = "" then
		Erro "É necessário fornecer um código!"
		exit function
	end if
	Cod = Trim(Request("codigo"))

	Query = "DELETE FROM Produtos WHERE codigo='" & Cod & "'"
	AbreConexao
	Conexao.Execute Query,,adCmdText
	
	if Request("tenho_atributos") then
		CodParcial = left(string("0",6) & Cod,6)
		' Apaga todos os atributos deste produto agrupador
		Query = "DELETE FROM Produtos WHERE sou_atributo_de ='" & Cod & "'"
		Conexao.Execute Query,,adCmdText
	
		' Não precisa apagar brindes porque a base de dados já faz isso automaticamente
		'Query = "DELETE FROM Brindes WHERE codigo_brinde LIKE '" & CodParcial & "%'"
		'Conexao.Execute Query,,adCmdText
		
		RegistraAcao "Removeu o produto " & Cod & " e todos os seus atributos."
	else
		' Não precisa apagar brindes porque a base de dados já faz isso automaticamente
		'Query = "DELETE FROM Brindes WHERE codigo_brinde = '" & Cod & "'"
		'Conexao.Execute Query,,adCmdText
	
		RegistraAcao "Removeu o produto " & Cod & "."
	end if

	' Se e' um atributo, refaz calculo de estoque do produto agrupador
	if Request("sou_atributo_de")<>"" then RecalculaDadosAgrupador(Request("sou_atributo_de"))
	
	RemoveProduto = TRUE
end function

%>
