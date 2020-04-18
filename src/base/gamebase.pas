unit gamebase;

{$mode objfpc}

interface

uses
  init, resources,
  JS, Web, WebGL;

type
  TGameState = (
    gsInit,
    gsLoad,
    gsMenu,
    gsGame
  );

  TCustomGame = class
  private     
    canvas: TJSHTMLCanvasElement;
    fgl: TJSWebGLRenderingContext;
    function OnClick(aEvent: TJSMouseEvent): boolean;
  private
    fTime: double;
    fState: TGameState;
    procedure DoLoad(const AResource: string; AProgress: double);
    procedure DoneLoad;

    procedure InitGL;
    function OnResized: boolean;

    procedure UpdateCanvas(ATime: TJSDOMHighResTimeStamp);
  protected
    procedure SetState(AState: TGameState);
    procedure StartState(AState: TGameState); virtual;
    procedure RegisterResources; virtual;
    procedure RenderFrame; virtual;

    procedure Resized; virtual;
    procedure Click(AX,AY: double); virtual;

    property Time: double read fTime;
    property GL: TJSWebGLRenderingContext read fgl;
  public
    constructor Create;

    procedure Run;
  end;

implementation

procedure TCustomGame.DoneLoad;
begin
  InitStop;
  fState:=gsMenu;
  StartState(gsMenu);
end;

function TCustomGame.OnClick(aEvent: TJSMouseEvent): boolean;
begin
  Click(aEvent.offsetX,aEvent.offsetY);
  result:=true;
end;

procedure TCustomGame.DoLoad(const AResource: string; AProgress: double);
begin
  InitProgress(AProgress, 'Loaded ' + AResource);
end;

procedure TCustomGame.InitGL;
begin
  canvas:=TJSHTMLCanvasElement(document.createElement('canvas'));
  canvas.width:=window.innerWidth;
  canvas.height:=window.innerHeight;
  canvas.style.setProperty('position','absolute');
  canvas.style.setProperty('z-index','0');
  document.body.appendChild(canvas);

  canvas.onclick:=@OnClick;
  window.addEventListener('resize', @OnResized);

  fgl:=TJSWebGLRenderingContext(canvas.getContext('webgl'));
  if fgl = nil then
  begin
    writeln('Webgl not loaded');
    exit;
  end;
end;

function TCustomGame.OnResized: boolean;
begin
  canvas.width:=window.innerWidth;
  canvas.height:=window.innerHeight;

  gl.viewport(0, 0, canvas.width, canvas.height);

  Resized;

  result:=true;
end;

procedure TCustomGame.UpdateCanvas(ATime: TJSDOMHighResTimeStamp);
begin
  fTime:=ATime;
  Run;               
  window.requestAnimationFrame(@UpdateCanvas);
end;

procedure TCustomGame.SetState(AState: TGameState);
begin
  StartState(AState);
  fState:=AState;
end;

procedure TCustomGame.StartState(AState: TGameState);
begin
end;

procedure TCustomGame.RegisterResources;
begin
end;

procedure TCustomGame.RenderFrame;
begin
end;

procedure TCustomGame.Resized;
begin
end;

procedure TCustomGame.Click(AX, AY: double);
begin
end;

constructor TCustomGame.Create;
begin
  inherited Create;
  fState:=gsInit;
end;

procedure TCustomGame.Run;
begin
  case fState of
    gsInit:
      begin
        InitGL;
        window.requestAnimationFrame(@UpdateCanvas);

        StartState(gsInit);

        InitStart;

        RegisterResources;
        fState:=gsLoad;
        StartState(gsLoad);

        resources.LoadResources(@DoLoad, @DoneLoad);
      end;
    gsLoad:
      begin
      end;
    gsMenu,
    gsGame:
      RenderFrame;
  end;
end;

end.

