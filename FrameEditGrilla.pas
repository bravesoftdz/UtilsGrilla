{Implementa un frame con una grilla para la edición de tablas}
unit FrameEditGrilla;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, ActnList, Menus, Grids, LCLType,
  Graphics, LCLProc, CibUtils, UtilsGrilla, BasicGrilla, MisUtils;
type
  //Tipos de modificaciones
  TugTipModif = (
    umdFilAgre,  //Fila agregada
    umdFilModif,  //Fila modificada
    umdFilElim,   //Fila eliminada
    umdFilMovid   //Fila movida
  );
  TEvReqNuevoReg = procedure(fil: integer) of object;
  TEvGrillaModif = procedure(TipModif: TugTipModif) of object;

  { TfraEditGrilla }
  TfraEditGrilla = class(TFrame)
    acEdiCopCel: TAction;
    acEdiCopFil: TAction;
    acEdiElimin: TAction;
    acEdiNuevo: TAction;
    acEdiPegar: TAction;
    acEdiSubir: TAction;
    acEdiBajar: TAction;
    ActionList1: TActionList;
    grilla: TStringGrid;
    ImageList1: TImageList;
    MenuItem1: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure acEdiBajarExecute(Sender: TObject);
    procedure acEdiCopCelExecute(Sender: TObject);
    procedure acEdiCopFilExecute(Sender: TObject);
    procedure acEdiEliminExecute(Sender: TObject);
    procedure acEdiNuevoExecute(Sender: TObject);
    procedure acEdiPegarExecute(Sender: TObject);
    procedure acEdiSubirExecute(Sender: TObject);
  private
    function griLeerColorFondo(col, fil: integer): TColor;
    procedure gri_FinEditarCelda(var eveSal: TEvSalida; col, fil: integer;
      ValorAnter, ValorNuev: string);
    procedure gri_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gri_MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
    gri: TGrillaEdicFor;
    Modificado  : boolean;
    OnLeerColorFondo: TEvLeerColorFondo;
    OnReqNuevoReg   : TEvReqNuevoReg;
    OnGrillaModif   : TEvGrillaModif;
    MsjError: string;
    procedure ValidarGrilla;
    function BuscAgreEncabNum(titulo: string; ancho: integer): TugGrillaCol;
    procedure SetFocus; override;
  public  //Funciones espejo
    procedure IniEncab;
    function AgrEncabTxt(titulo: string; ancho: integer; indColDat: int16=-1
      ): TugGrillaCol;
    function AgrEncabChr(titulo: string; ancho: integer; indColDat: int16=-1
      ): TugGrillaCol;
    function AgrEncabNum(titulo: string; ancho: integer; indColDat: int16=-1
      ): TugGrillaCol;
    function AgrEncabBool(titulo: string; ancho: integer; indColDat: int16=-1
      ): TugGrillaCol;
    function AgrEncabDatTim(titulo: string; ancho: integer; indColDat: int16=-1
      ): TugGrillaCol;
    procedure FinEncab(actualizarGrilla: boolean=true);
    function RowCount: integer;
    procedure LimpiarFiltros;
    function AgregarFiltro(proc: TUtilProcFiltro): integer;
    procedure Filtrar;
    function FilVisibles: integer;
  public  //Constructor y destructor.
    constructor Create(AOwner: TComponent) ; override;
    destructor Destroy; override;
  end;

implementation
{$R *.lfm}

{ TfraEditGrilla }
//Funciones espejo
procedure TfraEditGrilla.IniEncab;
begin
  gri.IniEncab;
end;
function TfraEditGrilla.AgrEncabTxt(titulo: string; ancho: integer;
  indColDat: int16): TugGrillaCol;
begin
  Result := gri.AgrEncabTxt(titulo, ancho, indColDat);
end;
function TfraEditGrilla.AgrEncabChr(titulo: string; ancho: integer;
  indColDat: int16): TugGrillaCol;
begin
  Result := gri.AgrEncabChr(titulo, ancho, indColDat);
end;
function TfraEditGrilla.AgrEncabNum(titulo: string; ancho: integer;
  indColDat: int16): TugGrillaCol;
begin
  Result := gri.AgrEncabNum(titulo, ancho, indColDat);
end;
function TfraEditGrilla.AgrEncabBool(titulo: string; ancho: integer;
  indColDat: int16): TugGrillaCol;
begin
  Result := gri.AgrEncabBool(titulo, ancho, indColDat);
end;
function TfraEditGrilla.AgrEncabDatTim(titulo: string; ancho: integer;
  indColDat: int16): TugGrillaCol;
begin
  Result := gri.AgrEncabDatTim(titulo, ancho, indColDat);
