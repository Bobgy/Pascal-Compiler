program hello;
var
	i : integer;
	j : integer;
	k : integer;
function gao(x: integer): integer;
begin
	gao := 5;
end;
begin
	i := 3;
	j := 5;
	k := 8;
	j := gao(i);
	writeln(j);
end
.
