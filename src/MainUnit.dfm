object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = '7th Level File Manager v1.0 by Stas'#39'M'
  ClientHeight = 282
  ClientWidth = 413
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = Menu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object SG: TStringGrid
    Left = 0
    Top = 0
    Width = 413
    Height = 282
    Align = alClient
    ColCount = 4
    DefaultRowHeight = 16
    FixedCols = 0
    RowCount = 2
    TabOrder = 0
    OnDblClick = Extractselectedresource1Click
  end
  object Menu: TMainMenu
    Left = 264
    Top = 80
    object File1: TMenuItem
      Caption = '&File'
      object Open1: TMenuItem
        Caption = '&Open'
        ShortCut = 16463
        OnClick = Open1Click
      end
      object Close1: TMenuItem
        Caption = 'Close'
        ShortCut = 16499
        OnClick = Close1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        ShortCut = 16467
        OnClick = Save1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Importasproject1: TMenuItem
        Caption = 'Import from &project...'
        ShortCut = 16457
        OnClick = Importasproject1Click
      end
      object Exportasproject1: TMenuItem
        Caption = '&Export to project...'
        ShortCut = 16453
        OnClick = Exportasproject1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = '&Exit'
        OnClick = Exit1Click
      end
    end
    object Extract1: TMenuItem
      Caption = '&Tools'
      object Fileinformation1: TMenuItem
        Caption = '&Information'
        ShortCut = 73
        OnClick = Fileinformation1Click
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Extractselectedresource1: TMenuItem
        Caption = 'E&xtract selected resource'
        ShortCut = 69
        OnClick = Extractselectedresource1Click
      end
      object Extractallresources1: TMenuItem
        Caption = 'Extract &all resources'
        OnClick = Extractallresources1Click
      end
      object Extractallresourcesbytype1: TMenuItem
        Caption = 'Extract all resources by &type...'
        OnClick = Extractallresourcesbytype1Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Previewplayselectedresource1: TMenuItem
        Caption = 'Pre&view/play selected resource'
        ShortCut = 32
        OnClick = Previewplayselectedresource1Click
      end
      object Convert1: TMenuItem
        Caption = '&Convert resources'
        object Sounds1: TMenuItem
          Caption = '&Sounds'
          OnClick = Sounds1Click
        end
        object Music1: TMenuItem
          Caption = '&Music'
          OnClick = Music1Click
        end
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object License1: TMenuItem
        Caption = '&License agreement'
        OnClick = License1Click
      end
      object About1: TMenuItem
        Caption = '&About'
        OnClick = About1Click
      end
    end
  end
  object Open: TOpenDialog
    Filter = '7th Level executable binary (*.bin)|*.bin|All files (*.*)|*.*'
    Left = 264
    Top = 32
  end
  object Save: TSaveDialog
    Filter = '7th Level Audio File|*.7la'
    Left = 304
    Top = 32
  end
  object PlayerChk: TTimer
    Enabled = False
    Interval = 50
    OnTimer = PlayerChkTimer
    Left = 304
    Top = 80
  end
end
