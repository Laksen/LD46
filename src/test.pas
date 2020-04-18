{
  Mesh
    Vertex    3
    Texcoord  2
    Tile      2
    Normal    3
    Color     3

}

program test;

uses
  sysutils,math,
  js, Web, WebGL,
  font, shaders, data, matrix, resources, init, gamebase, menusystem, camera, ld46, utils, imgreader;
             

type
  TGame123 = class(TCustomGame)
  protected
    procedure StartState(AState: TGameState); override;
  end;

var
  canvas: TJSHTMLCanvasElement;
  gl: TJSWebGLRenderingContext;

  loaded: boolean = false;

  fnt: TFont;
  g: TCustomGame;

procedure UpdateCanvas(time: TJSDOMHighResTimeStamp);
var
  rr: TInfo;
begin
  if loaded then
    gl.clearColor(0, 0, 0, 1)
  else
    gl.clearColor(1, 0, 0, 1);
  gl.clear(gl.COLOR_BUFFER_BIT);

  if loaded then
  begin
    fnt.Draw(TMatrix.Perspective(90,window.innerWidth/window.innerHeight,0.1,1000),
             TMatrix.Translation(-rr.Width/2,-rr.Height/2,0).Translate(0,0,-500-400).
             RotateZ(sin(time/1000)),
             'Frame buffers: ', 1, gl);
  end else
  window.requestAnimationFrame(@UpdateCanvas);
end;

function Resized(Event: TEventListenerEvent): boolean;
begin                
  canvas.width:=window.innerWidth;
  canvas.height:=window.innerHeight;
                              
  gl.viewport(0, 0, canvas.width, canvas.height);

  result:=true;
end;

procedure done;
begin
  writeln('Done loading');
  loaded:=true;

  fnt:=TFont.Create(GetResources('assets/ubuntu_light.fnt'), gl);

end;

procedure evt(const AResource: string; A: double);
begin
  writeln('Loaded ', AResource);
end;

procedure TGame123.StartState(AState: TGameState);
begin
  writeln(AState);
end;

begin
  g:=TLD46.Create;
  g.Run;

  {//g:=TGame123.Create;
  //g.Run;

  canvas:=TJSHTMLCanvasElement(document.createElement('canvas'));
  canvas.width:=window.innerWidth;
  canvas.height:=window.innerHeight;
  canvas.style.setProperty('position','absolute');
  canvas.style.setProperty('z-index','0');
  document.body.appendChild(canvas);

  window.addEventListener('resize', @Resized);

  //InitStart;
  //exit;

  gl:=TJSWebGLRenderingContext(canvas.getContext('webgl'));
  if gl = nil then
  begin
    writeln('Webgl not loaded');
    exit;
  end;

  gl.viewport(0, 0, canvas.width, canvas.height);

  AddResource('assets/ubuntu_light.fnt');
 // LoadResources(@evt, @done);

  //x:=TMatrix.Perspective(45,1, 0.1,1000);
  //writeln(x.ToString);

  window.requestAnimationFrame(@UpdateCanvas);}
end.
