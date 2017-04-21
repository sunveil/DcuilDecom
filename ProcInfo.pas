unit ProcInfo;

interface

uses
  DCURecs;

type

  TProcInfo = class
  private
    FPrcoDecl: TProcDecl;
    FOfs0: Cardinal;
    FBlOfs: Cardinal;
    FBlSz: Cardinal;
    function GetProcDecl: TProcDecl;
  public
    constructor Create(AOfs0, ABlOfs, ABlSz: Cardinal; APrcoDecl: TProcDecl);
    property ProcDecl: TProcDecl read GetProcDecl;
    property Ofs0: Cardinal read FOfs0;
    property BlOfs: Cardinal read FBlOfs;
    property BlSz: Cardinal read FBlSz;
    destructor Destroy();
  end;

implementation

{ TProcInfo. }

constructor TProcInfo.Create(AOfs0, ABlOfs, ABlSz: Cardinal;
  APrcoDecl: TProcDecl);
begin
  FPrcoDecl := APrcoDecl;
  FOfs0 := AOfs0;
  FBlOfs := ABlOfs;
  FBlSz := ABlSz;
end;

destructor TProcInfo.Destroy;
begin

end;

function TProcInfo.GetProcDecl: TProcDecl;
begin
  Result := FPrcoDecl;
end;

end.
