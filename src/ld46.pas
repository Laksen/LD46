unit ld46;

{$mode objfpc}

interface

uses
  gamebase, camera, matrix, shaders, resources, utils, imgreader,
  JS, web, webgl;

type         
  TRenderContext = class;

  TRenderTarget = class
  private       
    fFBO: TJSWebGLFramebuffer;
    fColorTex: TJSWebGLTexture;
    fDepthRB: TJSWebGLRenderbuffer;
    fContext: TRenderContext;
  public
    procedure Resize(AWidth, AHeight: longint);
    constructor Create(AContext: TRenderContext; AWidth, AHeight: longint);
    destructor Destroy; override;

    property FBO: TJSWebGLFramebuffer read fFBO;
  end;

  TRenderContext = class
  private
    fCamera: TCamera;
    fGL: TJSWebGLRenderingContext;
    fOffscreenBuffer: TRenderTarget;
    fRenderTarget: TRenderTarget;
    procedure SetRenderTarget(AValue: TRenderTarget);
  public
    procedure Resize;

    constructor Create(AGL: TJSWebGLRenderingContext);

    property OffscreenBuffer: TRenderTarget read fOffscreenBuffer;

    property Camera: TCamera read fCamera;
    property GL: TJSWebGLRenderingContext read fGL;
    property RenderTarget: TRenderTarget read fRenderTarget write SetRenderTarget;
  end;

  TPoint = class
  private
    fX: double;
    fY: double;
    fZ: double;
  public
    constructor Create(AX, AY: double; AZ: double = 0);

    property X: double read fX;
    property Y: double read fY;
    property Z: double read fZ;
  end;

  TPoints = array of TPoint;

  TRenderable = class
  protected
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); virtual; abstract;
  end;

  TTileType = (ttNormal, ttHidden);

  TColor = record
    R,G,B: double;
  end;

  TTile = class
  private
    fColor: TColor;
    fRevealed: boolean;
    fTileType: TTileType;
    fX, fY: LongInt;
    fPoints: TPoints;
  public
    constructor Create(AX, AY: longint);

    property X: longint read fX;
    property Y: longint read fY;
    property Color: TColor read fColor write fColor;
    property Points: TPoints read fPoints;
    property TileType: TTileType read fTileType write fTileType;
    property Revealed: boolean read fRevealed write fRevealed;
  end;

  TTerrain = class(TRenderable)
  private
    class var fShader: TShader;       
    class var fTex: TJSWebGLTexture;

    class var aVertexLocation: integer;
    class var aTexcoordLocation: integer;
    class var aNormalLocation: integer;
    class var aColorLocation: integer;
    class var aPickLocation: integer;

    class var uMVPLocation: TJSWebGLUniformLocation;
    class var uProjLocation: TJSWebGLUniformLocation;
    class var uPickLocation: TJSWebGLUniformLocation;
    class var uSamplerLocation: TJSWebGLUniformLocation;

    class procedure InitShader(AContext: TRenderContext);
  private
    fHeight: longint;
    fWidth: longint;
    fTiles: array of TTile;

    fBuffer: TJSWebGLBuffer;

    function GetTile(AX, AY: longint): TTile;
    procedure DoRender(AContext: TRenderContext; APick: boolean);

    procedure PrepareBuffer(AContext: TRenderContext);
  protected
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); override;
  public
    function Pick(AContext: TRenderContext; AX, AY: longint): TTile;

    constructor Create(AContext: TRenderContext; AData: TJSArrayBuffer);
    constructor Create(AContext: TRenderContext; AW, AH: longint);

    property Width: longint read fWidth;
    property Height: longint read fHeight;
    property Tiles[AX,AY: longint]: TTile read GetTile;
  end;

  TCharacterTrait = (ctFocus, ctMotivated, ctAggro, ctShield);
  TCharacterTraits = set of TCharacterTrait;

  TCharacterStats = class
  public
    HP, Mana,
    MaxHP, MaxMana,
    ManaRegen,

    XP,Level,
    VisRange, MoveRange, AttackRange, AggroRange,

    BaseAttack: longint;
  end;

  TCharacterModel = class(TRenderable)
  protected
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); override;
  end;

  TCharacter = class(TRenderable)
  private
    fName: string;
    fSelected: boolean;
    fStats: TCharacterStats;
    fTraits: TCharacterTraits;
    fX: longint;
    fY: longint;
  protected
    function Model: TCharacterModel; virtual; abstract;
    function IsFriendly: boolean; virtual; abstract;
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); override;
  public
    constructor Create(const AName: string);

    property Name: string read fName;
    property Friendly: boolean read IsFriendly;
    property Selected: boolean read fSelected write fSelected;

    property Stats: TCharacterStats read fStats write fStats;
    property Traits: TCharacterTraits read fTraits write fTraits;

    property X: longint read fX write fX;
    property Y: longint read fY write fY;
  end;

  TLD46 = class(TCustomGame)
  private
    fContext: TRenderContext;

    fTerrain: TTerrain;
  protected
    procedure RegisterResources; override;
    procedure StartState(AState: TGameState); override;
    procedure InitGame;
    procedure RenderFrame; override;

    procedure Resized; override;
    procedure Click(AX, AY: double); override;
  end;

