object Form1: TForm1
  Left = 192
  Top = 138
  Width = 858
  Height = 481
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 120
  TextHeight = 16
  object Button1: TButton
    Left = 32
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 32
    Top = 80
    Width = 809
    Height = 353
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 1
    OnDblClick = Memo1DblClick
  end
  object txturl: TEdit
    Left = 32
    Top = 48
    Width = 817
    Height = 24
    TabOrder = 2
    Text = 
      'iscsi://192.168.1.144/iqn.2008-08.com.starwindsoftware:erwan-pc2' +
      '-test2/0'
  end
  object Button2: TButton
    Left = 768
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 216
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Write'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 440
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Read'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 520
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Read2'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 296
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Write2'
    TabOrder = 7
    OnClick = Button6Click
  end
end
