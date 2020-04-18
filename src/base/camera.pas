unit camera;

{$mode objfpc}

interface

uses
  Matrix;

type
  TCamera = class
  private
    fModelview,
    fProjection: TMatrix;
  public
    constructor Create(AProjection: TMatrix);
                                          
    procedure RotateX(AAngle: double);
    procedure RotateY(AAngle: double);
    procedure RotateZ(AAngle: double);
    procedure Translate(AX,AY,AZ: double);
    procedure Scale(AX,AY,AZ: double);

    property Projection: TMatrix read fProjection write fProjection;
    property Modelview: TMatrix read fModelview;
  end;

implementation

constructor TCamera.Create(AProjection: TMatrix);
begin
  inherited Create;
  fProjection:=AProjection;
  fModelview:=TMatrix.Identity;
end;

procedure TCamera.RotateX(AAngle: double);
var
  next: TMatrix;
begin
  next:=fModelview.RotateX(AAngle);
  fModelview.Free;
  fModelview:=next;
end;

procedure TCamera.RotateY(AAngle: double);
var
  next: TMatrix;
begin
  next:=fModelview.RotateY(AAngle);
  fModelview.Free;
  fModelview:=next;
end;

procedure TCamera.RotateZ(AAngle: double);
var
  next: TMatrix;
begin
  next:=fModelview.RotateZ(AAngle);
  fModelview.Free;
  fModelview:=next;
end;

procedure TCamera.Translate(AX, AY, AZ: double);
var
  next: TMatrix;
begin
  next:=fModelview.Translate(ax,ay,az);
  fModelview.Free;
  fModelview:=next;
end;

procedure TCamera.Scale(AX, AY, AZ: double);
var
  next: TMatrix;
begin
  next:=fModelview.Scale(ax,ay,az);
  fModelview.Free;
  fModelview:=next;
end;

end.

