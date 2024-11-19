@echo off
chcp 65001 >nul

REM Dependencies 디렉토리 생성
if not exist "Dependencies" (
    mkdir Dependencies
)

REM yt-dlp 설치 여부 확인
if not exist "Dependencies\yt-dlp.exe" (
    if not defined already_shown (
        set already_shown=1
        echo 필수 파일 설치하는 중...
    )
    echo yt-dlp을/를 설치하는 중...
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o Dependencies\yt-dlp.exe >nul 2>&1
    echo yt-dlp 설치 완료!
)

REM ffmpeg Essentials 설치 여부 확인
if not exist "Dependencies\bin\ffmpeg.exe" (
    if not defined already_shown (
        set already_shown=1
        echo 필수 파일 설치하는 중...
    )
    echo ffmpeg Essentials을/를 설치하는 중...
    if not exist "Dependencies\bin" (
        mkdir Dependencies\bin
    )
    curl -L https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip -o Dependencies\ffmpeg-essentials.zip >nul 2>&1

    REM ffmpeg 압축 해제
    tar -xf Dependencies\ffmpeg-essentials.zip -C Dependencies --strip-components=1 >nul 2>&1
    del /Q Dependencies\ffmpeg-essentials.zip >nul 2>&1
    echo ffmpeg Essentials 설치 완료!
)

REM 출력 디렉토리 설정
set output_dir=output

REM 출력 디렉토리 존재 여부 확인 및 생성
if not exist "%output_dir%" (
    mkdir "%output_dir%"
)

:input
REM 사용자로부터 링크와 파일 이름을 입력받음
set /p link=유튜브 링크를 입력하세요: 
set /p filename=저장할 파일 이름을 입력받으세요: 

REM 유튜브 링크에서 11자리 비디오 ID 추출
for /f "tokens=2 delims==&" %%A in ("%link%") do set video_id=%%A
set video_id=%video_id:~0,11%

REM 유튜브에서 오디오만 다운로드 (기본 확장자 사용)
Dependencies\yt-dlp.exe -f bestaudio https://www.youtube.com/watch?v=%video_id% -o "%output_dir%\%filename%"

REM 다운로드한 파일을 WAV 포맷으로 변환
for %%A in ("%output_dir%\%filename%.*") do set inputfile=%%A
Dependencies\bin\ffmpeg.exe -y -i "%inputfile%" "%output_dir%\%filename%.wav"

REM 기존 파일 삭제
del "%inputfile%"

REM 변환된 WAV 파일의 크기를 확인
for %%A in ("%output_dir%\%filename%.wav") do set size=%%~zA

REM WAV 파일 크기가 45MB를 넘는지 확인
if %size% GTR 47185920 (
    REM 파일 크기가 45MB를 넘으면 MP3로 트랜스코딩
    Dependencies\bin\ffmpeg.exe -y -i "%output_dir%\%filename%.wav" -ab 320k -f mp3 "%output_dir%\%filename%.mp3"
    REM MP3 변환 후 WAV 파일 삭제
    del "%output_dir%\%filename%.wav"
    echo MP3 변환 완료!
) else (
    echo WAV 변환 완료!
)

REM 계속할지 묻기
set /p continue=계속하시겠습니까? (y/n): 
if /i "%continue%"=="y" (
    goto input
) else (
    echo 프로그램을 종료합니다.
    pause
    exit
)
