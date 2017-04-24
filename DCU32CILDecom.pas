unit DCU32CILDecom;

interface

uses
  Classes, Dialogs {ShowMessage}, SysUtils {IntToStr},
  DCURecs, ComCtrls,
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
  CilExpr,
  CILDisAsm,
  DasmMSIL,
  CILMethodHeader,
  CILCtrlFlowGraph,
  CILStack,
  Win64SEH,
  DecomUtils  ;

type

  TDecomCILUnit = class(TUnit)
  protected
    FExcaptionHandlersTbl : TList;
    //procedure DasmCodeBlSeq(Ofs0,BlOfs,BlSz,SzMax: Cardinal; Proc: TProcDecl); override;
    //procedure DasmCodeBlCtlFlow(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl); override;
    procedure SaveGraphMLProc(Ofs0, BlOfs, BlSz: Cardinal; Proc: TProcDecl);

    procedure DasmCodeBlSeq(Ofs0,BlOfs,BlSz,SzMax: Cardinal; WasPartMsg: Boolean ;
    Proc: TProcDecl); override;
    procedure DasmCodeBlCtlFlow(Ofs0,BlOfs,BlSz: Cardinal; TraceDataFlow: Boolean;
        Proc: TProcDecl); override;


  public
    constructor Create;override;
    //procedure ShowCodeBl(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl);override;
    procedure ShowCodeBl(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl);override;
    procedure FillExceptionHandlersTbl(Ofs0,BlOfs,Sz: Cardinal);
  end;

  procedure SetDecompiler;

implementation

uses
  DCUTbl, GUI;

type

  TDasmCodeBlState = record
    Proc: TMethodBody;
    Ofs0,BlOfs,CmdOfs,CmdEnd: Cardinal;
    Seq: TCtrlFlowNode;
  end ;

var
  St: TDasmCodeBlState;

procedure RegCommandRef(RefP: LongInt; RefKind: Byte; IP: Pointer);
var
  {DP: Pointer;
  Ofs: LongInt;}
  RefSeq: TCtrlFlowNode;
begin
  with TDasmCodeBlState(IP^) do begin
    if (RefP>CmdOfs)and(RefP<CmdEnd) then
      CmdEnd := RefP;
    RefSeq := TCtrlFlowNode(Proc.AddSeq(RefP-BlOfs+Ofs0));
    if RefSeq=Nil then
      Exit;
    if RefKind=crJCond then begin
      Seq.SetCondNext(RefSeq);
      RefSeq.AddInRef(Seq);
      Seq.Outgoing.Add(RefSeq);
      RefSeq.Incoming.Add(Seq);
    end else begin
      Seq.SetNext(RefSeq);
      RefSeq.AddInRef(Seq);
      Seq.Outgoing.Add(RefSeq);
      RefSeq.Incoming.Add(Seq);
    end;
  end;
end;

{ TDecomUnit. }

constructor TDecomCILUnit.Create;
begin
  inherited Create;
  FExcaptionHandlersTbl := TList.Create;
end;

procedure TDecomCILUnit.SaveGraphMLProc(Ofs0, BlOfs, BlSz: Cardinal; Proc: TProcDecl);
var
  CmdSz: Cardinal;
  i, j, Ind: integer;
  DP: Pointer;
  Fix0: integer;
  BS: Cardinal;
var
  Seq1,Node, EntryPoint: TCtrlFlowNode;
  hCurSeq: integer;
  MaxSeqSz: Cardinal;
  Cmd : Tcmd;
  Locals, Args: TDcuRec;
  TypeDef: TTypeDef;
  DCURec: TDCURec;
  Ctx: TCILCtx;
  Instr: TInstruction;
  GraphML: TFileStream;
  Part: TProcMemPart;

