unit LicenseUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TLicenseForm = class(TForm)
    mText: TMemo;
    bAccept: TButton;
    bDecline: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LicenseForm: TLicenseForm;

implementation

{$R *.dfm}

end.
