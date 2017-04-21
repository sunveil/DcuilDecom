unit CILCtrlFlowGraph;

interface

uses
  Classes, ComCtrls,
  CILOpCode,
  CILCodes,
  DCU_Out,
  DasmMSIL,
  DasmCF,
  SysUtils,
  Dialogs{showMessage},
  CILExpr,
  CILMethodHeader,
  CILStack,
  TypInfo,
  DCURecs,
  DCU32,
  FixUp;


type

	TJumpType =
	(
		/// <summary>
		/// A regular control flow edge.
		/// </summary>
		jtNormal,
		/// <summary>
		/// Jump to exception handler (an exception occurred)
		/// </summary>
		jtJumpToExceptionHandler,
		/// <summary>
		/// Jump from try block to leave target:
		/// This is not a real jump, as the finally handler is executed first!
		/// </summary>
		jtLeaveTry,
		/// <summary>
		/// Jump at endfinally (to any of the potential leave targets).
		/// For any leave-instruction, control flow enters the finally block - the edge to the leave target (LeaveTry) is not a real control flow edge.
		/// EndFinally edges are inserted at the end of the finally block, jumping to any of the targets of the leave instruction.
		/// This edge type is only used when copying of finally blocks is disabled (with copying, a normal deterministic edge is used at each copy of the endfinally node).
		/// </summary>
	  jtEndFinally
	);

  TControlFlowNodeType =
	(
		/// <summary>
		/// A normal node represents a basic block.
		/// </summary>
		ntNormal,
		/// <summary>
		/// The entry point of the method.
		/// </summary>
		ntEntryPoint,
		/// <summary>
		/// The exit point of the method (every ret instruction branches to this node)
		/// </summary>
		ntRegularExit,
		/// <summary>
		/// This node represents leaving a method irregularly by throwing an exception.
		/// </summary>
		ntExceptionalExit,
		/// <summary>
		/// This node is used as a header for exception handler blocks.
		/// </summary>
		ntCatchHandler,
		/// <summary>
		/// This node is used as a header for finally blocks and fault blocks.
		/// Every leave instruction in the try block leads to the handler of the containing finally block;
		/// and exceptional control flow also leads to this handler.
		/// </summary>
		ntFinallyOrFaultHandler,
		/// <summary>
		/// This node is used as footer for finally blocks and fault blocks.
		/// Depending on the "copyFinallyBlocks" option used when creating the graph, it is connected with all leave targets using
		/// EndFinally edges (when not copying); or with a specific leave target using a normal edge (when copying).
		/// For fault blocks, an exception edge is used to represent the "re-throwing" of the exception.
		/// </summary>
		ntEndFinallyOrFault
	);

type

  PCaseSelector = ^TCaseSelector;
  TCaseSelector = record
    Val: integer;
    Next: PCaseSelector;
  end;

type

  PCILCtx = ^TCILCtx;
  TCILCtx = packed record
    Args, Locals: TCILArgs;
    CILStack: TCILStack;
  end;

  TInstruction = class(TCmd)
  protected
    FByteCode: TCILOpCode;
    FExpr: TCILExpr;
    FI4: integer;
    FFix: Integer;
    FFixupRec: PFixupRec;
    FSArgs: array[byte] of LongInt;
    FArgCnt: integer;
    procedure SetArg(index: integer; Value: LongInt);
    function GetArg(index: integer): LongInt;
  public
    constructor Create0(AOfs: integer; ByteCode: TCILOpCode);
    procedure AsString();
    property ByteCode: TCILOpCode read FByteCode;
    property Expr: TCILExpr read FExpr;
    property I4: integer read FI4 write FI4;
    property Fix: integer read FFix write FFix;
    property FixupRec: PFixupRec read FFixupRec write FFixupRec;
    property ArgCnt: integer read FArgCnt write FArgCnt;
    property SArgs[index: integer]: LongInt read GetArg write SetArg;
  end ;

  TPredcessors = class;

  TCtrlFlowNode = class(TCmdSeq)
  protected
    FInCtx: TCILCtx;
    FOutCtx: TCILCtx;
    FInEdges: TList;
    FIncoming: TPredcessors;
    FOutgoing: TList;
    FDominatorTreeChildren: TList;
    FImmediateDominator: TCtrlFlowNode;
    FDominanceFrontier: TCtrlFlowNode;
    FCmdOfs : Cardinal;
    FVisited: boolean;
    FLinesCnt: integer;
    FLabel: TCILLabel;
    FLInd: integer;
    function GetInEdgeCnt: integer;
    function GetInEdges: TList;
    function GetIncoming: TPredcessors;
    function GetOutgoing: TList;
    function GetNext: PCmdSeqRef;
    function GetNextCond: PCmdSeqRef;
    function GetStart: TInstruction;
    function GetEnd: TInstruction;
    function GetExprByOpC(var Instr: TInstruction): boolean;
  public
    FIndex: integer;
    constructor Create(AStart: integer);override;
    constructor Create0();
    procedure Show;
    destructor Destroy;override;
    procedure BuildILAst;
    function GetStr: String;
    procedure AddInRef(CmdSeq: TCtrlFlowNode);
    //function AddCmd(AStart,ASize: Cardinal): TCmd; override;
    property InEdgeCnt : integer read GetInEdgeCnt;
    function RemoveGoToExpr(Item: Pointer): Integer;
    property InEdges : TList read GetInEdges;
    property CmdOfs : Cardinal read FCmdOfs write FCmdOfs;
    property Next : PCmdSeqRef read GetNext;
    property Cond : PCmdSeqRef read GetNextCond;
    property StartOpCode : TInstruction read GetStart;
    property EndOpCode : TInstruction read GetEnd;
    property Incoming : TPredcessors read GetIncoming;
    property Outgoing : TList read GetOutgoing;
    property DominatorTreeChildren: TList read FDominatorTreeChildren;
    property ImmediateDominator: TCtrlFlowNode read FImmediateDominator write FImmediateDominator;
    property DominanceFrontier: TCtrlFlowNode read FDominanceFrontier write FDominanceFrontier;
    property Visited : boolean read FVisited write FVisited;
    property InCtx: TCILCtx read FInCtx write FInCtx;
    property OutCtx: TCILCtx read FOutCtx write FOutCtx;
    property LinesCnt: integer read FLinesCnt write FLinesCnt;
  end;

  TPredcessors = class(TList)
  public
    function GetFirstProcessed: TCtrlFlowNode;
  end;

  TMethodBody = class(TProc)
  protected
    FCtx: TCILCtx;
    destructor Destroy;
  private
    FLInd: integer;
		FRegularExit: TCtrlFlowNode;
    function GetEntryPoint: TCtrlFlowNode;
    function GetRegularExit: TCtrlFlowNode;
    procedure SetEntryPoint(const Value: TCtrlFlowNode);
    procedure SetRegularExit(const Value: TCtrlFlowNode);
  public
    constructor Create(AStart,ASize: integer; Ctx: TCILCtx);
    destructor Free;
    procedure SetState;
    procedure ResetVisited;
    procedure CreateCtrFlowEdges;
    procedure ComputeDominance;
    procedure FindConditions(var Body: TMethodBody);
    procedure BuildAst;
    procedure Show;
    procedure ShowDom;
    procedure RemoveNode(SrcNode, TrgNode: Pointer);
    function GetIndex(I: TCtrlFlowNode): integer;
    property EntryPoint: TCtrlFlowNode read GetEntryPoint write SetEntryPoint;
    property RegularExit: TCtrlFlowNode read GetRegularExit write SetRegularExit;
    property Ctx: TCILCtx read FCtx write FCtx;
  end;

