@ECHO Off & SETLOCAL EnableDelayedExpansion
MODE 120,31
COLOR 1B
TITLE lll       Bello vX       lll   Status: Starting up...


:::    /// ::: /// ::: /// ::: /// ::: /// :::
SET "VER=0.2.1"
SET "VERSION=0.2.1-20210310"
:::    /// ::: /// ::: /// ::: /// ::: /// :::



::USER:SETTINGS::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::: /// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::::
:Settings
SET "UsableLines=30"							::: Text line count to calculate UI on	 default:30
SET "SSharedFolder=C:\Dropbox\ZZZ_SVDX_Comms"	 ::: Server shared folder cloud/local share
SET "SPrivateFolder=C:\Scripts"							 ::: Pure server folder
SET "CSharedFolder=D:\Dropbox\ZZZ_SVDX_Comms"	 ::: Client shared folder cloud/local share
SET "GlobalTitle=lll       Bello vX       lll   codebase[!VERSION!]"
:::: /// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::: /// ::: /// ::: /// :::/// ::: /// ::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



::TODO:::::::::::::::::::::::::::::::::::::::::::::::
REM self copy into temporary directory, but transfer original starting point in order to prevent runtime errors when script is edited 
:::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::Pre:Start:Setup::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::/CALLS::::
SET "UPD=CALL :SplashCoexist"
SET "DFC=CALL :DontFreeze"
::::/FIRSTSET::::
SET "DF=0"
SET "ERRORCOUNT=0"
SET "WARNCOUNT=0"
SET "IPv4Gate=not defined"
SET "IPv6Gate=not defined"
SET "ZC=1"
SET "FIX2=is"
!DFC!
CALL :SplashSet
CALL :DetectIfClientOrServer
!DFC!
CALL :IsTeamViewerInstalled
CALL :SetCommands
!DFC!
CALL :ChooseNetworkCard
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:MAIN
TITLE !GlobalTitle!
CALL :ResetAll
CALL :GenerateHeartbeat
SET "L2=---[Status]"
!ITR!SET "L3=	 [ ] Fetching IsProcessRunning"
SET "L5=	 [ ] Fetching Memory usage
SET "L6=	 [ ] Fetching GetInternetConnection1"
SET "L7=	 [ ] Fetching GetInternetConnection2 (Gateway Adress)"
SET "L8=	 [ ] Fetching Results..."
SET "L9=	 [ ] Preparing briefing..."
CALL :GetMemoryLoadPercentage1
CALL :GetCPULoadPercentage
SET "L3=	>[ ] Fetching IsProcessRunning"
!UPD!
!ITR!CALL :IsProcessRunning
!ITR!SET "L3=	 [*] Fetching IsProcessRunning"
!UPD!
SET "L6=	>[ ] Fetching GetInternetConnection1"
!UPD!
CALL :GetInternetConnection1
SET "L6=	 [*] Fetching GetInternetConnection1"
!UPD!
SET "L7=	>[ ] Fetching GetInternetConnection2 (Gateway Adress)"
!UPD!
CALL :GetCPULoadPercentage
CALL :GetInternetConnection2
SET "L7=	 [*] Fetching GetInternetConnection2 (Gateway Adress)"
!UPD!
CALL :GetCPULoadPercentage
SET "L8=	>[ ] Fetching Results..."
!UPD!
CALL :Results
SET "L8=	 [*] Fetching Results..."
SET "L9=	 [*] Preparing Briefing..."
!UPD!
CALL :WAITUpd
GOTO :MAIN
EXIT /B

REM /////////////////////////////////////////////////////////////
 
:IsProcessRunning
FOR /F "delims=]+ tokens=1,2,3,4" %%A IN ('TASKLIST /FI "IMAGENAME eq TeamViewer.exe" ^| FIND /I /N "TeamViewer"') DO (
	SET "TMPModify=%%B"
	SET "TMPModify=!TMPModify:~0,14!
)
!DFC!
IF /i "!TMPModify!"=="TeamViewer.exe" (
	FOR /F "delims=*" %%A IN ('TASKLIST /fi "status eq not responding" /nh ^| FIND /I /N "TeamViewer.exe"') DO (
		SET "TMPModify2=%%B"
		SET "TMPModify2=!TMPModify2:~0,14!
	)
	IF "%ERRORLEVEL%"=="0" (
		REM TeamViewer not Responding
	) ELSE (
		REM TeamViewer Responding.
		SET "IsProcessRunning.Result=TeamViewerRunning"
	)
	SET "IsProcessRunning.Result=TeamViewerRunning"
) ELSE (
	SET /A ERRORCOUNT+=1
	SET "IsProcessRunning.Result=TeamViewerNotRunning"
	CALL :GetTeamViewerRunning
)
EXIT /B

