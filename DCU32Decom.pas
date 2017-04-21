unit DCU32Decom;

interface

uses
  Classes, Dialogs {ShowMessage}, SysUtils {IntToStr},
  DCURecs,
  DCU32,
  DasmDefs,
  DCU_Out,
  DasmX86,
  DasmCF,
  FixUp,
  DasmUtil,
  op,
  SemX86,
  SemExpr,
  Expr,
  CILDisAsm,
  Win64SEH,
  DecomUtils;

type

  TDecomUnit = class(TUnit)
  protected
    procedure DasmCodeBlSeq(Ofs0,BlOfs,BlSz,SzMax: Cardinal; WasPartMsg: Boolean ;
        Proc: TProcDecl); override;
    procedure DasmCodeBlCtlFlow(Ofs0,BlOfs,BlSz: Cardinal; TraceDataFlow: Boolean;
        Proc: TProcDecl); override;
  public
    procedure ShowCodeBl(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl);override;
  end;

  TCtrlFlowNode = class(TCmdSeq)
  protected
    FInEdges: TList;
    FCmdOfs : Cardinal;
    FProcState: TProcState;
    FIdx: integer;
    function GetInEdgeCnt: integer;
    function GetInEdges: TList;
    function GetNext: PCmdSeqRef;
    function GetNextCond: PCmdSeqRef;
    function GetProcState: TProcState;
  public
    constructor Create(AStart: integer);override;
    destructor Destroy;override;
    procedure AddInRef(CmdSeq: TCtrlFlowNode);
    property InEdgeCnt : integer read GetInEdgeCnt;
    property InEdges : TList read GetInEdges;
    property CmdOfs : Cardinal read FCmdOfs write FCmdOfs;
    property Next : PCmdSeqRef read GetNext;
    property Cond : PCmdSeqRef read GetNextCond;
    property ProcState : TProcState read GetProcState write FProcState;
    property Idx: integer read FIdx write FIdx;
  end;

  procedure SetDecompiler;

implementation

uses
  DCUTbl;

{ TDecomUnit. }

type

  TDasmCodeBlState = record
    Proc: TProc;
    Ofs0,BlOfs,CmdOfs,CmdEnd: Cardinal;
    Seq: TCtrlFlowNode;
  end ;

var
  St: TDasmCodeBlState;

procedure TDecomUnit.DasmCodeBlCtlFlow(Ofs0,BlOfs,BlSz: Cardinal; TraceDataFlow: Boolean;
     Proc: TProcDecl);
var
  CmdSz: Cardinal;
  i: integer;
  DP: Pointer;
  Fix0: integer;
var
  Seq1: TCtrlFlowNode;
  hCurSeq: integer;
  MaxSeqSz: Cardinal;
  Part: TProcMemPart;

  procedure ShowNotParsedDump;
  var
    Fix0: integer;
  begin
    if St.CmdEnd>=St.CmdOfs then
      Exit;
    NL;
    Fix0 := GetStartFixup(St.CmdEnd);
    ShowDump(FDataBlPtr+St.CmdEnd,FMemPtr,FMemSize,BlSz+St.Ofs0,St.CmdOfs-St.CmdEnd,
      St.CmdEnd-St.BlOfs+St.Ofs0,St.CmdEnd,0,
      FFixupCnt-Fix0,@FFixupTbl^[Fix0],true,ShowFileOffsets);
  end ;

