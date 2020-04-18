unit font;

interface

uses
  js, WebGL, Matrix;

type
  TCharInfo = record
    Ch: word;
    A,C,
    Width, Height: longint;
    X1,Y1,
    X2,Y2: double;
  end;

  TInfo = record
    Width, Height: double;
  end;

  TFont = class
  private
    fChars: array of TCharInfo;
    fCharLookup: array[byte] of longint;

    fWidth, fHeight: Word;
    fSpaceWidth: longword;
                          
    fBuffer: TJSWebGLBuffer;
    fTex: TJSWebGLTexture;
  public
    function Calc(const AStr: string): TInfo;
    procedure Draw(AProjection, AModelview: TMatrix; const AStr: string; col: longword; gl: TJSWebGLRenderingContext);

    constructor Create(const AFont: TJSArrayBuffer; gl: TJSWebGLRenderingContext);
    destructor Destroy; override;
  end;

implementation

uses
  shaders;

const
  VertShader = 'attribute vec2 aVertexPosition; attribute vec2 aTextureCoord; uniform mat4 uModelViewMatrix; uniform mat4 uProjectionMatrix; varying highp vec2 vTextureCoord; void main(void) { gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aVertexPosition,0.0,1.0); vTextureCoord = aTextureCoord; }';
  FragShader = 'varying highp vec2 vTextureCoord; uniform sampler2D uSampler; void main(void) { gl_FragColor = texture2D(uSampler, vTextureCoord); }';

var
  Shader: TShader = nil;

  vertLocation, texLocation: GLint;
  projectionMatrix, modelViewMatrix, uSampler: TJSWebGLUniformLocation;

procedure InitShader(gl: TJSWebGLRenderingContext);
begin
  if Shader=nil then
  begin
    Shader:=TShader.Create(VertShader, FragShader, gl);

    vertLocation:=gl.getAttribLocation(Shader.Prog, 'aVertexPosition');
    texLocation:=gl.getAttribLocation(Shader.Prog, 'aTextureCoord');

    projectionMatrix:=gl.getUniformLocation(Shader.Prog, 'uProjectionMatrix');
    modelViewMatrix:=gl.getUniformLocation(Shader.Prog, 'uModelViewMatrix');
    uSampler:=gl.getUniformLocation(Shader.Prog, 'uSampler');
  end;
end;

function TFont.Calc(const AStr: string): TInfo;
var
  CurX: double;
  Ch: Widechar;
  Chaar, I, Ind: integer;
begin
  result.Height:=0;
  CurX:=0;

  for I := 1 to length(AStr) do
  begin
    Ch := AStr[I];
    Chaar := integer(ch);

    Ind := fCharLookup[Chaar];

    if ind > -1 then
    begin
      CurX := CurX + fChars[Ind].A;
      if result.Height<fChars[ind].Height then
        result.Height:=fChars[ind].Height;
      CurX := CurX + fChars[Ind].C;
    end;
  end;
  result.Width:=CurX;
end;

procedure TFont.Draw(AProjection, AModelview: TMatrix; const AStr: string; col: longword; gl: TJSWebGLRenderingContext);
var
  CurX: double;
  Ch: Widechar;
  Chaar, I, Ind, quadCount: integer;
  textBuffer: TJSFloat32Array;