begin

  BS := BlSz;
  BS := BS + 10;
  DP := GetBlockMem(BlOfs,BS,BS);
  if DP=Nil then
    Exit;
  St.Ofs0 := Ofs0;
  St.BlOfs := BlOfs;
  St.Proc := TMethodBody.Create(St.Ofs0,BlSz,Ctx);
  try
    while true do begin
      hCurSeq := St.Proc.GetNotReadySeqNum;
      St.Seq := TCtrlFlowNode(St.Proc.GetProcMemPart(hCurSeq));
      if St.Seq=Nil then
        break;
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
      St.Proc.RegularExit:= St.Seq;
    end ;
    St.CmdOfs := St.BlOfs;
    St.Proc.CreateCtrFlowEdges;
    for i:=0 to St.Proc.Count-1 do begin
      Part:= St.Proc.GetProcMemPart(i);
      if not (Part is TCtrlFlowNode) then
        Continue;
      St.Seq:= TCtrlFlowNode(Part);
      St.Seq.FIndex:= St.Proc.GetIndex(St.Seq);
      St.CmdOfs := St.BlOfs+St.Seq.Start-St.Ofs0;
      St.CmdEnd := St.CmdOfs+St.Seq.Size;
      DasmCodeBlSeq(St.Seq.Start,St.CmdOfs,St.Seq.Size,BlSz+St.Ofs0, false, Proc);
      St.CmdEnd := St.CmdOfs+St.Seq.Size;
    end;
    St.CmdOfs := St.BlOfs+BlSz;
  finally
    St.Proc.Free;
  end ;
end;

procedure TDecomCILUnit.DasmCodeBlCtlFlow(Ofs0,BlOfs,BlSz: Cardinal; TraceDataFlow: Boolean;
    Proc: TProcDecl);
var
  CmdSz: Cardinal;
  i, j, Ind: integer;
  DP: Pointer;
  Fix0: integer;
  BS: Cardinal;
var
  Seq1,Node, EntryPoint: TCtrlFlowNode;
  hCurSeq: integer;
  MaxSeqSz: Cardinal;
  Cmd : Tcmd;
  Locals, Args: TDcuRec;
  TypeDef: TTypeDef;
  DCURec: TDCURec;
  Ctx: TCILCtx;
  Instr, PrevInstr: TInstruction;
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

  function GetDeclNdx(L: TDCURec): integer;
  begin
    if (L is TLocalDecl)and(TLocalDecl(L).GetTag<>arFld) then
      Result := TLocalDecl(L).Ndx
    else
      Result := -1;
  end;

  var
    GraphML: TFileStream;

