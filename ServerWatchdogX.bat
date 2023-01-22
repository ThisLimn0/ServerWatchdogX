@ECHO OFF & SETLOCAL EnableDelayedExpansion
::: Change the CodePage to 437 (DOS Latin-1)
CHCP 437 >NUL
::: When Parameter is set to "Worker" script will run in worker mode
IF /I "%~1"=="Worker" (
   GOTO :StartWorker
)


:::Version:Information::::::::::::::::::::::::
:::    /// ::: /// ::: /// ::: /// ::: /// :::
SET "VER=0.2.5" ::: Script version
SET "REV=30032022" ::: Code revision
SET "GLOBALTTL=lll       Bello vX       lll"
SET "SysUptimeLength=short" ::: long/short
:::    /// ::: /// ::: /// ::: /// ::: /// :::



:::USER:SETTINGS:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::Change:the:following:settings:to:your:needs.::::::::::::::::::::::::::::::::::::::::::::::::::::
:::: /// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::::
:Settings
SET "UsableLines=30"                              ::: Text line count to calculate UI on default:30
SET "SSharedFolder="	                             ::: Server shared folder cloud/local share
SET "SPrivateFolder="							        ::: Pure server folder
SET "CSharedFolder="	                             ::: Client shared folder cloud/local share
:::: /// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::
::: --- DISPLAY ---
TITLE %GLOBALTTL%   [codebase: %VER% rev. %REV%] - The Windows Server Watchdog Toolkit
::: Display window size is 120x31
MODE 120,31
::: Display color is White on Dark Blue
COLOR 1B


CALL :CleanBeforeStart
CALL :ChooseNetworkCard


::: Spawn the worker background process
START /MIN "" %~dpnx0 "Worker"

::: FirstSet
SET "DontFreeze=0"
SET "DogWaggle=0"
SET "ErrorCount=0"
SET "WarnCount=0"
SET "IPv4Gate=not defined"
SET "IPv6Gate=not defined"

CALL :SplashSet



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::Display:Worker:Main:Loop:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:DisplayLoop
CALL :Display
IF %DogWaggle% EQU 0 (
    CALL :ResetAll
)
REM DEBUG inject to kill worker after 150 ticks
REM IF DEFINED BGPTick (
REM    IF !BGPTick! GTR 150 (
REM       CALL :KillWorker
REM    )
REM )
TIMEOUT /T 1 >NUL
IF !BGPTick! GTR 3 (
   CALL :LoadData
)

GOTO :DisplayLoop

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



::: Should run as an endless loop, but if things go out of bounds...
Timeout /T 60 >NUL



GOTO :DisplayLoop
::: --- DISPLAY.Modules ---

:ChooseNetworkCard
IF EXIST ".\ServerWatchdogLastSession.txt" (
	ECHO.It seems like there is an existing Session. Do you want to read the settings from the last session?
	CHOICE /C YN /T 4 /D Y
	IF !ERRORLEVEL! EQU 1 (
		FOR /F "usebackq delims=*" %%X IN (".\ServerWatchdogLastSession.txt") DO (
			SET "Choice=%%X"
		)
		SET "NETW=1"
		FOR /F "skip=2 usebackq tokens=2* delims=, " %%A IN (`wmic nicconfig where "IPEnabled=TRUE and IPConnectionMetric>0" get Caption /format:csv`) DO (
			SET "NET!NETW!=%%A %%B"
			SET /A NETW+=1
		)
		ECHO.Set the NetworkCard Choice to !Choice!.
		GOTO :ChooseNetworkCard.Choice
	) ELSE (
		GOTO :ChooseNetworkCard.NewSession
	)
)
:ChooseNetworkCard.NewSession
ECHO. Setup
ECHO.  - Choose a Network Card to monitor from below
SET "NETW=1"
FOR /F "skip=2 usebackq tokens=2* delims=, " %%A IN (`wmic nicconfig where "IPEnabled=TRUE and IPConnectionMetric>0" get Caption /format:csv`) DO (
	ECHO. !NETW!. %%A %%B
	SET "NET!NETW!=%%A %%B"
	IF "!NET%NETW%!"=="" (
		GOTO :ChooseNetworkCard.Choice
	) ELSE (
		SET /A NETW+=1
	)
)
:ChooseNetworkCard.Choice
IF DEFINED Choice (
		SET "ChosenNetworkCard=!NET%Choice%!"
	) ELSE (
		SET /P "Choice=>"
)
ECHO.!Choice!>".\ServerWatchdogLastSession.txt"
IF DEFINED NET!Choice! (
	SET "ChosenNetworkCard=!NET%Choice%!"
)
EXIT /B

