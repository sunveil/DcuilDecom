unit CILExpr;

interface

uses
  SysUtils,
  Classes,
  CILOpCode,
  CILCodes,
  RefEl,
  DCU_Out;

type

PValue = ^TValue;
TValue = integer;

type
  TCILInstr = String;

type

PCILExpr = ^TCILExpr;
TCILExpr = class(TRefEl)
public
  function AddRef: TCILExpr;
  function Eval: TValue; virtual; abstract;
  function DependsOn(VN: String): boolean; virtual;
  function Eq(E: TCILExpr): boolean; virtual; abstract;
  function AsString(BrRq: boolean): String; virtual; abstract;
  procedure Show(BrRq: boolean); virtual; abstract;
end;

TCILLabel = class(TCILExpr)
protected
  FName: String;
  FRefCount: integer;
public
  constructor Create(AName: String);
  //function Eq(E: TCILExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
  procedure RemoveRef;
  procedure AddRef;
  property RefCount: integer read FRefCount write FRefCount;
end;

TCILIntVal = class(TCILExpr)
protected
  FVal: Int64;
  FSize: integer;
public
  constructor Create(AV: Int64; Size: integer);
  //function Eval: TValue; override;
  //function Eq(E: TCILExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

TCILArg = class(TCILExpr)
protected
  FName: String;
  FAssign: TCILExpr;
  FNDX: integer;
public
  constructor Create(AName: String);
  //function Eq(E: TCILExpr): boolean; override;
  procedure AssignExpr(Expr: TCILExpr);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
  property NDX: integer read FNDX write FNDX;
end;

TCILStr = class(TCILArg)
end;

TCILRet = class(TCILExpr)
protected
  FName: String;
public
  constructor Create();
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

TCILAssign = class(TCILExpr)
protected
  FDest, FSource: TCILExpr;
  FName: String;
public
  constructor Create(ADest, ASource: TCILExpr);
  //function Eq(E: TCILExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

TCILLocal = class(TCILExpr)
protected
  FName: String;
public
  constructor Create(AName: String);
  //function Eq(E: TCILExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

//Un operations

TCILUnOp = class(TCILExpr)
protected
  FArg: TCILExpr;
public
  constructor Create(AArg: TCILExpr);
  destructor Destroy; override;
  class function OpName: String; virtual; abstract;
  function DependsOn(VN: String): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

TCILIsInst = class(TCILUnOp)
protected
  FName: String;
  AArg: TCILArg;
public
  constructor Create(AName: String; AArg: TCILExpr);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

//Bin operations

TCILBinOp = class(TCILExpr)
protected
  FOpName: String;
  FArg,FArg1: TCILExpr;
public
  constructor Create(AArg,AArg1: TCILExpr); virtual;
  destructor Destroy; override;
  class function OpName: String; virtual; abstract;
  class function Simmetric: boolean; virtual;
  function DependsOn(VN: String): boolean; override;
  //function Eq(E: TCILExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end ;

TCILAdd = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILMul = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILSub = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILRem = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;


TCILCgt = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILConv = class(TCILIsInst)
protected
public
end;

