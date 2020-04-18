unit init;

{$mode objfpc}

interface

uses
  JS, Web;

procedure InitStart;
procedure InitProgress(AProgress: double; const AMessage: string);
procedure InitStop;

implementation

var
  cnv: TJSHTMLCanvasElement;
  rc: TJSCanvasRenderingContext2D;
  fProgress: double = 1.0;

procedure Repaint;
var
  x, y: double;
begin
  rc.fillStyle:='#000000';
  rc.fillRect(0,0,cnv.width,cnv.height);

  x:=cnv.width/2;
  y:=cnv.height/2;

  rc.fillStyle:='#CCCCCC';
  rc.font:='30px Arial';
  rc.textAlign:='center';
  rc.textBaseline:='Bottom';
  rc.fillText('Loading...',x,y-10);

  rc.fillRect(x-x/2,y,x,30);
  rc.fillStyle:='#000000';
  rc.fillRect(x-x/2+4,y+4,x-8,22);
  rc.fillStyle:='#CCCCCC';
  rc.fillRect(x-x/2+8,y+8,(x-16)*fProgress,14);
end;
         
function Resized(Event: TEventListenerEvent): boolean;
begin
  cnv.width:=window.innerWidth;
  cnv.height:=window.innerHeight;

  Repaint;

  result:=true;
end;

procedure InitStart;
begin
  cnv:=TJSHTMLCanvasElement(document.createElement('canvas'));
  cnv.width:=window.innerWidth;
  cnv.height:=window.innerHeight;
  cnv.style.setProperty('position','absolute');
  cnv.style.setProperty('z-index','1');
  document.body.appendChild(cnv);

  window.addEventListener('resize', @Resized);

  rc:=TJSCanvasRenderingContext2D(cnv.getContext('2d'));

  Repaint;
end;

procedure InitProgress(AProgress: double; const AMessage: string);
begin
  fProgress:=AProgress;
  Repaint;
end;

procedure InitStop;
begin                        
  window.removeEventListener('resize', @Resized);
  document.body.removeChild(cnv);

  rc:=Nil;
  cnv:=nil;
end;

end.