begin
  //init context
  Ctx.Args:= TCIlArgs.Create;
  Ctx.Locals:= TCIlArgs.Create;
  Ctx.CILStack:= TCILStack.Create;
  Locals:= Proc.Locals;
  while Locals <> nil do begin
    Ind:= GetDeclNdx(Locals);
    if Ind>=0 then begin
      if Ord(Locals.GetName^.GetStr[1]) = 1 then
        Ctx.Locals.AddArg(TCILArg.Create('LocVar'),Ind)
      else
        Ctx.Locals.AddArg(TCILArg.Create(Locals.GetName^.GetStr),Ind);
    end;
    Locals:= TNameDecl(Locals.Next);
  end;
  Args:= Proc.Args;
  Ind:= 0;
  while Args <> nil do begin
    Ctx.Args.Add(TCILArg.Create(Args.GetName^.GetStr));
    Args:= TNameDecl(Args.Next);
    Inc(Ind);
  end;
  BS := BlSz;
  BS := BS + 10;
  DP := GetBlockMem(BlOfs,BS,BS);
  if DP=Nil then
    Exit;
  St.Ofs0 := Ofs0;
  St.BlOfs := BlOfs;
  St.Proc := TMethodBody.Create(St.Ofs0,BlSz,Ctx);
  try
    EntryPoint:= TCtrlFlowNode.Create0;
    St.Proc.Add(EntryPoint);
    while true do begin
      hCurSeq := St.Proc.GetNotReadySeqNum;
      St.Seq := TCtrlFlowNode(St.Proc.GetProcMemPart(hCurSeq));
      if St.Seq=Nil then
        break;
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
        Instr:= TInstruction.Create0(St.CmdOfs-St.BlOfs+St.Ofs0, ByteCode);
        PrevInstr:= Instr;
        Instr.IsProc:= false;
        if ByteCode.Name = 'pop' then begin
          PrevInstr.IsProc:= true;   
        end;
        St.Seq.AddCmd(Instr,CmdSz);
        Instr.I4:= Instr.ByteCode.I4;
        Instr.Fix:= Instr.ByteCode.Fix;
        Instr.FixupRec:= Instr.ByteCode.FixupRec;
        for i:=0 to Instr.ByteCode.ArgCnt - 1 do
          Instr.SArgs[i]:= Instr.ByteCode.SArgs[i];

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
      St.Proc.RegularExit:= St.Seq;
    end ;
    St.CmdOfs := St.BlOfs;
    St.Proc.CreateCtrFlowEdges;
    for i:=0 to St.Proc.Count-1 do begin
      Part:= St.Proc.GetProcMemPart(i);
      if not (Part is TCtrlFlowNode) then
        Continue;                
      St.Seq:= TCtrlFlowNode(Part);
      St.Seq.FIndex:= St.Proc.GetIndex(St.Seq);
      St.CmdOfs := St.BlOfs+St.Seq.Start-St.Ofs0;
      ShowNotParsedDump;
      ShiftNLOfs(-2);
      NL;
      RemOpen0;
      PutSFmt('// -- Basic Block #%d -- Incoming %d --',[i, St.Seq.Incoming.Count]);
      PutSFmt(' // -- Outgoing %d --',[St.Seq.Outgoing.Count]);
      PutSFmt(' // -- Index %d --',[TCtrlFlowNode(St.Proc.GetProcMemPart(i)).FIndex]);
      for j:=0 to St.Seq.Incoming.Count-1 do begin
        if St.Proc.GetIndex(TCtrlFlowNode(St.Seq.Incoming[j])) > St.Proc.GetIndex(TCtrlFlowNode(St.Proc.GetProcMemPart(i))) then begin
          PutSFmt(' // -- Loop Start: %d End: %d --',[i, St.Proc.GetIndex(TCtrlFlowNode(St.Seq.Incoming[j]))]);
          Break;
        end;
      end;
      RemClose0;
      ShiftNLOfs(2);
      St.CmdEnd := St.CmdOfs+St.Seq.Size;
      DasmCodeBlSeq(St.Seq.Start,St.CmdOfs,St.Seq.Size,BlSz+St.Ofs0,false,nil);
      St.CmdEnd := St.CmdOfs+St.Seq.Size;
    end;

    St.CmdOfs := St.BlOfs+BlSz;

    St.Proc.SetState;
    St.Proc.ComputeDominance;
    St.Proc.ShowDom;
    St.Proc.BuildAst;
    St.Proc.FindConditions(St.Proc);
    St.Proc.Show;
  finally
    St.Proc.Free;
  end ;
end;

