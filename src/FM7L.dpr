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
program FM7L;

{$R *.dres}

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  LicenseUnit in 'LicenseUnit.pas' {LicenseForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '7th Level File Manager';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TLicenseForm, LicenseForm);
  Application.Run;
end.