implementation

uses
  math;

procedure TRenderTarget.Resize(AWidth, AHeight: longint);
begin
  fContext.GL.activeTexture(fContext.GL.TEXTURE0);
  fContext.GL.bindTexture(fContext.GL.TEXTURE_2D, fColorTex);
  fContext.gl.texImage2D(fContext.GL.TEXTURE_2D,0,fContext.GL.RGBA,AWidth,AHeight,0,fContext.GL.RGBA,fContext.GL.UNSIGNED_BYTE,nil);

  fContext.GL.bindRenderbuffer(fContext.GL.RENDERBUFFER, fDepthRB);
  fContext.GL.renderbufferStorage(fContext.GL.RENDERBUFFER, fContext.GL.DEPTH_COMPONENT16, AWidth, AHeight);
end;

constructor TRenderTarget.Create(AContext: TRenderContext; AWidth, AHeight: longint);
begin
  inherited Create;
  fContext:=AContext;

  fFBO:=AContext.GL.createFramebuffer;

  fColorTex:=AContext.GL.createTexture;
  fDepthRB:=AContext.GL.createRenderbuffer;

  AContext.GL.bindFramebuffer(AContext.GL.FRAMEBUFFER, ffBO);

  fContext.GL.activeTexture(fContext.GL.TEXTURE0);
  fContext.GL.bindTexture(fContext.GL.TEXTURE_2D, fColorTex);
  fContext.gl.texImage2D(fContext.GL.TEXTURE_2D,0,fContext.GL.RGBA,AWidth,AHeight,0,fContext.GL.RGBA,fContext.GL.UNSIGNED_BYTE,nil);
  AContext.GL.framebufferTexture2D(AContext.GL.FRAMEBUFFER, AContext.GL.COLOR_ATTACHMENT0, AContext.GL.TEXTURE_2D, fColorTex, 0);
                                                                               
  AContext.GL.bindRenderbuffer(AContext.GL.RENDERBUFFER, fDepthRB);
  AContext.GL.renderbufferStorage(AContext.GL.RENDERBUFFER, AContext.GL.DEPTH_COMPONENT16, AWidth, AHeight);
  AContext.GL.framebufferRenderbuffer(AContext.GL.FRAMEBUFFER, AContext.GL.DEPTH_ATTACHMENT, AContext.GL.RENDERBUFFER, fDepthRB);

  AContext.GL.bindFramebuffer(AContext.GL.FRAMEBUFFER, nil);
end;

destructor TRenderTarget.Destroy;
begin
  fContext.GL.deleteFramebuffer(fFBO);
  fContext.GL.deleteTexture(fColorTex);
  fContext.GL.deleteRenderbuffer(fDepthRB);
  inherited Destroy;
end;

constructor TTile.Create(AX, AY: longint);
begin
  inherited Create;
  fX:=AX;
  fY:=AY;
  fRevealed:=false;
  fTileType:=ttNormal;
  fColor.R:=0.5;
  fColor.G:=0.5;
  fColor.B:=0.5;

  setlength(fPoints, 4);
  fPoints[0]:=TPoint.Create(fX+0,fY+0);
  fPoints[1]:=TPoint.Create(fX+0,fY+1);
  fPoints[2]:=TPoint.Create(fX+1,fY+0);
  fPoints[3]:=TPoint.Create(fX+1,fY+1);
end;

procedure TCharacterModel.Render(AContext: TRenderContext; APosition: TPoint; ARotation: double);
begin
end;

