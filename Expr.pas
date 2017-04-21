unit Expr;

interface

uses
  SysUtils, Classes,
  RefEl;

type

PValue = ^TValue;
TValue = integer;

type

PExpr = ^TExpr;
TExpr = class(TRefEl)
public
  function AddRef: TExpr;
  function Eval: TValue; virtual; abstract;
  function DependsOn(VN: String): boolean; virtual;
  function Eq(E: TExpr): boolean; virtual; abstract;
  function AsString(BrRq: boolean): String; virtual; abstract;
end;

TValOp = class(TExpr)
protected
  FV: TValue;
public
  constructor Create(AV: TValue);
  function Eval: TValue; override;
  function Eq(E: TExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
end ;

//”нарные операции

TUnOp = class(TExpr)
protected
  FArg: TExpr;
public
  constructor Create(AArg: TExpr);
  destructor Destroy; override;
  class function OpName: String; virtual; abstract;
  function DependsOn(VN: String): boolean; override;
  function AsString(BrRq: boolean): String; override;
end ;

TNEG = class(TUnOp)
public
  class function OpName: String; override;
  function Eval: TValue; override;
end;

TINC = class(TUnOp)
public
  class function OpName: String; override;
  function Eval: TValue; override;
end;

TDEC = class(TUnOp)
public
  class function OpName: String; override;
  function Eval: TValue; override;
end;

//Ѕинарные операции

TBinOp = class(TExpr)
protected
  FArg,FArg1: TExpr;
public
  constructor Create(AArg,AArg1: TExpr); virtual;
  destructor Destroy; override;
  class function OpName: String; virtual; abstract;
  class function Simmetric: boolean; virtual;
  function DependsOn(VN: String): boolean; override;
  function Eq(E: TExpr): boolean; override;
  function AsString(BrRq: boolean): String; override;
end ;

TAssign = class(TBinOp)
public
  constructor Create(AArg,AArg1: TExpr);override;
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
  function AsString(BrRq: boolean): String; override;
end;

TADD = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
  function AsString(BrRq: boolean): String; override;
end;

TSUB = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
  function AsString(BrRq: boolean): String; override;
end;

TOR = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
end;

TXOR = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function AsString(BrRq: boolean): String; override;
  function Eval: TValue; override;
end;

TAND = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
end;

TMUL = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
end;

TDiv = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function Eval: TValue; override;
end;

TCmp = class(TBinOp)
public
  class function OpName: String; override;
  class function Simmetric: boolean; override;
  function AsString(BrRq: boolean): String; override;
  function Eval: TValue; override;
end;

implementation

{ TExpr. }

function TExpr.AddRef: TExpr;
begin
  Result := TExpr(inherited AddRef);
end ;

function TExpr.DependsOn(VN: String): boolean;
begin
  Result := false;
end ;

{ TUnOp. }

constructor TUnOp.Create(AArg: TExpr);
begin
  inherited Create;
  FArg := AArg.AddRef;
end ;

destructor TUnOp.Destroy;
begin
  FArg.RmRef;
  inherited Destroy;
end ;

function TUnOp.DependsOn(VN: String): boolean;
begin
  Result := FArg.DependsOn(VN);
end ;

function TUnOp.AsString(BrRq: boolean): String;
begin
  Result := Format('%s(%s)',[OpName, FArg.AsString(true)]);
end ;

{ TValOp. }

constructor TValOp.Create(AV: TValue);
begin
  inherited Create;
  FV := AV;
end ;

function TValOp.Eval: TValue;
begin
  Result := FV;
end ;

function TValOp.Eq(E: TExpr): boolean;
begin
  Result := (E.ClassType=TValOp)and(FV=TValOp(E).FV);
end ;

function TValOp.AsString(BrRq: boolean): String;
begin
  Result := FloatToStr(FV);
end ;

{ TNegOp. }

class function TNEG.OpName: String;
begin
  Result := '-';
end ;

function TNEG.Eval: TValue;
begin
  Result := -FArg.Eval;
end ;


{ TBinOp. }

constructor TBinOp.Create(AArg,AArg1: TExpr);
begin
  inherited Create;
  FArg := AArg.AddRef;
  FArg1 := AArg1.AddRef;
end ;

destructor TBinOp.Destroy;
begin
  FArg.RmRef;
  FArg1.RmRef;
  inherited Destroy;
end ;

function TBinOp.DependsOn(VN: String): boolean;
begin
  Result := FArg.DependsOn(VN)or FArg1.DependsOn(VN);
end ;

function TBinOp.AsString(BrRq: boolean): String;
begin
  Result := Format('%s%s%s',[FArg.AsString(true), OpName,
    FArg1.AsString(true)]);
  if BrRq then
    Result := Format('(%s)',[Result]);
end ;

function TBinOp.Eq(E: TExpr): boolean;
begin
  Result := false;
  if (E.ClassType<>ClassType) then
    Exit;
  Result := (FArg.Eq(TBinOp(E).FArg))and(FArg1.Eq(TBinOp(E).FArg1));
  if Result or not Simmetric then
    Exit;
  Result := (FArg1.Eq(TBinOp(E).FArg))and(FArg.Eq(TBinOp(E).FArg1));
end ;

class function TBinOp.Simmetric: boolean;
begin
  Result := false;
end ;

{ TAddOp. }

class function TADD.OpName: String;
begin
  Result := '+';
end ;

class function TADD.Simmetric: boolean;
begin
  Result := true;
end ;

function TADD.Eval: TValue;
begin
  Result := FArg.Eval + FArg1.Eval;
end ;

function TADD.AsString(BrRq: boolean): String;
begin
  Result := Format('%s%s%s',[FArg.AsString(true), OpName,
    FArg1.AsString(true)]);
  if BrRq then
    Result := Format('(%s)',[Result]);
end;

{ TSubOp. }

function TSUB.Eval: TValue;
begin
  Result := FArg.Eval - FArg1.Eval;
end;

function TSUB.AsString(BrRq: boolean): String;
begin
  Result := Format('%s%s%s',[FArg.AsString(true), OpName,
    FArg1.AsString(true)]);
  if BrRq then
    Result := Format('(%s)',[Result]);
end;

class function TSUB.OpName: String;
begin
  Result := '-';
end;

class function TSUB.Simmetric: boolean;
begin
  Result := True;
end;

{ TOR. }

function TOR.Eval: TValue;
begin
end;

class function TOR.OpName: String;
begin
  Result := 'or'
end;

class function TOR.Simmetric: boolean;
begin
  Result := True;
end;

{ TXOR. }

function TXOR.Eval: TValue;
begin
end;

class function TXOR.OpName: String;
begin
  Result := 'xor'
end;

function TXOR.AsString(BrRq: boolean): String;
begin
  Result := Format('%s := %s xor %s',[FArg.AsString(False), FArg1.AsString(False)]);
end;

class function TXOR.Simmetric: boolean;
begin
  Result := True;
end;



{ TAND. }

function TAND.Eval: TValue;
begin

end;

class function TAND.OpName: String;
begin
  Result := 'and';
end;

class function TAND.Simmetric: boolean;
begin
  Result := True;
end;

{ TMUL. }

function TMUL.Eval: TValue;
begin

end;

class function TMUL.OpName: String;
begin
  Result := '*';
end;

class function TMUL.Simmetric: boolean;
begin
  Result := True;
end;

{ TDIV. }

function TDIV.Eval: TValue;
begin

end;

class function TDIV.OpName: String;
begin
  Result := '/';
end;

class function TDIV.Simmetric: boolean;
begin
  Result := False;
end;

{ TINC. }

function TINC.Eval: TValue;
begin

end;

class function TINC.OpName: String;
begin
  Result := 'Inc';
end;

{ TDEC. }

function TDEC.Eval: TValue;
begin

end;

class function TDEC.OpName: String;
begin
 Result := 'Dec';
end;

{ TAssign. }

constructor TAssign.Create(AArg,AArg1: TExpr);
begin
  FArg := AArg.AddRef;
  FArg1 := AArg1.AddRef;
  FArg := FArg1;
end;

function TAssign.AsString(BrRq: boolean): String;
begin
  Result := Format('%s',[FArg1.AsString(False)]);
end;

function TAssign.Eval: TValue;
begin
  Result := FArg1.Eval;
end;

class function TAssign.OpName: String;
begin
  Result := ':=';
end;

class function TAssign.Simmetric: boolean;
begin
  Result := False;
end;

{ TCmp. }

class function TCmp.OpName: String;
begin
  Result:='Set';
end;

class function TCmp.Simmetric: boolean;
begin
 Result:=True;
end;

function TCmp.Eval: TValue;
begin

end;

function TCmp.AsString(BrRq: boolean): String;
begin
  Result := Format('Compare %s with %s (modif o..szapc flags)',[FArg.AsString(False),FArg1.AsString(False)]);
end;

end.
