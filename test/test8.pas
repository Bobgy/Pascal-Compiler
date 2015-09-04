program hello;
var
	i : integer;
	j : integer;
	k : integer;
	a : array[0..10] of integer;
function test(x: integer): integer;
begin
	test := 6;
end;
function gao(x: integer): integer;
begin
	gao := 5;
end;
begin
	i := 3;
	a[i] := 4;
	writeln(a[i]);
	j := 5;
	a[j] := a[i];
	writeln(a[j]);
	k := 8;
	j := gao(i);
	writeln(j);
	writeln(a[5]+a[3]);
end
.
