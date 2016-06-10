program IntegralCrunch;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, NumericalIntegrationGUI, fcllaz, UnitStacks, userfunctionmkiii,
  tachartlazaruspkg;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfrmNumericalIntegration, frmNumericalIntegration);
  Application.Run;
end.

