unit matrix;

{$mode objfpc}

interface

uses
  JS;

type
  TMatrix = class
  private
    fValues: TJSFloat32Array;
    function GetArray: TJSFloat32Array;
    function GetValue(ARow, ACol: integer): double;
    procedure SetValue(ARow, ACol: integer; AValue: double);
  public
    constructor Create;

    constructor Identity;
    constructor Perspective(AFoV, AAspectRatio, AZNear, AZFar: double);
    constructor Orthographic(ALeft, ARight, ABottom, ATop, AZNear, AZFar: double);

    constructor RotationX(AAngle: double);
    constructor RotationY(AAngle: double);
    constructor RotationZ(AAngle: double);
    constructor Translation(AX,AY,AZ: double);

    function RotateX(AAngle: double): TMatrix;
    function RotateY(AAngle: double): TMatrix;
    function RotateZ(AAngle: double): TMatrix;
    function Translate(AX,AY,AZ: double): TMatrix;

    function Invert: TMatrix;

    function Multiply(B: TMatrix): TMatrix;
    class function Multiply(A,B: TMatrix): TMatrix;

    function ToString: String; override;

    property Copy: TJSFloat32Array read GetArray;
    property M[ARow,ACol: integer]: double read GetValue write SetValue;
  end;

implementation

uses
  SysUtils;

function TMatrix.GetValue(ARow, ACol: integer): double;
begin
  result:=fValues[ARow*4+ACol];
end;

function TMatrix.GetArray: TJSFloat32Array;
begin
  result:=fValues;
end;

procedure TMatrix.SetValue(ARow, ACol: integer; AValue: double);
begin
  fValues[ARow*4+ACol]:=AValue;
end;

constructor TMatrix.Create;
begin
  inherited Create;
  fValues:=TJSFloat32Array.new(16);
end;

constructor TMatrix.Identity;
var
  i, i2: Integer;
begin
  Create;
  for i:=0 to 3 do
    for i2:=0 to 3 do
      if i=i2 then
        M[i,i2]:=1
      else
        M[i,i2]:=0;
end;

constructor TMatrix.Perspective(AFoV, AAspectRatio, AZNear, AZFar: double);
var
  Radians, ZDelta, Sine, Cotangent: Double;
  i, i2: Integer;
begin
  Identity;

  Radians:=(AFoV*0.5)*PI/180;
  ZDelta:=AZFar-AZNear;
  Sine:=sin(Radians);

  if not ((ZDelta=0) or (Sine=0) or (AAspectRatio=0)) then
  begin                                         
    Cotangent:=cos(Radians)/Sine;

    M[0,0]:=Cotangent/AAspectRatio;
    M[1,1]:=Cotangent;
    M[2,2]:=(-(AZFar+AZNear))/ZDelta;
    M[2,3]:=-1-0;
    M[3,2]:=(-(2.0*AZNear*AZFar))/ZDelta;
    M[3,3]:=0.0;
  end
  else
    writeln('Invalid parameters');
end;

constructor TMatrix.Orthographic(ALeft, ARight, ABottom, ATop, AZNear, AZFar: double);
var
  Width, Height, Depth: Double;
begin
  Identity;

  Width:=ARight-ALeft;
  Height:=ATop-ABottom;
  Depth:=AZFar-AZNear;

  M[0,0]:=2.0/Width;
  M[1,1]:=2.0/Height;
  M[2,2]:=(-2.0)/Depth;
  M[3,0]:=(-(ARight+ALeft))/Width;
  M[3,1]:=(-(ATop+ABottom))/Height;
  M[3,2]:=(-(AZFar+AZNear))/Depth;
  M[3,3]:=1.0;
end;

constructor TMatrix.RotationX(AAngle: double);
begin
  Identity;

  M[1,2]:=Sin(AAngle);
  M[1,1]:=Cos(AAngle);
  M[2,1]:=-M[1,2];
  M[2,2]:=M[1,1];
end;

constructor TMatrix.RotationY(AAngle: double);
begin
  Identity;

  M[2,0]:=Sin(AAngle);
  M[0,0]:=Cos(AAngle);
  M[0,2]:=-M[2,0];
  M[2,2]:=M[0,0];
end;

