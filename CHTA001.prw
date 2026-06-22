#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include 'TopConn.ch'
#Include "FwBrowse.ch"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CHTA001()
		 Tela de manutenção de Registris (monitor)		 
		 de importação.		 
@author  Leandro Heilig - Apply System
@since   05/08/2019
@version 1.0
@type    User function
@history 
/*/
User Function CHTA001()
	Local oBrowse
	
	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias('Z01')
	oBrowse:SetDescription(" Monitor de Importação de Registros")
		
	oBrowse:AddLegend("Z01->Z01_STATUS == '0'"	,"BLUE"   ,"Registro Importado"     ) 		
	oBrowse:AddLegend("Z01->Z01_STATUS == '1'"	,"YELLOW" ,"Cliente Criado"         )	
	oBrowse:AddLegend("Z01->Z01_STATUS == '2'"	,"GREEN"  ,"Pedido de venda Criado" )
	oBrowse:AddLegend("Z01->Z01_STATUS == '4'"	,"PINK"   ,"Nota gerada"            )	
	oBrowse:AddLegend("Z01->Z01_STATUS == '3'"	,"RED"	  ,"Erro no registro"       )
	
	oBrowse:Activate()	
Return

/*/{Protheus.doc} MenuDef()
			Menu da rotina
@Author		Leandro Heilig
@Since		05/08/19      
@Sample		MenuDef()
@Version	P12.1.17
@menu		SIGAFAT
@Return		Nil
@Project    
@Obs	   	
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Pesquisar'    ACTION 'PesqBrw'            OPERATION 1 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'   Action 'VIEWDEF.CHTA001'	OPERATION 2 ACCESS 0	
//	ADD OPTION aRotina Title 'Incluir'      Action 'VIEWDEF.CHTA001'	OPERATION 3 ACCESS 0		
	ADD OPTION aRotina Title 'Alterar'      Action 'VIEWDEF.CHTA001'	OPERATION 4 ACCESS 0 	    
//	ADD OPTION aRotina Title 'Excluir'      Action 'VIEWDEF.CHTA001'	OPERATION 5 ACCESS 0	
	
Return aRotina

/*/{Protheus.doc} ModelDef()
		    Menu da rotina
@Author		Leandro Heilig
@Since		05/08/19      
@Sample		PCFA001
@Version	P12.1.17
@menu		SIGAFAT
@Return		oModel
@Obs	 
/*/
Static Function ModelDef()
	
	Local oModel
	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruZ01  := FWFormStruct( 1, 'Z01', /*bAvalCampo*/, /*lViewUsado*/ )
	
	//-- Cria a estrutura basica	
	oModel := MPFormModel():New('CHTA001M', { |oModel| CHT01Pre( oModel ) }/* bPreValidacao*/,/*bPosValidacao*/, { |oModel| CHT01Commit( oModel ) }/*bCommit*/, /*bCancel*/ )
	
	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'Z01MASTER', /*cOwner*/, oStruZ01, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
			
	//-- Configura o model
	oModel:SetPrimaryKey( {} )

	oModel:SetDescription('Registros Importados')
	oModel:GetModel('Z01MASTER' ):SetDescription('Registros Importados') 
	
//	oModel:SetActivate()

Return oModel

/*/{Protheus.doc} ViewDef()
		    Menu da rotina
@Author		Leandro Heilig
@Since		26/04/17      
@Sample		PCFA001
@Version	P12.1.7
@menu		SIGAGCT
@Return		oModel
@Project    Porto Carro Fácil - Customizações
@Obs	 
/*/
Static Function ViewDef()

	Local oModel   := FWLoadModel( 'CHTA001' )
	Local oStruZ01 := FWFormStruct( 2, 'Z01' )
	Local oView  
	// Local cCampos := {}
	
	// Cria o objeto de View
	oView := FWFormView():New()	
	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )	
	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_Z01', oStruZ01, 'Z01MASTER' )	
	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'TELA' , 100 )	
	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_Z01', 'TELA' )	

Return oView

/*/{Protheus.doc} CHT01Pre( oModel )
		 Pré-Validação do modelo de dados		 
@author  Leandro Heilig
@since   05/08/2019
@version 1.0
@return  oModel
/*/
Static Function CHT01Pre( oModel )
	Local	lRet		:=	.T.
	Local	nOperation	:=	oModel:GetOperation()
	Local	aArea		:=	GetArea()
	Local   cStatus     := ""
	
	If nOperation==4
		cStatus:= oModel:GetModel( 'Z01MASTER' ):GetValue( 'Z01_STATUS' )
		If cStatus<> "3" 					
			HELP(' ',1,'CHTA001' ,,'Alteração não permitida.',2,0,,,,,, {'A opção de alteração só está disponível para registros com status 3 (Erro). Utiliza a opção Visualizar.'})
			lRet:= .F.	
		Endif	
	Endif	
	RestArea(aArea)
Return lRet

/*/{Protheus.doc} cht01Commit( oModel )
		 Validação do modelo de dados e gravação de dados adicionais		 
@author  Leandro Heilig
@since   05/08/2019
@version 1.0
@return  oModel
/*/

Static Function cht01Commit( oModel )

	Local lRet          := .T. 
	Local oModel        := FwModelActive()
	Local oMdlZ01       := oModel:GetModel('Z01MASTER')
	Local aAreaZ01      := Z01->( GetArea() )
	Local nOperation    := oModel:GetOperation()
	Local nI            := 0
	Local cStatus       := ""
	Local cPedido       := ""
	Local dDtAlt        := dDataBase
	Local cUsrId        := RetCodUsr()
	
	If nOperation == 4
		
		cStatus := oMdlZ01:GetValue('Z01_STATUS')
		cPedido := oMdlZ01:GetValue('Z01_CODPV')
		
		If cStatus == "3"		
			oMdlZ01:SetValue("Z01_DTALT" ,dDtAlt )
			oMdlZ01:SetValue("Z01_USRALT",cUsrId )
			If !Empty(cPedido)
				oMdlZ01:SetValue("Z01_STATUS","2" )
			Else
				oMdlZ01:SetValue("Z01_STATUS","0" )
			Endif
			Help( ,, 'Help',, "Log de alteração gerado. Status do registro alterado de '3'(erro) para '0 '(Pendente)" , 1, 0 )				
		Endif	
	Endif	
	FWFormCommit( oModel )	
	RestArea(aAreaZ01)	
Return lRet
