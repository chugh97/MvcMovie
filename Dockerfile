# escape=`

FROM shaleenchughacr.azurecr.io/vsbuildtools:20210202.10 AS builder

RUN mkdir C:\src

RUN mkdir C:\out

WORKDIR C:\src

COPY . .

ARG BUILD_VERBOSITY=minimal
ARG BUILD_CONFIGURATION=Release

RUN dotnet build C:\src\MvcMovie.csproj

RUN dotnet publish C:\out
