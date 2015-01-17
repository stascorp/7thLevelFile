{
	7th Level MIDI converter v0.1 by Stas'M

	This tool is a part of 7th Level File Manager project.

	Copyright (C) Stas'M Corp. 2012
	http://stascorp.com/

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
}
program midi7th;

{$APPTYPE CONSOLE}

{$R *.dres}

uses
  SysUtils,
  Classes,
  Res;

const
  sHead: AnsiString = 'MThd';
  sTrack: AnsiString = 'MTrk';

type
  Header_7LM = record
    Size: Word;
    resId: Word;
  end;
  Header_MIDI = record
    Typ: Word;
    Cnt: Word;
    Spd: Word;
  end;

var
  fI, fO, I, O: TMemoryStream;
  OutFile: String;

function SwapEndian(Value: LongWord): LongWord; register; overload;
asm
  bswap eax
end;

function SwapEndian(Value: Word): Word; register; overload;
asm
  xchg  al, ah
end;

procedure ReadMidi;
const
  Err = 'Error: Input file is not MIDI file.';
var
  hd: Header_MIDI;
  sig: Array[0..4] of AnsiChar;
  dw: LongWord;
begin
  if fI.Size < SizeOf(hd) + 8 then begin
    Writeln(Err);
    Halt(1);
  end;

  sig[4]:=#0;
  fI.ReadBuffer(sig, 4);
  if StrPas(sig)<>sHead then begin
    Writeln(Err);
    Halt(1);
  end;

  fI.ReadBuffer(dw, 4);
  dw := SwapEndian(dw);
  if dw < SizeOf(hd) then begin
    Writeln(Err);
    Halt(1);
  end;

  fI.ReadBuffer(hd, SizeOf(hd));
  hd.Typ := SwapEndian(hd.Typ);
  hd.Cnt := SwapEndian(hd.Cnt);
  hd.Spd := SwapEndian(hd.Spd);
  if hd.Typ <> 0 then begin
    Writeln('Error: Only MIDI Type 0 can be converted.');
    Halt(1);
  end;
  if hd.Cnt < 1 then begin
    Writeln('Error: No tracks found.');
    Halt(1);
  end;
  if hd.Cnt > 1 then begin
    Writeln('Error: MIDI Type 0 must have only one track.');
    Halt(1);
  end;

  fI.Seek(dw - SizeOf(hd), soCurrent);
  fI.ReadBuffer(sig, 4);
  if StrPas(sig)<>sTrack then begin
    Writeln('Error: Track expected but MTrk signature not found.');
    Halt(1);
  end;

  fI.ReadBuffer(dw, 4);
  dw := SwapEndian(dw);
  if dw > fI.Size-22 then begin
    Writeln('Error: Wrong file size. Possibly file is truncated.');
    Halt(1);
  end;

  Writeln('Standard MIDI format detected.');

  I:=TMemoryStream.Create;
  I.SetSize(dw);
  fI.ReadBuffer(I.Memory^, dw);
end;

procedure Read7lm;
var
  hd: Header_7LM;
begin
  if fI.Size < SizeOf(hd) then begin
    Writeln('Error: Wrong file size.');
    Halt(1);
  end;

  fI.ReadBuffer(hd, sizeof(hd));

  if fI.Size < hd.Size + SizeOf(hd) then begin
    Writeln('Error: Wrong file size.');
    Halt(1);
  end;

  Writeln('7th Level MIDI format detected.');

  I:=TMemoryStream.Create;
  I.SetSize(hd.Size);
  fI.ReadBuffer(I.Memory^, hd.Size);
end;

procedure WriteMidi;
var
  dw: LongWord;
  hd: Header_MIDI;
begin
  fO:=TMemoryStream.Create;
  fO.WriteBuffer(PAnsiChar(sHead)^, 4);

  dw:=SizeOf(hd);
  dw:=SwapEndian(dw);
  fO.WriteBuffer(dw, 4);

  hd.Typ:=SwapEndian(0);
  hd.Cnt:=SwapEndian(1);
  hd.Spd:=SwapEndian(500);
  fO.WriteBuffer(hd, SizeOf(hd));

  fO.WriteBuffer(PAnsiChar(sTrack)^, 4);

  dw:=SwapEndian(O.Size);
  fO.WriteBuffer(dw, 4);

  O.Seek(0, soFromBeginning);
  fO.WriteBuffer(O.Memory^, O.Size);
