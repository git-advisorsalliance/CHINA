#include "protheus.ch" 
#include "tbiconn.ch" 
#include "AP5MAIL.CH" 
/*/ +----------------------------------------------------------------------- | Função | SENDMAIL | Autor | Arnaldo R. Junior | Data | | +----------------------------------------------------------------------- | Descrição | ENVIO DE E-MAIL GENERICO | +----------------------------------------------------------------------- | Uso | Curso ADVPL | +----------------------------------------------------------------------- /*/ 
USER FUNCTION SendMail(cContato,cMensagem,cTitulo,aAttach) 

Local lResulConn := .T. 
Local lResulSend := .T. 
Local cError := "" 
Local cServer := AllTrim(GetMV("MV_RELSERV")) 
Local cEmail := AllTrim(GetMV("MV_RELACNT")) 
Local cPass := AllTrim(GetMV("MV_RELPSW")) 
Local lRelauth := GetMv("MV_RELAUTH") 
Local cDe := cEmail 
Local cPara := cContato
Local cCc := "" 
Local cAssunto := cTitulo 
Local cAnexo1 := ""
Local cAnexo2 := "" 
Local cMsg := Space(200) 
Local cCo	:= "chinatelecom@ctbrasil.com"

Local lResult
Local _lJob := .F. 
cMsg := cMensagem
CONNECT SMTP SERVER cServer ACCOUNT cEmail PASSWORD cPass RESULT lResulConn

IF(Len(aAttach)>1)
	cAnexo1	:= aAttach[1]
	cAnexo2	:= aAttach[2]
ENDIF

If !lResulConn 
	GET MAIL ERROR cError 
	If _lJob
		ConOut(Padc("Falha na conexao "+cError,80))
	Else
		FWAlertError("Erro: "+cError, "Falha no email")
	Endif 
	Return(.F.) 
Endif // Sintaxe: SEND MAIL FROM cDe TO cPara CC cCc SUBJECT cAssunto BODY cMsg ATTACHMENT cAnexo RESULT lResulSend // Todos os e-mail terão: De, Para, Assunto e Mensagem, porém precisa analisar se tem: Com Cópia e/ou Anexo 

If lRelauth 
	lResult := MailAuth(Alltrim(cEmail), Alltrim(cPass)) //Se nao conseguiu fazer a Autenticacao usando o E-mail completo, tenta fazer a autenticacao usando apenas o nome de usuario do E-mail 
	
	If !lResult 
		nA := At("@",cEmail) 
		cUser := If(nA>0,Subs(cEmail,1,nA-1),cEmail) 
		lResult := MailAuth(Alltrim(cUser), Alltrim(cPass)) 
	Endif 
Endif 

If lResult 
	If Empty(cCc) .And. Empty(cAnexo1) 
		SEND MAIL FROM cDe TO cPara SUBJECT cAssunto BODY cMsg RESULT lResulSend 
	Else
		If Empty(cCc) .And. !Empty(cAnexo1) 
			SEND MAIL FROM cDe TO cPara BCC cCo SUBJECT cAssunto BODY cMsg ATTACHMENT cAnexo1 , cAnexo2 RESULT lResulSend 
		ElseIf !Empty(cCc) .And. !Empty(cAnexo) 
			SEND MAIL FROM cDe TO cPara BCC cCo CC cCc SUBJECT cAssunto BODY cMsg ATTACHMENT cAnexo1 , cAnexo2 RESULT lResulSend 
		ElseIf Empty(cCc) .And. Empty(cAnexo) 
			SEND MAIL FROM cDe TO cPara CC cCc SUBJECT cAssunto BODY cMsg RESULT lResulSend 
		Endif 
	Endif
	
	If !lResulSend 
		GET MAIL ERROR cError 
		If _lJob
			ConOut(Padc("Falha no Envio do e-mail "+cError,80)) 
		Else 
			ConOut("Falha no Envio do e-mail " + cError) 
		Endif 
	Endif 
Else
	If _lJob
		ConOut(Padc("Falha na autenticação do e-mail: "+cError,80)) 
	Else 
		ConOut("Falha na autenticação do e-mail:" + cError) 
	Endif 
Endif 

DISCONNECT SMTP SERVER 

IF lResulSend 
	If _lJob
		ConOut(Padc("E-mail enviado com sucesso",80)) 
	Else 
		MsgInfo("E-mail enviado com sucesso!","Envio de Email") 
	Endif 
ENDIF 

RETURN lResulSend
