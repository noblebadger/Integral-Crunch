unit UserFunctionMKII; //Written By Adam White

{$mode objfpc}{$H+}

interface

uses
  Classes, Math, StrUtils, UnitStacks;

type
  Tx = Record
    Co, Csnt : Real;
    Op       : String[4];
  end;

type
  TPostFix = array[0..9] of Tx;

type
  TUserFunction = Class(TObject)
  private
    PPos    : Byte;
    procedure StBrackets (Op : Char; var OpStack : TOperatorStack);
    function GetPrec(Op : String): Byte;
    procedure StOperator(Op : Char; var OpStack : TOperatorStack);
    procedure StOperand(Oprd : String);
    function StdMathFunction(Input : Real; Func : String): Real;
  public
    Postfix : TPostFix;
    constructor Create;
    procedure InfixToPostfix(var InptStr : String);
    function f(x : Real): Real; //Evalute User function
end;

implementation

constructor TUserFunction.Create;

var
  i : Byte;

begin
  PPos := 0;
  for i := 0 to 9 do
    begin
      Postfix[i].Op   := '';
      Postfix[i].Co   := 1;
      Postfix[i].Csnt := 0;
    end;
end;

procedure TUserFunction.StBrackets (Op : Char; var OpStack : TOperatorStack);
begin
  with OpStack do
    begin
      if (Op = '(') //check for function
        then AddStkMem(Op)
        else
          begin
            while Pos('(', StkMem) = 0 do
              begin
                Writeln('StkMem =', StkMem);
                Postfix[PPos].Op := StkMem;
                PPos := PPos + 1;
                RemoveStkMem;
              end;
            if StkMem = '('
              then RemoveStkMem
              else
                begin
                  Postfix[PPos].Op := StkMem;
                  PPos := PPos + 1;
                  RemoveStkMem;
                end;
          end;
    end; // looks for open brackets or function
end;

function TUserFunction.GetPrec(Op : String): Byte;
begin
  case Op of
     '+' : GetPrec := 2;
     '-' : GetPrec := 2;  //will changing precedence help?
     '/' : GetPrec := 3;
     '*' : GetPrec := 4;
     '^' : GetPrec := 5;
  else GetPrec := 0;
  end;
end;

procedure TUserFunction.StOperator(Op : Char; var OpStack : TOperatorStack);

var
  OpPrec : Byte;

begin
  Writeln('StOperator: ', Op);
  OpPrec := 0;
  if (Op = '(') or (Op = ')')
    then StBrackets(Op, OpStack)
    else
      begin
        OpPrec := GetPrec(Op);
         //gives op a precedence value
        with OpStack do
          begin
            if (OpPrec > GetPrec(StkMem)) or (StkIndex = -1)
              then AddStkMem(Op)
              else
                begin
                  repeat
                    Writeln('operator popped from stack =', Op);
                    Postfix[PPos].Op := StkMem;
                    PPos := PPos + 1;
                    Writeln('StkMem to be removed: ', StkMem);
                    RemoveStkMem;
                  until (OpPrec > GetPrec(StkMem)) or (StkIndex = 0);
                  AddStkMem(Op);
                end;
          end;
      end;
end;

procedure TUserFunction.StOperand(Oprd : String);
                   //Operand
var
  xPos : Byte;
  LStr : String;

begin
  Writeln('Operand Stored: ', Oprd);
  LStr := '';
  xPos := Pos('x', Oprd);
  if xPos <> 0
    then
      begin
        LStr := LeftStr(Oprd, xPos - 1);
        if LStr = ''
          then LStr := '1'
          else
            if LStr = '-'
              then LStr := '-1';
        Val(LStr, Postfix[PPos].Co);
      end
    else Val(Oprd, Postfix[PPos].Csnt);
    PPos := PPos + 1;
end;

procedure TUserFunction.InfixToPostfix(var InptStr : String);

var
  i        : Byte;
  OpStk    : TOperatorStack;
  SubStr   : String;
  FuncBuff : String[6];

