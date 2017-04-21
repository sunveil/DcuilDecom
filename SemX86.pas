unit SemX86;

interface

uses
  SemExpr,
  DAsmDefs,
  DAsmUtil,
  op,
  Expr,
  Stack,
  DecomUtils;

const

  efCF = 0;
  efPF = 1;
  efAF = 2;
  efZF = 3;
  efSF = 4;
  efTF = 5;
  efIF = 6;
  efDF = 7;
  efOF = 8;

const

  EFLAGS: array[0..8] of THBMName = (
    efCF, efPF, efAF, efZF, efSF, efTF, efIF, efDF, efOF
  );

type
  TProcState = class
    rEAX,rECX,rEDX,rEBX,rESP,rEBP,rESI,rEDI: TExpr;
    rtReg32: TSemTable;
    rAX,rCX,rDX,rBX,rSP,rBP,rSI,rDI: TSemRegPart;
    rtReg16: TSemTable;
    rAL,rCL,rDL,rBL,rAH,rCH,rDH,rBH: TExpr;
    rtRegB: TSemTable;
    rES,rCS,rSS,rDS,rFS,rGS: TExpr;
    rtSReg: TSemTable;
    rEFlags,rEIP: TExpr;
    rfCF,rfPF, rfAF, rfZF,rfSF,rfTF,rfIF,rfDF,rfOF: TExpr;
    rfIOPL,rIP: TExpr;
    rfNT,rfRF,rfVM,rfAC,rfVIF,rfVIP,rfID: TExpr;
    rStack : TStack;
    rZeroInt, rZeroInt1, rZeroInt2 : TExpr;
    rtIntVal : TSemTable;
    rZeroHexVal : TSemImmedVal;
    rtImmedVal : TSemTable;
    procedure DefineRegs;
    procedure SetEFLAG(Inf: integer; Flag: boolean; Ref: TExpr);
    function GetArg(Arg: TCmArg): TExpr;
    function GetReg(Inf: integer): TExpr;
    function SetArg(Arg: TCmArg; Expr: TExpr): boolean;
  end;

implementation

{ TProcState. }

procedure TProcState.SetEFLAG(Inf: integer; Flag: boolean; Ref: TExpr);
begin
  case Inf of
    efCF: begin
      TSemRegBit(Self.rfCF).SetFlag(Flag);
      TSemRegBit(Self.rfCF).SetRef(Ref);
    end;
    efPF: begin
      TSemRegBit(Self.rfPF).SetFlag(Flag);
      TSemRegBit(Self.rfPF).SetRef(Ref);
    end;
    efAF: begin
      TSemRegBit(Self.rfAF).SetFlag(Flag);
      TSemRegBit(Self.rfAF).SetRef(Ref);
    end;
    efZF: begin
      TSemRegBit(Self.rfZF).SetFlag(Flag);
      TSemRegBit(Self.rfZF).SetRef(Ref);
    end;
    efSF: begin
      TSemRegBit(Self.rfCF).SetFlag(Flag);
      TSemRegBit(Self.rfCF).SetRef(Ref);
    end;
    efTF: ;
    efIF: ;
    efDF: ;
    efOF: ;
  end;
end;

