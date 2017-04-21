object DCU2INT: TDCU2INT
  Left = 367
  Top = 234
  Width = 687
  Height = 611
  Caption = 'DCU32Decom'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 0
    Top = 41
    Width = 671
    Height = 511
    Align = alClient
    TabOrder = 0
    object Splitter1: TSplitter
      Left = 192
      Top = 1
      Height = 509
    end
    object TVProc: TTreeView
      Left = 1
      Top = 1
      Width = 191
      Height = 509
      Align = alLeft
      Indent = 19
      TabOrder = 0
      OnClick = TVProcClick
      OnDblClick = TVProcDblClick
    end
    object REDCUDump: TRichEdit
      Left = 195
      Top = 1
      Width = 475
      Height = 509
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100000000
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 671
    Height = 41
    Align = alTop
    TabOrder = 1
    object GroupBox: TGroupBox
      Left = 16
      Top = 0
      Width = 465
      Height = 33
      TabOrder = 0
      object ChkDasmMode: TComboBox
        Left = 160
        Top = 8
        Width = 145
        Height = 21
        ItemHeight = 13
        TabOrder = 0
        Text = 'ChkDasmMode'
        OnChange = ChkDasmModeChange
        Items.Strings = (
          'DasmSeq'
          'DasmCtrlFlow')
      end
      object ChkDisAsm: TComboBox
        Left = 8
        Top = 8
        Width = 145
        Height = 21
        ItemHeight = 13
        TabOrder = 1
        Text = 'ChkDisAsm'
        OnChange = ChkDisAsmChange
        Items.Strings = (
          'MSIL'
          'CIL'
          'x86')
      end
      object GML: TComboBox
        Left = 312
        Top = 8
        Width = 145
        Height = 21
        ItemHeight = 13
        ItemIndex = 1
        TabOrder = 2
        Text = 'GUI'
        OnChange = GMLChange
        Items.Strings = (
          'GML'
          'GUI')
      end
    end
  end
  object ProcFile: TOpenDialog
    Left = 832
    Top = 8
  end
  object SaveDlg: TSaveDialog
    Filter = 'Rich Text Format (*.RTF)|*.rtf'
    Left = 800
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 624
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
      object ProcessFile1: TMenuItem
        Caption = 'Process file'
        OnClick = ProcessFile1Click
      end
      object Saveasrtf1: TMenuItem
        Caption = 'Save as rtf'
        OnClick = Saveasrtf1Click
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
    object Config1: TMenuItem
      Caption = 'Config'
      object Options1: TMenuItem
        Caption = 'Options'
        OnClick = Options1Click
      end
    end
  end
end