implementation

uses
  CILDisAsm,
  CILHLOp;


{ TPredcessors. }

function TPredcessors.GetFirstProcessed: TCtrlFlowNode;
var
  i: integer;
begin
  for i:=0 to Count-1 do begin
    if TCtrlFlowNode(Items[i]).FVisited=True then begin
      Self.Move(i,0);
      Result:= TCtrlFlowNode(Self.Items[0]);
      Exit;
    end;
  end;
  Result:=nil;
end;

{ TCtrlFlowNode. }

constructor TCtrlFlowNode.Create(AStart: integer);
begin
  inherited Create(AStart);
  FInEdges:= TList.Create;
  FIncoming:= TPredcessors.Create;
  FOutgoing:= TList.Create;
  FDominatorTreeChildren:= TList.Create;
  FIndex:= FCommands.IndexOf(Self);
  FInCtx.Args:= TCILArgs.Create;
  FInCtx.Locals:= TCILArgs.Create;
  FOutCtx.Args:= TCILArgs.Create;
  FOutCtx.Locals:= TCILArgs.Create;
  FInCtx.CILStack:= TCILStack.Create;
  FOutCtx.CILStack:= TCILStack.Create;
  FLinesCnt:= 0;
end;

constructor TCtrlFlowNode.Create0();
begin
  FCommands := TList.Create;
  FInEdges:= TList.Create;
  FIncoming:= TPredcessors.Create;
  FOutgoing:= TList.Create;
  FDominatorTreeChildren := TList.Create;
  FIndex:= FCommands.IndexOf(Self);
  FInCtx.Args:= TCILArgs.Create;
  FInCtx.Locals:= TCILArgs.Create;
  FOutCtx.Args:= TCILArgs.Create;
  FOutCtx.Locals:= TCILArgs.Create;
  FInCtx.CILStack:= TCILStack.Create;
  FOutCtx.CILStack:= TCILStack.Create;
  FLinesCnt:= 0;
  FNext:= nil;
  FNextCond:= nil;
end;


destructor TCtrlFlowNode.Destroy;
begin
  inherited Destroy;
  FInEdges.Free;
  FIncoming.Free;
  FOutgoing.Free;
  FDominatorTreeChildren.Free;
  FInCtx.Args.Free;
  FInCtx.Locals.Free;
  //FOutCtx.Args.Free;
  //FOutCtx.Locals.Free;
  FInCtx.CILStack.Free;
  FOutCtx.CILStack.Free;
end;

procedure TCtrlFlowNode.Show;
var
  i : integer;
  Instr: TInstruction;
begin
  if (FLabel <> nil) and (FLabel.RefCount > 0) then begin
    NL;
    FLabel.Show(false);
  end;
  for i:=0 to Count-1 do begin
    Instr:= TInstruction(FCommands[i]);
    if (Instr.FExpr <> nil) and (Instr.ByteCode.GetCode <> Switch) then begin
       NL;
       Instr.FExpr.Show(true);
    end;
  end;
end;

function GetExpr(Node: TCtrlFlowNode; Cond: TCILExpr; var Body: TMethodBody): boolean;
var
  L, R, C, D: TCtrlFlowNode;
  NewNode, Next, TNode, FNode: TCtrlFlowNode;
  IfTE: TCILIfThenElseBlock;
  IfT: TCILIfThenBlock;
  WhileSt: TCILWhileSt;
  RepeatSt: TCILRepeatSt;
  Cnd: TCILCondition;
  Expr: TCILExpr;
  i, j, ind: integer;
  Instr: TInstruction;
