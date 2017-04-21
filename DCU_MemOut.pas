unit DCU_MemOut;

interface

uses
  {$IFDEF UNICODE}AnsiStrings,{$ENDIF}SysUtils, FixUp, Classes, DCU_Out;

type

  TMemWriter = class(TBaseWriter)
  protected
    FWasStr,FMemTaken: boolean;
    FMem : TMemoryStream;
    procedure WriteEnd; override;
    procedure WriteCP(CP: PAnsiChar; Len: integer); override;
    procedure NL; override;
    function OpenStrInfo(Info: integer; Data: Pointer): boolean; override;
    procedure CloseStrInfo; override;
    procedure MarkDefStart(hDef: integer); override;
    procedure MarkMemOfs(Ofs: integer); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteStart; override;
    function TakeMem: TMemoryStream;
  end ;

var
  FRes: TextFile;

var
  oFmtMem : boolean = True;

const
  rtfKeyWord = '{\b ';
  rtfEnd = '{\i ';
  rtfRem = '{\cf3\i ';
  rtfCloseRem = '} ';
  rtfClose = '} ';
  rtfStrConst = '{\cf3\i ';
  rtfOpName = '{\cf2 ';
  rtfNL= #13#10'\par';
  rtfRemOpen = '';
  rftRemClose = '';
  siOpName = 9;
  siRemOpen = 10;
  siRemClose = 11;

function InitOutMem: TBaseWriter;


implementation

uses
  DCU32, DCU_In;

{ TMemWriter. }

constructor TMemWriter.Create;
begin
  inherited Create;
  if FMem = nil then
    FMem := TMemoryStream.Create;
  WriteStart;  
end;

destructor TMemWriter.Destroy;
begin
  if not FMemTaken then
    FMem.Free;
  inherited Destroy;
end;

procedure TMemWriter.WriteStart;
const
  //rtfBegin = '{\rtf1 ';
  //rtfColorTbl = '{\colortbl\red0\green0\blue0;\red0\green128\blue128;\red0\green128\blue0;\red128\green128\blue0;} ';
  rtfBegin = '{\rtf1\ansi\deff0\deftab720'+
  '{\fonttbl{\f0\fmodern\fprq1\fcharset204{\*\fname Courier New;}Courier New Cyr;}'+
  '{\colortbl\red255\green255\blue0;\red255\green255\blue0;\red0\green0\blue0;\red0\green0\blue255;}'+
  '\deffn\f5\fs20}'+
  '\deflang1049\pard\plain\f0\fs20';
begin
  inherited WriteStart;
  //FMem := TMemoryStream.Create;
  FMem.Position := 0;
  FMem.Write(rtfBegin,Length(rtfBegin));
  //FMem.Write(rtfBegin,Length(rtfColorTbl));
end ;

procedure TMemWriter.WriteEnd;
const
  rtfFEnd: AnsiChar = '}';
begin
  FMem.Write(rtfFEnd, SizeOf(rtfFEnd));
end ;

procedure TMemWriter.WriteCP(CP: PAnsiChar; Len: integer);
const
  sTags: array[1..siMaxRange]of String[7] = ('{\i','{\i\{','{\b','','');
var
  S: String;
var
  Buf: ShortString;
  i,j: integer;
  Ch: Char;

  procedure FlushBuf;
  var
    ind: integer;
  begin
    Buf[0] := AnsiChar(j);
    for ind:=1 to j do begin
      FMem.Write(Buf[ind],1);
    end;
//FMem.Write(Buf,Length(Buf));
    j := 0;
  end ;

  procedure PutS(C: PChar);
  begin
    while C^<>#0 do begin
      Inc(j);
      Buf[j] := C^;
      Inc(C);
    end ;
  end ;

begin
  S := '';
  if not FWasStr and(CP^<>#0)and(FInfo>0) then
    case FInfo of
      siRem: S := rtfRem;
      siStrConst: S := rtfStrConst;
      siKeyWord : S := rtfKeyWord;
      siOpName  : S := rtfOpName;
      siRemOpen : S := rtfRemOpen;
      siRemClose: S := rftRemClose;
    end;
  if S<>'' then
    FMem.Write(S[1],Length(S));

  FWasStr:= True;
  j := 0;
  for i:=0 to Len-1 do begin
    Ch := CP[i];
    case Ch of
      '{': PutS('\{');
      '}': PutS('\}');
    else
      Inc(j);
      Buf[j] := Ch;
    end;
    if j>240 then
      FlushBuf;
  end ;
  FlushBuf;
end ;

procedure TMemWriter.NL;
begin
  FMem.Write(rtfNL, Length(rtfNL));
end ;

function TMemWriter.OpenStrInfo(Info: integer; Data: Pointer): boolean;
begin
  if inherited OpenStrInfo(Info,Data) then
    FWasStr := false;
end ;

procedure TMemWriter.CloseStrInfo;
const
  sTags: array[1..siMaxRange]of String = ('}','}','}','','');
begin
  if FWasStr and (FInfo>0) then
    case FInfo of
      siRem: FMem.Write(rtfCloseRem,Length(rtfCloseRem));
      siStrConst: FMem.Write(rtfClose,Length(rtfClose));
      siKeyWord: FMem.Write(rtfClose,Length(rtfClose));
      siOpName: FMem.Write(rtfClose,Length(rtfClose));
      siRemOpen: FMem.Write(rtfClose,Length(rtfClose));
      siRemClose: FMem.Write(rtfClose,Length(rtfClose));
    end;
  inherited CloseStrInfo;
  FWasStr := false;
end ;

procedure TMemWriter.MarkDefStart(hDef: integer);
begin
end;

procedure TMemWriter.MarkMemOfs(Ofs: integer);
begin
end;

function TMemWriter.TakeMem: TMemoryStream;
begin
  Result := FMem;
  FMemTaken := true;
end;

function InitOutMem: TBaseWriter;
begin
  if Writer=Nil then
    Writer := TMemWriter.Create;
  Result := Writer;
end;

end.
