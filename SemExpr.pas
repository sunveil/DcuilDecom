unit SemExpr;

interface

uses
  SysUtils, Classes,
  DasmDefs,
  DasmUtil,
  op,
  Expr,
  DecomUtils;

type


  TSemExpr = class(TExpr)
  end;

  TSemVal = class(TSemExpr)
    function GetBitSize: integer; virtual; abstract;
  end ;

  TSemIntVal = class(TSemVal)
    FVal: integer;
    FBitSize: integer;
    constructor Create(AVal: integer; ABitSize: integer);
    function GetBitSize: integer; override;
    function Eval: TValue;override;
    function AsString(BrRq: boolean): String; override;
    function Eq(E: TExpr): boolean; override;
  end;

  TSemImmedVal = class(TSemIntVal)
    function AsString(BrRq: boolean): String; override;
  end;

  TSemEAVal = class(TSemVal)
    FCmArg : TCmArg;
    constructor Create(ACmArg: TCmArg);
    function AsString(BrRq: boolean): String; override;
    function Eq(E: TExpr): boolean; override;
  end;

  TSemVar = class(TSemVal)
  end;

  TSemRegPart = class;

  TSemReg = class(TSemVar)
    FBitSize: integer;
    FName: String;
    Parts: TSemRegPart;
    constructor Create(AName: String; ABitSize: integer);
    function GetBitSize: integer; override;
    function GetRegName: String;
    function AsString(BrRq: boolean): String; override;
    function Eq(E: TExpr): boolean; override;
    function Eval: TValue;override;
    procedure AddPart(P: TSemRegPart);
    property BitSize: integer read GetBitSize;
    property Name: String read GetRegName;
  end;

  TSemRegPart = class(TSemReg)
    FBitOfs: integer;
    FBaseReg: TExpr;
    NextPart: TSemRegPart;
    constructor Create(AName: String; ABase: TExpr; ABitOfs, ABitSize: integer);
    function AsString(BrRq: boolean): String; override;
    function Eq(E: TExpr): boolean; override;
    property BitOfs: integer read FBitOfs;
  end;

  TSemRegBit = class(TSemRegPart)
    FState: boolean;
    FRef: TExpr;
    constructor Create(AName: String; ABase: TExpr; ABitOfs: integer);
    function Eq(E: TExpr): boolean; override;
    function AsString(BrRq: boolean): String; override;
    procedure SetFlag(AState: boolean);
    procedure SetRef(ARef: TExpr);
    function GetRef: TExpr;
    procedure UnDefFlag;
  end;

  TSemVarSlice = class(TSemVar)
    FBitSize,FBitOfs: integer;
    FBase: TSemVar;
    constructor Create(ABase: TSemVar; ABitOfs, ABitSize: integer);
  end;

  TSemVarJoin = class(TSemVar)
    FR1,FR2: TSemReg;
    constructor Create(AR1,AR2: TSemReg);
    function GetBitSize: integer; override;
  end;

  TSemMem = class
    FBitSize,FBitOfs: integer;
  end;

  TSemMemVar = class(TSemVar)
    FMem: TSemMem;
    FOfs: TSemVal;
    FBitSize: integer;
    constructor Create(AMem: TSemMem; AOfs: TSemVal; ABitSize: integer);
    function AsString(BrRq: boolean): String; override;
    function GetBitSize: integer; override;
  end;

  TSemTable = class(TList)
    constructor Create(const eTbl: array of TExpr);
    function GetExpr(N: integer): TSemExpr;
    procedure SetExpr(N: integer; Expr: TExpr);
    procedure AddExpr(Expr: TExpr);
  end;

  TSemEnv = class;

  TSemEnvLink = class
    EnvPre,EnvPost: TSemEnv;
    Cond: TSemVal;
    NextPre, NextPost: TSemEnvLink;
  end ;

  TSemVarValLnk = class
    Next: TSemVarValLnk;
    Vr: TSemVar; Vl: TSemVal;
  end ;

  TSemEnv = class
    Ofs: Cardinal;
    Pre, Post: TSemEnvLink;
    Env: TSemVarValLnk;
   // function GetVarVal(Vr: TSemVar): TSemVal;
   // procedure AddVarVal(Vr: TSemVar; Vl: TSemVal);
  end ;

  TSemOp = class(TSemExpr)

  end ;

function BinSemAction(var Arg: TExpr; var Action: TExpr): boolean;

implementation

function BinSemAction(var Arg: TExpr; var Action: TExpr): boolean;
begin
  Arg := Action;
end;

{ TSemExpr. }

{ TSemVal. }

{ TSemIntVal. }

constructor TSemIntVal.Create(AVal: integer; ABitSize: integer);
begin
  inherited Create;
  FVal := AVal;
  FBitSize := ABitSize
end ;

function TSemIntVal.GetBitSize: integer;
begin
  Result := FBitSize;
end ;