:GenerateHeartbeat
:::Get optimised time and date for tracing
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
   IF "%%~L"=="" goto w_done
      Set _yyyy=%%L
      Set _mm=00%%J
      Set _dd=00%%G
      Set _hour=00%%H
      SET _minute=00%%I
      SET _second=00%%K
)
:w_done

:: Pad digits with leading zeros
Set _mm=%_mm:~-2%
Set _dd=%_dd:~-2%
Set _hour=%_hour:~-2%
Set _minute=%_minute:~-2%
Set _second=%_second:~-2%
ECHO.%_yyyy%_%_mm%_%_dd%;%_hour%_%_minute%_%_second%>".\heartbeat.srvf"
IF NOT EXIST ".\heartbeat.srvf" (
	TITLE !GlobalTitle!   l   Heartbeat ERROR [^</3]
) ELSE (
	TITLE !GlobalTitle!   l   Heartbeat sent: [^<3] %_hour%:%_minute%:%_second%
)
EXIT /B

:CalculateLength
SET "SplashStringMaxLen=27"
SET "DisplayStringMaxLen=92"
EXIT /B


:CheckBGPTick
IF NOT DEFINED BGPTick (
    IF NOT EXIST ".\t" (
        SET "L30=                                        Background worker process is terminated^!"
        CALL :KillWorker
    ) ELSE (
        SET /P BGPTick=<".\t"
        IF NOT DEFINED BGPTick (
          SET "L30="
        ) ELSE (
          SET "L30=                                        Background worker process tick {%BGPTick%}"
        )
    )
) ELSE (
    IF NOT EXIST ".\t" (
        SET "L2=  Background worker process is terminated^!"
        CALL :KillWorker
    ) ELSE (
       SET "BGPTickOld=!BGPTick!"
       SET /P BGPTick=<".\t"
       IF !BGPTickOld! EQU !BGPTick! (
          IF NOT DEFINED BGPTickErr (
             SET /A BGPTickErr+=1
             SET "L30=                                        Background worker process tick {%BGPTick%}"
          ) ELSE IF !BGPTickErr! GTR 4 (
             SET "L30=                                        Background worker process is restarting..."
             CALL :KillWorker
          ) ELSE (
             SET /A BGPTickErr+=1
             SET "L30=                                        Background worker process is terminated^!"
          )
       ) ELSE (
             SET "BGPTickErr="
             SET "L30=                                        Background worker process tick {%BGPTick%}"
       )
    )
)
EXIT /B


:LoadData
CALL :ResetDisplay
IF EXIST "layout.gtx" (
    FOR /F "usebackq delims=*" %%I IN (".\layout.gtx") DO SET %%I
)
EXIT /B


:SplashSet
SET "SPL1=^<^!--                        "
SET "SPL2=         |`-.__             "
SET "SPL3=          / '  _/ Bello vX  "
SET "SPL4=         ****`     !VER!    "
SET "SPL5=        /    }              "
SET "SPL6=  .    /   \ /              "
SET "SPL7=   \ /`    \\\              "
SET "SPL8=    `\     /_\\             "
SET "SPL9=     `~~~~~` `~`            "
SET "SPL10=                            "
SET "SPL11=  Watchdog goes woof^!   --^> "
SET "SPL12=                            "
SET "SPL13=                            "
SET "SPL14=                            "
SET "SPL15=                            "
SET "SPACER=                           "
SET "L14=                                       +-------------+"
SET "L15=                                       | Starting up |"
SET "L16=                                       | Please wait |"
SET "L17=                                       +-------------+"
EXIT /B


