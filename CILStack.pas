unit CILStack;

interface

uses
  SysUtils,
  Variants,
  Classes,
  CILExpr;

type

TCILStack = class(TList)
private
  //FItems: array of TCILExpr;
  //FCnt : integer;
public
  constructor Create;
  procedure PushExpr(FReg: TCILExpr);
  function PopExpr: TCILExpr;
  function PeekExpr: TCILExpr;
  procedure Clear;
  function GetCount: integer;
  destructor Destroy;
end;

implementation

constructor TCILStack.Create;
begin
  inherited Create;
end;

procedure TCILStack.PushExpr(FReg: TCILExpr);
begin
  Add(FReg.AddRef);
end;

function TCILStack.PopExpr: TCILExpr;
begin
  if Count<1 then begin
    Result:= TCILLabel.Create('A');
    Exit;
  end;
  //TCILExpr(Items[Count-1]).RmRef;
  Result:= TCILExpr(Items[Count-1]);
  Delete(Count-1);
end;

function TCILStack.PeekExpr: TCILExpr;
begin
  if Count<1 then
    Exit;
  Result:= TCILExpr(Items[Count-1]);
end;

function TCILStack.GetCount: integer;
begin
  Result:= Count;
end;

procedure TCILStack.Clear;
var
  i: integer;
begin
  for i:=0 to Count-1 do begin
    TCILExpr(Items[i]).Free;
  end;
end;

destructor TCILStack.Destroy;
var
  i: integer;
begin
  for i:=0 to Count-1 do begin
    TCILExpr(Items[i]).Free;
  end;
  inherited Destroy;
end;

end.
