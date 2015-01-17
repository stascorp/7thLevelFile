{
	This file is part of 7th Level File Manager.

	Copyright (C) Stas'M Corp. 2012
	http://stascorp.com/

	7th Level File Manager is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	7th Level File Manager is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with 7th Level File Manager.  If not, see <http://www.gnu.org/licenses/>.
}
unit Res;

interface

uses
  Windows, Classes;

function ExtractResText(ResName: String): String;

implementation

function ExtractResText(ResName: String): String;
var
  ResStream: TResourceStream;
  Str: TStringList;
begin
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  Str := TStringList.Create;
  try
    Str.LoadFromStream(ResStream);
  except

  end;
  ResStream.Free;
  Result := Str.Text;
  Str.Free;
end;

end.
