unit imgreader;

{$mode objfpc}

interface

uses
  JS, Web,
  sysutils;

function DecodeTGA(const AData: TJSArrayBuffer; out AW,AH: longint): TJSUint8Array;

implementation

function DecodeTGA(const AData: TJSArrayBuffer; out AW,AH: longint): TJSUint8Array;
var
  dv: TJSDataView;
  w, h: SmallInt;
  bpp, idx: Byte;
begin
  dv:=TJSDataView.new(AData);
  w:=dv.getInt16(4+4*2,true);
  h:=dv.getInt16(4+4*2+2,true);
  bpp:=dv.getUint8(4+4*2+4);
  idx:=dv.getUint8(4+4*2+5);

  writeln(w,',',h,',',bpp,',',idx);

  if bpp<>32 then
    raise exception.Create('Wrong BPP');

  AW:=W;
  AH:=H;

  result:=TJSUint8Array.new(AData, 4+4*2+6, w*h*4);
end;

end.

