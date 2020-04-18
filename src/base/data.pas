unit data;

{$mode objfpc}

interface

uses
  js, Web;

type
  TLoader = class;

  TLoadCallback = procedure(ASender: TLoader; const AFilename: string; const AData: TJSArrayBuffer) of object;

  TLoader = class
  private           
    fFilename,
    fMimetype: String;

    fData: TJSArrayBuffer;

    fOnLoad: TLoadCallback;
    fRequest: TJSXMLHttpRequest;
    procedure HandleReady;
  public
    constructor Create(const AFilename: string; AMimeType: string = 'application/octet-stream');

    procedure StartLoad;

    property Data: TJSArrayBuffer read fData;
    property OnLoad: TLoadCallback read fOnLoad write fOnLoad;
  end;

implementation

function GetStringLL(const Value: JSValue): TJSArrayBuffer; assembler;
asm
  return Value;
end;

procedure Prepare(ARequest: TJSXMLHttpRequest); assembler;
asm
  ARequest.responseType = "arraybuffer";
end;

procedure TLoader.HandleReady;
begin
  if fRequest.readyState<>4 then exit;

  if (fRequest.status = 200) and (fRequest.response<>nil) then
		fData:=GetStringLL(fRequest.response);

  if assigned(fOnLoad) then fOnLoad(self, fFilename, fData);
end;

constructor TLoader.Create(const AFilename: string; AMimeType: string);
begin
  inherited Create;
  fData:=nil;
  fFilename:=AFilename;
  fMimetype:=AMimeType;
end;

procedure TLoader.StartLoad;
begin
  fRequest:=TJSXMLHttpRequest.new;
	fRequest.open('GET', fFilename);
	fRequest.overrideMimeType(fMimetype);
  Prepare(fRequest);
	fRequest.onreadystatechange:=TJSOnReadyStateChangeHandler(@HandleReady);
	fRequest.send;
end;

end.