begin
  Result:= False;

  if Node.Outgoing.Count = 2 then begin
    //if-then-else
    if (TCtrlFlowNode(Node.Outgoing.Items[0]).Outgoing.Count = 1) and
    (TCtrlFlowNode(Node.Outgoing.Items[1]).Outgoing.Count = 1) then begin
    //if TCtrlFlowNode(Node.FNext.Tgt).FNext.Tgt = TCtrlFlowNode(Node.FNextCond.Tgt).FNext.Tgt then begin
      L:= TCtrlFlowNode(Node.Outgoing.Items[0]);
      R:= TCtrlFlowNode(Node.Outgoing.Items[1]);
      if TCtrlFlowNode(L.Outgoing.Items[0]) = TCtrlFlowNode(R.Outgoing.Items[0])then begin
        TNode:= TCtrlFlowNode(Node.FNextCond.Tgt);
        TNode.RemoveGoToExpr(TNode.FCommands.Last);
        FNode:= TCtrlFlowNode(Node.FNext.Tgt);
        FNode.RemoveGoToExpr(FNode.FCommands.Last);
        TCtrlFlowNode(Node.FNextCond.Tgt).FLabel.RemoveRef;
        Cnd:= TCILCondition(Cond).Neg;
        IfTE := TCILIfThenElseBlock.Create(Cnd, FNode, TNode);
        //NewNode:= TCtrlFlowNode.Create0;
        //NewNode.Assign(Node);
        //NewNode.LinesCnt:=4;
        TInstruction(Node.FCommands.Last).FExpr:= IfTE;
        {for i:=0 to Node.Incoming.Count-1 do begin
          NewNode.Incoming.Add(Node.Incoming.Items[i]);
          TCtrlFlowNode(Node.Incoming.Items[i]).Outgoing.Remove(Node);
          TCtrlFlowNode(Node.Incoming.Items[i]).Outgoing.Add(NewNode);
        end;}
        for i:=0 to Node.Incoming.Count-1 do begin
          if TCtrlFlowNode(TCtrlFlowNode(Node.Incoming[i]).FNextCond) = Node then
            TCtrlFlowNode(TCtrlFlowNode(Node.Incoming[i]).FNextCond):= Node;
          if TCtrlFlowNode(TCtrlFlowNode(Node.Incoming[i]).FNext.Tgt) = Node then
            TCtrlFlowNode(TCtrlFlowNode(Node.Incoming[i]).FNext.Tgt):= Node;
        end;
        for i:=0 to Node.Outgoing.Count-1 do begin
          Body.Remove(TCtrlFlowNode(Node.Outgoing.Items[i]));
        end;
        C:= TCtrlFlowNode(L.Outgoing.Items[0]);
        Node.Next.Tgt:= C;
        if C.FLabel <> nil then
          C.FLabel.RemoveRef;
        Node.FNextCond.Tgt:= nil;
        Node.Outgoing.Remove(L);
        Node.Outgoing.Remove(R);
        Node.Outgoing.Add(C);
        C.Incoming.Add(Node);
        C.Incoming.Remove(L);
        C.Incoming.Remove(R);
        //Body.Items[Body.IndexOf(Node)]:= NewNode;
        Result:= True;
        Exit;
      end;
    end;

    //if-then
    if TCtrlFlowNode(Node.FNext.Tgt).FNext <> nil then begin
      if TCtrlFlowNode(Node.FNext.Tgt).FNext.Tgt = Node.FNextCond.Tgt then begin
        TNode:= TCtrlFlowNode(Node.FNext.Tgt);
        Cnd:= TCILCondition(Cond).Neg;
        IfTE:= TCILIfThenElseBlock.Create(Cnd, TNode, nil);
        Instr:= TInstruction(Node.FCommands.Last);
        Instr.FExpr:= IfTE;
        //Node.Clear;
        //Node.Add(Instr);
        TInstruction(Node.FCommands.Last).FExpr:=IfTE;
        Node.Outgoing.Remove(Node.FNext.Tgt);
        TCtrlFlowNode(Node.FNextCond.Tgt).Incoming.Remove(Node.FNext.Tgt);
        TCtrlFlowNode(Node.Cond.Tgt).FLabel.RemoveRef;
        if TCtrlFlowNode(Node.Next.Tgt).FLabel <> nil then
          TCtrlFlowNode(Node.Next.Tgt).FLabel.RemoveRef;
        Body.Remove(Node.Next.Tgt);
        Node.Next.Tgt:= Node.Cond.Tgt;
    {if TCtrlFlowNode(Node.FNext.Tgt).FNext <> nil then begin
      if TCtrlFlowNode(Node.FNext.Tgt).FNext.Tgt = Node.FNextCond.Tgt then begin
        TNode:= TCtrlFlowNode(Node.FNext.Tgt);
        Cnd:= TCILCondition(Cond).Neg;
        IfTE:= TCILIfThenElseBlock.Create(Cnd, TNode, nil);
        Instr:= TInstruction(Node.Last);
        Instr.FExpr:= IfTE;
        //Node.Clear;
        //Node.Add(Instr);
        TInstruction(Node.Last).FExpr:=IfTE;
        Node.Outgoing.Remove(Node.FNext.Tgt);
        TCtrlFlowNode(Node.FNextCond.Tgt).Incoming.Remove(Node.FNext.Tgt);
        TCtrlFlowNode(Node.FNextCond.Tgt).Incoming.Remove(Node);
        TCtrlFlowNode(Node.FNextCond.Tgt).Incoming.Add(Node);
        TCtrlFlowNode(Node.FNext.Tgt).Incoming.Add(Node);
        TCtrlFlowNode(Node.FNext.Tgt).Incoming.Remove(Node);
        TCtrlFlowNode(Node.Cond.Tgt).FLabel.RemoveRef;
        //Node.Outgoing.Clear;
        if TCtrlFlowNode(Node.Next.Tgt).FLabel <> nil then
          TCtrlFlowNode(Node.Next.Tgt).FLabel.RemoveRef;
        if TCtrlFlowNode(Node.FNext.Tgt).FNextCond <> nil then
          Node.FNextCond.Tgt:= TCtrlFlowNode(Node.FNext.Tgt).FNextCond.Tgt;
        Body.Remove(Node.Next.Tgt);
        Node.Next.Tgt:= Node.Cond.Tgt;
        Node.Outgoing.Clear;
        Node.Outgoing.Add(Node.FNext.Tgt);
        Node.Outgoing.Add(Node.FNextCond.Tgt);
        //Node.Cond.Tgt:= nil;
        {for i:= 0 to Node.Incoming.Count-1 do begin
          NL;
          PutS('inc');
          TCtrlflowNode(Node.Incoming.Items[i]).Show;
        end;  }
        Result:= True;
        Exit;
      end;
    end;
  end;

  //while
  if Node.FNextCond.Tgt = Node then begin
    NewNode:= TCtrlflowNode.Create0;
    Cnd:= TCILCondition(Cond);
    Instr:= TInstruction(Node.FCommands.Last);
    Node.FCommands.Remove(Node.FCommands.Last);
    Node.FNextCond.Tgt:= nil;
    for i:=0 to Node.Outgoing.Count-1 do begin
      Node.Incoming.Remove(Node.Outgoing.Items[i]);
    end;
    Node.Incoming.Remove(Node);
    Node.Outgoing.Remove(Node);
    Node.FLabel.RemoveRef;
    NewNode.FCommands.Assign(Node.FCommands);
    NewNode.LinesCnt:= 2;
    Expr:= TCILWhileSt.Create(Cnd, NewNode);
    for i:=0 to Node.Incoming.Count-1 do begin
      if TCtrlflowNode(Node.Incoming.Items[i]).Outgoing.Count = 1 then begin
        Expr:= TCILRepeatSt.Create(Cnd, NewNode);
      end;
    end;
    Instr.FExpr:= Expr;
    Node.FCommands.Clear;
    Node.Add(Instr);
    Result:= True;
    Exit;
  end;

  if (Node.Outgoing.Count = 1) and (TCtrlFlowNode(Node.FNext.Tgt).Incoming.Count = 1) then begin
    if Node.Incoming.Count <= 0 then
      Exit;
    if TCtrlFlowNode(Node.Outgoing.Items[0]).Outgoing.Count <= 0 then
      Exit;

    Next:= TCtrlFlowNode(Node.Outgoing.Items[0]);
    Node.Outgoing.Clear;
    Node.Outgoing.Assign(Next.Outgoing);

    for i:= 0 to Node.Outgoing.Count - 1 do begin
      TCtrlFlowNode(Node.Outgoing.Items[i]).Incoming.Remove(Next);
      TCtrlFlowNode(Node.Outgoing.Items[i]).Incoming.Add(Node);
    end;

    for i:=0 to TCtrlFlowNode(Node.FNext.Tgt).Count-1 do begin
      Node.Add(TCtrlFlowNode(Node.FNext.Tgt).FCommands.Items[i]);
    end;

    Body.Remove(Node.FNext.Tgt);
    if (Node.FNextCond <> nil) and (Next.FNextCond <> nil) then
      Node.FNextCond.Tgt:= Next.FNextCond.Tgt;
    if (Node.FNext <> nil) and (Next.FNext <> nil) then
      Node.FNext.Tgt:= Next.FNext.Tgt;
    Result:= True;
    Exit;
  end;

end;


function FindCase(Node: TCtrlFlowNode; var Body: TMethodBody): boolean;
var
  A: TCtrlFlowNode;
  i, j, ind: integer;
  Instr: TInstruction;
  Flag: boolean;
  CaseSt: TCILCaseSt;
begin
  Result:= False;
  Flag:= True;
  A:= TCtrlFlowNode(Node.Outgoing.Items[0]);
  for i:=1 to Node.Outgoing.Count-1 do begin
    if TCtrlFlowNode(TCtrlFlowNode(Node.Outgoing.Items[i]).Outgoing.Items[0]) <> A then
      Flag:= False;
  end;
  if not Flag then
    Exit;
  Instr:= TInstruction(Node.FCommands.Last);
  CaseSt:= TCILCaseSt.Create(Instr.FExpr,Node.Outgoing,Instr.ByteCode);
  CaseSt.Show(false);

  //if Instr.ByteCode.GetCode = switch then
  //  ShowMessage('case');
end;

procedure MergeOneWayB(Node: TCtrlFlowNode; var Body: TMethodBody);
var
  Next: TCtrlFlowNode;
  i: integer;
begin
  //Result:= False;
  if (Node.Outgoing.Count = 1) and (TCtrlFlowNode(Node.FNext.Tgt).Incoming.Count = 1) then begin
    if Node.Incoming.Count <= 0 then
      Exit;
    if TCtrlFlowNode(Node.Outgoing.Items[0]).Outgoing.Count <= 0 then
      Exit;

    Next:= TCtrlFlowNode(Node.Outgoing.Items[0]);
    Node.Outgoing.Clear;
    Node.Outgoing.Assign(Next.Outgoing);

    for i:= 0 to Node.Outgoing.Count - 1 do begin
      TCtrlFlowNode(Node.Outgoing.Items[i]).Incoming.Remove(Next);
      TCtrlFlowNode(Node.Outgoing.Items[i]).Incoming.Add(Node);
    end;

    for i:=0 to TCtrlFlowNode(Node.FNext.Tgt).Count-1 do begin
      Node.Add(TCtrlFlowNode(Node.FNext.Tgt).FCommands.Items[i]);
    end;

    Body.Remove(Node.FNext.Tgt);
    if (Node.FNextCond <> nil) and (Next.FNextCond <> nil) then
      Node.FNextCond.Tgt:= Next.FNextCond.Tgt;
    if (Node.FNext <> nil) and (Next.FNext <> nil) then
      Node.FNext.Tgt:= Next.FNext.Tgt;
    //Result:= True;
    Exit;
  end;
end;


function TCtrlFlowNode.GetExprByOpC(var Instr: TInstruction): boolean;
var
  R, Arg, Arg1 : TCILExpr;
  Cond: TCILExpr;
  IfSt: TCILExpr;
  CS: PCaseSelector;
  D: TDcuRec;
  Args: TDCURec;
  ProcArgs: TList;
  U, OldU: TUnit;
  Fix: PFixupRec;
  TD: TTypeDef;
  Member: TDCURec;
  hDT: integer;

  function GetTypeDeclExpr(Instr: TInstruction): TCILExpr;
  begin
    D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
    if (D <> nil) then begin
      OldU:= CurUnit;
      CurUnit := U;
      OldU:= CurUnit;
    end else
      D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
    if (D.ClassType <> TTypeDecl) then
      Exit;
    if (D <> nil) then CurUnit:= OldU;
  end;

begin
  try
    case Instr.FByteCode.GetCode of
      Ldc_I4: begin
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(Instr.I4,32));
      end;
      Ldc_I4_0: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(0,32));
      end;
      Ldc_I4_1: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(1,32));
      end;
      Ldc_I4_2: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(2,32));
      end;
      Ldc_I4_3: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(3,32));
      end;
      Ldc_I4_4: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(4,32));
      end;
      Ldc_I4_5: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(5,32));
      end;
      Ldc_I4_6: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(6,32));
      end;
      Ldc_I4_7: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(7,32));
      end;
      Ldc_I4_S: begin
        //Instr.FExpr:= TCILIntVal.Create(2,32);
        //Instr.FByteCode.GetVal;
        FInCtx.CILStack.PushExpr(TCILIntVal.Create(Instr.I4,32));
      end;
      Stloc_0: begin
        if FInCtx.Locals.Count > 0 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Locals.GetArg(0),FInCtx.CILStack.PopExpr);
          //FInCtx.Locals.SetArg(Instr.FExpr,0);
      end;
      Stloc_1: begin
        if FInCtx.Locals.Count > 1 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Locals.GetArg(1),FInCtx.CILStack.PopExpr);
          //FInCtx.Locals.SetArg(Instr.FExpr,1);
      end;
      Stloc_2: begin
        if FInCtx.Locals.Count > 2 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Locals.GetArg(2),FInCtx.CILStack.PopExpr);
          //FInCtx.Locals.SetArg(Instr.FExpr,2);
      end;
      Stloc_3: begin
        if FInCtx.Locals.Count > 3 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Locals.GetArg(3),FInCtx.CILStack.PopExpr);
          //FInCtx.Locals.SetArg(Instr.FExpr,3);
      end;
      Stloc_S: begin
        if FInCtx.Args.Count >= Instr.I4 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Locals.GetArg(Instr.I4),FInCtx.CILStack.PopExpr);
      end;
      Starg_S: begin
        if FInCtx.Args.Count >= Instr.I4 then
          Instr.FExpr:= TCILAssign.Create(FInCtx.Args.GetArg(Instr.I4),FInCtx.CILStack.PopExpr);
          //FInCtx.Args.SetArg(Instr.FExpr,ByteCode.I4);
      end;
      Ldloc_0: begin
        FInCtx.CILStack.PushExpr(FInCtx.Locals.GetArg(0));
      end;
      Ldloc_1: begin
        FInCtx.CILStack.PushExpr(FInCtx.Locals.GetArg(1));
      end;
      Ldloc_2: begin
        FInCtx.CILStack.PushExpr(FInCtx.Locals.GetArg(2));
      end;
      Ldloc_3: begin
        FInCtx.CILStack.PushExpr(FInCtx.Locals.GetArg(3));
      end;
      Ldarg_0: begin
        FInCtx.CILStack.PushExpr(FInCtx.Args.GetArg(0));
      end;
      Ldarg_1: begin
        FInCtx.CILStack.PushExpr(FInCtx.Args.GetArg(1));
      end;
      Ldarg_2: begin
        FInCtx.CILStack.PushExpr(FInCtx.Args.GetArg(2));
      end;
      Ldarg_3: begin
        FInCtx.CILStack.PushExpr(FInCtx.Args.GetArg(3));
      end;
      LdStr: begin
        D := TUnit(FixUnit).GetAddrDef(Instr.Fix);
        FInCtx.CILStack.PushExpr(TCILStr.Create((TConstDecl(D).GetName^.GetStr)));
      end;
      LdNull:begin
        FInCtx.CILStack.PushExpr(TCILArg.Create('null'));
      end;
      LdLen: begin
        Arg:= FInCtx.CILStack.PopExpr;
        R:= TCILLabel.Create('Length('+Arg.AsString(false)+');');
        FInCtx.CILStack.PushExpr(R);
      end;
      Ldloc_S: begin
        FInCtx.CILStack.PushExpr(FInCtx.Args.GetArg(Instr.I4));
        WriteLN(FInCtx.Args.GetArg(Instr.I4).AsString(false));
      end;
      Add_: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        R:= TCILAdd.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(R);
      end;
      Mul: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        R:= TCILMul.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(R);
      end;
      Sub: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        R:= TCILSub.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(R);
      end;
      opShl: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        R:= TCILShl.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(R);
      end;
      Beq_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '=');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Ble_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '=<');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Bge_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '>=');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Bge: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '>');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Blt_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '<');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Bne_Un_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '<>');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Bne_Un: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '<>');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Blt: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '<');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Blt_Un_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '<');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Bgt_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg, Arg1, '>');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Br_S: begin
        if TCtrlFlowNode(FNext.Tgt).FLabel = nil then
          TCtrlFlowNode(FNext.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNext.Tgt).FLabel.AddRef;
        IfSt:= TCILGoToUnCond.Create(TCtrlFlowNode(FNext.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Brtrue: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg1, TCILArg.Create('true'), '=');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Brtrue_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg1, TCILArg.Create('0'), '<>');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Brfalse: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg1, TCILArg.Create('false'), '=');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Brfalse_S: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Cond:= TCILCondition.Create(Arg1, TCILArg.Create('0'), '=');
        if TCtrlFlowNode(FNextCond.Tgt).FLabel = nil then
          TCtrlFlowNode(FNextCond.Tgt).FLabel:= TCILLabel.Create('Label'+IntToStr(FIndex))
        else
          TCtrlFlowNode(FNextCond.Tgt).FLabel.AddRef;
        IfSt:= TCILGoTo.Create(Cond,TCtrlFlowNode(FNextCond.Tgt).FLabel);
        Instr.FExpr:= IfSt;
      end;
      Leave_s: begin
        FInCtx.CILStack.Clear;
      end;
      Switch: begin
        Arg:= FInCtx.CILStack.PopExpr;
        //Instr.FExpr:= TCILCase(Arg);
      end;
      Cgt: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        //Instr.FExpr:= TCILCgt.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(TCILCgt.Create(Arg,Arg1));
      end;
      Cgt_Un: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        //Instr.FExpr:= TCILCgt.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(TCILCgt.Create(Arg,Arg1));
      end;
      opXor: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        //Instr.FExpr:= TCILXor.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(TCILRem.Create(Arg,Arg1));
      end;
      Conv_U8: begin
        Arg:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(TCILLabel.Create('Integer('+Arg.AsString(false)+')'));
      end;
      Conv_U4: begin
        Arg:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(TCILLabel.Create('Integer('+Arg.AsString(false)+')'));
      end;
      Conv_U2: begin
        Arg:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(TCILLabel.Create('Integer('+Arg.AsString(false)+')'));
      end;
      Conv_U1: begin
        Arg:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(TCILLabel.Create('Integer('+Arg.AsString(false)+')'));
      end;
      Rem: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
        //Instr.FExpr:= TCILXor.Create(Arg,Arg1);
        FInCtx.CILStack.PushExpr(TCILRem.Create(Arg,Arg1));
      end;
      Call: begin
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
        OldU:= CurUnit;
        CurUnit := U;
        if D = nil then begin
          PutS('Cant find Call');
          Exit;
        end;
        if D.ClassType = TTypeDecl then begin
          IfSt:= TCILCall.Create(TTypeDecl(D).Name^.GetStr,nil);
          FInCtx.CILStack.PushExpr(IfSt);
        end;
        if D.ClassType = TProcDecl then begin
          ProcArgs:= TList.Create;
          Args:= TProcDecl(D).Args;
          while Args<>nil do begin
            ProcArgs.Add(FInCtx.CILStack.PopExpr);
            Args:= TNameDecl(Args.Next);
          end;
          IfSt:= TCILCall.Create(TProcDecl(D).Name^.GetStr,ProcArgs);
          if TProcDecl(D).IsProc then
            Instr.FExpr:= IfSt;
          FInCtx.CILStack.PushExpr(IfSt);
        end;
        CurUnit:= OldU;
      end;
      CallVirt: begin
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
        OldU:= CurUnit;
        CurUnit := U;
        if D = nil then begin
          PutS('Cant find CallVirt');
          Exit;
        end;
        if D.ClassType = TTypeDecl then begin
          //WriteLn('CallVirt' + D.ClassName);
          Member := Nil;
          if (D<>Nil)and(D is TTypeDecl) then
            hDT := TTypeDecl(D).hDef;
          TD := Nil;
          if hDT>=0 then
            TD := U.GetTypeDef(hDT);
          if TD<>Nil then begin
            //PutCh('.');
            if (TD<>Nil)and(TD is TRecBaseDef) then begin
              Member := TRecBaseDef(TD).GetMemberByNum(Instr.FI4-1);
              if Member<>Nil then begin
                if Member is TMethodDecl then begin
                  ProcArgs:= TList.Create;
                  Args:= (TMethodDecl(Member).GetProcDecl).Args;
                  while Args<>nil do begin
                    ProcArgs.Add(FInCtx.CILStack.PopExpr);
                    Args:= TNameDecl(Args.Next);
                  end;
                  WriteLn('TProcDecl Call Virt');
                end;
                IfSt:= TCILCall.Create(TTypeDecl(D).Name^.GetStr + '.' + Member.GetName^.GetStr,ProcArgs);
                FInCtx.CILStack.PushExpr(IfSt);
              end;
                //Member.ShowName;
            end ;
      end ;
        end;
        if D.ClassType = TProcDecl then begin
          ProcArgs:= TList.Create;
          Args:= TProcDecl(D).Args;
          while Args<>nil do begin
            ProcArgs.Add(FInCtx.CILStack.PopExpr);
            Args:= TNameDecl(Args.Next);
          end;
          IfSt:= TCILCall.Create(TProcDecl(D).Name^.GetStr,ProcArgs);
          if TProcDecl(D).IsProc then
            Instr.FExpr:= IfSt
          else
            FInCtx.CILStack.PushExpr(IfSt);
        end;
        CurUnit:= OldU;
      end;
      NewObj: begin
        U:= CurUnit;
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
        OldU:= CurUnit;
        CurUnit := U;
        WriteLn(D.ClassName);
        if D.ClassType = TTypeDecl then begin
          ProcArgs:= TList.Create;
          IfSt:= TCILCall.Create(TTypeDecl(D).Name^.GetStr + CurUnit.GetOfsQualifier(TTypeDecl(D).hDecl,Instr.I4),nil);
          FInCtx.CILStack.PushExpr(IfSt);
        end;
        if D.ClassType = TProcDecl then begin
          ProcArgs:= TList.Create;
          Args:= TProcDecl(D).Args;
          while Args.next<>nil do begin
            ProcArgs.Add(FInCtx.CILStack.PopExpr);
            Args:= TNameDecl(Args.Next);
          end;
          IfSt:= TCILCall.Create(TProcDecl(D).Name^.GetStr,ProcArgs);
          FInCtx.CILStack.PushExpr(IfSt);
        end;
        CurUnit:= OldU;
      end;
      NewArr: begin
        U := CurUnit;
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
        OldU:= CurUnit;
        CurUnit := U;
        //WriteLn(D.ClassName);
        if D.ClassType = TTypeDecl then begin
          Arg:= FInCtx.CILStack.PopExpr;
          FInCtx.CILStack.PushExpr(TCILLabel.Create('arr'));
          IfSt:= TCILLabel.Create('arr:= array of ' + TTypeDecl(D).GetName^.GetStr);
        end;
        CurUnit:= OldU;
      end;
      Ldtoken: begin
        D := TUnit(FixUnit).GetAddrDef(Instr.Fix);
        FInCtx.CILStack.PushExpr(TCILArg.Create(TTypeDecl(D).GetName^.GetStr));
      end;
      Ldfld: begin
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.FixUpRec.Ndx, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.FixUpRec.Ndx);
        WriteLn('LDFLDF:' + D.ClassName);
        OldU:= CurUnit;
        CurUnit := U;
        IfSt:= TCILCall.Create(TTypeDecl(D).Name^.GetStr + U.GetOfsQualifier(TTypeDecl(D).hDef, Instr.I4), nil);
        FInCtx.CILStack.PushExpr(IfSt);
        CurUnit:= OldU;
      end;
      Ldsfld: begin
        D := TUnit(FixUnit).GetAddrDef(Instr.Fix);
        FInCtx.CILStack.PushExpr(TCILArg.Create(TTypeDecl(D).GetName^.GetStr));
      end;
      Stfld: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        Arg:= FInCtx.CILStack.PopExpr;
                
        Instr.FExpr:= TCILAssign.Create(Arg, Arg1);
      end;
      Stsfld: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        D := TUnit(FixUnit).GetGlobalAddrDef(Instr.Fix, U);
        if D = nil then
          D:= TUnit(FixUnit).GetAddrDef(Instr.Fix);
        OldU:= CurUnit;
        CurUnit := U;
        IfSt:= TCILCall.Create(TTypeDecl(D).Name^.GetStr + CurUnit.GetOfsQualifier(TTypeDecl(D).hDecl,Instr.I4),nil);
        Instr.FExpr:= TCILAssign.Create(IfSt, Arg1);
        CurUnit:= OldU;
      end;
      IsInst: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        D := TUnit(FixUnit).GetAddrDef(Instr.Fix);
        FInCtx.CILStack.PushExpr(TCILIsInst.Create(TTypeDecl(D).GetName^.GetStr, Arg1));
      end;
      Conv_i4: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(TCILIsInst.Create('Integer', Arg1));
      end;
      Dup: begin
        Arg1:= FInCtx.CILStack.PopExpr;
        FInCtx.CILStack.PushExpr(Arg1);
        FInCtx.CILStack.PushExpr(Arg1);
      end;
      Ret: begin
        if (FInCtx.CILStack.Count > 0)then
          Instr.FExpr:= TCILAssign.Create(TCILArg.Create('Result'),FInCtx.CILStack.PopExpr);
          //FInCtx.Locals.SetArg(Instr.FExpr,0);
      end;
      Pop: FInCtx.CILStack.PopExpr;
      else begin
        Instr.FExpr:= TCilLabel.Create('{'+Instr.FByteCode.Name+'}');
      end;
    end;
  except
    Writeln('Error');
  end;