:GetTeamViewerRunning
FOR /L %%A in (1,1,5) DO (
	TASKKILL /IM "TeamViewer.exe" 2>NUL
)
TIMEOUT /T 3 >NUL
Start "" "!TVPath!"
TIMEOUT /T 3 >NUL
SET "FIX= - TeamViewer was started automatically."
SET "FIX2=was"
EXIT /B

:SetCommands
SET "SPL26=               [Commands]---"
SET "L25=---[Restart Computer]----!TRIM1!---[Copy IPv4 to Clipboard]"
SET "L26=            î             !TRIM2!                              î              "
SET "L27=---------[Copy IPv6 to Clipboard]----------[Restart Watchdog]"
SET "L28=                  î                         î     "
SET "L29=                    [X] Emergency restart packet"
SET "L30=                     î"
EXIT /B

:ResetAll
FOR /L %%A in (1,1,24) do (
	SET "L%%A="
)
FOR /L %%A in (12,1,15) do (
	SET "SPL%%A=                            "
)
!DFC!
MODE 120,31
SET "TMPModify="
SET "FIX="
SET "ZC=1"
EXIT /B 

:GetInternetConnection1
PING -n 3 -w 1000 8.8.8.8 | find /i "bytes=" >NUL
!DFC!
IF %ERRORLEVEL% EQU 0 (
	SET "InternetConnectedFlag=true"
	SET "GetInternetConnection1.Result=InternetConnection1Connected"
) ELSE (
	SET /A ERRORCOUNT+=1
	SET "InternetConnectedFlag=false"
	SET "GetInternetConnection1.Result=InternetConnection1NotPossible"
)
EXIT /B

:GetCPULoadPercentage
FOR /F "skip=1 usebackq delims=*" %%A IN (`wmic cpu get loadpercentage`) DO (
	SET "CPUUsage!ZC!=%%A"
	SET "L4=	 [%ZC%] Probing CPU Usage: !CPUUsage%ZC%!"
	!DFC!
	GOTO :GetCPULoadPercentage.Avg
)
:GetCPULoadPercentage.Avg
IF !ZC! EQU 3 (
	SET /A "CPUUsageAvg=CPUUsage1+CPUUsage2+CPUUsage3"
	SET /A "CPUUsageAvg=CPUUsageAvg/3"
	IF !CPUUsageAvg! GTR 80 (
		SET /A WARNCOUNT+=1
		SET "GetCPULoadPercentage.Result=CPULoadAvgHigh"
		SET "L4=	 [*] High CPU Usage: !CPUUsageAvg!%%"
	) ELSE (
		SET "GetCPULoadPercentage.Result=CPULoadAvgNorm"
		SET "L4=	 [*] Average CPU Usage: !CPUUsageAvg!%%"
	)
)
!DFC!
SET /a ZC+=1
EXIT /B

:GetMemoryLoadPercentage1
FOR /F "skip=1 usebackq" %%D IN (`wmic ComputerSystem get TotalPhysicalMemory`) DO (
	SET "TotalMemory=%%D"
	GOTO :GetMemoryLoadPercentage2
)
:GetMemoryLoadPercentage2
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
IF !UsedPercent! GTR 80 (
	SET /A WARNCOUNT+=1
	SET "GetMemoryLoadPercentage.Result=MemoryLoadAvgHigh"
	SET "L5=	 [*] High Memory Usage: !UsedPercent!%%"
) ELSE IF !UsedPercent! LSS 80 (
	SET "GetMemoryLoadPercentage.Result=MemoryLoadAvgNorm"
	SET "L5=	 [*] Average Memory Usage: !UsedPercent!%%"
)
EXIT /B

:IsTeamViewerInstalled
FOR /f "usebackq tokens=3*" %%A IN (`reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer /v InstallationDirectory`) DO (
	SET "TVPath=%%A %%B"
	SET "TVPath=!TVPath!\TeamViewer.exe"
)
IF %ERRORLEVEL% EQU 0 (
	REM ECHO. [DEBUG]TeamViewer is installed.
	SET "ITR="
	SET "TRIM1=[Restart TeamViewer]"
	SET "TRIM2=î"
) ELSE (
	ECHO.ERROR^!^!^! Team Viewer might not be installed.
	SET "L3=	 (x) Module IsProcessRunning deactivated"
	SET "TRIM1=--------------------"
	SET "TRIM2= "
	SET "ITR=REM "
)
EXIT /B