end;
procedure TfraEditGrilla.FinEncab(actualizarGrilla: boolean);
begin
  gri.FinEncab(actualizarGrilla);
end;
function TfraEditGrilla.RowCount: integer;
begin
  Result := grilla.RowCount;
end;
procedure TfraEditGrilla.LimpiarFiltros;
begin
  gri.LimpiarFiltros;
end;
function TfraEditGrilla.AgregarFiltro(proc: TUtilProcFiltro): integer;
begin
  gri.AgregarFiltro(proc);
end;
procedure TfraEditGrilla.Filtrar;
begin
  gri.Filtrar;
end;
function TfraEditGrilla.FilVisibles: integer;
begin
  Result := gri.filVisibles;
end;
//Manejo de eventos
procedure TfraEditGrilla.gri_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Longint;
begin
  if Button = mbRight then begin
    grilla.MouseToCell(X, Y, ACol, ARow );
    if ARow<1 then exit;   //protección
    if ACol = 0 then begin
      //Columna fija
      PopupMenu1.PopUp;
    end else begin
      PopupMenu1.PopUp;
    end;
  end;
end;
procedure TfraEditGrilla.ValidarGrilla;
{Valida el contenido de las celdas de las grilla. Si encuentra error, muestra el mensaje
y devuelve el mensaje en "MsjError".}
var
  f: Integer;
begin
  MsjError := '';
  for f:=1 to grilla.RowCount-1 do begin
    gri.ValidaFilaGrilla(f);
    if gri.MsjError<>'' then begin
      //Hubo error
      MsjError := gri.MsjError;  //copia mensaje
      MsgExc(MsjError);
      //Selecciona la celda
      grilla.Row:=f;  //fila del error
      grilla.Col:=gri.colError;  //columna del error
      exit;
    end;
  end;
end;
function TfraEditGrilla.BuscAgreEncabNum(titulo: string; ancho: integer): TugGrillaCol;
{Busca o agrega una columna, a la grilla, sin modificar los datos ya ingresados.}
begin
  //Asegura que exista la columna
  Result := gri.BuscarColumna(titulo);
  if Result = nil then begin
    Result := gri.AgrEncabNum(titulo, ancho);
  end;
  grilla.ColCount:=gri.cols.Count;   //Hace espacio
  gri.DimensColumnas;   //actualiza anchos
end;
procedure TfraEditGrilla.SetFocus;
//Manejamos nuestra propia versión se SetFocus
begin
//  inherited SetFocus;
  if not Visible then exit;
  if not grilla.Visible then exit;
  try
    grilla.SetFocus;
  except
  end;
end;
procedure TfraEditGrilla.gri_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
{COnfigura los accesos de teclado de la grilla. Se configuran aquí, y no con atajos de las
acciones, porque se quiere qie estos accesos solo funciones cuando la grilal tiene
el enfoque.}
var
  filAct: Integer;
begin
  if Key = VK_APPS then begin  //Menú contextual
    PopupMenu1.PopUp;
  end;
  if (Shift = [ssCtrl]) and (Key = VK_C) then begin
    acEdiCopCelExecute(self);
  end;
  if (Shift = [ssCtrl]) and (Key = VK_INSERT) then begin
    acEdiCopCelExecute(self);
  end;
  if (Shift = [ssCtrl]) and (Key = VK_V) then begin
    acEdiPegarExecute(self);
  end;
  if (Shift = [ssShift]) and (Key = VK_INSERT) then begin
    acEdiPegarExecute(self);
  end;
  if (Shift = [ssCtrl]) and (Key = VK_J) then begin
    filAct := grilla.Row;  //guarda fila actual
    RetrocederAFilaVis(grilla);    //sube a fila anterior
    gri.CopiarCampo;
    grilla.Row := filAct;  //retorna fila
    gri.PegarACampo;
  end;
  if (Shift = [ssAlt]) and (Key = VK_UP) then begin
    acEdiSubirExecute(self);
    Key := 0;  //para que no desplaze
  end;
  if (Shift = [ssAlt]) and (Key = VK_DOWN) then begin
    acEdiBajarExecute(self);
    Key := 0;  //para que no desplaze
  end;
end;
procedure TfraEditGrilla.gri_FinEditarCelda(var eveSal: TEvSalida; col,
  fil: integer; ValorAnter, ValorNuev: string);
{Termina la edición de una celda. Validamos, la celda.}
begin
  if eveSal in [evsTecEnter, evsTecTab, evsTecDer, evsEnfoque] then begin
    //Puede haber cambio