function TSemIntVal.Eval: TValue;
begin
  Result := FVal;
end;

function TSemIntVal.AsString(BrRq: boolean): String;
begin
  Result := IntToStr(FVal);
end;

function TSemIntVal.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType = TSemIntVal)and(FVal = TSemIntVal(E).FVal);
end;

{ TSemVar. }

{ TSemReg. }

constructor TSemReg.Create(AName: String; ABitSize: integer);
begin
  inherited Create;
  FName := AName;
  FBitSize := ABitSize;
  Parts := Nil;
end ;

function TSemReg.GetBitSize: integer;
begin
  Result := FBitSize;
end ;

function TSemReg.GetRegName: String;
begin
  Result := FName;
end;

function TSemReg.AsString(BrRq: boolean): String;
begin
  Result := FName;
end;

function TSemReg.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType=TSemReg)and(FName = TSemReg(E).FName);
end;

function TSemReg.Eval: TValue;
begin
  Result := 0;
end;

procedure TSemReg.AddPart(P: TSemRegPart);
var
  PP: ^TSemRegPart;
begin
  PP := @Parts;
  while (PP^<>Nil)and(PP^.BitOfs>=P.BitOfs) do
    PP := @PP^.NextPart;
  P.NextPart := PP^;
  PP^ := P;
end ;

{ TSemRegPart. }

constructor TSemRegPart.Create(AName: String; ABase: TExpr; ABitOfs, ABitSize: integer);
begin
  inherited Create(AName,ABitSize);
  FBaseReg := ABase;
  FBitOfs := ABitOfs;
end ;

function TSemRegPart.AsString(BrRq: boolean): String;
begin
  Result := FName;
end;

function TSemRegPart.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType = TSemRegPart)and(FName = TSemRegPart(E).FName);
end;

{ TSemRegBit. }

constructor TSemRegBit.Create(AName: String; ABase: TExpr; ABitOfs: integer);
begin
  inherited Create(AName,ABase,ABitOfs,1);
end ;

function TSemRegBit.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType = TSemRegBit)and(FName = TSemRegBit(E).FName);
end;

function TSemRegBit.AsString(BrRq: boolean): String;
begin
  Result := FName;
end;

procedure TSemRegBit.SetFlag(AState: boolean);
begin
  FState := AState;
end;

procedure TSemRegBit.SetRef(ARef: TExpr);
begin
  FRef := ARef;
end;

function TSemRegBit.GetRef: TExpr;
begin
  Result:= FRef;
end;

procedure TSemRegBit.UnDefFlag;
begin
  FState := False;
end;
{ TSemVarSlice. }

constructor TSemVarSlice.Create(ABase: TSemVar; ABitOfs, ABitSize: integer);
begin
  inherited Create;
  FBase := ABase;
  FBitOfs := ABitOfs;
  FBitSize := ABitSize;
end ;

{ TSemVarJoin. }

constructor TSemVarJoin.Create(AR1,AR2: TSemReg);
begin
  inherited Create;
  FR1 := AR1;
  FR2 := AR2;
end ;

function TSemVarJoin.GetBitSize: integer;
begin
  Result := FR1.BitSize+FR2.BitSize;
end ;

{ TSemMem. }

{ TSemMemVar. }

constructor TSemMemVar.Create(AMem: TSemMem; AOfs: TSemVal; ABitSize: integer);
begin
  inherited Create;
  FMem := AMem;
  FOfs := AOfs;
  FBitSize := ABitSize;
end ;

function TSemMemVar.AsString(BrRq: boolean): String;
begin
  Result := 'mem';
end;

function TSemMemVar.GetBitSize: integer;
begin
  Result := FBitSize;
end ;

{ TSemTable. }
constructor TSemTable.Create(const eTbl: array of TExpr);
var
  i: integer;
begin
  inherited Create;
  for i:=Low(eTbl) to High(eTbl) do
    Add(eTbl[i]);
end ;

function TSemTable.GetExpr(N: integer): TSemExpr;
begin
  Result := TSemExpr(Items[N]);
end ;

procedure TSemTable.SetExpr(N: integer; Expr: TExpr);
begin
  Self.Put(N,Expr);
end;

procedure TSemTable.AddExpr(Expr: TExpr);
begin
 Add(Expr);
end;

{ TSemImmedVal. }

function TSemImmedVal.AsString(BrRq: boolean): String;
begin
  Result := Format('$%x',[FVal]);
end;

{ TSemEAVal. }

function TSemEAVal.AsString(BrRq: boolean): String;
begin
  Result := 'EA'{GetStrEA};
end;

constructor TSemEAVal.Create(ACmArg: TCmArg);
begin
  FCmArg := ACmArg;
end;

function TSemEAVal.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType = TSemEAVal)and(FCmArg.CmdKind = TSemEAVal(E).FCmArg.CmdKind)
    and(FCmArg.Inf = TSemEAVal(E).FCmArg.Inf)
end;

end.

