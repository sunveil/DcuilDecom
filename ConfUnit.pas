unit ConfUnit;

interface

uses
  IniFiles, SysUtils,
  DCU_Out;

const
  cIFName = 'dcu32int.ini';
  cPathSep = '\';

procedure ReadIFile;
procedure WriteIFile;

implementation

procedure ReadIFile;
var
  I : TIniFile;
begin
  if not FileExists(cIFName) then
    Exit;
  I :=  TIniFile.Create(cIFName);
  ShowImpNames := I.ReadBool('options','ShowImpNames',ShowImpNames);
  ShowTypeTbl := I.ReadBool('options','ShowTypeTbl',ShowTypeTbl);
  ShowAddrTbl := I.ReadBool('options','ShowAddrTbl',ShowAddrTbl);
  ShowDataBlock := I.ReadBool('options','ShowDataBlock',ShowDataBlock);
  ShowFixupTbl := I.ReadBool('options','ShowFixupTbl',ShowFixupTbl);
  ShowAuxValues := I.ReadBool('options','ShowAuxValues',ShowAuxValues);
  ResolveMethods := I.ReadBool('options','ResolveMethods',ResolveMethods);
  ResolveConsts := I.ReadBool('options','ResolveConsts',ResolveConsts);
  ShowDotTypes := I.ReadBool('options','ShowDotTypes',ShowDotTypes);
  ShowVMT := I.ReadBool('options','ShowVMT',ShowVMT);
  I.Free;
end;

procedure WriteIFile;
var
  I : TIniFile;
begin
  I := TIniFile.Create(cIFName);
  I.WriteBool('options','ShowImpNames',ShowImpNames);
  I.WriteBool('options','ShowTypeTbl',ShowTypeTbl);
  I.WriteBool('options','ShowAddrTbl',ShowAddrTbl);
  I.WriteBool('options','ShowDataBlock',ShowDataBlock);
  I.WriteBool('options','ShowFixupTbl',ShowFixupTbl);
  I.WriteBool('options','ShowAuxValues',ShowAuxValues);
  I.WriteBool('options','ResolveMethods',ResolveMethods);
  I.WriteBool('options','ResolveConsts',ResolveConsts);
  I.WriteBool('options','ShowDotTypes',ShowDotTypes);
  I.WriteBool('options','ShowVMT',ShowVMT);
  I.Free;
end;

end.
