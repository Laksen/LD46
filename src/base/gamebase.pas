unit gamebase;

{$mode objfpc}

interface

uses
  init, resources;

type
  TGameState = (
    gsInit,
    gsLoad,
    gsMenu
  );

  TCustomGame = class
  private
    fState: TGameState;
    procedure DoLoad(const AResource: string; AProgress: double);
    procedure DoneLoad;
  protected
    procedure StartState(AState: TGameState); virtual;
    procedure RegisterResources; virtual;
    procedure RenderFrame; virtual;
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

procedure TCustomGame.StartState(AState: TGameState);
begin
end;

procedure TCustomGame.DoLoad(const AResource: string; AProgress: double);
begin
  InitProgress(AProgress, 'Loaded ' + AResource);
end;

procedure TCustomGame.RegisterResources;
begin
end;

procedure TCustomGame.RenderFrame;
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
        StartState(gsInit);

        InitStart;

        RegisterResources;
        fState:=gsLoad;
        StartState(gsLoad);

        resources.LoadResources(@DoLoad, @DoneLoad);
      end;
    gsLoad:
      begin
        // Should not happen
      end;
    gsMenu:
      begin

      end;
  end;
end;

end.