TCILShl = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILXor = class(TCILBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  //function Eval: TValue; override;
end;

TCILConvU8 = class(TCILExpr)
public

end;

implementation

{ TCILExpr. }

function TCILExpr.AddRef: TCILExpr;
begin
  Result := TCILExpr(inherited AddRef);
end;

function TCILExpr.DependsOn(VN: String): boolean;
begin
  Result := False;
end;

{ TCILUnOp. }

function TCILUnOp.AsString(BrRq: boolean): String;
begin
  //Result:=
end;

procedure TCILUnOp.Show(BrRq: boolean);
begin
end;

constructor TCILUnOp.Create(AArg: TCILExpr);
begin
  inherited Create;
  FArg := AArg.AddRef;
end;

function TCILUnOp.DependsOn(VN: String): boolean;
begin

end;

destructor TCILUnOp.Destroy;
begin
  FArg.RmRef;
  inherited Destroy;
end;

{ TCILBinOp. }

function TCILBinOp.AsString(BrRq: boolean): String;
begin
  if BrRq then
    Result:= Format('(%s %s %s)',[FArg.AsString(BrRq), OpName ,FArg1.AsString(BrRq)])
  else
    Result:= Format('%s %s %s',[FArg.AsString(BrRq), OpName ,FArg1.AsString(BrRq)]);
end;

procedure TCILBinOp.Show(BrRq: boolean);
begin
  PutS(AsString(BrRq));
end;

constructor TCILBinOp.Create(AArg, AArg1: TCILExpr);
begin
  inherited Create;
  FArg := AArg.AddRef;
  FArg1 := AArg1.AddRef;
end;

function TCILBinOp.DependsOn(VN: String): boolean;
begin

end;

destructor TCILBinOp.Destroy;
begin
  FArg.RmRef;
  FArg1.RmRef;
  inherited Destroy;
end;

{function TCILBinOp.Eq(E: TCILExpr): boolean;
begin
  Result := false;
  if (E.ClassType<>ClassType) then
    Exit;
  Result := (FArg.Eq(TCILBinOp(E).FArg))and(FArg1.Eq(TCILBinOp(E).FArg1));
  if Result or not Simmetric then
    Exit;
  Result := (FArg1.Eq(TCILBinOp(E).FArg))and(FArg.Eq(TCILBinOp(E).FArg1));
end;}

class function TCILBinOp.Simmetric: boolean;
begin

end;

{ TCILIValOp. }

function TCILIntVal.AsString(BrRq: boolean): String;
begin
  Result:= IntToStr(FVal);
end;

procedure TCILIntVal.Show(BrRq: boolean);
begin
  PutSFmt('%d',[FVal]);
end;

constructor TCILIntVal.Create(AV: Int64; Size: integer);
begin
  FVal:= AV;
  FSize:= Size;
end;

{function TCILIntVal.Eq(E: TCILExpr): boolean;
begin
  if (TCILIntVal(E).FVal = FVal) and (TCILIntVal(E).FSize = FSize) then
    Result:= True;
end;}

{ TCILArg. }

constructor TCILArg.Create(AName: String);
begin
  FName:= Aname;
end;

function TCILArg.AsString(BrRq: boolean): String;
begin
  Result:= FName;
  if FAssign <> nil then
    Result:= format('%s',[FAssign.AsString(false)]);
end;

procedure TCILArg.Show(BrRq: boolean);
begin
  if FAssign <> nil then
    PutSFmt('%s',[FAssign.AsString(false)])
  else
    PutS(FName);
end;


procedure TCILArg.AssignExpr(Expr: TCILExpr);
begin
  if FAssign <> nil then
    FAssign.RmRef;
  FAssign:= Expr;
end;

{function TCILArg.Eq(E: TCILExpr): boolean;
begin
  Result:= (E.ClassType = TCILArg) and (TCILArg(E).FName = FName) and
    (TCILArg(E).FAssign = FAssign);
end; }

{ TCILLocal. }

constructor TCILLocal.Create(AName: String);
begin
  FName:= AName;
end;

function TCILLocal.AsString(BrRq: boolean): String;
begin
  Result:= FName;
end;

procedure TCILLocal.Show(BrRq: boolean);
begin
  PutS(FName);
end;

{function TCILLocal.Eq(E: TCILExpr): boolean;
begin
  Result:= (E.ClassType=TCILLocal) and (TCILLocal(E).FName = FName);
end;}

{ TCILAdd. }

class function TCILAdd.OpName: String;
begin
  Result := '+';
end;

class function TCILAdd.Simmetric: boolean;
begin

end;

{ TCILMul. }

class function TCILMul.OpName: String;
begin
  Result := '*';
end;

class function TCILMul.Simmetric: boolean;
begin

end;

{ TCILSub. }

class function TCILSub.OpName: String;
begin
  Result := '-';
end;

class function TCILSub.Simmetric: boolean;
begin

end;

class function TCILShl.OpName: String;
begin
  Result := 'shl';
end;

class function TCILShl.Simmetric: boolean;
begin

end;

{ TCILAssign. }

function TCILAssign.AsString(BrRq: boolean): String;
begin
  if (BrRq) then
    Result:= Format('%s %s %s',[FName,':=',FSource.AsString(false)])
  else
    Result:= Format('%s',[FSource.AsString(false)]);
end;

procedure TCILAssign.Show(BrRq: boolean);
begin
  if (BrRq) then
    PutSFmt('%s %s %s;',[FName,':=',FSource.AsString(false)])
  else
    PutSFmt('%s;',[FSource.AsString(false)]);
end;

constructor TCILAssign.Create(ADest, ASource: TCILExpr);
begin
  FName:= TCILArg(ADest).FName;
  FSource:= ASource;
  FDest:= ADest;
end;

{function TCILAssign.Eq(E: TCILExpr): boolean;
begin

end;}

{ TCILLabel. }

constructor TCILLabel.Create(AName: String);
begin
  FName:= AName;
  FRefCount:= 1;
end;

function TCILLabel.AsString(BrRq: boolean): String;
begin
  Result:= FName+':';
end;

{function TCILLabel.Eq(E: TCILExpr): boolean;
begin

end;}

procedure TCILLabel.Show(BrRq: boolean);
begin
  PutKW(FName+':;');
end;

procedure TCILLabel.RemoveRef;
begin
  if FRefCount < 1 then
    Exit;
  Dec(FRefCount);
end;

procedure TCILLabel.AddRef;
begin
  Inc(FRefCount);
end;


{ TCILRet }

function TCILRet.AsString(BrRq: boolean): String;
begin
  Result:= 'Exit;';
end;

constructor TCILRet.Create();
begin

end;

procedure TCILRet.Show(BrRq: boolean);
begin
  PutS('Exit;')
end;

{ TCILCgt. }

class function TCILCgt.OpName: String;
begin
  Result:= '>';
end;

class function TCILCgt.Simmetric: boolean;
begin
  Result:= False;
end;

{ TCILXor. }

class function TCILXor.OpName: String;
begin
  Result:= 'xor';
end;

class function TCILXor.Simmetric: boolean;
begin
  Result:= False;
end;

{ TCILRem. }

class function TCILRem.OpName: String;
begin
  Result:= 'mod';
end;

class function TCILRem.Simmetric: boolean;
begin
  Result:= False;
end;

{ TCILIsInst }

function TCILIsInst.AsString(BrRq: boolean): String;
begin
  Result:= Format('%s(%s)',[FName, FArg.AsString(BrRq)]);
end;

constructor TCILIsInst.Create(AName: String; AArg: TCILExpr);
begin
  FName:= AName;
  FArg:= AArg;
end;

procedure TCILIsInst.Show(BrRq: boolean);
begin
  PutS(AsString(false));
end;

end.