end;

procedure Write7lm;
var
  hd: Header_7LM;
begin
  fO:=TMemoryStream.Create;
  hd.Size := O.Size;
  hd.resId:=0;
  fO.WriteBuffer(hd, SizeOf(hd));
  O.Seek(0, soFromBeginning);
  fO.WriteBuffer(O.Memory^, O.Size);
end;

function ReadVarVal(var M: TMemoryStream; var Error: Byte): UInt64;
var
  B,I: Byte;
begin
  Result:=0;
  Error:=0;
  if M.Position >= M.Size then begin
    Error:=2;
    Exit;
  end else
    M.ReadBuffer(B, 1);
  I:=7;
  Result:=B and 127;
  while (B shr 7)=1 do begin
    if M.Position >= M.Size then begin
      Error:=2;
      Exit;
    end else
      M.ReadBuffer(B, 1);
    if I+7 <= 64 then
      Inc(I, 7)
    else begin
      Error:=1;
      Break;
    end;
    Result:=(Result shl 7) or (B and 127);
  end;
end;

procedure WriteVarVal(var M: TMemoryStream; Val: UInt64);
var
  I: Integer;
  A: Array of Byte;
begin
  while True do begin
    SetLength(A, Length(A)+1);
    A[Length(A)-1]:=Val and 127;
    Val:=Val shr 7;
    if Val=0 then
      Break;
  end;
  for I:=Length(A)-1 downto 0 do begin
    if I>0 then
      A[I]:=A[I] or 128;
    M.WriteBuffer(A[I],1);
  end;
end;

procedure Encode;
type
  Rec = record
    Parm1: Byte;
    Parm2: Byte;
    Parm3: Byte;
    IsDelay: Byte;
  end;
var
  R: Rec;
  B: Byte;
  Err: Byte;
  dw: LongWord;
  Delay: UInt64;
begin
  while I.Position < I.Size do begin
    Delay:=ReadVarVal(I, Err);
    if Delay > 0 then begin
      dw := Delay;
      dw := dw or $80000000;
      O.WriteBuffer(dw, 4);
    end;
    I.ReadBuffer(B, 1);
    case B shr 4 of
      $8..$B, $E: begin
        R.Parm1:=B;
        I.ReadBuffer(R.Parm2, 1);
        I.ReadBuffer(R.Parm3, 1);
      end;
      $C..$D: begin
        R.Parm1:=B;
        I.ReadBuffer(R.Parm2, 1);
        R.Parm3:=0;
      end;
      $F: begin
        if B = $FF then begin
          I.ReadBuffer(B, 1);
          if B <> $2F then begin
            Writeln('Error: Meta events isn''t supported.');
            Halt(1);
          end else
            Break;
        end else begin
          Writeln('Error: System events isn''t supported.');
          Halt(1);
        end;
      end;
      else begin
        Writeln('Error: Status byte expected but not recieved.');
        Halt(1);
      end;
    end;
    O.WriteBuffer(R, SizeOf(R));
  end;
end;

procedure Decode;
type
  Rec = record
    Parm1: Byte;
    Parm2: Byte;
    Parm3: Byte;
    Parm4: Byte;
  end;
var
  R: Rec;
  Delay: UInt64;
