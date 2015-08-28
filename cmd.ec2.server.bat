@echo off
setlocal enabledelayedexpansion
set ERR=nothing to do.
set TMP=%~dp0tmp.txt
set i=1


rem -------- arg check
if not "%1"=="start" if not "%1"=="stop" (
	echo usage: cmd.ec2.server [start] [stop] option:[ELB name]
	exit /B
)

if "%1" equ "" (
	echo usage: cmd.ec2.server [start] [stop] option:[ELB name]
	exit /B
)

if "%1"=="start" (
	set RUN=start
)

if "%1"=="stop" (
	set RUN=stop
)


rem -------- your EC2 instances display
echo your EC2 instance(s):

if "%2" neq "" (

	echo ELB name: %2
	aws elb describe-instance-health --load-balancer-name "%2" | jq -r ".InstanceStates[]|{InstanceId, State}"
	aws elb describe-instance-health --load-balancer-name "%2" | jq -r ".InstanceStates[].InstanceId" > tmp.txt

) else (

	aws ec2 describe-instances | jq -r ".Reservations[].Instances[] | {State, InstanceId, PublicDnsName, PublicIpAddress}"
	aws ec2 describe-instances | jq -r ".Reservations[].Instances[].InstanceId" > %TMP%
)

call :sub %TMP%
goto :eof
:sub
if %~z1==0 (
	exit /B
)


rem -------- build pseudo array
for /f "delims=" %%a in (%TMP%) do (
	set /a Array_Index=!Array_Index!+1
	set Array[!Array_Index!]=%%a
	echo [!Array_Index!] %%a
)


rem -------- run target
echo choose EC2 instance number (ctrl+c or enter to cancel):
set /P INUM=

if "%INUM%" equ "" (
	echo %ERR%
	exit /B
)

if %INUM% gtr %Array_Index% (
	echo %ERR%
	exit /B
)

aws ec2 %RUN%-instances --instance-ids !Array[%INUM%]!

del /Q %TMP%

