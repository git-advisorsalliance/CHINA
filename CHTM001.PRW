#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include 'TopConn.ch'
#Include "FwBrowse.ch"

/*/{Protheus.doc} CHTM001()
Importação dos movimentos fiscais de NFS-e
@author  Leandro Heilig
@since   01/08/2019
@version undefine
@type    function
/*/
User Function CHTM001()

	Local aSays      	:= {}
	Local aButtons   	:= {}
	// Local nOpcA      	:= 0
	Local cTitulo	  	:= "Importação de movimentos fiscais"

	Private cPerg      	:= PadR("CHTM001", 10)
	Private nOpcSel	   	:= 0
	Private cDirFile   	:= ""
	Private oFile      	:= Nil
	Private aAllLines  	:= {}
	Private aArqLog		:= {}
	Private cMsgLog	   	:= ""
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.
	Private cCadastro 	:= "Log de Operações"

	// --> Ajusta o grupo de perguntas
	AjustaX1()

	// --> Cria o diretório para salvar os logs do execauto
	If !ExistDir("\log_mov_fiscais")
		MakeDir("\log_mov_fiscais")
	EndIf

	cPerg := Padr( cPerg, 10 )
	Pergunte(cPerg,.F.)

	//+-----------------------------------------------------+
	//| Monta a tela inicial da rotina                      |
	//+-----------------------------------------------------+
	AADD(aSays,"   Esta rotina tem como objetivo realizar a importação ")
	AADD(aSays,"   de arquivo .csv com informações para a criação      ")
	AADD(aSays,"   de clientes e pedidos de venda.                     ")	
	AADD(aSays,"   Versão 1.20250521                                   ")

	AADD(aButtons, { 5,.T.,{|o| Pergunte(cPerg,.T.) }} )
	AADD(aButtons, { 1,.T.,{|o| Cht001Prc(), o:oWnd:End() }} )
	AADD(aButtons, { 2,.T.,{|o| o:oWnd:End() }} )

	FormBatch( cTitulo, aSays, aButtons,,200,405 )

	return

	/*/{Protheus.doc} Cht001Prc()
	Efetua o processamento de acordo com a opção selecionada
	@author  Leandro Heilig
	@since   01/08/2019
	@version undefined
	@type    function
	/*/
Static Function Cht001Prc()

	nOpcSel	:= mv_par01//3 //mv_par01
	cDirFile := mv_par02//"C:\leandro\Tecnvs\OneDrive\Clientes\TrueCPA\ID001 - Integração Fiscal\Teste_002_20190805.csv"//mv_par02

	If nOpcSel == 1
		Processa( {|| ChImpCSV() }, "Aguarde...", "Importando Arquivo", .F. ) 
	ElseIf nOpcSel == 2
		ChtPrZ01() // --> Função para processamento dos dados
	ElseIf nOpcSel == 3
		Processa( {|| ChImpCSV() }, "Aguarde...", "Importando Arquivo", .F. )
		ChtPrZ01() // --> Função para processamento dos dados
	EndIf	
	// --> Apresenta o log
	ShowLOG()

Return