:DogTailAnimation
CALL :CheckBGPTick
IF %DogWaggle% EQU 0 (
    :::default
    SET "SPL6=  .    /   \ /              "
    SET "SPL7=   \ /`    \\\              "
    SET "SPL8=    `\     /_\\             "
    SET "SPL9=     `~~~~~` `~`            "
    SET "DogWaggle=1"
) ELSE IF %DogWaggle% EQU 1 (
    :::waggle_HighMid
    SET "SPL6=       /   \ /              "
    SET "SPL7= ,-. /`    \\\              "
    SET "SPL8=    `\     /_\\             "
    SET "SPL9=     `~~~~~` `~`            "
    SET "DogWaggle=2"
    EXIT /B
) ELSE IF %DogWaggle% EQU 2 (
    :::waggle_LowMid
    SET "SPL6=       /   \ /              "
    SET "SPL7=     /`    \\\              "
    SET "SPL8=  ,-`\     /_\\             "
    SET "SPL9= `   `~~~~~` `~`            "
    SET "DogWaggle=3"
    EXIT /B
) ELSE IF %DogWaggle% EQU 3 (
    :::waggle_HighMid
    SET "SPL6=       /   \ /              "
    SET "SPL7= ,-. /`    \\\              "
    SET "SPL8=    `\     /_\\             "
    SET "SPL9=     `~~~~~` `~`            "
    SET "DogWaggle=0"
    EXIT /B
)
EXIT /B

:BuildCommandPallette
EXIT /B

:ResetAll
FOR /L %%A in (1,1,24) DO (
	SET "L%%A="
)
FOR /L %%A in (12,1,15) DO (
	SET "SPL%%A=                            "
)
EXIT /B


:ResetDisplay
FOR /L %%A in (1,1,30) DO (
	SET "L%%A="
)
EXIT /B


:Display
CALL :DogTailAnimation
::: Clear
CLS
FOR /L %%A in (1,1,!UsableLines!) DO (
	IF DEFINED SPL%%A (
		IF DEFINED L%%A (
			ECHO.!SPL%%A!^|!L%%A!
		) ELSE IF NOT DEFINED L%%A (
			ECHO.!SPL%%A!^|
		)
	) ELSE IF NOT DEFINED SPL%%A (
		ECHO.!SPACER! ^|!L%%A!
	)
)
EXIT /B

:KillWorker
ECHO.1>".\kill"
TIMEOUT /T 1 >NUL
START /MIN "" %~dpnx0 "Worker"
SET "BGPTick="
SET "BGPTickOld="
EXIT /B



:::::::::::::::::::::::::::



:::::::::::::::::::
::: --- WORKER ---
:StartWorker

TITLE Bello vX background worker process
SET "PID=%RANDOM:~0,3%-%RANDOM:~0,3%"
SET "Tick=0"


::: RunOnce
CALL :CleanBeforeStart
IF !ERRORLEVELCBS! GTR 0 (
   CALL :Warn "CleanRoutine exited with errors." "!ERRORLEVELCBSREASON!"
)
CALL :CreateESC
CALL :CreateTick

CALL :Info "Bello vX background worker process started. PID: %PID%"

CALL :IsTeamViewerInstalled

::: Suppress non issued error messages
CALL :Tick 2>NUL
::: RunAtTick



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::Background:Worker:Main:Loop::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:Tick
TITLE Bello vX background worker process - {%Tick%}
SET /A Tick+=1
ECHO.%Tick%>".\t"
IF %ERRORLEVEL% GTR 0 (
    CALL :Error "Can't write to file" "Tick: [.\t]"
)
TIMEOUT /T 1 >NUL
IF %Tick% GTR 31999 (
    SET "Tick=0"
    CALL :Info "Reset tick after 32000"
)
SET /A ASyncEvent=%Tick%%%5
IF !ASyncEvent! EQU 0 (
    CALL :GetSystemUptime
)
IF EXIST "./kill" (
   CALL :ExitWorker
)
CALL :LockFile
CALL :TickLoad
CALL :TickSave
CALL :UnlockFile
GOTO :Tick

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:LockFile
ECHO.!PID!>".\lock" 2>NUL
IF %ERRORLEVEL% GTR 0 (
   CALL :Error "Can't write to file" "LockFile: [.\lock]"
)
EXIT /B

:UnlockFile
DEL /F /Q ".\lock" 2>NUL
IF %ERRORLEVEL% GTR 0 (
   CALL :Error "Can't delete file" "UnlockFile: [.\lock]"
)
EXIT /B

