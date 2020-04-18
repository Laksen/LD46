unit menusystem;

{$mode objfpc}

interface

uses
  Classes, SysUtils,
  webgl,
  Font, Camera;

type
  TOnClickEvent = procedure of object;

  TButton = class
  private
    fLeft: integer;
    FOnClick: TOnClickEvent;
    fSize: double;
    fText: string;
    fTop: integer;
  public
    constructor Create;

    property Text: string read fText write fText;
    property Size: double read fSize write fSize;

    property Left: integer read fLeft write fLeft;
    property Top: integer read fTop write fTop;

    property OnClick: TOnClickEvent read FOnClick write FOnClick;
  end;

  TMenu = class
  private
    fFont: TFont;
    fButtons: TList;
    fSelection: TButton;
  public
    procedure Render(ACamera: TCamera; gl: TJSWebGLRenderingContext);

    function AddButton: TButton;

    constructor Create(AFont: TFont);
  end;

implementation

constructor TButton.Create;
begin

end;

procedure TMenu.Render(ACamera: TCamera; gl: TJSWebGLRenderingContext);
var
  i: Integer;
  col: longword;
  btn: TButton;
begin
  for i:=0 to fButtons.Count-1 do
  begin
    btn:=TButton(fButtons[i]);

    col:=$FFFFFFFF;
    if fSelection=btn then
      col:=$00FF00FF;

    fFont.Draw(ACamera.Projection, ACamera.Modelview.Translate(btn.Left,btn.Top,0),
               btn.Text, col, gl);
  end;
end;

function TMenu.AddButton: TButton;
begin
  result:=TButton.Create;
  fButtons.Add(result);

  if fSelection=nil then
    fSelection:=result;
end;

constructor TMenu.Create(AFont: TFont);
begin
  inherited Create;
  fFont:=AFont;
  fButtons:=TList.Create;
  fSelection:=nil;
end;

end.