procedure TRenderContext.SetRenderTarget(AValue: TRenderTarget);
begin
  if fRenderTarget=AValue then Exit;
  fRenderTarget:=AValue;

  if fRenderTarget<>nil then
    GL.bindFramebuffer(GL.FRAMEBUFFER, fRenderTarget.FBO)
  else
    GL.bindFramebuffer(GL.FRAMEBUFFER, nil);
end;

procedure TRenderContext.Resize;
var
  w, h: GLsizei;
  aspect: double;
begin
  w:=fGL.canvas.width;
  h:=fGL.canvas.height;

  aspect:=h/w;

  fOffscreenBuffer.Resize(w,h);
  fCamera.Projection:=TMatrix.Orthographic(-1,1,-aspect/2,aspect/2,-100,100);
end;

constructor TRenderContext.Create(AGL: TJSWebGLRenderingContext);
begin
  inherited Create;
  fGL:=AGL;

  fCamera:=TCamera.Create(TMatrix.Orthographic(-1,1,-1,1,-1,1));
  //fCamera:=TCamera.Create(TMatrix.Perspective(90,1,0.1,1000)); 
  fOffscreenBuffer:=TRenderTarget.Create(self, fGL.canvas.width, fgl.canvas.height);

  Resize;
end;

constructor TPoint.Create(AX, AY, AZ: double);
begin
  inherited Create;
  fX:=AX;
  fY:=AY;
  fZ:=AZ;
end;

class procedure TTerrain.InitShader(AContext: TRenderContext);
var
  data: TJSUint8Array;
  w, h: longint;
begin
  if assigned(fShader) then exit;
  fShader:=TShader.Create(GetResourceString('assets/shaders/terrain.vert'), GetResourceString('assets/shaders/terrain.frag'), AContext.GL);

  aVertexLocation:=AContext.GL.getAttribLocation(fShader.Prog, 'aVertex');
  aTexcoordLocation:=AContext.GL.getAttribLocation(fShader.Prog, 'aTexcoord');
  aNormalLocation:=AContext.GL.getAttribLocation(fShader.Prog, 'aNormal');
  aColorLocation:=AContext.GL.getAttribLocation(fShader.Prog, 'aColor');
  aPickLocation:=AContext.GL.getAttribLocation(fShader.Prog, 'aPick');

  uMVPLocation:=AContext.GL.getUniformLocation(fShader.Prog, 'uMVP');
  uProjLocation:=AContext.GL.getUniformLocation(fShader.Prog, 'uProj');
  uPickLocation:=AContext.GL.getUniformLocation(fShader.Prog, 'uPick');
  uSamplerLocation:=AContext.GL.getUniformLocation(fShader.Prog, 'uSampler');

  data:=DecodeTGA(GetResources('assets/textures/terrain.tga'), w,h);
  fTex:=AContext.GL.createTexture();
  AContext.GL.bindTexture(AContext.GL.TEXTURE_2D, fTex);
  AContext.GL.texImage2D(AContext.GL.TEXTURE_2D, 0, AContext.GL.RGBA, w, h, 0, AContext.GL.RGBA, AContext.GL.UNSIGNED_BYTE, data);
  AContext.GL.texParameteri(AContext.GL.TEXTURE_2D, AContext.GL.TEXTURE_WRAP_S, AContext.GL.CLAMP_TO_EDGE);
  AContext.GL.texParameteri(AContext.GL.TEXTURE_2D, AContext.GL.TEXTURE_WRAP_T, AContext.GL.CLAMP_TO_EDGE);
  AContext.GL.texParameteri(AContext.GL.TEXTURE_2D, AContext.GL.TEXTURE_MAG_FILTER, AContext.GL.LINEAR);
  AContext.GL.texParameteri(AContext.GL.TEXTURE_2D, AContext.GL.TEXTURE_MIN_FILTER, AContext.GL.LINEAR_MIPMAP_LINEAR);
  AContext.GL.generateMipmap(AContext.GL.TEXTURE_2D);
end;

function TTerrain.GetTile(AX, AY: longint): TTile;
begin
  result:=fTiles[AX+AY*fWidth];
end;

const
  TerrainVertSize = 3+2+3+3+3;