:TickLoad
IF EXIST "layout.gtx" (
    DEL /F /Q "layout.gtx" 2>NUL
    IF %ERRORLEVEL% GTR 0 (
       CALL :Error "Can't delete file" "TickLoad: [layout.gtx]"
    )
)
EXIT /B

:TickSave
IF EXIST ".\lock" (
   FOR /F "usebackq delims=*" %%I IN (".\lock") DO SET "LockPID=%%I"
   IF %ERRORLEVEL% GTR 0 (
       CALL :Error "Can't read from file" "TickSave: [.\lock]"
   )
   IF NOT !LockPID! EQU !PID! (
      CALL :Error "PID mismatch." "TickSave:!LockPID![!PID!]"
      EXIT
   )
)
IF /i "!SysUptimeLength!"=="long" (
   ECHO."L28=  [SysUptime]                    Uptime is: !SystemUptimeDays! days, !SystemUptimeHours! hours, !SystemUptimeMinutes! minutes, !SystemUptimeSeconds! seconds.">>"layout.gtx"
) ELSE IF /i "!SysUptimeLength!"=="short" (
   ECHO."L28=  [SysUptime]                    Uptime: !SystemUptimeDays!d !SystemUptimeHours!h !SystemUptimeMinutes!m !SystemUptimeSeconds!s.">>"layout.gtx"
) ELSE (
   ECHO."L28=  [SysUptime]                    Uptime is: !SystemUptimeDays! days, !SystemUptimeHours! hours, !SystemUptimeMinutes! minutes, !SystemUptimeSeconds! seconds.">>"layout.gtx"
)

IF !TVInstalled! EQU 1 (
    ECHO."L20=  [TeamViewerStatus]         TeamViewer is installed.">>"layout.gtx"
    ECHO."L21=   --^> !TVPath!">>"layout.gtx"
    ECHO."L22=  [TeamViewerStatus]         TeamViewer is running.">>"layout.gtx"
) ELSE (
    ECHO."L20=  [TeamViewerStatus]             TeamViewer is not installed.">>"layout.gtx"
)
IF %ERRORLEVEL% GTR 0 (
       CALL :Error "Can't write to file" "TickSave: [layout.gtx]"
)
EXIT /B

:GetSystemUptime
FOR /F "UseBackQ Tokens=1-4" %%A IN (
    `Powershell "$OS=GWmi Win32_OperatingSystem;$UP=(Get-Date)-"^
    "($OS.ConvertToDateTime($OS.LastBootUpTime));$DO='d='+$UP.Days+"^
    "' h='+$UP.Hours+' n='+$UP.Minutes+' s='+$UP.Seconds;Echo $DO"`) DO (
    SET "%%A"&SET "%%B"&SET "%%C"&SET "%%D")
SET "SystemUptimeDays=!d!"
SET "SystemUptimeHours=!h!"
SET "SystemUptimeMinutes=!n!"
SET "SystemUptimeSeconds=!s!"
IF !SystemUptimeDays! GTR 6 (
    IF DEFINED SystemUptimeBeyondThreshold (
       IF !SystemUptimeBeyondThreshold! GTR 5 (
          CALL :Info "System uptime is beyond threshold. Reboot is required"
          shutdown -r -t 0 2>NUL
          IF %ERRORLEVEL% GTR 0 (
              CALL :Error "Could not issue shutdown command" "SystemUptimeBeyondThreshold: [ERR:!ERRORLEVEL!]"
          ) ELSE (
              CALL :Done "Reboot command successful"
          )
          TIMEOUT /T 60 >NUL
       ) ELSE (
            IF !ASyncEvent! EQU 0 (
                SET /A SystemUptimeBeyondThreshold+=1
            )
        )
    )
)
EXIT /B

:ExitWorker
CALL :CleanBeforeStart
EXIT


::: --- WORKER.Modules ---