:GetInternetConnection2
SET "GATEWAYADDR="
REM IPv4&IPv6
FOR /F "usebackq tokens=2-3 delims={+,+}" %%A IN (`wmic nicconfig where "IPEnabled=TRUE and Caption='%ChosenNetworkCard%'" get defaultipgateway /format:list ^| findstr "I"`) DO (
	SET "IPv4GateTMP=%%~A"
	SET "IPv6GateTMP="
	IF DEFINED IPv4GateTMP ( SET "IPv4GateTMP=!IPv4GateTMP: =!" & IF NOT "!IPv4GateTMP!"=="" ( SET "IPv4Gate=!IPv4GateTMP!" ) )
	IF DEFINED IPv6GateTMP ( SET "IPv6GateTMP=!IPv6GateTMP: =!" & IF NOT "!IPv6GateTMP!"=="" ( SET "IPv6Gate=!IPv6GateTMP!" ) )
)
!DFC!
IF DEFINED IPv4Gate (
	PING -n 3 -w 1000 !IPv4Gate! | find /i "bytes=" >NUL
	!DFC!
	IF %ERRORLEVEL% EQU 0 (
		SET "GetInternetConnection2.ResultIPv4=InternetConnection2Connected"
	) ELSE (

		SET /A ERRORCOUNT+=1
		SET "GetInternetConnection2.ResultIPv4=InternetConnection2NotPossible"
	)
	IF DEFINED IPv6Gate (
		PING -n 3 -w 1000 !IPv6Gate! | find /i "bytes=" >NUL
		!DFC!
		IF %ERRORLEVEL% EQU 0 (
			SET "GetInternetConnection2.ResultIPv6=InternetConnection2Connected"
		) ELSE (
			SET /A ERRORCOUNT+=1
			SET "GetInternetConnection2.ResultIPv6=InternetConnection2NotPossible"
		)
	)
)
EXIT /B

