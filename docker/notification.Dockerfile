FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY global.json ./
COPY src ./src
RUN dotnet restore src/VaultHistory.Notification.Worker/VaultHistory.Notification.Worker.csproj
RUN dotnet publish src/VaultHistory.Notification.Worker/VaultHistory.Notification.Worker.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "VaultHistory.Notification.Worker.dll"]
