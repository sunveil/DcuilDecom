unit CILInstructions;

interface

uses
  CILOpCodes,
  CILOpCode,
  CILSequencePoint;

type

	TInstruction = class
  protected
    FOffset : Integer;
		FOpCode : TCILOpCode;
		FOperand : TObject;
		FPrevious : TInstruction;
		FNext : TInstruction;
    FSequencePoint : TSequencePoint;
    function GetOffset: Integer;
    function GetOpCode: TCILOpCode;
    function GetOperand: TObject;
    function GetPrevious: TInstruction;
    function GetNext: TInstruction;
    function GetSequencePoint: TSequencePoint;
    procedure SetOffset(AOffset: Integer);
    procedure SetOpCode(AOpCode: TCILOpCode);
    procedure SetOperand(AOperand: TObject);
    procedure SetPrevious(APrevious: TInstruction);
    procedure SetNext(ANext: TInstruction);
    procedure SetSequencePoint(ASequencePoint: TSequencePoint);
  public
    function GetSize : Integer;
    property Offset: Integer read GetOffset write SetOffset;
    property OpCode: TCILOpCode read GetOpCode write SetOpCode;
    property Operand: TObject read GetOperand write SetOperand;
    property Previous: TInstruction read GetPrevious write SetPrevious;
    property Next: TInstruction read GetNext write SetNext;
    property SequencePoint: TSequencePoint read GetSequencePoint write SetSequencePoint;
  end;

implementation



{ TInstruction. }

function TInstruction.GetNext: TInstruction;
begin

end;

function TInstruction.GetOffset: Integer;
begin

end;

function TInstruction.GetOpCode: TCILOpCode;
begin

end;

function TInstruction.GetOperand: TObject;
begin

end;

function TInstruction.GetPrevious: TInstruction;
begin

end;

function TInstruction.GetSequencePoint: TSequencePoint;
begin

end;

function TInstruction.GetSize: Integer;
var
  Size: integer;
begin
	 //	Size := OpCode.Size;
    //case OpCode.GetOperandType of
			//InlineSwitch: Result := ;
			{case OperandType.InlineI8:
			case OperandType.InlineR:
				return size + 8;
			case OperandType.InlineBrTarget:
			case OperandType.InlineField:
			case OperandType.InlineI:
			case OperandType.InlineMethod:
			case OperandType.InlineString:
			case OperandType.InlineTok:
			case OperandType.InlineType:
			case OperandType.ShortInlineR:
			case OperandType.InlineSig:
				return size + 4;
			case OperandType.InlineArg:
			case OperandType.InlineVar:
				return size + 2;
			case OperandType.ShortInlineBrTarget:
			case OperandType.ShortInlineI:
			case OperandType.ShortInlineArg:
			case OperandType.ShortInlineVar:
				return size + 1;
			default:
				return size;  }

end;

procedure TInstruction.SetNext(ANext: TInstruction);
begin

end;

procedure TInstruction.SetOffset(AOffset: Integer);
begin

end;

procedure TInstruction.SetOpCode(AOpCode: TCILOpCode);
begin

end;

procedure TInstruction.SetOperand(AOperand: TObject);
begin

end;

procedure TInstruction.SetPrevious(APrevious: TInstruction);
begin

end;

procedure TInstruction.SetSequencePoint(ASequencePoint: TSequencePoint);
begin

end;

end.