end;

procedure TCtrlFlowNode.BuildILAst;
var
  i, j, LInd : integer;
  Instr : TInstruction;
begin
  for i:=0 to Count-1 do begin
    try
      Instr:= TInstruction(FCommands[i]);
      GetExprByOpC(Instr);
      if Instr.FExpr<>nil then
        Inc(FLinesCnt);
    except
      WriteLn('Error');
    end;
  end;
end;

function TCtrlFlowNode.GetStr;
var
  i,j : integer;
  Instr: TInstruction;
  Expr: TCILExpr;
begin
  Result:= '';
  for i:=0 to Count-1 do begin
    Instr:= TInstruction(FCommands[i]);
    if Instr.FExpr <> nil then begin
       Result:= Result+ Instr.FExpr.AsString(true)+ ' ';
    end;
  end;
end;

procedure TCtrlFlowNode.AddInRef(CmdSeq: TCtrlFlowNode);
begin
{  if FInEdges=nil then
    FInEdges := TList.Create;}
  FInEdges.Add(CmdSeq);
end;

{function TCtrlFlowNode.AddCmd(AStart,ASize: Cardinal): TCmd;
begin
  Result := TInstruction.Create0(AStart,ByteCode);
  Add(Result);
  FSize := AStart+ASize-FStart;
end;
}

