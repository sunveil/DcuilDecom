unit CILHLOp;

interface

uses
  Classes, SysUtils,
  CILExpr,
  CILCtrlFlowGraph,
  DCU_Out,
  DCURecs,
  CILOpCode ;

type

TCILCondition = class(TCILExpr)
protected
  FName: String;
  FA, FB: TCILExpr;
public
  constructor Create(AA,AB: TCILExpr;AName: String);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);
  function Neg: TCILCondition;
end;

TCILCall = class(TCILExpr)
protected
  FName: String;
  FArgs: TList;
public
  constructor Create(AName: String; AArgs: TList);
  function AsString(BrRq: boolean): String;override;
  procedure Show(BrRq: boolean);override;
end;


TCILGoTo = class(TCILExpr)
protected
  FCond: TCILCondition;
  FLAbel: TCILLabel;
public
  constructor Create(ACond: TCILExpr; ALabel: TCILLabel);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
  property Cond: TCILCondition read FCond;
end;

TCILGoToUnCond = class(TCILExpr)
protected
  FLAbel: TCILLabel;
public
  constructor Create(ALabel: TCILLabel);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
end;

TCILCase = class(TCILExpr)
public
  constructor Create;
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean);override;
end;

TCILCaseSt = class(TCILExpr)
protected
  FExpr: TCILExpr;
  FSelector: TList;
  FByteCode: TCILOpCode;
public
  constructor Create(AExpr: TCILExpr; ASelector: TList; AByteCode: TCILOpCode);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
end;

TCILWhileSt = class(TCILExpr)
protected
  FBody: TCtrlFlowNode;
  FCond: TCILCondition;
public
  constructor Create(ACond: TCILCondition; Abody: TCtrlFlowNode);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
  property Cond: TCILCondition read FCond;
end;

TCILRepeatSt = class(TCILExpr)
protected
  FBody: TCtrlFlowNode;
  FCond: TCILCondition;
public
  constructor Create(ACond: TCILCondition; Abody: TCtrlFlowNode);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
  property Cond: TCILCondition read FCond;
end;

TCILIfThenElseBlock = class(TCILExpr)
protected
  FTrue, FFalse: TCtrlFlowNode;
  FCond: TCILCondition;
public
  constructor Create(ACond: TCILCondition; ATrue, AFalse: TCtrlFlowNode);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
  property Cond: TCILCondition read FCond;
end;

TCILIfThenBlock = class(TCILExpr)
protected
  FTrue: TCtrlFlowNode;
  FCond: TCILCondition;
public
  constructor Create(ACond: TCILCondition; ATrue: TCtrlFlowNode);
  function AsString(BrRq: boolean): String; override;
  procedure Show(BrRq: boolean); override;
  property Cond: TCILCondition read FCond;
end;

implementation

{ TCILCondition. }

constructor TCILCondition.Create(AA, AB: TCILExpr; AName: String);
begin
  FA:= AA;
  FB:= AB;
  FName:= AName;
end;

function TCILCondition.AsString(BrRq: boolean): String;
begin
  if (FA = nil) or (FB = nil) then
    Exit;
  Result:= Format('(%s %s %s)',[FA.AsString(true), FName, FB.AsString(true)]);
end;

procedure TCILCondition.Show(BrRq: boolean);
begin
  PutS(AsString(BrRq));
end;

function TCILCondition.Neg: TCILCondition;
var
  Name: String;
begin
  if FName = '=<' then Name:= '>';
  if FName = '>=' then Name:= '<';
  if FName = '<' then Name:= '>=';
  if FName = '>' then Name:= '=<';
  if FName = '=' then Name:= '<>';
  if FName = '<>' then
  Name:= '=';
  Result:= TCILCondition.Create(FA,FB, Name);
end;

{ TCILIfThenElseBlock. }

