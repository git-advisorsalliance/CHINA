#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} M460FIM
P.E. chamado apos a Gravacao da NF de Saida. Fora da transação.
@type Function
@author Marcos Cavalaro
@since 06/01/2022
@version 1.0
@history 06/01/2022, Marcos, Incluido opção de Gravação de Chave Nfe.
/*/

USER FUNCTION M460FIM()

Local aArea	:= GetArea()
// Local ExpA1 := {}
// Local ExpN2 := 3
Local _cFilial	:= SF2->F2_FILIAL
Local _cNumDoc := SF2->F2_DOC
Local _cSerie  := SF2->F2_SERIE
Local _cCli		:= SF2->F2_CLIENTE
Local _cLoja	:= SF2->F2_LOJA
Local _cTes		:= ALLTRIM(SuperGetMv("ES_TESCOM",.F.,"'501','507','508'"))
Local cAliasSD2 := GetNextAlias()
Local cQuery	:= ""
Local cMedido  := ""

Local aAreaSF3:= SF3->(GetArea())
Local aAreaSFT:= SFT->(GetArea())
Local aAreaSC5:= SC5->(GetArea())

PRIVATE lMsErroAuto := .F.

	cQuery	:= " SELECT R_E_C_N_O_ AS REGISTRO FROM " + RetSqlName("SD2") + " WHERE D2_SERIE = '"+ _cSerie +"' AND D2_DOC = '"+ _cNumDoc +"' AND D2_FILIAL = '"+ _cFilial +"' AND "
	cQuery	+= " D2_CLIENTE = '" + _cCli + "' AND D2_LOJA = '" + _cLoja + "' AND D2_TES IN("+ _cTes +") AND D_E_L_E_T_ = '' ORDER BY D2_ITEM "

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasSD2,.F.,.T.)

	DbSelectArea("SD2")
	SD2->(DbSetOrder(3))
	SD2->(DbGoTop())

	Do While (cAliasSD2)->(!eof())

		SD2->(DbGoTo((cAliasSD2)->REGISTRO))

		DbSelectArea("SFX")
		SFX->(DbSetOrder(1))
		SFX->(DbGoTop())

		IF(!SFX->(DbSeek(SD2->D2_FILIAL+'S'+SD2->D2_SERIE+SD2->D2_DOC+SD2->D2_CLIENTE+SD2->D2_LOJA+SD2->D2_ITEM+SD2->D2_COD)))

			Reclock("SFX",.T.)
				SFX->FX_FILIAL 	:= SD2->D2_FILIAL
				SFX->FX_TIPOMOV	:= 'S'
				SFX->FX_DOC			:= SD2->D2_DOC
				SFX->FX_SERIE		:= SD2->D2_SERIE
				SFX->FX_ESPECIE	:= SF2->F2_ESPECIE
				SFX->FX_CLIFOR		:= SD2->D2_CLIENTE
				SFX->FX_LOJA		:= SD2->D2_LOJA
				SFX->FX_ITEM		:= SD2->D2_ITEM
				SFX->FX_COD			:= SD2->D2_COD
				SFX->FX_TPCLASS	:= '3'
				SFX->FX_CLASCON	:= '10'
				SFX->FX_GRPCLAS   := '10'
				SFX->FX_CLASSIF	:= '04'
				SFX->FX_TIPOREC	:= '0'
				SFX->FX_RECEP		:= SD2->D2_CLIENTE
				SFX->FX_LOJAREC	:= SD2->D2_LOJA
				SFX->FX_TIPSERV	:= '3'
				SFX->FX_TPASSIN	:= '99'
				SFX->FX_PERFIS    := SUBSTR(DTOS(SF2->F2_EMISSAO),5,2)+SUBSTR(DTOS(SF2->F2_EMISSAO),1,4)
				SFX->FX_DTINI     := FirstDate(SF2->F2_EMISSAO)
				SFX->FX_DTFIM     := LastDate(SF2->F2_EMISSAO)
				SFX->FX_DINCONT   := FirstDate(SF2->F2_EMISSAO)
				SFX->FX_DFICONT   := LastDate(SF2->F2_EMISSAO)
				SFX->FX_ESTCONT   := SD2->D2_CLIENTE+SD2->D2_LOJA
				SFX->FX_TERMINA   := SD2->D2_CLIENTE+SD2->D2_LOJA
				SFX->FX_AREATER   := '35'
				SFX->FX_NUMCONT   := SD2->D2_CLIENTE+SD2->D2_LOJA
				// Reforma tribuaria exigiu novos campos
				cMedido := Posicione("SC5", 1, xFilial("SC5") + SD2->D2_PEDIDO, "C5_XMEDIDO")
				If cMedido == '1'
					SFX->FX_CCLAS62   := '0300201'
				ElseIf cMedido == '2'
					SFX->FX_CCLAS62   := '0400201'
				EndIf
				SFX->FX_FINNFC    := '0'
				SFX->FX_INDPAG   := "1"
			SFX->(MsUnlock())

		ENDIF

		(cAliasSD2)->(DbSkip())

	EndDo

	(cAliasSD2)->(dbCloseArea())



// Grava a Chave da NF digitada no SC5
/*
If SC5->(FieldPos("C5_XCHVNFE")) > 0

	RecLock("SF2",.F.)
	 SF2->F2_CHVNFE:=SC5->C5_XCHVNFE
	MsUnlock()

	SF3->(dbSetOrder(4))
	SF3->(dbSeek(xFilial("SF3")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_DOC+SF2->F2_SERIE))

	RecLock("SF3",.F.)
	 SF3->F3_CHVNFE:=SC5->C5_XCHVNFE
	MsUnlock()

	SFT->(dbSetOrder(1))
	SFT->(dbSeek(xFilial("SFT")+"S"+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA))

	While !SFT->(EOF()).AND. SFT->(FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA) == SF2->(F2_FILIAL+"S"+F2_SERIE+F2_DOC+F2_CLIENTE+F2_LOJA)

		RecLock("SFT",.F.)
		 SFT->FT_CHVNFE:=SC5->C5_XCHVNFE
		MsUnlock()

		SFT->(dbSkip())

	EndDo

Endif
*/

SC5->(RestArea(aAreaSC5))
SF3->(RestArea(aAreaSF3))
SFT->(RestArea(aAreaSFT))

RestArea(aArea)

Return