function TCtrlFlowNode.GetInEdgeCnt: integer;
begin
  if (FInEdges.Count<0) or (FInEdges=nil) then
    Result:=0
  else
    Result := FInEdges.Count;
end;

function TCtrlFlowNode.GetInEdges: TList;
begin
  Result := FInEdges;
end;

function TCtrlFlowNode.GetIncoming: TPredcessors;
begin
  Result := FIncoming;
end;

function TCtrlFlowNode.GetOutgoing: TList;
begin
  Result := FOutgoing;
end;

function TCtrlFlowNode.GetNext: PCmdSeqRef;
begin
  Result := Self.FNext;
end;

function TCtrlFlowNode.GetNextCond: PCmdSeqRef;
begin
  Result:= nil;
  if FNextCond = nil then
    Exit;
  Result := Self.FNextCond;
end;

function TCtrlFlowNode.GetStart: TInstruction;
begin
  Result := FCommands.First;
end;

function TCtrlFlowNode.GetEnd: TInstruction;
begin
  Result := FCommands.Last;
end;

{ TInstruction. }

constructor TInstruction.Create0(AOfs: integer; ByteCode: TCILOpCode);
begin
  inherited Create(AOfs);
  FByteCode := ByteCode;
  FExpr:= TCILExpr.Create();
  FArgCnt:=0;
  FExpr:= nil;
