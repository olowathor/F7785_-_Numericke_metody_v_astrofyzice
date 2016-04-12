@echo off
rem this works in CS-TeX;
rem (if it doesn't work try LATEX=latex, PLAIN=plaintex ???)
SET LATEX=cslatex
SET PLAIN=csplain

if "%1"=="" goto help

rem you can set some other environment variables here
rem SET EMTEXDIR=c:\emtex
rem SET TEXVER=htex386
rem SET TEXSIZE=h
rem SET MFVER=bmf386
rem SET DVIPSVER=dvips32
rem this is recommended
SET INDEXOPT=-s %EMTEXDIR%\idxstyle\gind.ist
rem nevertheless it's intended to be run from `inside' of CS-TeX environment
rem where it all should be already properly set
if "%EMTEXDIR%"=="" goto outside

if "%1"=="all" goto all
if "%1"=="clean" goto clean
if "%1"=="doc" goto doc
if "%1"=="install" goto install
goto help

:all
if "%TEXVER%"=="" goto outside
if "%MFVER%"=="" goto outside

@echo on
@rem prepare variables like %OPT%, etc.
call %EMTEXDIR%\bin\%PLAIN%.bat
@if not exist %EMTEXDIR%\%TEXSIZE%texfmts\%FMT%.fmt goto nofmt

@rem generate the packages, font soruces
%TEXVER% %OPT% &%FMT% moremath.ins
@rem generate metric files
%MFVER% \mode=laserjet; \input cmvec10;
@echo off
goto end

:install
@echo on
@rem make directories
mkdir %EMTEXDIR%\texinput\trific
mkdir %EMTEXDIR%\mfinput\trific
mkdir %EMTEXDIR%\tfm\trific
mkdir %EMTEXDIR%\doc\trific
@rem if I put it all on one line, DOS will truncate it
@rem and you'll get grabage :-(
copy /y binbreak.sty %EMTEXDIR%\texinput\trific
copy /y binbreak.tex %EMTEXDIR%\texinput\trific
copy /y bracksym.sty %EMTEXDIR%\texinput\trific
copy /y mathabbr.sty %EMTEXDIR%\texinput\trific
copy /y mathabbr.tex %EMTEXDIR%\texinput\trific
copy /y moremath.sty %EMTEXDIR%\texinput\trific
copy /y newvec.sty %EMTEXDIR%\texinput\trific
copy /y valform.sty %EMTEXDIR%\texinput\trific
copy /y valform.tex %EMTEXDIR%\texinput\trific
copy /y ot1cmvec.fd %EMTEXDIR%\texinput\trific
copy /y cmvec10.mf %EMTEXDIR%\mfinput\trific
copy /y cmvec10.tfm %EMTEXDIR%\mfinput\trific
copy /y moremath.dvi %EMTEXDIR%\doc\trific
copy /y moremath.ps %EMTEXDIR%\doc\trific
copy /y README.htm %EMTEXDIR%\doc\trific
copy /y LICENSE %EMTEXDIR%\doc\trific
@echo off
goto end

:doc
@echo on
@rem prepare variables like %OPT%, etc.
call %EMTEXDIR%\bin\%LATEX%.bat
@if not exist %EMTEXDIR%\%TEXSIZE%texfmts\%FMT%.fmt goto nofmt

@rem generate documentation --- three passes are needed :-(
@rem and maybe more, but usually it should be enough
%TEXVER% %OPT% &%FMT% moremath.dtx
%TEXVER% %OPT% &%FMT% moremath.dtx
%EMTEXDIR%\bin\csindex %INDEXOPT% moremath
%TEXVER% %OPT% &%FMT% moremath.dtx
%EMTEXDIR%\bin\dvidrv %DVIPSVER% moremath
@echo off
goto end

:clean
@echo on
@rem delete products
del binbreak.sty
del binbreak.tex
del bracksym.sty
del mathabbr.sty
del mathabbr.tex
del moremath.sty
del newvec.sty
del valform.sty
del valform.tex
del ot1cmvec.fd
del cmvec10.mf
del cmvec10.tfm
del cmvec10.300
del cmvec10.600
@rem documentation
del moremath.dvi
del moremath.ps
@rem and auxilarity/bak files
del moremath.log
del moremath.aux
del moremath.dlg
del moremath.toc
del moremath.idx
del moremath.ind
del moremath.ilg
del cmvec10.log
del moremath.bak
del cmvec10.bak
del make.bak
@echo off
goto end

:help
echo This is a make-fake for generating/installing components of moremath bundle
echo under DOS CS-TeX. Read README for further details. Or try to run make.bat
echo with parametres `all' (generates all moremath components), `install' (tries
echo to install them to _CS-TeX_ directory structure), `doc' (generates
echo documentation --- DVI and PostScript) or `clean' (does what you expect).
goto end

:outside
echo Problem: At least one of EMTEXDIR, TEXVER, MFVER is undefined or empty.
echo Try to run this script from `inside' of CS-TeX enverionment.
echo (It needs also some other variables set.)
goto end

:nofmt
echo Problem: %EMTEXDIR%\%TEXSIZE%texfmts\%FMT%.fmt doesn't exist.
echo It means you haven't compiled any LaTeX and/or PlainTeX document yet,
echo or, more likely, something went wrong.
goto end

echo .
:end
