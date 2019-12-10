vlib work
IF ERRORLEVEL 1 GOTO error

vlog ..\..\u765.sv
IF ERRORLEVEL 1 GOTO error


vlog ..\image_controller.sv
IF ERRORLEVEL 1 GOTO error


vlog tb_img_ctrl.sv
IF ERRORLEVEL 1 GOTO error
vsim -novopt -t ns tb -do all_img_ctrl.do
IF ERRORLEVEL 1 GOTO error

goto ok

:error
echo Ocorreu erro
pause

:ok