begin
  DP := GetBlockMem(BlOfs,BlSz,BlSz);
  if DP=Nil then
    Exit;
  St.Ofs0 := Ofs0;
  St.BlOfs := BlOfs;
  St.Proc := TProc.Create(St.Ofs0,BlSz);
  try
    while true do begin
      hCurSeq := St.Proc.GetNotReadySeqNum;
      St.Seq := TCtrlFlowNode(St.Proc.GetProcMemPart(hCurSeq));
      if St.Seq=Nil then
        Break;
      MaxSeqSz := St.Proc.GetMaxMemPartSize(hCurSeq);
      St.CmdOfs := St.Seq.Start+St.BlOfs-St.Ofs0;
      Fix0 := GetStartFixup(St.CmdOfs);
      St.CmdEnd := St.CmdOfs+MaxSeqSz;
      SetCodeRange(FDataBlPtr,TIncPtr(DP)-St.Ofs0+St.CmdOfs-St.BlOfs,St.CmdEnd);
      while true do begin
        if St.CmdOfs>=St.CmdEnd then begin
          St.Proc.ReachedNextS(St.Seq);
          break;
        end ;
        CodePtr := FDataBlPtr+St.CmdOfs;
        SetStartFixupInfo(Fix0);
        if not Disassembler.ReadCommand then
          break;
        CmdSz := CodePtr-PrevCodePtr;
        //St.CmdOfs-St.BlOfs+St.Ofs0
        St.Seq.NewCmd(St.CmdOfs-St.BlOfs+St.Ofs0,CmdSz);
        Inc(St.CmdOfs,CmdSz);
        case Disassembler.CheckCommandRefs(RegCommandRef,St.CmdOfs,@St) of
         crJmp: break;
         crJCond: if St.CmdOfs<St.CmdEnd then begin
           Seq1 := TCtrlFlowNode(St.Proc.AddSeq(St.CmdOfs-St.BlOfs+St.Ofs0));
           St.Seq.SetNext(Seq1);
           St.Seq := Seq1;
          end ;
        end ;
        Fix0 := GetNextFixup(Fix0,St.CmdOfs);
      end ;
    end ;
    St.CmdOfs := St.BlOfs;
    St.CmdEnd := St.BlOfs;
    for i:=0 to St.Proc.Count-1 do begin
      St.Seq := TCtrlFlowNode(St.Proc.GetProcMemPart(i));
      TCtrlFlowNode(St.Seq).FIdx := i;
    end;
    for i:=0 to St.Proc.Count-1 do begin
      St.Seq := TCtrlFlowNode(St.Proc.GetProcMemPart(i));
      St.CmdOfs := St.BlOfs+St.Seq.Start-St.Ofs0;
      //ShowNotParsedDump;
      //ShiftNLOfs(-2);
      //NL;
      //RemOpen0;
      //PutSFmt('// -- Basic Block #%d -- InEdgeCnt %d --',[i, St.Seq.InEdgeCnt]);
      //RemClose0;
      //ShiftNLOfs(2);
      St.CmdEnd := St.CmdOfs+St.Seq.Size;
      NL;
      ShiftNLOfs(2);
      PutSFmt('<node id="%d">',[i]);
      NL;
      ShiftNLOfs(2);
      PutSFmt('<data key="node_content">',[]);
      //DasmCodeBlSeq(St.Seq.Start,St.CmdOfs,St.Seq.Size,BlSz+St.Ofs0, nil);
      ShiftNLOfs(-2);
      NL;
      PutSFmt('</data>',[]);
      NL;
      ShiftNLOfs(-2);
      PutSFmt('</node>',[]);
      //DasmCodeBlSeq(St.Seq.Start,St.CmdOfs,St.Seq.Size,BlSz+St.Ofs0, Proc);
    end;
    for i:=0 to St.Proc.Count-1 do begin
          //St.Seq := TCtrlFlowNode(St.Proc.GetCmdSeq(i));
          if TCtrlFlowNode(St.Seq).Cond <> nil then
        if TCtrlFlowNode(St.Seq.Cond^.Tgt) <> nil then begin
          TCtrlFlowNode(St.Seq.Cond^.Tgt).AddInRef(St.Seq);
          NL;
          PutSFmt('<edge id="%d" source = "%d" target = "%d"/>',[i, TCtrlFlowNode(St.Seq).Idx, TCtrlFlowNode(St.Seq.Cond^.Tgt).Idx]);
        end;
      if TCtrlFlowNode(St.Seq).Next <> nil then
        if TCtrlFlowNode(St.Seq.Next^.Tgt) <> nil then begin
          TCtrlFlowNode(St.Seq.Next^.Tgt).AddInRef(St.Seq);
          NL;
          PutSFmt('<edge id="%d" source = "%d" target = "%d"/>',[i, TCtrlFlowNode(St.Seq).Idx, TCtrlFlowNode(St.Seq.Next^.Tgt).Idx]);
        end;
    end;

    //ShowNotParsedDump;
    St.CmdOfs := St.BlOfs+BlSz;
  finally
    St.Proc.Free;
  end ;
end;

procedure TDecomUnit.DasmCodeBlSeq(Ofs0,BlOfs,BlSz,SzMax: Cardinal; WasPartMsg: Boolean ;
    Proc: TProcDecl);