procedure TProcState.DefineRegs;
begin
  rEAX := TSemReg.Create('EAX',32);
  rECX := TSemReg.Create('ECX',32);
  rEDX := TSemReg.Create('EDX',32);
  rEBX := TSemReg.Create('EBX',32);
  rESP := TSemReg.Create('ESP',32);
  rEBP := TSemReg.Create('EBP',32);
  rESI := TSemReg.Create('ESI',32);
  rEDI := TSemReg.Create('EDI',32);
  rtReg32 := TSemTable.Create([rEAX,rECX,rEDX,rEBX,rESP,rEBP,rESI,rEDI]);
  rAX := TSemRegPart.Create('AX',rEAX,0,16);
  rCX := TSemRegPart.Create('CX',rECX,0,16);
  rDX := TSemRegPart.Create('DX',rEDX,0,16);
  rBX := TSemRegPart.Create('BX',rEBX,0,16);
  rSP := TSemRegPart.Create('SP',rESP,0,16);
  rBP := TSemRegPart.Create('BP',rEBP,0,16);
  rSI := TSemRegPart.Create('SI',rESI,0,16);
  rDI := TSemRegPart.Create('DI',rEDI,0,16);
  rtReg16 := TSemTable.Create([rAX,rCX,rDX,rBX,rSP,rBP,rSI,rDI]);
  rAL := TSemRegPart.Create('AL',rAX,0,8);
  rCL := TSemRegPart.Create('CL',rCX,0,8);
  rDL := TSemRegPart.Create('DL',rDX,0,8);
  rBL := TSemRegPart.Create('BL',rBX,0,8);
  rAH := TSemRegPart.Create('AH',rAX,8,8);
  rCH := TSemRegPart.Create('CH',rCX,8,8);
  rDH := TSemRegPart.Create('DH',rDX,8,8);
  rBH := TSemRegPart.Create('BH',rBX,8,8);
  rtRegB := TSemTable.Create([rAL,rCL,rDL,rBL,rAH,rCH,rDH,rBH]);
  rES := TSemReg.Create('ES',16);
  rCS := TSemReg.Create('CS',16);
  rSS := TSemReg.Create('SS',16);
  rDS := TSemReg.Create('DS',16);
  rFS := TSemReg.Create('FS',16);
  rGS := TSemReg.Create('GS',16);
  rtSReg := TSemTable.Create([rES,rCS,rSS,rDS,rFS,rGS,Nil,Nil]);
  rEIP := TSemReg.Create('EIP',32);
  rIP := TSemRegPart.Create('IP',rEIP,0,16);
  rEFLAGS := TSemReg.Create('EFLAGS',32);
  rfCF := TSemRegBit.Create('CF',rEFLAGS,0);
  rfPF := TSemRegBit.Create('PF',rEFLAGS,2);
  rfAF := TSemRegBit.Create('AF',rEFLAGS,4);
  rfZF := TSemRegBit.Create('ZF',rEFLAGS,6);
  rfSF := TSemRegBit.Create('SF',rEFLAGS,7);
  rfTF := TSemRegBit.Create('TF',rEFLAGS,8);
  rfIF := TSemRegBit.Create('IF',rEFLAGS,9);
  rfDF := TSemRegBit.Create('DF',rEFLAGS,10);
  rfOF := TSemRegBit.Create('OF',rEFLAGS,11);
  rfIOPL := TSemRegPart.Create('IOPL',rEFLAGS,12,2);
  rfNT := TSemRegBit.Create('NT',rEFLAGS,14);
  rfRF := TSemRegBit.Create('RF',rEFLAGS,16);
  rfVM := TSemRegBit.Create('VM',rEFLAGS,17);
  rfAC := TSemRegBit.Create('AC',rEFLAGS,18);
  rfVIF := TSemRegBit.Create('VIF',rEFLAGS,19);
  rfVIP := TSemRegBit.Create('VIF',rEFLAGS,20);
  rfID := TSemRegBit.Create('ID',rEFLAGS,21);
  rStack := TStack.Create;
  rZeroInt := TSemIntVal.Create(0,32);
  rZeroInt1 := TSemIntVal.Create(0,32);
  if rZeroInt.Eq(rZeroInt1) then
    rZeroInt1 := rZeroInt
  else
    rZeroInt1:= TSemIntVal.Create(0,32);
  rZeroInt2 := TSemIntVal.Create(0,32);
  rtIntVal := TSemTable.Create([rZeroInt]);
  rZeroHexVal := TSemImmedVal.Create(0,32);
  rtImmedVal := TSemTable.Create([rZeroHexVal]);

end ;

{procedure InitSemInfo;
begin
  DefineRegs;
end ;}

function TProcState.GetReg(Inf: integer): TExpr;
begin
  case Inf of
    hnEAX : Result := rtReg32.GetExpr(0);
    hnECX : Result := rtReg32.GetExpr(1);
    hnEDX : Result := rtReg32.GetExpr(2);
    hnEBX : Result := rtReg32.GetExpr(3);
    hnESP : Result := rtReg32.GetExpr(4);
    hnEBP : Result := rtReg32.GetExpr(5);
    hnESI : Result := rtReg32.GetExpr(6);
    hnEDI : Result := rtReg32.GetExpr(7);
    hnAX : Result := rtReg16.GetExpr(0);
    hnCX : Result := rtReg16.GetExpr(1);
    hnDX : Result := rtReg16.GetExpr(2);
    hnBX : Result := rtReg16.GetExpr(3);
    hnSP : Result := rtReg16.GetExpr(4);
    hnBP : Result := rtReg16.GetExpr(5);
    hnSI : Result := rtReg16.GetExpr(6);
    hnDI : Result := rtReg16.GetExpr(7);
    hnAL : Result := rtRegB.GetExpr(0);
    hnCL : Result := rtRegB.GetExpr(1);
    hnDL : Result := rtRegB.GetExpr(2);
    hnBL : Result := rtRegB.GetExpr(3);
    hnAH : Result := rtRegB.GetExpr(4);
    hnCH : Result := rtRegB.GetExpr(5);
    hnDH : Result := rtRegB.GetExpr(6);
    hnBH : Result := rtRegB.GetExpr(7);
  end;
