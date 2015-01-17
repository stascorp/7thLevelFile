{
	7th Level ADPCM converter v0.1 by Stas'M

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
program adpcm7th;

{$APPTYPE CONSOLE}

{$R *.dres}

uses
  SysUtils,
  Classes,
  Res;

const
  Table_7thADPCM: Array[0..88, 0..7] of Word =
  ((   0,     1,     3,     4,     7,     8,    10,    11),  //  0
   (   1,     3,     5,     7,     9,    11,    13,    15),  //  1
   (   1,     3,     5,     7,    10,    12,    14,    16),  //  2
   (   1,     3,     6,     8,    11,    13,    16,    18),  //  3
   (   1,     3,     6,     8,    12,    14,    17,    19),  //  4
   (   1,     4,     7,    10,    13,    16,    19,    22),  //  5
   (   1,     4,     7,    10,    14,    17,    20,    23),  //  6
   (   1,     4,     8,    11,    15,    18,    22,    25),  //  7
   (   2,     6,    10,    14,    18,    22,    26,    30),  //  8
   (   2,     6,    10,    14,    19,    23,    27,    31),  //  9
   (   2,     6,    11,    15,    21,    25,    30,    34),  // 10
   (   2,     7,    12,    17,    23,    28,    33,    38),  // 11
   (   2,     7,    13,    18,    25,    30,    36,    41),  // 12
   (   3,     9,    15,    21,    28,    34,    40,    46),  // 13
   (   3,    10,    17,    24,    31,    38,    45,    52),  // 14
   (   3,    10,    18,    25,    34,    41,    49,    56),  // 15
   (   4,    12,    21,    29,    38,    46,    55,    63),  // 16
   (   4,    13,    22,    31,    41,    50,    59,    68),  // 17
   (   5,    15,    25,    35,    46,    56,    66,    76),  // 18
   (   5,    16,    27,    38,    50,    61,    72,    83),  // 19
   (   6,    18,    31,    43,    56,    68,    81,    93),  // 20
   (   6,    19,    33,    46,    61,    74,    88,   101),  // 21
   (   7,    22,    37,    52,    67,    82,    97,   112),  // 22
   (   8,    24,    41,    57,    74,    90,   107,   123),  // 23
   (   9,    27,    45,    63,    82,   100,   118,   136),  // 24
   (  10,    30,    50,    70,    90,   110,   130,   150),  // 25
   (  11,    33,    55,    77,    99,   121,   143,   165),  // 26
   (  12,    36,    60,    84,   109,   133,   157,   181),  // 27
   (  13,    39,    66,    92,   120,   146,   173,   199),  // 28
   (  14,    43,    73,   102,   132,   161,   191,   220),  // 29
   (  16,    48,    81,   113,   146,   178,   211,   243),  // 30
   (  17,    52,    88,   123,   160,   195,   231,   266),  // 31
   (  19,    58,    97,   136,   176,   215,   254,   293),  // 32
   (  21,    64,   107,   150,   194,   237,   280,   323),  // 33
   (  23,    70,   118,   165,   213,   260,   308,   355),  // 34
   (  26,    78,   130,   182,   235,   287,   339,   391),  // 35
   (  28,    85,   143,   200,   258,   315,   373,   430),  // 36
   (  31,    94,   157,   220,   284,   347,   410,   473),  // 37
   (  34,   103,   173,   242,   313,   382,   452,   521),  // 38
   (  38,   114,   191,   267,   345,   421,   498,   574),  // 39
   (  42,   126,   210,   294,   379,   463,   547,   631),  // 40
   (  46,   138,   231,   323,   417,   509,   602,   694),  // 41
   (  51,   153,   255,   357,   459,   561,   663,   765),  // 42
   (  56,   168,   280,   392,   505,   617,   729,   841),  // 43
   (  61,   184,   308,   431,   555,   678,   802,   925),  // 44
   (  68,   204,   340,   476,   612,   748,   884,  1020),  // 45
   (  74,   223,   373,   522,   672,   821,   971,  1120),  // 46
   (  82,   246,   411,   575,   740,   904,  1069,  1233),  // 47
   (  90,   271,   452,   633,   814,   995,  1176,  1357),  // 48
   (  99,   298,   497,   696,   895,  1094,  1293,  1492),  // 49
   ( 109,   328,   547,   766,   985,  1204,  1423,  1642),  // 50
   ( 120,   360,   601,   841,  1083,  1323,  1564,  1804),  // 51
   ( 132,   397,   662,   927,  1192,  1457,  1722,  1987),  // 52
   ( 145,   436,   728,  1019,  1311,  1602,  1894,  2185),  // 53
   ( 160,   480,   801,  1121,  1442,  1762,  2083,  2403),  // 54
   ( 176,   528,   881,  1233,  1587,  1939,  2292,  2644),  // 55
   ( 194,   582,   970,  1358,  1746,  2134,  2522,  2910),  // 56
   ( 213,   639,  1066,  1492,  1920,  2346,  2773,  3199),  // 57
   ( 234,   703,  1173,  1642,  2112,  2581,  3051,  3520),  // 58
   ( 258,   774,  1291,  1807,  2324,  2840,  3357,  3873),  // 59
   ( 284,   852,  1420,  1988,  2556,  3124,  3692,  4260),  // 60
   ( 312,   936,  1561,  2185,  2811,  3435,  4060,  4684),  // 61
   ( 343,  1030,  1717,  2404,  3092,  3779,  4466,  5153),  // 62
   ( 378,  1134,  1890,  2646,  3402,  4158,  4914,  5670),  // 63
   ( 415,  1246,  2078,  2909,  3742,  4573,  5405,  6236),  // 64
   ( 457,  1372,  2287,  3202,  4117,  5032,  5947,  6862),  // 65
   ( 503,  1509,  2516,  3522,  4529,  5535,  6542,  7548),  // 66
   ( 553,  1660,  2767,  3874,  4981,  6088,  7195,  8302),  // 67
   ( 608,  1825,  3043,  4260,  5479,  6696,  7914,  9131),  // 68
   ( 669,  2008,  3348,  4687,  6027,  7366,  8706, 10045),  // 69
   ( 736,  2209,  3683,  5156,  6630,  8103,  9577, 11050),  // 70
   ( 810,  2431,  4052,  5673,  7294,  8915, 10536, 12157),  // 71
   ( 891,  2674,  4457,  6240,  8023,  9806, 11589, 13372),  // 72
   ( 980,  2941,  4902,  6863,  8825, 10786, 12747, 14708),  // 73
   (1078,  3235,  5393,  7550,  9708, 11865, 14023, 16180),  // 74
   (1186,  3559,  5932,  8305, 10679, 13052, 15425, 17798),  // 75
   (1305,  3915,  6526,  9136, 11747, 14357, 16968, 19578),  // 76
   (1435,  4306,  7178, 10049, 12922, 15793, 18665, 21536),  // 77
   (1579,  4737,  7896, 11054, 14214, 17372, 20531, 23689),  // 78
   (1737,  5211,  8686, 12160, 15636, 19110, 22585, 26059),  // 79
   (1911,  5733,  9555, 13377, 17200, 21022, 24844, 28666),  // 80
   (2102,  6306, 10511, 14715, 18920, 23124, 27329, 31533),  // 81
   (2312,  6937, 11562, 16187, 20812, 25437, 30062, 34687),  // 82
   (2543,  7630, 12718, 17805, 22893, 27980, 33068, 38155),  // 83
   (2798,  8394, 13990, 19586, 25183, 30779, 36375, 41971),  // 84
   (3077,  9232, 15388, 21543, 27700, 33855, 40011, 46166),  // 85
   (3385, 10156, 16928, 23699, 30471, 37242, 44014, 50785),  // 86
   (3724, 11172, 18621, 26069, 33518, 40966, 48415, 55863),  // 87
   (4095, 12286, 20478, 28669, 36862, 45053, 53245, 61436)); // 88
   // end of ADPCM table (indexes from zero)
  Adjust: Array[0..15] of ShortInt =
   (-1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8);
  sRIFF: AnsiString = 'RIFF';
  sWAVE: AnsiString = 'WAVE';
  sfmt: AnsiString = 'fmt ';
  sdata: AnsiString = 'data';

type
  Header_7LA = record
    Size: LongWord;
    Dummy1: Word;
    Compressed: Word; // 1
    Dummy2: Word;
    resId: Word;
    wFormatTag: Word; // 1
    nChannels: Word; // 1 or 2
    nSamplesPerSec: LongWord;
    nAvgBytesPerSec: LongWord;
    nBlockAlign: Word;
    wBitsPerSample: Word;
  end;
  Header_Wave = record
    wFormatTag: Word;
    nChannels: Word;
    nSamplesPerSec: LongWord;
    nAvgBytesPerSec: LongWord;
    nBlockAlign: Word;
    wBitsPerSample: Word;
  end;
var
  fI, fO, I, O: TMemoryStream;
  S, p_S: Array[0..1] of SmallInt;
  B: Byte;
  nib: Array[0..1] of Byte;
  d: Array[0..1] of ShortInt;
  SampleRate: Cardinal = 22050;
  Chn: Word = 1;
  OutFile: String;

procedure ReadWav;
const
  Err = 'Error: Input file is not Wave audio file.';
var
  hd: Header_Wave;
  sig: Array[0..4] of AnsiChar;
  dw: LongWord;
  found: Boolean;
begin
  if fI.Size < SizeOf(hd) + 28 then begin
    Writeln(Err);
    Halt(1);
  end;
  sig[4]:=#0;
  fI.ReadBuffer(sig, 4);
  if StrPas(sig)<>sRIFF then begin
    Writeln('Error: RIFF chunk not found.');
    Halt(1);
  end;
  fI.ReadBuffer(dw, 4);
  if fI.Size < dw+8 then begin
    Writeln('Error: Wrong file size.');
    Halt(1);
  end;
  fI.ReadBuffer(sig, 4);
  if StrPas(sig)<>sWAVE then begin
    Writeln('Error: Not a Wave file.');
    Halt(1);
  end;
  found:=False;
  while fI.Position < fI.Size do begin
    fI.ReadBuffer(sig, 4);
    if StrPas(sig) = sfmt then begin
      found:=True;
      Break;
    end;
  end;
  if not found then begin
    Writeln('Error: Format chunk not found.');
    Halt(1);
  end;

  fI.ReadBuffer(dw, 4);
  if dw < SizeOf(hd) then begin
    Writeln('Error: Wrong format chunk size.');
    Halt(1);
  end;
  fI.ReadBuffer(hd, SizeOf(hd));

  if hd.wFormatTag<>1 then begin
    Writeln('Error: Wave file must be in uncompressed PCM format.');
    Halt(1);
  end;
  if hd.wBitsPerSample<>16 then begin
    Writeln('Error: Wave file must be in 16-bit format.');
    Halt(1);
  end;
  if hd.nBlockAlign <> (hd.nChannels * hd.wBitsPerSample) shr 3 then begin
    Writeln('Error: Wrong Wave header.');
    Halt(1);
  end;
  if hd.nAvgBytesPerSec <> hd.nSamplesPerSec * hd.nBlockAlign then begin
    Writeln('Error: Wrong Wave header.');
    Halt(1);
  end;

  found:=False;
  while fI.Position < fI.Size do begin
    fI.ReadBuffer(sig, 4);
    if StrPas(sig) = sdata then begin
      found:=True;
      Break;
    end;
  end;
  if not found then begin
    Writeln('Error: Data chunk not found.');
    Halt(1);
  end;

  fI.ReadBuffer(dw, 4);
  if dw > fI.Size - fI.Position then begin
    Writeln('Error: Wrong data chunk size.');
    Halt(1);
  end;

  Writeln('Microsoft RIFF Wave audio format detected.');

  SampleRate := hd.nSamplesPerSec;
  Chn := hd.nChannels;

  Writeln('Sample rate: '+IntToStr(SampleRate));
  Writeln('Channels: '+IntToStr(Chn));

  I:=TMemoryStream.Create;
  I.SetSize(dw);
  fI.ReadBuffer(I.Memory^, dw);
end;

procedure Read7la;
var
  hd: Header_7LA;
begin
  if fI.Size < SizeOf(hd) then begin
    Writeln('Error: Wrong file size.');
    Halt(1);
  end;

  fI.ReadBuffer(hd, sizeof(hd));

  if hd.Compressed<>1 then begin
    Writeln('Error: Audio file is not ADPCM compressed.');
    Halt(1);
  end;
  if hd.wFormatTag<>1 then begin
    Writeln('Error: Unsupported format.');
    Halt(1);
  end;
  if hd.wBitsPerSample<>16 then begin
    Writeln('Error: Wrong bits per sample.');
    Halt(1);
  end;
  if fI.Size < hd.Size + SizeOf(hd) then begin
    Writeln('Error: Wrong file size.');
    Halt(1);
  end;
  if hd.nBlockAlign <> (hd.nChannels * hd.wBitsPerSample) shr 3 then begin
    Writeln('Error: Wrong header data.');
    Halt(1);
  end;
  if hd.nAvgBytesPerSec <> hd.nSamplesPerSec * hd.nBlockAlign then begin
    Writeln('Error: Wrong header data.');
    Halt(1);
  end;

  Writeln('7th Level Audio format detected.');

  SampleRate := hd.nSamplesPerSec;
  Chn := hd.nChannels;

  Writeln('Sample rate: '+IntToStr(SampleRate));
  Writeln('Channels: '+IntToStr(Chn));

  I:=TMemoryStream.Create;
  I.SetSize(hd.Size);
  fI.ReadBuffer(I.Memory^, hd.Size);
end;

procedure WriteWav;
var
  dw: LongWord;
  hd: Header_Wave;
begin
  fO:=TMemoryStream.Create;
  fO.WriteBuffer(PAnsiChar(sRIFF)^, 4);
  dw:=28 + SizeOf(Header_Wave) + O.Size;
  fO.WriteBuffer(dw, 4);
  fO.WriteBuffer(PAnsiChar(sWAVE)^, 4);
  fO.WriteBuffer(PAnsiChar(sfmt)^, 4);
  dw:=SizeOf(Header_Wave);
  fO.WriteBuffer(dw, 4);
  hd.wFormatTag:=1;
  hd.nChannels:=Chn;
  hd.nSamplesPerSec:=SampleRate;
  hd.wBitsPerSample:=16;
  hd.nBlockAlign:=(hd.nChannels * hd.wBitsPerSample) shr 3;
  hd.nAvgBytesPerSec:=hd.nSamplesPerSec * hd.nBlockAlign;
  fO.WriteBuffer(hd, SizeOf(hd));
  fO.WriteBuffer(PAnsiChar(sdata)^, 4);
  dw:=O.Size;
  fO.WriteBuffer(dw, 4);
  O.Seek(0, soFromBeginning);
  fO.WriteBuffer(O.Memory^, O.Size);
end;

procedure Write7la;
var
  hd: Header_7LA;
begin
  fO:=TMemoryStream.Create;
  hd.Size := O.Size;
  hd.Dummy1:=0;
  hd.Compressed:=1;
  hd.Dummy2:=0;
  hd.resId:=0;
  hd.wFormatTag:=1;
  hd.nChannels:=Chn;
  hd.nSamplesPerSec:=SampleRate;
  hd.wBitsPerSample:=16;
  hd.nBlockAlign:=(hd.nChannels * hd.wBitsPerSample) shr 3;
  hd.nAvgBytesPerSec:=hd.nSamplesPerSec * hd.nBlockAlign;
  fO.WriteBuffer(hd, SizeOf(hd));
  O.Seek(0, soFromBeginning);
  fO.WriteBuffer(O.Memory^, O.Size);
end;

procedure Encode;
var
  IdxNib, MinNib: Integer;
  test: Word;
begin
  if not(Chn in [1..2]) then begin
    Writeln('Error: Supported only Mono and Stereo audio files.');
    Halt(1);
  end;

  case Chn of
    1: begin
      // init values
      nib[0] := 0;
      d[0] := 0;
      p_S[0] := 0;
      MinNib := 0;
      // check and fix file size (must be not odd)
      if Odd(I.Size) then begin
        I.Seek(I.Size-1, soFromBeginning);
        I.WriteBuffer(d[0], 1);
        I.Seek(0, soFromBeginning);
      end;
      Writeln('Converting '+IntToStr(I.Size shr 1)+' samples...');
      // conversion
      while I.Position<I.Size do begin
        if I.Position mod 4 = 0 then
          B:=0;

        I.ReadBuffer(S[0], 2);

        test:=65535;
        for IdxNib:=0 to 7 do
          if Abs(Table_7thADPCM[d[0], IdxNib] - Abs(S[0] - p_S[0]))<test then begin
            test:=Abs(Table_7thADPCM[d[0], IdxNib] - Abs(S[0] - p_S[0]));
            MinNib:=IdxNib;
          end else
            Break;

        if S[0] - p_S[0]<0 then begin
          nib[0]:=MinNib or 8;
          if p_S[0] - Table_7thADPCM[d[0], MinNib] >= -32768 then
            Dec(p_S[0], Table_7thADPCM[d[0], MinNib])
          else
            p_S[0]:=-32768;
        end else begin
          nib[0]:=MinNib;
          if p_S[0] + Table_7thADPCM[d[0], MinNib] <= 32767 then
            Inc(p_S[0], Table_7thADPCM[d[0], MinNib])
          else
            p_S[0]:=32767;
        end;

        d[0] := d[0] + Adjust[nib[0]];
        if d[0]<0 then
          d[0]:=0;
        if d[0]>88 then
          d[0]:=88;

        if I.Position mod 4 = 2 then
          B:=nib[0]
        else begin
          B:=B or (nib[0] shl 4);
          O.WriteBuffer(B, 1);
        end;
      end;
    end;
    2: begin
      // init values
      nib[0] := 0;
      nib[1] := 0;
      d[0] := 0;
      d[1] := 0;
      p_S[0] := 0;
      p_S[1] := 0;
      MinNib := 0;
      // check and fix file size
      if I.Size mod 4 > 0 then begin
        I.Seek(I.Size-1, soFromBeginning);
        case I.Size mod 4 of
          1:
            I.WriteBuffer(d[0], 1);
          2: begin
            I.WriteBuffer(d[0], 1);
            I.WriteBuffer(d[0], 1);
          end;
          3: begin
            I.WriteBuffer(d[0], 1);
            I.WriteBuffer(d[0], 1);
            I.WriteBuffer(d[0], 1);
          end;
        end;
        I.Seek(0, soFromBeginning);
      end;
      Writeln('Converting '+IntToStr(I.Size shr 2)+' samples...');
      // conversion
      while I.Position<I.Size do begin
        B:=0;
        // sample L
        I.ReadBuffer(S[0], 2);
        // sample R
        I.ReadBuffer(S[1], 2);

        test:=65535;
        for IdxNib:=0 to 7 do
          if Abs(Table_7thADPCM[d[0], IdxNib] - Abs(S[0] - p_S[0]))<test then begin
            test:=Abs(Table_7thADPCM[d[0], IdxNib] - Abs(S[0] - p_S[0]));
            MinNib:=IdxNib;
          end else
            Break;

        if S[0] - p_S[0]<0 then begin
          nib[0]:=MinNib or 8;
          if p_S[0] - Table_7thADPCM[d[0], MinNib] >= -32768 then
            Dec(p_S[0], Table_7thADPCM[d[0], MinNib])
          else
            p_S[0]:=-32768;
        end else begin
          nib[0]:=MinNib;
          if p_S[0] + Table_7thADPCM[d[0], MinNib] <= 32767 then
            Inc(p_S[0], Table_7thADPCM[d[0], MinNib])
          else
            p_S[0]:=32767;
        end;

        d[0] := d[0] + Adjust[nib[0]];
        if d[0]<0 then
          d[0]:=0;
        if d[0]>88 then
          d[0]:=88;

        test:=65535;
        for IdxNib:=0 to 7 do
          if Abs(Table_7thADPCM[d[1], IdxNib] - Abs(S[1] - p_S[1]))<test then begin
            test:=Abs(Table_7thADPCM[d[1], IdxNib] - Abs(S[1] - p_S[1]));
            MinNib:=IdxNib;
          end else
            Break;

        if S[1] - p_S[1]<0 then begin
          nib[1]:=MinNib or 8;
          if p_S[1] - Table_7thADPCM[d[1], MinNib] >= -32768 then
            Dec(p_S[1], Table_7thADPCM[d[1], MinNib])
          else
            p_S[1]:=-32768;
        end else begin
          nib[1]:=MinNib;
          if p_S[1] + Table_7thADPCM[d[1], MinNib] <= 32767 then
            Inc(p_S[1], Table_7thADPCM[d[1], MinNib])
          else
            p_S[1]:=32767;
        end;

        d[1] := d[1] + Adjust[nib[1]];
        if d[1]<0 then
          d[1]:=0;
        if d[1]>88 then
          d[1]:=88;

        B:=nib[0] or (nib[1] shl 4);
        O.WriteBuffer(B, 1);
      end;
    end;
  end;
end;

procedure Decode;
var
  NextNib: Boolean;
begin
  if not(Chn in [1..2]) then begin
    Writeln('Error: Supported only Mono and Stereo audio files.');
    Halt(1);
  end;

  case Chn of
    1: begin
      // init values
      S[0]:=0;
      d[0]:=0;
      Writeln('Converting '+IntToStr(I.Size shl 1)+' samples...');
      NextNib:=False;
      while (I.Position<I.Size) or NextNib do begin
        if not NextNib then begin
          // read byte
          I.ReadBuffer(B, 1);
          nib[0]:=B and 15; // nibble #1
        end else
          nib[0]:=B shr 4;  // nibble #2
        NextNib:=not NextNib;

        if nib[0] shr 3 = 0 then begin
          if S[0] + Table_7thADPCM[d[0], nib[0] mod 8] <= 32767 then
            Inc(S[0], Table_7thADPCM[d[0], nib[0] mod 8])
          else
            S[0]:=32767;
        end else begin
          if S[0] - Table_7thADPCM[d[0], nib[0] mod 8] >= -32768 then
            Dec(S[0], Table_7thADPCM[d[0], nib[0] mod 8])
          else
            S[0]:=-32768;
        end;

        d[0] := d[0] + Adjust[nib[0]];
        if d[0]<0 then
          d[0]:=0;
        if d[0]>88 then
          d[0]:=88;

        O.WriteBuffer(S, 2);
      end;
    end;
    2: begin
      // init values
      S[0]:=0;
      S[1]:=0;
      d[0]:=0;
      d[1]:=0;
      Writeln('Converting '+IntToStr(I.Size)+' samples...');
      while I.Position<I.Size do begin
        // read byte
        I.ReadBuffer(B, 1);
        nib[0]:=B and 15; // nibble L
        nib[1]:=B shr 4;  // nibble R

        if nib[0] shr 3 = 0 then begin
          if S[0] + Table_7thADPCM[d[0], nib[0] mod 8] <= 32767 then
            Inc(S[0], Table_7thADPCM[d[0], nib[0] mod 8])
          else
            S[0]:=32767;
        end else begin
          if S[0] - Table_7thADPCM[d[0], nib[0] mod 8] >= -32768 then
            Dec(S[0], Table_7thADPCM[d[0], nib[0] mod 8])
          else
            S[0]:=-32768;
        end;

        d[0] := d[0] + Adjust[nib[0]];
        if d[0]<0 then
          d[0]:=0;
        if d[0]>88 then
          d[0]:=88;

        O.WriteBuffer(S[0], 2);

        if nib[1] shr 3 = 0 then begin
          if S[1] + Table_7thADPCM[d[1], nib[1] mod 8] <= 32767 then
            Inc(S[1], Table_7thADPCM[d[1], nib[1] mod 8])
          else
            S[1]:=32767;
        end else begin
          if S[1] - Table_7thADPCM[d[1], nib[1] mod 8] >= -32768 then
            Dec(S[1], Table_7thADPCM[d[1], nib[1] mod 8])
          else
            S[1]:=-32768;
        end;

        d[1] := d[1] + Adjust[nib[1]];
        if d[1]<0 then
          d[1]:=0;
        if d[1]>88 then
          d[1]:=88;

        O.WriteBuffer(S[1], 2);
      end;
    end;
  end;
end;

begin
  Writeln('7th Level ADPCM converter v0.1');
  Writeln('Copyright (C) Stas''M Corp. 2012');
  Writeln('');
  Writeln('7th Level ADPCM format specification is reversed by Stas''M from');
  Writeln('Audio Library 2.2 (C) 1995 7th Level, Inc.');
  Writeln('');
  if ParamCount = 0 then begin
    Writeln('USAGE:');
    Writeln('adpcm7th.exe <-l> <-e|-d> <input file> [output file]');
    Writeln('');
    Writeln('-l           show license agreement');
    Writeln('-e           encode uncompressed PCM file');
    Writeln('  input file   [*.wav] Microsoft Wave file');
    Writeln('               [*.raw] PCM 16-bit LE raw file');
    Writeln('  output file  [*.7la] 7th Level Audio file     (default)');
    Writeln('               [*.raw] 7th Level ADPCM raw file');
    Writeln('-d           decode compressed ADPCM file');
    Writeln('  input file   [*.7la] 7th Level Audio file');
    Writeln('               [*.raw] 7th Level ADPCM raw file');
    Writeln('  output file  [*.wav] Microsoft Wave file      (default)');
    Writeln('               [*.raw] PCM 16-bit LE raw file');
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
    (ExtractFileExt(ParamStr(2)) <> '.wav') and
    (ExtractFileExt(ParamStr(2)) <> '.raw')
    then begin
      Writeln('Error: File extension not supported in encoding mode.');
      Halt(1);
    end;
  if ParamStr(1) = '-d' then
    if
    (ExtractFileExt(ParamStr(2)) <> '.7la') and
    (ExtractFileExt(ParamStr(2)) <> '.raw')
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
    if ExtractFileExt(ParamStr(2)) = '.wav' then
      ReadWav;
    if ExtractFileExt(ParamStr(2)) = '.raw' then
      Pointer(I) := Pointer(fI);
    Encode;
  end;
  if ParamStr(1) = '-d' then begin
    if ExtractFileExt(ParamStr(2)) = '.7la' then
      Read7la;
    if ExtractFileExt(ParamStr(2)) = '.raw' then
      Pointer(I) := Pointer(fI);
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
    if ParamStr(1) = '-e' then begin
      if ExtractFileExt(ParamStr(3)) = '.raw' then
        Pointer(fO) := Pointer(O)
      else
        Write7la;
    end;
    if ParamStr(1) = '-d' then begin
      if ExtractFileExt(ParamStr(3)) = '.raw' then
        Pointer(fO) := Pointer(O)
      else
        WriteWav;
    end;
  end else begin
    if ParamStr(1) = '-e' then begin
      Write7la;
      OutFile := ExtractFilePath(ParamStr(2))+ExtractFileName(ParamStr(2))+'.7la';
    end;
    if ParamStr(1) = '-d' then begin
      WriteWav;
      OutFile := ExtractFilePath(ParamStr(2))+ExtractFileName(ParamStr(2))+'.wav';
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
