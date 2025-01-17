{******************************************************************************}
{ Projeto: Componentes ACBr                                                    }
{  Biblioteca multiplataforma de componentes Delphi para intera��o com equipa- }
{ mentos de Automa��o Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2009 Daniel Simoes de Almeida               }
{                                                                              }
{ Colaboradores nesse arquivo:   Jo�o Elson                                    }
{                                                                              }
{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do  Projeto ACBr    }
{ Componentes localizado em      http://www.sourceforge.net/projects/acbr      }
{                                                                              }
{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }
{                                                                              }
{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Daniel Sim�es de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{              Pra�a Anita Costa, 34 - Tatu� - SP - 18270-410                  }
{                                                                              }
{******************************************************************************}

{Conv�nio SIGCB Carteira 1 ou 2 Registrada ou Sem Registro} 

{$I ACBr.inc}

unit ACBrBancoCaixa;

interface

uses
  Classes, SysUtils, Contnrs, ACBrBoleto;

type

  { TACBrCaixaEconomica}

  TACBrCaixaEconomica = class(TACBrBancoClass)
   protected
    function GetLocalPagamento: String; override;
   private
    fValorTotalDocs:Double;
    function FormataNossoNumero(const ACBrTitulo :TACBrTitulo): String;
   public
    Constructor create(AOwner: TACBrBanco);
    function CalcularDigitoVerificador(const ACBrTitulo: TACBrTitulo ): String; override;
    function CalcularDVCedente(const ACBrTitulo: TACBrTitulo ): String;
    function MontarCodigoBarras(const ACBrTitulo : TACBrTitulo): String; override;
    function MontarCampoCodigoCedente(const ACBrTitulo: TACBrTitulo): String; override;
    function MontarCampoNossoNumero(const ACBrTitulo :TACBrTitulo): String; override;
    function GerarRegistroHeader240(NumeroRemessa : Integer): String; override;
    function GerarRegistroTransacao240(ACBrTitulo : TACBrTitulo): String; override;
    function GerarRegistroTrailler240(ARemessa : TStringList): String;  override;
    procedure LerRetorno240(ARetorno: TStringList); override;
    procedure LerRetorno400(ARetorno: TStringList); override; 
    function CodMotivoRejeicaoToDescricao(const TipoOcorrencia: TACBrTipoOcorrencia; CodMotivo: Integer): string; override;
    function TipoOcorrenciaToDescricao(const TipoOcorrencia: TACBrTipoOcorrencia): String; override;
    function CodOcorrenciaToTipo(const CodOcorrencia: Integer): TACBrTipoOcorrencia; override;
    function TipoOCorrenciaToCod(const TipoOcorrencia: TACBrTipoOcorrencia): String; override;
    function CodigoLiquidacao_Descricao( CodLiquidacao : Integer) : String;
   end;

implementation

uses StrUtils, Variants,
  {$IFDEF COMPILER6_UP} DateUtils {$ELSE} ACBrD5, FileCtrl {$ENDIF},
  ACBrUtil;

constructor TACBrCaixaEconomica.create(AOwner: TACBrBanco);
begin
   inherited create(AOwner);
   fpDigito                := 0;
   fpNome                  := 'Caixa Economica Federal';
   fpNumero                := 104;
   fpTamanhoAgencia        := 5;
   fpTamanhoMaximoNossoNum := 15;
   fpTamanhoCarteira       := 2;
   fValorTotalDocs         := 0;

   fpOrientacoesBanco.Clear;
   fpOrientacoesBanco.Add(ACBrStr(
                          'SAC CAIXA: 0800 726 0101 (informa��es, reclama��es, sugest�es e elogios) ' + sLineBreak +
                          'Para pessoas com defici�ncia auditiva ou de fala: 0800 726 2492 ' + sLineBreak +
                          'Ouvidoria: 0800 725 7474') + sLineBreak +
                          '     caixa.gov.br      ');
end;

function TACBrCaixaEconomica.CalcularDigitoVerificador(const ACBrTitulo: TACBrTitulo ): String;
var
  Num, ACarteira, ANossoNumero, Res :String;
begin
   Result := '0';
   if (ACBrTitulo.Carteira = 'RG') then
      ACarteira := '1'
   else if (ACBrTitulo.Carteira = 'SR')then
      ACarteira := '2'
   else
      raise Exception.Create( ACBrStr('Carteira Inv�lida.'+sLineBreak+'Utilize "RG" ou "SR"') ) ;

   ANossoNumero := OnlyNumber(ACBrTitulo.NossoNumero);

   if ACBrTitulo.CarteiraEnvio = tceCedente then //O Cedente � quem envia o boleto
      Num := ACarteira + '4' + PadLeft(ANossoNumero, 15, '0')
   else
      Num := ACarteira + '1' + PadLeft(ANossoNumero, 15, '0'); //o Banco � quem Envia

   Modulo.CalculoPadrao;
   Modulo.MultiplicadorFinal   := 2;
   Modulo.MultiplicadorInicial := 9;
   Modulo.Documento := Num;
   Modulo.Calcular;

   Res:= IntToStr(Modulo.ModuloFinal);

   if Length(Res) > 1 then
      Result := '0'
   else
      Result := Res[1];

end;

function TACBrCaixaEconomica.CalcularDVCedente(const ACBrTitulo: TACBrTitulo): String;
var
  Num, Res: string;
begin 
    Num := RightStr(ACBrTitulo.ACBrBoleto.Cedente.CodigoCedente,6);
    Modulo.CalculoPadrao;
    Modulo.MultiplicadorFinal   := 2;
    Modulo.MultiplicadorInicial := 9;
    Modulo.Documento := Num;
    Modulo.Calcular;
    Res := intTostr(Modulo.ModuloFinal);

    if Length(Res) > 1 then
       Result := '0'
    else
       Result := Res[1];
end;

function TACBrCaixaEconomica.GetLocalPagamento: String;
begin
  Result := 'Preferencialmente nas Casas Lot�ricas at� o valor limite';
end;

function TACBrCaixaEconomica.FormataNossoNumero(const ACBrTitulo :TACBrTitulo): String;
var
  ANossoNumero :String;
begin
   with ACBrTitulo do
   begin
      ANossoNumero := OnlyNumber(NossoNumero);

      if (ACBrTitulo.Carteira = 'RG') then
      begin         {carterira registrada}
        if ACBrTitulo.CarteiraEnvio = tceCedente then
          ANossoNumero := '14'+PadLeft(ANossoNumero, 15, '0')
        else
          ANossoNumero := '11'+PadLeft(ANossoNumero, 15, '0')
      end
      else if (ACBrTitulo.Carteira = 'SR')then     {carteira 2 sem registro}
      begin
        if ACBrTitulo.CarteiraEnvio = tceCedente then
          ANossoNumero := '24'+PadLeft(ANossoNumero, 15, '0')
        else
          ANossoNumero := '21'+PadLeft(ANossoNumero, 15, '0')
      end
      else
         raise Exception.Create( ACBrStr('Carteira Inv�lida.'+sLineBreak+'Utilize "RG" ou "SR"') ) ;
   end;

   Result := ANossoNumero;
end;

function TACBrCaixaEconomica.MontarCodigoBarras(const ACBrTitulo : TACBrTitulo): String;
var
  CodigoBarras, FatorVencimento, DigitoCodBarras :String;
  CampoLivre,DVCampoLivre, ANossoNumero : String;
begin

    FatorVencimento := CalcularFatorVencimento(ACBrTitulo.Vencimento);
    
    ANossoNumero := FormataNossoNumero(ACBrTitulo);

    {Montando Campo Livre}
    CampoLivre := PadLeft(ACBrTitulo.ACBrBoleto.Cedente.CodigoCedente,6,'0') +
                  CalcularDVCedente(ACBrTitulo) + Copy(ANossoNumero,3,3)  +
                  Copy(ANossoNumero,1,1) + Copy(ANossoNumero,6,3)         +
                  Copy(ANossoNumero,2,1) + Copy(ANossoNumero,9,9);

    Modulo.CalculoPadrao;
    Modulo.MultiplicadorFinal   := 2;
    Modulo.MultiplicadorInicial := 9;
    Modulo.Documento := CampoLivre;
    Modulo.Calcular;
    DVCampoLivre := intTostr(Modulo.ModuloFinal);

    if Length(DVCampoLivre) > 1 then
       DVCampoLivre := '0';

    CampoLivre := CampoLivre + DVCampoLivre;
    
    {Codigo de Barras}
    with ACBrTitulo.ACBrBoleto do
    begin
       CodigoBarras := IntToStrZero(Banco.Numero, 3) +
                       '9' +
                       FatorVencimento +
                       IntToStrZero(Round(ACBrTitulo.ValorDocumento * 100), 10) +
                       CampoLivre;
    end;

    DigitoCodBarras := CalcularDigitoCodigoBarras(CodigoBarras);
    Result:= copy( CodigoBarras, 1, 4) + DigitoCodBarras + copy( CodigoBarras, 5, 44);
end;

function TACBrCaixaEconomica.TipoOCorrenciaToCod(const TipoOcorrencia: TACBrTipoOcorrencia): String;
begin

  if (ACBrBanco.ACBrBoleto.LayoutRemessa = c240) then
  begin
    case TipoOcorrencia of
      toRetornoSolicitacaoImpressaoTituloConfirmada            : Result := '01';
      toRetornoRegistroConfirmado                              : Result := '02';
      toRetornoRegistroRecusado                                : Result := '03';
      toRetornoTransferenciaCarteiraEntrada                    : Result := '04';
      toRetornoTransferenciaCarteiraBaixa                      : Result := '05';
      toRetornoLiquidado                                       : Result := '06';
      toRetornoRecebimentoInstrucaoConcederDesconto            : Result := '07';
      toRetornoRecebimentoInstrucaoCancelarDesconto            : Result := '08';
      toRetornoBaixado                                         : Result := '09';
      toRetornoRecebimentoInstrucaoConcederAbatimento          : Result := '12';
      toRetornoRecebimentoInstrucaoCancelarAbatimento          : Result := '13';
      toRetornoRecebimentoInstrucaoAlterarVencimento           : Result := '14';
      toRetornoRecebimentoInstrucaoProtestar                   : Result := '19';
      toRetornoRecebimentoInstrucaoSustarProtesto              : Result := '20';
      toRetornoBaixaPorProtesto                                : Result := '25';
      toRetornoInstrucaoRejeitada                              : Result := '26';
      toRetornoAlteracaoUsoCedente                             : Result := '27';
      toRetornoDebitoTarifas                                   : Result := '28';
      toRetornoAlteracaoOutrosDadosRejeitada                   : Result := '30';
      toRetornoConfirmacaoInclusaoBancoSacado                  : Result := '35';
      toRetornoConfirmacaoAlteracaoBancoSacado                 : Result := '36';
      toRetornoConfirmacaoExclusaoBancoSacado                  : Result := '37';
      toRetornoEmissaoBloquetoBancoSacado                      : Result := '38';
      toRetornoManutencaoSacadoRejeitada                       : Result := '39';
      toRetornoEntradaTituloBancoSacadoRejeitada               : Result := '40';
      toRetornoManutencaoBancoSacadoRejeitada                  : Result := '41';
      toRetornoBaixaOuLiquidacaoEstornada                      : Result := '44';
      toRetornoRecebimentoInstrucaoAlterarDados                : Result := '45';
    end;
  end
  else
  begin
    case TipoOcorrencia of
      toRetornoRegistroConfirmado                              : Result := '01';
      toRetornoBaixaManualConfirmada                           : Result := '02';
      toRetornoAbatimentoConcedido                             : Result := '03';
      toRetornoAbatimentoCancelado                             : Result := '04';
      toRetornoVencimentoAlterado                              : Result := '05';
      toRetornoAlteracaoUsoCedente                             : Result := '06';
      toRetornoPrazoProtestoAlterado                           : Result := '07';
      toRetornoPrazoDevolucaoAlterado                          : Result := '08';
      toRetornoDadosAlterados                                  : Result := '09';
      toRetornoAlteracaoReemissaoBloquetoConfirmada            : Result := '10';
      toRetornoAlteracaoOpcaoProtestoParaDevolucaoConfirmada   : Result := '11';
      toRetornoAlteracaoOpcaoDevolucaoParaProtestoConfirmada   : Result := '12';
      toRetornoTituloEmSer                                     : Result := '20';
      toRetornoLiquidado                                       : Result := '21';
      toRetornoLiquidadoEmCartorio                             : Result := '22';
      toRetornoBaixadoPorDevolucao                             : Result := '23';
      toRetornoBaixaPorProtesto                                : Result := '25';
      toRetornoEncaminhadoACartorio                            : Result := '26';
      toRetornoProtestoSustado                                 : Result := '27';
      toRetornoEstornoProtesto                                 : Result := '28';
      toRetornoProtestoOuSustacaoEstornado                     : Result := '29';
      toRetornoRecebimentoInstrucaoAlterarDados                : Result := '30';
      toRetornoTarifaDeManutencaoDeTitulosVencidos             : Result := '31';
      toRetornoOutrasTarifasAlteracao                          : Result := '32';
      toRetornoEstornoBaixaLiquidacao                          : Result := '33';
      toRetornoDebitoTarifas                                   : Result := '34';
      toRetornoRegistroRecusado                                : Result := '99';
    end;
  end;
end;

function TACBrCaixaEconomica.MontarCampoCodigoCedente (
   const ACBrTitulo: TACBrTitulo ) : String;
begin
  Result := RightStr(ACBrTitulo.ACBrBoleto.Cedente.Agencia,4)+ '/' +
            ACBrTitulo.ACBrBoleto.Cedente.CodigoCedente+ '-' +
                CalcularDVCedente(ACBrTitulo);
end;

function TACBrCaixaEconomica.MontarCampoNossoNumero (const ACBrTitulo: TACBrTitulo ) : String;
var ANossoNumero : string;
begin
    ANossoNumero := FormataNossoNumero(ACBrTitulo);

    Result := ANossoNumero + '-' + CalcularDigitoVerificador(ACBrTitulo);
end;

function TACBrCaixaEconomica.GerarRegistroHeader240(NumeroRemessa : Integer): String;
var
  ATipoInscricao: string;
begin

   with ACBrBanco.ACBrBoleto.Cedente do
   begin
      case TipoInscricao of
         pFisica  : ATipoInscricao := '1';
         pJuridica: ATipoInscricao := '2';
      end;

          { GERAR REGISTRO-HEADER DO ARQUIVO }

      Result:= IntToStrZero(ACBrBanco.Numero, 3)       + //1 a 3 - C�digo do banco
               '0000'                                  + //4 a 7 - Lote de servi�o
               '0'                                     + //8 - Tipo de registro - Registro header de arquivo
               PadRight('', 9, ' ')                        + //9 a 17 Uso exclusivo FEBRABAN/CNAB
               ATipoInscricao                          + //18 - Tipo de inscri��o do cedente
               PadLeft(OnlyNumber(CNPJCPF), 14, '0')      + //19 a 32 -N�mero de inscri��o do cedente
               //PadRight(CodigoCedente, 18, '0') + '  '     + //33 a 52 - C�digo do conv�nio no banco [ Alterado conforme instru��es da CSO Bras�lia ] 27-07-09
               PadRight('',20, '0')                        +  //33 a 52 - C�digo do conv�nio no banco
               PadLeft(OnlyNumber(Agencia), 5, '0')       + //53 a 57 - C�digo da ag�ncia do cedente
               PadRight(AgenciaDigito, 1 , '0')            + //58 - D�gito da ag�ncia do cedente
               PadLeft(CodigoCedente, 6, '0')             + //59 a 64 - C�digo Cedente (C�digo do Conv�nio no Banco)
               PadRight('', 7, '0')                        + //65 a 71 - Uso Exclusivo CAIXA
               '0'                                     + //72 - Uso Exclusivo CAIXA
               PadRight(Nome, 30, ' ')                     + //73 a 102 - Nome do cedente
               PadRight('CAIXA ECONOMICA FEDERAL', 30, ' ') + //103 a 132 - Nome do banco
               PadRight('', 10, ' ')                       + //133 a 142 - Uso exclusivo FEBRABAN/CNAB
               '1'                                     + //143 - C�digo de Remessa (1) / Retorno (2)
               FormatDateTime('ddmmyyyy', Now)         + //144 a 151 - Data do de gera��o do arquivo
               FormatDateTime('hhmmss', Now)           + //152 a 157 - Hora de gera��o do arquivo
               PadLeft(IntToStr(NumeroRemessa), 6, '0')   + //158 a 163 - N�mero seq�encial do arquivo
               '050'                                   + //164 a 166 - N�mero da vers�o do layout do arquivo
               PadRight('',  5, '0')                       + //167 a 171 - Densidade de grava��o do arquivo (BPI)
               Space(20)                               + // 172 a 191 - Uso reservado do banco
               PadRight('REMESSA-PRODUCAO', 20, ' ')       + // 192 a 211 - Uso reservado da empresa
               PadRight('', 4, ' ')                        + // 212 a 215 - Versao Aplicativo Caixa
               PadRight('', 25, ' ');                        // 216 a 240 - Uso Exclusivo FEBRABAN / CNAB

          { GERAR REGISTRO HEADER DO LOTE }

      Result:= Result + #13#10 +
               IntToStrZero(ACBrBanco.Numero, 3)       + //1 a 3 - C�digo do banco
               '0001'                                  + //4 a 7 - Lote de servi�o
               '1'                                     + //8 - Tipo de registro - Registro header de arquivo
               'R'                                     + //9 - Tipo de opera��o: R (Remessa) ou T (Retorno)
               '01'                                    + //10 a 11 - Tipo de servi�o: 01 (Cobran�a)
               '00'                                    + //12 a 13 - Forma de lan�amento: preencher com ZEROS no caso de cobran�a
               '030'                                   + //14 a 16 - N�mero da vers�o do layout do lote
               ' '                                     + //17 - Uso exclusivo FEBRABAN/CNAB
               ATipoInscricao                          + //18 - Tipo de inscri��o do cedente
               PadLeft(OnlyNumber(CNPJCPF), 15, '0')      + //19 a 33 -N�mero de inscri��o do cedente
               PadLeft(CodigoCedente, 6, '0')             + //34 a 39 - C�digo do conv�nio no banco (c�digo do cedente)
               PadRight('', 14, '0')                       + //40 a 53 - Uso Exclusivo Caixa
               PadLeft(OnlyNumber(Agencia), 5 , '0')      + //54 a 58 - D�gito da ag�ncia do cedente
               PadRight(AgenciaDigito, 1 , '0')            + //59 - D�gito da ag�ncia do cedente
               PadLeft(CodigoCedente, 6, '0')             + //60 a 65 - C�digo do conv�nio no banco (c�digo do cedente)
               PadRight('',7,'0')                          + //66 a 72 - C�digo do Modelo Personalizado (C�digo fornecido pela CAIXA/gr�fica, utilizado somente quando o modelo do bloqueto for personalizado)
               '0'                                     + //73 - Uso Exclusivo Caixa
               PadRight(Nome, 30, ' ')                     + //74 a 103 - Nome do cedente
               PadRight('', 40, ' ')                       + //104 a 143 - Mensagem 1 para todos os boletos do lote
               PadRight('', 40, ' ')                       + //144 a 183 - Mensagem 2 para todos os boletos do lote
               PadLeft(IntToStr(NumeroRemessa), 8, '0')   + //184 a 191 - N�mero do arquivo
               FormatDateTime('ddmmyyyy', Now)         + //192 a 199 - Data de gera��o do arquivo
               PadRight('', 8, '0')                        + //200 a 207 - Data do cr�dito - S� para arquivo retorno
               PadRight('', 33, ' ');                        //208 a 240 - Uso exclusivo FEBRABAN/CNAB
   end;
end;

function TACBrCaixaEconomica.GerarRegistroTransacao240(ACBrTitulo : TACBrTitulo): String;
var
  ATipoOcorrencia, ATipoBoleto, ADataMoraJuros         : String;
  ADataDesconto, ADataMulta, ANossoNumero, ATipoAceite, AEspecieDoc: String; 
begin
   with ACBrTitulo do
   begin
      if ( Trim(ACBrTitulo.NossoNumero) <> '' ) then
        ANossoNumero := FormataNossoNumero(ACBrTitulo)
      else
        ANossoNumero := '';  

      {SEGMENTO P}

      {Pegando o Tipo de Ocorrencia}
      case OcorrenciaOriginal.Tipo of
        toRemessaBaixar                        : ATipoOcorrencia := '02';
        toRemessaConcederAbatimento            : ATipoOcorrencia := '04';
        toRemessaCancelarAbatimento            : ATipoOcorrencia := '05';
        toRemessaAlterarVencimento             : ATipoOcorrencia := '06';
        toRemessaConcederDesconto              : ATipoOcorrencia := '07';
        toRemessaCancelarDesconto              : ATipoOcorrencia := '08';
        toRemessaProtestar                     : ATipoOcorrencia := '09';
        toRemessaCancelarInstrucaoProtestoBaixa: ATipoOcorrencia := '10';
        toRemessaCancelarInstrucaoProtesto     : ATipoOcorrencia := '11';
        toRemessaDispensarJuros                : ATipoOcorrencia := '13';
        toRemessaAlterarNomeEnderecoSacado     : ATipoOcorrencia := '31';
      else
        ATipoOcorrencia := '01';
      end;

      { Pegando o Aceite do Titulo }
      case Aceite of
         atSim :  ATipoAceite := 'A';
         atNao :  ATipoAceite := 'N';
      end;

      if AnsiSameText(EspecieDoc, 'CH') then
        AEspecieDoc := '01'
      else if AnsiSameText(EspecieDoc, 'DM') then
        AEspecieDoc := '02'
      else if AnsiSameText(EspecieDoc, 'DMI') then
        AEspecieDoc := '03'
      else if AnsiSameText(EspecieDoc, 'DS') then
        AEspecieDoc := '04'
      else if AnsiSameText(EspecieDoc, 'DSI') then
        AEspecieDoc := '05'
      else if AnsiSameText(EspecieDoc, 'DR') then
        AEspecieDoc := '06'
      else if AnsiSameText(EspecieDoc, 'LC') then
        AEspecieDoc := '07'
      else if AnsiSameText(EspecieDoc, 'NCC') then
        AEspecieDoc := '08'
      else if AnsiSameText(EspecieDoc, 'NCE') then
        AEspecieDoc := '09'
      else if AnsiSameText(EspecieDoc, 'NCI') then
        AEspecieDoc := '10'
      else if AnsiSameText(EspecieDoc, 'NCR') then
        AEspecieDoc := '11'
      else if AnsiSameText(EspecieDoc, 'NP') then
        AEspecieDoc := '12'
      else if AnsiSameText(EspecieDoc, 'NPR') then
        AEspecieDoc := '13'
      else if AnsiSameText(EspecieDoc, 'TM') then
        AEspecieDoc := '14'
      else if AnsiSameText(EspecieDoc, 'TS') then
        AEspecieDoc := '15'
      else if AnsiSameText(EspecieDoc, 'NS') then
        AEspecieDoc := '16'
      else if AnsiSameText(EspecieDoc, 'RC') then
        AEspecieDoc := '17'
      else if AnsiSameText(EspecieDoc, 'FAT') then
        AEspecieDoc := '18'
      else if AnsiSameText(EspecieDoc, 'ND') then
        AEspecieDoc := '19'
      else if AnsiSameText(EspecieDoc, 'AP') then
        AEspecieDoc := '20'
      else if AnsiSameText(EspecieDoc, 'ME') then
        AEspecieDoc := '21'
      else if AnsiSameText(EspecieDoc, 'PC') then
        AEspecieDoc := '22'
      else if AnsiSameText(EspecieDoc, 'NF') then
        AEspecieDoc := '23'
      else if AnsiSameText(EspecieDoc, 'DD') then
        AEspecieDoc := '24'
      else if AnsiSameText(EspecieDoc, 'CPR') then
        AEspecieDoc := '25'
      else
        AEspecieDoc := '99';

      {Pegando Tipo de Boleto} //Quem emite e quem distribui o boleto?
      case ACBrBoleto.Cedente.ResponEmissao of
         tbBancoEmite      : ATipoBoleto := '1' + '1';
         tbCliEmite        : ATipoBoleto := '2' + '0';
         tbBancoReemite    : ATipoBoleto := '4' + '1';
         tbBancoNaoReemite : ATipoBoleto := '5' + '2';
      end;

      {Mora Juros}
      if (ValorMoraJuros > 0) then
       begin
         if DataMoraJuros <> 0 then
            ADataMoraJuros := FormatDateTime('ddmmyyyy', DataMoraJuros)
         else
            ADataMoraJuros := PadRight('', 8, '0');
       end
      else
         ADataMoraJuros := PadRight('', 8, '0');

      {Descontos}
      if (ValorDesconto > 0) then
       begin
         if (DataDesconto <> Null) then
            ADataDesconto := FormatDateTime('ddmmyyyy', DataDesconto)
         else
            ADataDesconto := PadRight('', 8, '0');
       end
      else
         ADataDesconto := PadRight('', 8, '0');

      {Multa}
      if (PercentualMulta > 0) then
        ADataMulta := IfThen(DataMoraJuros > 0,
                             FormatDateTime('ddmmyyyy', DataMoraJuros),
                             FormatDateTime('ddmmyyyy', Vencimento + 1))
      else
        ADataMulta := PadLeft('', 8, '0');

      fValorTotalDocs:= fValorTotalDocs  + ValorDocumento;
      Result:= IntToStrZero(ACBrBanco.Numero, 3)                          + //1 a 3 - C�digo do banco
               '0001'                                                     + //4 a 7 - Lote de servi�o
               '3'                                                        + //8 - Tipo do registro: Registro detalhe
               IntToStrZero((3*ACBrBoleto.ListadeBoletos.IndexOf(ACBrTitulo))+1,5) + //9 a 13 - N�mero seq�encial do registro no lote - Cada t�tulo tem 2 registros (P e Q)
               'P'                                                        + //14 - C�digo do segmento do registro detalhe
               ' '                                                        + //15 - Uso exclusivo FEBRABAN/CNAB: Branco
               ATipoOcorrencia                                            + //16 a 17 - C�digo de movimento
               PadLeft(OnlyNumber(ACBrBoleto.Cedente.Agencia), 5, '0')       + //18 a 22 - Ag�ncia mantenedora da conta
               PadRight(ACBrBoleto.Cedente.AgenciaDigito, 1 , '0')            + //23 -D�gito verificador da ag�ncia
               PadRight(ACBrBoleto.Cedente.CodigoCedente, 6, '0')             + //24 a 29 - C�digo do Conv�nio no Banco (Codigo do cedente)
               PadRight('', 11, '0')                                          + //30 a 40 - Uso Exclusivo da CAIXA
               PadRight(Copy(ANossoNumero,1,2), 2, '0')                                                        + //41 a 42 - Modalidade da Carteira
               PadLeft(Copy(ANossoNumero,3,17), 15, '0')                     + //43 a 57 - Nosso n�mero - identifica��o do t�tulo no banco
               '1'                                                        + //58 - Cobran�a Simples
               '1'                                                        + //59 - Forma de cadastramento do t�tulo no banco: com cadastramento  1-cobran�a Registrada
               '2'                                                        + //60 - Tipo de documento: Tradicional
               ATipoBoleto                                                + //61 e 62(juntos)- Quem emite e quem distribui o boleto?
               PadRight(NumeroDocumento, 11, ' ')                             + //63 a 73 - N�mero que identifica o t�tulo na empresa
               PadRight('', 4, ' ')                                           + //74 a 77 - Uso Exclusivo Caixa
               FormatDateTime('ddmmyyyy', Vencimento)                     + //78 a 85 - Data de vencimento do t�tulo
               IntToStrZero( round( ValorDocumento * 100), 15)            + //86 a 100 - Valor nominal do t�tulo
               PadRight('', 5, '0')                                           + //101 a 105 - Ag�ncia cobradora. Se ficar em branco, a caixa determina automaticamente pelo CEP do sacado
               '0'                                                        + //106 - D�gito da ag�ncia cobradora
               PadRight(AEspecieDoc, 2)                                       + // 107 a 108 - Esp�cie do documento
               ATipoAceite                                                + //109 - Identifica��o de t�tulo Aceito / N�o aceito
               FormatDateTime('ddmmyyyy', DataDocumento)                  + //110 a 117 - Data da emiss�o do documento
               IfThen(ValorMoraJuros > 0, '1', '3')                       + //118 - C�digo de juros de mora: Valor por dia
               ADataMoraJuros                                             + //119 a 126 - Data a partir da qual ser�o cobrados juros
               IfThen(ValorMoraJuros > 0, IntToStrZero( round(ValorMoraJuros * 100), 15), PadRight('', 15, '0')) + //127 a 141 - Valor de juros de mora por dia
               IfThen(ValorDesconto > 0, '1', '0')                        + //142 - C�digo de desconto: Valor fixo at� a data informada
               ADataDesconto                                              + //143 a 150 - Data do desconto
               IfThen(ValorDesconto > 0, IntToStrZero( round(ValorDesconto * 100), 15),PadRight('', 15, '0'))+ //151 a 165 - Valor do desconto por dia
               IntToStrZero( round(ValorIOF * 100), 15)                   + //166 a 180 - Valor do IOF a ser recolhido
               IntToStrZero( round(ValorAbatimento * 100), 15)            + //181 a 195 - Valor do abatimento
               PadRight(IfThen(SeuNumero<>'',SeuNumero,NumeroDocumento), 25, ' ') + //196 a 220 - Identifica��o do t�tulo na empresa
               IfThen((DataProtesto <> 0) and (DataProtesto > Vencimento), '1', '3') + //221 - C�digo de protesto: Protestar em XX dias corridos
               IfThen((DataProtesto <> 0) and (DataProtesto > Vencimento),
                    PadLeft(IntToStr(DaysBetween(DataProtesto, Vencimento)), 2, '0'), '00') + //222 a 223 - Prazo para protesto (em dias corridos)
               IfThen((DataBaixa <> 0) and (DataBaixa > Vencimento), '1', '2') + //224 - C�digo para baixa/devolu��o: N�o baixar/n�o devolver
               IfThen((DataBaixa <> 0) and (DataBaixa > Vencimento),
                 PadLeft(IntToStr(DaysBetween(DataBaixa, Vencimento)), 3, '0'), '000') + //225 a 227 - Prazo para baixa/devolu��o (em dias corridos)

               '09'                                                       + //228 a 229 - C�digo da moeda: Real
               PadRight('', 10 , '0')                                         + //230 a 239 - Uso Exclusivo CAIXA
               ' ';                                                         //240 - Uso exclusivo FEBRABAN/CNAB

      {SEGMENTO Q}
      Result:= Result + #13#10 +
               IntToStrZero(ACBrBanco.Numero, 3)                                       + //1 a 3 - C�digo do banco
               '0001'                                                                  + //4 a 7 - N�mero do lote
               '3'                                                                     + //8 - Tipo do registro: Registro detalhe
               IntToStrZero((3 * ACBrBoleto.ListadeBoletos.IndexOf(ACBrTitulo))+ 2 ,5) + //9 a 13 - N�mero seq�encial do registro no lote - Cada t�tulo tem 2 registros (P e Q)
               'Q'                                                                     + //14 - C�digo do segmento do registro detalhe
               ' '                                                                     + //15 - Uso exclusivo FEBRABAN/CNAB: Branco
               ATipoOcorrencia                                                         + //16 a 17 - C�digo de movimento
                   {Dados do sacado}
               IfThen(Sacado.Pessoa = pJuridica,'2','1')                               + //18 - Tipo inscricao
               PadLeft(OnlyNumber(Sacado.CNPJCPF), 15, '0')                            + //19 a 33 - N�mero de Inscri��o
               PadRight(Sacado.NomeSacado, 40, ' ')                                    + //34 a 73 - Nome sacado
               PadRight(Sacado.Logradouro + ' ' + Sacado.Numero + ' ' + 
                        Sacado.Complemento , 40, ' ')                                  + //74 a 113 - Endere�o
               PadRight(Sacado.Bairro, 15, ' ')                                        + // 114 a 128 - bairro sacado
               PadLeft(OnlyNumber(Sacado.CEP), 8, '0')                                 + // 129 a 133 e 134 a 136- cep sacado prefixo e sufixo sem o tra�o"-" somente numeros
               PadRight(Sacado.Cidade, 15, ' ')                                        + // 137 a 151 - cidade sacado
               PadRight(Sacado.UF, 2, ' ')                                             + // 152 a 153 - UF sacado
               {Dados do sacador/avalista}
               IfThen(EstaVazio(Sacado.SacadoAvalista.NomeAValista),
                      '0',
                      IfThen(Sacado.SacadoAvalista.Pessoa = pJuridica,
                             '2',
                             '1'
                      )
               )                                                                       + // 154 a 157 - Tipo de Inscri��o
               PadLeft(OnlyNumber(Sacado.SacadoAvalista.CNPJCPF), 15, '0')             + // 155 a 169 - N�mero de inscri��o
               PadRight(Sacado.SacadoAvalista.NomeAValista, 40, ' ')                   + // 170 a 209 - Nome do sacador/avalista
               PadRight('', 3, '0')                                                    + // 210 a 212 - Uso exclusivo FEBRABAN/CNAB
               PadRight('',20, ' ')                                                    + // 213 a 232 - Uso exclusivo FEBRABAN/CNAB
               PadRight('', 8, ' ');                                                     // 233 a 240 - Uso exclusivo FEBRABAN/CNAB

 {SEGMENTO R}
      Result:= Result + #13#10 +
               IntToStrZero(ACBrBanco.Numero, 3)                                           + //   1 a 3   - C�digo do banco
               '0001'                                                                      + //   4 a 7   - N�mero do lote
               '3'                                                                         + //   8 a 8   - Tipo do registro: Registro detalhe
               IntToStrZero((3 * ACBrBoleto.ListadeBoletos.IndexOf(ACBrTitulo))+ 3 ,5)     + //   9 a 13  - N�mero seq�encial do registro no lote - Cada t�tulo tem 2 registros (P e Q)
               'R'                                                                         + //  14 a 14  - C�digo do segmento do registro detalhe
               ' '                                                                         + //  15 a 15  - Uso exclusivo FEBRABAN/CNAB: Branco
               ATipoOcorrencia                                                             + //  16 a 17  - Tipo Ocorrencia
               PadLeft('', 1,  '0')                                                           + //  18 a 18  - Codigo do Desconto 2
               PadLeft('', 8,  '0')                                                           + //  19 a 26  - Data do Desconto 2
               PadLeft('', 15, '0')                                                           + //  27 a 41  - Valor/Percentual a ser concedido
               PadLeft('', 1,  '0')                                                           + //  42 a 42  - C�digo do Desconto 3
               PadLeft('', 8,  '0')                                                           + //  43 a 50  - Data do Desconto 3
               PadLeft('', 15, '0')                                                           + //  51 a 65  - Valor/Percentual a ser concedido
               IfThen((PercentualMulta <> null) and (PercentualMulta > 0), '2', '0')       + //  66 a 66  - C�digo da Multa
               ADataMulta                                                                  + //  67 a 74  - Data da Multa
               IfThen(PercentualMulta > 0, IntToStrZero(round(PercentualMulta * 100), 15),
                      PadRight('', 15, '0'))                                                   + //  75 a 89  - Valor/Percentual a ser aplicado
               PadRight('', 10, ' ')                                                           + //  90 a 99  - Informa��o ao Sacado
               PadRight('', 40, ' ')                                                           + // 100 a 139 - Mensagem 3
               PadRight('', 40, ' ')                                                           + // 140 a 179 - Mensagem 4
               PadRight(Sacado.Email, 50, ' ')                                                           + // 180 a 229 - Email do Sacado P/ Envio de Informacoes
               PadRight('', 11, ' ');                                                            // 230 a 240 - Uso Exclusivo Febraban/CNAB
      end;
end;

function TACBrCaixaEconomica.GerarRegistroTrailler240( ARemessa : TStringList ): String;
var
  wQTDTitulos: Integer;
begin

   wQTDTitulos := ARemessa.Count - 1;
   {REGISTRO TRAILER DO LOTE}
   Result:= IntToStrZero(ACBrBanco.Numero, 3)                          + //C�digo do banco
            '0001'                                                     + //Lote de Servi�o
            '5'                                                        + //Tipo do registro: Registro trailer do lote
            Space(9)                                                   + //Uso exclusivo FEBRABAN/CNAB
            IntToStrZero((3* wQTDTitulos + 2 ), 6)                     + //Quantidade de Registro no Lote (Registros P,Q,R, header e trailer do lote)
            IntToStrZero((wQTDTitulos), 6)                             + //Quantidade t�tulos em cobran�a
            IntToStrZero( round( fValorTotalDocs * 100), 17)           + //Valor dos t�tulos em carteiras}
            PadRight('', 6, '0')                                           + //Quantidade t�tulos em cobran�a
            PadRight('',17, '0')                                           + //Valor dos t�tulos em carteiras}
            PadRight('',6,  '0')                                           + //Quantidade t�tulos em cobran�a
            PadRight('',17, '0')                                           + //Quantidade de T�tulos em Carteiras
            PadRight('',31, ' ')                                           + //Uso exclusivo FEBRABAN/CNAB
            PadRight('',117,' ')                                           ; //Uso exclusivo FEBRABAN/CNAB}

   {GERAR REGISTRO TRAILER DO ARQUIVO}
   Result:= Result + #13#10 +
            IntToStrZero(ACBrBanco.Numero, 3)                          + //C�digo do banco
            '9999'                                                     + //Lote de servi�o
            '9'                                                        + //Tipo do registro: Registro trailer do arquivo
            PadRight('',9,' ')                                             + //Uso exclusivo FEBRABAN/CNAB}
            '000001'                                                   + //Quantidade de lotes do arquivo (Registros P,Q,R, header e trailer do lote e do arquivo)
            IntToStrZero((3* wQTDTitulos)+4, 6)                        + //Quantidade de registros do arquivo, inclusive este registro que est� sendo criado agora}
            PadRight('',6,' ')                                             + //Uso exclusivo FEBRABAN/CNAB}
            PadRight('',205,' ');                                            //Uso exclusivo FEBRABAN/CNAB}
end;
procedure TACBrCaixaEconomica.LerRetorno240(ARetorno: TStringList);
var
  ContLinha: Integer;
  Titulo   : TACBrTitulo;
  Linha, rCedente, rCNPJCPF: String;
  rAgencia, rConta,rDigitoConta: String;
  MotivoLinha, I, CodMotivo: Integer;
  wSeuNumero: String;
begin
 
   if (copy(ARetorno.Strings[0],1,3) <> '104') then
      raise Exception.Create(ACBrStr(ACBrBanco.ACBrBoleto.NomeArqRetorno +
                             'n�o � um arquivo de retorno do '+ Nome));

   rCedente := trim(Copy(ARetorno[0],73,30));
   rAgencia := trim(Copy(ARetorno[0],53,5));
   rConta   := trim(Copy(ARetorno[0],59,5));
   rDigitoConta := Copy(ARetorno[0],64,1);
   ACBrBanco.ACBrBoleto.NumeroArquivo := StrToIntDef(Copy(ARetorno[0], 158, 6), 0);

   ACBrBanco.ACBrBoleto.DataArquivo   := StringToDateTimeDef(Copy(ARetorno[1],192,2)+'/'+
                                                             Copy(ARetorno[1],194,2)+'/'+
                                                             Copy(ARetorno[1],198,2),0, 'DD/MM/YY' );

   if StrToIntDef(Copy(ARetorno[1],200,6),0) <> 0 then
      ACBrBanco.ACBrBoleto.DataCreditoLanc := StringToDateTimeDef(Copy(ARetorno[1],200,2)+'/'+
                                                                  Copy(ARetorno[1],202,2)+'/'+
                                                                  Copy(ARetorno[1],204,4),0, 'DD/MM/YY' );
   rCNPJCPF := trim( Copy(ARetorno[0],19,14)) ;

   if ACBrBanco.ACBrBoleto.Cedente.TipoInscricao = pJuridica then
    begin
      rCNPJCPF := trim( Copy(ARetorno[1],19,15));
      rCNPJCPF := RightStr(rCNPJCPF,14) ;
    end
   else
    begin
      rCNPJCPF := trim( Copy(ARetorno[1],23,11));
      rCNPJCPF := RightStr(rCNPJCPF,11) ;
    end;


   with ACBrBanco.ACBrBoleto do
   begin

      if (not LeCedenteRetorno) and (rCNPJCPF <> OnlyNumber(Cedente.CNPJCPF)) then
         raise Exception.Create(ACBrStr('CNPJ\CPF do arquivo inv�lido'));

      if (not LeCedenteRetorno) and ((rAgencia <> OnlyNumber(Cedente.Agencia)) or
          (rConta+rDigitoConta  <> OnlyNumber(Cedente.CodigoCedente))) then
         raise Exception.Create(ACBrStr('Agencia\Conta do arquivo inv�lido'));

      if LeCedenteRetorno then
      begin
         Cedente.Nome    := rCedente;
         Cedente.CNPJCPF := rCNPJCPF;
         Cedente.Agencia := rAgencia;
         Cedente.AgenciaDigito:= '0';
         Cedente.Conta   := rConta;
         Cedente.ContaDigito:= rDigitoConta;
         Cedente.CodigoCedente:= rConta+rDigitoConta;

         case StrToIntDef(Copy(ARetorno[1],18,1),0) of
            1: Cedente.TipoInscricao:= pFisica;
            2: Cedente.TipoInscricao:= pJuridica;
            else
               Cedente.TipoInscricao:= pJuridica;
         end;
      end;

      ACBrBanco.ACBrBoleto.ListadeBoletos.Clear;
   end;

   Linha := '';
   Titulo := nil;

   for ContLinha := 1 to ARetorno.Count - 2 do
   begin
      Linha := ARetorno[ContLinha] ;

      {Segmento T - S� cria ap�s passar pelo seguimento T depois U}
      if Copy(Linha,14,1)= 'T' then
         Titulo := ACBrBanco.ACBrBoleto.CriarTituloNaLista;

      if Assigned(Titulo) then
      with Titulo do
      begin
         {Segmento T}
         if Copy(Linha,14,1)= 'T' then
          begin
            SeuNumero                   := Trim(copy(Linha,106,25));
            NumeroDocumento             := copy(Linha,59,11);
            OcorrenciaOriginal.Tipo     := CodOcorrenciaToTipo(StrToIntDef(copy(Linha,16,2),0));

            //05 = Liquida��o Sem Registro
            Vencimento := StringToDateTimeDef( Copy(Linha,74,2)+'/'+
                                               Copy(Linha,76,2)+'/'+
                                               Copy(Linha,80,2),0, 'DD/MM/YY' );

            ValorDocumento       := StrToFloatDef(Copy(Linha,82,15),0)/100;
            ValorDespesaCobranca := StrToFloatDef(Copy(Linha,199,15),0)/100;
            NossoNumero          := Copy(Linha,42,15);  
            Carteira             := Copy(Linha,40,2);
            CodigoLiquidacao     := Copy(Linha,214,02);
            CodigoLiquidacaoDescricao := CodigoLiquidacao_Descricao( StrToIntDef(CodigoLiquidacao,0) );
            
            // prevenir quando o seunumero n�o vem informado no arquivo
            wSeuNumero := StringReplace(SeuNumero, '0','',[rfReplaceAll]);
            if (AnsiSameText(wSeuNumero, EmptyStr)) then
            begin
              SeuNumero := NossoNumero;
              NumeroDocumento := NossoNumero
            end;            
          
            MotivoLinha := 214;

            for I := 0 to 4 do
            begin
              CodMotivo := StrToIntDef(IfThen(Copy(Linha, MotivoLinha, 2) = '00', '00', Copy(Linha, MotivoLinha, 2)), 0);

              if CodMotivo <> 0 then
              begin
                MotivoRejeicaoComando.Add(IfThen(Copy(Linha, MotivoLinha, 2) = '00', '00', Copy(Linha, MotivoLinha, 2)));
                DescricaoMotivoRejeicaoComando.Add(CodMotivoRejeicaoToDescricao(OcorrenciaOriginal.Tipo, CodMotivo));
              end;

              MotivoLinha := MotivoLinha + 2; // Incrementa a coluna dos motivos.
            end;
            
            // informa��es do local de pagamento
            Liquidacao.Banco      := StrToIntDef(Copy(Linha,97,3), -1);
            Liquidacao.Agencia    := Copy(Linha,100,5);
            Liquidacao.Origem     := '';
            Liquidacao.FormaPagto := '';

            // quando a liquida��o ocorre nos canais da caixa o banco vem zero
            // ent�o acertar
            if Liquidacao.Banco = 0 then
              Liquidacao.Banco := 104;            
          end
         {Ssegmento U}
         else if Copy(Linha,14,1)= 'U' then
          begin

            if StrToIntDef(Copy(Linha,138,6),0) <> 0 then
               DataOcorrencia := StringToDateTimeDef( Copy(Linha,138,2)+'/'+
                                                      Copy(Linha,140,2)+'/'+
                                                      Copy(Linha,142,4),0, 'DD/MM/YYYY' );

            if StrToIntDef(Copy(Linha,146,6),0) <> 0 then
               DataCredito:= StringToDateTimeDef( Copy(Linha,146,2)+'/'+
                                                  Copy(Linha,148,2)+'/'+
                                                  Copy(Linha,150,4),0, 'DD/MM/YYYY' );

            ValorMoraJuros       := StrToFloatDef(Copy(Linha,18,15),0)/100;
            ValorDesconto        := StrToFloatDef(Copy(Linha,33,15),0)/100;
            ValorAbatimento      := StrToFloatDef(Copy(Linha,48,15),0)/100;
            ValorIOF             := StrToFloatDef(Copy(Linha,63,15),0)/100;
            ValorPago            := StrToFloatDef(Copy(Linha,78,15),0)/100;
            ValorRecebido        := StrToFloatDef(Copy(Linha,93,15),0)/100;
            ValorOutrasDespesas  := StrToFloatDef(Copy(Linha,108,15),0)/100;
            ValorOutrosCreditos  := StrToFloatDef(Copy(Linha,123,15),0)/100;
         end
        {Segmento W}
        else if Copy(Linha, 14, 1) = 'W' then
         begin
           //verifica o motivo de rejei��o
           MotivoRejeicaoComando.Add(copy(Linha,29,2));
           DescricaoMotivoRejeicaoComando.Add(CodMotivoRejeicaoToDescricao(
                                              CodOcorrenciaToTipo(
                                              StrToIntDef(copy(Linha, 16, 2), 0)),
                                              StrToInt(Copy(Linha, 29, 2))));
         end;
      end;
   end;

end;
function TACBrCaixaEconomica.CodOcorrenciaToTipo(
  const CodOcorrencia: Integer): TACBrTipoOcorrencia;
begin

  if (ACBrBanco.ACBrBoleto.LayoutRemessa = c240) then
  begin
    case CodOcorrencia of
      01: Result := toRetornoSolicitacaoImpressaoTituloConfirmada;
      02: Result := toRetornoRegistroConfirmado;
      03: Result := toRetornoRegistroRecusado;
      04: Result := toRetornoTransferenciaCarteiraEntrada;
      05: Result := toRetornoTransferenciaCarteiraBaixa;
      06: Result := toRetornoLiquidado;
      07: Result := toRetornoRecebimentoInstrucaoConcederDesconto;
      08: Result := toRetornoRecebimentoInstrucaoCancelarDesconto;
      09: Result := toRetornoBaixado;
      12: Result := toRetornoRecebimentoInstrucaoConcederAbatimento;
      13: Result := toRetornoRecebimentoInstrucaoCancelarAbatimento;
      14: Result := toRetornoRecebimentoInstrucaoAlterarVencimento;
      19: Result := toRetornoRecebimentoInstrucaoProtestar;
      20: Result := toRetornoRecebimentoInstrucaoSustarProtesto;
      25: Result := toRetornoBaixaPorProtesto;
      26: Result := toRetornoInstrucaoRejeitada;
      27: Result := toRetornoAlteracaoUsoCedente;
      28: Result := toRetornoDebitoTarifas;
      30: Result := toRetornoAlteracaoOutrosDadosRejeitada;
      35: Result := toRetornoConfirmacaoInclusaoBancoSacado;
      36: Result := toRetornoConfirmacaoAlteracaoBancoSacado;
      37: Result := toRetornoConfirmacaoExclusaoBancoSacado;
      38: Result := toRetornoEmissaoBloquetoBancoSacado;
      39: Result := toRetornoManutencaoSacadoRejeitada;
      40: Result := toRetornoEntradaTituloBancoSacadoRejeitada;
      41: Result := toRetornoManutencaoBancoSacadoRejeitada;
      44: Result := toRetornoBaixaOuLiquidacaoEstornada;
      45: Result := toRetornoRecebimentoInstrucaoAlterarDados;
    end;
  end
  else
  begin
    case CodOcorrencia of
      01: Result := toRetornoRegistroConfirmado;
      02: Result := toRetornoBaixaManualConfirmada;
      03: Result := toRetornoAbatimentoConcedido;
      04: Result := toRetornoAbatimentoCancelado;
      05: Result := toRetornoVencimentoAlterado;
      06: Result := toRetornoAlteracaoUsoCedente;
      07: Result := toRetornoPrazoProtestoAlterado;
      08: Result := toRetornoPrazoDevolucaoAlterado;
      09: Result := toRetornoDadosAlterados;
      10: Result := toRetornoAlteracaoReemissaoBloquetoConfirmada;
      11: Result := toRetornoAlteracaoOpcaoProtestoParaDevolucaoConfirmada;
      12: Result := toRetornoAlteracaoOpcaoDevolucaoParaProtestoConfirmada;
      20: Result := toRetornoTituloEmSer;
      21: Result := toRetornoLiquidado;
      22: Result := toRetornoLiquidadoEmCartorio;
      23: Result := toRetornoBaixadoPorDevolucao;
      25: Result := toRetornoBaixaPorProtesto;
      26: Result := toRetornoEncaminhadoACartorio;
      27: Result := toRetornoProtestoSustado;
      28: Result := toRetornoEstornoProtesto;
      29: Result := toRetornoProtestoOuSustacaoEstornado;
      30: Result := toRetornoRecebimentoInstrucaoAlterarDados;
      31: Result := toRetornoTarifaDeManutencaoDeTitulosVencidos;
      32: Result := toRetornoOutrasTarifasAlteracao;
      33: Result := toRetornoEstornoBaixaLiquidacao;
      34: Result := toRetornoDebitoTarifas;
      99: Result := toRetornoRegistroRecusado;
    end;
  end;
end;

function TACBrCaixaEconomica.CodMotivoRejeicaoToDescricao(const TipoOcorrencia: TACBrTipoOcorrencia; CodMotivo: Integer): string;
begin  
  case TipoOcorrencia of
    toRetornoRegistroConfirmado, toRetornoRegistroRecusado,
      toRetornoInstrucaoRejeitada, toRetornoALteracaoOutrosDadosRejeitada:
    case CodMotivo of
      01: Result := '01-C�digo do Banco Inv�lido';
      02: Result := '02-C�digo do Registro Inv�lido';
      03: Result := '03-C�digo do Segmento Inv�lido';
      04: Result := '04-C�digo do Movimento n�o Permitido p/ Carteira';
      05: Result := '05-C�digo do Movimento Inv�lido';
      06: Result := '06-Tipo N�mero Inscri��o Cedente Inv�lido';
      07: Result := '07-Agencia/Conta/DV Inv�lidos';
      08: Result := '08-Nosso N�mero Inv�lido';
      09: Result := '09-Nosso N�mero Duplicado';
      10: Result := '10-Carteira Inv�lida';
      11: Result := '11-Data de Gera��o Inv�lida';
      12: Result := '12-Tipo de Documento Inv�lido';
      13: Result := '13-Identif. Da Emiss�o do Bloqueto Inv�lida';
      14: Result := '14-Identif. Da Distribui��o do Bloqueto Inv�lida';
      15: Result := '15-Caracter�sticas Cobran�a Incompat�veis';
      16: Result := '16-Data de Vencimento Inv�lida';
      17: Result := '17-Data de Vencimento Anterior a Data de Emiss�o';
      18: Result := '18-Vencimento fora do prazo de opera��o';
      19: Result := '19-T�tulo a Cargo de Bco Correspondentes c/ Vencto Inferior a XX Dias';
      20: Result := '20-Valor do T�tulo Inv�lido';
      21: Result := '21-Esp�cie do T�tulo Inv�lida';
      22: Result := '22-Esp�cie do T�tulo N�o Permitida para a Carteira';
      23: Result := '23-Aceite Inv�lido';
      24: Result := '24-Data da Emiss�o Inv�lida';
      25: Result := '25-Data da Emiss�o Posterior a Data de Entrada';
      26: Result := '26-C�digo de Juros de Mora Inv�lido';
      27: Result := '27-Valor/Taxa de Juros de Mora Inv�lido';
      28: Result := '28-C�digo do Desconto Inv�lido';
      29: Result := '29-Valor do Desconto Maior ou Igual ao Valor do T�tulo';
      30: Result := '30-Desconto a Conceder N�o Confere';
      31: Result := '31-Concess�o de Desconto - J� Existe Desconto Anterior';
      32: Result := '32-Valor do IOF Inv�lido';
      33: Result := '33-Valor do Abatimento Inv�lido';
      34: Result := '34-Valor do Abatimento Maior ou Igual ao Valor do T�tulo';
      35: Result := '35-Valor Abatimento a Conceder N�o Confere';
      36: Result := '36-Concess�o de Abatimento - J� Existe Abatimento Anterior';
      37: Result := '37-C�digo para Protesto Inv�lido';
      38: Result := '38-Prazo para Protesto Inv�lido';
      39: Result := '39-Pedido de Protesto N�o Permitido para o T�tulo';
      40: Result := '40-T�tulo com Ordem de Protesto Emitida';
      41: Result := '41-Pedido Cancelamento/Susta��o p/ T�tulos sem Instru��o Protesto';
      42: Result := '42-C�digo para Baixa/Devolu��o Inv�lido';
      43: Result := '43-Prazo para Baixa/Devolu��o Inv�lido';
      44: Result := '44-C�digo da Moeda Inv�lido';
      45: Result := '45-Nome do Sacado N�o Informado';
      46: Result := '46-Tipo/N�mero de Inscri��o do Sacado Inv�lidos';
      47: Result := '47-Endere�o do Sacado N�o Informado';
      48: Result := '48-CEP Inv�lido';
      49: Result := '49-CEP Sem Pra�a de Cobran�a (N�o Localizado)';
      50: Result := '50-CEP Referente a um Banco Correspondente';
      51: Result := '51-CEP incompat�vel com a Unidade da Federa��o';
      52: Result := '52-Unidade da Federa��o Inv�lida';
      53: Result := '53-Tipo/N�mero de Inscri��o do Sacador/Avalista Inv�lidos';
      54: Result := '54-Sacador/Avalista N�o Informado';
      55: Result := '55-Nosso n�mero no Banco Correspondente N�o Informado';
      56: Result := '56-C�digo do Banco Correspondente N�o Informado';
      57: Result := '57-C�digo da Multa Inv�lido';
      58: Result := '58-Data da Multa Inv�lida';
      59: Result := '59-Valor/Percentual da Multa Inv�lido';
      60: Result := '60-Movimento para T�tulo N�o Cadastrado. Erro gen�rico para as situa��es:' + #13#10
                      + '"Cedente n�o cadastrado" ou' + #13#10
                      + '"Ag�ncia Cedente n�o cadastrada ou desativada"';
      61: Result := '61-Altera��o da Ag�ncia Cobradora/DV Inv�lida';
      62: Result := '62-Tipo de Impress�o Inv�lido';
      63: Result := '63-Entrada para T�tulo j� Cadastrado';
      64: Result := '64-Entrada Inv�lida para Cobran�a Caucionada';
      65: Result := '65-CEP do Sacado n�o encontrado';
      66: Result := '66-Agencia Cobradora n�o encontrada';
      67: Result := '67-Agencia Cedente n�o encontrada';
      68: Result := '68-Movimenta��o inv�lida para t�tulo';
      69: Result := '69-Altera��o de dados inv�lida';
      70: Result := '70-Apelido do cliente n�o cadastrado';
      71: Result := '71-Erro na composi��o do arquivo';
      72: Result := '72-Lote de servi�o inv�lido';
      73: Result := '73-C�digo do Cedente inv�lido';
      74: Result := '74-Cedente n�o pertencente a Cobran�a Eletr�nica';
      75: Result := '75-Nome da Empresa inv�lido';
      76: Result := '76-Nome do Banco inv�lido';
      77: Result := '77-C�digo da Remessa inv�lido';
      78: Result := '78-Data/Hora Gera��o do arquivo inv�lida';
      79: Result := '79-N�mero Sequencial do arquivo inv�lido';
      80: Result := '80-Vers�o do Lay out do arquivo inv�lido';
      81: Result := '81-Literal REMESSA-TESTE - V�lido s� p/ fase testes';
      82: Result := '82-Literal REMESSA-TESTE - Obrigat�rio p/ fase testes';
      83: Result := '83-Tp N�mero Inscri��o Empresa inv�lido';
      84: Result := '84-Tipo de Opera��o inv�lido';
      85: Result := '85-Tipo de servi�o inv�lido';
      86: Result := '86-Forma de lan�amento inv�lido';
      87: Result := '87-N�mero da remessa inv�lido';
      88: Result := '88-N�mero da remessa menor/igual remessa anterior';
      89: Result := '89-Lote de servi�o divergente';
      90: Result := '90-N�mero sequencial do registro inv�lido';
      91: Result := '91-Erro seq de segmento do registro detalhe';
      92: Result := '92-Cod movto divergente entre grupo de segm';
      93: Result := '93-Qtde registros no lote inv�lido';
      94: Result := '94-Qtde registros no lote divergente';
      95: Result := '95-Qtde lotes no arquivo inv�lido';
      96: Result := '96-Qtde lotes no arquivo divergente';
      97: Result := '97-Qtde registros no arquivo inv�lido';
      98: Result := '98-Qtde registros no arquivo divergente';
      99: Result := '99-C�digo de DDD inv�lido';
    else
      Result := IntToStrZero(CodMotivo, 2) + ' - Outros Motivos';
    end;

    toRetornoDebitoTarifas:
    case CodMotivo of
      01: Result := '01-Tarifa de Extrato de Posi��o';
      02: Result := '02-Tarifa de Manuten��o de T�tulo Vencido';
      03: Result := '03-Tarifa de Susta��o';
      04: Result := '04-Tarifa de Protesto';
      05: Result := '05-Tarifa de Outras Instru��es';
      06: Result := '06-Tarifa de Outras Ocorr�ncias';
      07: Result := '07-Tarifa de Envio de Duplicata ao Sacado';
      08: Result := '08-Custas de Protesto';
      09: Result := '09-Custas de Susta��o de Protesto';
      10: Result := '10-Custas de Cart�rio Distribuidor';
      11: Result := '11-Custas de Edital';
      12: Result := '12-Redisponibiliza��o de Arquivo Retorno Eletr�nico';
      13: Result := '13-Tarifa Sobre Registro Cobrada na Baixa/Liquida��o';
      14: Result := '14-Tarifa Sobre Reapresenta��o Autom�tica';
      15: Result := '15-Banco de Sacados';
      16: Result := '16-Tarifa Sobre Informa��es Via Fax';
      17: Result := '17-Entrega Aviso Disp Bloqueto via e-amail ao sacado (s/ emiss�o Bloqueto)';
      18: Result := '18-Emiss�o de Bloqueto Pr�-impresso CAIXA matricial';
      19: Result := '19-Emiss�o de Bloqueto Pr�-impresso CAIXA A4';
      20: Result := '20-Emiss�o de Bloqueto Padr�o CAIXA';
      21: Result := '21-Emiss�o de Bloqueto/Carn�';
      31: Result := '31-Emiss�o de Aviso de Vencido';
      42: Result := '42-Altera��o cadastral de dados do t�tulo - sem emiss�o de aviso';
      45: Result := '45-Emiss�o de 2� via de Bloqueto Cobran�a Registrada';
    else
      Result := IntToStrZero(CodMotivo, 2) + ' - Outros Motivos';
    end;

    toRetornoLiquidado, toRetornoBaixado:
    case CodMotivo of
      02: Result := '02-Casa Lot�rica';
      03: Result := '03-Ag�ncias CAIXA';
      04: Result := '04-Compensa��o Eletr�nica';
      05: Result := '05-Compensa��o Convencional';
      06: Result := '06-Internet Banking';
      07: Result := '07-Correspondente Banc�rio';
      08: Result := '08-Em Cart�rio';
      09: Result := '09-Comandada Banco';
      10: Result := '10-Comandada Cliente via Arquivo';
      11: Result := '11-Comandada Cliente On-line';
      12: Result := '12-Decurso Prazo - Cliente';
      13: Result := '13-Decurso Prazo - Banco';
      14: Result := '14-Protestado';
    else
      Result := IntToStrZero(CodMotivo, 2) + ' - Outros Motivos';
    end;
  end;  
end;

function TACBrCaixaEconomica.TipoOcorrenciaToDescricao(const TipoOcorrencia: TACBrTipoOcorrencia): String;
var
  CodOcorrencia: Integer;
begin
  CodOcorrencia := StrToIntDef(TipoOCorrenciaToCod(TipoOcorrencia),0);

  if (ACBrBanco.ACBrBoleto.LayoutRemessa = c240) then
  begin
    case CodOcorrencia of
      01: Result := '01-Solicita��o de Impress�o de T�tulos Confirmada';
      02: Result := '02-Entrada Confirmada';
      03: Result := '03-Entrada Rejeitada';
      04: Result := '04-Transfer�ncia de Carteira/Entrada';
      05: Result := '05-Transfer�ncia de Carteira/Baixa';
      06: Result := '06-Liquida��o';
      07: Result := '07-Confirma��o do Recebimento da Instru��o de Desconto';
      08: Result := '08-Confirma��o do Recebimento do Cancelamento do Desconto';
      09: Result := '09-Baixa';
      12: Result := '12-Confirma��o Recebimento Instru��o de Abatimento';
      13: Result := '13-Confirma��o Recebimento Instru��o de Cancelamento Abatimento';
      14: Result := '14-Confirma��o Recebimento Instru��o Altera��o de Vencimento';
      19: Result := '19-Confirma��o Recebimento Instru��o de Protesto';
      20: Result := '20-Confirma��o Recebimento Instru��o de Susta��o/Cancelamento de Protesto';
      26: Result := '26-Instru��o Rejeitada';
      27: Result := '27-Confirma��o do Pedido de Altera��o de Outros Dados';
      28: Result := '28-D�bito de Tarifas/Custas';
      30: Result := '30-Altera��o de Dados Rejeitada';
      35: Result := '35-Confirma��o de Inclus�o Banco de Sacado';
      36: Result := '36-Confirma��o de Altera��o Banco de Sacado';
      37: Result := '37-Confirma��o de Exclus�o Banco de Sacado';
      38: Result := '38-Emiss�o de Bloquetos de Banco de Sacado';
      39: Result := '39-Manuten��o de Sacado Rejeitada';
      40: Result := '40-Entrada de T�tulo via Banco de Sacado Rejeitada';
      41: Result := '41-Manuten��o de Banco de Sacado Rejeitada';
      44: Result := '44-Estorno de Baixa / Liquida��o';
      45: Result := '45-Altera��o de Dados';
    end;
  end
  else
  begin
    case CodOcorrencia of
      01: Result := '01-Entrada Confirmada';
      02: Result := '02-Baixa Manual Confirmada';
      03: Result := '03-Abatimento Concedido';
      04: Result := '04-Abatimento Cancelado';
      05: Result := '05-Vencimento Alterado';
      06: Result := '06-Uso da Empresa Alterado';
      07: Result := '07-Prazo de Protesto Alterado';
      08: Result := '08-Prazo de Devolu��o Alterado';
      09: Result := '09-Altera��o Confirmada';
      10: Result := '10-Altera��o com Reemiss�o de Bloqueto Confirmada';
      11: Result := '11-Altera��o da Op��o de Protesto para Devolu��o Confirmada';
      12: Result := '12-Altera��o da Op��o de Devolu��o para Protesto Confirmada';
      20: Result := '20-Em Ser';
      21: Result := '21-Liquida��o';
      22: Result := '22-Liquida��o em Cart�rio';
      23: Result := '23-Baixa por Devolu��o';
      25: Result := '25-Baixa por Protesto';
      26: Result := '26-T�tulo Enviado para Cart�rio';
      27: Result := '27-Susta��o de Protesto';
      28: Result := '28-Estorno de Protesto';
      29: Result := '29-Estorno de Susta��o de Protesto';
      30: Result := '30-Altera��o de T�tulo';
      31: Result := '31-Tarifa sobre T�tulo Vencido';
      32: Result := '32-Outras Tarifas de Altera��o';
      33: Result := '33-Estorno de Baixa / Liquida��o';
      34: Result := '34-Tarifas Diversas';
      99: Result := '99-Rejei��o do T�tulo';
    end;
  end;
end;

function TACBrCaixaEconomica.CodigoLiquidacao_Descricao(CodLiquidacao: Integer): String;
begin
  case CodLiquidacao of
    02 : result := 'Casa Lot�rica';
    03 : result := 'Ag�ncias CAIXA';
    04 : result := 'Compensa��o Eletr�nica';
    05 : result := 'Compensa��o Convencional';
    06 : result := 'Internet Banking';
    07 : result := 'Correspondente Banc�rio';
    08 : result := 'Em Cart�rio'
  end;
end;

procedure TACBrCaixaEconomica.LerRetorno400(ARetorno: TStringList);
var
  Titulo : TACBrTitulo;
  ContLinha : Integer;
  rAgencia, rConta, Linha, rCedente :String;
begin
   fpTamanhoMaximoNossoNum := 15;
 
   if StrToIntDef(copy(ARetorno.Strings[0],77,3),-1) <> Numero then
      raise Exception.Create(ACBrStr(ACBrBanco.ACBrBoleto.NomeArqRetorno +
                             'n�o � um arquivo de retorno do '+ Nome));

   rCedente := trim(Copy(ARetorno[0],47,30));
   rAgencia := Copy(ARetorno[0],27,4);
   rConta   := Copy(ARetorno[0],34,8);


   ACBrBanco.ACBrBoleto.NumeroArquivo := StrToIntDef(Copy(ARetorno[0],390,5),0);

   ACBrBanco.ACBrBoleto.DataArquivo   := StringToDateTimeDef(Copy(ARetorno[0],95,2)+'/'+
                                                             Copy(ARetorno[0],97,2)+'/'+
                                                             Copy(ARetorno[0],99,2),0, 'DD/MM/YY' );

   with ACBrBanco.ACBrBoleto do
   begin
      if (not LeCedenteRetorno) and
         ((rAgencia <> OnlyNumber(Cedente.Agencia)) or
          (rConta <> OnlyNumber(Cedente.Conta))) then
         raise Exception.Create(ACBrStr('Agencia\Conta do arquivo inv�lido'));

      if LeCedenteRetorno then
      begin
        Cedente.Nome         := rCedente;
        Cedente.Agencia      := rAgencia;
        Cedente.Conta        := rConta;
      end;

      ACBrBanco.ACBrBoleto.ListadeBoletos.Clear;
   end;

   ACBrBanco.TamanhoMaximoNossoNum := 15;

   for ContLinha := 1 to ARetorno.Count - 2 do
   begin
     Linha := ARetorno[ContLinha] ;

     if (Copy(Linha,1,1) <> '7') and (Copy(Linha,1,1) <> '1') then
       Continue;

     Titulo := ACBrBanco.ACBrBoleto.CriarTituloNaLista;

     with Titulo do
     begin
       SeuNumero                   := copy(Linha,59,15);
       NumeroDocumento             := copy(Linha,117,10);
       OcorrenciaOriginal.Tipo     := CodOcorrenciaToTipo(StrToIntDef(
                                        copy(Linha,109,2),0));
       DataOcorrencia := StringToDateTimeDef( Copy(Linha,111,2)+'/'+
                                              Copy(Linha,113,2)+'/'+
                                              Copy(Linha,115,2),0, 'DD/MM/YY' );

       Vencimento := StringToDateTimeDef( Copy(Linha,147,2)+'/'+
                                          Copy(Linha,149,2)+'/'+
                                          Copy(Linha,151,2),0, 'DD/MM/YY' );

       ValorDocumento       := StrToFloatDef(Copy(Linha,153,13),0)/100;
       ValorIOF             := StrToFloatDef(Copy(Linha,215,13),0)/100;
       ValorAbatimento      := StrToFloatDef(Copy(Linha,228,13),0)/100;
       ValorDesconto        := StrToFloatDef(Copy(Linha,241,13),0)/100;
       ValorRecebido        := StrToFloatDef(Copy(Linha,254,13),0)/100;
       ValorMoraJuros       := StrToFloatDef(Copy(Linha,267,13),0)/100;
       ValorOutrosCreditos  := StrToFloatDef(Copy(Linha,280,13),0)/100;
       Carteira             := Copy(Linha,57,2);
       NossoNumero          := Copy(Linha,59,15);
       ValorDespesaCobranca := StrToFloatDef(Copy(Linha,176,13),0)/100; //--Anderson: Valor tarifa

       DataCredito:= StringToDateTimeDef( Copy(Linha,294,2)+'/'+
                                          Copy(Linha,296,2)+'/'+
                                          Copy(Linha,298,2),0, 'DD/MM/YY' );

       if StrToIntDef(SeuNumero,0) = 0 then
       begin
         SeuNumero := NossoNumero;
         NumeroDocumento := NossoNumero
       end;
     end;
   end;

   fpTamanhoMaximoNossoNum := 15;
end;

end.