end;


function TProcState.GetArg(Arg: TCmArg): TExpr;

  function GetReg(N: integer): TExpr;
  begin
    case N of
      hnEAX : Result := rtReg32.GetExpr(0);
      hnECX : Result := rtReg32.GetExpr(1);
      hnEDX : Result := rtReg32.GetExpr(2);
      hnEBX : Result := rtReg32.GetExpr(3);
      hnESP : Result := rtReg32.GetExpr(4);
      hnEBP : Result := rtReg32.GetExpr(5);
      hnESI : Result := rtReg32.GetExpr(6);
      hnEDI : Result := rtReg32.GetExpr(7);
      hnAX : Result := rtReg16.GetExpr(0);
      hnCX : Result := rtReg16.GetExpr(1);
      hnDX : Result := rtReg16.GetExpr(2);
      hnBX : Result := rtReg16.GetExpr(3);
      hnSP : Result := rtReg16.GetExpr(4);
      hnBP : Result := rtReg16.GetExpr(5);
      hnSI : Result := rtReg16.GetExpr(6);
      hnDI : Result := rtReg16.GetExpr(7);
      hnAL : Result := rtRegB.GetExpr(0);
      hnCL : Result := rtRegB.GetExpr(1);
      hnDL : Result := rtRegB.GetExpr(2);
      hnBL : Result := rtRegB.GetExpr(3);
      hnAH : Result := rtRegB.GetExpr(4);
      hnCH : Result := rtRegB.GetExpr(5);
      hnDH : Result := rtRegB.GetExpr(6);
      hnBH : Result := rtRegB.GetExpr(7);
    end;
  end;

  function GetInt(Val : integer): TExpr;
  begin
    Result := TSemIntVal.Create(Val, 32);
    rtIntVal.AddExpr(Result);
  end;

  function GetImmed(Val : integer): TExpr;
  begin
    Result := TSemImmedVal.Create(Val,32);
    rtImmedVal.AddExpr(Result);
  end;

  function GetEffArd(Arg: TCmArg): TExpr;
  begin
    Result := TSemEAVal.Create(Arg);
  end;

begin
  case Arg.CmdKind and caMask of
    caReg : Result := GetReg(Arg.Inf or nf);
    caInt : Result := GetInt(ReportImmed(true,false,0,Arg.CmdKind shr 4,hCS,Arg.Inf,Arg.Fix));
    caImmed : Result := GetImmed(Arg.Inf);
    caEffAdr : Result := GetEffArd(Arg);
  else
    Result := rtIntVal.GetExpr(0);
  end;
end;

function TProcState.SetArg(Arg: TCmArg; Expr: TExpr): boolean;
var
  N : integer;
begin
  Result := True;
  N := Arg.Inf or nf;
  case N of
    hnEAX : rtReg32.SetExpr(0,Expr);
    hnECX : rtReg32.SetExpr(1,Expr);
    hnEDX : rtReg32.SetExpr(2,Expr);
    hnEBX : rtReg32.SetExpr(3,Expr);
    hnESP : rtReg32.SetExpr(4,Expr);
    hnEBP : rtReg32.SetExpr(5,Expr);
    hnESI : rtReg32.SetExpr(6,Expr);
    hnEDI : rtReg32.SetExpr(7,Expr);
    hnAX : rtReg16.SetExpr(0,Expr);
    hnCX : rtReg16.SetExpr(1,Expr);
    hnDX : rtReg16.SetExpr(2,Expr);
    hnBX : rtReg16.SetExpr(3,Expr);
    hnSP : rtReg16.SetExpr(4,Expr);
    hnBP : rtReg16.SetExpr(5,Expr);
    hnSI : rtReg16.SetExpr(6,Expr);
    hnDI : rtReg16.SetExpr(7,Expr);
    hnAL : rtRegB.SetExpr(0,Expr);
    hnCL : rtRegB.SetExpr(1,Expr);
    hnDL : rtRegB.SetExpr(2,Expr);
    hnBL : rtRegB.SetExpr(3,Expr);
    hnAH : rtRegB.SetExpr(4,Expr);
    hnCH : rtRegB.SetExpr(5,Expr);
    hnDH : rtRegB.SetExpr(6,Expr);
    hnBH : rtRegB.SetExpr(7,Expr);
  else
    Result := False;
  end;
end;

end.