procedure TTerrain.DoRender(AContext: TRenderContext; APick: boolean);
begin
  InitShader(AContext);

  AContext.GL.activeTexture(AContext.GL.TEXTURE0);
  AContext.GL.bindTexture(AContext.GL.TEXTURE_2D, fTex);

  AContext.GL.useProgram(fShader.Prog);  
  AContext.GL.uniformMatrix4fv(uMVPLocation, false, AContext.Camera.Modelview.Copy);
  AContext.GL.uniformMatrix4fv(uProjLocation, false, AContext.Camera.Projection.Copy);
  AContext.GL.uniform1f(uPickLocation, ord(APick));
  AContext.GL.uniform1i(uSamplerLocation, 0);

  AContext.GL.bindBuffer(AContext.GL.ARRAY_BUFFER, fBuffer);

  AContext.GL.enableVertexAttribArray(aVertexLocation);
  AContext.GL.enableVertexAttribArray(aTexcoordLocation);
  AContext.GL.enableVertexAttribArray(aNormalLocation);
  AContext.GL.enableVertexAttribArray(aColorLocation);
  AContext.GL.enableVertexAttribArray(aPickLocation);

  AContext.GL.vertexAttribPointer(aVertexLocation, 3, AContext.GL.FLOAT, false, TerrainVertSize*4, 0);
  AContext.GL.vertexAttribPointer(aTexcoordLocation, 2, AContext.GL.FLOAT, false, TerrainVertSize*4, (3)*4);
  AContext.GL.vertexAttribPointer(aNormalLocation, 3, AContext.GL.FLOAT, false, TerrainVertSize*4, (3+2)*4);
  AContext.GL.vertexAttribPointer(aColorLocation, 3, AContext.GL.FLOAT, false, TerrainVertSize*4, (3+2+3)*4);
  AContext.GL.vertexAttribPointer(aPickLocation, 3, AContext.GL.FLOAT, false, TerrainVertSize*4, (3+2+3+3)*4);

  AContext.GL.drawArrays(AContext.GL.TRIANGLE_STRIP, 0, 10*length(fTiles));

  AContext.GL.disableVertexAttribArray(aVertexLocation);
  AContext.GL.disableVertexAttribArray(aTexcoordLocation);
  AContext.GL.disableVertexAttribArray(aNormalLocation);
  AContext.GL.disableVertexAttribArray(aColorLocation);
  AContext.GL.disableVertexAttribArray(aPickLocation);
end;

procedure TTerrain.PrepareBuffer(AContext: TRenderContext);
var
  data: TJSFloat32Array;
  i,cnt: Integer;

  procedure AddVertex(const APt: TPoint; T: TTile; AX,AY: double);
  begin
    // Vertex
    data[TerrainVertSize*cnt+0]:=APt.X;
    data[TerrainVertSize*cnt+1]:=APt.Y;
    data[TerrainVertSize*cnt+2]:=APt.Z;

    // Texcoord
    data[TerrainVertSize*cnt+3]:=AX;
    data[TerrainVertSize*cnt+4]:=AY;

    // Normal
    data[TerrainVertSize*cnt+5]:=1;
    data[TerrainVertSize*cnt+6]:=0;
    data[TerrainVertSize*cnt+7]:=0;

    // Color
    data[TerrainVertSize*cnt+8]:=T.Color.R;
    data[TerrainVertSize*cnt+9]:=T.Color.G;
    data[TerrainVertSize*cnt+10]:=T.Color.B;

    // Pick
    data[TerrainVertSize*cnt+11]:=T.X/256;
    data[TerrainVertSize*cnt+12]:=T.Y/256;
    data[TerrainVertSize*cnt+13]:=0;

    inc(cnt);
  end;

  procedure AddTile(T: TTile);
  var
    pts: TPoints;
    center: TPoint;
  begin
    pts:=T.Points;
    center:=TPoint.Create((pts[0].X+pts[1].X+pts[2].X+pts[3].X)/4,
                          (pts[0].y+pts[1].y+pts[2].y+pts[3].y)/4,
                          (pts[0].z+pts[1].z+pts[2].z+pts[3].z)/4);

    AddVertex(pts[0],t,0,0);
    AddVertex(pts[0],t,0,0);
    AddVertex(pts[1],t,1,0);
    AddVertex(center,t,0.5,0.5); 
    AddVertex(pts[3],t,1,1);
    AddVertex(pts[2],t,0,1);
    AddVertex(pts[2],t,0,1); 
    AddVertex(center,t,0.5,0.5);
    AddVertex(pts[0],t,0,0);
    AddVertex(pts[0],t,0,0);
  end;

