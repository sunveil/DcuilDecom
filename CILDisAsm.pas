unit CILDisAsm;
(*
The MSIL disassembler main module of the DCU32INT utility
by Alexei Hmelnov.
----------------------------------------------------------------------------
E-Mail: alex@icc.ru
http://hmelnov.icc.ru/DCU/
----------------------------------------------------------------------------

See the file "readme.txt" for more details.

------------------------------------------------------------------------
                             IMPORTANT NOTE:
This software is provided 'as-is', without any expressed or implied warranty.
In no event will the author be held liable for any damages arising from the
use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented, you must not
   claim that you wrote the original software.
2. Altered source versions must be plainly marked as such, and must not
   be misrepresented as being the original software.
3. This notice may not be removed or altered from any source
   distribution.
*)
interface

uses
  DasmDefs,
  FixUp,
  CILOpCode;

type
  PMSILHeader = ^TMSILHeader;
  TMSILHeader = packed record
   //The Fat format - always used (the Tiny one was never observed)
    Flags: Word;
    MaxStack: Word; //Maximum number of items on the operand stack
    CodeSz: Cardinal; //Size in bytes of the actual method body
    LocalVarSigTok: LongInt; //Meta Data token for a signature describing the layout
      //of the local variables for the method.
      //0 means there are no local variables present
  end ;

var
  ByteCode : TCILOpCode;

procedure SetCILDisassembler;

implementation

uses
  DCU_In, DCU_Out, Dialogs {ShowMessage}, SysUtils {IntToStr}, TypInfo;

const

CheckKindTbl: array[$0..$2] of PChar = (
  'typecheck'{0x1},
  'rangecheck'{0x2},
  'nullcheck'{0x4});

type
  PCmdInfo = ^TCmdInfo;
  TCmdInfo = record
    Name: PChar;
    F: integer;
  end ;

  PCmdInfoTbl = ^TCmdInfoTbl;
  TCmdInfoTbl = array[byte] of TCmdInfo;

  PStrTbl = ^TStrTbl;
  TStrTbl = array[byte]of PChar;


function ReadCodeByte(var B: Byte): boolean;
{ This procedure can use fixup information to prevent parsing commands }
{ which contradict fixups }
{Was copied here just in case that something is different with MSIL Fixups}
begin
  Result := ChkNoFixupIn(CodePtr,1);
  if not Result then
    Exit;
  B := Byte(CodePtr^);
  Inc(CodePtr);
  Result := true;
end ;

function ReadCodeInt(var V: integer): boolean;
{ This procedure can use fixup information to prevent parsing commands }
{ which contradict fixups }
begin
  Result := ChkNoFixupIn(CodePtr,4);
  if not Result then
    Exit;
  V := integer(Pointer(CodePtr)^);
  Inc(CodePtr,SizeOf(integer));
  Result := true;
end ;

procedure SkipCode(Size: Cardinal);
begin
  Inc(CodePtr,Size);
end ;

type
  TCmdAction = procedure(CI: TCILOpCode; DP: Pointer; IP: Pointer);

function ProcessCommand(Action: TCmdAction; IP: Pointer): boolean;
var
  opC, opC1: Byte;
  F,Sz, Cnt: integer;
  PCmdTbl: PCmdInfoTbl;
  DP: Pointer;
  CmdTblHi, D: integer;
  Fix: PFixupRec;
begin
  Result := false;
  CodePtr := PrevCodePtr;
  PCmdTbl := @OneByteOpCode;
  CmdTblHi := High(OneByteOpCode);
  if not ReadCodeByte(opC) then
    Exit;
  if opC>CmdTblHi then
    Exit;
  if opC <> $fe then
    ByteCode := OneByteOpCode[opC]
  else begin
    ReadCodeByte(opC1);
    ByteCode := TwoBytesOpCode[opC1];
  end;
  DP := CodePtr;
  Sz := 0;
    case ByteCode.GetOperandType of
      ShortInlineI ,ShortInlineBrTarget, ShortInlineVar, ShortInlineArg: begin
        ByteCode.I4:= Byte(DP^);
        SkipCode(1);
        //if ByteCode.GetOperandType = ShortInlineI then
        //  ByteCode.I4:= ShortInt(DP^);
      end;
      InlineVar, InlineArg: begin
        ByteCode.I4:= Word(DP^);
        SkipCode(2);
      end;
      InlineBrTarget, ShortInlineR, InlineI: begin
        ByteCode.I4:= Integer(DP^);
        SkipCode(4);
        //if ByteCode.GetOperandType = InlineI then
        //  ByteCode.I4:= Integer(DP^);
      end;
      InlineI8, InlineR:
        SkipCode(8);
      InlineSwitch: begin
        if not ReadCodeInt(Sz) then
          Exit;
        Cnt:= Sz;
        ByteCode.ArgCnt:= Cnt;
        while Cnt-1>0 do begin
          Inc(CodePtr,SizeOf(integer));
          ByteCode.SArgs[Cnt-1]:= (CodePtr-CodeBase)+LongInt(DP^);
          Dec(Cnt);
        end ;
        //SkipCode(Sz*SizeOf(integer))
      end;
      InlineSig, InlineString, InlineMethod, InlineTok, InlineType, InlineField:begin
        ByteCode.I4:= Integer(DP^);
        if GetFixupFor(DP,4,false,Fix) then begin
          ByteCode.Fix := Fix^.NDX;
          ByteCode.FixupRec := Fix;
        end;
          //ReportFixup(Fix,D,ShowHeuristicRefs);
        SkipCode(4);
      end;

    end;
  if CodePtr>CodeEnd then
    Exit; //Error
  Action(ByteCode,DP,IP);
  Result := true;
