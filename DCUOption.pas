unit DCUOption;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  ConfUnit;

type
  TDCU2INTOption = class(TForm)
    GroupBox1: TGroupBox;
    c1: TCheckBox;
    c2: TCheckBox;
    c3: TCheckBox;
    C4: TCheckBox;
    C5: TCheckBox;
    C6: TCheckBox;
    C7: TCheckBox;
    C8: TCheckBox;
    C10: TCheckBox;
    C9: TCheckBox;
    OK: TButton;
    Cancel: TButton;
    procedure OKClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
     sOPTIONS : String;
  end;

var
  DCU2INTOption: TDCU2INTOption;

implementation

uses
  DCU_Out;

{$R *.dfm}

procedure TDCU2INTOption.OKClick(Sender: TObject);
begin

  {InterfaceOnly: boolean=false;
  ShowImpNames: boolean=true;
  ShowTypeTbl: boolean=true;
  ShowAddrTbl: boolean=true;
  ShowDataBlock: boolean=true;
  ShowFixupTbl: boolean=true;
  ShowLocVarTbl: boolean=true;
  ShowFileOffsets: boolean=true;
  ShowAuxValues: boolean=true;
  ResolveMethods: boolean=true;
  ResolveConsts: boolean=true;
  ShowDotTypes: boolean=true;
  ShowSelf: boolean=true;
  ShowVMT: boolean=true;
  ShowHeuristicRefs: boolean=true;
  ShowImpNamesUnits: boolean=true;
  DasmMode: TDasmMode = dasmCtlFlow;
  OutFmt: TOutFmt = ofmtMem; }
  ShowImpNames:=c1.Checked;
  ShowTypeTbl:=c2.Checked;
  ShowAddrTbl:=c3.Checked;
  ShowDataBlock:=c4.Checked;
  ShowFixupTbl:=c5.Checked;
  ShowAuxValues:=c6.Checked;
  ResolveMethods:=c7.Checked;
  ResolveConsts:=c8.Checked;
  ShowDotTypes:=c9.Checked;
  ShowVMT:=c10.Checked;
  ModalResult:=mrOK;
end;

procedure TDCU2INTOption.CancelClick(Sender: TObject);
begin
  Close;
end;

procedure TDCU2INTOption.FormCreate(Sender: TObject);
begin
  c1.Checked := ShowImpNames;
  c2.Checked := ShowTypeTbl;
  c3.Checked := ShowAddrTbl;
  c4.Checked := ShowDataBlock;
  c5.Checked := ShowFixupTbl;
  c6.Checked := ShowAuxValues;
  c7.Checked := ResolveMethods;
  c8.Checked := ResolveConsts;
  c9.Checked := ShowDotTypes;
  c10.Checked := ShowVMT;
end;

initialization

   ReadIFile;

finalization

  //WriteIFile;

end.