begin
  SubStr := '';
  FuncBuff := '';
  OpStk := TOperatorStack.Create;

  for i := 1 to Length(InptStr) do
    case InptStr[i] of
      '+', '*','/',
      ')', '^'      : if (SubStr <> '')
                       then
                         begin
                           StOperand(SubStr);
                           StOperator(InptStr[i], OpStk);
                           SubStr := '';
                         end
                       else  StOperator(InptStr[i], OpStk);
      '-'           : if InptStr[i - 1] = ')'
                        then StOperator(InptStr[i], OpStk)
                        else
                          if SubStr <> ''
                            then
                              begin
                                StOperand(SubStr);
                                StOperator(InptStr[i], OpStk);
                                SubStr := '';
                              end
                            else SubStr := SubStr + InptStr[i];
      'a'..'w'      :  FuncBuff := FuncBuff + InptStr[i];
      '('           :  if FuncBuff = ''
                         then StOperator(InptStr[i], OpStk)
                         else
                           begin
                             OpStk.AddStkMem(FuncBuff + InptStr[i]);
                             Funcbuff := '';
                           end;
    else SubStr := SubStr + InptStr[i];
//free opstk
    end;
  if SubStr <> ''
    then StOperand(SubStr);
  if OpStk.StkIndex <> -1
    then
      begin
        for i := OpStk.StkIndex downto 0 do
          begin
            if Pos('(', OpStk.StkMem) = 0
              then
                begin
                  Postfix[PPos].Op := OpStk.StkMem;
                  Writeln('Opeartor popped from stack at end: ', Postfix[PPos].Op);
                  OpStk.RemoveStkMem;
                  PPos := PPos + 1;
                end;
          end;
      end;
 OpStk.Free;
end;

function TUserFunction.StdMathFunction(Input : Real; Func : String): Real;

var
  n : Real;

begin
  n := 0;
  case Func of
    'sin' : n := sin(Input);
    'tan' : n := tan(Input);
    'cos' : n := cos(Input);
    'sqrt': n := sqrt(Input);
    'log' : n := log10(Input);
    'ln'  : n := ln(Input);
  end;
  StdMathFunction := n;
end;

function TUserFunction.f(x : Real): Real;

var
  i, j, k, l, q: Byte;
  OprdStk : array of Real;
  Total : Real;

begin
  Total := 0;
  i := 0;
  k := 0;
  j := 10;

  repeat
    j := j - 1;
  until (Postfix[j].Op <> '') or (j = 0);

  for i := 0 to j do
    begin
      if Postfix[i].Op <> ''
        then
          begin
            l := Length(OprdStk) - 1; //this will be used to index
            Writeln('l (index) = ', l);
            case Postfix[i].Op of
              '+' : Total := Total + (OprdStk[l - 1] + OprdStk[l]);
              '-' : Total := Total + (OprdStk[l - 1] - OprdStk[l]);
              '*' : Total := Total + (OprdStk[l - 1] * OprdStk[l]);
              '/' : Total := Total + (OprdStk[l - 1] / OprdStk[l]);
              '^' : if Postfix[i - 2].Csnt = 0
                      then Total := Total + Postfix[i - 2].Co * Power(x, OprdStk[l])
                      else Total := Total + Power(OprdStk[l - 1], OprdStk[l]);
            else Total := Total + StdMathFunction(OprdStk[l], Postfix[i].Op);
            end;
            OprdStk := Copy(OprdStk, 1, l - 1);
            for q := 0 to l do
              Writeln('OprdStk Mem = ', OprdStk[q]);
          end
        else
          begin
            if (Postfix[i + 2].Op <> '^') and (Postfix[i].Csnt = 0)
              then Postfix[i].Csnt := Postfix[i].Co * x;
            SetLength(OprdStk, k + 1);
            OprdStk[k] := Postfix[i].Csnt;
            k := k + 1;
          end;
      //work out the associatvitiy of ^ and + -
      //problem with 3+ operands before operator
      //if at odd position then move operands below up
      //this may not apply to functions another small stack could be the way to go
    end;

  f := Total;
end;


end.
