unit CILOpCodeInfo;

interface

uses
 CILOpCode,
 CILOpCodes,
 CILCodes;

type

  TInfo = class
  public
    constructor Create;virtual;abstract;
  end;

  TOpCodeInfo = class
  private
    FOpCode: TCILOpCode;
    FIsMoveInstruction: boolean;
	  FCanThrow: boolean;
  public
    constructor Create(AOpCode: TCILOpCode; AIsMoveInstruction: boolean; ACanThrow: boolean);
    function IsUnconditionalBranch(Code: TCILCode): boolean;
    //function GetOpCodeInfo(Code : TCILCode): TOpCodeInfo;
    property IsMoveInstruction : boolean read FIsMoveInstruction;
    property CanThrow : boolean read FCanThrow;
  end;

  TOpCodeInfoTbl = class
  public
    constructor Create;
    function GetOpCodeInfo(Code: TCILCode): TOpCodeInfo;
  end;

var
  InfoTbl: TOpCodeInfoTbl;

implementation

var
  OpCodeInfoTbl: array[TCILCode] of TOpCodeInfo;


{ TOpCodeInfo. }

constructor TOpCodeInfo.Create(AOpCode: TCILOpCode; AIsMoveInstruction,
  ACanThrow: boolean);
begin
  FOpCode := AOpCode;
  FIsMoveInstruction := AIsMoveInstruction;
  FCanThrow := ACanThrow;
  OpCodeInfoTbl[FOpCode.GetCode] := Self;
end;

function TOpCodeInfo.IsUnconditionalBranch(Code: TCILCode): boolean;
begin
  Result := False;
  if FOpCode.GetOpCodeType = Prefix then
    Exit;
  case FOpCode.GetFlowControl of
    fcBranch, fcThrow, fcReturn: Result:= True;
    fcNext, fcCall, fcCond_Branch: Result:= False;
  end;
end;

{ TOpCodeInfoTbl. }