end;

function TInstruction.GetArg(index: integer): LongInt;
begin
  Result:= FSArgs[index];
end;

procedure TInstruction.SetArg(index: integer; Value: LongInt);
begin
  FSArgs[index]:= Value;
end;

procedure TInstruction.AsString();
begin
  PutS(FByteCode.Name);
end;

function IsUnconditionalBranch(ByteCode: TCILOpCode): boolean;
begin
  Result:= False;
  if ByteCode.GetOpCodeType = Prefix then
    Exit;
  case ByteCode.GetFlowControl of
    fcBranch, fcThrow, fcReturn: Result:= True;
    fcCall, fcCond_Branch, fcNext: Result:= False;
  end;
end;

{ TMethodBody. }

constructor TMethodBody.Create(AStart,ASize: integer; Ctx: TCILCtx);
begin
  inherited Create(AStart,ASize);
  FCtx.Args:= TCILArgs.Create;
  FCtx.Locals:= TCILArgs.Create;
  FCtx.CILStack:= TCILStack.Create;
  FCtx:= Ctx;
  FLInd:= 0;
end;

destructor TMethodBody.Destroy;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TCtrlFlowNode(Items[i]).Destroy;
end;

destructor TMethodBody.Free;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TCtrlFlowNode(Items[i]).Destroy;
end;

