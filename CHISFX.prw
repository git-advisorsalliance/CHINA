#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} CHISFX
Corrige Tabela SFX com informações de faturamento.
@type Function
@author Marcos Cavalaro
@since 19/03/2024
@version 1.0
@history 19/03/2024, Marcos Cavalaro, Desenvolvimento da Rotina Inicial.
/*/
USER FUNCTION CHISFX()

	Local aArea	:= GetArea()
	// Local _cFilial	:= SF2->F2_FILIAL
	// Local _cNumDoc := SF2->F2_DOC
	// Local _cSerie  := SF2->F2_SERIE
	// Local _cCli	:= SF2->F2_CLIENTE
	// Local _cLoja	:= SF2->F2_LOJA
	Local _cTes	:= ALLTRIM(SuperGetMv("ES_TESCOM",.F.,"'501','507','508'"))
	Local _cEspecie:= ''
	Local cAliasSD2:= GetNextAlias()
	Local cPerg	:= "CHISFX"
	Local cQuery	:= ""

	AjustaSX1(cPerg)
	Pergunte(cPerg,.T.)

	cQuery := "SELECT D2_FILIAL , D2_DOC , D2_SERIE , D2_CLIENTE , D2_LOJA , D2_ITEM , D2_COD FROM " + RetSqlName("SD2") + " WHERE "
	cQuery += "D2_DOC BETWEEN '"+ MV_PAR01 +"' AND '" + MV_PAR02 + "' AND "
	cQuery += "D2_SERIE BETWEEN '"+ MV_PAR03 +"' AND '" + MV_PAR04 + "' AND "
	cQuery += "D2_CLIENTE BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' AND "
	cQuery += "D2_EMISSAO BETWEEN '" + DTOS(MV_PAR09) + "' AND '" + DTOS(MV_PAR10) + "' AND "
	cQuery += "D2_LOJA BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' AND D2_TES IN("+ _cTes +") AND D_E_L_E_T_ = '' ORDER BY D2_DOC , D2_ITEM "

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasSD2,.F.,.T.)

	Do While (cAliasSD2)->(!eof())

		DbSelectArea("SF2")
		SF2->(DbSetOrder(1))
		SF2->(DbGoTop())

		IF(!SF2->(DbSeek((cAliasSD2)->D2_FILIAL+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA)))
			cEspecie	:= 'NTST'
		ELSE
			cEspecie	:= SF2->F2_ESPECIE
		ENDIF

		DbSelectArea("SFX")
		SFX->(DbSetOrder(1))
		SFX->(DbGoTop())

		IF(!SFX->(DbSeek((cAliasSD2)->D2_FILIAL+'S'+(cAliasSD2)->D2_SERIE+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA+(cAliasSD2)->D2_ITEM+(cAliasSD2)->D2_COD)))

			Reclock("SFX",.T.)
			SFX->FX_FILIAL 	:= (cAliasSD2)->D2_FILIAL
			SFX->FX_TIPOMOV	:= 'S'
			SFX->FX_DOC			:= (cAliasSD2)->D2_DOC
			SFX->FX_SERIE		:= (cAliasSD2)->D2_SERIE
			SFX->FX_ESPECIE	:= cEspecie
			SFX->FX_CLIFOR		:= (cAliasSD2)->D2_CLIENTE
			SFX->FX_LOJA		:= (cAliasSD2)->D2_LOJA
			SFX->FX_ITEM		:= (cAliasSD2)->D2_ITEM
			SFX->FX_COD			:= (cAliasSD2)->D2_COD
			SFX->FX_CLASCON	:= '10'
			SFX->FX_GRPCLAS   := '10'
			SFX->FX_CLASSIF	:= '04'
			SFX->FX_TIPOREC	:= '0'
			SFX->FX_RECEP		:= (cAliasSD2)->D2_CLIENTE
			SFX->FX_LOJAREC	:= (cAliasSD2)->D2_LOJA
			SFX->FX_TIPSERV	:= '3'
			SFX->FX_TPASSIN	:= '1'
			SFX->FX_PERFIS    := SUBSTR(DTOS(SF2->F2_EMISSAO),5,2)+SUBSTR(DTOS(SF2->F2_EMISSAO),1,4)
			MsUnlock()

		ENDIF

		(cAliasSD2)->(DbSkip())

	EndDo

	RestArea(aArea)

Return


Static Function AjustaSX1(cPerg) // função para validar o arquivo de perguntas

	Local aHelp 	:= {}
	Local nTamDoc	:= TamSX3("D2_DOC")[1]
	Local nTamSer	:= TamSX3("D2_SERIE")[1]
	Local nTamCli	:= TamSX3("D2_CLIENTE")[1]
	Local nTamLoj	:= TamSX3("D2_LOJA")[1]

	aHelp := {'Informe o Doc Inicial'}
	xPutSx1( cPerg,"01","Doc de:","","",;
		"mv_ch1","C",nTamDoc,0,1,"G","","","","","mv_par01", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe a Doc Final'}
	xPutSx1( cPerg,"02","Doc ate:","","",;
		"mv_ch2","C",nTamDoc,0,1,"G","","","","","mv_par02", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe o Serie Inicial'}
	xPutSx1( cPerg,"03","Serie de:","","",;
		"mv_ch3","C",nTamSer,0,1,"G","","","","","mv_par03", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe o Serie Final'}
	xPutSx1( cPerg,"04","Serie Ate:","","",;
		"mv_ch4","C",nTamSer,0,1,"G","","","","","mv_par04", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe o Cliente Incial'}
	xPutSx1( cPerg,"05","Cliente De:","","",;
		"mv_ch5","C",nTamCli,0,1,"G","","SA1","","","mv_par05", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe o Cliente Final'}
	xPutSx1( cPerg,"06","Cliente Ate:","","",;
		"mv_ch6","C",nTamCli,0,1,"G","","SA1","","","mv_par06", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe a Loja Inicial'}
	xPutSx1( cPerg,"07","Loja De:","","",;
		"mv_ch7","C",nTamLoj,0,1,"G","","","","","mv_par07", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe a Loja Final'}
	xPutSx1( cPerg,"08","Loja Ate:","","",;
		"mv_ch8","C",nTamLoj,0,1,"G","","","","","mv_par08", '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

	aHelp := {'Informe data inicial de Emissão'}
	xPutSx1(cPerg, '09', 'Emissão De?' , '', '', 'MV_CH9', 'D', 8, 0, 0,;
		'G', '', '', '', '', 'MV_PAR09', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp,{}, {})

	aHelp := {'Informe a data final de Emissão'}
	xPutSx1(cPerg, '10', 'Emissão Até?' , '', '', 'MV_CHA', 'D', 8, 0, 0,;
		'G', '(MV_PAR10>=MV_PAR09) ', '', '', '', 'MV_PAR10', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', aHelp, {}, {})

Return


Static Function xPutSx1(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,; // função utilizada para substituir a PUTSX1
                         cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,;
                              cF3, cGrpSxg,cPyme,;
                              cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,;
                              cDef02,cDefSpa2,cDefEng2,;
                              cDef03,cDefSpa3,cDefEng3,;
                              cDef04,cDefSpa4,cDefEng4,;
                              cDef05,cDefSpa5,cDefEng5,;
                              aHelpPor,aHelpEng,aHelpSpa,cHelp)

	LOCAL aArea := GetArea()
	Local cKey
	Local lPort := .f.
	Local lSpa := .f.
	Local lIngl := .f.

	cKey := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "."

	cPyme   := Iif( cPyme     == Nil, " ", cPyme    )
	cF3     := Iif( cF3       == NIl, " ", cF3      )
	cGrpSxg := Iif( cGrpSxg   == Nil, " ", cGrpSxg  )
	cCnt01  := Iif( cCnt01    == Nil, "" , cCnt01   )
	cHelp   := Iif( cHelp     == Nil, "" , cHelp    )

	dbSelectArea( "SX1" )
	dbSetOrder( 1 )

     // Ajusta o tamanho do grupo. Ajuste emergencial para validação dos fontes.
     // RFC - 15/03/2007
	cGrupo := PadR( cGrupo , Len( SX1->X1_GRUPO ) , " " )

	If !( DbSeek( cGrupo + cOrdem ))

		cPergunt:= If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt)
		cPerSpa     := If(! "?" $ cPerSpa .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa)
		cPerEng     := If(! "?" $ cPerEng .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng)

		Reclock( "SX1" , .T. )

		Replace X1_GRUPO   With cGrupo
		Replace X1_ORDEM   With cOrdem
		Replace X1_PERGUNT With cPergunt
		Replace X1_PERSPA With cPerSpa
		Replace X1_PERENG With cPerEng
		Replace X1_VARIAVL With cVar
		Replace X1_TIPO    With cTipo
		Replace X1_TAMANHO With nTamanho
		Replace X1_DECIMAL With nDecimal
		Replace X1_PRESEL With nPresel
		Replace X1_GSC     With cGSC
		Replace X1_VALID   With cValid
		Replace X1_VAR01   With cVar01
		Replace X1_F3      With cF3
		Replace X1_GRPSXG With cGrpSxg

		If Fieldpos("X1_PYME") > 0
			If cPyme != Nil
				Replace X1_PYME With cPyme
			Endif
		Endif

		Replace X1_CNT01   With cCnt01
		If cGSC == "C"               // Mult Escolha
			Replace X1_DEF01   With cDef01
			Replace X1_DEFSPA1 With cDefSpa1
			Replace X1_DEFENG1 With cDefEng1

			Replace X1_DEF02   With cDef02
			Replace X1_DEFSPA2 With cDefSpa2
			Replace X1_DEFENG2 With cDefEng2

			Replace X1_DEF03   With cDef03
			Replace X1_DEFSPA3 With cDefSpa3
			Replace X1_DEFENG3 With cDefEng3

			Replace X1_DEF04   With cDef04
			Replace X1_DEFSPA4 With cDefSpa4
			Replace X1_DEFENG4 With cDefEng4

			Replace X1_DEF05   With cDef05
			Replace X1_DEFSPA5 With cDefSpa5
			Replace X1_DEFENG5 With cDefEng5
		Endif

		Replace X1_HELP With cHelp

		PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

		MsUnlock()
	Else

		lPort := ! "?" $ X1_PERGUNT .And. ! Empty(SX1->X1_PERGUNT)
		lSpa := ! "?" $ X1_PERSPA .And. ! Empty(SX1->X1_PERSPA)
		lIngl := ! "?" $ X1_PERENG .And. ! Empty(SX1->X1_PERENG)

		If lPort .Or. lSpa .Or. lIngl
			RecLock("SX1",.F.)
			If lPort
				SX1->X1_PERGUNT:= Alltrim(SX1->X1_PERGUNT)+" ?"
			EndIf
			If lSpa
				SX1->X1_PERSPA := Alltrim(SX1->X1_PERSPA) +" ?"
			EndIf
			If lIngl
				SX1->X1_PERENG := Alltrim(SX1->X1_PERENG) +" ?"
			EndIf
			SX1->(MsUnLock())
		EndIf
	Endif

	RestArea( aArea )

Return