:Done
SET "Reason=%~1"
SET "Trace=%~2"
IF DEFINED Trace (
   SET "Trace={Trace:!Trace!}"
)
ECHO.!E![42m!E![30m  !T!  !E![0m!E![32m  [DONE]   [!Time:~0,8!] - !Reason! !Trace! !E![0m
EXIT /B

:Info
SET "Reason=%~1"
SET "Trace=%~2"
IF DEFINED Trace (
   SET "Trace={Trace:!Trace!}"
)
ECHO.!E![44m!E![30m  i  !E![0m!E![36m  [INFO]   [!Time:~0,8!] - !Reason! !Trace! !E![0m
EXIT /B

:Warn
SET "Reason=%~1"
SET "Trace=%~2"
IF DEFINED Trace (
   SET "Trace={Trace:!Trace!}"
)
ECHO.!E![43m!E![30m  ^!  !E![0m!E![33m  [WARN]   [!Time:~0,8!] - !Reason! !Trace! !E![0m
EXIT /B

:Error
SET "Reason=%~1"
SET "Trace=%~2"
IF DEFINED Trace (
   SET "Trace={Trace:!Trace!}"
)
ECHO.!E![41m!E![30m  x  !E![0m!E![91m  [ERROR]  [!Time:~0,8!] - !Reason! !Trace! !E![0m
EXIT /B

:CreateESC
FOR /f "delims=" %%E IN (
    'FORFILES /p "%~dp0." /m "%~nx0" /c "CMD /c ECHO(0x1B"'
) DO SET "E=%%E"
EXIT /B

:CreateTick
::: Alt+0251=û
FOR /f "delims=" %%T IN (
    'FORFILES /p "%~dp0." /m "%~nx0" /c "CMD /c ECHO(0xFB"'
) DO SET "T=%%T"
EXIT /B

::: RunOnce Modules

:IsTeamViewerInstalled
FOR /f "usebackq tokens=3*" %%A IN (`reg query HKLM\SOFTWARE\TeamViewer /v InstallationDirectory`) DO (
	SET "TVPath=%%A %%B"
	SET "TVPath=!TVPath!\TeamViewer.exe"
)
IF %ERRORLEVEL% EQU 0 (
	CALL :Info "TeamViewer is installed [!TVPATH!]"
   SET "TVInstalled=1"
	REM SET "ITR="
	REM SET "TRIM1=[Restart TeamViewer]"
	REM SET "TRIM2=î"
) ELSE (
	CALL :Warn "TeamViewer is not installed" "IsTeamViewerInstalled:Error"
   SET "TVInstalled=0"
	REM SET "L3=	 (x) Module IsProcessRunning deactivated"
	REM SET "TRIM1=--------------------"
	REM SET "TRIM2= "
	REM SET "ITR=REM "
)
EXIT /B

:IsProcessRunning
FOR /F "delims=]+ tokens=1,2,3,4" %%A IN ('TASKLIST /FI "IMAGENAME eq TeamViewer.exe" ^| FIND /I /N "TeamViewer"') DO (
	SET "TeamViewerResult=%%B"
	SET "TeamViewerResult=!TeamViewerResult:~0,14!
)
!DFC!
IF /i "!TeamViewerResult!"=="TeamViewer.exe" (
	FOR /F "delims=*" %%A IN ('TASKLIST /fi "status eq not responding" /nh ^| FIND /I /N "TeamViewer.exe"') DO (
		SET "TeamViewerResultNotResponding=%%B"
		SET "TeamViewerResultNotResponding=!TeamViewerResultNotResponding:~0,14!
	)
	IF "%ERRORLEVEL%"=="0" (
		REM TeamViewer not responding
	) ELSE (
		REM TeamViewer responding.
		SET "IsProcessRunning.Result=TeamViewerRunning"
	)
	SET "IsProcessRunning.Result=TeamViewerRunning"
) ELSE (
	SET "IsProcessRunning.Result=TeamViewerNotRunning"
	CALL :GetTeamViewerRunning
)
EXIT /B

:GetTeamViewerRunning
FOR /L %%A in (1,1,5) DO (
	TASKKILL /IM "TeamViewer.exe" 2>NUL
)
START "" "!TVPath!"
EXIT /B


:Timestamp
SET "TS=[!DATE!] [!TIME:~0,2!:!TIME:~3,2!:!TIME:~6,2! !TIME:~9,2!ms] "
EXIT /B


:CleanBeforeStart
SET "ERRORLEVELCBS=" ::: Clean errorlevel var
IF EXIST ".\Bello_vX_bgworker.log" (
   DEL /F /Q ".\Bello_vX_bgworker.log" >NUL
)
IF %ERRORLEVEL% GTR 0 (
   SET "ERRORLEVELCBS=%ERRORLEVEL%"
   SET "ERRORLEVELCBSREASON=DeleteLog"
)
IF EXIST ".\layout.gtx" (
   DEL /F /Q ".\layout.gtx" >NUL
)
IF %ERRORLEVEL% GTR 0 (
   SET "ERRORLEVELCBS=%ERRORLEVEL%"
   SET "ERRORLEVELCBSREASON=DeleteLayout"
)
IF EXIST ".\lock" (
   DEL /F /Q ".\lock" >NUL
)
IF %ERRORLEVEL% GTR 0 (
   SET "ERRORLEVELCBS=%ERRORLEVEL%"
   SET "ERRORLEVELCBSREASON=DeleteLock"
)
IF EXIST ".\t" (
   DEL /F /Q ".\t" >NUL
)
IF %ERRORLEVEL% GTR 0 (
   SET "ERRORLEVELCBS=%ERRORLEVEL%"
   SET "ERRORLEVELCBSREASON=DeleteTick"
)
IF EXIST ".\kill" (
   DEL /F /Q ".\kill" >NUL
)
IF %ERRORLEVEL% GTR 0 (
   SET "ERRORLEVELCBS=%ERRORLEVEL%"
   SET "ERRORLEVELCBSREASON=DeleteIssuedKill"
)
EXIT /B %ERRORLEVELCBS%

::: RunAtTick Modules

:GetCPULoadPercentage
FOR /F "skip=1 usebackq delims=*" %%A IN (`wmic cpu get loadpercentage`) DO (
	SET "CPUUsage!ZC!=%%A"
	SET "L4=	 [%ZC%] Probing CPU Usage: !CPUUsage%ZC%!"
	GOTO :GetCPULoadPercentage.Avg
)
:GetCPULoadPercentage.Avg
IF !ZC! EQU 3 (
	SET /A "CPUUsageAvg=CPUUsage1+CPUUsage2+CPUUsage3"
	SET /A "CPUUsageAvg=CPUUsageAvg/3"
	IF !CPUUsageAvg! GTR 80 (
		SET "GetCPULoadPercentage.Result=CPULoadAvgHigh"
		SET "L4=	 [*] High CPU Usage: !CPUUsageAvg!%%"
	) ELSE (
		SET "GetCPULoadPercentage.Result=CPULoadAvgNorm"
		SET "L4=	 [*] Average CPU Usage: !CPUUsageAvg!%%"
	)
)
SET /a ZC+=1
EXIT /B

:GetMemoryTotal
FOR /F "skip=1 usebackq" %%D IN (`wmic ComputerSystem get TotalPhysicalMemory`) DO (
	SET "TotalMemory=%%D"
	GOTO :GetMemoryFree
)
:GetMemoryFree
FOR /F "skip=1 usebackq" %%E IN (`wmic OS get FreePhysicalMemory`) DO (
	SET "AvailableMemory=%%E"
	GOTO :GetMemoryLoadPercentage.ProcessValues
)
:GetMemoryLoadPercentage.ProcessValues
SET "TotalMemory=%TotalMemory:~0,-6%"
SET /A TotalMemory+=50
SET /A TotalMemory/=1024
SET /A TotalMemory*=1024
SET /A AvailableMemory/=1024
SET /A "UsedMemory=TotalMemory - AvailableMemory"
SET /A "UsedPercent=(UsedMemory * 100) / TotalMemory"
IF !UsedPercent! GTR 79 (
	SET /A WARNCOUNT+=1
	SET "GetMemoryLoadPercentage.Result=MemoryLoadAvgHigh"
	SET "L5=	 [*] High Memory Usage: !UsedPercent!%%"
) ELSE IF !UsedPercent! LSS 80 (
	SET "GetMemoryLoadPercentage.Result=MemoryLoadAvgNorm"
	SET "L5=	 [*] Average Memory Usage: !UsedPercent!%%"
)
EXIT /B

::::::::::::::::::::::::::
