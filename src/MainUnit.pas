{
	7th Level File Manager v1.0 by Stas'M

	This tool was made for extracting some resources from 7th Level Inc games and for game modding. Tested on "Disney's Timon & Pumbaa's Jungle Games".

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
unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, Grids, FileCtrl, StdCtrls, ExtCtrls, IniFiles;

type
  TMainForm = class(TForm)
    SG: TStringGrid;
    Menu: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Extract1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    Fileinformation1: TMenuItem;
    Open: TOpenDialog;
    Extractselectedresource1: TMenuItem;
    Extractallresources1: TMenuItem;
    Convert1: TMenuItem;
    Sounds1: TMenuItem;
    Music1: TMenuItem;
    Extractallresourcesbytype1: TMenuItem;
    Save: TSaveDialog;
    N2: TMenuItem;
    N3: TMenuItem;
    Importasproject1: TMenuItem;
    Exportasproject1: TMenuItem;
    Close1: TMenuItem;
    Save1: TMenuItem;
    Previewplayselectedresource1: TMenuItem;
    N4: TMenuItem;
    PlayerChk: TTimer;
    License1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Fileinformation1Click(Sender: TObject);
    procedure Extractselectedresource1Click(Sender: TObject);
    procedure Extractallresources1Click(Sender: TObject);
    procedure Extractallresourcesbytype1Click(Sender: TObject);
    procedure Sounds1Click(Sender: TObject);
    procedure Music1Click(Sender: TObject);
    procedure License1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Exportasproject1Click(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Previewplayselectedresource1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure PlayerChkTimer(Sender: TObject);
    procedure Importasproject1Click(Sender: TObject);
  private
    { Private declarations }
    procedure CloseFile;
    procedure LoadFile;
  public
    { Public declarations }
  end;

procedure PlayMovie(Handle: HWND; hInst: THandle; lpszCmdLine: PWideChar;
  nCmdShow: Integer); stdcall; external 'amovie.ocx' name 'RunDllW';

type
  ftEntry = packed record
    Flags: Word;
    Offset: LongWord;
    Size: LongWord;
  end;
const
  sign7L: AnsiString = '7L';
var
  MainForm: TMainForm;
  Opened: Boolean = False;
  M: TMemoryStream;
  vMajor: Byte;
  vMinor1: Byte;
  vMinor2: Byte;
  FileTable: Array of ftEntry;
  TempFiles: TStringList;
  AMovie: TForm;

implementation

{$R *.dfm}

uses
  Res, LicenseUnit;

function ExecAppAndWait(ACommandLine,  AWorkDir: String): DWORD;
var
  R: Boolean;
  ProcessInformation: TProcessInformation;
  StartupInfo: TStartupInfo;
  ExCode: DWORD;
begin
  UniqueString(ACommandLine);
  UniqueString(AWorkDir);
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_HIDE;
  end;
  R := CreateProcess(
    nil, // Pointer to name of executable module
    PChar(ACommandLine), // Pointer to command line string
    nil, // Pointer to process security attributes
    nil, // Pointer to thread security attributes
    False, // handle inheritance flag
    0, // creation flags
    nil, // Pointer to new environment block
    PChar(AWorkDir), // Pointer to current directory name
    StartupInfo, // Pointer to STARTUPINFO
    ProcessInformation); // Pointer to PROCESS_INFORMATION
  if R then begin
    WaitForSingleObject(ProcessInformation.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInformation.hProcess, ExCode);
    Result:=ExCode;
    CloseHandle(ProcessInformation.hThread);
    CloseHandle(ProcessInformation.hProcess);
  end else
    Result := GetLastError;
end;

procedure TMainForm.License1Click(Sender: TObject);
begin
  LicenseForm.mText.Text := ExtractResText('LICENSE');
  if LicenseForm.ShowModal <> mrOk then
    Halt(0);
end;

procedure TMainForm.About1Click(Sender: TObject);
begin
  MessageBox(Handle,
  '7th Level File Manager v1.0 by Stas''M'+#13#10+
  'Copyright © Stas''M Corp. 2012'+#13#10#13#10+
  'This tool was made for extracting some resources '+
  'from 7th Level Inc games and possibly for game modding. Tested on '+
  '"Disney''s Timon & Pumbaa''s Jungle Games".'+#13#10#13#10+
  'Internal formats supported:'+#13#10+
  '- 7th Level Audio files (ADPCM compressed)'+#13#10+
  '- 7th Level MIDI files'+#13#10#13#10+
  'For latest version visit http://stascorp.com',
  'About',
  mb_Ok or mb_IconAsterisk);
end;

procedure TMainForm.Close1Click(Sender: TObject);
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  CloseFile;
end;

procedure TMainForm.CloseFile;
begin
  M.Free;
  Opened:=False;
  SetLength(FileTable, 0);
  SG.RowCount:=2;
  SG.Cells[0,1]:='';
  SG.Cells[1,1]:='';
  SG.Cells[2,1]:='';
  SG.Cells[3,1]:='';
end;

procedure ExtractResource(Idx: Integer; FileName: String);
var
  Mem: TMemoryStream;
  dw: LongWord;
begin
  if (Idx < -1) or (Idx > Length(FileTable) + 5 - 1) then
    Exit;
  if (Idx >= 0) and (Idx <= Length(FileTable)-1) then begin
    Mem:=TMemoryStream.Create;
    Mem.SetSize(FileTable[Idx].Size);
    M.Seek(FileTable[Idx].Offset, soFromBeginning);
    M.ReadBuffer(Mem.Memory^, Mem.Size);
    Mem.SaveToFile(FileName);
    Mem.Free;
  end else begin
    Mem:=TMemoryStream.Create;
    if Idx = -1 then begin
      M.Seek(0, soFromBeginning);
      Mem.SetSize(286);
      M.ReadBuffer(Mem.Memory^, Mem.Size);
      Mem.SaveToFile(FileName);
      Mem.Free;
      Exit;
    end;
    if Idx = Length(FileTable) then begin
      M.Seek($C2, soFromBeginning);
      M.ReadBuffer(dw, 4);
      Mem.SetSize(dw);
      M.Seek($BE, soFromBeginning);
    end;
    if Idx = Length(FileTable)+1 then begin
      M.Seek($DA, soFromBeginning);
      M.ReadBuffer(dw, 4);
      Mem.SetSize(dw);
      M.Seek($D6, soFromBeginning);
    end;
    if Idx = Length(FileTable)+2 then begin
      M.Seek($E2, soFromBeginning);
      M.ReadBuffer(dw, 4);
      Mem.SetSize(dw);
      M.Seek($DE, soFromBeginning);
    end;
    if Idx = Length(FileTable)+3 then begin
      M.Seek($EA, soFromBeginning);
      M.ReadBuffer(dw, 4);
      Mem.SetSize(dw);
      M.Seek($E6, soFromBeginning);
    end;
    if Idx = Length(FileTable)+4 then begin
      M.Seek($F2, soFromBeginning);
      M.ReadBuffer(dw, 4);
      Mem.SetSize(dw);
      M.Seek($EE, soFromBeginning);
    end;
    M.ReadBuffer(dw, 4);
    M.Seek(dw, soFromBeginning);
    M.ReadBuffer(Mem.Memory^, Mem.Size);
    Mem.SaveToFile(FileName);
    Mem.Free;
  end;
end;

procedure ExtractAllRes(Dir: String; ExtractAliases: Boolean);
var
  I: Integer;
  FileName: String;
  Fr: TForm;
  L: TLabel;
begin
  if not Opened then
    Exit;

  Fr:=TForm.Create(Application);
  with Fr do begin
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Extracting, please wait...';
    ClientWidth := 200;
    ClientHeight := 26;
    L:=TLabel.Create(Fr);
    with L do begin
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='';
    end;
    Show;
  end;

  for I:=0 to Length(FileTable)-1 do begin
    L.Caption := 'Saving resource '+IntToStr(I+1)+' of '+IntToStr(Length(FileTable))+'...';
    FileName:='res'+IntToStr(I);
    case FileTable[I].Flags of
      1: FileName:=FileName+'.7lg';
      4: FileName:=FileName+'.7lm';
      7: FileName:=FileName+'.7la';
      8..16:
        FileName:='alias'+IntToStr(I)+'.'+IntToStr(FileTable[I].Flags);
      else
        FileName:=FileName+'.'+IntToStr(FileTable[I].Flags);
    end;
    if not(FileTable[I].Flags in [8..16]) or ExtractAliases then
      ExtractResource(I, Dir + '\' + FileName);
    Application.ProcessMessages;
  end;
  Fr.Free;
end;

function SizeFile(FileName: String): Int64;
var
  F: TFileStream;
  Err: Boolean;
begin
  Err:=False;
  Result:=0;
  try
    F:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  except
    Err:=True;
  end;
  if Err then
    Exit
  else begin
    Result := F.Size;
    F.Free;
  end;
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.Exportasproject1Click(Sender: TObject);
type
  Color = packed record
    R,G,B,A: Byte;
  end;
const
  crlf: Word = $A0D;
var
  Dir: String;
  I: Integer;
  FileName: String;
  ResIdx: Array of LongWord;
  S1,S2: TMemoryStream;
  Str: TStringList;
  Prj: TIniFile;
  C: Color;
  B: Byte;
  Fr: TForm;
  L: TLabel;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  if not SelectDirectory('Choose directory for project', '', Dir) then
    Exit;

  Fr:=TForm.Create(Application);
  with Fr do begin
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Exporting, please wait...';
    ClientWidth := 200;
    ClientHeight := 26;
    L:=TLabel.Create(Fr);
    with L do begin
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='';
    end;
    Show;
  end;

  L.Caption := 'Saving header...';
  Application.ProcessMessages;
  ExtractResource(-1, Dir + '\head.bin');
  L.Caption := 'Saving constants...';
  Application.ProcessMessages;
  ExtractResource(Length(FileTable)+1, Dir + '\const.bin');
  L.Caption := 'Saving string table...';
  Application.ProcessMessages;
  ExtractResource(Length(FileTable)+2, Dir + '\strings.bin');
  L.Caption := 'Saving code section...';
  Application.ProcessMessages;
  ExtractResource(Length(FileTable)+3, Dir + '\code.bin');
  L.Caption := 'Saving palette...';
  Application.ProcessMessages;
  ExtractResource(Length(FileTable)+4, Dir + '\palette.bin');
  L.Caption := 'Saving project settings...';
  Application.ProcessMessages;

  Prj:=TIniFile.Create(Dir + '\7th_proj.txt');
  Prj.WriteString('Main', 'Header', 'head.bin');

  Prj.WriteInteger('Main', 'Entry', Length(FileTable));

  if SizeFile(Dir + '\const.bin') > 0 then
    Prj.WriteString('Main', 'Constants', 'const.bin')
  else
    DeleteFile(Dir + '\const.bin');

  if SizeFile(Dir + '\strings.bin') > 0 then begin
    S1:=TMemoryStream.Create;
    S2:=TMemoryStream.Create;
    S1.LoadFromFile(Dir + '\strings.bin');
    DeleteFile(Dir + '\strings.bin');
    while S1.Position < S1.Size do begin
      S1.ReadBuffer(B, 1);
      if B=0 then
        S2.WriteBuffer(crlf, 2)
      else
        S2.WriteBuffer(B, 1);
    end;
    S1.Free;
    S2.SaveToFile(Dir + '\strings.txt');
    S2.Free;
    Prj.WriteString('Main', 'Strings', 'strings.txt');
  end else
    DeleteFile(Dir + '\strings.bin');

  Application.ProcessMessages;

  if SizeFile(Dir + '\code.bin') > 0 then
    Prj.WriteString('Main', 'Code', 'code.bin')
  else
    DeleteFile(Dir + '\code.bin');

  if SizeFile(Dir + '\palette.bin') > 0 then begin
    S1:=TMemoryStream.Create;
    S1.LoadFromFile(Dir + '\palette.bin');
    DeleteFile(Dir + '\palette.bin');
    Str:=TStringList.Create;
    Str.Add('JASC-PAL');
    Str.Add('0100');
    Str.Add(IntToStr(S1.Size shr 2));
    while S1.Position < S1.Size do begin
      S1.ReadBuffer(C, SizeOf(C));
      Str.Add(IntToStr(C.R)+' '+IntToStr(C.G)+' '+IntToStr(C.B));
    end;
    S1.Free;
    Str.SaveToFile(Dir + '\palette.pal');
    Str.Free;
    Prj.WriteString('Main', 'Palette', 'palette.pal');
  end else
    DeleteFile(Dir + '\palette.bin');

  Application.ProcessMessages;

  for I:=0 to Length(FileTable)-1 do begin
    FileName:='res'+IntToStr(I);
    case FileTable[I].Flags of
      1: FileName:=FileName+'.7lg';
      4: FileName:=FileName+'.7lm';
      7: FileName:=FileName+'.7la';
      else
        FileName:=FileName+'.'+IntToStr(FileTable[I].Flags);
    end;
    Prj.WriteInteger('Table', 'Type'+IntToStr(I), FileTable[I].Flags);
    if not(FileTable[I].Flags in [8..16]) then begin
      Prj.WriteString('Table', 'File'+IntToStr(I), FileName);
      SetLength(ResIdx, Length(ResIdx)+1);
      ResIdx[Length(ResIdx)-1]:=I;
    end else
      Prj.WriteInteger('Table', 'Size'+IntToStr(I), FileTable[I].Size);
    if I mod 128 = 0 then
      Application.ProcessMessages;
  end;
  Prj.Free;

  L.Caption := 'Saving resources...';
  Application.ProcessMessages;
  for I:=0 to Length(ResIdx)-1 do begin
    FileName:='res'+IntToStr(ResIdx[I]);
    case FileTable[ResIdx[I]].Flags of
      1: FileName:=FileName+'.7lg';
      4: FileName:=FileName+'.7lm';
      7: FileName:=FileName+'.7la';
      else
        FileName:=FileName+'.'+IntToStr(FileTable[ResIdx[I]].Flags);
    end;
    ExtractResource(ResIdx[I], Dir + '\' + FileName);
    if I mod 128 = 0 then
      Application.ProcessMessages;
  end;

  Fr.Free;

  MessageBox(Handle,
  'Project export finished.',
  'Information',
  mb_Ok or mb_IconAsterisk);
end;

procedure TMainForm.Extractallresources1Click(Sender: TObject);
var
  Dir: String;
  Alias: Boolean;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  if not SelectDirectory('Choose directory', '', Dir) then
    Exit;
  Alias:=MessageBox(Handle,
  'Do you wish to extract aliases? (it''s not an actual resources)',
  'Information',
  mb_YesNo or mb_IconQuestion) = mrYes;
  ExtractAllRes(Dir, Alias);
end;

procedure TMainForm.Extractallresourcesbytype1Click(Sender: TObject);
var
  Dir: String;
  A: Array of Word;
  Swp: Word;
  Fnd: Boolean;
  I,J: Integer;
  FileName: String;
  Fr: TForm;
  Cmb: TComboBox;
  L: TLabel;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  for I:=0 to Length(FileTable)-1 do begin
    Fnd:=False;
    for J:=0 to Length(A)-1 do
      if A[J] = FileTable[I].Flags then begin
        Fnd:=True;
        Break;
      end;
    if not Fnd then begin
      SetLength(A, Length(A)+1);
      A[Length(A)-1] := FileTable[I].Flags;
    end;
  end;

  repeat
    Fnd:=False;
    for I:=0 to Length(A)-2 do
      if A[I] > A[I+1] then begin
        Swp:=A[I];
        A[I]:=A[I+1];
        A[I+1]:=Swp;
        Fnd:=True;
      end;
  until not Fnd;

  Fr := TForm.Create(Application);
  with Fr do begin
    BorderStyle := bsDialog;
    PopupMode := pmAuto;
    Position := poOwnerFormCenter;
    Caption := 'Select resource type';
    ClientWidth := 160;
    ClientHeight := 53;
    TabStop := False;
  end;
  Cmb:=TComboBox.Create(Fr);
  with Cmb do begin
    Parent := Fr;
    SetBounds(7, 6, 145, 21);
    Style := csDropDownList;
    for I:=0 to Length(A)-1 do
      case A[I] of
        1: Items.Add('Graphics');
        4: Items.Add('Musics');
        7: Items.Add('Sounds');
        8..16:
          Items.Add('Aliases #'+IntToStr(A[I]));
        else
          Items.Add(IntToStr(A[I])+' (unknown)');
      end;
    ItemIndex := 0;
  end;
  with TButton.Create(Fr) do begin
    Parent := Fr;
    Caption := '&OK';
    ModalResult := mrOk;
    Default := True;
    SetBounds(7, 32, 72, 17);
  end;
  with TButton.Create(Fr) do begin
    Parent := Fr;
    Caption := '&Cancel';
    ModalResult := mrCancel;
    SetBounds(80, 32, 72, 17);
  end;
  if Fr.ShowModal = mrOk then
    Swp := A[Cmb.ItemIndex]
  else begin
    Fr.Free;
    Exit;
  end;
  Fr.Free;

  if not SelectDirectory('Choose directory', '', Dir) then
    Exit;

  with Fr do begin
    Fr:=TForm.Create(MainForm);
    Parent := MainForm;
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Extracting, please wait...';
    ClientWidth := 200;
    ClientHeight := 26;
    with L do begin
      L:=TLabel.Create(Fr);
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='Saving type '+IntToStr(Swp)+' resources...';
    end;
    Show;
  end;

  for I:=0 to Length(FileTable)-1 do
    if FileTable[I].Flags = Swp then begin
      FileName:='res'+IntToStr(I);
      case FileTable[I].Flags of
        1: FileName:=FileName+'.7lg';
        4: FileName:=FileName+'.7lm';
        7: FileName:=FileName+'.7la';
        else
          FileName:=FileName+'.'+IntToStr(FileTable[I].Flags);
      end;
      ExtractResource(I, Dir + '\' + FileName);
      Application.ProcessMessages;
    end;
  Fr.Free;
end;

procedure TMainForm.Extractselectedresource1Click(Sender: TObject);
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  if FileTable[SG.Row-1].Flags in [8..16] then
    if MessageBox(Handle,
    'Selected resource is an alias (not an actual resource). '+
    'Do you wish to extract it?',
    'Information',
    mb_YesNo or mb_IconQuestion) <> mrYes then
      Exit;
  if SG.Row <= Length(FileTable) then begin
    Save.FileName:='res'+IntToStr(SG.Row-1);
    case FileTable[SG.Row-1].Flags of
      1: begin
        Save.Filter:='7th Level Graphic File|*.7lg';
        Save.FileName:=Save.FileName+'.7lg';
      end;
      4: begin
        Save.Filter:='7th Level MIDI File|*.7lm';
        Save.FileName:=Save.FileName+'.7lm';
      end;
      7: begin
        Save.Filter:='7th Level Audio File|*.7la';
        Save.FileName:=Save.FileName+'.7la';
      end;
      8..16: begin
        Save.FileName:='alias'+IntToStr(SG.Row-1);
        Save.Filter:='All files|*.*';
        Save.FileName:=Save.FileName+'.'+IntToStr(FileTable[SG.Row-1].Flags);
      end
      else begin
        Save.Filter:='All files|*.*';
        Save.FileName:=Save.FileName+'.'+IntToStr(FileTable[SG.Row-1].Flags);
      end;
    end;
  end else begin
    if SG.Row = Length(FileTable)+1 then begin
      Save.Filter:='All files|*.*';
      Save.FileName:='table.bin';
    end;
    if SG.Row = Length(FileTable)+2 then begin
      Save.Filter:='All files|*.*';
      Save.FileName:='const.bin';
    end;
    if SG.Row = Length(FileTable)+3 then begin
      Save.Filter:='All files|*.*';
      Save.FileName:='strings.bin';
    end;
    if SG.Row = Length(FileTable)+4 then begin
      Save.Filter:='All files|*.*';
      Save.FileName:='code.bin';
    end;
    if SG.Row = Length(FileTable)+5 then begin
      Save.Filter:='All files|*.*';
      Save.FileName:='palette.bin';
    end;
  end;
  Save.Title:='Extract resource as';
  if not Save.Execute then
    Exit;
  ExtractResource(SG.Row-1, Save.FileName);
end;

procedure TMainForm.Fileinformation1Click(Sender: TObject);
type
  Knd = record
    Typ: Word;
    Cnt: Cardinal;
  end;
var
  S: String;
  I,J: Integer;
  A: Array of Knd;
  Swp: Knd;
  ResCnt, AliasCnt: LongWord;
  Fnd: Boolean;
begin
  if not Opened then
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk)
  else begin
    S:='File: '+Open.FileName+#13#10#13#10;
    S:=S+'7th Level File v'+IntToStr(vMajor)+'.'+IntToStr(vMinor1)+'.'+IntToStr(vMinor2);
    S:=S+#13#10#13#10;
    S:=S+'Total entries: '+IntToStr(Length(FileTable))+#13#10;
    for I:=0 to Length(FileTable)-1 do begin
      Fnd:=False;
      for J:=0 to Length(A)-1 do
        if A[J].Typ = FileTable[I].Flags then begin
          Fnd:=True;
          Inc(A[J].Cnt);
          Break;
        end;
      if not Fnd then begin
        SetLength(A, Length(A)+1);
        A[Length(A)-1].Typ := FileTable[I].Flags;
        A[Length(A)-1].Cnt := 1;
      end;
    end;

    repeat
      Fnd:=False;
      for I:=0 to Length(A)-2 do
        if A[I].Typ > A[I+1].Typ then begin
          Swp:=A[I];
          A[I]:=A[I+1];
          A[I+1]:=Swp;
          Fnd:=True;
        end;
    until not Fnd;

    ResCnt:=0;
    AliasCnt:=0;
    for I:=0 to Length(A)-1 do
      if A[I].Typ in [8..16] then
        Inc(AliasCnt, A[I].Cnt)
      else
        Inc(ResCnt, A[I].Cnt);
    S:=S+'Total resources: '+IntToStr(ResCnt)+#13#10;
    S:=S+'Total aliases: '+IntToStr(AliasCnt)+#13#10#13#10;

    for I:=0 to Length(A)-1 do
      case A[I].Typ of
        1: S:=S+'Graphic resources: '+IntToStr(A[I].Cnt)+#13#10;
        4: S:=S+'Music resources: '+IntToStr(A[I].Cnt)+#13#10;
        7: S:=S+'Sound resources: '+IntToStr(A[I].Cnt)+#13#10;
        8..16:
           S:=S+'Aliases #'+IntToStr(A[I].Typ)+': '+IntToStr(A[I].Cnt)+#13#10;
        else
          S:=S+'Type '+IntToStr(A[I].Typ)+' resources: '+IntToStr(A[I].Cnt)+#13#10;
      end;
    MessageBox(Handle,
    PWideChar(S),
    'Information',
    mb_Ok or mb_IconAsterisk);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TempFiles:=TStringList.Create;
  SG.Cells[0,0]:='Offset (hex)';
  SG.Cells[1,0]:='Size (hex)';
  SG.Cells[2,0]:='Type';
  SG.Cells[3,0]:='Description';
  SG.ColWidths[0]:=64;
  SG.ColWidths[1]:=64;
  SG.ColWidths[2]:=64;
  SG.ColWidths[3]:=192;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  for I:=0 to TempFiles.Count-1 do
    DeleteFile(TempFiles.Strings[I]);
  TempFiles.Free;
end;

procedure TMainForm.Importasproject1Click(Sender: TObject);
var
  Prj: TIniFile;
  ResCnt: LongWord;
  ResIdx: Array of LongWord;
  fI, fO: TMemoryStream;
  sig: Array[0..2] of AnsiChar;
  B,Chk: Byte;
  clr: Array of Byte;
  ColorStr: String;
  ColorCnt: Word;
  FileName, Dir: String;
  rtOffset, rtSize: LongWord;
  ctOffset, ctSize: LongWord;
  stOffset, stSize: LongWord;
  csOffset, csSize: LongWord;
  plOffset, plSize: LongWord;
  Err: Boolean;
  AliasOffset: LongWord;
  S: TStringList;
  I: Integer;
  Fr: TForm;
  L: TLabel;
begin
  Open.Filter:='7th Level project settings|7th_proj.txt';
  Open.FileName:='7th_proj.txt';
  Open.Title:='Import project';
  if not Open.Execute then
    Exit;
  Dir := ExtractFilePath(Open.FileName);
  Prj:=TIniFile.Create(Open.FileName);
  if not Prj.SectionExists('Main') then begin
    Prj.Free;
    MessageBox(Handle,
    'Main section not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  FileName:=Prj.ReadString('Main', 'Header', '');
  if not Prj.ValueExists('Main', 'Header') then begin
    Prj.Free;
    MessageBox(Handle,
    'Header value not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  if not FileExists(Dir + FileName) then begin
    Prj.Free;
    MessageBox(Handle,
    'Header file not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  fI:=TMemoryStream.Create;
  fI.LoadFromFile(Dir + FileName);
  if fI.Size <> 286 then begin
    CloseFile;
    Prj.Free;
    fI.Free;
    MessageBox(Handle,
    'Header file has wrong size.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  FillChar(sig, 3, 0);
  fI.ReadBuffer(sig, 2);
  if StrPas(sig) <> sign7L then begin
    CloseFile;
    Prj.Free;
    fI.Free;
    MessageBox(Handle,
    '7th Level signature in header file not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  fI.Seek(0, soFromBeginning);
  M:=TMemoryStream.Create;
  M.WriteBuffer(fI.Memory^, fI.Size);
  fI.Free;
  ResCnt:=Prj.ReadInteger('Main', 'Entry', 0);
  if not Prj.ValueExists('Main', 'Entry') then begin
    Prj.Free;
    MessageBox(Handle,
    'Entry count value not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;

  Fr:=TForm.Create(Application);
  with Fr do begin
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Importing project...';
    ClientWidth := 200;
    ClientHeight := 26;
    L:=TLabel.Create(Fr);
    with L do begin
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='';
    end;
    Show;
  end;

  SetLength(FileTable, ResCnt);
  AliasOffset:=0;
  L.Caption:='Reading entry table...';
  Application.ProcessMessages;
  for I:=0 to ResCnt-1 do begin
    FileTable[I].Flags := Prj.ReadInteger('Table', 'Type'+IntToStr(I), 0);
    if not Prj.ValueExists('Table', 'Type'+IntToStr(I)) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Type value #'+IntToStr(I)+' not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    if not(FileTable[I].Flags in [8..16]) then begin
      SetLength(ResIdx, Length(ResIdx)+1);
      ResIdx[Length(ResIdx)-1]:=I;
    end else begin
      FileTable[I].Size := Prj.ReadInteger('Table', 'Size'+IntToStr(I), 0);
      if not Prj.ValueExists('Table', 'Size'+IntToStr(I)) then begin
        CloseFile;
        Prj.Free;
        Fr.Free;
        MessageBox(Handle,
        PWideChar('Size value #'+IntToStr(I)+' not found.'),
        'Error',
        mb_Ok or mb_IconError);
        Exit;
      end;
      FileTable[I].Offset := AliasOffset;
      Inc(AliasOffset, FileTable[I].Size);
    end;
    if I mod 128 = 0 then
      Application.ProcessMessages;
  end;
  L.Caption:='Reading resources...';
  Application.ProcessMessages;
  for I:=0 to Length(ResIdx)-1 do begin
    FileName:=Prj.ReadString('Table', 'File'+IntToStr(ResIdx[I]), '');
    if not Prj.ValueExists('Table', 'File'+IntToStr(ResIdx[I])) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('File value #'+IntToStr(ResIdx[I])+' not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    if not FileExists(Dir + FileName) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Resource file #'+IntToStr(ResIdx[I])+' "'+FileName+'" not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    fI:=TMemoryStream.Create;
    fI.LoadFromFile(Dir + FileName);
    FileTable[ResIdx[I]].Offset := M.Position;
    FileTable[ResIdx[I]].Size := fI.Size;
    M.WriteBuffer(fI.Memory^, fI.Size);
    fI.Free;
    if I mod 128 = 0 then
      Application.ProcessMessages;
  end;
  SetLength(ResIdx, 0);
  L.Caption:='Building resource table...';
  Application.ProcessMessages;
  rtOffset := M.Size;
  rtSize := Length(FileTable) * SizeOf(ftEntry);
  M.Seek($BE, soFromBeginning);
  M.WriteBuffer(rtOffset, 4);
  M.WriteBuffer(rtSize, 4);
  M.Seek(rtOffset, soFromBeginning);
  for I:=0 to Length(FileTable)-1 do begin
    M.WriteBuffer(FileTable[I], SizeOf(ftEntry));
    if I mod 128 = 0 then
      Application.ProcessMessages;
  end;

  FileName:=Prj.ReadString('Main', 'Constants', '');
  if not Prj.ValueExists('Main', 'Constants') then begin
    ctOffset := 0;
    ctSize := 0;
  end else begin
    L.Caption:='Reading constants...';
    Application.ProcessMessages;
    if not FileExists(Dir + FileName) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Constants file "'+FileName+'" not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    fI:=TMemoryStream.Create;
    fI.LoadFromFile(Dir + FileName);
    ctOffset := M.Size;
    ctSize := fI.Size;
    M.WriteBuffer(fI.Memory^, ctSize);
    fI.Free;
  end;
  M.Seek($D6, soFromBeginning);
  M.WriteBuffer(ctOffset, 4);
  M.WriteBuffer(ctSize, 4);
  M.Seek(M.Size, soFromBeginning);

  FileName:=Prj.ReadString('Main', 'Strings', '');
  if not Prj.ValueExists('Main', 'Strings') then begin
    stOffset := 0;
    stSize := 0;
  end else begin
    L.Caption:='Reading string table...';
    Application.ProcessMessages;
    if not FileExists(Dir + FileName) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Strings table file "'+FileName+'" not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    fI:=TMemoryStream.Create;
    fO:=TMemoryStream.Create;
    fI.LoadFromFile(Dir + FileName);
    while fI.Position < fI.Size do begin
      fI.ReadBuffer(B, 1);
      case B of
        $D: ;
        $A: begin
          B:=0;
          fO.WriteBuffer(B, 1);
        end;
        else
          fO.WriteBuffer(B, 1);
      end;
    end;
    fI.Free;
    fO.Seek(0, soFromBeginning);
    stOffset := M.Size;
    stSize := fO.Size;
    M.WriteBuffer(fO.Memory^, stSize);
    fO.Free;
  end;
  M.Seek($DE, soFromBeginning);
  M.WriteBuffer(stOffset, 4);
  M.WriteBuffer(stSize, 4);
  M.Seek(M.Size, soFromBeginning);

  FileName:=Prj.ReadString('Main', 'Code', '');
  if not Prj.ValueExists('Main', 'Code') then begin
    csOffset := 0;
    csSize := 0;
  end else begin
    L.Caption:='Reading code section...';
    Application.ProcessMessages;
    if not FileExists(Dir + FileName) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Code section file "'+FileName+'" not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    fI:=TMemoryStream.Create;
    fI.LoadFromFile(Dir + FileName);
    csOffset := M.Size;
    csSize := fI.Size;
    M.WriteBuffer(fI.Memory^, csSize);
    fI.Free;
  end;
  M.Seek($60, soFromBeginning);
  M.WriteBuffer(csSize, 4);
  M.Seek($E6, soFromBeginning);
  M.WriteBuffer(csOffset, 4);
  M.WriteBuffer(csSize, 4);
  M.Seek(M.Size, soFromBeginning);

  FileName:=Prj.ReadString('Main', 'Palette', '');
  if not Prj.ValueExists('Main', 'Palette') then begin
    plOffset := 0;
    plSize := 0;
  end else begin
    L.Caption:='Reading palette...';
    Application.ProcessMessages;
    if not FileExists(Dir + FileName) then begin
      CloseFile;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      PWideChar('Palette file "'+FileName+'" not found.'),
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    S:=TStringList.Create;
    S.LoadFromFile(Dir + FileName);
    if S.Count < 4 then begin
      CloseFile;
      S.Free;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      'Palette file is not in JASC-PAL format.',
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    if (S.Strings[0] <> 'JASC-PAL') or (S.Strings[1] <> '0100') then begin
      CloseFile;
      S.Free;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      'Palette file is not in JASC-PAL format.',
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    Err:=False;
    try
      ColorCnt:=StrToInt(S.Strings[2]);
    except
      Err:=True;
    end;
    if Err then begin
      CloseFile;
      S.Free;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      'Can''t read color count in palette.',
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    if S.Count <> ColorCnt+3 then begin
      CloseFile;
      S.Free;
      Prj.Free;
      Fr.Free;
      MessageBox(Handle,
      'Defined color count value doesn''t match the actual count of color entries in palette.',
      'Error',
      mb_Ok or mb_IconError);
      Exit;
    end;
    fI:=TMemoryStream.Create;
    for I:=3 to S.Count-1 do begin
      Err:=False;
      ColorStr := S.Strings[I];
      SetLength(clr, 0);
      if ColorStr[Length(ColorStr)]<>' ' then
        ColorStr:=ColorStr+' ';
      while Pos(' ', ColorStr) > 0 do begin
        SetLength(clr, Length(clr)+1);
        if Length(clr) > 3 then begin
          CloseFile;
          S.Free;
          fI.Free;
          Prj.Free;
          Fr.Free;
          MessageBox(Handle,
          PWideChar('Palette color entry contains more than 3 values of RGB (line '+IntToStr(I)+').'),
          'Error',
          mb_Ok or mb_IconError);
          Exit;
        end;
        try
          clr[High(clr)] := StrToInt(Copy(ColorStr, 1, Pos(' ',ColorStr)-1));
          Delete(ColorStr, 1, Pos(' ', ColorStr));
        except
          Err:=True;
        end;
        if Err then begin
          CloseFile;
          S.Free;
          fI.Free;
          Prj.Free;
          Fr.Free;
          MessageBox(Handle,
          PWideChar('Can''t read palette color (line '+IntToStr(I)+').'),
          'Error',
          mb_Ok or mb_IconError);
          Exit;
        end;
      end;
      fI.WriteBuffer(clr[0], 1);
      fI.WriteBuffer(clr[1], 1);
      fI.WriteBuffer(clr[2], 1);
      B:=0;
      fI.WriteBuffer(B, 1);
    end;
    S.Free;
    fI.Seek(0, soFromBeginning);
    plOffset := M.Size;
    plSize := fI.Size;
    M.WriteBuffer(fI.Memory^, plSize);
    fI.Free;
  end;
  M.Seek($EE, soFromBeginning);
  M.WriteBuffer(plOffset, 4);
  M.WriteBuffer(plSize, 4);

  Prj.Free;

  M.Seek($AF, soFromBeginning);
  Chk:=0;
  M.WriteBuffer(Chk, 1);
  M.Seek(0, soFromBeginning);
  for I:=0 to 285 do begin
    M.ReadBuffer(B, 1);
    Inc(Chk, B);
  end;
  Chk:=256-Chk;
  M.Seek($AF, soFromBeginning);
  M.WriteBuffer(Chk, 1);

  M.Seek(0, soFromBeginning);
  // render the table
  L.Caption:='Parsing and finishing...';
  Application.ProcessMessages;
  LoadFile;
  Fr.Free;
end;

procedure TMainForm.Music1Click(Sender: TObject);
var
  Dir: String;
  A: Array of Word;
  Swp: Word;
  Fnd: Boolean;
  I,J: Integer;
  FileName: String;
  Fr: TForm;
  L: TLabel;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  if not SelectDirectory('Choose directory', '', Dir) then
    Exit;

  if not FileExists(ExtractFilePath(Application.ExeName) + 'midi7th.exe') then begin
    MessageBox(Handle,
    '7th Level MIDI converter (midi7th.exe) not found. Please reinstall the program.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;

  Fr:=TForm.Create(Application);
  with Fr do begin
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Converting, please wait...';
    ClientWidth := 200;
    ClientHeight := 26;
    L:=TLabel.Create(Fr);
    with L do begin
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='Extracting and converting music...';
    end;
    Show;
  end;

  for I:=0 to Length(FileTable)-1 do begin
    Fnd:=False;
    for J:=0 to Length(A)-1 do
      if A[J] = FileTable[I].Flags then begin
        Fnd:=True;
        Break;
      end;
    if not Fnd then begin
      SetLength(A, Length(A)+1);
      A[Length(A)-1] := FileTable[I].Flags;
    end;
  end;

  repeat
    Fnd:=False;
    for I:=0 to Length(A)-2 do
      if A[I] > A[I+1] then begin
        Swp:=A[I];
        A[I]:=A[I+1];
        A[I+1]:=Swp;
        Fnd:=True;
      end;
  until not Fnd;

  Swp:=4;
  for I:=0 to Length(FileTable)-1 do
    if FileTable[I].Flags = Swp then begin
      Application.ProcessMessages;
      FileName:='res'+IntToStr(I)+'.7lm';
      ExtractResource(I, Dir + '\' + FileName);
      ExecAppAndWait('midi7th -d "'+Dir+'\res'+IntToStr(I)+'.7lm" "'+Dir+'\res'+IntToStr(I)+'.mid"', ExtractFilePath(Application.ExeName));
      DeleteFile(Dir + '\' + FileName);
    end;
  Fr.Free;
end;

procedure TMainForm.LoadFile;
var
  I: Integer;
  sig: Array[0..2] of AnsiChar;
  B,Chk1,Chk2: Byte;
  dw: LongWord;
  st,en: LongWord;
  id: Word;
begin
  if M.Size < 286 then begin
    CloseFile;
    MessageBox(Handle,
    'File size too small.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  FillChar(sig, 3, 0);
  M.ReadBuffer(sig, 2);
  if StrPas(sig) <> sign7L then begin
    CloseFile;
    MessageBox(Handle,
    '7th Level header signature not found.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  M.ReadBuffer(vMinor2, 1);
  M.ReadBuffer(vMinor1, 1);
  M.ReadBuffer(vMajor, 1);

  M.Seek($60, soFromBeginning);
  M.ReadBuffer(st, 4);
  M.Seek($EA, soFromBeginning);
  M.ReadBuffer(en, 4);
  if st<>en then begin
    MessageBox(Handle,
    'Code section size check is not equal the code section size.',
    'Warning',
    mb_Ok or mb_IconWarning);
  end;

  M.Seek($AF, soFromBeginning);
  M.ReadBuffer(Chk1, 1);
  M.Seek(0, soFromBeginning);
  Chk2:=0;
  for I:=0 to 174 do begin
    M.ReadBuffer(B, 1);
    Inc(Chk2, B);
  end;
  M.ReadBuffer(B, 1);
  for I:=176 to 285 do begin
    M.ReadBuffer(B, 1);
    Inc(Chk2, B);
  end;
  Chk2:=256-Chk2;
  if Chk1<>Chk2 then begin
    CloseFile;
    MessageBox(Handle,
    'Wrong checksum.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;

  // read file table size
  M.Seek($C2, soFromBeginning);
  M.ReadBuffer(dw, 4);
  SetLength(FileTable, dw div SizeOf(ftEntry));
  // read file table pointer
  M.Seek($BE, soFromBeginning);
  M.ReadBuffer(dw, 4);
  if M.Size < (dw + Length(FileTable)*SizeOf(ftEntry)) then begin
    CloseFile;
    MessageBox(Handle,
    'Wrong file size, possibly truncated.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;
  // read file table
  M.Seek(dw, soFromBeginning);
  SG.RowCount:=1 + Length(FileTable) + 5;
  for I:=0 to Length(FileTable)-1 do begin
    M.ReadBuffer(FileTable[I], SizeOf(ftEntry));
    SG.Cells[0,I+1]:=IntToHex(FileTable[I].Offset, 8);
    SG.Cells[1,I+1]:=IntToHex(FileTable[I].Size, 8);
    SG.Cells[2,I+1]:=IntToStr(FileTable[I].Flags);
    case FileTable[I].Flags of
      1: SG.Cells[2,I+1]:=SG.Cells[2,I+1]+' (graphics)';
      4: SG.Cells[2,I+1]:=SG.Cells[2,I+1]+' (music)';
      7: SG.Cells[2,I+1]:=SG.Cells[2,I+1]+' (sound)';
    end;
    if not (FileTable[I].Flags in [8..16]) then
      SG.Cells[3,I+1]:='Resource #'+IntToStr(I)
    else
      SG.Cells[3,I+1]:='Alias #'+IntToStr(I);
  end;
  // resource table info
  SG.Cells[0, Length(FileTable)+1]:=IntToHex(dw, 8);
  SG.Cells[1, Length(FileTable)+1]:=IntToHex(Length(FileTable)*SizeOf(ftEntry), 8);
  SG.Cells[2, Length(FileTable)+1]:='';
  SG.Cells[3, Length(FileTable)+1]:='Entry table';
  // read constants info
  M.Seek($D6, soFromBeginning);
  M.ReadBuffer(dw, 4);
  SG.Cells[0, Length(FileTable)+2]:=IntToHex(dw, 8);
  M.ReadBuffer(dw, 4);
  SG.Cells[1, Length(FileTable)+2]:=IntToHex(dw, 8);
  SG.Cells[2, Length(FileTable)+2]:='';
  SG.Cells[3, Length(FileTable)+2]:='Constants';
  // read system strings info
  M.Seek($DE, soFromBeginning);
  M.ReadBuffer(dw, 4);
  SG.Cells[0, Length(FileTable)+3]:=IntToHex(dw, 8);
  M.ReadBuffer(dw, 4);
  SG.Cells[1, Length(FileTable)+3]:=IntToHex(dw, 8);
  SG.Cells[2, Length(FileTable)+3]:='';
  SG.Cells[3, Length(FileTable)+3]:='Strings table';
  // read code section info
  M.Seek($E6, soFromBeginning);
  M.ReadBuffer(dw, 4);
  SG.Cells[0, Length(FileTable)+4]:=IntToHex(dw, 8);
  M.ReadBuffer(dw, 4);
  SG.Cells[1, Length(FileTable)+4]:=IntToHex(dw, 8);
  SG.Cells[2, Length(FileTable)+4]:='';
  SG.Cells[3, Length(FileTable)+4]:='Code section';
  // read palette info
  M.Seek($EE, soFromBeginning);
  M.ReadBuffer(dw, 4);
  SG.Cells[0, Length(FileTable)+5]:=IntToHex(dw, 8);
  M.ReadBuffer(dw, 4);
  SG.Cells[1, Length(FileTable)+5]:=IntToHex(dw, 8);
  SG.Cells[2, Length(FileTable)+5]:='';
  SG.Cells[3, Length(FileTable)+5]:='32-bit palette ('+IntToStr(dw shr 2)+' colors)';
  for I:=0 to Length(FileTable)-1 do begin
    id:=0;
    case FileTable[I].Flags of
      1: begin
        M.Seek(FileTable[I].Offset + 14, soFromBeginning);
        M.ReadBuffer(id, 2);
      end;
      4: begin
        M.Seek(FileTable[I].Offset + 2, soFromBeginning);
        M.ReadBuffer(id, 2);
      end;
      7: begin
        M.Seek(FileTable[I].Offset + 10, soFromBeginning);
        M.ReadBuffer(id, 2);
      end;
    end;
    if id>0 then
      SG.Cells[3, I+1]:=SG.Cells[3, I+1]+' (id '+IntToStr(id)+')';
  end;
  Opened:=True;
end;

procedure TMainForm.Open1Click(Sender: TObject);
begin
  Open.Title:='Open 7th Level File';
  Open.Filter:='7th Level executable binary (*.bin)|*.bin|All files (*.*)|*.*';
  if not Open.Execute then
    Exit;
  M:=TMemoryStream.Create;
  M.LoadFromFile(Open.FileName);
  LoadFile;
end;

function GetTempDirectory: String;
var
  tempFolder: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @tempFolder);
  result := StrPas(tempFolder);
end;

procedure TMainForm.PlayerChkTimer(Sender: TObject);
begin
  if AMovie <> nil then
    if not IsWindowVisible(AMovie.Handle) then begin
      PlayerChk.Enabled:=False;
      FreeAndNil(AMovie);
    end;
end;

procedure TMainForm.Previewplayselectedresource1Click(Sender: TObject);
var
  Dir: String;
  FileName: String;
  Rnd: Cardinal;
  Stat: Byte;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;

  Rnd:=Random(16777216);

  if SG.Row <= Length(FileTable) then begin
    FileName:='res'+IntToStr(SG.Row-1)+'_'+IntToStr(Rnd);
    case FileTable[SG.Row-1].Flags of
      4: FileName:=FileName+'.7lm';
      7: FileName:=FileName+'.7la';
      8..16: begin
        MessageBox(Handle,
        'Aliases can not be previewed because it''s not an actual resources.',
        'Information',
        mb_Ok or mb_IconAsterisk);
        Exit;
      end;
      else begin
        MessageBox(Handle,
        'Preview for this resource type is not available.',
        'Information',
        mb_Ok or mb_IconAsterisk);
        Exit;
      end;
    end;
  end else begin
    MessageBox(Handle,
    'Preview for this resource type is not available.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;

  Dir:=GetTempDirectory;
  FileName:=Dir + FileName;
  ExtractResource(SG.Row-1, FileName);
  case FileTable[SG.Row-1].Flags of
    4: begin
      if not FileExists(ExtractFilePath(Application.ExeName) + 'midi7th.exe') then begin
        MessageBox(Handle,
        '7th Level MIDI converter (midi7th.exe) not found. Please reinstall the program.',
        'Error',
        mb_Ok or mb_IconError);
        Exit;
      end;
      Stat:=ExecAppAndWait('midi7th -d "'+FileName+'" "'+Dir+'res'+IntToStr(SG.Row-1)+'_'+IntToStr(Rnd)+'.mid"', ExtractFilePath(Application.ExeName));
      DeleteFile(FileName);
      if Stat <> 2 then begin
        MessageBox(Handle,
        'An error occured while converting.',
        'Error',
        mb_Ok or mb_IconError);
        Exit;
      end;
      FileName:=Dir+'res'+IntToStr(SG.Row-1)+'_'+IntToStr(Rnd)+'.mid';
    end;
    7: begin
      if not FileExists(ExtractFilePath(Application.ExeName) + 'adpcm7th.exe') then begin
        MessageBox(Handle,
        '7th Level ADPCM codec (adpcm7th.exe) not found. Please reinstall the program.',
        'Error',
        mb_Ok or mb_IconError);
        Exit;
      end;
      Stat:=ExecAppAndWait('adpcm7th -d "'+FileName+'" "'+Dir+'res'+IntToStr(SG.Row-1)+'_'+IntToStr(Rnd)+'.wav"', ExtractFilePath(Application.ExeName));
      DeleteFile(FileName);
      if Stat <> 2 then begin
        MessageBox(Handle,
        'An error occured while converting.',
        'Error',
        mb_Ok or mb_IconError);
        Exit;
      end;
      FileName:=Dir+'res'+IntToStr(SG.Row-1)+'_'+IntToStr(Rnd)+'.wav';
    end;
  end;
  TempFiles.Add(FileName);
  if AMovie = nil then begin
    AMovie:=TForm.Create(Application);
    PlayMovie(AMovie.Handle, GetModuleHandle('AMovie.ocx'), PWideChar('/play /close ' + FileName), SW_SHOW);
    PlayerChk.Enabled := True;
  end;
end;

procedure TMainForm.Save1Click(Sender: TObject);
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  Save.Filter:='7th Level executable binary (*.bin)|*.bin|All files (*.*)|*.*';
  Save.FileName:='filename.bin';
  Save.Title:='';
  if not Save.Execute then
    Exit;
  M.Seek(0, soFromBeginning);
  M.SaveToFile(Save.FileName);
end;

procedure TMainForm.Sounds1Click(Sender: TObject);
var
  Dir: String;
  A: Array of Word;
  Swp: Word;
  Fnd: Boolean;
  I,J: Integer;
  FileName: String;
  Fr: TForm;
  L: TLabel;
begin
  if not Opened then begin
    MessageBox(Handle,
    'No file opened.',
    'Information',
    mb_Ok or mb_IconAsterisk);
    Exit;
  end;
  if not SelectDirectory('Choose directory', '', Dir) then
    Exit;

  if not FileExists(ExtractFilePath(Application.ExeName) + 'adpcm7th.exe') then begin
    MessageBox(Handle,
    '7th Level ADPCM codec (adpcm7th.exe) not found. Please reinstall the program.',
    'Error',
    mb_Ok or mb_IconError);
    Exit;
  end;

  Fr:=TForm.Create(Application);
  with Fr do begin
    Position := poOwnerFormCenter;
    BorderIcons := [];
    BorderStyle := bsDialog;
    Caption := 'Converting, please wait...';
    ClientWidth := 200;
    ClientHeight := 26;
    L:=TLabel.Create(Fr);
    with L do begin
      Parent := Fr;
      Left := 8;
      Top := 6;
      AutoSize := True;
      Caption:='Extracting and converting sounds...';
    end;
    Show;
  end;

  for I:=0 to Length(FileTable)-1 do begin
    Fnd:=False;
    for J:=0 to Length(A)-1 do
      if A[J] = FileTable[I].Flags then begin
        Fnd:=True;
        Break;
      end;
    if not Fnd then begin
      SetLength(A, Length(A)+1);
      A[Length(A)-1] := FileTable[I].Flags;
    end;
  end;

  repeat
    Fnd:=False;
    for I:=0 to Length(A)-2 do
      if A[I] > A[I+1] then begin
        Swp:=A[I];
        A[I]:=A[I+1];
        A[I+1]:=Swp;
        Fnd:=True;
      end;
  until not Fnd;

  Swp:=7;
  for I:=0 to Length(FileTable)-1 do
    if FileTable[I].Flags = Swp then begin
      Application.ProcessMessages;
      FileName:='res'+IntToStr(I)+'.7la';
      ExtractResource(I, Dir + '\' + FileName);
      ExecAppAndWait('adpcm7th -d "'+Dir+'\res'+IntToStr(I)+'.7la" "'+Dir+'\res'+IntToStr(I)+'.wav"', ExtractFilePath(Application.ExeName));
      DeleteFile(Dir + '\' + FileName);
    end;
  Fr.Free;
end;

end.
