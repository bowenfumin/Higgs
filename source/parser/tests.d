/*****************************************************************************
*
*                      Higgs JavaScript Virtual Machine
*
*  This file is part of the Higgs project. The project is distributed at:
*  https://github.com/maximecb/Higgs
*
*  Copyright (c) 2011, Maxime Chevalier-Boisvert. All rights reserved.
*
*  This software is licensed under the following license (Modified BSD
*  License):
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are
*  met:
*   1. Redistributions of source code must retain the above copyright
*      notice, this list of conditions and the following disclaimer.
*   2. Redistributions in binary form must reproduce the above copyright
*      notice, this list of conditions and the following disclaimer in the
*      documentation and/or other materials provided with the distribution.
*   3. The name of the author may not be used to endorse or promote
*      products derived from this software without specific prior written
*      permission.
*
*  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
*  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
*  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
*  NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
*  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*****************************************************************************/

module parser.tests;

import std.stdio;
import parser.ast;
import parser.parser;

ASTProgram testParse(string input, bool valid = true)
{
    //writefln("input: %s", input);

    try
    {
        auto ast = parseString(input);

        if (valid == false)
        {
            assert (
                false,
                "parse succeeded on invalid input:\n" ~
                input         
           );
        }

        return ast;
    }

    catch (Throwable e)
    {
        if (valid == true)
        {
            writeln("parse failed on input:\n" ~ input);
            throw e;
        }

        return null;
    }
}

ASTProgram testAST(string input, ASTNode inAst)
{
    ASTProgram outAst = testParse(input);

    string outStr = outAst.toString();
    string inStr = inAst.toString();

    if (outStr != inStr)
    {
        assert (
            false,
            "Incorrect parse for:\n" ~
            input ~ "\n" ~
            "expected:\n" ~
            inStr ~ "\n" ~
            "got:\n"~
            outStr
        );
    }

    return outAst;
}

ASTProgram testExprAST(string input, ASTExpr exprAst)
{
    ASTProgram inAst = new ASTProgram([new ExprStmt(exprAst)]);
    return testAST(input, inAst);
}

/// Test parsing of simple expressions
unittest
{
    testParse("");
    testParse(";");
    testParse("+", false);
    testParse(":", false);
    testParse("1", false);
    testParse("1;");
    testParse("3.0;");
    testParse("\"foobar\";");
    testParse("[1, 2, 3];");
    testParse("true;");
    testParse("false;");
    testParse("null;");
}

/// Test expression parsing
unittest
{
    testParse("1 + 1;");
    testParse("1 * 2 + 4 + -b;");
    testParse("++x;");

    testParse("foo !== \"bar\";");

    testParse("x = 1;");
    testParse("x += 1;");

    testParse("z = f[2] + 3; ++z;");
    testParse("1? 2:3 + 4;");

    testParse("[x + y, 2, \"foo\"];");
}

