unit utils;

{$mode objfpc}

interface

uses
  js;

function EncodeUTF8(ABuf: TJSArrayBuffer): string;

implementation

function EncodeUTF8(ABuf: TJSArrayBuffer): string; assembler;
asm
  return String.fromCharCode.apply(null, new Uint8Array(ABuf));
end;

end.

