unit shaders;

{$mode objfpc}

interface

uses
  webgl;

type
  TShader = class
  private
    fProg: TJSWebGLProgram;
    fVert, fFrag: TJSWebGLShader;
    function LoadShader(const ASrc: string; AType: integer; gl: TJSWebGLRenderingContext): TJSWebGLShader;
  public
    constructor Create(const AVertSource, AFragSource: string; gl: TJSWebGLRenderingContext);
    destructor Destroy; override;

    property Prog: TJSWebGLProgram read fProg;
  end;

implementation

function TShader.LoadShader(const ASrc: string; AType: integer; gl: TJSWebGLRenderingContext): TJSWebGLShader;
var
  shader: TJSWebGLShader;
begin
  shader:=gl.createShader(AType);
  gl.shaderSource(shader, ASrc);
  gl.compileShader(shader);

  if not gl.getShaderParameter(shader, gl.COMPILE_STATUS) then
  begin
    Writeln('An error occurred compiling the shaders: ', gl.getShaderInfoLog(shader));
    gl.deleteShader(shader);
    exit(nil);
  end;

  result:=shader;
end;

constructor TShader.Create(const AVertSource, AFragSource: string; gl: TJSWebGLRenderingContext);
begin
  inherited Create;
  fVert:=LoadShader(AVertSource, gl.VERTEX_SHADER, gl);
  fFrag:=LoadShader(AFragSource, gl.FRAGMENT_SHADER, gl);

  fProg:=gl.createProgram;
  gl.attachShader(fProg, fVert);
  gl.attachShader(fProg, fFrag);
  gl.linkProgram(fProg);

  if not gl.getProgramParameter(fProg, gl.LINK_STATUS) then
  begin
    Writeln('An error occurred linking the shaders: ', gl.getProgramInfoLog(fProg));
  end;
end;

destructor TShader.Destroy;
begin
  inherited Destroy;
end;

end.

