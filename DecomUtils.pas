unit DecomUtils;

interface

uses
  DCU_Out,
  DasmUtil,
  FixUp,
  op;

type
  TDisAsmMode = (mCIL, mMSIL, mX86);

var
  DisAsmMode: TDisAsmMode; 


function GetStrEA: AnsiString;

implementation

function GetStrEA: AnsiString;
var
  SegN,DSF: Byte;
  Cnt,Sz:integer;
  hLastReg: byte;

  procedure Plus;
  begin
    if Cnt>0 then
      PutS('+');
    Inc(Cnt);
  end ;

  function GetRegName(hReg,SS:Byte; ShowVar: boolean): AnsiString;
  const
    ScaleStr: array[0..3] of String[3] = ('','2*','4*','8*');
  begin
    if hReg and hPresent=0 then
      Exit;
    hReg := RegTbl{$IFDEF I64}[hReg and hRegHasRex<>0]{$ENDIF}
        [(hReg shr hRegSizeShift)and hRegSizeMask]^[hReg and $F];
    if SS=0 then
      hLastReg := hReg;
    Plus;
    if (SS>0)and(SS<=3) then
      PutS(ScaleStr[SS]);
    if ShowVar and(SS=0) then
      Result := GetOpName(hReg)
      //WriteRegName(hReg,false{IsFirst})
    else
      Result := GetOpName(hReg)
  end ;

var
  hR1,hR2: byte;
  Fixed,AsExpr: boolean;
  D: LongInt;
  Cmd: TCmdInfo;
begin
  //Cmd.
  DSF := (Cmd.EA.hSeg shr 4)and dsMask;
  Case DSF of
    0:;
    dsByte: PutS('BYTE');
    dsWord: PutS('WORD');
    dsDbl:  PutS('DWORD');
    dsPtr:  PutS('DWORD');
    dsPtr6b:PutS('FWORD');
    dsQWord:PutS('QWORD');
    dsTWord:PutS('TBYTE');
  else
    PutS('?');
  End ;
  if DSF<>0 then
    PutS(' PTR ')
  else
    PutS(' ');
  SegN := Cmd.EA.hSeg and $f;
  if SegN<hDefSeg then begin
    Result := GetOpName(SegRegTbl^[segN]);
    //WriteBMOpName(SegRegTbl^[segN]);
    //PutS(':');
    Result :=  Result + ':';
  end ;
  Cnt := 0;
  PutS('[');
  Fixed := FixupOk(Cmd.EA.Fix);
  hR1 := Cmd.EA.hBaseOnly;
  hR2 := Cmd.EA.hIndex;
  AsExpr := (not Fixed)and((hR1 and hPresent<>0)<>(hR2 and hPresent<>0)
    and(Cmd.EA.SS=0));
  Result := Result + GetRegName(hR1,0,not AsExpr);
  Result := Result + GetRegName(hR2,Cmd.EA.SS,not AsExpr);
  if Cmd.EA.dOfs<>0 then begin
    Sz := Cmd.EA.dOfs shr dOfsSizeShift;
    if Sz>=dsIPOfs then begin
      //WriteJmpOfs(dsDbl,Cmd.EA.dOfs and dOfsOfsMask,Cmd.EA.Fix);
      D := 0;//!!!Temp
     end
    else
      D := ReportImmed(Cnt>0{IsInt},Cnt>0{SignRq},DSF,Sz{hDSize},
        SegN and $7,Cmd.EA.dOfs and dOfsOfsMask{Ofs},Cmd.EA.Fix)
   end
  else
    D := 0;
  if AsExpr then
    //WriteRegVarInfo(hLastReg,D{Ofs},dsToSize[DSF]{Size},false{IsFirst});
  PutS(']');
end ;

end.
