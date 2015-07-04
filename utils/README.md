Utilities
=========
Here's the utilities that help building and debugging.

Visualize tokens
-----
```
$> token.bash path\to\test_file
```

example:
```
$ utils/token.bash test/t2/t2.pas
NAME: hello
NAME: i
NAME: go
NAME: a
NAME: a
INTEGER: 1
NAME: go
INTEGER: 1
NAME: a
INTEGER: 2
NAME: go
INTEGER: 1
NAME: go
NAME: go
NAME: a
INTEGER: 1
NAME: go
NAME: a
INTEGER: 2
NAME: i
NAME: go
INTEGER: 10
NAME: i
======================
PROGRAM NAME SEMI
VAR NAME COLON SYS_TYPE SEMI
FUNCTION NAME LP NAME COLON SYS_TYPE RP COLON SYS_TYPE SEMI
BEGIN_TOKEN IF NAME EQUAL INTEGER THEN BEGIN_TOKEN NAME ASSIGN INTEGER SEMI
END ELSE BEGIN_TOKEN IF NAME EQUAL INTEGER THEN BEGIN_TOKEN NAME ASSIGN INTEGER SEMI
END ELSE BEGIN_TOKEN NAME ASSIGN NAME LP NAME MINUS INTEGER RP PLUS NAME LP NAME MINUS INTEGER RP SEMI
END SEMI
END SEMI
END SEMI
BEGIN_TOKEN NAME ASSIGN NAME LP INTEGER RP SEMI
SYS_PROC LP NAME RP SEMI
END DOT
```

for t2.pas
```pascal
program hello;
var
	i : integer;

function go(a : integer): integer;
begin
	if a = 1 then
	begin
		go := 1;
	end
	else
	begin
		if a = 2 then
		begin
			go := 1;
		end
		else
		begin
			go := go(a - 1) + go(a - 2);
		end
		;
	end
	;
end
;

begin
	i := go(10);
	writeln(i);
end
.
```
