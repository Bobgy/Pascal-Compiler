program suffix;
const
    maxn=10000;
var
    i,j,n,p,q,ans,pos,sum           :integer;
    x, y: array[1..100] of integer;
procedure qsort(l:integer;r:integer);
var i,j,k,p,temp:integer;
begin
    i:=l;j:=r;
    k:=x[(i+j) div 2];
    p:=y[(i+j) div 2];
    repeat
        while (x[i]<k)or((x[i]=k)and(y[i]<p)) do inc(i);
        while (x[j]>k)or((x[j]=k)and(y[j]>p)) do dec(j);
        if i<=j then
            begin
                temp:=x[i];x[i]:=x[j];x[j]:=temp;
                temp:=y[i];y[i]:=y[j];y[j]:=temp;
                temp:=sa[i];sa[i]:=sa[j];sa[j]:=temp;
                inc(i);dec(j);
            end;
    until i>j;
    if i<r then qsort(i,r);
    if l<j then qsort;
end;
begin
    x[1]:=1;
    x[100]:=3; 
    qsort(1,100);
end.
