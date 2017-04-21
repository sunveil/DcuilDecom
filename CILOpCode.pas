unit CILOpCode;

interface

uses
  CILOpCodeTable,
  CILCodes,
  FixUp;

type

  { FlowControl }
  TFlowControl = (
    fcBranch,
    fcBreak,
    fcCall,
    fcCond_Branch,
    fcMeta,
    fcNext,
    fcPhi,
    fcReturn,
    fcThrow
  );

  { OpCodeType }
  TOpCodeType = (
    Annotation,
    Macro,
    Nternal,
    Objmodel,
    Prefix,
    Primitive
  );


  { OperandType }
  TOperandType = (
    InlineBrTarget,
    InlineField,
    InlineI,
    InlineI8,
    InlineMethod,
    InlineNone,
    InlinePhi,
    InlineR,
    InlineSig,
    InlineString,
    InlineSwitch,
    InlineTok,
    InlineType,
    InlineVar,
    InlineArg,
    ShortInlineBrTarget,
    ShortInlineI,
    ShortInlineR,
    ShortInlineVar,
    ShortInlineArg
  );

  { StackBehaviour }
  TStackBehaviour = (
    Pop0,
    Pop1,
    Pop1_pop1,
    Popi,
    Popi_pop1,
    Popi_popi,
    Popi_popi8,
    Popi_popi_popi,
    Popi_popr4,
    Popi_popr8,
    Popref,
    Popref_pop1,
    Popref_popi,
    Popref_popi_popi,
    Popref_popi_popi8,
    Popref_popi_popr4,
    Popref_popi_popr8,
    Popref_popi_popref,
    PopAll,
    Push0,
    Push1,
    Push1_push1,
    Pushi,
    Pushi8,
    Pushr4,
    Pushr8,
    Pushref,
    Varpop,
    Varpush
  );

type

  TCILOpCode = class
  protected
    Op1 : Byte;
    Op2 : Byte;
    Code : TCILCode;
    FlowControl : TFlowControl;
    OpCodeType : TOpCodeType;
    OperandType : TOperandType;
    StackBehaviorPop : TStackBehaviour;
    StackBehaviorPush : TStackBehaviour;
    FI4: integer;
    FFix: Integer;
    FFixupRec: PFixupRec;
    FArgCnt: integer;
    FSArgs: array[byte] of LongInt;
    procedure SetArg(index: integer; Value: LongInt);
    function GetArg(index: integer): LongInt;
  public
    constructor Create(x: integer; y: integer);
    destructor Destroy;
    function Name : String;
    function Size : Byte;
    function GetOp1 : Byte;
    function GetOp2 : Byte;
    function GetVal : integer;
    function GetCode : TCILCode;
		function GetFlowControl : TFlowControl;
		function GetOpCodeType : TOpCodeType;
		function GetOperandType : TOperandType;
		function GetStackBehaviourPop : TStackBehaviour;
 		function GetStackBehaviourPush : TStackBehaviour;
    property I4: integer read FI4 write FI4;
    property Fix: integer read FFix write FFix;
    property ArgCnt: integer read FArgCnt write FArgCnt;
    property FixupRec: PFixupRec read FFixupRec write FFixupRec;
    property SArgs[index: integer]: LongInt read GetArg write SetArg;
  end;

{type

  OpCode =  TCILOpCode;}

type

  PCILInfoTbl = ^TCILInfoTbl;
  TCILInfoTbl = array[byte]of TCILOpCode;

var

  OneByteOpCode : array[Byte] of TCILOpCode;
  TwoBytesOpCode : array[Byte] of TCILOpCode;
  OpCodeNames: array[TCILCode] of string;

implementation

{ TCILOpCode. }

function TCILOpCode.GetCode: TCILCode;
begin
  Result := Code;
end;

function TCILOpCode.GetFlowControl: TFlowControl;
begin
  Result := FlowControl;
end;

function TCILOpCode.GetOp1: Byte;
begin
  Result := Op1;
end;

function TCILOpCode.GetOp2: Byte;
begin
  Result := Op2;
end;

function TCILOpCode.GetOpCodeType: TOpCodeType;
begin
  Result := OpCodeType;
end;

function TCILOpCode.GetOperandType: TOperandType;
begin
  Result := OperandType;
end;

function TCILOpCode.GetStackBehaviourPop: TStackBehaviour;
begin
  Result := StackBehaviorPop;
end;

function TCILOpCode.GetStackBehaviourPush: TStackBehaviour;
begin
  Result := StackBehaviorPush;
end;

function TCILOpCode.GetVal: integer;
begin
  if Op1 = $ff then
    Result := Op2
  else
    Result := Op1 shl 8 and Op2;
end;

function TCILOpCode.Name: String;
begin
  Result := OpCodeNames[Code];
end;

function TCILOpCode.Size: Byte;
begin
  Result := 1;
  if Op1 = $ff then
    Result := 2;
end;

constructor TCILOpCode.Create(x: integer;y:integer);
begin
  Op1 := Byte((x and 255));
  Op2 := Byte((x shr 8 and 255));
  Code := TCILCode(Byte((x shr 16 and 255)));
  FlowControl := TFlowControl((x shr 24 and 255));
  OpCodeType := TOpCodeType((y and 255));
  OperandType := TOperandType((y shr 8 and 255));
  StackBehaviorPop := TStackBehaviour((y shr 16 and 255));
  StackBehaviorPush := TStackBehaviour((y shr 24 and 255));
  if (Op1 = $ff) then
	  OneByteOpCode[Op2] := Self
	else
		TwoBytesOpCode[Op2] := Self;
end;

destructor TCILOpCode.Destroy;
begin
  inherited Destroy;
end;

function TCILOpCode.GetArg(index: integer): LongInt;
begin
  Result:= FSArgs[index];
end;

procedure TCILOpCode.SetArg(index: integer; Value: LongInt);
begin
  FSArgs[index]:= Value;
end;

end.
