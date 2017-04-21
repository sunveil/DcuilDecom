unit GUI;

interface

uses
  SysUtils, Forms, Dialogs, StdCtrls, Classes, Controls, ComCtrls,  WinTypes, WinProcs, Messages,
  DCU32,
  DCUTbl,
  DCU_In,
  DCU_Out,
  FixUp,
  DCURecs,
  DasmDefs,
  DasmCF,
  DCP,
  DasmX86,
  DasmMSIL,
  ExtCtrls,
  Expr,
  SemX86,
  SemExpr,
  X86Ref,
  op,
  DCU_MemOut,
  Menus,
  CILOpcodes,
  CILOpCodeTable,
  CILOpCode,
  CILOpCodeInfo,
  DCU32CILDecom,
  DCU32Decom,
  DecomUtils ;

type
  TDCU2INT = class(TForm)
    REDCUDump: TRichEdit;
    ProcFile: TOpenDialog;
    Panel2: TPanel;
    SaveDlg: TSaveDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    ProcessFile1: TMenuItem;
    Exit1: TMenuItem;
    Config1: TMenuItem;
    Options1: TMenuItem;
    Saveasrtf1: TMenuItem;
    Panel1: TPanel;
    ChkDasmMode: TComboBox;
    ChkDisAsm: TComboBox;
    GroupBox: TGroupBox;
    TVProc: TTreeView;
    Splitter1: TSplitter;
    GML: TComboBox;
    procedure PrcessFileClick(Sender: TObject);
    procedure ProcessFile1Click(Sender: TObject);
    procedure Saveasrtf1Click(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure ChkDasmModeChange(Sender: TObject);
    procedure ChkDisAsmChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GMLChange(Sender: TObject);
    procedure TVProcClick(Sender: TObject);
    procedure TVProcDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function SearchForText_AndSelect(RichEdit: TRichEdit; SearchText: string): Boolean;
  end;

var
  DCU2INT: TDCU2INT;

implementation

uses DCUOption;

var
  DCUName: String = '';
  FNRes: String = '';
  Mem : TMemoryStream;

function ProcessParms(sOPTIONS : String): boolean;
var
  i,j: integer;
  Ch: Char;
  TmpList : TStringList;
  PS : String;
begin
  Result:=True;
  TmpList:=TStringList.Create;
  sOPTIONS:='';
  TmpList.CommaText:=sOPTIONS;
  Try
    for i:=0 to TmpList.Count-1 do begin
      PS := TmpList[i];
      if (Length(PS)>1)and((PS[1]='/')or(PS[1]='-')) then begin
        Ch := UpCase(PS[2]);
        case Ch of
          'S': begin
            if Length(PS)=2 then
              //SetShowAll
            else begin
              for j:=3 to Length(PS) do begin
                Ch := {UpCase(}PS[j]{)};
                case Ch of
                  'I': ShowImpNames := false;
                  'T': ShowTypeTbl := true;
                  'A': ShowAddrTbl := true;
                  'D': ShowDataBlock := true;
                  'F': ShowFixupTbl := true;
                  'V': ShowAuxValues := true;
                  'M': ResolveMethods := false;
                  'C': ResolveConsts := false;
                  'd': ShowDotTypes := true;
                  'v': ShowVMT := true;
                else
                  Result:=false;
                  //Raise Exception.CreateFmt(err_unk_dcu_flag,[Ch]);
                  Exit;
                end ;
              end ;
            end ;
          end ;
          'I': InterfaceOnly := true;
          'U': begin
            Delete(PS,1,2);
            DCUPath := 'D:/lib/';//PS;
          end ;
          'N': begin
            Delete(PS,1,2);
            NoNamePrefix := PS;
          end ;
          'D': begin
            Delete(PS,1,2);
            DotNamePrefix := PS;
          end;
         End;
      end ;
    end ;
  Finally
    TmpList.Free;
  End;
end;

function ReplaceStar(FNRes,FN: String): String;
var
  CP: PChar;
begin
  CP := StrScan(PChar(FNRes),'*');
  if CP=Nil then begin
    Result := FNRes;
    Exit;
  end ;
  if StrScan(CP+1,'*')<>Nil then
    raise Exception.Create('2nd "*" is not allowed');
  FN := ExtractFilename(FN);
  if (CP+1)^=#0 then begin
    Result := Copy(FNRes,1,CP-PChar(FNRes))+ChangeFileExt(FN,'.int');
    Exit;
  end;
  Result := Copy(FNRes,1,CP-PChar(FNRes))+ChangeFileExt(FN,'')+Copy(FNRes,CP-PChar(FNRes)+2,MaxInt);
end ;

function ProcessFile(FN: String; var ResMS: TMemoryStream): integer {ErrorLevel};
var
  U: TUnit;
  NS,ExcS: String;
  OutRedir: boolean;
  CP: PChar;
  W: TBaseWriter;
begin
  Result := 0;
  ResMS := Nil;
  OutRedir := false;
  if FNRes='-' then
    FNRes := ''
  else begin
    //Writeln{(StdErr)};
    //Writeln('File: "',FN,'"');
    NS := ExtractFileName(FN);
    CP := StrScan(PChar(NS),PkgSep);
    if CP<>Nil then
      NS := StrPas(CP+1);
    if FNRes='' then
      FNRes := ExtractFilePath(FN)+ChangeFileExt(NS,DefaultExt[OutFmt])
    else
      FNRes := ReplaceStar(FNRes,FN);
    //Writeln('Result: "',FNRes,'"');
//    CloseFile(Output);
    Flush(Output);
    OutRedir := true;
  end ;
  AssignFile(FRes,FNRes);
  TTextRec(FRes).Mode := fmClosed;
  try
    try
      Rewrite(FRes); //Test whether the FNRes is a correct file name
      try
        if oFmtMEM then
          W := InitOutMem
        else
          W := InitOut('FRes');
        FN := ExpandFileName(FN);
        U := Nil;
        try
          U := GetDCUByName(FN,'',0,false,dcuplWin32,0){TUnit.Create(FN)};
        finally
          if U=Nil then
            U := MainUnit;
          if U<>Nil then
            U.Show;
        end;
      finally
        FreeDCU;
      end ;
    except
      on E: Exception do begin
        Result := 1;
        ExcS := Format('%s: "%s"',[E.ClassName,E.Message]);
        if TTextRec(FRes).Mode<>fmClosed then begin
          Writeln(FRes);
          Writeln(FRes,ExcS);
          Flush(FRes);
        end ;
        if OutRedir then
          Writeln(ExcS);
      end;
    end;
  finally
    if TTextRec(FRes).Mode<>fmClosed then begin
      //DoneOut;
      Close(FRes);
    end;
    if Writer is TMemWriter then
      ResMS := TMemWriter(Writer).TakeMem;
    Writer.Free;
    Writer:= nil;
    {if OutRedir then begin
      //Writeln(Format('Total %d lines generated.',[OutLineNum]));
      //Close(Output);
    end ;}
  end ;
end ;


{$R *.dfm}

procedure TDCU2INT.PrcessFileClick(Sender: TObject);
begin
end;

{procedure TDCU2INT.TestExprClick(Sender: TObject);
var
  ExprA, ExprB, ExprC, ExprD : TExpr;
  ExprInt1, ExprInt2 : TExpr;
  i : integer;
begin
 { DefineRegs;
  rEDX := TADD.Create(rEAX, rECX);
  WriteLn(rEDX.AsString(False));
  rEBX := TADD.Create(rEDX, rAX);
  WriteLn(rEBX.AsString(False));
  rAL := TMUL.Create(rEBX,rEDX);
  WriteLn(rAL.AsString(False));
  rEDI := TINC.Create(rESI);
  WriteLn(rEDI.AsString(True));
  rStack.Push(rEAX);
  rEAX := TADD.Create(rEDX, rAX);
  rEAX := rStack.Pop;
  WriteLn(rEAX.AsString(True));
  rStack.Push(rAL);
  ExprInt1 := TSemIntVal.Create(24,32);
  ExprInt2 := TSemIntVal.Create(12,32);
  WriteLn(TADD.Create(ExprInt1,ExprInt2).AsString(True));
  WriteLn(TADD.Create(ExprInt1,ExprInt2).EVal);
  ExprA := TAssign.Create(rEAX,rAL);
  WriteLn(ExprA.AsString(False));
  WriteLn(BMNames[hnEDX and nm]);
end;  }

function TDCU2INT.SearchForText_AndSelect(RichEdit: TRichEdit; SearchText: string): Boolean; 
var 
  StartPos, Position, Endpos: Integer; 
begin 
  StartPos := 0; 
  with RichEdit do
  begin 
    Endpos := Length(RichEdit.Text); 
    Lines.BeginUpdate; 
    while FindText(SearchText, StartPos, Endpos, [stMatchCase])<>-1 do 
    begin 
      Endpos   := Length(RichEdit.Text) - startpos; 
      Position := FindText(SearchText, StartPos, Endpos, [stMatchCase]); 
      Inc(StartPos, Length(SearchText)); 
      SetFocus;
      SelStart  := Position; 
      SelLength := Length(SearchText); 
    end; 
    Lines.EndUpdate; 
  end; 
end; 

procedure TDCU2INT.ProcessFile1Click(Sender: TObject);
var
  OutF: String;
  Stream: TStream;
  TmpStr : String;
  i, lnI: integer;
  PArr: PCILInfoTbl;
  ResMS: TMemoryStream;
begin
  TVProc.Items.Clear;
  ResMS := Nil;
  try
    REDCUDump.Lines.Clear;
    // TypInfo
    // GetEnumName(TypeInfo(),OneByteOpCode[i].GetFlowControl);
    if not ProcFile.Execute then
      Exit;
   // FMem := TMemoryStream.Create;
    DCUName:= ProcFile.FileName;
    ProcessParms(DCU2INTOption.sOPTIONS);
    ProcessFile(DCUName,ResMS);
    if ResMS<>Nil then begin
      ResMS.Position:=0;
      REDCUDump.Lines.LoadFromStream(ResMS);
    end ;
   // OutF := ChangeFileExt(DCUName,'.rtf');
   // FMem.SaveToFile(OutF);
  finally
    ResMS.Free;
    //FMem := Nil;
  end;
end;

procedure TDCU2INT.Saveasrtf1Click(Sender: TObject);
begin
  if not SaveDlg.Execute then
    Exit;
  REDCUDump.Lines.SaveToFile(ChangeFileExt(SaveDlg.FileName,'.rtf'));
end;

procedure TDCU2INT.Options1Click(Sender: TObject);
begin
  DCU2INTOption.ShowModal;
  If DCU2INTOption.ModalResult=mrOK
     Then ProcessParms(DCU2INTOption.sOPTIONS)
end;

procedure TDCU2INT.ChkDasmModeChange(Sender: TObject);
begin
  case ChkDasmMode.ItemIndex of
    0: DasmMode:= dasmSeq;
    1: DasmMode:= dasmCtlFlow;
  end;
end;

procedure TDCU2INT.ChkDisAsmChange(Sender: TObject);
begin
  case ChkDisAsm.ItemIndex of
    0 : begin
      TopLevelUnitClass := TUnit;
      DisAsmMode:= mMSIL;
    end;
    1 : begin
      DisAsmMode:= mCil;
      TopLevelUnitClass := TDecomCILUnit;
    end;
    2: begin
      DisAsmMode:= mX86;
      TopLevelUnitClass := TDecomUnit;
    end;
  end;
end;

procedure TDCU2INT.FormCreate(Sender: TObject);
begin
  ProcFile.Filter := 'Delphi files|*.dcu;*.tpu;*.dcuil|All files|*.*';
  ChkDasmMode.ItemIndex := 1;
  DisAsmMode := mCIL;
  ChkDisAsm.ItemIndex :=1;
  TopLevelUnitClass := TDecomCILUnit;
end;

procedure TDCU2INT.GMLChange(Sender: TObject);
begin
  case GML.ItemIndex of
    1: TopLevelUnitClass := TUnit;
  end;
end;

procedure TDCU2INT.TVProcClick(Sender: TObject);
var
  i, id: Cardinal;
begin
  //SearchForText_AndSelect(REDCUDump, TVProc.Selected.Text);
end;

procedure TDCU2INT.TVProcDblClick(Sender: TObject);
begin
  REDCUDump.Lines.BeginUpdate;
  REDCUDump.SetFocus;
  REDCUDump.SelStart := REDCUDump.Perform(EM_LINEINDEX, Integer(TVProc.Selected.Data), 0);
  REDCUDump.SelLength := 0;
  REDCUDump.Perform(EM_SCROLLCARET,0,1);
  REDCUDump.Perform(SB_LINEUP,0,1);
  REDCUDump.Lines.EndUpdate;
end;

initialization
  DecimalSeparator := '.';
  InitOpCodeNames;
  OpCodes:= TCILOpCodes.Create;
  OpCodes.InitOpCodes;
  InfoTbl := TOpCodeInfoTbl.Create;
finalization
  DisposeOpCodes;

end.