//    if ValorAnter = ValorNuev then exit;  //no es cambio
    gri.MsjError := '';
    gri.cols[col].ValidateStr(fil, ValorNuev);
    if gri.MsjError<>'' then begin
      //Hay rutina de validación
      MsgExc(gri.MsjError);
      eveSal := evsNulo;
    end;
  end;
end;
function TfraEditGrilla.griLeerColorFondo(col, fil: integer): TColor;
begin
  if OnLeerColorFondo<>nil then Result := OnLeerColorFondo(col, fil)
  else Result := clWhite;
end;

constructor TfraEditGrilla.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  gri := TGrillaEdicFor.Create(grilla);
  //Configura opciones en la grilla
  gri.MenuCampos:=true;
  gri.OpResaltFilaSelec:=true;
  gri.OpDimensColumnas:=true;
  gri.OpEncabezPulsable:=true;
  gri.OpResaltarEncabez:=true;
  //Configura eventos
  gri.OnMouseUp       := @gri_MouseUp;
  gri.OnKeyDown       := @gri_KeyDown;
  gri.OnFinEditarCelda:= @gri_FinEditarCelda;
  gri.OnLeerColorFondo:= @griLeerColorFondo;
end;
destructor TfraEditGrilla.Destroy;
begin
  gri.Destroy;
  inherited Destroy;
end;
///////////////////////// Acciones ////////////////////////////////
//Acciones de edición
procedure TfraEditGrilla.acEdiCopCelExecute(Sender: TObject);
begin
  gri.CopiarCampo;
end;
procedure TfraEditGrilla.acEdiSubirExecute(Sender: TObject);
var
  filAnt, filAct: Integer;
begin
  filAnt := FilaVisAnterior(grilla);
  if filAnt = -1 then exit;
  filAct := grilla.Row;
  grilla.ExchangeColRow(false, filAnt, filAct);
  grilla.Row := filAnt;
  //Actualiza
  gri.NumerarFilas;
  Modificado := true;
  if OnGrillaModif<>nil then OnGrillaModif(umdFilMovid);
end;
procedure TfraEditGrilla.acEdiBajarExecute(Sender: TObject);
var
  filSig, filAct: Integer;
begin
  filSig := FilaVisSiguiente(grilla);
  if filSig = -1 then exit;
  filAct := grilla.Row;
  grilla.ExchangeColRow(false, filSig, filAct);
  grilla.Row := filSig;
  //Actualiza
  gri.NumerarFilas;
  Modificado := true;
  if OnGrillaModif<>nil then OnGrillaModif(umdFilMovid);
end;
procedure TfraEditGrilla.acEdiCopFilExecute(Sender: TObject);
begin
  gri.CopiarFila;
end;
procedure TfraEditGrilla.acEdiPegarExecute(Sender: TObject);
begin
  gri.PegarACampo;
  //Habría que ver. si en realida lo modifica
  if OnGrillaModif<>nil then OnGrillaModif(umdFilModif);
end;
procedure TfraEditGrilla.acEdiNuevoExecute(Sender: TObject);
var
  f: Integer;
begin
  if grilla.Row = 0 then begin
    grilla.InsertColRow(false, 1);
    f := 1;  //fila insertada
  end else begin
    grilla.InsertColRow(false, grilla.Row);
    f := grilla.Row - 1;  //fila insertada
  end;
  //Llena los campos por defecto.
  if OnReqNuevoReg<>nil then OnReqNuevoReg(f);
//  colCodigo.ValStr[f] := '##'+IntToStr(grilla.RowCount);
//  colPreUni.ValNum[f] := 0;
//  colStock.ValNum[f] := 0;
//  colPreCos.ValNum[f] := 0;
//  colFecCre.ValDatTim[f] := now;
//  colFecMod.ValDatTim[f] := now;
  //Ubica fila seleccionada
  grilla.Row := f;
  //Actualiza
  gri.NumerarFilas;
  Modificado := true;
  if OnGrillaModif<>nil then OnGrillaModif(umdFilAgre);
end;
procedure TfraEditGrilla.acEdiEliminExecute(Sender: TObject);
{Elimina el registro seleccionado.}
var
  tmp: String;
begin
  if grilla.Row<1 then exit;;
//  tmp := colDescri.ValStr[grilla.Row];
  tmp := grilla.Cells[0, grilla.Row];
  if MsgYesNo('¿Eliminar registro: ' + tmp + '?') <> 1 then exit ;
  //Se debe eliminar el registro seleccionado
  grilla.DeleteRow(grilla.Row);
  //Actualiza
  gri.NumerarFilas;
  Modificado := true;
  if OnGrillaModif<>nil then OnGrillaModif(umdFilElim);
end;
end.