procedure TMethodBody.SetState;
var
  i: integer;
begin
  for i:=0 to Count-1 do begin
    TCtrlFlowNode(Items[i]).FInCtx.Args.Assign(FCtx.Args);
    TCtrlFlowNode(Items[i]).FInCtx.Locals.Assign(FCtx.Locals);
    TCtrlFlowNode(Items[i]).FInCtx.CILStack.Assign(FCtx.CILStack);
    TCtrlFlowNode(Items[i]).FOutCtx.Args:= TCILArgs.Create;//(FCtx.Args);
    TCtrlFlowNode(Items[i]).FOutCtx.Locals:= TCILArgs.Create;
    TCtrlFlowNode(Items[i]).FOutCtx.CILStack:= TCILStack.Create;
  end;
end;

procedure TMethodBody.ResetVisited;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TCtrlFlowNode(Items[i]).Visited := False;
end;

procedure TMethodBody.CreateCtrFlowEdges;
var
  i: integer;
  CtrFlowNode: TCtrlFlowNode;
  EOpC: TInstruction;
  Part: TProcMemPart;
begin
  for i:=1 to Count-1 do begin
    Part:= GetProcMemPart(i);
    if not (Part is TCtrlFlowNode) then
      Continue;
    CtrFlowNode := TCtrlFlowNode(Part);
    EOpC:= CtrFlowNode.GetEnd;
    if (EOpC = nil) or (IsUnconditionalBranch(EOpC.ByteCode)) then
      Continue;
    CtrFlowNode.Outgoing.Add(TCtrlFlowNode(CtrFlowNode.Next^.Tgt));
    TCtrlFlowNode(CtrFlowNode.Next^.Tgt).Incoming.Add(CtrFlowNode);
  end;
end;

{ A Simple, Fast Dominance Algorithm
  Keith D. Cooper, Timothy J. Harvey, and Ken Kennedy }

procedure TMethodBody.ComputeDominance;

  function Intersect(const b1: TCtrlFlowNode; const b2: TCtrlFlowNode): TCtrlFlowNode;
  var
    //i: integer;
    Finger1, Finger2: TCtrlFlowNode;
  begin
    Finger1:= b1;
    Finger2:= b2;
    while(finger1 <> finger2) do begin
      while(IndexOf(Finger1) > IndexOf(Finger2)) do begin
        Finger1:= Finger1.ImmediateDominator;
      end;
      while(IndexOf(Finger2) > IndexOf(Finger1)) do begin
        Finger2:= Finger2.ImmediateDominator;
      end;
    end;
    Result:= finger1;
  end;

var
  EntryPoint, NewIDom, b, p, Node: TCtrlFlowNode;
  Changed: boolean;
  i, j: integer;
  Part: TProcMemPart;