constructor TOpCodeInfoTbl.Create;
begin
  TOpCodeInfo.Create(OpCodes.Nop,false,true);
  TOpCodeInfo.Create(OpCodes.Add, false, false);
  TOpCodeInfo.Create(OpCodes.Add_Ovf,false,true);
  TOpCodeInfo.Create(OpCodes.Add_Ovf_Un,false,true);
  TOpCodeInfo.Create(OpCodes.opAnd,false,false);
  TOpCodeInfo.Create(OpCodes.Arglist,false,false);
  TOpCodeInfo.Create(OpCodes.Beq,false,false);
  TOpCodeInfo.Create(OpCodes.Beq_S,false,false);
  TOpCodeInfo.Create(OpCodes.Bge,false,false);
  TOpCodeInfo.Create(OpCodes.Bge_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bge_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bge_Un_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bgt,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bgt_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bgt_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bgt_Un_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ble,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ble_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ble_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ble_Un_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Blt,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Blt_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Blt_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Blt_Un_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bne_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Bne_Un_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Br,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Br_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opBreak,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Brfalse,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Brfalse_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Brtrue,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Brtrue_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opCall,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Calli,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Ceq,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Cgt,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Cgt_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ckfinite,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Clt,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Clt_Un,false,false) { CanThrow = false };
    // conv.<to type>
  TOpCodeInfo.Create(OpCodes.Conv_I1,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_I2,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_I4,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_I8,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_R4,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_R8,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_U1,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_U2,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_U4,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_U8,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_I,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_U,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Conv_R_Un,false,false){ CanThrow = false };
    // conv.ovf.<to type>
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I1,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I2,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I4,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I8,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U1,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U2,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U4,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U8,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U,false,true){ CanThrow = true};
    // conv.ovf.<to type>.un
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I1_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I2_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I4_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I8_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U1_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U2_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U4_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U8_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_I_Un,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Conv_Ovf_U_Un,false,true){ CanThrow = true };

    // TOpCodeInfo.Create(OpCodes.Cpblk){ CanThrow = true }; - no idea whether this might cause trouble for the type system; C# shouldn't use it so I'll disable it
  TOpCodeInfo.Create(OpCodes.opDiv,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Div_Un,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Dup,true,true){ CanThrow = true; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Endfilter,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Endfinally,false,false) { CanThrow = false };
    // TOpCodeInfo.Create(OpCodes.Initblk){ CanThrow = true }; - no idea whether this might cause trouble for the type system; C# shouldn't use it so I'll disable it
    // TOpCodeInfo.Create(OpCodes.Jmp){ CanThrow = true } - We don't support non-local control transfers.
  TOpCodeInfo.Create(OpCodes.Ldarg,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarg_0,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarg_1,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarg_2,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarg_3,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarg_S,true,false) { CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldarga,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldarga_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_M1,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_0,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_1,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_2,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_3,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_4,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_5,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_6,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_7,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_8,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I4_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_I8,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_R4,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldc_R8,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldftn,false,false){ CanThrow = false };
    // ldind.<type>
  TOpCodeInfo.Create(OpCodes.Ldind_I1,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_I2,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_I4,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_I8,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_U1,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_U2,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_U4,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_R4,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_R8,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_I,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Ldind_Ref,false,true) { CanThrow = true };
    // the ldloc exceptions described in the spec can only occur on methods without .localsinit - but csc always sets that flag
  TOpCodeInfo.Create(OpCodes.Ldloc,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloc_0,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloc_1,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloc_2,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloc_3,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloc_S,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Ldloca,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldloca_S,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldnull,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Leave,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Leave_S,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Localloc,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Mul,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Mul_Ovf,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Mul_Ovf_Un,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Neg,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Nop,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opNot,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opOr,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Pop,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opRem,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Rem_Un,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Ret,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opShl,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opShr,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Shr_Un,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Starg,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Starg_S,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stind_I1,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_I2,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_I4,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_I8,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_R4,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_R8,false,true) { CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_I,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stind_Ref,false,true){ CanThrow = true };
  TOpCodeInfo.Create(OpCodes.Stloc,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stloc_0,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stloc_1,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stloc_2,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stloc_3,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.Stloc_S,true,false){ CanThrow = false; IsMoveInstruction = true };
  TOpCodeInfo.Create(OpCodes.opSub,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Sub_Ovf,false,true){ CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Sub_Ovf_Un,false,true) { CanThrow = true};
  TOpCodeInfo.Create(OpCodes.Switch,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.opXor,false,false){ CanThrow = false };
  // CanThrow is true by default - most OO instructions can throw; so we don't specify CanThrow all of the time
  TOpCodeInfo.Create(OpCodes.Box,false,true);
  TOpCodeInfo.Create(OpCodes.Callvirt,false,true);
  TOpCodeInfo.Create(OpCodes.Castclass,false,true);
  TOpCodeInfo.Create(OpCodes.Cpobj,false,true);
  TOpCodeInfo.Create(OpCodes.Initobj,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Isinst,false,false){ CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldelem_Any,false,true);
  // ldelem.<type>
  TOpCodeInfo.Create(OpCodes.Ldelem_I,false,true) ;
  TOpCodeInfo.Create(OpCodes.Ldelem_I1,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_I2,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_I4,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_I8,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_R4,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_R8,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_Ref,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_U1,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_U2,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelem_U4,false,true);
  TOpCodeInfo.Create(OpCodes.Ldelema,false,true);
  TOpCodeInfo.Create(OpCodes.Ldfld,false,true) ;
  TOpCodeInfo.Create(OpCodes.Ldflda,false,true);
  TOpCodeInfo.Create(OpCodes.Ldlen,false,true) ;
  TOpCodeInfo.Create(OpCodes.Ldobj,false,true) ;
  TOpCodeInfo.Create(OpCodes.Ldsfld,false,true);
  TOpCodeInfo.Create(OpCodes.Ldsflda,false,true);
  TOpCodeInfo.Create(OpCodes.Ldstr,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldtoken,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Ldvirtftn,false,true);
  TOpCodeInfo.Create(OpCodes.Mkrefany,false,true);
  TOpCodeInfo.Create(OpCodes.Newarr,false,true);
  TOpCodeInfo.Create(OpCodes.Newobj,false,true);
  TOpCodeInfo.Create(OpCodes.Refanytype,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Refanyval,false,true);
  TOpCodeInfo.Create(OpCodes.Rethrow,false,true);
  TOpCodeInfo.Create(OpCodes.Sizeof,false,false) { CanThrow = false };
  TOpCodeInfo.Create(OpCodes.Stelem_Any,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_I1,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_I2,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_I4,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_I8,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_R4,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_R8,false,true);
  TOpCodeInfo.Create(OpCodes.Stelem_Ref,false,true);
  TOpCodeInfo.Create(OpCodes.Stfld,false,true);
  TOpCodeInfo.Create(OpCodes.Stobj,false,true);
  TOpCodeInfo.Create(OpCodes.Stsfld,false,true);
  TOpCodeInfo.Create(OpCodes.Throw,false,true);
  TOpCodeInfo.Create(OpCodes.Unbox,false,true);
  TOpCodeInfo.Create(OpCodes.Unbox_Any,false,true);
end;

function TOpCodeInfoTbl.GetOpCodeInfo(Code: TCILCode): TOpCodeInfo;
begin

end;

end.
