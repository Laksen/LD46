unit ld46;

{$mode objfpc}

interface

uses
  gamebase, camera, matrix,
  JS, webgl;

type

  TRenderTarget = class
  private
  public
    {procedure Resize(AWidth, AHeight: longint);

    constructor CreateBuffer(AWidth, AHeight: longint);}
  end;

  TRenderContext = class
  private
    fCamera: TCamera;
    fGL: TJSWebGLRenderingContext;
    fRenderTarget: TRenderTarget;
    procedure SetRenderTarget(AValue: TRenderTarget);
  public
    constructor Create(AGL: TJSWebGLRenderingContext);

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

  TRenderable = class
  protected
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); virtual; abstract;
  end;

  TTile = class
  public
  end;

  TTerrain = class(TRenderable)
  private
    fHeight: longint;
    fWidth: longint;
    fTiles: array of TTile;
    function GetTile(AX, AY: longint): TTile;
  protected
    procedure Render(AContext: TRenderContext; APosition: TPoint; ARotation: double); override;
  public
    function Pick(AContext: TRenderContext; AX, AY: longint): TTile;

    constructor Create(AData: TJSArrayBuffer);

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
  protected
    procedure StartState(AState: TGameState); override;
    procedure InitGame;
    procedure RenderFrame; override;
  end;

implementation

uses
  math;

procedure TCharacterModel.Render(AContext: TRenderContext; APosition: TPoint; ARotation: double);
begin
end;

procedure TRenderContext.SetRenderTarget(AValue: TRenderTarget);
begin
  if fRenderTarget=AValue then Exit;
  fRenderTarget:=AValue;

  {if fRenderTarget=nil then
    GL.bindFramebuffer();}
end;

constructor TRenderContext.Create(AGL: TJSWebGLRenderingContext);
begin
  inherited Create;
  fGL:=AGL;
  fCamera:=TCamera.Create(TMatrix.Orthographic(-1,1,-1,1,-1,1));
end;

constructor TPoint.Create(AX, AY, AZ: double);
begin
  inherited Create;
  fX:=AX;
  fY:=AY;
  fZ:=AZ;
end;

function TTerrain.GetTile(AX, AY: longint): TTile;
begin
  result:=fTiles[AX+AY*fWidth];
end;

procedure TTerrain.Render(AContext: TRenderContext; APosition: TPoint; ARotation: double);
begin
end;

function TTerrain.Pick(AContext: TRenderContext; AX, AY: longint): TTile;
var
  buf: TJSUint32Array;
  offset: longword;
begin
  AContext.GL.clearColor(1,1,1,1);
  AContext.GL.clear(AContext.GL.COLOR_BUFFER_BIT or AContext.GL.DEPTH_BUFFER_BIT);
  Render(AContext, TPoint.Create(0,0), 0);

  buf:=TJSUint32Array.new(1);
  AContext.GL.readPixels(AX,AY,1,1,AContext.GL.RGBA,AContext.GL.UNSIGNED_BYTE,buf);
  offset:=buf.values[0];

  AContext.GL.clear(AContext.GL.COLOR_BUFFER_BIT or AContext.GL.DEPTH_BUFFER_BIT);

  result:=nil;
end;

constructor TTerrain.Create(AData: TJSArrayBuffer);
begin
  inherited Create;
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
  fContext.Camera.Modelview.RotateX(DegToRad(30)).RotateZ(DegToRad(45));
end;

procedure TLD46.RenderFrame;
begin
end;

end.