function TCILIfThenElseBlock.AsString(BrRq: boolean): String;
begin
  Result:= Format('if %s then begin %s end else begin %s end;',[FCond.AsString(false), FTrue.GetStr, FFalse.GetStr]);
end;

procedure TCILIfThenElseBlock.Show(BrRq: boolean);
begin
  PutKW('if');
  if (FCond=nil) then
    PutKW('false')
  else
    PutS(FCond.AsString(false));
  PutKW(' then');
  if (FTrue<>nil) then begin
    if (FTrue.LinesCnt>1) {or (TInstruction(FTrue.Last).Expr.ClassType = TCILIfThenElseBlock) or
      (TInstruction(FTrue.Last).Expr.ClassType = TCILWhileSt) }
    then
      PutKW('begin ');
    ShiftNLOfs(2);
    FTrue.Show;
    ShiftNLOfs(-2);NL;
    if (FTrue.LinesCnt>1){ or (TInstruction(FTrue.Last).Expr.ClassType = TCILIfThenElseBlock) or
      (TInstruction(FTrue.Last).Expr.ClassType = TCILWhileSt) }
    then
      if FFalse=nil then
        PutKW('end;')
      else
        PutKW('end');
  end;
  if FFalse<>nil then begin
    PutKW('else');
    if (FFalse.LinesCnt>1) {or (TInstruction(FFalse.Last).Expr.ClassType = TCILIfThenElseBlock) or
      (TInstruction(FTrue.Last).Expr.ClassType = TCILWhileSt)}
    then
      PutKW('begin ');
    ShiftNLOfs(2);
    FFalse.Show;
    ShiftNLOfs(-2);
    NL;
    if (FFalse.LinesCnt>1) {or (TInstruction(FFalse.Last).Expr.ClassType = TCILIfThenElseBlock) or
      (TInstruction(FTrue.Last).Expr.ClassType = TCILWhileSt)    }
      
    then
      PutKW('end;');
  end;
end;

constructor TCILIfThenElseBlock.Create(ACond: TCILCondition; ATrue, AFalse: TCtrlFlowNode);
begin
  FTrue:= ATrue;
  FFalse:= AFalse;
  FCond:= ACond;
end;

{ TCILIfThenBlock }

function TCILIfThenBlock.AsString(BrRq: boolean): String;
begin

end;

constructor TCILIfThenBlock.Create(ACond: TCILCondition; ATrue: TCtrlFlowNode);
begin
  FTrue:= ATrue;
  FCond:= ACond;
end;

procedure TCILIfThenBlock.Show(BrRq: boolean);
begin
  PutKW('if');
  if (FCond=nil) then
    PutKW('false')
  else
    PutS(FCond.AsString(false));
  PutKW(' then ');
  if (FTrue.LinesCnt>1) then
    PutKW('begin ');
  ShiftNLOfs(2);
  FTrue.Show;
  ShiftNLOfs(-2);NL;
  if (FTrue.LinesCnt>1) then
    PutKW('end ');
end;

{ TCILGoTo }

constructor TCILGoTo.Create(ACond: TCILExpr; ALabel: TCILLabel);
begin
  FCond:= TCILCondition(ACond);
  FLAbel:= ALabel;
end;

function TCILGoTo.AsString(BrRq: boolean): String;
begin

end;

procedure TCILGoTo.Show(BrRq: boolean);
begin
  PutKW('if');
  if (FCond=nil) then
    PutKW('false')
  else
    PutS(FCond.AsString(false));
  PutKW(' then ');
  ShiftNLOfs(2);
  NL;
  PutKW('goto ');FLAbel.Show(false);
  ShiftNLOfs(-2);
end;

{ TCILGoToUnCond }

constructor TCILGoToUnCond.Create(ALabel: TCILLabel);
begin
  FLAbel:= ALabel;
end;

function TCILGoToUnCond.AsString(BrRq: boolean): String;
begin
  Result:= 'goto ' + FLAbel.AsString(false);
end;