procedure TDecomCILUnit.DasmCodeBlSeq(Ofs0,BlOfs,BlSz,SzMax: Cardinal; WasPartMsg: Boolean ;
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
  Expt: TExpr;
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
    SetStartFixupInfo(Fix0);
    if Ok then
      CmdSz := CodePtr-PrevCodePtr
    else if FixUpEnd>PrevCodePtr then
      CmdSz := FixUpEnd-PrevCodePtr
    else
      CmdSz := 1;
    OfsInProc := CmdOfs-BlOfs+Ofs0;
    ShowDump(FDataBlPtr+CmdOfs,FMemPtr{FOfs0},FMemSize,SzMax-OfsInProc{BlSz+Ofs0},CmdSz,OfsInProc,CmdOfs,
      7,FFixupCnt-Fix0,@FFixupTbl^[Fix0],not Ok,ShowFileOffsets);
    PutCh(' ');
    if not Ok then begin
      PutCh('?');
     end
    else begin
      SetStartFixupInfo(Fix0);
      Disassembler.ShowCommand;
    end ;
    Dec(BlSz,CmdSz);
    if BlSz<=0 then
      Break;
    Inc(CmdOfs,CmdSz);
    Fix0 := GetNextFixup(Fix0,CmdOfs);
  end;
end;

procedure TDecomCILUnit.FillExceptionHandlersTbl(Ofs0,BlOfs,Sz: Cardinal);
var
  DP: Pointer;
  Rest,Al,Sz0,ElSz: Cardinal;
  IsFat: Boolean;
  F,TblSz: LongInt;
  ECF: PMSILFatExcClause;
  ECBuf: TMSILFatExcClause;
  ECS: PMSILSmallExcClause;
begin
  Al := ((Ofs0+3)and not 3)-Ofs0; //align to 4
  if Al+4>Sz then
    Exit;
  Inc(Ofs0,Al);
  Sz0 := Sz;
  Dec(Sz,Al);
  DP := GetBlockMem(BlOfs+Ofs0,Sz,Rest);
  if DP=Nil then
    Exit;
  repeat
    F := LongInt(DP^);
    if F and $3<>CorILMethod_Sect_EHTable then
      break;
    IsFat := (F and CorILMethod_Sect_FatFormat)<>0;
    if IsFat then
      ElSz := SizeOf(TMSILFatExcClause)
    else
      ElSz := SizeOf(TMSILSmallExcClause);
    TblSz := (F shr 8)and $FFFFFF;
    if (TblSz<SizeOf(LongInt))or(TblSz>Sz)or(TblSz mod ElSz<>SizeOf(LongInt)) then
      break;
    Dec(Sz,TblSz);
    Inc(TIncPtr(DP),SizeOf(LongInt));
    Dec(TblSz,SizeOf(LongInt));
    while TblSz>0 do begin
      if IsFat then
        ECF := DP
      else begin
        ECS := DP;
        ECBuf.Flags := ECS^.Flags;
        ECBuf.TryOffset := ECS^.TryOffset;
        ECBuf.TryLength := ECS^.TryLength;
        ECBuf.HandlerOffset := ECS^.HandlerOffset;
        ECBuf.HandlerLength := ECS^.HandlerLength;
        ECBuf.ClassToken := ECS^.ClassToken;
       // ECBuf.FilterOffset := ECS^.FilterOffset;
        ECF := @ECBuf;
      end ;
      NL;
      Inc(TIncPtr(DP),ElSz);
      Dec(TblSz,ElSz);
    end ;
    FExcaptionHandlersTbl.Add(ECF);
  until F and CorILMethod_Sect_MoreSects=0;
end;

procedure TDecomCILUnit.ShowCodeBl(Ofs0,BlOfs,BlSz: Cardinal; Proc: TProcDecl);
var
  MSILHdr: PMSILHeader;
  Sz,CodeSz: Cardinal;
  D: TDCURec;
  S: String;
  ProcCnt: Integer;
  TN: TTreeNode;
begin
  if modeI64 or (DisAsmMode = mMSIL) then begin
    inherited ShowCodeBl(Ofs0,BlOfs,BlSz, Proc);
    Exit;
  end;
 // D := TUnit(self).DeclList.Next;
 // PutS(D.GetName^.GetStr);
  CodeSz := BlSz;
  if IsMSIL then begin
    if BlSz-Ofs0<=SizeOf(TMSILHeader) then begin
      NL;
      ShowDataBl(Ofs0,BlOfs,Ofs0+BlSz);
      Exit; //Wrong size
    end ;
    {NL;
    ShowDataBl(Ofs0,BlOfs,Ofs0+BlSz); //!!!Temp
    NL;}
    //A:= TProcDecl(D).Args;
    MSILHdr := GetBlockMem(BlOfs+Ofs0,SizeOf(TMSILHeader),Sz);
    //PutS('Size: '+IntToStr(MSILHdr^.Flags and $F000));
    if MSILHdr=Nil then begin
      ShowDataBl(Ofs0,BlOfs,Ofs0+BlSz);
      Exit; //Error reading MSIL header
    end ;
    if Ofs0=Cardinal(-1) then
      Ofs0 := 0;
   //1st 3 dwords - some info about proc.
    CodeSz := MSILHdr^.CodeSz;
    if CodeSz>BlSz then
      CodeSz := BlSz; //Just in case
    PutsFmt('[Flags:%4.4x,MaxStack:%d,CodeSz:%x,LocalVarSigTok:%d]',[MSILHdr^.Flags,MSILHdr^.MaxStack,MSILHdr^.CodeSz,MSILHdr^.LocalVarSigTok]);
    NL;
//    Inc(Ofs0,SizeOf(TMSILHeader));
    Inc(BlOfs,SizeOf(TMSILHeader));
    Dec(BlSz,SizeOf(TMSILHeader));
  end ;
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
  S := GetDCURecStr(Proc,Proc.hDecl,false);
  TN:= TTreeNode.Create(GUI.DCU2INT.TVProc.Items);
  TN.Text:= S;
  GUI.DCU2INT.TVProc.Items.Add(TN, S).Data:= TObject(Writer.OutLineNum);
  if IsMSIL then begin
    case DisAsmMode of
      mCIL: SetCILDisassembler;
      mMSIL: SetMSILDisassembler;
      mX86: SetCILDisassembler;
    end;
  end else
    Set80x86Disassembler{$IFDEF I64}(FPlatform=dcuplWin64{I64}){$ENDIF};
  //Proc.Locals;
  case DasmMode of
   dasmSeq: DasmCodeBlSeq(Ofs0,BlOfs,CodeSz,0, false,Proc);
   dasmCtlFlow: DasmCodeBlCtlFlow(Ofs0,BlOfs,CodeSz, false, Proc);
  end ;
  if CodeSz<BlSz then begin
    NL;
    PutS('rest:');NL;
    ShowDataBl(Ofs0+CodeSz,BlOfs{+CodeSz},Ofs0+BlSz);
    FillExceptionHandlersTbl(Ofs0+CodeSz,BlOfs,Ofs0+BlSz);
  end;
end;

procedure ShowDecomCommand;
begin
  PutS('');
end;

procedure SetDecompiler;
begin
  //Disassembler.ShowCommand := ShowCommand;
end;

{ TCtrlFlowNode. }

{constructor TCtrlFlowNode.Create(AStart: integer);
begin
  inherited Create(AStart);
  FInEdges:= TList.Create;
end;

destructor TCtrlFlowNode.Destroy;
begin
  inherited Destroy;
  FInEdges.Free;
end;

procedure TCtrlFlowNode.AsString;
begin
//  NL;
//  PutS(IntToStr(FSize));
end;

procedure TCtrlFlowNode.AddInRef(CmdSeq: TCtrlFlowNode);
begin
{  if FInEdges=nil then
    FInEdges := TList.Create;}
 { FInEdges.Add(CmdSeq);
end; }

{function TCtrlFlowNode.GetInEdgeCnt: integer;
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

function TCtrlFlowNode.GetNext: PCmdSeqRef;
begin
  Result := Self.FNext;
end;

function TCtrlFlowNode.GetNextCond: PCmdSeqRef;
begin
  Result := Self.FNextCond;
end;        }


initialization
  DefaultCmdSeqClass := TCtrlFlowNode{TCtrlFlowNode};
  //TopLevelUnitClass := TDecomCILUnit{TUnit};

end.
