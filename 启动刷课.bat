@echo off
title Zhihuishu Course Launcher
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0add-course.ps1" %*
