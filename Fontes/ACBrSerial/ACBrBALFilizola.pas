{******************************************************************************}
{ Projeto: Componentes ACBr                                                    }
{  Biblioteca multiplataforma de componentes Delphi para intera��o com equipa- }
{ mentos de Automa��o Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2004 Fabio Farias                           }
{                                       Daniel Simoes de Almeida               }
{                                                                              }
{ Colaboradores nesse arquivo:                                                 }
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

{******************************************************************************
|* Historico
|*
|* 04/10/2005: Fabio Farias  / Daniel Sim�es de Almeida
|*  - Primeira Versao ACBrBALFilizola
|* 25/05/2005: Daniel Simoes de Almeida
|*  - Adaptado para funcionar com v�rios modelos de Filizola (MF, BP) permitindo
|*    varia��o na posi��o do ponto flutante
|* 16/02/2007: Juliano Pereira dos Santos
|*  - Adaptado para funcionar com modelo "CS"
|*
|* 11/10/2016 - Elias C�sar Vieira
|*  - Refatora��o de ACBrBALFilizola
******************************************************************************}

{$I ACBr.inc}

unit ACBrBALFilizola;

interface

uses
  ACBrBALClass, Classes;

type

  { TACBrBALFilizola }

  TACBrBALFilizola = class(TACBrBALClass)
  public
    constructor Create(AOwner: TComponent);

    function LePeso(MillisecTimeOut: Integer = 3000): Double; override;

    function InterpretarRepostaPeso(aResposta: AnsiString): Double; override;
  end;

implementation

uses
  ACBrConsts, SysUtils,
  {$IFDEF COMPILER6_UP}
    DateUtils
  {$ELSE}
    ACBrD5, Windows
  {$ENDIF};

{ TACBrBALGertecSerial }

constructor TACBrBALFilizola.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fpModeloStr := 'Filizola';
end;

function TACBrBALFilizola.LePeso(MillisecTimeOut: Integer): Double;
begin
  { A Filizola pode responder com Instavel inicalmente, mas depois ela poderia
    estabilizar... Portanto utilizar� a fun��o AguardarRespostaPeso }
  Result := AguardarRespostaPeso(MillisecTimeOut, True);
end;

function TACBrBALFilizola.InterpretarRepostaPeso(aResposta: AnsiString): Double;
var
  wResposta: AnsiString;
begin
  Result := 0;

  { Retira STX, ETX }
  wResposta := aResposta;
  if (Copy(wResposta, 1, 1) = STX) then
    wResposta := Copy(wResposta, 2, Length(wResposta));

  if (Copy(wResposta, Length(wResposta), 1) = ETX) then
    wResposta := Copy(wResposta, 1, Length(wResposta) - 1);

  if (wResposta = EmptyStr) then
    Exit;

  { Ajustando o separador de Decimal corretamente }
  wResposta := StringReplace(wResposta, '.', DecimalSeparator, [rfReplaceAll]);
  wResposta := StringReplace(wResposta, ',', DecimalSeparator, [rfReplaceAll]);

  try
    if (Length(wResposta) > 10) then
      Result := (StrToFloat(Copy(wResposta, 1, 6)) / 1000)
    else if (Pos(DecimalSeparator, wResposta) > 0) then
      Result := StrToFloat(wResposta)
    else
      Result := (StrToInt(wResposta) / 1000)
  except
    case Trim(wResposta)[1] of
      'I': Result := -1;   { Instavel }
      'N': Result := -2;   { Peso Negativo }
      'S': Result := -10;  { Sobrecarga de Peso }
    else
      Result := 0;
    end;
  end;
end;

end.
