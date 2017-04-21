unit RefEl;

interface

type

TRefEl = class
protected
  FRefCnt: integer;
public
  function AddRef: TRefEl;
  procedure FreeNoRef;
  procedure RmRef;
end ;

implementation

function TRefEl.AddRef: TRefEl;
begin
  Result := Self;
  if Self=Nil then
    Exit;
  Inc(FRefCnt);
end ;

procedure TRefEl.FreeNoRef;
begin
  if Self=Nil then
    Exit;
  if FRefCnt<=0 then
    Destroy;
end ;

procedure TRefEl.RmRef;
begin
  if Self=Nil then
    Exit;
  Dec(FRefCnt);
  if FRefCnt<=0 then
    Destroy;
end ;

end.