/*/{Protheus.doc} ChImpCSV
Importação do arquivo CSV e gravação da tabela Z01
@author  Leandro Heilig
@since   01/08/2019
@version undefined
@type    function
/*/
Static Function ChImpCSV()

	Local lOpen := .F.	
	Local nTotLinhas := 0

	oFile := FWFileReader():New( AllTrim(cDirFile) )

	If ( oFile:Open() )
		lOpen := .T.
	Else
		MsgAlert("Não foi possível realizar a abertura do arquivo.", "Atenção")
	EndIf

	If lOpen	
		If ! (oFile:EoF())	
			//aAllLines := ReaderFile()	
			aAllLines := oFile:GetAllLines()
			nTotLinhas := Len(aAllLines)
			ProcRegua(nTotLinhas)
			//Método GoTop não funciona (dependendo da versão da LIB), deve fechar e abrir novamente o arquivo
			oFile:Close()
			oFile := FWFileReader():New(cDirFile)
			oFile:Open()
			// --> Efetua a gravação dos registros na Z01
	`		If !(Len(aAllLines) < 1)
				GravaZ01()
			Else
				FwAlertError("A Estrutura do Arquivo esta inválida.", "Atenção")
			EndIf	
		EndIf
	EndIf

Return


/*/{Protheus.doc} ReaderFile
Retorna as linhas do arquivo CSV
@author  Leandro heilig
@since   02/08/2019
@version undefined
@type    function
/*/
Static Function ReaderFile()

	Local aLines := {}
	Local nCont  := 0
	Local aAux   := {}

	ProcRegua( oFile:GetFileSize() )

	While( oFile:HasLine() )		
		nCont ++
		IncProc("Processando linha: " + AllTrim(Str(nCont)) )
		aAux := Separa( oFile:GetLine(), ";", .T. )
		If Len(aAux) == 29
			If IsDigit(aAux[1])
				//			If AsCan( aLines, {|x| x[17] == aAux[17]} ) <= 0
				AAdd( aLines, aAux)
				//			EndIf
			Endif
		Else
			cMsgLog := "Linha "+AllTrim(Str(nCont))+" com erro ou inválida ! Verifique as colunas e as informações do arquivo."
			Aadd(aArqLog, {"", cMsgLog} )
		EndIf		
		aAux := {}		
	EndDo	
	oFile:Close()	

Return(aLines)


/*/{Protheus.doc} GravaZ01
Função para gravar na tabela Z01
@author  Leandro Heilig
@since   02/08/2019
@version undefined
@type    function
/*/
Static Function GravaZ01()

	Local nX	  := 0
	Local aArea   := GetArea()
	Local cCgc    := ""
	Local cCodZ01 := ""
	Local cCodUsr := RetCodUsr()
	Local dData   := dDataBase
	Local lIgnor01   := FWAlertYesNo('Deseja ignorar a linha 1 do arquivo?', 'Ignorar?')
	Local nLinhaAtu  := 0
	Local cLinAtu    := ''
	Local nTotLinhas := 0
	Local cMedido    := ""

	Private cSeparador := ';'

	cMedido := cValtoChar(MV_PAR04)

	ProcRegua( Len(aAllLines) )
	Z01->( DbSetOrder(1) )

	Begin Transaction
		While (oFile:HasLine())

			nLinhaAtu++
			IncProc('Analisando linha ' + cValToChar(nLinhaAtu) + ' de ' + cValToChar(nTotLinhas) + '...')

			cLinAtu := oFile:GetLine()
			aAllLines  := Separa(cLinAtu, cSeparador)

			If lIgnor01 .And. nLinhaAtu == 1
				Loop
				//Se houver posições no array
			ElseIf Len(aAllLines) > 0

				If ( !Empty(aAllLines[01]) .And. !Empty(aAllLines[07]) )		

					cCodZ01:= GetSX8Num("Z01", "Z01_CODIGO")
					cCgc   := StrTran(StrTran(StrTran( aAllLines[04], ".", "" ), "-", "" ), "/", "")

					If !(Z01->( DbSeek( xFilial("Z01") + cCodZ01 + aAllLines[04] )))
						RecLock("Z01", .T.)
						Z01->Z01_FILIAL 	:= xFilial("Z01")
						Z01->Z01_CGC 		:= AllTrim(aAllLines[04])
						Z01->Z01_CODIGO	:= cCodZ01 
						Z01->Z01_CODCHT	:= AllTrim(aAllLines[01])
						Z01->Z01_LOJCHT	:= aAllLines[02]
						Z01->Z01_NOME   	:= aAllLines[03]
						Z01->Z01_CODERP	:= Space(06) 
						Z01->Z01_LOJERP	:= Space(02)
						Z01->Z01_CODNAT	:= aAllLines[05]
						Z01->Z01_CODPRO 	:= AllTrim(aAllLines[07])
						Z01->Z01_DESPRO	:= AllTrim(aAllLines[08])
						Z01->Z01_CIRCNR	:= AllTrim(aAllLines[09])
						Z01->Z01_VELOCI	:= AllTrim(aAllLines[10])
						Z01->Z01_QUANT		:= Val(aAllLines[11])
						Z01->Z01_VLRUNI	:= Val( StrTran(StrTran(aAllLines[12], ".", ""), ",", "." ) )
						Z01->Z01_VLRTOT	:= Val( StrTran(StrTran(aAllLines[13], ".", ""), ",", "." ) )
						Z01->Z01_TES		:= aAllLines[14]
						Z01->Z01_CODPAG	:= aAllLines[15]
						Z01->Z01_DTVENC	:= CtoD(aAllLines[16])
						Z01->Z01_COMPET	:= Upper(AllTrim(aAllLines[17]))
						Z01->Z01_FRMPGT	:= Iif( Upper(AllTrim(aAllLines[18]) )=="BOLETO","1","2" )
						Z01->Z01_EMAIL 	:= StrTran(aAllLines[19],"|",";")
						Z01->Z01_END  		:= AllTrim(aAllLines[20])
						Z01->Z01_BAIRRO	:= AllTrim(aAllLines[21])
						Z01->Z01_CEP 		:= AllTrim(aAllLines[22])
						Z01->Z01_CIDADE	:= AllTrim(aAllLines[23])
						Z01->Z01_UF     	:= Upper(AllTrim(aAllLines[24]))
						Z01->Z01_INSCRI 	:= AllTrim(aAllLines[25])
						Z01->Z01_DDD  		:= AllTrim(aAllLines[26])
						Z01->Z01_TEL 		:= AllTrim(aAllLines[27])
						Z01->Z01_CODPV  	:= ""
						Z01->Z01_STATUS	:= "0" // registro gerado, pendente de criação de cliente e pedido
						Z01->Z01_USRCOD	:= cCodUsr
						Z01->Z01_DTIMP 	:= dData 
						Z01->Z01_HRIMP 	:= StrTran( Time(),":","" )
						Z01->Z01_TPNOTA	:= Upper(AllTrim(aAllLines[28]))
						Z01->Z01_MEDIDO	:= cMedido
						Z01->( MsUnlock() )
					EndIf
					ConfirmSX8()
				EndIf
			EndIf	
		enddo
	End Transaction 
	RestArea(aArea)
Return

/*/{Protheus.doc} CHtPrZ01
Realiza a atualização dos dados
@author  Leandro Heilig
@since   03/08/2019
@version undefined
@type    function
/*/
Static Function ChtPrZ01()

	Local bCondCli := {|| Cht001Cli() }
	Local bCondPed := {|| Cht001PV()  }
	//Local bCondNFE := {|| Cht001NFe() }

	// --> Atualiza entidade de clientes
	Processa(bCondCli, "Aguarde", "Atualizando entidade de clientes..." )	
	// --> Gera pedido de vendas
	Processa(bCondPed, "Aguarde", "Gerando Pedido de Vendas..." )	
	// --> Gera nota fiscal 
	//Processa(bCondNFE, "Aguarde", "Gerando documento de saída..." )

	Return

	/*/{Protheus.doc} Cht001Cli()
	Função   para atualizar a entidade de clientes
	@author  Leandro Heilig
	@since   04/08/2019
	@version undefined
	@type    function
	/*/
Static Function Cht001Cli()

	Local aArea   	:= GetArea()
	Local aDadosCli := {} 
	Local cQryCli 	:= ""
	Local cAliasCli := GetNextAlias()
	// Local cNatCli	:= ""
	Local nOpc		:= 3
	Local lAltCli	:= .F.
	Local lIncCli	:= .F.
	Local nQtdReg	:= 0
	Local cCodCli   := ""
	Local cErro     := ""
	Local cArqLog   := ""
	Local cCodCHT   := ""
	Local _Pessoa   := ""

	cQryCli := " SELECT DISTINCT "	
	cQryCli += " Z01.Z01_CODIGO,Z01.Z01_CODCHT,Z01.Z01_LOJCHT,Z01.Z01_CODNAT,Z01.Z01_TES,Z01.Z01_EMAIL, " 
	cQryCli += " Z01.Z01_CGC,Z01.Z01_END, Z01.Z01_BAIRRO, Z01.Z01_CEP, Z01.Z01_CIDADE,Z01_UF, Z01_NOME, " 
	cQryCli += " Z01.Z01_INSCRI,Z01.Z01_DDD, Z01_TEL,Z01.R_E_C_N_O_ AS Z01REC "
	cQryCli += " FROM "  + RetSQLName("Z01") + " Z01 "
	cQryCli += " WHERE Z01_STATUS = '0' "
	cQryCli += " AND Z01.D_E_L_E_T_ = ' ' "
	cQryCli += " AND Z01.Z01_FILIAL= '"+xFilial("Z01")+"' "

	If Select(cAliasCli)
		(cAliasCli)->( DbCloseArea() )
	EndIf

	TCQuery cQryCli New Alias (cAliasCli)

	(cAliasCli)->( DbEval({||nQtdReg++} ) )	
	(cAliasCli)->( DbGoTop() )

	SA1->( DbSetOrder(3) )

	ProcRegua(nQtdReg)

	Begin Transaction

		While (cAliasCli)->( !Eof() )

			IncProc( (cAliasCli)->Z01_NOME ) 

			SA1->(DBSETORDER(3))

			If !SA1->( DbSeek( xFilial("SA1") + (cAliasCli)->Z01_CGC ) ) 

				lIncCli := .T.
				nOpc 	:= 3
				cCodCli := GetSX8Num("SA1", "A1_COD")

				Aadd( aDadosCli, { "A1_COD" 	, cCodCli						, Nil } )
				Aadd( aDadosCli, { "A1_LOJA" 	, "01"							, Nil } )
				Aadd( aDadosCli, { "A1_NOME" 	, (cAliasCli)->Z01_NOME			, Nil } )
				_Pessoa:= Iif( Len(AllTrim((cAliasCli)->Z01_CGC)) == 14,_Pessoa:="J",_Pessoa:="F")
				Aadd( aDadosCli, { "A1_PESSOA" 	, _Pessoa						, Nil } )
				Aadd( aDadosCli, { "A1_CEP"   	, (cAliasCli)->Z01_CEP			, Nil } )
				Aadd( aDadosCli, { "A1_END" 	, (cAliasCli)->Z01_END			, Nil } )
				Aadd( aDadosCli, { "A1_NREDUZ" 	, (cAliasCli)->Z01_NOME			, Nil } )
				Aadd( aDadosCli, { "A1_BAIRRO" 	, (cAliasCli)->Z01_BAIRRO		, Nil } )
				Aadd( aDadosCli, { "A1_TIPO" 	, "F"							, Nil } )
				Aadd( aDadosCli, { "A1_EST" 	, (cAliasCli)->Z01_UF			, Nil } )
				Aadd( aDadosCli, { "A1_COMPLEM" , " "							, Nil } )
				Aadd( aDadosCli, { "A1_MUN" 	, (cAliasCli)->Z01_CIDADE		, Nil } )			
				//			Aadd( aDadosCli, { "A1_INSCRM" 	, (cAliasCli)->Z01_INSCRM		, Nil } )
				Aadd( aDadosCli, { "A1_INSCR" 	, (cAliasCli)->Z01_INSCRI		, Nil } )
				Aadd( aDadosCli, { "A1_EMAIL" 	, (cAliasCli)->Z01_EMAIL		, Nil } )
				Aadd( aDadosCli, { "A1_NATUREZ"	, (cAliasCli)->Z01_CODNAT		, Nil } )
				Aadd( aDadosCli, { "A1_DDD"		, (cAliasCli)->Z01_DDD			, Nil } )			
				Aadd( aDadosCli, { "A1_TEL"		, (cAliasCli)->Z01_TEL			, Nil } )
				Aadd( aDadosCli, { "A1_CGC" 	, (cAliasCli)->Z01_CGC			, Nil } )
				Aadd( aDadosCli, { "A1_CGC" 	, (cAliasCli)->Z01_CGC			, Nil } )	
				Aadd( aDadosCli, { "A1_XIDCHT" 	, (cAliasCli)->Z01_CODCHT		, Nil } )	

			Else


				_cQuery := " SELECT * FROM "+RetSqlName('SA1')+" WHERE D_E_L_E_T_ = ' ' AND A1_XIDCHT = '"+(cAliasCli)->Z01_CODCHT+"' "
				_cQuery := ChangeQuery(_cQuery)

				If Select("QrySB1") > 0
					QrySB1->(dbCloseArea())
				EndIf

				DBUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"QrySB1",.F.,.T.)

				If QrySB1->(Eof()) 
				
					lIncCli := .T.
					nOpc 	:= 3
					cCodCli := GetSX8Num("SA1", "A1_COD")

					Aadd( aDadosCli, { "A1_COD" 	, cCodCli						, Nil } )
					Aadd( aDadosCli, { "A1_LOJA" 	, "01"							, Nil } )
					Aadd( aDadosCli, { "A1_NOME" 	, (cAliasCli)->Z01_NOME			, Nil } )
					_Pessoa:= Iif( Len(AllTrim((cAliasCli)->Z01_CGC)) == 14,_Pessoa:="J",_Pessoa:="F")
					Aadd( aDadosCli, { "A1_PESSOA" 	, _Pessoa						, Nil } )
					Aadd( aDadosCli, { "A1_CEP"   	, (cAliasCli)->Z01_CEP			, Nil } )
					Aadd( aDadosCli, { "A1_END" 	, (cAliasCli)->Z01_END			, Nil } )
					Aadd( aDadosCli, { "A1_NREDUZ" 	, (cAliasCli)->Z01_NOME			, Nil } )
					Aadd( aDadosCli, { "A1_BAIRRO" 	, (cAliasCli)->Z01_BAIRRO		, Nil } )
					Aadd( aDadosCli, { "A1_TIPO" 	, "F"							, Nil } )
					Aadd( aDadosCli, { "A1_EST" 	, (cAliasCli)->Z01_UF			, Nil } )
					Aadd( aDadosCli, { "A1_COMPLEM" , " "							, Nil } )
					Aadd( aDadosCli, { "A1_MUN" 	, (cAliasCli)->Z01_CIDADE		, Nil } )			
					//			Aadd( aDadosCli, { "A1_INSCRM" 	, (cAliasCli)->Z01_INSCRM		, Nil } )
					Aadd( aDadosCli, { "A1_INSCR" 	, (cAliasCli)->Z01_INSCRI		, Nil } )
					Aadd( aDadosCli, { "A1_EMAIL" 	, (cAliasCli)->Z01_EMAIL		, Nil } )
					Aadd( aDadosCli, { "A1_NATUREZ"	, (cAliasCli)->Z01_CODNAT		, Nil } )
					Aadd( aDadosCli, { "A1_DDD"		, (cAliasCli)->Z01_DDD			, Nil } )			
					Aadd( aDadosCli, { "A1_TEL"		, (cAliasCli)->Z01_TEL			, Nil } )
					Aadd( aDadosCli, { "A1_CGC" 	, (cAliasCli)->Z01_CGC			, Nil } )
					Aadd( aDadosCli, { "A1_CGC" 	, (cAliasCli)->Z01_CGC			, Nil } )	
					Aadd( aDadosCli, { "A1_XIDCHT" 	, (cAliasCli)->Z01_CODCHT		, Nil } )
					 
				ELSE 

					SA1->(DBSETORDER(1))
					IF SA1->(DBSEEK(XFILIAL("SA1")+QrySB1->A1_COD+QrySB1->A1_LOJA))
						// Caso o cliente já exista, apenas grava o código no registro
						Z01->( DbGoTo( (cAliasCli)->Z01REC ) )

						RecLock("Z01", .F.)
						Z01->Z01_STATUS := "0"
						Z01->Z01_CODERP := SA1->A1_COD
						Z01->Z01_LOJERP := SA1->A1_LOJA
						Z01->Z01_OBSERV := "Cliente já existente. Pendente apenas a criação do pedido"
						Z01->( MsUnlock() )
					ENDIF 
				ENDIF 
			EndIf

			If lAltCli .Or. lIncCli

				// --> Ordena array de acordo com dicionário SX3
				aDadosCli := FWVetByDic(aDadosCli, "SA1",.F.,)  

				lMsErroAuto := .F.			
				MSExecAuto({|x,y| MATA030(x,y)},aDadosCli,nOpc)

				If !lMsErroAuto

					ConfirmSX8()
					cMsgLog := "Cliente: " +(cAliasCli)->Z01_CODCHT +"|" +Alltrim((cAliasCli)->Z01_NOME) + Iif(nOpc == 3, " incluído", " alterado") + " com sucesso. Codigo ERP:"+cCodCli+"|01" 
					Aadd(aArqLog, {(cAliasCli)->Z01_CODIGO, cMsgLog} )

					// --> Atualiza o status para cliente atualizado
					Z01->( DbGoTo( (cAliasCli)->Z01REC ) )

					RecLock("Z01", .F.)
					Z01->Z01_STATUS := "1"
					Z01->Z01_CODERP := cCodCli
					Z01->Z01_LOJERP := "01"
					Z01->Z01_OBSERV := " "
					Z01->( MsUnlock() )
				Else
					RollBackSX8()
					cMsgLog := "Erro na " + Iif(nOpc == 3, "inclusão", "alteração") + " do cliente " + Alltrim((cAliasCli)->Z01_NOME) + "."
					cCodCHT := (cAliasCli)->Z01_CODIGO
					cArqLog := cCodCHT + "_" +"SA1_"+dtos(date()) + StrTran( time(),":","" ) + ".log"
					cErro   := MostraErro("\log_mov_fiscais\", cArqLog)
					cErro   := TrataErro(cErro) // --> Trata o erro para devolver para o client.
					cMsgLog += cErro
					Aadd(aArqLog, {(cAliasCli)->Z01_CODIGO, cMsgLog} ) 

					// --> Atualiza o status para cliente e grava motivo do erro.
					Z01->( DbGoTo( (cAliasCli)->Z01REC ) )

					RecLock("Z01", .F.)
					Z01->Z01_STATUS := "3"
					Z01->Z01_OBSERV := cMsgLog
					Z01->( MsUnlock() )				
				EndIf
			EndIf

			//--> Restaura as variáveis
			lAltCli   := .F.
			lIncCli   := .F.
			aDadosCli := {}
			cErro     := ""
			cMsgLog   := ""

			(cAliasCli)->( DbSkip() )

		EndDo	
	End Transaction    
	(cAliasCli)->(DbCloseArea())             
	RestArea(aArea)
Return

/*/{Protheus.doc} Cht001PV
Geração do Pedido de Venda
@author  Leandro Heilig
@since   04/08/2019
@version undefined
@type    function
/*/
Static Function Cht001PV

	Local aArea    := getArea()
	Local cQryPed 	:= ""
	Local cCliente	:= ""
	Local cLoja		:= ""
	Local cUM		:= ""
	Local cTES		:= ""
	Local cArmazem := ""
	Local cNumPed	:= ""  
	Local cCondPg	:= ""
	Local cAliasPed:= GetNextAlias()
	Local nQtdReg	:= 0
	Local aCabPed  := {}
	Local aItemPed := {} // --> Sempre será um único item!!!
	// Local dBkpdBase := dDataBase
	Local cErro    := ""
	Local cArqLog  := ""
	Local cCodCHT  := ""
	Local aItensPed:= {}
	Local aRecZ01	:= {}
	Local nValTotal:= 0
	Local nItem		:= 0
	Local cItem		:=''
	Local lErro		:= .F.
	Local cOper		:= ''
	Local nL

	Private lMsErroAuto	:= .F.

	For nL:=1 To 2

		cQryPed := " SELECT Z01.Z01_CGC,Z01.Z01_CODERP, Z01.Z01_LOJERP, Z01.Z01_CODNAT,Z01.Z01_CODCHT,Z01.Z01_NOME, Z01.R_E_C_N_O_ Z01REC, "	
		cQryPed += " Z01.Z01_CODPRO, Z01.Z01_VLRUNI, Z01.Z01_VLRTOT, Z01.Z01_QUANT,Z01.Z01_TES,Z01.Z01_CODPAG, Z01.Z01_CODIGO,Z01.Z01_DTVENC, "
		cQryPed += " Z01.Z01_CIRCNR,Z01.Z01_VELOCI,Z01.Z01_TPNOTA, Z01_MEDIDO "
		cQryPed += " FROM "+RetSQLName("Z01")+" Z01 "
		cQryPed += " WHERE Z01.D_E_L_E_T_<>'*' "
		If nL == 1
			cQryPed += " AND Z01.Z01_TPNOTA ='D'"
		Else
			cQryPed += " AND Z01.Z01_TPNOTA ='T'"
		Endif
		cQryPed += " AND Z01.Z01_STATUS= '0' OR Z01.Z01_STATUS= '1'"
		cQryPed += " AND Z01.Z01_CODPV= ' ' "
		cQryPed += " AND Z01.Z01_FILIAL='"+xFilial("Z01")+"' "
		cQryPed += " ORDER BY Z01.Z01_CODCHT"
		If Select(cAliasPed) > 0
			(cAliasPed)->( DbCloseArea() )
		EndIf

		TCQuery cQryPed New Alias (cAliasPed)	
		(cAliasPed)->( DbEval({||nQtdReg++} ) )	
		(cAliasPed)->( DbGoTop() )

		ProcRegua(nQtdReg)

		Begin Transaction

			If mv_par03 == 2
				While (cAliasPed)->( !Eof() )

					IncProc("Gerando pedido de venda referente ao cliente " + AllTrim((cAliasPed)->Z01_CODCHT) + "|"+AllTrim((cAliasPed)->Z01_NOME)) 

					SA1->( DbSetOrder(1) )
					SB1->( DbSetOrder(1) )

					_TpNota := (cAliasPed)->Z01_TPNOTA

					If SA1->( DbSeek( xFilial("SA1") + AllTrim((cAliasPed)->Z01_CODERP)+AllTrim((cAliasPed)->Z01_LOJERP) ) )
						cCliente := SA1->A1_COD
						cLoja 	:= SA1->A1_LOJA 
						cCondPg  := (cAliasPed)->Z01_CODPAG

						cNumPed := GetSX8Num("SC5", "C5_NUM") 

						// --> Monta o cabeçalho
						Aadd( aCabPed, { "C5_FILIAL"	, xFilial("SC5") 			 , Nil } )
						Aadd( aCabPed, { "C5_NUM"		, cNumPed 					 , Nil } )
						Aadd( aCabPed, { "C5_TIPO"		, "N"					    	 , Nil } )
						Aadd( aCabPed, { "C5_CLIENTE"	, cCliente				    , Nil } )
						Aadd( aCabPed, { "C5_LOJA"		, cLoja					    , Nil } )
						Aadd( aCabPed, { "C5_CONDPAG"	, cCondPg				    , Nil } )
						Aadd( aCabPed, { "C5_PARC1"	, (cAliasPed)->Z01_VLRTOT   		, Nil } )
						Aadd( aCabPed, { "C5_DATA1"	, StoD((cAliasPed)->Z01_DTVENC)	, Nil } )
						Aadd( aCabPed, { "C5_NATUREZ"	, (cAliasPed)->Z01_CODNAT   		, Nil } )	
						Aadd( aCabPed, { "C5_XMEDIDO"	, (cAliasPed)->Z01_MEDIDO   		, Nil } )								

						If SB1->( DbSeek( xFilial("SB1") + (cAliasPed)->Z01_CODPRO ) )

							cUM       := SB1->B1_UM
							cTES      := (cAliasPed)->Z01_TES
							cArmazem  := SB1->B1_LOCPAD
							If (cAliasPed)->Z01_TPNOTA == 'D'
								cOper := '10'	// 10-TELECOM NOTA DEBITO                               
							Else
								cOper		 := If((cAliasPed)->Z01_MEDIDO == '1','09','08')	// 08-Não Medido / 09-Medido
							EndIf

							// --> Monta o item.
							// --> Sempre será um único item!!!
							Aadd(aItemPed,{} ) 
							//Aadd(aItemPed[Len(aItemPed)], { "C6_ITEM"		, "01", Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_PRODUTO"	, (cAliasPed)->Z01_CODPRO	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_UM"		, cUM					 			, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_TES"		, cTES					 		, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_QTDVEN"	, (cAliasPed)->Z01_QUANT	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_PRCVEN"	, (cAliasPed)->Z01_VLRUNI	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_TOTAL"	, (cAliasPed)->Z01_VLRTOT	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_QTDLIB"	, (cAliasPed)->Z01_QUANT	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_LOCAL"	, cArmazem						, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_P_DESI"	, (cAliasPed)->Z01_CIRCNR	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_P_CAP"	, (cAliasPed)->Z01_VELOCI	, Nil } )
							Aadd(aItemPed[Len(aItemPed)], { "C6_OPER"		, cOper							, Nil } )

							lMsErroAuto := .F.				
							MsExecAuto({|x,y,z| MATA410(x,y,z)},aCabPed,aItemPed,3)

							If !lMsErroAuto		

								ConfirmSX8()

								cMsgLog := "Pedido de venda  " + AllTrim(SC5->C5_NUM) + " gerado com sucesso." 

								Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )									

								cNotaFeita := Cht001NFe( SC5->C5_NUM, _TpNota )

								Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
								RecLock("Z01", .F.)
								Z01->Z01_CODPV  := SC5->C5_NUM
								Z01->Z01_STATUS := "2"
								Z01->Z01_OBSERV := " "
								Z01->( MsUnlock() )

								If cNotaFeita != ""
									cMsgLog := "Documento de Saida  " + cNotaFeita + " gerado com sucesso." 
									Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )	
								EndIf		

							Else

								RollBackSX8() 

								cMsgLog := "Erro na geração do Pedido de vendas. "
								cCodCHT := (cAliasPed)->Z01_CODIGO

								cArqLog := AllTrim(cCodCHT)+ "_" +"SC5_"+dtos(date()) + StrTran( time(),":","" ) + ".log"
								cErro   := MostraErro("\log_mov_fiscais\", cArqLog)
								cErro   := TrataErro(cErro) // --> Trata o erro para devolver para o client.
								cMsgLog += cErro

								// Marca o registro como pendente de Erro
								Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
								RecLock("Z01", .F.)
								Z01->Z01_STATUS := "3"
								Z01->Z01_OBSERV := cMsgLog
								Z01->( MsUnlock() )

								// Gera log

								Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )
							EndIf				
						Else
							cMsgLog := " Produto " + (cAliasPed)->Z01_CODPRO + " não encontrado. "  
							Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )

							Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
							RecLock("Z01", .F.)
							Z01->Z01_STATUS := "3"
							Z01->Z01_OBSERV := cMsgLog
							Z01->( MsUnlock() )

						EndIf
					Else

						cMsgLog := " Cliente " + (cAliasPed)->Z01_CGC + " não encontrado. "  
						Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )

						Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
						RecLock("Z01", .F.)
						Z01->Z01_STATUS := "3"
						Z01->Z01_OBSERV := cMsgLog
						Z01->( MsUnlock() )

					EndIf		

					// ---> Restaura as variáveis 
					aCabPed  := {}
					aItemPed := {}
					cCliente := ""
					cLoja	 := ""
					cUM  	 := ""
					cTES 	 := ""

					(cAliasPed)->( DbSkip() )

				EndDo

			Else

				cCodAnt := " "

				While (cAliasPed)->( !Eof() )

					IncProc("Gerando pedido de venda referente ao cliente " + AllTrim((cAliasPed)->Z01_CODCHT) + "|"+AllTrim((cAliasPed)->Z01_NOME)) 
					SA1->( DbSetOrder(1) )
					SB1->( DbSetOrder(1) )

					_TpNota := (cAliasPed)->Z01_TPNOTA

					If SA1->( DbSeek( xFilial("SA1") + AllTrim((cAliasPed)->Z01_CODERP)+AllTrim((cAliasPed)->Z01_LOJERP) ) )
						cCliente := SA1->A1_COD
						cLoja 	 := SA1->A1_LOJA 
						cCondPg  := (cAliasPed)->Z01_CODPAG

						cNumPed := GetSX8Num("SC5", "C5_NUM") 

						// --> Monta o cabeçalho
						Aadd( aCabPed, { "C5_FILIAL"	, xFilial("SC5") 			, Nil } )
						Aadd( aCabPed, { "C5_NUM"		, cNumPed 					, Nil } )
						Aadd( aCabPed, { "C5_TIPO"		, "N"					    	, Nil } )
						Aadd( aCabPed, { "C5_CLIENTE"	, cCliente				    , Nil } )
						Aadd( aCabPed, { "C5_LOJA"		, cLoja					    , Nil } )
						Aadd( aCabPed, { "C5_CONDPAG"	, cCondPg				    , Nil } )
						Aadd( aCabPed, { "C5_DATA1"	, StoD((cAliasPed)->Z01_DTVENC)   , Nil } )	
						Aadd( aCabPed, { "C5_NATUREZ"	, (cAliasPed)->Z01_CODNAT   , Nil } )	
						Aadd( aCabPed, { "C5_XMEDIDO"	, (cAliasPed)->Z01_MEDIDO   , Nil } )	


						While AllTrim((cAliasPed)->Z01_CODERP) == cCodAnt .And. (cAliasPed)->( !Eof() ) .Or. cCodAnt == " " .And. (cAliasPed)->( !Eof() )

							lErro := .F.
							cCodAnt := (cAliasPed)->Z01_CODERP

							If SB1->( DbSeek( xFilial("SB1") + (cAliasPed)->Z01_CODPRO ) )

								cUM     := SB1->B1_UM
								cTES    := (cAliasPed)->Z01_TES
								cArmazem:= SB1->B1_LOCPAD
								nItem	  := nItem +1
								cItem	  := fSomaUm(nItem, 2)
								cOper	  := If((cAliasPed)->Z01_MEDIDO == '1','09','08')	// 08-Não Medido / 09-Medido

								// --> Monta o item.
								// --> Sempre será um único item!!!
								aItemPed := {}
								//Aadd(aItemPed,{} ) 
								Aadd(aItemPed, { "C6_ITEM"		, cItem, Nil } ) //
								Aadd(aItemPed, { "C6_PRODUTO"	, (cAliasPed)->Z01_CODPRO	, Nil } )
								Aadd(aItemPed, { "C6_UM"		, cUM					 			, Nil } )
								Aadd(aItemPed, { "C6_TES"		, cTES					 		, Nil } )
								Aadd(aItemPed, { "C6_QTDVEN"	, (cAliasPed)->Z01_QUANT	, Nil } )
								Aadd(aItemPed, { "C6_PRCVEN"	, (cAliasPed)->Z01_VLRUNI	, Nil } )
								Aadd(aItemPed, { "C6_TOTAL"	, (cAliasPed)->Z01_VLRTOT	, Nil } )
								Aadd(aItemPed, { "C6_QTDLIB"	, (cAliasPed)->Z01_QUANT	, Nil } )
								Aadd(aItemPed, { "C6_LOCAL"	, cArmazem						, Nil } )
								Aadd(aItemPed, { "C6_P_DESI"	, (cAliasPed)->Z01_CIRCNR	, Nil } )
								Aadd(aItemPed, { "C6_P_CAP"	, (cAliasPed)->Z01_VELOCI	, Nil } )
								Aadd(aItemPed, { "C6_OPER"		, cOper							, Nil } )

								Aadd(aItensPed, aItemPed)

								aAdd(aRecZ01, (cAliasPed)->Z01REC )

								nValTotal += (cAliasPed)->Z01_VLRTOT

							Else
								cMsgLog := " Produto " + (cAliasPed)->Z01_CODPRO + " não encontrado. "  
								Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )

								Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
								RecLock("Z01", .F.)
								Z01->Z01_STATUS := "3"
								Z01->Z01_OBSERV := cMsgLog
								Z01->( MsUnlock() )
								lErro := .T.
								(cAliasPed)->( DbSkip() )
								LOOP

							EndIf

							(cAliasPed)->( DbSkip() )

						EndDo

						Aadd( aCabPed, { "C5_PARC1"	    , nValTotal   , Nil } )

						If !lErro 

							lMsErroAuto := .F.				
							MsExecAuto({|x,y,z| MATA410(x,y,z)},aCabPed,aItensPed,3)

							If !lMsErroAuto

								cNotaFeita := Cht001NFe( SC5->C5_NUM, _TpNota )

								If cNotaFeita != ""
									cMsgLog := "Documento de Saida  " + cNotaFeita + " gerado com sucesso." 
									Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )	
								Endif

								For nX :=1 To Len(aRecZ01)
									Z01->( DbGoTo( aRecZ01[nX] ) )
									RecLock("Z01", .F.)
									Z01->Z01_CODPV  := SC5->C5_NUM
									If cNotaFeita != ""
										Z01->Z01_STATUS := "4"
									Else
										Z01->Z01_STATUS := "2"
									EndIf
									Z01->Z01_OBSERV := " "
									Z01->( MsUnlock() )
								Next
								aRecZ01 := nil
								aRecZ01 := {}
								ConfirmSX8()				

							Else
								cMsgLog := "Erro na geração do Pedido de vendas. "
								cCodCHT := (cAliasPed)->Z01_CODIGO
								cArqLog := AllTrim(cCodCHT)+ "_" +"SC5_"+dtos(date()) + StrTran( time(),":","" ) + ".log"
								cErro   := MostraErro("\log_mov_fiscais\", cArqLog)
								cErro   := TrataErro(cErro) // --> Trata o erro para devolver para o client.
								cMsgLog += cErro

								// Marca o registro como pendente de Erro
								For nX :=1 To Len(aRecZ01)
									Z01->( DbGoTo( aRecZ01[nX] ) )
									RecLock("Z01", .F.)
									Z01->Z01_STATUS := "3"
									Z01->Z01_OBSERV := cMsgLog
									Z01->( MsUnlock() )
								Next
								//Gera log
								Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )
								RollBackSX8() 
							EndIf
						Endif
					Else
						cMsgLog := " Cliente " + (cAliasPed)->Z01_CGC + " não encontrado. "  
						Aadd(aArqLog, {(cAliasPed)->Z01_CODIGO, cMsgLog} )

						Z01->( DbGoTo( (cAliasPed)->Z01REC ) )
						RecLock("Z01", .F.)
						Z01->Z01_STATUS := "3"
						Z01->Z01_OBSERV := cMsgLog
						Z01->( MsUnlock() )

					EndIf		
					// ---> Restaura as variáveis 
					aCabPed  := {}
					aItemPed := {}
					aItensPed:= {}
					cCliente := ""
					cLoja	 := ""
					cUM  	 := ""
					cTES 	 := ""
					cCodAnt  := " "
					nValTotal:= 0
					nItem 	 := 0
					aRecZ01	 := Nil
					aRecZ01  := {}			

					//(cAliasPed)->( DbSkip() )

				EndDo

			EndIf
		End Transaction
	Next	
	DbCloseArea("SA1")
	DbCloseArea("SB1")
	RestArea(aArea)

Return

/* /{Protheus.doc} TrataErro
Trata o erro para devolver no log
@author Leandro Heilig
@since  05/08/2019
@type   Static function
/*/
Static Function TrataErro(cErroAuto)
	local nLines	:= MLCount(cErroAuto)
	local cNewErro	:= ""
	local nErr		:= 0
	for nErr := 1 to nLines step 1
		cNewErro += alltrim( MemoLine( cErroAuto, , nErr ) ) + " - "
	next nErr
Return(cNewErro)


/*/{Protheus.doc} ShowLOG
Apresentação do log de processamento
@author  Leandro Heilig 
@since   04/08/2019
@version undefined
@type    function
/*/
Static Function ShowLOG()

	Local aSize	  := MsAdvSize(.T.)                                                    
	Local aButEnc := {}

	FWAlertInfo("Processamento finalizado !!!", "Upload Faturamento")

	If Len(aArqLog) > 0                 	

		Aadd(aButEnc, {"CARGA", {|| GeraLog() }, "Impr. Log" })

		ASort(aArqLog,,,{ | x,y | x[1] < y[1] } )		
		DEFINE MSDIALOG oDialog FROM aSize[7],0 TO aSize[6],aSize[5] TITLE OemToAnsi("Conferência de Processamento") OF oMainWnd PIXEL			
		DEFINE FWBROWSE oTela DATA ARRAY ARRAY aArqLog NO SEEK NO CONFIG NO REPORT Of oDialog

		ADD COLUMN oColumn DATA { || aArqLog[oTela:At(),1] } Title "Cod.Importacao"  PICTURE "@!" SIZE 10 Of oTela	
		ADD COLUMN oColumn DATA { || aArqLog[oTela:At(),2] } Title "Mensagem" PICTURE "@!" SIZE 40 Of oTela

		ACTIVATE FWBrowse oTela			
		ACTIVATE MSDIALOG oDialog ON INIT EnchoiceBar(oDialog, {||oDialog:End()}, {||oDialog:End()},,aButEnc) CENTERED	
	EndIf
Return

/*/{Protheus.doc} GeraLog
Função para impressão do log em TReport
@author  Leandro Heilig
@since   04/08/2019
@version undefined
@type    function
/*/
Static Function GeraLog()
	//--> Impressão do log de conferência
	U_CHTR001(aArqLog)
Return

/*/{Protheus.doc} AjustaX1
Ajusta o grupo de perguntas do SX1
@author  Leandro Heilig
@since   04/08/2019
@version undefined
@type    function
/*/
Static Function AjustaX1()

	Local aArea := GetArea()
	Local aPerg := {}
	Local i		:= 0

	Aadd(aPerg, {cPerg, "01", "Tipo Processamento: ", "MV_CHA" , 	"N", 01	, 2 , "C"	, "MV_PAR01", ""	,"Importação","Processamento" ,"Importação e Processamento",""})
	Aadd(aPerg, {cPerg, "02", "Local do Arquivo:   ", "MV_CHB" , 	"C", 99 , 2 , "G"	, "MV_PAR02", "DIR"	,""			 ,"" 	    	  ,"",""})
	Aadd(aPerg, {cPerg, "03", "Aglutina Pedidos ? " , "MV_CHC" , 	"N", 01	, 2 , "C"	, "MV_PAR03", ""	,"Sim" 		 ,"Não"			  ,"",""})

	DbSelectArea("SX1")
	DbSetOrder(1)

	For i := 1 To Len(aPerg)
		If  !SX1->( DbSeek( aPerg[i,1] + aPerg[i,2]) )
			RecLock("SX1",.T.)
		Else
			RecLock("SX1",.F.)
		EndIf

		Replace X1_GRUPO   With aPerg[i,01]
		Replace X1_ORDEM   With aPerg[i,02]
		Replace X1_PERGUNT With aPerg[i,03]
		Replace X1_VARIAVL With aPerg[i,04]
		Replace X1_TIPO	   With aPerg[i,05]
		Replace X1_TAMANHO With aPerg[i,06]
		Replace X1_PRESEL  With aPerg[i,07]
		Replace X1_GSC	   With aPerg[i,08]
		Replace X1_VAR01   With aPerg[i,09]
		Replace X1_F3	   With aPerg[i,10]
		Replace X1_DEF01   With aPerg[i,11]
		Replace X1_DEF02   With aPerg[i,12]
		Replace X1_DEF03   With aPerg[i,13]
		Replace X1_DEF04   With aPerg[i,14]

		SX1->( MsUnlock() )

	Next i

	RestArea(aArea)
Return

/*/{Protheus.doc} Cht001NFe
Geração das notas fiscais de saída
@author  Leandro Heilig
@since   07/08/2019
@version undefined
@type function
/*/

Static Function Cht001NFe(_cPedido, _cSerie)

	Local aPvlNfs   := {}
	Local nItemNf   := 0
	Local aPvAux	:= {} 
	Local xSerie	:= SuperGetMv("ES_SERCHT" ,.F.,"2")
	Local aSerie    := StrTokArr( xSerie , ";" )
	Local cSerie	:= ""
	Local lCont		:= .F.
	Local aBloqueio	:= {}
	Local aNotas	:= {}
	Local aZ01REC	:= {}
	Local aPvVal	:= {}
	Local cNotaFeita:= ""

	cSerie := SubStr( aSerie[ AScan( aSerie , _cSerie + "=" ) ], 3 ) 

	Ma410LbNfs(2,@aPvlNfs,@aBloqueio)

	Ma410LbNfs(1,@aPvlNfs,@aBloqueio)

	If !Empty(aPvlNfs)
		nItemNf  := a460NumIt(cSerie)
		aadd(aNotas,{})
		// Efetua as quebras de acordo com o numero de itens
		For nX := 1 To Len(aPvlNfs)
			If Len(aNotas[Len(aNotas)])>=nItemNf
				aadd(aNotas,{})
			EndIf
			//Removo do meu arrey todos os pedidos de venda que não foram adicionados pela rotina de importação e que nao sao do tipo 1 ou 2 conforme query e for principal
			//If aScan( aPvVal, aPvlNfs[nX][1] ) != 0
			aadd(aNotas[Len(aNotas)],aClone(aPvlNfs[nX]))
			//	aDel(aZ01RED, aScan(aZ01RED, {|x| AllTrim(x[2])==aNotas[nX]}) )
			//EndIf
		Next nX
		// Gera as notas de acordo com a quebra
		For nX := 1 To Len(aNotas)
			cNotaFeita:= MaPvlNfs( aNotas[nX],cSerie , .F., .F., .F., .F., .F., 0, 0, .F., .F.)
		Next nX
	Endif
Return cNotaFeita


//---------------------------------------------------
// fSomaUm
//---------------------------------------------------
Static Function fSomaUm(nValor, nQtdPos)

	Local aArea  := GetArea()
	Local cValor := StrTran(Space(nQtdPos), ' ', '0')
	Local nAtual := 0

	//Percorrendo o valor
	For nAtual := 1 To nValor
		cValor := Soma1(cValor)
	Next

	RestArea(aArea)

Return cValor