/// Test expression ASTs
unittest
{
    testExprAST("1;", new IntExpr(1));
    testExprAST("7.0;", new FloatExpr(7));
    testExprAST("true;", new TrueExpr());
    testExprAST("false;", new FalseExpr());
    testExprAST("null;", new NullExpr());

    testExprAST("1 + b;", 
        new BinOpExpr("+", new IntExpr(1), new IdentExpr("b"))
    );

    testExprAST("1 + 2 * 3;", 
        new BinOpExpr(
            "+",
            new IntExpr(1),
            new BinOpExpr(
                "*",
                new IntExpr(2),
                new IntExpr(3)
            )
        )
    );

    testExprAST("foo + 1 + 2;", 
        new BinOpExpr(
            "+",
            new BinOpExpr(
                "+",
                new IdentExpr("foo"),
                new IntExpr(1),
            ),
            new IntExpr(2)
        )
    );

    testExprAST("foo + bar == bif;", 
        new BinOpExpr(
            "==",
            new BinOpExpr(
                "+",
                new IdentExpr("foo"),
                new IdentExpr("bar")
            ),
            new IdentExpr("bif")
        )
    );

    testExprAST("-a.b;", 
        new UnOpExpr(
            "-", 'r', 
            new BinOpExpr(
                ".", 
                new IdentExpr("a"),
                new IdentExpr("b")
            )
        )
    );

    testExprAST("-a + b;",
        new BinOpExpr(
            "+", 
            new UnOpExpr("-", 'r', new IdentExpr("a")),
            new IdentExpr("b")
        )
    );

    testExprAST("a.b.c;",
        new BinOpExpr(
            ".", 
            new BinOpExpr(
                ".", 
                new IdentExpr("a"),
                new IdentExpr("b")
            ),
            new IdentExpr("c")
        )
    );

    testExprAST("++a.b;", 
        new UnOpExpr(
            "++", 'r', 
            new BinOpExpr(
                ".", 
                new IdentExpr("a"),
                new IdentExpr("b")
            )
        )
    );

    testExprAST("a.b();",
        new CallExpr(
            new BinOpExpr(
                ".", 
                new IdentExpr("a"),
                new IdentExpr("b")
            ),
            []
        )
    );

    testExprAST("a++;", 
        new UnOpExpr(
            "++", 'l', 
            new IdentExpr("a"),
        )
    );

    testExprAST("a + b++;",
        new BinOpExpr(
            "+",
            new IdentExpr("a"),
            new UnOpExpr(
                "++", 'l', 
                new IdentExpr("b"),
            )
        )
    );

    testExprAST("++a.b();",
        new UnOpExpr(
            "++", 'r', 
            new CallExpr(
                new BinOpExpr(
                    ".", 
                    new IdentExpr("a"),
                    new IdentExpr("b")
                ),
                []
            )
        )
    );

    testExprAST("-a++;",
        new UnOpExpr(
            "-", 'r',
            new UnOpExpr(
                "++", 'l',
                new IdentExpr("a")
            )
        )
    );

    testExprAST("a = b? 1:2;",
        new BinOpExpr(
            "=", 
            new IdentExpr("a"),
            new CondExpr(
                new IdentExpr("b"),
                new IntExpr(1),
                new IntExpr(2)
            )
        )
    );

    testExprAST("x += y;",
        new BinOpExpr(
            "=", 
            new IdentExpr("x"),
            new BinOpExpr(
                "+",
                new IdentExpr("x"),
                new IdentExpr("y")
            )
        )
    );
}

/// Test statement parsing
unittest
{
    testParse("{}");
    testParse("{ 1; }");
    testParse("{ 1; 2; }");

    testParse("var x;");
    testParse("var x; var y; var z = 1 + 1;");
    testParse("var x += 2;", false);

    testParse("if (x) f();");
    testParse("if (x) f(); else g();");
    testParse("if (x) { f(); }");
    testParse("if (x);");
    testParse("if () {}", false);

    testParse("while (true) 1;");
    testParse("while (false);");

    testParse("do {} while (x)");
    testParse("do; while(true)");
    testParse("do while (x)", false);
    testParse("do; while ()", false);

    testParse("for (var i = 0; i < 10; i += 1) println(\"foobar\");");
    testParse("for (;;) {}");
    testParse("for (;;);");
    testParse("for (;);", false);

    testParse("throw 1;");
    testParse("throw;", false);

    testParse("try foo(); catch (e) e;");
    testParse("try foo(); catch (e) e; finally bar();");
}

/// Test program-level ASTs
unittest
{
    testAST(
        "",
        new ASTProgram([])
    );

    testAST(
        "var x = 1;",
        new ASTProgram([new VarStmt(new IdentExpr("x"), new IntExpr(1))])
    );
}

/// Test function parsing and ASTs
unittest
{
    testParse("fun () { return 1; };");
    testParse("fun () { return; };");
    testParse("fun (x) {};");
    testParse("fun (x,y) {};");
    testParse("fun (x,) {};", false);
    testParse("fun (x) { if (x) return 1; else return 2; };",);

    testExprAST("fun () { return 1; };",
        new FunExpr(
            [], 
            new BlockStmt([new ReturnStmt(new IntExpr(1))])
        )
    );

    testExprAST("fun () 1;;",
        new FunExpr([], new ReturnStmt(new IntExpr(1)))
    );
}