begin
  Part:= GetProcMemPart(0);
  if not (Part is TCtrlFlowNode) then
    Exit;                      
  EntryPoint:= TCtrlFlowNode(Part);
  EntryPoint.ImmediateDominator := EntryPoint;
  Changed:= True;
  while Changed do begin
    ResetVisited;
    EntryPoint.Visited:= True;
    Changed:= False;
    for i:=1 to Count-1 do begin
      Part:= GetProcMemPart(i);
      if not (Part is TCtrlFlowNode) then
        Continue;
      b:= TCtrlFlowNode(Part);
      NewIDom:= TCtrlFlowNode(b.Incoming.GetFirstProcessed);
      for j:=1 to b.Incoming.Count-1 do begin
        p:= TCtrlFlowNode(b.Incoming.Items[j]);
        if ((p.ImmediateDominator <> nil)) then
          NewIDom := Intersect(p, NewIDom);
      end;
      if b.ImmediateDominator <> NewIDom then begin
        b.ImmediateDominator := NewIDom;
        Changed:= True;
      end;
      b.Visited:= True;
    end;
  end;
  Part:= GetProcMemPart(1);
  if not (Part is TCtrlFlowNode) then
    Exit;
  TCtrlFlowNode(Part).ImmediateDominator:= TCtrlFlowNode(Part);
  for i:= 0 to Count-1 do begin
    Part:= GetProcMemPart(i);
    if not (Part is TCtrlFlowNode) then
      Continue;
    Node:= TCtrlFlowNode(Part);
    if Node.ImmediateDominator <> nil then begin
      if i=1 then
        Continue;
      Node.FImmediateDominator.FDominatorTreeChildren.Add(Node);
    end;
  end;
end;

procedure TMethodBody.FindConditions(var Body: TMethodBody);
var
  Changed: boolean;
  Node: TCtrlFlowNode;
  i, j: integer;
  Cond: TCILExpr;
  Part: TProcMemPart;
begin
  Changed:= True;
  while Changed do begin
  //for j:=0 to 15 do begin
    Changed:= False;
    for i:=Count-1 downto 0 do begin
      if Changed then
        Continue;

      Part:= GetProcMemPart(i);
      if not (Part is TCtrlFlowNode) then
        Continue;
      Node:= TCtrlFlowNode(Part);
      if Node.Count<1 then
        Continue;
      if TInstruction(Node.FCommands.Last).FExpr = nil then
        Continue;
      //if (TInstruction(Node.Last).FExpr).ClassType = TCILGoTo
       if Node.FNextCond <> nil
      then begin
        if TInstruction(Node.FCommands.Last).FExpr.ClassType = TCILGoTo then
          Cond:= TCILGoTo(TInstruction(Node.FCommands.Last).FExpr).Cond
        else if (TInstruction(Node.FCommands.Last).FExpr).ClassType = TCILIfThenElseBlock then
          Cond:= TCILIfThenElseBlock(TInstruction(Node.FCommands.Last).FExpr).Cond
        else if TInstruction(Node.FCommands.Last).FExpr.ClassType = TCILWhileSt then
          Cond:= TCILWhileSt(TInstruction(Node.FCommands.Last).FExpr).Cond
        else if TInstruction(Node.FCommands.Last).FExpr.ClassType = TCILRepeatSt then
          Cond:= TCILRepeatSt(TInstruction(Node.FCommands.Last).FExpr).Cond
        else
          Continue;
        Changed:= GetExpr(Node,Cond,Body);
      end; //else
      //if TInstruction(Node.Last).ByteCode.GetCode = Switch then
        //Changed:= FindCase(Node,Body);
      MergeOneWayB(Node,Body);
      //if Changed then
      //  ShowMessage('detect');
    end;
  end;
end;

procedure TMethodBody.BuildAst;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TCtrlFlowNode(Items[i]).BuildILAst();
end;

procedure TMethodBody.Show;
var
  i: integer;
begin
  for i:=0 to Count-1 do
    TCtrlFlowNode(Items[i]).Show();
end;

procedure TMethodBody.ShowDom;
var
  i, j: integer;
begin
  for i:=0 to Count-1 do begin
    NL; PutS('BB '+IntToStr(i));NL;
    for j:=0 to TCtrlFlowNode(Items[i]).DominatorTreeChildren.Count-1 do begin
      PutS(IntToStr(TCtrlFlowNode(TCtrlFlowNode(Items[i]).DominatorTreeChildren.Items[j]).FIndex));
    end;
  end;
end;

procedure TMethodBody.RemoveNode(SrcNode, TrgNode: Pointer);
var
  i, j: integer;
begin
  for i:= 0 to TCtrlFlowNode(SrcNode).Incoming.Count-1 do begin
    TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).Outgoing.Remove(SrcNode);
    for j:=0 to TCtrlFlowNode(SrcNode).Outgoing.Count-1 do begin
      if TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).FCommands.IndexOf(TCtrlFlowNode(TCtrlFlowNode(SrcNode).Outgoing.Items[j])) = -1 then begin
        TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).Outgoing.Add(TCtrlFlowNode(TCtrlFlowNode(SrcNode).Outgoing.Items[j]));
        TCtrlFlowNode(TCtrlFlowNode(SrcNode).Outgoing.Items[j]).Outgoing.Add(TCtrlFlowNode(SrcNode).Incoming.Items[i]);
      end;
    end;



    {if TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).IndexOf(SrcNode) = -1 then
      TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).Outgoing.Add(TrgNode);

    if TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).FNext.Tgt = SrcNode then
      TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).FNext.Tgt:= TrgNode;

    if TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).FNextCond.Tgt = SrcNode then
      TCtrlFlowNode(TCtrlFlowNode(SrcNode).Incoming.Items[i]).FNextCond.Tgt:= TrgNode; }
  end;
end;

function TMethodBody.GetIndex(I: TCtrlFlowNode): integer;
begin
  Result := IndexOf(I);
end;


function TMethodBody.GetEntryPoint: TCtrlFlowNode;
begin
  Result:= Items[0];
end;

function TMethodBody.GetRegularExit: TCtrlFlowNode;
begin
  Result:= FRegularExit;
end;

procedure TMethodBody.SetEntryPoint(const Value: TCtrlFlowNode);
begin
  Items[0]:= Value;
end;

procedure TMethodBody.SetRegularExit(const Value: TCtrlFlowNode);
begin
  FRegularExit:= Value;
end;

function TCtrlFlowNode.RemoveGoToExpr(Item: Pointer): Integer;
begin
  if (TInstruction(Item).FExpr = nil) or ((TInstruction(Item).FExpr.ClassType <> TCILGoToUnCond))
    then
      Exit;
  Result:=FCommands.Remove(Item);
  Dec(FLinesCnt);
end;

end.
