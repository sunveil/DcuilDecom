unit Stack;

interface

uses
  SysUtils,
  Variants,
  Classes,
  Expr;

type

TStack = class
private
  FItems: array of TExpr;
  FCnt : integer;
public
  constructor Create;
  procedure Push(var FReg: TExpr);
  function Pop: TExpr;
  function Peek: TExpr;
  procedure Clear;
  function GetCount: integer;
  property Count: integer read GetCount;
  destructor Destroy;
end;

implementation

constructor TStack.Create;
begin
  FCnt := 0;
end;

procedure TStack.Push(var FReg: TExpr);
begin
  Inc(FCnt);
  SetLength(FItems,FCnt);
  FItems[FCnt-1] := FReg;
  FReg.AddRef;
end;

function TStack.Pop: TExpr;
begin
  if FCnt <= 0 then begin
    Exit;
    Result := nil;
  end;
  Result:= FItems[FCnt-1];
  SetLength(FItems,FCnt-1);
end;

function TStack.Peek: TExpr;
begin
  if FCnt = 0 then begin
    Result := nil;
    Exit;
  end;
  Result := FItems[FCnt-1];
end;

function TStack.GetCount: integer;
begin
  Result := FCnt;
end;

procedure TStack.Clear;
begin
  SetLength(FItems,0);
end;

destructor TStack.Destroy;
begin
  Clear;
  inherited Destroy;
end;

end.