begin
  if length(astr)<=0 then exit;

  textBuffer:=TJSFloat32Array.new(length(astr)*(6*4));

  CurX:=0;
  quadCount:=0;

  for I := 0 to length(AStr)-1 do
  begin
    Ch := AStr[I+1];
    Chaar := integer(ch);

    Ind := fCharLookup[Chaar];
    if Ind=-1 then            
      Ind := fCharLookup[32];

    CurX := CurX + fChars[Ind].A;

    textBuffer[quadCount+0]:=CurX;
    textBuffer[quadCount+1]:=0;
    textBuffer[quadCount+2]:=fChars[ind].x1;
    textBuffer[quadCount+3]:=1-fChars[ind].y2;

    textBuffer[quadCount+4+0]:=CurX;
    textBuffer[quadCount+4+1]:=0;
    textBuffer[quadCount+4+2]:=fChars[ind].x1;
    textBuffer[quadCount+4+3]:=1-fChars[ind].y2;

    textBuffer[quadCount+8+0]:=CurX;
    textBuffer[quadCount+8+1]:=fChars[ind].Height;
    textBuffer[quadCount+8+2]:=fChars[ind].x1;
    textBuffer[quadCount+8+3]:=1-fChars[ind].y1;

    textBuffer[quadCount+12+0]:=CurX+fChars[ind].Width;
    textBuffer[quadCount+12+1]:=0;
    textBuffer[quadCount+12+2]:=fChars[ind].x2;
    textBuffer[quadCount+12+3]:=1-fChars[ind].y2;

    textBuffer[quadCount+16+0]:=CurX+fChars[ind].Width;
    textBuffer[quadCount+16+1]:=fChars[ind].Height;
    textBuffer[quadCount+16+2]:=fChars[ind].x2;
    textBuffer[quadCount+16+3]:=1-fChars[ind].y1;

    textBuffer[quadCount+20+0]:=CurX+fChars[ind].Width;
    textBuffer[quadCount+20+1]:=fChars[ind].Height;
    textBuffer[quadCount+20+2]:=fChars[ind].x2;
    textBuffer[quadCount+20+3]:=1-fChars[ind].y1;

    CurX := CurX + fChars[Ind].C;
    inc(quadCount, 6*4);
  end;

  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  // Bind buffers
  gl.bindBuffer(gl.ARRAY_BUFFER, fBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, textbuffer, gl.STREAM_DRAW);

  gl.enableVertexAttribArray(vertLocation);
  gl.enableVertexAttribArray(texLocation);
  gl.vertexAttribPointer(vertLocation, 2, gl.FLOAT, false, 4*4, 0);
  gl.vertexAttribPointer(texLocation,  2, gl.FLOAT, false, 4*4, 2*4);

  // Bind texture
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, fTex);

  // Bind shader
  gl.useProgram(Shader.Prog);
  gl.uniformMatrix4fv(modelViewMatrix, false, AModelview.Copy);
  gl.uniformMatrix4fv(projectionMatrix, false, AProjection.Copy);
  gl.uniform1i(uSampler, 0);

  gl.drawArrays(gl.TRIANGLE_STRIP, 0, quadCount div 4);
end;

constructor TFont.Create(const AFont: TJSArrayBuffer; gl: TJSWebGLRenderingContext);
var
  header: TJSDataView;
  data: TJSUint8Array;
  ofs, i: Integer;
  charCount: LongWord;
begin
  inherited Create;

  InitShader(gl);

  header:=TJSDataView.New(AFont,0);
  fWidth:=header.getUint16(12, true);
  fHeight:=header.getUint16(14, true);

  data:=TJSUint8Array.New(AFont, $12, fWidth*fHeight*4);
  //data:=TJSUint8Array.New(fWidth*fHeight*4);
  //for i:=0 to data.length-1 do data[i]:=$0;

  fTex:=gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, fTex);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, fWidth, fHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
  gl.generateMipmap(gl.TEXTURE_2D);

  // Chars
  header:=TJSDataView.New(AFont,$12+fWidth*fHeight*4);
  ofs:=4;
  charCount:=header.getUint32(ofs, true); inc(ofs,4);
  fSpaceWidth:=header.getUint32(ofs, true); inc(ofs,4);

  setlength(fChars, charCount);

  for i:=0 to high(fCharLookup) do
    fCharLookup[i]:=-1;

  for i:=0 to charCount-1 do
  begin
    fChars[i].Ch:=    header.getInt16(ofs, true); inc(ofs,2);
    fChars[i].A:=     header.getInt32(ofs, true); inc(ofs,4);
    fChars[i].C:=     header.getInt32(ofs, true); inc(ofs,4);
    fChars[i].Width :=header.getInt32(ofs, true); inc(ofs,4);
    fChars[i].Height:=header.getInt32(ofs, true); inc(ofs,4);

    fChars[i].X1:=header.getFloat64(ofs, true); inc(ofs,8);
    fChars[i].Y1:=header.getFloat64(ofs, true); inc(ofs,8);
    fChars[i].X2:=header.getFloat64(ofs, true); inc(ofs,8);
    fChars[i].Y2:=header.getFloat64(ofs, true); inc(ofs,8);

    fCharLookup[fChars[i].Ch and $FF]:=i;
  end;

  writeln('Loaded ', charCount, ' chars');

  fBuffer:=gl.createBuffer;
end;

destructor TFont.Destroy;
begin
end;

end.
