unit resources;

{$mode objfpc}

interface

uses
  JS,
  Classes, Types;

type
  TResourceCallback = procedure(const AResource: string; AProgress: double) of object;
  TDoneCallback = procedure of object;

procedure AddResource(const AFilename: string);
procedure LoadResources(AEventCallback: TResourceCallback; ADoneCallback: TDoneCallback);
function GetResources(const AFilename: string): TJSArrayBuffer;

implementation

uses
  data;

type
  TLoadObject = class
  private       
    fLoader: TLoader;
    fDone: TDoneCallback;
    fEvent: TResourceCallback;
    function GetData: TJSArrayBuffer;
    procedure Loaded(ASender: TLoader; const AFilename: string; const AData: TJSArrayBuffer);
  public
    constructor Create(const AFilename: string);
    procedure Load(AEventCallback: TResourceCallback; ADoneCallback: TDoneCallback);

    property Data: TJSArrayBuffer read GetData;
  end;

var
  Resources: TStringList;
  LoadCount,LoadTarget: longint;

procedure AddResource(const AFilename: string);
begin
  Resources.AddObject(AFilename, TLoadObject.Create(AFilename));
end;

procedure LoadResources(AEventCallback: TResourceCallback; ADoneCallback: TDoneCallback);
var
  i: Integer;
begin
  LoadCount:=0;
  LoadTarget:=Resources.Count;

  if LoadTarget=0 then
  begin
    AEventCallback('', 1.0);
    ADoneCallback();
    exit;
  end;

  for i:=0 to Resources.Count-1 do
    TLoadObject(Resources.Objects[i]).Load(AEventCallback,ADoneCallback);
end;

function GetResources(const AFilename: string): TJSArrayBuffer;
begin
  result:=TLoadObject(Resources.Objects[Resources.IndexOf(AFilename)]).Data;
end;

function TLoadObject.GetData: TJSArrayBuffer;
begin
  result:=fLoader.Data;
end;

procedure TLoadObject.Loaded(ASender: TLoader; const AFilename: string; const AData: TJSArrayBuffer);
begin
  inc(LoadCount);  
  fEvent(AFilename, LoadCount/LoadTarget);
  if LoadCount=LoadTarget then
    fDone();
end;

constructor TLoadObject.Create(const AFilename: string);
begin
  inherited Create;
  fLoader:=TLoader.Create(AFilename);
  fLoader.OnLoad:=@Loaded;
end;

procedure TLoadObject.Load(AEventCallback: TResourceCallback; ADoneCallback: TDoneCallback);
begin
  fEvent:=AEventCallback;
  fDone:=ADoneCallback;
  fLoader.StartLoad;
end;

initialization
  Resources:=TStringList.Create;
  Resources.CaseSensitive:=true;
  Resources.Sorted:=true;
  Resources.Duplicates:=dupIgnore;

end.