begin
  Delay:=0;
  while I.Position < I.Size do begin
    I.ReadBuffer(R, SizeOf(R));
    if R.Parm4 = $80 then
      Delay:=Delay + R.Parm1 or (R.Parm2 shl 8) or (R.Parm3 shl 16)
    else begin
      WriteVarVal(O, Delay);
      Delay:=0;
      case R.Parm1 shr 4 of
        $8..$B, $E: begin
          O.WriteBuffer(R.Parm1, 1);
          O.WriteBuffer(R.Parm2, 1);
          O.WriteBuffer(R.Parm3, 1);
        end;
        $C..$D: begin
          O.WriteBuffer(R.Parm1, 1);
          O.WriteBuffer(R.Parm2, 1);
        end;
      end;
    end;
  end;
  WriteVarVal(O, Delay);
  R.Parm1:=$FF;
  R.Parm2:=$2F;
  R.Parm3:=$00;
  O.WriteBuffer(R.Parm1, 1);
  O.WriteBuffer(R.Parm2, 1);
  O.WriteBuffer(R.Parm3, 1);
end;

begin
  Writeln('7th Level MIDI converter v0.1');
  Writeln('Copyright (C) Stas''M Corp. 2012');
  Writeln('');
  if ParamCount = 0 then begin
    Writeln('USAGE:');
    Writeln('midi7th.exe <-l> <-e|-d> <input file> [output file]');
    Writeln('');
    Writeln('-l           show license agreement');
    Writeln('-e           convert MIDI to 7LM');
    Writeln('  input file   [*.mid] MIDI file');
    Writeln('  output file  [*.7lm] 7th Level MIDI file');
    Writeln('-d           convert 7LM to MIDI');
    Writeln('  input file   [*.7lm] 7th Level MIDI file');
    Writeln('  output file  [*.mid] MIDI file');
    Halt(0);
  end;
  if ParamStr(1) = '-l' then begin
    Writeln(ExtractResText('license'));
    Halt(0);
  end;
  if (ParamStr(1) <> '-e') and (ParamStr(1) <> '-d') then begin
    Writeln('Error: No correct mode specified.');
    Halt(1);
  end;
  if ParamCount = 1 then begin
    Writeln('Error: No input file specified.');
    Halt(1);
  end;

  if ParamStr(1) = '-e' then
    if
    (ExtractFileExt(ParamStr(2)) <> '.mid')
    then begin
      Writeln('Error: File extension not supported in encoding mode.');
      Halt(1);
    end;
  if ParamStr(1) = '-d' then
    if
    (ExtractFileExt(ParamStr(2)) <> '.7lm')
    then begin
      Writeln('Error: File extension not supported in decoding mode.');
      Halt(1);
    end;
  if not FileExists(ParamStr(2)) then begin
    Writeln('Error: Input file doesn''t exists!');
    Halt(1);
  end;
  fI := TMemoryStream.Create;
  try
    fI.LoadFromFile(ParamStr(2));
  except
    on E: Exception do begin
      Writeln('Error: '+E.Message);
      Halt(1);
    end;
  end;

  O := TMemoryStream.Create;
  if ParamStr(1) = '-e' then begin
    if ExtractFileExt(ParamStr(2)) = '.mid' then
      ReadMidi;
    Encode;
  end;
  if ParamStr(1) = '-d' then begin
    if ExtractFileExt(ParamStr(2)) = '.7lm' then
      Read7lm;
    Decode;
  end;

  if Pointer(I) = Pointer(fI) then
    fI.Free
  else begin
    I.Free;
    fI.Free;
  end;
  Writeln('Saving...');

  if ParamCount = 3 then begin
    OutFile := ParamStr(3);
    if ParamStr(1) = '-e' then
      Write7lm;
    if ParamStr(1) = '-d' then
      WriteMidi;
  end else begin
    if ParamStr(1) = '-e' then begin
      Write7lm;
      OutFile := ExtractFilePath(ParamStr(2))+ExtractFileName(ParamStr(2))+'.7lm';
    end;
    if ParamStr(1) = '-d' then begin
      WriteMidi;
      OutFile := ExtractFilePath(ParamStr(2))+ExtractFileName(ParamStr(2))+'.mid';
    end;
  end;

  try
    fO.SaveToFile(OutFile);
  except
    on E: Exception do begin
      fO.Free;
      Writeln('Error: '+E.Message);
      Halt(1);
    end;
  end;
  if Pointer(O) = Pointer(fO) then
    fO.Free
  else begin
    O.Free;
    fO.Free;
  end;
  Writeln('Done.');
  Halt(2);
end.