var
  CmdOfs,OfsInProc,CmdSz: Cardinal;
  DP: Pointer;
  Fix0: integer;
  Ok: boolean;
  Arg, Arg1: TCmArg;
  ProcState : TProcState;
  D : TDCURec;
  U: TUnit;
  Expr: TExpr;

  procedure ShowRegister;
  const
    pcConv: array[0..2]of THBMName = (
      hnEAX, hnEDX, hnECX
    );
  var
    A: TNameDecl;
    i: integer;
  begin
    D.ShowName;PutS('(');
    A:= TProcDecl(D);
    if A=nil then begin
      PutS(')');
      Exit;
    end;
    for i:= 0 to 2 do begin
      PutS(ProcState.GetReg(pcConv[i]).AsString(False));
      if TNameDecl(A).Next = nil then
        Break;
      A:= TNameDecl(TProcDecl(D).Args.Next);
      PutS(', ');
    end;
    PutS(')');
    RemOpen0;PutS('{');
    PutS('Result type: ');
    D:= FTypes[0];
    if D<>Nil then
      TNameDecl(D).ShowName
    else
      PutS('?');
    PutS('}');RemClose0;
    ProcState.rEAX := TSemReg.Create('EAX',32);
end;

  procedure ShowCdecl(D: TProcDecl);
  begin
  end;

  procedure ShowPascal(D: TProcDecl);
  begin
  end;

  procedure ShowStdCall(D: TProcDecl);
  begin
  end;

  procedure ShowSafeCall(D: TProcDecl);
  begin
  end;