:ChooseNetworkCard
IF EXIST "%SPrivateFolder%\ServerWatchdogLastSession.txt" (
	ECHO.It seems like there is an existing Session. Do you want to read the settings from the last session?
	CHOICE /C YN /T 4 /D Y 
	IF !ERRORLEVEL! EQU 1 (
		FOR /F "usebackq delims=*" %%X IN ("%SPrivateFolder%\ServerWatchdogLastSession.txt") DO (
			SET "Choice=%%X" 
		)
		SET "NETW=1"
		FOR /F "skip=2 usebackq tokens=2* delims=, " %%A IN (`wmic nicconfig where "IPEnabled=TRUE and IPConnectionMetric>0" get Caption /format:csv`) DO (
			SET "NET!NETW!=%%A %%B"
			SET /A NETW+=1
		)
		ECHO.Set the NetworkCard Choice to !Choice!.
		GOTO :ChooseNetworkCard.Choice
	)
	IF !ERRORLEVEL! EQU 2 (
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
ECHO.!Choice!>"%SPrivateFolder%\ServerWatchdogLastSession.txt"
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
ECHO.%_yyyy%_%_mm%_%_dd%;%_hour%_%_minute%_%_second%>"!SSharedFolder!\heartbeat.srvf"
IF NOT EXIST "!SSharedFolder!\heartbeat.srvf" (
	TITLE !GlobalTitle!   l   Heartbeat ERROR [^</3]
) ELSE (
	TITLE !GlobalTitle!   l   Heartbeat sent: [^<3] %_hour%:%_minute%:%_second%
)
EXIT /B

:DetectIfClientOrServer
EXIT /B

:ServerRestartOverSharedFolder.Client

ECHO.RESTART>"%CSharedFolder%\ServerWatchdogLastWish.ZZZ"
ECHO.Emergency Restart packet was sent. The server should restart in about 50 seconds and be up in 2 Minutes max.,
PAUSE >NUL
EXIT /B
:ServerRestartOverSharedFolder.Server
IF EXIST "%SSharedFolder%\ServerWatchdogLastWish.ZZZ" (
	IF EXIST "%SSharedFolder%\ServerWatchdogLockFile.YYY" (
		EXIT /B
	)
	IF EXIST "%TEMP%\ServerWatchdogLastWishClientPacket.ZZZ" (	
		EXIT /B
	)
	ECHO.Emergency restart packet was received.
	DEL /F /Q "%SSharedFolder%\ServerWatchdogLastWish.ZZZ"
	ECHO.LOCKED!TIME!;!DATE!>"%SharedFolder%\ServerWatchdogLockFile.YYY"
	REM Let shared folder sync deleted file to avoid reboot-loop and sync lockfile to avoid reboot-loop.
	REM Lockfile in case the sync fails due to internet outage
	TIMEOUT /T 30 >NUL
	shutdown /r /f /t 10
)
EXIT /B
:WAITUpd
FOR /L %%A in (60,-1,1) DO (
	CHOICE /C NTC46W /T 1 /D N >NUL
	IF %ERRORLEVEL% EQU 1 (
		SET "BLANK="
	)
	IF %ERRORLEVEL% EQU 2 (
		REM Restart TeamViewer Choice
	)
	IF %ERRORLEVEL% EQU 3 (
		REM Restart Computer Choice
	)
	IF %ERRORLEVEL% EQU 4 (
		REM Copy IPv4 Choice
		ECHO !IPv4Gate!^| CLIP
		PAUSE
	)
	IF %ERRORLEVEL% EQU 5 (
		REM Copy IPv6 Choice
		ECHO !IPv6Gate!^| CLIP
		PAUSE
	)
	IF %ERRORLEVEL% EQU 6 (
		REM Restart Watchdog Choice
	)
	SET "SPL13=  Waiting for %%A seconds... "
	IF %%A EQU 30 ( CALL :GenerateHeartbeat )
	IF %%A EQU 1 (
		SET "SPL13=  Waiting for %%A second...  "
	)
	CALL :TailAnim
	!UPD!
)
SET "SPL13=  Watchdog is on Duty...      "
EXIT /B

:TailAnim
EXIT /B


REM SET /A tail+=1
:::default
SET "SPL6=  .    /   \ /              "
SET "SPL7=   \ /`    \\\              "
SET "SPL8=    `\     /_\\             "
SET "SPL9=     `~~~~~` `~`            "
:::waggle_mid
SET "SPL6=       /   \ /              "
SET "SPL7= ,-. /`    \\\              "
SET "SPL8=    `\     /_\\             "
SET "SPL9=     `~~~~~` `~`            "
:::waggle_down
SET "SPL6=       /   \ /              "
SET "SPL7=     /`    \\\              "
SET "SPL8=  ,-´\     /_\\             "
SET "SPL9= ´   `~~~~~` `~`            "

EXIT /B

:DontFreeze
IF "%DF%"=="1" (
	SET "DF=0"
	SET "L1=                                                                                        ßÜ"
	SET "SPL30=Üß                          "
) ELSE IF "%DF%"=="0" (
	SET "DF=1"
	SET "L1=                                                                                        Üß"
	SET "SPL30=ßÜ                          "
)
EXIT /B

:GetInternetConnection3
PING -n 2 -w 1000 8.8.8.8 | find /i "bytes=" >NUL
IF %ERRORLEVEL% EQU 0 (
    ECHO. [i] Connected to the internet.
	SET "GetInternetConnection3.Result=InternetConnection1Connected"
) ELSE (
    ECHO. /^^!\ Not connected to the internet.
	SET /A ERRORCOUNT+=1
	SET "GetInternetConnection3.Result=InternetConnection1NotPossible"
)
EXIT /B

:SplashSet
REM OLD SPLASH COMMENTED OUT
REM ECHO. ^<^^!-- 
REM ECHO.         ^|`-.__
REM ECHO.          / '  _/ !VER!
REM ECHO.         ^*^*^*^*`
REM ECHO.        /    }
REM ECHO.  .    /   \ /
REM ECHO.   \ /`    \\\
REM ECHO.    `\     /_\\
REM ECHO.     `~~~~~` `~`
REM ECHO.
REM ECHO.  Watchdog goes woof^^!  --^>
SET "SPL1=^<^!--                        "
SET "SPL2=         |`-.__             "
SET "SPL3=          / '  _/ !VER!     "
SET "SPL4=         ****`              "
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
SET "SPACER=                            "
EXIT /B


:SplashCoexist
CLS
!DFC!
FOR /L %%A in (1,1,!UsableLines!) DO (
	IF DEFINED SPL%%A (
		IF DEFINED L%%A (
			ECHO.!SPL%%A!^|!L%%A!
		)
		IF NOT DEFINED L%%A (
			ECHO.!SPL%%A!^|!L%%A!
		)
	)
	IF NOT DEFINED SPL%%A (
		ECHO.!SPACER!^|!L%%A!
	)
)
EXIT /B


REM // Old Display Code	
REM FOR /L %%A in (1,1,15) DO (
	ECHO.!SPL%%A! ^|!L%%A!
)
REM FOR /L %%A in (16,1,!UsableLines!) DO (
	ECHO.!SPACER! ^|!L%%A!
)

:Results
SET "L12=---[Briefing]"
IF !ERRORCOUNT! LSS 1 (
	SET "L14=   [!ERRORCOUNT!] There were !ERRORCOUNT! Errors."
	CALL :Results.2
) ELSE IF !ERRORCOUNT! LSS 2 (
	SET "L14=   /^!\ [!ERRORCOUNT!] There was !ERRORCOUNT! Error:"
	CALL :Results.2
) ELSE (
	SET "L14=   /^!\ [!ERRORCOUNT!] There were !ERRORCOUNT! Errors:"
	CALL :Results.2
)
IF !ERRORCOUNT! LSS 1 (
	SET "L20=   [!ERRORCOUNT!] There were !ERRORCOUNT! Warnings."
	CALL :Results.2
) ELSE IF !ERRORCOUNT! LSS 2 (
	SET "L20=   /^!\ [!ERRORCOUNT!] There was !ERRORCOUNT! Warning:"
	CALL :Results.2
) ELSE (
	SET "L20=   /^!\ [!ERRORCOUNT!] There were !ERRORCOUNT! Warning:"
	CALL :Results.2
)
:Results.2
IF "!IsProcessRunning.Result!"=="TeamViewerRunning" (
	SET "L15=	 [i] TeamViewer is Running"
) ELSE IF "!IsProcessRunning.Result!"=="TeamViewerNotRunning" (
	SET "L15=	 /^!\ TeamViewer !FIX2! not Running^!!FIX!"
) ELSE IF "!IsProcessRunning.Result!"=="TeamViewerNotInstalled" (
	SET "L15=	 (x) TeamViewer is not Installed^!"
)
IF "!GetInternetConnection1.Result!"=="InternetConnection1Connected" (
	SET "L16=	 [i] Connected to the internet."
) ELSE IF "!GetInternetConnection1.Result!"=="InternetConnection1NotPossible" (
	SET "L16=	 /^!\ Not connected to the internet."
)
IF "!GetInternetConnection2.ResultIPv4!"=="InternetConnection2Connected" (
	SET "L17=	 [i] IPv4: Connected to the Router [!IPv4Gate!]"
) ELSE IF "!GetInternetConnection2.ResultIPv4!"=="TeamViewerNotRunning" (
	SET "L17=	 /^!\ IPv4: No connection to the Router [!IPv4Gate!]"	
)
IF "!GetInternetConnection2.ResultIPv6!"=="InternetConnection2Connected" (
	SET "L18=	 [i] IPv6: Connected to the Router [!IPv6Gate!]"
) ELSE IF "!GetInternetConnection2.ResultIPv6!"=="InternetConnection2NotPossible" (
	SET "L18=	 /^!\ IPv6: No connection to the Router [!IPv6Gate!]"
)
IF "!GetCPULoadPercentage.Result!"=="CPULoadAvgHigh" (
	SET "L21=	 /^!\ CPU: High load [Average: !CPUUsageAvg!%%]"
) ELSE IF "!GetCPULoadPercentage.Result!"=="CPULoadAvgNorm" (
	SET "L21=	 [i] CPU: Normal load  [Average: !CPUUsageAvg!%%]"
)
IF "!GetMemoryLoadPercentage.Result!"=="MemoryLoadAvgHigh" (
	SET "L22=	 /^!\ Memory: High load [Average: !UsedPercent!%%]"
) ELSE IF "!GetMemoryLoadPercentage.Result!"=="MemoryLoadAvgNorm" (
	SET "L22=	 [i] Memory: Normal load  [Average: !UsedPercent!%%]"
)
SET "ERRORCOUNT=0"
SET "WARNCOUNT=0"
EXIT /B