constructor TMatrix.RotationZ(AAngle: double);
begin
  Identity;

  M[0,1]:=Sin(AAngle);
  M[0,0]:=Cos(AAngle);
  M[1,0]:=-M[0,1];
  M[1,1]:=M[0,0];
end;

constructor TMatrix.Translation(AX, AY, AZ: double);
begin
  Identity;

  M[3,0]:=AX;
  M[3,1]:=AY;
  M[3,2]:=AZ;
end;

function TMatrix.RotateX(AAngle: double): TMatrix;
begin
  result:=Multiply(TMatrix.RotationX(AAngle));
end;

function TMatrix.RotateY(AAngle: double): TMatrix;
begin
  result:=Multiply(TMatrix.RotationY(AAngle));
end;

function TMatrix.RotateZ(AAngle: double): TMatrix;
begin
  result:=Multiply(TMatrix.RotationZ(AAngle));
end;

function TMatrix.Translate(AX, AY, AZ: double): TMatrix;
begin
  result:=Multiply(TMatrix.Translation(AX, AY, AZ));
end;

function TMatrix.Invert: TMatrix;
var
  d: double;
  t0,t4,t8,t12: double;
begin
  t0:=(((M[1,1]*M[2,2]*M[3,3])-(M[1,1]*M[2,3]*M[3,2]))-(M[2,1]*M[1,2]*M[3,3])+(M[2,1]*M[1,3]*M[3,2])+(M[3,1]*M[1,2]*M[2,3]))-(M[3,1]*M[1,3]*M[2,2]);
  t4:=((((-(M[1,0]*M[2,2]*M[3,3]))+(M[1,0]*M[2,3]*M[3,2])+(M[2,0]*M[1,2]*M[3,3]))-(M[2,0]*M[1,3]*M[3,2]))-(M[3,0]*M[1,2]*M[2,3]))+(M[3,0]*M[1,3]*M[2,2]);
  t8:=((((M[1,0]*M[2,1]*M[3,3])-(M[1,0]*M[2,3]*M[3,1]))-(M[2,0]*M[1,1]*M[3,3]))+(M[2,0]*M[1,3]*M[3,1])+(M[3,0]*M[1,1]*M[2,3]))-(M[3,0]*M[1,3]*M[2,1]);
  t12:=((((-(M[1,0]*M[2,1]*M[3,2]))+(M[1,0]*M[2,2]*M[3,1])+(M[2,0]*M[1,1]*M[3,2]))-(M[2,0]*M[1,2]*M[3,1]))-(M[3,0]*M[1,1]*M[2,2]))+(M[3,0]*M[1,2]*M[2,1]);

  d:=(M[0,0]*t0)+(M[0,1]*t4)+(M[0,2]*t8)+(M[0,3]*t12);

  result := TMatrix.Identity;
  if d<>0.0 then begin
    d:=1.0/d;
    result.M[0,0]:=t0*d;
    result.M[0,1]:=(((((-(M[0,1]*M[2,2]*M[3,3]))+(M[0,1]*M[2,3]*M[3,2])+(M[2,1]*M[0,2]*M[3,3]))-(M[2,1]*M[0,3]*M[3,2]))-(M[3,1]*M[0,2]*M[2,3]))+(M[3,1]*M[0,3]*M[2,2]))*d;
    result.M[0,2]:=(((((M[0,1]*M[1,2]*M[3,3])-(M[0,1]*M[1,3]*M[3,2]))-(M[1,1]*M[0,2]*M[3,3]))+(M[1,1]*M[0,3]*M[3,2])+(M[3,1]*M[0,2]*M[1,3]))-(M[3,1]*M[0,3]*M[1,2]))*d;
    result.M[0,3]:=(((((-(M[0,1]*M[1,2]*M[2,3]))+(M[0,1]*M[1,3]*M[2,2])+(M[1,1]*M[0,2]*M[2,3]))-(M[1,1]*M[0,3]*M[2,2]))-(M[2,1]*M[0,2]*M[1,3]))+(M[2,1]*M[0,3]*M[1,2]))*d;
    result.M[1,0]:=t4*d;
    result.M[1,1]:=((((M[0,0]*M[2,2]*M[3,3])-(M[0,0]*M[2,3]*M[3,2]))-(M[2,0]*M[0,2]*M[3,3])+(M[2,0]*M[0,3]*M[3,2])+(M[3,0]*M[0,2]*M[2,3]))-(M[3,0]*M[0,3]*M[2,2]))*d;
    result.M[1,2]:=(((((-(M[0,0]*M[1,2]*M[3,3]))+(M[0,0]*M[1,3]*M[3,2])+(M[1,0]*M[0,2]*M[3,3]))-(M[1,0]*M[0,3]*M[3,2]))-(M[3,0]*M[0,2]*M[1,3]))+(M[3,0]*M[0,3]*M[1,2]))*d;
    result.M[1,3]:=(((((M[0,0]*M[1,2]*M[2,3])-(M[0,0]*M[1,3]*M[2,2]))-(M[1,0]*M[0,2]*M[2,3]))+(M[1,0]*M[0,3]*M[2,2])+(M[2,0]*M[0,2]*M[1,3]))-(M[2,0]*M[0,3]*M[1,2]))*d;
    result.M[2,0]:=t8*d;
    result.M[2,1]:=(((((-(M[0,0]*M[2,1]*M[3,3]))+(M[0,0]*M[2,3]*M[3,1])+(M[2,0]*M[0,1]*M[3,3]))-(M[2,0]*M[0,3]*M[3,1]))-(M[3,0]*M[0,1]*M[2,3]))+(M[3,0]*M[0,3]*M[2,1]))*d;
    result.M[2,2]:=(((((M[0,0]*M[1,1]*M[3,3])-(M[0,0]*M[1,3]*M[3,1]))-(M[1,0]*M[0,1]*M[3,3]))+(M[1,0]*M[0,3]*M[3,1])+(M[3,0]*M[0,1]*M[1,3]))-(M[3,0]*M[0,3]*M[1,1]))*d;
    result.M[2,3]:=(((((-(M[0,0]*M[1,1]*M[2,3]))+(M[0,0]*M[1,3]*M[2,1])+(M[1,0]*M[0,1]*M[2,3]))-(M[1,0]*M[0,3]*M[2,1]))-(M[2,0]*M[0,1]*M[1,3]))+(M[2,0]*M[0,3]*M[1,1]))*d;
    result.M[3,0]:=t12*d;
    result.M[3,1]:=(((((M[0,0]*M[2,1]*M[3,2])-(M[0,0]*M[2,2]*M[3,1]))-(M[2,0]*M[0,1]*M[3,2]))+(M[2,0]*M[0,2]*M[3,1])+(M[3,0]*M[0,1]*M[2,2]))-(M[3,0]*M[0,2]*M[2,1]))*d;
    result.M[3,2]:=(((((-(M[0,0]*M[1,1]*M[3,2]))+(M[0,0]*M[1,2]*M[3,1])+(M[1,0]*M[0,1]*M[3,2]))-(M[1,0]*M[0,2]*M[3,1]))-(M[3,0]*M[0,1]*M[1,2]))+(M[3,0]*M[0,2]*M[1,1]))*d;
    result.M[3,3]:=(((((M[0,0]*M[1,1]*M[2,2])-(M[0,0]*M[1,2]*M[2,1]))-(M[1,0]*M[0,1]*M[2,2]))+(M[1,0]*M[0,2]*M[2,1])+(M[2,0]*M[0,1]*M[1,2]))-(M[2,0]*M[0,2]*M[1,1]))*d;
  end;
end;

function TMatrix.Multiply(B: TMatrix): TMatrix;
begin
  result:=TMatrix.Multiply(self,B);
end;

class function TMatrix.Multiply(A, B: TMatrix): TMatrix;
var
  i, i2, i3: Integer;
  sum: double;
begin
  result:=TMatrix.Create;
  for i:=0 to 3 do
    for i2:=0 to 3 do
    begin
      sum:=0;
      for i3:=0 to 3 do
        sum:=sum+A.M[i,i3]*B.M[i3,i2];
      result.M[i,i2]:=Sum;
    end;
end;

function TMatrix.ToString: String;
var
  i, i2: Integer;
begin
  result:='';
  for i:=0 to 2 do
  begin
    result:=result+FloatToStr(M[i,0]);
    for i2:=1 to 3 do
      result:=result+','+FloatToStr(M[i,i2]);
    result:=result+LineEnding;
  end;

  result:=result+FloatToStr(M[3,0]);
  for i2:=1 to 3 do
    result:=result+','+FloatToStr(M[3,i2]);
end;

end.