begin
  //ProcState := St.Seq.ProcState;
  //ProcState.DefineRegs;
  DP := GetBlockMem(BlOfs,BlSz,BlSz);
  if DP=Nil then
    Exit;
  CmdOfs := BlOfs;
  Fix0 := GetStartFixup(BlOfs);
  if SzMax<=0 then
    SzMax := BlSz+Ofs0;
  SetCodeRange(FDataBlPtr,TIncPtr(DP)-Ofs0,BlSz+Ofs0);
  while true do begin
    NL;
    CodePtr := FDataBlPtr+CmdOfs;
    SetStartFixupInfo(Fix0);
    Ok := Disassembler.ReadCommand;
    if Ok then
      CmdSz := CodePtr-PrevCodePtr
    else if FixUpEnd>PrevCodePtr then
      CmdSz := FixUpEnd-PrevCodePtr
    else
      CmdSz := 1;
    OfsInProc := CmdOfs-BlOfs+Ofs0;
    //ShowDump(FDataBlPtr+CmdOfs,FMemPtr{FOfs0},FMemSize,SzMax-OfsInProc{BlSz+Ofs0},CmdSz,OfsInProc,CmdOfs,
    //  7,FFixupCnt-Fix0,@FFixupTbl^[Fix0],not Ok,ShowFileOffsets);
    //PutCh(' ');
    if not Ok then begin
      PutCh('?');
     end
    else begin
      Disassembler.ShowCommand;
      PutS('\n');
      {case Cmd.hCmd of
        hnMOV: begin
          Arg := Cmd.Arg[1];
          Arg1 := Cmd.Arg[2];
          PutS(' ---> ');
          PutS(ProcState.GetArg(Arg).AsString(False)+':= ');
          St.Seq.FProcState.SetArg(Arg,TAssign.Create(ProcState.GetArg(Arg),ProcState.GetArg(Arg1)));
          PutS(ProcState.GetArg(Arg).AsString(False));
          //ProcState.
        end;
        //PutS('--->');
        hnADD: begin
          Arg := Cmd.Arg[1];
          Arg1 := Cmd.Arg[2];
          PutS(' ---> ');
          PutS(ProcState.GetArg(Arg).AsString(False)+':= ');
          ProcState.SetArg(Arg,TADD.Create(ProcState.GetArg(Arg),ProcState.GetArg(Arg1)));
          PutS(ProcState.GetArg(Arg).AsString(False));
        end;
        hnSUB: begin
          Arg := Cmd.Arg[1];
          Arg1 := Cmd.Arg[2];
          PutS(' ---> ');
          PutS(ProcState.GetArg(Arg).AsString(False)+':= ');
          ProcState.SetArg(Arg,TSUB.Create(ProcState.GetArg(Arg),ProcState.GetArg(Arg1)));
          PutS(ProcState.GetArg(Arg).AsString(False));
        end;
        hnMUL: begin
          Arg := Cmd.Arg[1];
          Arg1 := Cmd.Arg[2];
          PutS(' ---> ');
          PutS(ProcState.GetArg(Arg).AsString(False)+':= ');
          ProcState.SetArg(Arg,TMUL.Create(ProcState.GetArg(Arg),ProcState.GetArg(Arg1)));
          PutS(ProcState.GetArg(Arg).AsString(False));
        end;
        hnRET: begin
          PutS(' ---> ');
          PutS('Result:=');PutS(ProcState.GetReg(hnEAX).AsString(False));
          NL;
          PutS('Exit;');
        end;
        { Delphi calling conventions }
        {hnCALL: begin
          PutS(' ---> ');
          if not FixupOk(Cmd.Arg[1].Fix) then
            Break;
          D := TUnit(FixUnit).GetGlobalAddrDef(Cmd.Arg[1].Fix^.NDX,U);
          if D=nil then
            Break;
          if D.ClassType<>TProcDecl then
            Break;
          case TProcDecl(D).CallKind of
            pcCdecl: ShowCdecl(TProcDecl(D));
            pcPascal: ShowPascal(TProcDecl(D));
            pcStdCall: ShowStdCall(TProcDecl(D));
            pcSafeCall: ShowSafeCall(TProcDecl(D));
            pcRegister: ShowRegister;
          end;
        end;
        hnCMP: begin
          Arg := Cmd.Arg[1];
          Arg1 := Cmd.Arg[2];
          ProcState.SetEFLAG(efCF, True, TCmp.Create(ProcState.GetArg(Arg),ProcState.GetArg(Arg1)));
          RemOpen;
          PutS(TSemRegBit(ProcState.rfCF).GetRef.AsString(False));
          RemClose;
        end;
        hnJ_ : begin
          //PutS(TSemRegBit(ProcState.rfCF).GetRef.AsString(False));
        end;
      end;     }
    end ;
    Dec(BlSz,CmdSz);
    if BlSz<=0 then
      Break;
    Inc(CmdOfs,CmdSz);
    Fix0 := GetNextFixup(Fix0,CmdOfs);
  end ;
end;

procedure TDecomUnit.ShowCodeBl(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl);
var
  CodeSz: Cardinal;
begin
  if IsMSIL or modeI64 then begin
    inherited ShowCodeBl(Ofs0,BlOfs,BlSz,  Proc);
    Exit; //MSIL not supported
  end;
  CodeSz := BlSz;
  OpenAux;
  RemOpen0;
  if Ofs0=0 then
    PutSFmt('//raw[0x%x]',[CodeSz])
  else
    PutSFmt('//raw[0x%x..0x%x]',[Ofs0,Ofs0+CodeSz]);
  if BlOfs<>Cardinal(-1) then
    PutSFmt('at 0x%x',[BlOfs]);
  RemClose0;
  CloseAux;
  if IsMSIL then begin
    case DisAsmMode of
      mCIL: SetCILDisassembler;
      //mMSIL: SetMSILDisassembler;
    end;
  end else
  Set80x86Disassembler{$IFDEF I64}(FPlatform=dcuplWin64{I64}){$ENDIF};
  if DasmMode = dasmCtlFlow then
    SetDecompiler;
  DasmCodeBlCtlFlow(Ofs0,BlOfs,CodeSz, false, Proc);
  if CodeSz<BlSz then begin
    NL;
    PutS('rest:');NL;
    ShowDataBl(Ofs0+CodeSz,BlOfs,Ofs0+BlSz);
  end;
end;

procedure ShowDecomCommand;
begin
  PutS('');
end;

procedure SetDecompiler;
begin
  Disassembler.ShowCommand := ShowCommand;
end;

{ TCtrlFlowNode. }

constructor TCtrlFlowNode.Create(AStart: integer);
begin
  inherited Create(AStart);
  FInEdges:= TList.Create;
  FProcState:= TProcState.Create;
end;

destructor TCtrlFlowNode.Destroy;
begin
  inherited Destroy;
  FInEdges.Free;
end;

procedure TCtrlFlowNode.AddInRef(CmdSeq: TCtrlFlowNode);
begin
  if FInEdges=nil then
    FInEdges := TList.Create;
  FInEdges.Add(CmdSeq);
end;

function TCtrlFlowNode.GetInEdgeCnt: integer;
begin
  Result:= 0;
  if FInEdges = nil then
    Exit;
  Result := FInEdges.Count;
end;

function TCtrlFlowNode.GetInEdges: TList;
begin
  Result := FInEdges;
end;

function TCtrlFlowNode.GetProcState: TProcState;
begin
  Result:= FProcState;
end;

function TCtrlFlowNode.GetNext: PCmdSeqRef;
begin
  Result := Self.FNext;
end;

function TCtrlFlowNode.GetNextCond: PCmdSeqRef;
begin
  Result := Self.FNextCond;
end;

initialization
  //DefaultCmdSeqClass := TCtrlFlowNode{TCtrlFlowNode};
  //TopLevelUnitClass := TDecomUnit{TUnit};

end.
