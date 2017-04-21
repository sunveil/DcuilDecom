object DCU2INTOption: TDCU2INTOption
  Left = 593
  Top = 191
  Width = 417
  Height = 204
  Caption = 'DCU2INTOption'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 401
    Height = 165
    Align = alClient
    Caption = 'Select Options'
    TabOrder = 0
    object c1: TCheckBox
      Left = 8
      Top = 16
      Width = 153
      Height = 17
      Caption = 'show Imported names'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object c2: TCheckBox
      Left = 8
      Top = 40
      Width = 161
      Height = 17
      Caption = 'show Type table'
      TabOrder = 1
    end
    object c3: TCheckBox
      Left = 8
      Top = 64
      Width = 169
      Height = 17
      Caption = 'show Address table'
      TabOrder = 2
    end
    object C4: TCheckBox
      Left = 8
      Top = 88
      Width = 145
      Height = 17
      Caption = 'show Data block'
      TabOrder = 3
    end
    object C5: TCheckBox
      Left = 8
      Top = 112
      Width = 97
      Height = 17
      Caption = 'show fixups'
      TabOrder = 4
    end
    object C6: TCheckBox
      Left = 192
      Top = 16
      Width = 169
      Height = 17
      Caption = 'show auxiliary Values'
      TabOrder = 5
    end
    object C7: TCheckBox
      Left = 192
      Top = 40
      Width = 161
      Height = 17
      Caption = 'don'#39't resolve class methods'
      TabOrder = 6
    end
    object C8: TCheckBox
      Left = 192
      Top = 64
      Width = 176
      Height = 17
      Caption = 'don'#39't resolve constant values'
      TabOrder = 7
    end
    object C10: TCheckBox
      Left = 192
      Top = 112
      Width = 185
      Height = 17
      Caption = 'show VMT for objects and classes'
      TabOrder = 8
    end
    object C9: TCheckBox
      Left = 192
      Top = 88
      Width = 97
      Height = 17
      Caption = 'show dot types'
      TabOrder = 9
    end
    object OK: TButton
      Left = 192
      Top = 136
      Width = 75
      Height = 25
      Caption = 'OK'
      TabOrder = 10
      OnClick = OKClick
    end
    object Cancel: TButton
      Left = 280
      Top = 136
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 11
      OnClick = CancelClick
    end
  end
end
