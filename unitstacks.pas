unit UnitStacks;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TOpArray = array of String[6];


type
  TOperatorStack = Class(TObject) //Virtual Stack
  private
    Stack : TOpArray;
    Pos   : SmallInt;
  public
    constructor Create;
    function StkIndex (): SmallInt;
    function StkMem(): String;
    procedure AddStkMem(Input : String);
    procedure RemoveStkMem();
    procedure Print();
  end;

implementation

constructor TOperatorStack.Create;
begin
  Pos := -1;
  Writeln('INIT');
end;

function TOperatorStack.StkIndex() : SmallInt;
begin
  StkIndex := Pos;
end;

function TOperatorStack.StkMem() : String;  //acessor
begin
  if Pos <> -1
    then StkMem := Stack[Pos];
end;

procedure TOperatorStack.AddStkMem(Input : String);
begin
  Pos := Pos + 1;
  Writeln('incriment caused by: ', Input);
  Writeln('add pos = ', Pos);
  SetLength(Stack, Pos + 1);
  Stack[Pos] := Input;
end;

procedure TOperatorStack.RemoveStkMem();
begin
  if (Pos <> -1)
    then
      if Pos = 0
        then Stack[0] := ''
        else
          begin
            Writeln('remove pos = ', Pos);
            Stack := Copy(Stack, 0, Pos);

            //copies the number of elements
            //not elements at index <= Pos
          end;
  Pos := Pos - 1;
end;

procedure TOperatorStack.Print();

var
  i : Byte;

begin
  for i := 0 to Pos do
    Writeln('OpStk: ', Stack[i]);
end;
end.
