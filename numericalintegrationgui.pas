unit NumericalIntegrationGUI; //Written by Adam White

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, StdCtrls, Spin, userfunctionmkiii,
  TACustomSeries, Math, RegExpr;

type

  { TfrmNumericalIntegration }

  TfrmNumericalIntegration = class(TForm)
    btnCalculate: TButton;
    btnExit: TButton;
    chtGraph: TChart;
    cboNumericalMethod: TComboBox;
    chtAreaCal: TAreaSeries;
    fsedtLwBnd: TFloatSpinEdit;
    fsedtUpBnd: TFloatSpinEdit;
    lblInstruc: TLabel;
    lblTwo: TLabel;
    lblAnswer: TLabel;
    lblAreaBounds: TLabel;
    ledtEquationInput: TLabeledEdit;
    sedtPwr: TSpinEdit;
    procedure btnCalculateClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmNumericalIntegration : TfrmNumericalIntegration;
  UserFunction : TUserFunction;
  PrevInput : String;

implementation

{$R *.lfm}

//METHOD FUNCTIONS

function InitH (LwBounds, UpBounds : Real; StripNo : Integer) : Real;
begin
  { gives the 'height' of each strip }
  Inith := ((UpBounds - LwBounds) / StripNo);
end;

function TrapeziumRule (h, LwBound, UpBound : Real; UserFunction : TUserFunction) : Real;

var
  x, Sum  : Real;

begin
  Sum := 0;
  x := LwBound + h;
  { Initialises x to take the value of x1 }
  with UserFunction do
    begin
      { Finds the sum of terms between y1 and y n- 1 }
      while (x <= UpBound - h) do
        begin
          Sum := Sum + f(x);
          x := x + h;
        end;
      { h/2  * ( y0  +  yn + 2( y1 + y2 + y3 + yn-1)) }
      TrapeziumRule := (h/2) * ((f(LwBound) + f(UpBound)) + (2 * (Sum)));
    end;
end;

function MidpointRule (h, LwBound : Real; NoOfStrips : Integer; UserFunction : TUserFunction) : Real;

var
  n : Integer;
  Sum : Real;

begin
  Sum := 0;
  for n := 0 to (NoOfStrips - 1) do
    begin
      { Find the area of each rectangle (height * base  and sums it }
      Sum := Sum + h * UserFunction.f(LwBound + (n * h) + h/2);
    end;
  MidpointRule := Sum;
end;

function SimpsonsRule (h, LwBound, UpBound : Real; NoOfStrips : Integer; UserFunction : TUserFunction): Real;
begin
  { Using simpsons rule according to the weighted average }
  SimpsonsRule := (2*MidpointRule(h, LwBound, NoOfStrips, UserFunction) +
                   TrapeziumRule(h, LwBound, Upbound, UserFunction)) /3
end;

function CheckExpression (Expr : String): Boolean;
var
  RegexObj: TRegExpr;

begin
  CheckExpression := False;
  RegexObj := TRegExpr.Create;
  { multiple operators }
  RegexObj.Expression := '\w*(((\/|\*|\^){2,})|((\-|\+){2,}))\w*';
  if RegexObj.Exec(Expr) then
    CheckExpression := True;
  RegexObj.Free;
end;

{ Events }

{ TfrmNumericalIntegration }

{ This is my GUI and is resposible for
  handling the events of each widget and
  interfacing with my major objects. }

procedure TfrmNumericalIntegration.FormCreate(Sender: TObject);
begin
  PrevInput := '';
  UserFunction := TUserFunction.Create;
end;

procedure TfrmNumericalIntegration.btnCalculateClick(Sender: TObject);

var
  h, Answer, x : Real;
  Strips,  i : Integer;
  SPostfix : String;

begin
  Answer := 0;
  { Clears the graph each time }
  chtAreaCal.Clear;
  x := 0;
   if ledtEquationInput.Text = '' then
     ShowMessage('No function input')
     else
       begin
         if PrevInput <> ledtEquationInput.Text then
           begin
             UserFunction.ClearArray;
             if CheckExpression(ledtEquationInput.Text) then
               ShowMessage('Function syntax error') else
               UserFunction.InfixToPostfix(ledtEquationInput.Text);
           end;

               Strips := Trunc(intPower(2, sedtPwr.Value));
               if fsedtLwBnd.Value >= fsedtUpBnd.Value then
                 ShowMessage('Bounds error')
                 else
                   begin
                     h := InitH(fsedtLwBnd.Value, fsedtUpBnd.Value, Strips);
                     try
                       case cboNumericalMethod.ItemIndex of
                        -1 : ShowMessage('No rule selected');
                         0 : begin
                               Answer := MidpointRule(h, fsedtLwBnd.Value, Strips, UserFunction);
                               chtAreaCal.ConnectType := ctStepXY;
                               chtAreaCal.SeriesColor := clMenuHighlight;
                             end;
                         1 : begin
                               Answer := TrapeziumRule(h, fsedtLwBnd.Value, fsedtUpBnd.Value, UserFunction);
                               chtAreaCal.ConnectType := ctLine;
                               chtAreaCal.SeriesColor := clHotLight;
                             end;
                         2 : begin
                               Answer := SimpsonsRule(h, fsedtLwBnd.Value, fsedtUpBnd.Value, Strips, UserFunction);
                               chtAreaCal.ConnectType := ctLine;
                               chtAreaCal.SeriesColor := $002967F8;
                             end;
                       end;
                       { Index validation check independant of case
                         so can display error even bounds are correct }
                      lblAnswer.Caption := 'Answer = ' + FloatToStr(Answer);
                      lblAnswer.Visible := True;
                      { Sets area style depending on number of strips }
                      if sedtPwr.Value > 8
                        then chtAreaCal.AreaLinesPen.Style := psClear
                        else chtAreaCal.AreaLinesPen.Style := psSolid;
                      { Displays function and area to be found on graph }

                      x := fsedtLwBnd.Value;
                      for i := 0 to (Strips)  do
                        begin
                          chtAreaCal.AddXY(x, UserFunction.f(x));
                          x := x + h;
                        end;
                     except
                       on E : EMathError do
                              begin
                                ShowMessage('Math error')
                              end;
                       on E : EDivByZero do
                              begin
                                ShowMessage('Division by zero');
                                //UserFunction.ClearArray;
                              end;
                       on E : EInvalidPointer do
                              begin
                                ShowMessage('Function syntax error');
                                //UserFunction.ClearArray;
                              end;
                       on E : EAccessViolation do
                              begin
                                ShowMessage('Function syntax error');
                                //UserFunction.ClearArray;
                              end;
                     end;{ put clear array in finally statement }
                   end;
             end;
         PrevInput := ledtEquationInput.Text;
end;


procedure TfrmNumericalIntegration.btnExitClick(Sender: TObject);
begin
  UserFunction.Free; { Destructor }
  Close;
end;


end.

