unit CILMethodHeader;

interface

uses
  Classes,
  CILExpr;

type

  TCILArgs = class(TList)
  public
    procedure AddArg(Expr: TCILExpr; Ind: integer);
    procedure SetArg(Expr: TCILExpr;i: integer);
    function GetArg(Ind: integer): TCILExpr;
    function GetArgsCount: integer;
  end;

implementation

{ TCILArgs. }

procedure TCILArgs.AddArg(Expr: TCILExpr; Ind: integer);
begin
//  TCILArg(Expr).NDX :=Ind;
//  Add(Expr);
  if Count<Ind+1 then
    Count:= Ind+1;
  Put(Ind,Expr);
end;

function TCILArgs.GetArg(Ind: integer): TCILExpr;
begin
  Result:= TCilLabel.Create('ARG');
  if (Ind<0) or (Count<Ind) then
    Exit;
  Result:= TCILExpr(Items[Ind]);
end;

function TCILArgs.GetArgsCount: integer;
begin
  Result:= Count;
end;

procedure TCILArgs.SetArg(Expr: TCILExpr; i: integer);
begin
  Items[i]:= Expr; //.AssignExpr(Expr);
end;

end.