procedure TCILGoToUnCond.Show(BrRq: boolean);
begin
  PutKW('goto ');FLAbel.Show(false);
end;

{ TCILRepeatSt. }

constructor TCILRepeatSt.Create(ACond: TCILCondition; ABody: TCtrlFlowNode);
begin
  FCond:= ACond;
  FBody:= ABody;
end;

function TCILRepeatSt.AsString(BrRq: boolean): String;
begin

end;

procedure TCILRepeatSt.Show(BrRq: boolean);
begin
  PutKW('repeat');
  ShiftNLOfs(2);
  if FBody <> nil then
    FBody.Show;
  ShiftNLOfs(-2);
  NL;
  PutKW('until');
  if FCond <> nil then
    PutS(FCond.AsString(false));
  PutS(';');
end;

{ TCILWhileSt. }

constructor TCILWhileSt.Create(ACond: TCILCondition; ABody: TCtrlFlowNode);
begin
  FCond:= ACond;
  FBody:= ABody;
end;

function TCILWhileSt.AsString(BrRq: boolean): String;
begin

end;

procedure TCILWhileSt.Show(BrRq: boolean);
begin
  PutKW('while');
  if FCond <> nil then
    PutS(FCond.AsString(false))
  else
    PutS('true');
  if (FBody.LinesCnt > 1) then
    PutKW(' do begin')
  else
    PutKW('do');
  ShiftNLOfs(2);
  if FBody <> nil then
    FBody.Show;
  ShiftNLOfs(-2);
  NL;
  PutKW('end;');
end;

{ TCILCaseSt. }

constructor TCILCaseSt.Create(AExpr: TCILExpr; ASelector: TList; AByteCode: TCILOpCode);
begin
  FExpr:= AExpr;
  FSelector:= ASelector;
  FByteCode:= AByteCode;
end;

function TCILCaseSt.AsString(BrRq: boolean): String;
begin

end;

procedure TCILCaseSt.Show(BrRq: boolean);
var
  i: integer;
begin
  PutKW('case ');
  FExpr.Show(false);
  PutKW('of');
  NL;
  ShiftNLOfs(2);
    for i:=1 to FByteCode.ArgCnt do begin
      PutSFmt('%d',[FByteCode.SArgs[i]]);
      PutS(': ');
      if TCtrlflowNode(FSelector.Items[i]).LinesCnt > 1 then
        PutKW('begin');
    end;
  ShiftNLOfs(-2);
end;

{ TCILCase }

function TCILCase.AsString(BrRq: boolean): String;
begin

end;

constructor TCILCase.Create;
begin

end;

procedure TCILCase.Show(BrRq: boolean);
begin
  inherited;

end;

{ TCILCall. }

constructor TCILCall.Create(AName: String; AArgs: TList);
begin
  FName:= AName;
  FArgs:= AArgs;
end;

function TCILCall.AsString(BrRq: boolean): String;
var
  i: integer;
  TmpStr, Sep: String;
begin
  if FArgs=nil then begin
    Result:= Format('%s()',[FName]);
    Exit;
  end;
  TmpStr:= '';
  Sep:= '';
  for i:=FArgs.Count-1 downto 0 do begin
    TmpStr:= TmpStr+Sep+TCILArg(FArgs.Items[i]).AsString(false);
    Sep:= ', ';
  end;
  Result:= Format('%s(%s)',[FName,TmpStr]);
end;

procedure TCILCall.Show(BrRq: boolean);
var
  i: integer;
  TmpStr, Sep: String;
begin
  if FArgs=nil then begin
    PutS(Format('%s()',[FName]));
    Exit;
  end;
  TmpStr:= '';
  Sep:= '';
  for i:=FArgs.Count-1 downto 0 do begin
    TmpStr:= TmpStr+Sep+TCILArg(FArgs.Items[i]).AsString(false);
    Sep:= ', ';
  end;
  PutS(Format('%s(%s)',[FName,TmpStr]));
end;

end.
