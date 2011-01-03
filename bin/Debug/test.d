// usage dpp.exe test.d
import std.stdio, std.conv, std.string, std.array, std.functional ;
void main ()
{                       
	auto y1 = sum !{i = 0:10.0; i*sum !{j=0:10; i+j}} ;
	assert (y1 == 4875) ;
	//writeln (y1) ;

	/******************************************/
	auto y2 = prod!{i = 1:10;1+1.0/i} ;
	assert (typeof(y2).stringof == "double" && y2 == 10) ;
	//writeln (y2, " ", typeof (y2).stringof) ;
	/******************************************/
	auto y3 = min !{i=0:10; i*i-10*i+10} ;
	//writeln("min = ", y3) ;
	assert(y3 == -15) ;
	/******************************************/
	auto y4 = max !{i=0:10; i*i-10*i+10} ;
	//writeln("max = ", y4) ;
	assert(y4 == 10) ;

	/******************************************/
	int[] a = [1,1,2,1,1,2,3,4,5];
	//@@@bug@@@: x is allways of type int
	auto y5 = sum!{x:a, x!=1, x!=2; x} ;
	//writeln("sum {x:a; x} = ", y5) ;
	assert(is(typeof(y5)==int) && y5 == 12) ;
	/******************************************/
	auto y6 = forAll!{x:a; x>0};
	//auto y6 = reduce!"a&&b"(true,map!"a>0"(a));
	assert (y6 == true) ;
	assert (forAll!{i=0:10; sum!{(j,x):a; x*i*j} >= 0}) ;

	assert (forNone!{x:a; x==7}) ;
	assert (!forNone!{x:a; x==1}) ;
	assert (forAny!{x:a; x>2 && x<4}) ;

	/******************************************/	
	//f!{float a; a*a}
	//function (float a){return a*a;}
	//(float a){return a*a;}
	//writeln (f!{int a, int b; f!{int a; a*a}(a)+b}(2,2)) ;
	//writeln (f!{int a, int b; double c=1.0; c+a*b}(2,2)) ;
	assert (f!{a+1}(5) == 6) ;
	assert (f!{a+b}(1,2) == 3) ;

	struct Point 
	{
		int x ;
		int y ;
	}
	assert (f!{a.x * b.y - b.x*a.y}(Point(1, 1), Point(2, 2)) ==
		binaryFun!q{a.x * b.y - b.x*a.y}(Point(1, 1), Point(2, 2)) ) ;
	/******************************************/
	writeln(@"123");
	writeln(@"a= $a ***") ;

	/******************************************/
	writeln ("All tests passed") ;
}
