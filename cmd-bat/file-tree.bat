echo off & color 0A
echo 当前目录："%cd%" >fileTree.txt
tree /f >>fileTree.txt 
echo 目录树已生成，按任意键查看。
pause>nul
start fileTree.txt