begin
  data:=TJSFloat32Array.new(TerrainVertSize*10*length(fTiles));

  for i:=0 to high(fTiles) do
    AddTile(fTiles[i]);

  AContext.GL.bindBuffer(AContext.GL.ARRAY_BUFFER, fBuffer);
  AContext.GL.bufferData(AContext.GL.ARRAY_BUFFER, data, AContext.GL.STATIC_DRAW);
end;

procedure TTerrain.Render(AContext: TRenderContext; APosition: TPoint; ARotation: double);
begin
  DoRender(AContext, false);
end;

function TTerrain.Pick(AContext: TRenderContext; AX, AY: longint): TTile;
var
  buf: TJSUint8Array;
  offsetX, offsetY: Byte;
  selected: Boolean;
begin
  AContext.RenderTarget:=AContext.OffscreenBuffer;

  AContext.GL.pixelStorei(AContext.GL.UNPACK_COLORSPACE_CONVERSION_WEBGL, AContext.GL.NONE);
  AContext.GL.pixelStorei(AContext.GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 0);

  AContext.GL.clearColor(1,1,1,1);
  AContext.GL.clear(AContext.GL.COLOR_BUFFER_BIT or AContext.GL.DEPTH_BUFFER_BIT);
  DoRender(AContext, true);

  AContext.GL.flush();

  buf:=TJSUint8Array.new(4);
  AContext.GL.readPixels(AX,AContext.GL.canvas.height-AY,1,1,AContext.GL.RGBA,AContext.GL.UNSIGNED_BYTE,buf);
  offsetX:=TJSDataView.new(buf.buffer).getUint8(0);
  offsetY:=TJSDataView.new(buf.buffer).getUint8(1);
  selected:=TJSDataView.new(buf.buffer).getUint8(3)<>$FF;

  AContext.RenderTarget:=nil;

  if selected then
    result:=fTiles[offsetX+offsetY*fWidth]
  else
    result:=nil;
end;

constructor TTerrain.Create(AContext: TRenderContext; AData: TJSArrayBuffer);
begin
  inherited Create;
end;

constructor TTerrain.Create(AContext: TRenderContext; AW, AH: longint);
var
  y, x: Integer;
begin
  inherited Create;
  fWidth:=AW;
  fHeight:=AH;

  setlength(fTiles, AW*AH);
  for y:=0 to AH-1 do
    for x:=0 to AW-1 do
      fTiles[x+y*AW]:=TTile.Create(x,y);
                             
  fBuffer:=AContext.GL.createBuffer();

  PrepareBuffer(AContext);
end;

procedure TCharacter.Render(AContext: TRenderContext; APosition: TPoint; ARotation: double);
begin
  Model.Render(AContext, APosition, ARotation);
end;

constructor TCharacter.Create(const AName: string);
begin
  inherited Create;
  fStats:=TCharacterStats.Create;
  fName:=AName;
end;

procedure TLD46.RegisterResources;
begin
  // Terrain
  AddResource('assets/shaders/terrain.vert');
  AddResource('assets/shaders/terrain.frag');

  AddResource('assets/textures/terrain.tga');
end;

procedure TLD46.StartState(AState: TGameState);
begin
  if AState=gsMenu then
    SetState(gsGame)
  else if AState=gsGame then
    InitGame;
end;

procedure TLD46.InitGame;
begin
  // Init stuff
  fContext:=TRenderContext.Create(GL);  
  fContext.Camera.Translate(-2,-2,-0);
  fContext.Camera.RotateZ(DegToRad(45));
  fContext.Camera.RotateX(DegToRad(-80));  
  //fContext.Camera.Scale(0.125,0.125,1);

  // Load level
  writeln('Creating terrain');
  fTerrain:=TTerrain.Create(fContext, 100,100);
  //fTerrain.Tiles[1,1].;
end;

procedure TLD46.RenderFrame;
begin
  fContext.GL.clearColor(0,0,0,1);
  fContext.GL.clear(fContext.GL.COLOR_BUFFER_BIT or fContext.GL.DEPTH_BUFFER_BIT);

  fTerrain.Render(fContext, TPoint.Create(0,0), 0);
end;

procedure TLD46.Resized;
begin
  fContext.Resize;
end;

procedure TLD46.Click(AX, AY: double);
var
  x: TTile;
begin
  x:=fTerrain.Pick(fContext, round(ax), round(ay));
  if x<>nil then
  begin
    x.Color.g:=1;
    fTerrain.PrepareBuffer(fContext);
  end;
end;

end.