end ;

procedure DoNothing(CI: TCILOpCode; DP: Pointer; IP: Pointer);
begin
end ;

function ReadCommand: boolean;
begin
  PrevCodePtr := CodePtr;
  Result := ProcessCommand(DoNothing,Nil);
end ;

procedure ReportFlags(Flags: integer; Names: PStrTbl; NHi: integer);
var
  i,F: integer;
begin
  F := 1;
  for i:=0 to NHi do begin
    if Flags=0 then
      Exit;
    if Flags and F<>0 then begin
      Flags := Flags and not F;
      PutsFmt('.%s',[Names^[i]]);
    end ;
    F := F shl 1;
  end ;
  if F<>0 then
    PutsFmt('.$%x',[F]);
end ;

procedure ShowCmdPart(CI: TCILOpCode; DP: Pointer; IP: Pointer);
var
  Cnt,D: integer;
  Sep: AnsiChar;
  Fix: PFixupRec;
  Fixed: boolean;
begin
  PutKW(CI.Name);PutS('Pop: ');
  PutKW(GetEnumName(TypeInfo(TStackBehaviour),Ord(CI.GetStackBehaviourPop)));
  PutS('Push: ');
  PutKW(GetEnumName(TypeInfo(TStackBehaviour),Ord(CI.GetStackBehaviourPush)));
  PutS('Type: ');
  PutKW(GetEnumName(TypeInfo(TOperandType),Ord(CI.GetOperandType)));
  case CI.GetOperandType of
   ShortInlineI: PutSFmt(' %d',[ShortInt(DP^)]);
   InlineI: PutSFmt(' %d',[Integer(DP^)]);
   InlineI8: PutSFmt(' $%x%8.8x',[Integer(Pointer(TIncPtr(DP)+4)^),Integer(DP^)]);
   ShortInlineR: begin
     PutSpace;
     PutS(FixFloatToStr(Single(DP^)));
    end ;
   InlineR: begin
     PutSpace;
     PutS(FixFloatToStr(Double(DP^)));
   end ;
   InlineString, InlineSig, InlineTok, InlineType, InlineMethod, InlineField: begin
     D := Integer(DP^);
     Fix := Nil;
     Fixed := false;
     if GetFixupFor(DP,SizeOf(integer),false,Fix)and(Fix<>Nil) then begin
       Fixed := ReportFixup(Fix,D,ShowHeuristicRefs);
     end ;
     if (D=0)and(Fix<>Nil) then
       Exit;
     if Fixed then
       PutS('{+');
     PutSFmt('%d',[D]);
     if Fixed then
       PutS('}');
    end ;
   ShortInlineBrTarget: PutSFmt(' $%x',[(CodePtr-CodeBase)+ShortInt(DP^)]);
   InlineBrTarget: PutSFmt(' $%x',[(CodePtr-CodeBase)+LongInt(DP^)]);
   InlineSwitch: begin
     Cnt := integer(DP^);
     Puts(' ');
     Sep := '[';
     while Cnt>0 do begin
       Inc(TIncPtr(DP),SizeOf(integer));
       PutSFmt('%s$%x',[Sep,(CodePtr-CodeBase)+LongInt(DP^)]);
       Sep := ',';
       Dec(Cnt);
     end ;
     if Sep=',' then
       Puts(']');
    end ;
  end ;
end ;

procedure ShowCommand;
begin
  ProcessCommand(ShowCmdPart,Nil);
end ;

type
  TCmdRefCtx = record
    RegRef: TRegCommandRefProc;
    IPRegRef: Pointer;
    Res: integer;
    CmdOfs: Cardinal;
  end ;

procedure CmdPartRefs(CI: TCILOpCode; DP: Pointer; IP: Pointer);
var
  Cnt: integer;
begin
  with TCmdRefCtx(IP^) do begin
    if CI.GetFlowControl = fcBranch then
      Res := crJmp;
    case CI.GetOperandType of
     ShortInlineBrTarget: begin
       if Res<0 then
         Res := crJCond;
       RegRef(CmdOfs+ShortInt(DP^),Res,IPRegRef);
      end ;
     InlineBrTarget: begin
       if Res<0 then
         Res := crJCond;
       RegRef(CmdOfs+LongInt(DP^),Res,IPRegRef);
      end ;
     InlineSwitch: begin
       Res := crJCond;
       Cnt := integer(DP^);
       while Cnt>0 do begin
         Inc(TIncPtr(DP),SizeOf(integer));
         RegRef(CmdOfs+LongInt(DP^),Res,IPRegRef);
         Dec(Cnt);
       end ;
      end ;
    end ;
  end ;
end ;

function CheckCommandRefs(RegRef: TRegCommandRefProc; CmdOfs: Cardinal;
  IP: Pointer): integer;
var
  Ctx: TCmdRefCtx;
begin
  Ctx.RegRef := RegRef;
  Ctx.IPRegRef := IP;
  Ctx.Res := -1;
  Ctx.CmdOfs := CmdOfs;
  ProcessCommand(CmdPartRefs,@Ctx);
  Result := Ctx.Res;
end ;

procedure SetCILDisassembler;
begin
  SetDisassembler(ReadCommand, ShowCommand,CheckCommandRefs);
end ;

end.
